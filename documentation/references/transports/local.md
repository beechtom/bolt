# Local transport

## Configuration options

The following configuration options are available for the Local transport.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `run-as` | A different user to run commands as after login. | `String` | None |
| `run-as-command` | The command to elevate permissions.<br>Bolt appends the user and command strings to the configured run as a command before running it on the target. This command must not require an interactive password prompt, and the `sudo-password` option is ignored when `run-as-command` is specified. The `run-as-command` must be specified as an array. | `Array[String]` | None |
| `sudo-password` | The password to use when changing users via `run-as`. | `String` | None |
| `tmpdir` | The directory to copy and execute temporary files on the target. | `String` | None |

## Examples

### Setting configuration in the Bolt configuration file

Local transport configuration options can be set in a `bolt.yaml` under the `local` field.

```yaml
local:
  run-as: root
  sudo-password: bolt
```

### Setting configuration in an inventory file

Local transport configuration options can be set in an inventory file at the group or target level. These options are set under the `local` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      local:
        run-as: root
        sudo-password: bolt
# Group-level configuration
config:
  local:
    run-as: administrator
    sudo-password: puppet
```