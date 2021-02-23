# frozen_string_literal: true

# rubocop:disable Lint/SuppressedException
begin
  require 'rspec/core/rake_task'
  require 'open3'

  namespace :tests do
    desc "Run all RSpec tests"
    RSpec::Core::RakeTask.new(:spec)

    namespace :Linux do
      desc ''
      task :provision do
        sh './spec/fixtures/provision/linux.sh'
      end
      
      desc 'Run unit tests on Linux'
      RSpec::Core::RakeTask.new(:unit) do |t|
        t.rspec_opts = '--pattern spec/unit/**/*'
      end

      desc 'Run integration tests on Linux'
      RSpec::Core::RakeTask.new(:integration) do |t|
        t.rspec_opts = '--pattern spec/integration/**/* --tag ~windows_agents --tag ~omi --tag ~kerberos --tag ~windows'
      end
    end

    namespace :Windows do
      desc ''
      task :provision do
        sh 'powershell "& ./spec/fixtures/provision/windows.ps1"'
      end

      desc 'Run unit tests on Windows'
      RSpec::Core::RakeTask.new(:unit) do |t|
        t.rspec_opts = t.rspec_opts = '--pattern spec/unit/**/* --tag ~ssh --tag ~bash'
      end

      desc 'Run integration tests on Windows'
      task :integration do |t|
        puts 'hi'
      end
    end
  end

  # The following tasks are run during CI and require additional environment setup
  # to run. Jobs that run these tests can be viewed in .github/workflows/
  namespace :ci do
    namespace :linux do
      # Run RSpec tests that do not require WinRM
      desc ''
      RSpec::Core::RakeTask.new(:fast) do |t|
        t.rspec_opts = '--tag ~winrm --tag ~windows_agents --tag ~puppetserver --tag ~puppetdb ' \
                       '--tag ~omi --tag ~windows --tag ~kerberos --tag ~expensive'
      end

      # Run RSpec tests that are slow or require slow to start containers for setup
      desc ''
      RSpec::Core::RakeTask.new(:slow) do |t|
        t.rspec_opts = '--tag puppetserver --tag puppetdb --tag expensive'
      end
    end

    namespace :windows do
      # Run RSpec tests that do not require Puppet Agents on Windows
      desc ''
      RSpec::Core::RakeTask.new(:agentless) do |t|
        t.rspec_opts = '--tag ~ssh --tag ~docker --tag ~bash --tag ~windows_agents ' \
                       '--tag ~orchestrator --tag ~puppetserver --tag ~puppetdb --tag ~omi ' \
                       '--tag ~kerberos'
      end

      # Run RSpec tests that require Puppet Agents configured with Windows
      desc ''
      RSpec::Core::RakeTask.new(:agentful) do |t|
        t.rspec_opts = '--tag windows_agents'
      end
    end

    desc "Run RSpec tests for Bolt's bundled content"
    task :modules do
      success = true
      # Test core modules
      %w[boltlib ctrl file dir out prompt system].each do |mod|
        Dir.chdir("#{__dir__}/../bolt-modules/#{mod}") do
          sh 'rake spec' do |ok, _|
            success = false unless ok
          end
        end
      end
      # Test modules
      %w[canary aggregate puppetdb_fact puppet_connect].each do |mod|
        Dir.chdir("#{__dir__}/../modules/#{mod}") do
          sh 'rake spec' do |ok, _|
            success = false unless ok
          end
        end
      end
      # Test BoltSpec
      Dir.chdir("#{__dir__}/../bolt_spec_spec/") do
        sh 'rake spec' do |ok, _|
          success = false unless ok
        end
      end
      raise "Module tests failed" unless success
    end
  end
rescue LoadError
end
# rubocop:enable Lint/SuppressedException
