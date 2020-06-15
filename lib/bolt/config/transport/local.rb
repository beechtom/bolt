# frozen_string_literal: true

require 'bolt/error'
require 'bolt/config/transport/base'

module Bolt
  class Config
    module Transport
      class Local < Base
        # NOTE: All transport configuration options should have a corresponding schema definition
        #       in schemas/bolt-transport-definitions.json
        OPTIONS = {
          "cleanup" => { type: TrueClass,
                         desc: "Whether to clean up temporary files created on targets." },
          "interpreters" => { type: Hash,
                              desc: "A map of an extension name to the absolute path of an executable, "\
                                      "enabling you to override the shebang defined in a task executable. The "\
                                      "extension can optionally be specified with the `.` character (`.py` and "\
                                      "`py` both map to a task executable `task.py`) and the extension is case "\
                                      "sensitive. When a target's name is `localhost`, Ruby tasks run with the "\
                                      "Bolt Ruby interpreter by default." },
          "tmpdir" => { type: String,
                        desc: "The directory to copy and execute temporary files." }
        }.merge(RUN_AS_OPTIONS).freeze

        WINDOWS_OPTIONS = {
          "cleanup"      => { type: TrueClass,
                              desc: "Whether to clean up temporary files created on targets." },
          "interpreters" => { type: Hash,
                              desc: "A map of an extension name to the absolute path of an executable, "\
                                    "enabling you to override the shebang defined in a task executable. The "\
                                    "extension can optionally be specified with the `.` character (`.py` and "\
                                    "`py` both map to a task executable `task.py`) and the extension is case "\
                                    "sensitive. When a target's name is `localhost`, Ruby tasks run with the "\
                                    "Bolt Ruby interpreter by default." },
          "tmpdir"       => { type: String,
                              desc: "The directory to copy and execute temporary files." }
        }.freeze

        DEFAULTS = {
          'cleanup' => true
        }.freeze

        def self.options
          Bolt::Util.windows? ? WINDOWS_OPTIONS : OPTIONS
        end

        private def validate
          super

          if @config['interpreters']
            @config['interpreters'] = normalize_interpreters(@config['interpreters'])
          end

          if (run_as_cmd = @config['run-as-command'])
            unless run_as_cmd.all? { |n| n.is_a?(String) }
              raise Bolt::ValidationError,
                    "run-as-command must be an Array of Strings, received #{run_as_cmd.class} #{run_as_cmd.inspect}"
            end
          end
        end
      end
    end
  end
end
