# frozen_string_literal: true

require 'bolt/error'
require 'bolt/config/transport/base'

module Bolt
  class Config
    module Transport
      class SSH < Base
        LOGIN_SHELLS = %w[sh bash zsh dash ksh powershell].freeze

        # NOTE: All transport configuration options should have a corresponding schema definition
        #       in schemas/bolt-transport-definitions.json
        OPTIONS = {
          "cleanup"               => { type: TrueClass,
                                       external: true,
                                       desc: "Whether to clean up temporary files created on targets." },
          "connect-timeout"       => { type: Integer,
                                       desc: "How long to wait when establishing connections." },
          "copy-command"          => { external: true,
                                       desc: "Command to use when copying files using ssh-command. "\
                                             "Bolt runs `<copy-command> <src> <dest>`. **This option is "\
                                             "experimental.**" },
          "disconnect-timeout"    => { type: Integer,
                                       desc: "How long to wait before force-closing a connection." },
          "encryption-algorithms" => { type: Array,
                                       desc: "List of encryption algorithms to use when establishing a "\
                                             "connection with a target. Supported algorithms are "\
                                             "defined by the Ruby net-ssh library and can be viewed "\
                                             "[here](https://github.com/net-ssh/net-ssh#supported-algorithms). "\
                                             "All supported, non-deprecated algorithms are available by default when "\
                                             "this option is not used. To reference all default algorithms "\
                                             "when using this option, add 'defaults' to the list of supported "\
                                             "algorithms." },
          "extensions"            => { type: Array,
                                       desc: "List of file extensions that are accepted for scripts or tasks on "\
                                             "Windows. Scripts with these file extensions rely on the target's file "\
                                             "type association to run. For example, if Python is installed on the "\
                                             "system, a `.py` script runs with `python.exe`. The extensions `.ps1`, "\
                                             "`.rb`, and `.pp` are always allowed and run via hard-coded "\
                                             "executables." },
          "host"                  => { type: String,
                                       external: true,
                                       desc: "Host name." },
          "host-key-algorithms"   => { type: Array,
                                       desc: "List of host key algorithms to use when establishing a connection "\
                                             "with a target. Supported algorithms are defined by the Ruby net-ssh "\
                                             "library "\
                                             "([docs](https://github.com/net-ssh/net-ssh#supported-algorithms)). "\
                                             "All supported, non-deprecated algorithms are available by default when "\
                                             "this option is not used. To reference all default algorithms "\
                                             "using this option, add 'defaults' to the list of supported "\
                                             "algorithms." },
          "host-key-check"        => { type: TrueClass,
                                       external: true,
                                       desc: "Whether to perform host key validation when connecting." },
          "interpreters"          => { type: Hash,
                                       external: true,
                                       desc: "A map of an extension name to the absolute path of an executable, "\
                                             "enabling you to override the shebang defined in a task executable. "\
                                             "The extension can optionally be specified with the `.` character "\
                                             "(`.py` and `py` both map to a task executable `task.py`) and the "\
                                             "extension is case sensitive. When a target's name is `localhost`, "\
                                             "Ruby tasks run with the Bolt Ruby interpreter by default." },
          "kex-algorithms"        => { type: Array,
                                       desc: "List of key exchange algorithms to use when establishing a "\
                                             "connection to a target. Supported algorithms are defined by the "\
                                             "Ruby net-ssh library "\
                                             "([docs](https://github.com/net-ssh/net-ssh#supported-algorithms)). "\
                                             "All supported, non-deprecated algorithms are available by default when "\
                                             "this option is not used. To reference all default algorithms "\
                                             "using this option, add 'defaults' to the list of supported "\
                                             "algorithms." },
          "load-config"           => { type: TrueClass,
                                       desc: "Whether to load system SSH configuration." },
          "login-shell"           => { type: String,
                                       desc: "Which login shell Bolt should expect on the target. "\
                                             "Supported shells are #{LOGIN_SHELLS.join(', ')}. "\
                                             "**This option is experimental.**" },
          "mac-algorithms"        => { type: Array,
                                       desc: "List of message authentication code algorithms to use when "\
                                             "establishing a connection to a target. Supported algorithms are "\
                                             "defined by the Ruby net-ssh library "\
                                             "([docs](https://github.com/net-ssh/net-ssh#supported-algorithms)). "\
                                             "All supported, non-deprecated algorithms are available by default when "\
                                             "this option is not used. To reference all default algorithms "\
                                             "using this option, add 'defaults' to the list of supported "\
                                             "algorithms." },
          "password"              => { type: String,
                                       desc: "Login password." },
          "port"                  => { type: Integer,
                                       external: true,
                                       desc: "Connection port." },
          "private-key"           => { external: true,
                                       desc: "Either the path to the private key file to use for authentication, or "\
                                             "a hash with the key `key-data` and the contents of the private key." },
          "proxyjump"             => { type: String,
                                       desc: "A jump host to proxy connections through, and an optional user to "\
                                             "connect with." },
          "script-dir"            => { type: String,
                                       external: true,
                                       desc: "The subdirectory of the tmpdir to use in place of a randomized "\
                                             "subdirectory for uploading and executing temporary files on the "\
                                             "target. It's expected that this directory already exists as a subdir "\
                                             "of tmpdir, which is either configured or defaults to `/tmp`." },
          "ssh-command"           => { external: true,
                                       desc: "Command and flags to use when SSHing. This enables the external "\
                                             "SSH transport which shells out to the specified command. "\
                                             "**This option is experimental.**" },
          "tmpdir"                => { type: String,
                                       external: true,
                                       desc: "The directory to upload and execute temporary files on the target." },
          "tty"                   => { type: TrueClass,
                                       desc: "Request a pseudo tty for the session. This option is generally "\
                                             "only used in conjunction with the `run-as` option when the sudoers "\
                                             "policy requires a `tty`." },
          "user"                  => { type: String,
                                       external: true,
                                       desc: "Login user." }
        }.merge(RUN_AS_OPTIONS).freeze

        DEFAULTS = {
          "cleanup"            => true,
          "connect-timeout"    => 10,
          "tty"                => false,
          "load-config"        => true,
          "disconnect-timeout" => 5,
          "login-shell"        => 'bash'
        }.freeze

        private def validate
          super

          if (key_opt = @config['private-key'])
            unless key_opt.instance_of?(String) || (key_opt.instance_of?(Hash) && key_opt.include?('key-data'))
              raise Bolt::ValidationError,
                    "private-key option must be a path to a private key file or a Hash containing the 'key-data', "\
                    "received #{key_opt.class} #{key_opt}"
            end

            if key_opt.instance_of?(String)
              @config['private-key'] = File.expand_path(key_opt, @project)

              # We have an explicit test for this to only warn if using net-ssh transport
              Bolt::Util.validate_file('ssh key', @config['private-key']) if @config['ssh-command']
            end

            if key_opt.instance_of?(Hash) && @config['ssh-command']
              raise Bolt::ValidationError, 'private-key must be a filepath when using ssh-command'
            end
          end

          if @config['interpreters']
            @config['interpreters'] = normalize_interpreters(@config['interpreters'])
          end

          if @config['login-shell'] && !LOGIN_SHELLS.include?(@config['login-shell'])
            raise Bolt::ValidationError,
                  "Unsupported login-shell #{@config['login-shell']}. Supported shells are #{LOGIN_SHELLS.join(', ')}"
          end

          %w[encryption-algorithms host-key-algorithms kex-algorithms mac-algorithms run-as-command].each do |opt|
            next unless @config.key?(opt)
            unless @config[opt].all? { |n| n.is_a?(String) }
              raise Bolt::ValidationError,
                    "#{opt} must be an Array of Strings, received #{@config[opt].inspect}"
            end
          end

          if @config['login-shell'] == 'powershell'
            %w[tty run-as].each do |key|
              if @config[key]
                raise Bolt::ValidationError,
                      "#{key} is not supported when using PowerShell"
              end
            end
          end

          if @config['ssh-command'] && !@config['load-config']
            msg = 'Cannot use external SSH transport with load-config set to false'
            raise Bolt::ValidationError, msg
          end

          if (ssh_cmd = @config['ssh-command'])
            unless ssh_cmd.is_a?(String) || ssh_cmd.is_a?(Array)
              raise Bolt::ValidationError,
                    "ssh-command must be a String or Array, received #{ssh_cmd.class} #{ssh_cmd.inspect}"
            end
          end

          if (copy_cmd = @config['copy-command'])
            unless copy_cmd.is_a?(String) || copy_cmd.is_a?(Array)
              raise Bolt::ValidationError,
                    "copy-command must be a String or Array, received #{copy_cmd.class} #{copy_cmd.inspect}"
            end
          end
        end
      end
    end
  end
end
