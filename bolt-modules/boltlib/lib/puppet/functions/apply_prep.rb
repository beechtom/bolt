# frozen_string_literal: true

require 'bolt/logger'
require 'bolt/task'

# Installs the `puppet-agent` package on targets if needed, then collects facts,
# including any custom facts found in Bolt's module path. The package is
# installed using either the configured plugin or the `task` plugin with the
# `puppet_agent::install` task.
#
# Agent installation will be skipped if the target includes the `puppet-agent` feature, either as a
# property of its transport (PCP) or by explicitly setting it as a feature in Bolt's inventory.
#
# > **Note:** Not available in apply block
Puppet::Functions.create_function(:apply_prep) do
  # @param targets A pattern or array of patterns identifying a set of targets.
  # @param options Options hash.
  # @option options [Array] _required_modules An array of modules to sync to the target.
  # @option options [String] _run_as User to run as using privilege escalation.
  # @return [nil]
  # @example Prepare targets by name.
  #   apply_prep('target1,target2')
  dispatch :apply_prep do
    param 'Boltlib::TargetSpec', :targets
    optional_param 'Hash[String, Data]', :options
  end

  def script_compiler
    @script_compiler ||= Puppet::Pal::ScriptCompiler.new(closure_scope.compiler)
  end

  def inventory
    @inventory ||= Puppet.lookup(:bolt_inventory)
  end

  def get_task(name, params = {})
    tasksig = script_compiler.task_signature(name)
    raise Bolt::Error.new("Task '#{name}' could not be found", 'bolt/apply-prep') unless tasksig

    errors = []
    unless tasksig.runnable_with?(params) { |msg| errors << msg }
      # This relies on runnable with printing a partial message before the first real error
      raise Bolt::ValidationError, "Invalid parameters for #{errors.join("\n")}"
    end

    Bolt::Task.from_task_signature(tasksig)
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_agent_feature(target)
    inventory.set_feature(target, 'puppet-agent')
  end
  # rubocop:enable Naming/AccessorMethodName

  def run_task(targets, task, args = {}, options = {})
    executor.run_task(targets, task, args, options)
  end

  # Returns true if the target has the puppet-agent feature defined, either from inventory or transport.
  def agent?(target, executor, inventory)
    inventory.features(target).include?('puppet-agent') ||
      executor.transport(target.transport).provided_features.include?('puppet-agent') || target.remote?
  end

  def executor
    @executor ||= Puppet.lookup(:bolt_executor)
  end

  def apply_prep(target_spec, options = {})
    unless Puppet[:tasks]
      raise Puppet::ParseErrorWithIssue
        .from_issue_and_stack(Bolt::PAL::Issues::PLAN_OPERATION_NOT_SUPPORTED_WHEN_COMPILING, action: 'apply_prep')
    end

    # Unfreeze this
    options = options.slice(*%w[_run_as _required_modules])
    options['_noop'] = true if executor.noop

    applicator = Puppet.lookup(:apply_executor)

    executor.report_function_call(self.class.name)

    targets = inventory.get_targets(target_spec)

    required_modules = options.delete('_required_modules').to_a
    if required_modules.any?
      Puppet.debug("Syncing only required modules: #{required_modules.join(',')}.")
    end

    # Gather facts, including custom facts
    plugins = applicator.build_plugin_tarball do |mod|
      next unless required_modules.empty? || required_modules.include?(mod.name)
      search_dirs = []
      search_dirs << mod.plugins if mod.plugins?
      search_dirs << mod.pluginfacts if mod.pluginfacts?
      search_dirs
    end

    executor.log_action('install puppet and gather facts', targets) do
      executor.without_default_logging do
        # Skip targets that include the puppet-agent feature, as we know an agent will be available.
        agent_targets, need_install_targets = targets.partition { |target| agent?(target, executor, inventory) }
        agent_targets.each { |target| Puppet.debug "Puppet Agent feature declared for #{target.name}" }
        unless need_install_targets.empty?
          # lazy-load expensive gem code
          require 'concurrent'
          pool = Concurrent::ThreadPoolExecutor.new

          hooks = need_install_targets.map do |t|
            opts = t.plugin_hooks&.fetch('puppet_library').dup
            plugin_name = opts.delete('plugin')
            hook = inventory.plugins.get_hook(plugin_name, :puppet_library)
            # Give plan function options precedence over inventory options
            { 'target' => t,
              'hook_proc' => hook.call(opts.merge(options), t, self) }
          # Catch and immediately re-raise noop errors so the entire plan fails,
          # otherwise we'll get a failing result for each target. This error is
          # raised by the plugin module, since that's where the plugin task is
          # loaded and where Bolt checks if it can be run in noop mode.
          rescue Bolt::Plugin::PluginError::NoopError
            raise
          # Catch all other errors and create a failing result.
          rescue StandardError => e
            Bolt::Result.from_exception(t, e)
          end

          hook_errors, ok_hooks = hooks.partition { |h| h.is_a?(Bolt::Result) }

          futures = ok_hooks.map do |hash|
            Concurrent::Future.execute(executor: pool) do
              hash['hook_proc'].call
            end
          end

          results = futures.zip(ok_hooks).map do |f, hash|
            f.value || Bolt::Result.from_exception(hash['target'], f.reason)
          end
          set = Bolt::ResultSet.new(results + hook_errors)
          raise Bolt::RunFailure.new(set.error_set, 'apply_prep') unless set.ok

          need_install_targets.each { |target| set_agent_feature(target) }
        end

        # If running in noop mode, skip the custom facts task. This task uses
        # the Puppet Ruby interpreter by default, which won't be available
        # unless the target already has the puppet-agent package installed as
        # apply_prep does not install the puppet-agent package in noop mode.
        unless executor.noop
          task = applicator.custom_facts_task
          arguments = { 'plugins' => Puppet::Pops::Types::PSensitiveType::Sensitive.new(plugins) }
          results = run_task(targets, task, arguments, options)

          # TODO: Standardize RunFailure type with error above
          raise Bolt::RunFailure.new(results, 'run_task', task.name) unless results.ok?

          results.each do |result|
            # Log a warning if the client version is < 6
            if unsupported_puppet?(result['clientversion'])
              Bolt::Logger.deprecate(
                "unsupported_puppet",
                "Detected unsupported Puppet agent version #{result['clientversion']} on target "\
                "#{result.target}. Bolt supports Puppet agent 6.0.0 and higher."
              )
            end

            inventory.add_facts(result.target, result.value)
          end
        end
      end
    end

    # Return nothing
    nil
  end

  # Returns true if the client's major version is < 6.
  #
  private def unsupported_puppet?(client_version)
    if client_version.nil?
      false
    else
      begin
        Integer(client_version.split('.').first) < 6
      rescue StandardError
        false
      end
    end
  end
end
