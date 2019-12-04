# PCP transport

## Configuration options

The following configuration options are available for the PCP transport.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `cacert` | The path to the CA certificate. | `String` | None |
| `service-url` | The URL of the orchestrator API. | `String` | None |
| `task-environment` | The environment the orchestrator loads task code from. | `String` | None |
| `token-file` | The path to the token file. | `String` | None |
| `job-poll-interval` | The interval to poll orchestrator for job status. | `Integer` | None |
| `job-poll-timeout` | The time to wait for orchestrator job status. | `Integer` | None |

## Examples

### Setting configuration in the Bolt configuration file

PCP transport configuration options can be set in a `bolt.yaml` under the `pcp` field.

```yaml
pcp:
  cacert: /path/to/cert/cacert.pem
  service-url: https://example.com:8143
```

### Setting configuration in an inventory file

PCP transport configuration options can be set in an inventory file at the group or target level. These options are set under the `pcp` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      pcp:
        task-environment: production
# Group-level configuration
config:
  pcp:
    task-environment: development
```