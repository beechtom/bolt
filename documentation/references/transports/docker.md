# Docker transport

> **Note:** The Docker transport is experimental because the capabilities and role of the Docker API might change.

## Configuration options

The following configuration options are available for the Docker transport.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `service-url` | URL of the Docker host used for API requests. | `String` | Local via a Unix socket at `unix:///var/docker.sock` |
| `shell-command` | A shell command to wrap any Docker exec commands in, such as `bash -lc`. | `String` | None |
| `tmpdir` | The directory to upload and execute temporary files on the target. | `String` | None |
| `tty` | Enable tty on Docker exec commands. | `Boolean` | `false` |

## Examples

### Setting configuration in the Bolt configuration file

Docker transport configuration options can be set in a `bolt.yaml` under the `docker` field.

```yaml
docker:
  service-url: tcp://192.168.0.100:2376
  tty: true 
```

### Setting configuration in an inventory file

Docker transport configuration options can be set in an inventory file at the group or target level. These options are set under the `docker` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      docker:
        tty: true
# Group-level configuration
config:
  docker:
    service-url: tcp://192.168.0.100:2376
```