# SSH transport

## Configuration options

The following configuration options are available for the SSH transport.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `connect-timeout` | How long to wait when establishing connections. | `Integer` | `10` |
| `disconnect-timeout` | How long to wait to force-close the connection. | `Integer` | `5` |
| `host-key-check` | Whether to perform host key validation when connecting. | `Boolean` | `true` |
| `password` | Login password. | `String` | None |
| `port` | Connection port. | `Integer` | `22` |
| `private-key` | The path to the private key file, or a hash with a `key-data` field and the contents of the private key. | `Variant[String, Hash]` | None |
| `proxyjump` | A jump host to proxy connections through, and an optional user to connect with. | `String` | None |
| `run-as` | A different user to run commands as after login. | `String` | None |
| `run-as-command` | The command to elevate permissions.<br>Bolt appends the user and command strings to the configured run as a command before running it on the target. This command must not require an interactive password prompt, and the `sudo-password` option is ignored when `run-as-command` is specified. The `run-as-command` must be specified as an array. | `Array[String]` | None |
| `sudo-password` | The password to use when changing users via `run-as`. | `String` | None |
| `tmpdir` | The directory to copy and execute temporary files on the target. | `String` | None |
| `tty` | Request a pseudo tty for the session.<br>This option is generally only used in conjunction with the `run-as` option when the sudoers policy requires a `tty`. | `Boolean` | `false` |
| `user` | Login user. | `String` | `root` |

## OpenSSH configuration options

In addition to the SSH transport options defined in Bolt configuration files, some additional SSH options are read from OpenSSH configuration files, including `~/.ssh/config`, `/etc/ssh_config`, and `/etc/ssh/ssh_config`. Not all OpenSSH configuration values have equivalents in Bolt.

For OpenSSH configuration options with direct equivalents in Bolt, such as `user` and `port`, the settings in Bolt config take precedence.

When using the SSH transport, Bolt also interacts with the ssh-agent for SSH key management. The most common interaction is to handle password protected private keys. When a private key is password protected it must be added to the ssh-agent in order to be used to authenticate Bolt SSH connections.

| **Key** | **Description** |
| ------- | --------------- |
| `Ciphers` | Ciphers allowed in order of precedence. Multiple ciphers must be comma separated. |
| `Compression` | Whether to use compression. |
| `CompressionLevel` | Compression level to use if `Compression` is enabled. |
| `GlobalKnownHostsFile` | Path to global known host key database. |
| `HostKeyAlgorithms` | Host key algorithms that the client wants to use in order of preference. |
| `HostKeyAlias` | Use alias instead of real hostname when looking up or saving the host key in the host key database file. |
| `HostName` | Host name to log. |
| `IdentitiesOnly` | Use only the identity key in SSH config even if ssh-agent offers others. |
| `IdentityFile` | File in which user's identity key is stored. |
| `Port` | Connection port. |
| `User` | Login user. |
| `UserKnownHostsFile` | Path to local user's host key database. |

## Examples

### Setting configuration in the Bolt configuration file

SSH transport configuration options can be set in a `bolt.yaml` under the `ssh` field.

```yaml
ssh:
  connect-timeout: 20
  disconnect-timeout: 10
  private-key:
    key-data: |
      MY PRIVATE KEY CONTENT
```

### Setting configuration on a group

SSH transport configuration options can be set in an inventory file at the group level. These options are set under the `ssh` field under `config`.

```yaml
targets:
  - target1
  - target2
config:
  ssh:
    connect-timeout: 20
    disconnect-timeout: 10
    private-key: /path/to/key/id_rsa
```

### Setting configuration on a target

SSH transport configuration options can be set in an inventory file at the target level. These options are set under the `ssh` field under `config`.

```yaml
targets:
  - uri: target1
    config:
      ssh:
        connect-timeout: 20
        disconnect-timeout: 10
        private-key: /path/to/key/id_rsa
  - uri: target2
    config:
      ssh:
        port: 3456
```

<!-- ### Setting configuration in an inventory file

SSH transport configuration options can be set in an inventory file at the group or target level. These options are set under the `ssh` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      ssh:
        run-as-command: ['sudo', '-k', '-n']
# Group-level configuration
config:
  ssh:
    connect-timeout: 20
    disconnect-timeout: 10
    private-key: /path/to/key/id_rsa
``` -->