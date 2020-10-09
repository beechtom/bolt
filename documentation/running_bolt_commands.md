# Running commands

## Command syntax

### Shell commands

Bolt shell commands follow a noun-verb convention. To view a full list of
available commands, use the `bolt help` command:

```shell
bolt help
```

📖 **Related information**

- [Bolt command reference](bolt_command_reference.md)

### PowerShell cmdlets

If you're running Bolt from a Windows controller, you can use PowerShell
cmdlets to run Bolt commands. The PowerShell cmdlets are defined in a
PowerShell module that ships with Bolt. Each cmdlet follows verb-noun
conventions.

To view a full list of available PowerShell cmdlets, use the `Get-Command`
cmdlet:

```powershell
Get-Command -Module PuppetBolt
```

## Specifying targets

Many of Bolt's commands are used to connect to remote targets and execute
actions on them. There are several ways that you can specify targets for a
command, from listing them on the command line to reusing targets from the
previous Bolt command.

The most common way to specify targets on the command line is with the
`targets` option. This option accepts a comma-separated list of targets.

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets bolt1.example.org,bolt2.example.org
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets bolt1.example.org,bolt2.example.org
  ```

If you have an inventory file, you can list targets and groups of targets by
name instead of using the target's Universal Resource Identifier (URI).

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets servers,databases
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets servers,databases
  ```

Bolt supports glob matches for targets. This is helpful when you have several
targets that you want to run a comand on that have similar names. For example,
to run a command on all targets that start with the word `bolt`:

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets 'bolt*'
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets 'bolt*'
  ```

### Reading targets from a file

To read a file of targets, pass an `@` symbol, followed by the relative path to
the file, to the `targets` option.

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets '@targets.txt'
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets '@targets.txt'
  ```

  > **Note:** In PowerShell, always wrap the file name in single quotes.

### Reading targets from standard input (stdin)

To read a list of targets from stdin, pipe the results from another command to
Bolt and pass a single dash (`-`) to the `targets` option.

- _\*nix shell command_

  ```shell
  cat targets.txt | bolt command run 'pwd' --targets -
  ```

Reading from `stdin` is not supported by the PowerShell module.

### Specifying targets from the previous command

After every execution, Bolt writes information about the result of that run to a
`.rerun.json` file inside the Bolt project directory. You can use the
`.rerun.json` file together with the `rerun` option to specify targets for
future commands. The `rerun` option accepts one of three values:

- `success`: The list of targets the command succeeded on.
- `failure`: The list of targets the command failed on.
- `all`: All of the targets the command ran on.

For example, if you need to run a command that is dependent on the success of
the previous command, you can target the successful targets with the `success`
value.

- _\*nix shell command_

  ```shell
  bolt task run restart_server --targets servers --rerun success
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltTask -Name restart_server -Targets servers -Rerun success
  ```

Sometimes, you may want to preserve the results from a previous run so you can
specify targets with the `rerun` option multiple times. To prevent the
`.rerun.json` from being overwritten, you can disable saving the rerun file.

- _\*nix shell command_

  Use the `--no-save-rerun` option to disable saving the rerun file:

  ```shell
  bolt task run restart_server --targets server --rerun success --no-save-rerun
  ```

- _PowerShell cmdlet_

  Use the `-SaveRerun` argument with a value of `$false` to disable saving the
  rerun file:

  ```powershell
  Invoke-BoltTask -Name restart_server -Targets servers -Rerun success -SaveRerun:$false
  ```

## Specifying connection credentials

To establish connections with remote targets, Bolt needs to provide credentials
to the target. You can provide credentials at the command line or in an
inventory file, and the credentials you provide might vary based on the
operating system the target is running.

Whether a target is running a Unix-like operating system or Windows, the
simplest way to specify credentials is to pass the `user` and `password`
to the Bolt command:

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets servers --user bolt --password puppet
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets servers -User bolt -Password puppet
  ```

If youdd prefer to have Bolt securely prompt for a password, so that it does not
appear in a process listing or on the console, use the `password-prompt` option
instead:

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets servers --user bolt --password-prompt
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'pwd' -Targets servers -User bolt -PasswordPrompt
  ```

## Specifying a transport

Bolt uses a specific transport to establish a connection with a target. By
default, Bolt connects to targets using the `ssh` transport. You can use one of
the methods below to set a different transport from the command line, or you can
configure transports in your inventory file.

You can specify the transport used to connect to a specific target by setting
it as the protocol in the target's URI:

- _\*nix shell command_

  ```shell
  bolt command run 'Get-Location' --targets winrm://windows.example.org
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'Get-Location' -Targets winrm://windows.example.org
  ```

You can also use the `transport` command-line option:

- _\*nix shell command_

  ```shell
  bolt command run 'Get-Location' --targets windows.example.org --transport winrm
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'Get-Location' -Targets windows.example.org -Transport winrm
  ```

📖 **Related information**

- [Bolt transports reference](bolt_transports_reference.md)

## Interacting with remote targets

Most of the commands you will run with Bolt are used to connect to remote
targets and perform actions on them. These actions range in complexity from
invoking a simple command to running a series of commands and tasks as part of
an orchestration workflow.

### Running a command

Bolt can run arbitrary commands on remote targets. To run a command, provide a
command and a list of targets to run the command on.

- _\*nix shell command_

  ```shell
  bolt command run 'pwd' --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command 'Get-Location' -Targets servers
  ```

> 🔩 **Tip:** If a command contains spaces or special shell characters, wrap
> the command in single quotation marks.

You can also read a command from a file and run it on a list of targets. This
can be helpful if you need to run a script on a target that does not permit file
uploads. To read a command from a file, pass an `@` symbol, followed by the
relative path to the file

- _\*nix shell command_

  ```shell
  bolt command run @configure.sh --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltCommand -Command '@configure.ps1' -Targets servers
  ```

  > **Note:** In PowerShell, always wrap the file name in single quotes.

You can also read a command from `stdin`. To read a command from `stdin`,
pipe the results from another command to Bolt and pass a single dash `-`
as the command.

- _\*nix shell command_

  ```shell
  cat command.sh | bolt command run - --targets servers
  ```

> **Note:** Reading from `stdin` is not supported by the PowerShell module.

### Running a script

Bolt can run a script on remote targets. When you run a script on a remote
target, Bolt copies the script from your controller to a temporary directory on
the target, runs the script, and then deletes the script from the target.

You can run scripts in any language, as long as the appropriate interpreter is
installed on the remote system. This includes scripting languages such as Bash,
PowerShell, Python, and Ruby.

To run a script, provide the path to the script on the controller and a list of
targets to run the script on.

- _\*nix shell command_

  ```shell
  bolt script run ./scripts/configure.sh --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltScript -Script ./scripts/configure.ps1 -Targets servers
  ```

You can also pass arguments to a script. Argument values are passed literally
and are not interpolated by the shell on the remote host.

- _\*nix shell command_

  To pass arguments to a script, specify them after the command:

  ```shell
  bolt script run ./scripts/configure.sh --targets servers arg1 arg2
  ```

- _PowerShell cmdlet_

  To pass arguments to a script, use the `-Arguments` parameter:

  ```powershell
  Invoke-BoltScript -Script ./scripts/configure.sh -Targets servers -Arguments arg1 arg2
  ```

> 🔩 **Tip:** If an argument contains spaces or special characters, wrap them
> in single quotes.

Depending on a target's operating system, there are additional requirements for
running scripts:

- Scripts run on Unix-like targets must include a shebang line specifying the
  interpreter. For example, a Bash script should provide the path to the Bash
  interpreter:

  ```bash
  #!/bin/bash
  echo hello
  ```

- For Windows targets, you might need to enable file extensions. By default,
  Windows targets support the extensions `.ps1`, `.rb`, and `.pp`. To add
  additional file extensions, add them to the `winrm` configuration section of
  your inventory file:

  ```yaml
  # inventory.yaml
  config:
    winrm:
      extensions:
        - .py
        - .pl
  ```

### Running a task

Tasks are single actions that you can execute on a target. They are similar
to scripts, but have metadata, accept structured input, and return structured
output. You can write tasks that are specific to your project or download
modules from the Puppet Forge that include tasks.

To run a task, provide the name of the task and a list of targets to run the
task on.

- _\*nix shell command_

  ```shell
  bolt task run facts --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltTask -Name facts -Targets servers
  ```

If a task accepts parameters, you can pass them to Bolt as part of the command.

- _\*nix shell command_

  To pass parameters to a task, add parameter declarations of the form
  `parameter=value` to the command:

  ```shell
  bolt task run package action=status name=apache2 --targets servers
  ```

- _PowerShell cmdlet_

  To pass parameters to a task, add an object with parameter declarations to
  the command:

  ```powershell
  Invoke-BoltTask -Name package -Targets servers -Params @{action='status';name='apache2'}
  ```

📖 **Related information**

- [Running tasks](bolt_running_tasks.md)
- [Writing tasks](writing_tasks.md)
- [Installing modules](bolt_installing_modules.md)

### Running a plan

Plans are sets of tasks and commands that can be combined with other logic. They
allow you to do complex operations, such as running multiple tasks with one
command, computing values for the input for a task, or running certain tasks
based on the results of another task. Similar to tasks, you can write plans that
are specific to your project or download modules from the Puppet Forge that
include plans.

To run a plan, provide the name of the plan.

- _\*nix shell command_

  ```shell
  bolt plan run myplan
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltPlan -Name myplan
  ```

If a plan accepts parameters, you can pass them to Bolt as part of the command.

- _\*nix shell command_

  To pass parameters to a plan, add parameter declarations of the form
  `parameter=value` to the command:

  ```shell
  bolt plan run reboot targets=servers
  ```

- _PowerShell cmdlet_

  To pass parameters to a task, add an object with parameter declarations to
  the command:

  ```powershell
  Invoke-BoltTask -Name reboot -Params @{targets='servers'}
  ```

If a plan accepts a `targets` parameter with the type `TargetSpec`, you can
use the `targets` command-line option to provide a value to the parameter.

  - _\*nix shell command_

    ```shell
    bolt task run reboot --targets servers
    ```

  - _PowerShell cmdlet_

    ```powershell
    Invoke-BoltPlan -Name reboot -Targets servers
    ```

📖 **Related information**

- [Running plans](bolt_running_plans.md)
- [Writing YAML plans](writing_yaml_plans.md)
- [Writing plans in the Puppet language](writing_plans.md)
- [Installing modules](bolt_installing_modules.md)

### Uploading a file or directory

Bolt can copy files and directories from your controller to remote targets. To
upload a file or directory, provide the `source` path on your controller, the
`destination` path on the remote target that it should be copied to, and a
list of targets.

Both the `source` and `destination` accept absolute and relative paths. If you
provide a relative path as the `destination`, Bolt will copy the file relative
to the current working directory on the target. Typically, the current working
directory for the target is the log-in user's home directory.

- _\*nix shell command_

  ```shell
  bolt file upload /path/to/source /path/to/destination --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Send-BoltFile -Source /path/to/source -Destination /path/to/destination -Targets servers
  ```

### Downloading a file or directory

Bolt can copy files and directories from remote targets to a destination
directory on your controller. To download a file or directory, provide the
`source` path on the remote target, the path to the `destination` directory on
the controller, and a list of targets.

Both the `source` and `destination` accept absolute and relative paths. If you
provide a relative path as the `source`, Bolt will copy the file relative to the
current working directory on the target. Typically, the current working
directory for the target is the log-in user's home directory.

- _\*nix shell command_

  ```shell
  bolt file download /path/to/source /path/to/destination --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Receive-BoltFile -Source /path/to/source -Destination /path/to/destination -Targets servers
  ```

The `destination` on the controller is a path to a directory that the downloaded
file or directory is copied to. If the `destination` directory does not exist,
Bolt will create it for you.

Bolt saves each file or directory it downloads to a subdirectory of the
`destination` directory that matches the URL-encoded name of the target it was
downloaded from. The target directory names are URL-encoded to ensure that they
are valid directory names.

For example, the following command downloads the SSH daemon configuration file from
two targets, `linux` and `ssh://example.com`, saving it to the destination
directory `sshd_config`:

- _\*nix shell command_

  ```shell
  bolt file download /etc/ssh/sshd_config sshd_config --targets linux,ssh://example.com
  ```

- _PowerShell cmdlet_

  ```powershell
  Receive-BoltFile -Source /etc/ssh/sshd_config -Destination sshd_config -Targets linux,ssh://example.com
  ```

After running this command from the root of your project directory, your project
directory structure would look similar to this:

```shell
.
├── bolt-project.yaml
├── inventory.yaml
└── sshd_config/
    ├── linux/
    │   └── sshd_config
    └── ssh%3A%2F%2Fexample.com/
        └── sshd_config
```

> 🔩 **Tip:** To avoid creating directories with special characters, give your
> targets a simple, human-readable name.

### Applying Puppet code

You can directly apply Puppet manifest code to your targets. To apply Puppet
manifest code to a target, provide the path to the manifest file and a list
of targets.

The Puppet Agent package needs to be installed on the target for the manifest
code to be run. When you apply Puppet manifest code, Bolt ensures that the
Puppet Agent package is installed on the target.

- _\*nix shell command_

  ```shell
  bolt apply manifests/servers.pp --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltApply -Manifest manifests/servers.pp -Targets servers
  ```

You can also apply Puppet code directly to your targets, without the need
for writing it to a file first. To apply Puppet code directly to a target,
use the `execute` command-line option.

- _\*nix shell command_

  ```shell
  bolt apply --execute "file { '/etc/puppetlabs': ensure => present }" --targets servers
  ```

- _PowerShell cmdlet_

  ```powershell
  Invoke-BoltApply -Execute "file { '/etc/puppetlabs': ensure => present}" -Targets servers
  ```

📖 **Related information**

- [Applying Puppet code](applying_manifest_blocks.md)
