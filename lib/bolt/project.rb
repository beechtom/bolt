# frozen_string_literal: true

require 'pathname'
require 'bolt/config'
require 'bolt/config/validator'
require 'bolt/pal'
require 'bolt/module'

module Bolt
  class Project
    BOLTDIR_NAME = 'Boltdir'
    CONFIG_NAME  = 'bolt-project.yaml'

    attr_reader :path, :data, :config_file, :inventory_file, :hiera_config,
                :puppetfile, :rerunfile, :type, :resource_types, :logs, :project_file,
                :deprecations, :downloads, :plans_path, :modulepath, :managed_moduledir,
                :backup_dir

    def self.default_project(logs = [])
      create_project(File.expand_path(File.join('~', '.puppetlabs', 'bolt')), 'user', logs)
    # If homedir isn't defined use the system config path
    rescue ArgumentError
      create_project(Bolt::Config.system_path, 'system', logs)
    end

    # Search recursively up the directory hierarchy for the Project. Look for a
    # directory called Boltdir or a file called bolt.yaml (for a control repo
    # type Project). Otherwise, repeat the check on each directory up the
    # hierarchy, falling back to the default if we reach the root.
    def self.find_boltdir(dir, logs = [])
      dir = Pathname.new(dir)

      if (dir + BOLTDIR_NAME).directory?
        create_project(dir + BOLTDIR_NAME, 'embedded', logs)
      elsif (dir + 'bolt.yaml').file? || (dir + CONFIG_NAME).file?
        create_project(dir, 'local', logs)
      elsif dir.root?
        default_project(logs)
      else
        logs << { debug: "Did not detect Boltdir, bolt.yaml, or #{CONFIG_NAME} at '#{dir}'. "\
                  "This directory won't be loaded as a project." }
        find_boltdir(dir.parent, logs)
      end
    end

    def self.create_project(path, type = 'option', logs = [])
      fullpath = Pathname.new(path).expand_path

      if type == 'user'
        begin
          # This is already expanded if the type is user
          FileUtils.mkdir_p(path)
        rescue StandardError
          logs << { warn: "Could not create default project at #{path}. Continuing without a writeable project. "\
                    "Log and rerun files will not be written." }
        end
      end

      if type == 'option' && !File.directory?(path)
        raise Bolt::Error.new("Could not find project at #{path}", "bolt/project-error")
      end

      if !Bolt::Util.windows? && type != 'environment' && fullpath.world_writable?
        raise Bolt::Error.new(
          "Project directory '#{fullpath}' is world-writable which poses a security risk. Set "\
          "BOLT_PROJECT='#{fullpath}' to force the use of this project directory.",
          "bolt/world-writable-error"
        )
      end

      project_file = File.join(fullpath, CONFIG_NAME)
      data         = Bolt::Util.read_optional_yaml_hash(File.expand_path(project_file), 'project')
      default      = type =~ /user|system/ ? 'default ' : ''
      exist        = File.exist?(File.expand_path(project_file))
      deprecations = []

      logs << { info: "Loaded #{default}project from '#{fullpath}'" } if exist

      # Validate the config against the schema. This will raise a single error
      # with all validation errors.
      schema = Bolt::Config::OPTIONS.slice(*Bolt::Config::BOLT_PROJECT_OPTIONS)

      Bolt::Config::Validator.new.tap do |validator|
        validator.validate(data, schema, project_file)

        validator.warnings.each { |warning| logs << { warn: warning } }

        validator.deprecations.each do |dep|
          deprecations << { type: "#{CONFIG_NAME} #{dep[:option]}", msg: dep[:message] }
        end
      end

      new(data, path, type, logs, deprecations)
    end

    def initialize(raw_data, path, type = 'option', logs = [], deprecations = [])
      @path         = Pathname.new(path).expand_path
      @project_file = @path + CONFIG_NAME
      @logs         = logs
      @deprecations = deprecations

      if (@path + 'bolt.yaml').file? && project_file?
        msg = "Project-level configuration in bolt.yaml is deprecated if using #{CONFIG_NAME}. "\
          "Transport config should be set in inventory.yaml, all other config should be set in "\
          "#{CONFIG_NAME}."
        @deprecations << { type: 'Using bolt.yaml for project configuration', msg: msg }
      end

      @inventory_file    = @path + 'inventory.yaml'
      @hiera_config      = @path + 'hiera.yaml'
      @puppetfile        = @path + 'Puppetfile'
      @rerunfile         = @path + '.rerun.json'
      @resource_types    = @path + '.resource_types'
      @type              = type
      @downloads         = @path + 'downloads'
      @plans_path        = @path + 'plans'
      @managed_moduledir = @path + '.modules'
      @backup_dir        = @path + '.bolt-bak'

      tc = Bolt::Config::INVENTORY_OPTIONS.keys & raw_data.keys
      if tc.any?
        msg = "Transport configuration isn't supported in #{CONFIG_NAME}. Ignoring keys #{tc}"
        @logs << { warn: msg }
      end

      @data = raw_data.reject { |k, _| Bolt::Config::INVENTORY_OPTIONS.include?(k) }

      # If the 'modules' key is present in the project configuration file,
      # use the new, shorter modulepath.
      @modulepath = if @data.key?('modules')
                      [(@path + 'modules').to_s]
                    else
                      [(@path + 'modules').to_s, (@path + 'site-modules').to_s, (@path + 'site').to_s]
                    end

      # Once bolt.yaml deprecation is removed, this attribute should be removed
      # and replaced with .project_file in lib/bolt/config.rb
      @config_file = if (Bolt::Config::BOLT_OPTIONS & @data.keys).any?
                       if (@path + 'bolt.yaml').file?
                         msg = "#{CONFIG_NAME} contains valid config keys, bolt.yaml will be ignored"
                         @logs << { warn: msg }
                       end
                       @project_file
                     else
                       @path + 'bolt.yaml'
                     end
      validate if project_file?
    end

    def to_s
      @path.to_s
    end

    # This API is used to prepend the project as a module to Puppet's internal
    # module_references list. CHANGE AT YOUR OWN RISK
    def to_h
      { path: @path.to_s,
        name: name,
        load_as_module?: load_as_module? }
    end

    def eql?(other)
      path == other.path
    end
    alias == eql?

    def project_file?
      @project_file.file?
    end

    def load_as_module?
      !name.nil?
    end

    def name
      @data['name']
    end

    def tasks
      @data['tasks']
    end

    def plans
      @data['plans']
    end

    def modules
      @modules ||= @data['modules']&.map do |mod|
        if mod.is_a?(String)
          { 'name' => mod }
        else
          mod
        end
      end
    end

    def validate
      if name
        if name !~ Bolt::Module::MODULE_NAME_REGEX
          raise Bolt::ValidationError, <<~ERROR_STRING
          Invalid project name '#{name}' in #{CONFIG_NAME}; project name must begin with a lowercase letter
          and can include lowercase letters, numbers, and underscores.
          ERROR_STRING
        elsif Dir.children(Bolt::Config::Modulepath::BOLTLIB_PATH).include?(name)
          raise Bolt::ValidationError, "The project '#{name}' will not be loaded. The project name conflicts "\
            "with a built-in Bolt module of the same name."
        end
      else
        message = "No project name is specified in #{CONFIG_NAME}. Project-level content will not be available."
        @logs << { warn: message }
      end
    end

    def check_deprecated_file
      if (@path + 'project.yaml').file?
        msg = "Project configuration file 'project.yaml' is deprecated; use '#{CONFIG_NAME}' instead."
        Bolt::Logger.deprecation_warning("Using project.yaml instead of #{CONFIG_NAME}", msg)
      end
    end
  end
end
