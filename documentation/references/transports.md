# Transport configuration

Bolt can set the transport protocol when connecting to targets. The configuration for each transport can be set in either the Bolt configuration file, `bolt.yaml`, or in an inventory file at either the group or target level.

## Available transports

* [Docker](docker.md)
* [Local](local.md)
* [PCP](pcp.md)
* [Remote](remote.md)
* [SSH](ssh.md)
* [WinRM](winrm.md)

## Examples

### Setting configuration in the Bolt configuration file

Transport configuration options can be set in the Bolt configuration file, `bolt.yaml`, by using the appropriate field for the transport. A default transport protocol can also be specified by setting the `transport` field.

```yaml
# Set the default transport protocol for all targets to SSH
transport: ssh
# Set the default SSH transport configuration
ssh:
  connect-timeout: 20
  disconnect-timeout: 10
  host-key-check: false
# Set the default WinRM transport configuration
winrm:
  cacert: /path/to/cert/cacert.pem
  user: Administrator
  password: bolt
```

### Setting configuration in an inventory file

Transport configuration options can be set in an inventory file at the group or target level. These options are set under the appropriate field for a transport, which is under the `config` field. A default transport protocol can also be specified by setting the `transport` field under `config`.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      transport: ssh
      ssh:
        run-as-command: ['sudo', '-k', '-n']
  - uri: target2
    config:
      transport: winrm
      winrm:
        user: Administrator
        password: bolt
# Group-level configuration
config:
  # Set the default transport protocol for the group to SSH
  transport: ssh
  ssh:
    connect-timeout: 20
    disconnect-timeout: 10
    private-key: /path/to/key/id_rsa
  winrm:
    cacert: /path/to/cert/cacert.pem
```