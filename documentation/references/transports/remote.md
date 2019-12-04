# Remote transport

> **Note:** The remote transport is experimental. Its configuration options and behavior might change between Y releases.

The remote transport can accept arbitrary options depending on the underlying remote target, for example `api-token`.

## Configuration options

The following configuration options are available for the Remote transport.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `run-on` | The proxy target that the task executes on. | `String` | `localhost` |

## Examples

### Setting configuration in the Bolt configuration file

Remote transport configuration options can be set in a `bolt.yaml` under the `remote` field.

```yaml
remote:
  run-on: https://example.com:2022
```

### Setting configuration in an inventory file

Remote transport configuration options can be set in an inventory file at the group or target level. These options are set under the `remote` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      remote:
        run-on: https://example.com:2033
# Group-level configuration
config:
  remote:
    run-on: https://example.com:2022
```