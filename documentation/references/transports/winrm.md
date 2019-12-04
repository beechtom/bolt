# WinRM transport

## Configuration options

The following configuration options are available for the WinRM transport. Options in **`bold`** are **required**.

| **Key** | **Description** | **Value** | **Default** |
| ------- | --------------- | --------- | ----------- |
| `cacert` | The path to the CA certificate. | `String` | None |
| `connect-timeout` | How long Bolt should wait when establishing connections. | `Integer` | None |
| `extensions` | List of file extensions that are accepted for scripts or tasks.<br>Scripts with these file extensions rely on the target node's file type association to run. For example, if Python is installed on the system, a `.py` script runs with `python.exe`. The extenions `.ps1`, `.rb`, and `.pp` are always allowed and run via hard-coded executables. | `Array[String]` | None |
| `file-protocol` | Which file transfer protocol to use. Using `smb` is recommended for large file transfers. | `Enum[winrm, smb]` | `winrm` |
| **`password`** | Login password.<br>**Required** unless using Kerberos. | `String` | None |
| `port` | Connection port. | `Integer` | `5986`, or `5985` when `ssl: false` |
| `realm` | Kerberos realm (Active Directory domain) to authenticate against. | `String` | None |
| `smb-port` | Connection port when `file-protocol: smb`. | `Integer` | `445` |
| `ssl` | Establish a secure https connection. | `Boolean` | `true` |
| `ssl-verify` | Verify the target's certificate matches the `cacert`. | `Boolean` | `true` |
| `tmpdir` | The directory to upload and execute temporary files on the target. | `String` | None |
| **`user`** | Login user.<br>**Required** unless using Kerberos. | `String` | None |

## Examples

### Setting configuration in the Bolt configuration file

WinRM transport configuration options can be set in a `bolt.yaml` under the `winrm` field.

```yaml
winrm:
  cacert: /path/to/cert/cacert.pem
  user: Administrator
  password: bolt
```

### Setting configuration in an inventory file

WinRM transport configuration options can be set in an inventory file at the group or target level. These options are set under the `winrm` field, which is under the `config` field.

```yaml
targets:
  - uri: target1
    # Target-level configuration
    config:
      winrm:
        extensions: [.py]
# Group-level configuration
config:
  winrm:
    cacert: /path/to/cert/cacert.pem
    user: Administrator
    password: bolt
```