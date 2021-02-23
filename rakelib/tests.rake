# frozen_string_literal: true

# rubocop:disable Lint/SuppressedException
begin
  require 'rspec/core/rake_task'

  namespace :tests do
    desc "Run all RSpec tests"
    RSpec::Core::RakeTask.new(:spec)

    namespace :Linux do
      desc ''
      task :setup do
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

      desc ''
      task :modules do |t|
        Rake::Task['tests:module'].invoke
      end
    end

    namespace :Windows do
      desc ''
      task :setup do
        sh 'powershell "& ./spec/fixtures/provision/windows.ps1"'
      end

      desc 'Run unit tests on Windows'
      RSpec::Core::RakeTask.new(:unit) do |t|
        t.rspec_opts = t.rspec_opts = '--pattern spec/unit/**/* --tag ~ssh --tag ~bash'
      end

      desc 'Run integration tests on Windows'
      RSpec::Core::RakeTask.new(:integration) do |t|
        t.rspec_opts = t.rspec_opts = '--pattern spec/integration/**/* --tag windows_agents'
      end

      desc ''
      task :modules do |t|
        Rake::Task['tests:module'].invoke
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
