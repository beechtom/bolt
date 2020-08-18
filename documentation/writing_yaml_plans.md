# Writing plans in YAML

YAML plans run a list of steps in order, which allows you to define simple
workflows. Steps can contain embedded Puppet code expressions to add logic where
necessary.

## Naming plans

Plan names are named based on the filename of the plan, the name of the module
containing the plan, and the path to the plan within the module.

Place plan files in your module's `./plans` directory, using these file
extensions:

-   Puppet plans — `.pp`
-   YAML plans — `.yaml`, not `.yml`

Plan names are composed of two or more name segments, indicating:

-   The name of the module the plan is located in.
-   The name of the plan file, without the extension.
-   The path within the module, if the plan is in a subdirectory of `./plans`.

For example, given a module called `mymodule` with a plan defined in
`./mymodule/plans/myplan.pp`, the plan name is `mymodule::myplan`. A plan
defined in `./mymodule/plans/service/myplan.pp`would be
`mymodule::service::myplan`. This name is how you refer to the plan when you run
commands.

The plan filename `init` is special: the plan it defines is referenced using the
module name only. For example, in a module called `mymodule`, the plan defined
in `init.pp` is the `mymodule` plan.

Avoid giving plans the same names as constructs in the Puppet language. Although
plans do not share their namespace with other language constructs, giving plans
these names makes your code difficult to read.

Each plan name segment must begin with a lowercase letter and:

-   May include lowercase letters.
-   May include digits.
-   May include underscores.
-   Must not be a [reserved
    word](https://docs.puppet.com/puppet/5.3/lang_reserved.html).
-   Must not have the same name as any Puppet data types.
-   Namespace segments must match the following regular expression
    `\A[a-z][a-z0-9_]*\Z`


## Plan structure

YAML plans contain a list of steps with optional parameters and results.

YAML maps accept these keys:

-   `steps`: The list of steps to perform
-   `parameters`: (Optional) The parameters accepted by the plan
-   `return`: (Optional) The value to return from the plan

### Steps key

The `steps` key is an array of step objects, each of which corresponds to a
specific action to take.

When the plan runs, each step is executed in order. If a step fails, the plan
halts execution and raises an error containing the result of the step that
failed.

Steps use these fields:

-   `name`: (Optional) A unique name that can be used to refer to the result of
    the step later.
-   `description`: (Optional) An explanation of what the step is doing.

Other available keys depend on the type of step.

#### Message step

Use a `message` step to print a message. This will print a message to `stdout`
when using the `human` output format, and print to `stderr` when using the
`json` output format.

Message steps use a single field:

-   `message`: The message to print

For example:

```yaml
steps:
  - message: hello world
```

#### Command step

Use a `command` step to run a single command on a list of targets and save the
results, containing stdout, stderr, and exit code.

The step fails if the exit code of any command is non-zero.

Command steps use these fields:

-   `command`: The command to run
-   `targets`: A target or list of targets to run the command on

For example:

```yaml
steps:
  - command: hostname -f
    targets:
      - web1.example.com
      - web2.example.com
      - web3.example.com
    description: "Get the webserver hostnames"
```

#### Task step

Use a `task` step to run a Bolt task on a list of targets and save the results.

Task steps use these fields:

-   `task`: The task to run
-   `targets`: A target or list of targets to run the task on
-   `parameters`: (Optional) A map of parameter values to pass to the task

For example:

```yaml
steps:
  - task: package
    targets:
      - web1.example.com
      - web2.example.com
      - web3.example.com
    description: "Check the version of the openssl package on the webservers"
    parameters:
      action: status
      name: openssl
```

#### Script step

Use a `script` step to run a script on a list of targets and save the results.

The script must be in the `files/` directory of a module. The name of the script
must be specified as `<modulename>/path/to/script`, omitting the `files`
directory from the path.

Script steps use these fields:

-   `script`: The script to run
-   `targets`: A target or list of targets to run the script on
-   `arguments`: (Optional) An array of command-line arguments to pass to the
    script

For example:

```yaml
steps:
  - script: mymodule/check_server.sh
    targets:
      - web1.example.com
      - web2.example.com
      - web3.example.com
    description: "Run mymodule/files/check_server.sh on the webservers"
    arguments:
      - "/index.html"
      - 60
```

#### File download step

Use a file download step to download a file or directory from a list of targets
to a destination directory on the local host.

Files and directories are downloaded to the destination directory within a
subdirectory matching the target's URL-encoded safe name. If the destination
directory is a relative path, it will expand relative to the project's
downloads directory, `<project>/downloads`.

File download steps use these fields:

- `download`: The location of the remote file to download
- `destination`: The destination directory to download the file to
- `targets`: A target or list of targets to download the file from

For example:

```yaml
steps:
  - download: /etc/ssh/sshd_config
    destination: sshd_config
    targets:
      - web1.example.com
      - ssh://web2.example.com
      - web3
    description: "Download ssh daemon config from the webservers"
```

If the specified file exists on each of the targets, it would be saved to the
following locations:

- `~/.puppetlabs/bolt/downloads/sshd_config/web1.example.com/sshd_config`
- `~/.puppetlabs/bolt/downloads/sshd_config/ssh%3A%2F%2Fweb2.example.com/sshd_config`
- `~/.puppetlabs/bolt/downloads/sshd_config/web3/sshd_config`

Since files are downloaded to a directory matching the target's safe name, the
target's safe name is URL encoded to ensure it's a valid directory name.

> 🔩 **Tip:** To avoid URL encoding the target's safe name, give the target a
> simple, human-readable name in your inventory file.

#### File upload step

Use a file upload step to upload a file to a specific location on a list of
targets.

The file to upload must be in the `files/` directory of a Puppet module. The
source for the file must be specified as `<modulename>/path/to/file`, omitting
the `files` directory from the path.

File upload steps use these fields:

-   `upload`: The location of the local file to be uploaded
-   `destination`: The remote location to upload the file to
-   `targets`: A target or list of targets to upload the file to

For example:

```yaml
steps:
  - upload: mymodule/motd.txt
    destination: /etc/motd
    targets:
      - web1.example.com
      - web2.example.com
      - web3.example.com
    description: "Upload motd to the webservers"
```

#### Plan step

Use a `plan` step to run another plan and save its result.

Plan steps use these fields:

-   `plan`: The name of the plan to run
-   `parameters`: (Optional) A map of parameter values to pass to the plan

For example:

```yaml
steps:
  - plan: facts
    description: "Gather facts for the webservers using the built-in facts plan"
    parameters:
      targets:
        - web1.example.com
        - web2.example.com
        - web3.example.com
```

#### Resources step

Use a `resources` step to apply a list of Puppet resources. A resource defines
the desired state for part of a target. Bolt ensures each resource is in its
desired state. Like the steps in a `plan`, if any resource in the list fails,
the rest are skipped.

For each `resources` step, Bolt executes the `apply_prep` plan function against
the targets specified with the `targets` field. For more information about
`apply_prep` see the [Applying manifest blocks](applying_manifest_blocks.md#)
section.

Resources steps use these fields:

-   `resources`: An array of resources to apply
-   `targets`: A target or list of targets to apply the resources on

Each resource is a YAML map with a type and title, and optionally a `parameters`
key. The resource type and title can either be specified separately with the
`type` and `title` keys, or can be specified in a single line by using the type
name as a key with the title as its value.

For example:

```yaml
steps:
  - resources:
    # This resource is type 'package' and title 'nginx'
    - package: nginx
      parameters:
        ensure: latest
    # This resource is type 'service' and title 'nginx'
    - type: service
      title: nginx
      parameters:
        ensure: running
    targets:
      - web1.example.com
      - web2.example.com
      - web3.example.com
    description: "Set up nginx on the webservers"
```

### Parameters key

Plans accept parameters with the `parameters` key. The value of `parameters` is
a map, where each key is the name of a parameter and the value is a map
describing the parameter.

Parameter values can be referenced from steps as variables.

Parameters use these fields:

-   `type`: (Optional) A valid [Puppet data
    type](https://puppet.com/docs/puppet/latest/lang_data.html#puppet-data-types).
    The value supplied must match the type or the plan fails.
-   `default`: (Optional) Used if no value is given for the parameter
-   `description`: (Optional)


For example, this plan accepts a `load_balancer` name as a string, two sets of
targets called `frontends` and `backends`, and a `version` string:

```yaml
parameters:
  # A simple parameter definition doesn't need a type or description
  load_balancer:
  frontends:
    type: TargetSpec
    description: "The frontend web servers"
  backends:
    type: TargetSpec
    description: "The backend application servers"
  version:
    type: String
    description: "The new application version to deploy"
```

### How strings are evaluated

The behavior of strings is defined by how they're written in the plan.

`'single-quoted strings'` are treated as string literals without any
interpolation.

`"double-quoted strings"` are treated as Puppet language double-quoted strings
with variable interpolation.

`| block-style strings` are treated as expressions of arbitrary Puppet code.
Note the string itself must be on a new line after the `|` character.

`bare strings` are treated dynamically based on their content. If they begin
with a `$`, they're treated as Puppet code expressions. Otherwise, they're
treated as YAML literals.

Here's an example of different kinds of strings in use:

```yaml
parameters:
  message:
    type: String
    default: "hello"

steps:
  - eval: hello
    description: 'This will evaluate to: hello'
  - eval: $message
    description: 'This will evaluate to: hello'
  - eval: '$message'
    description: 'This will evaluate to: $message'
  - eval: "${message} world"
    description: 'This will evaluate to: hello world'
  - eval: |
      [$message, $message, $message].join(" ")
    description: 'This will evaluate to: hello hello hello'
```

## Using variables and simple expressions

Parameters and step results are available as variables during plan execution,
and they can be used to compute the value for each field of a step.

The simplest way to use a variable is to reference it directly by name. For
example, this plan takes a parameter called `targets` and passes it as the
target list to a step:

```yaml
parameters:
  targets:
    type: TargetSpec

steps:
  - command: hostname -f
    targets: $targets
```

Variables can also be interpolated into string values. The string must be
double-quoted to allow interpolation. For example:

```yaml
parameters:
  username:
    type: String

steps:
  - task: echo
    parameters:
      message: "hello ${username}"
    targets: $targets
```

Many operations can be performed on variables to compute new values for step
parameters or other fields.

### Indexing arrays or hashes

You can retrieve a value from an Array or a Hash using the `[]` operator. This
operator can also be used when interpolating a value inside a string.

```yaml
parameters:
  users:
    # Array[String] is a Puppet data type representing an array of strings
    type: Array[String]

steps:
  - task: user::add
    targets: 'host.example.com'
    parameters:
      name: $users[0]
  - task: echo
    targets: 'host.example.com'
    parameters:
      message: "hello ${users[0]}"
```

### Calling functions

You can call a built-in [Bolt function](plan_functions.md#) or [Puppet
function](https://puppet.com/docs/puppet/latest/function.html) to compute a
value.

```yaml
parameters:
  users:
    type: Array[String]

steps:
  - task: user::add
    parameters:
      name: $users.first
  - task: echo
    message: "hello ${users.join(',')}"
```

### Using code blocks

Some Puppet functions take a block of code as an argument. For instance, you can
filter an array of items based on the result of a block of code.

The result of the `filter` function is an array here, not a string, because the
expression isn't inside quotes.

```yaml
parameters:
  numbers:
    type: Array[Integer]

steps:
  - task: sum
    description: "add up the numbers > 5"
    parameters:
      indexes: $numbers.filter |$num| { $num > 5 }
```

## Connecting steps

You can connect multiple steps by using the result of one step to compute the
parameters for another step.

### `name` key

The `name` key makes its result available to later steps in a variable with that
name.

This example uses the `map` function to get the value of `stdout` from each
command result and then joins them into a single string separated by commas.

```yaml
parameters:
  targets:
    type: TargetSpec

steps:
  - name: hostnames
    command: hostname -f
    targets: $targets
  - task: echo
    parameters:
      message: $hostnames.map |$hostname_result| { $hostname_result['stdout'] }.join(',')
```

### `eval` step

The `eval` step evaluates an expression and saves the result in a variable. This
is useful to compute a variable to use multiple times later.

```yaml
parameters:
  count:
    type: Integer

steps:
  - name: double_count
    eval: $count * 2
  - task: echo
    targets: web1.example.com
    parameters:
      message: "The count is ${count}, and twice the count is ${double_count}"
```

## Returning results

You can return a result from a plan by setting the `return` key at the top level
of the plan. When the plan finishes, the `return` key is evaluated and returned
as the result of the plan. If no `return` key is set, the plan returns `undef`.

```yaml
steps:
  - name: hostnames
    command: hostname -f
    targets: $targets

return: $hostnames.map |$hostname_result| { $hostname_result['stdout'] }
```

## Wrapping scripts

Oftentimes, you may have existing scripts that you use to perform tasks on your
targets. While Bolt is able to run scripts on remote targets, scripts do not
have many of the benefits of tasks and plans, such as parameterizing input or
listing available scripts in the UI. Sometimes it might make sense to convert
your scripts into tasks to get these benefits, but there are many instances
where wrapping your script in a simple YAML plan is just as effective.

The following script, `add_two.py`, is used to calculate the sum from two
numbers passed as arguments to the script:

```python
#!/usr/bin/env python
# myproject/files/add_two.py
import sys

if __name__ == "__main__":
    if len(sys.argv) > 2:
            num1 = long(sys.argv[1])
            num2 = long(sys.argv[2])
    else:
            print "This command takes two arguments and adds them"
            print "Less than two arguments given."
            sys.exit(1)
    print "%s" % str(num1 + num2)
```

We can easily wrap this script in a YAML plan that accepts two parameters and
passes them to the script as arguments.

First, you should place the script in the `files` directory of the module or
Bolt project that you will create the plan in. By placing the script in a module
or project `files` directory, you will be able to easily refer to it from a plan
using the convention `<module_name>/<script_basename>`.

Next, create a plan in the `plans` directory of the module or Bolt project. The
following plan wraps the `add_two.py` script above:

```yaml
# myproject/plans/add_two.yaml
description: Add two numbers together

parameters:
  num1:
    type: Numeric
    description: The first addend
  num2:
    type: Numeric
    description: The second addend
  targets:
    type: TargetSpec
    description: The targets to run the script on
    default: localhost

steps:
  - name: add_two
    script: myproject/add_two.py
    targets: $targets
    arguments:
      - $num1
      - $num2

return: $add_two
```

The `myproject::add_two` plan accepts three parameters. `num1` and `num2` are
the two numbers that will be passed to the script as arguments. `targets` is a
list of targets that we want to run the script on.

This plan executes a single `script` step that runs the script
`myproject/add_two.py` on the list of targets and passes the parameters `num1`
and `num2` as arguments to the script. Arguments listed under the `arguments`
key are passed to the script in order. Once the script runs, its result is
stored in the `add_two` variable. The value of the `add_two` variable is then
returned by the plan, letting you view the output from the script.

By wrapping your script in a plan, you get the benefit of plan metadata, which
adds automatic parameter validation and helpful contextual information for users
who run the script.

Once you have created your plan, you can view its metadata using the
`bolt plan show` command:

```shell
$ bolt plan show myproject::add_two

myproject::add_two - Add two numbers together

USAGE:
bolt plan run myproject::add_two [num1=<value>] [num2=<value>] [targets=<value>]

PARAMETERS:
- num1: Numeric
    The first addend
- num2: Numeric
    The second addend
- targets: TargetSpec
    Default: localhost
    The targets to run the script on

MODULE:
/Users/bolt/.puppetlabs/bolt
```

## Computing complex values

To compute complex values, you can use a Puppet code expression as the value of
any field of a step except the `name`.

Bolt loads the plan as a YAML data structure. As it executes each step, it
evaluates any expressions embedded in the step. Each plan parameter and the
values of every previous named step are available in scope.

This lets you take advantage of the power of Puppet language in the places it's
necessary, while keeping the rest of your plan simple.

When your plans need more sophisticated control flow or error handling beyond
running a list of steps in order, it's time to convert them to [Puppet language
plans](writing_plans.md#).

## Applying Puppet code from Puppet Forge modules

Modules downloaded from the Puppet Forge often include Puppet code that you can
use to simplify your workflow. The Puppet code in these modules can be applied
to targets from a YAML plan using the [resources step](#resources-step).

For example, if you wanted to install and configure Apache and MySQL on a group
of targets, you could download the
[apache](https://forge.puppet.com/puppetlabs/apache) and
[mysql](https://forge.puppet.com/puppetlabs/mysql) modules and apply the
`apache` and `mysql::server` classes to the targets with a resources step. You
can invoke a class as part of a resources step by using the syntax `class:
classname`.

The following YAML plan accepts a list of targets and then installs and
configures Apache and MySQL using classes from the `apache` and `mysql`
modules:

```yaml
description: Install and configure Apache and MySQL

parameters:
  targets:
    type: TargetSpec
    description: The targets to configure

steps:
  - description: Install and configure Apache and MySQL
    name: configure
    targets: $targets
    resources:
      - class: apache
      - class: mysql::server

return: $configure
```

Puppet code included in modules often accepts parameters. To set parameters,
add a map of parameter names and values under the `parameters` key for a
specific resource.

```yaml
- class: apache
  parameters:
    user: apache
    manage_user: false
```

## Converting YAML plans to Puppet language plans

You can convert a YAML plan to a Puppet language plan with the `bolt plan
convert` command.

```
bolt plan convert path/to/my/plan.yaml
```

This command takes the relative or absolute path to the YAML plan to be
converted and prints the converted Puppet language plan to stdout.

**Note:** Converting a YAML plan might result in a Puppet plan which is
syntactically correct, but behaves differently. Always manually verify a
converted Puppet language plan's functionality. There are some constructs that
do not translate from YAML plans to Puppet language plans. These are
[listed](#yaml-plan-constructs-that-cannot-be-translated-to-puppet-plans) below.
If you convert a YAML plan to Puppet and it changes behavior, [file an
issue](https://github.com/puppetlabs/bolt/issues) in Bolt's Git repo.

For example, with this YAML plan:

```yaml
# site-modules/mymodule/plans/yamlplan.yaml
parameters:
  targets:
    type: TargetSpec
steps:
  - name: run_task
    task: sample
    targets: $targets
    parameters:
      message: "hello world"
return: $run_task
```

Run the following conversion:

```console
$ bolt plan convert site-modules/mymodule/plans/yamlplan.yaml
# WARNING: This is an autogenerated plan. It may not behave as expected.
plan mymodule::yamlplan(
  TargetSpec $targets
) {
  $run_task = run_task('sample', $targets, {'message' => "hello world"})
  return $run_task
}
```

## Quirks when converting YAML plans to Puppet language plans

There are some quirks and limitations associated with converting a plan
expressed in YAML to a plan expressed in the Puppet language. In some cases it
is impossible to accurately translate from YAML to Puppet. In others, code that
is generated from the conversion is syntactically correct but not idiomatic
Puppet code.

### Named `eval` step

The `eval` step allows snippets of Puppet code to be expressed in YAML plans.
When converting a multi-line `eval` step to Puppet code and storing the result
in a variable, use the `with` lambda.

For example, here is a YAML plan with a multi-line `eval` step:

```yaml
parameters:
  foo:
    type: Optional[Integer]
    description: foo
    default: 0

steps:
  - eval: |
      $x = $foo + 1
      $x * 2
    name: eval_step

return: $eval_step
```

And here is the same plan, converted to the Puppet language:

```
plan yaml_plans::with_lambda(
  Optional[Integer] $foo = 0
) {
  $eval_step = with() || {
    $x = $foo + 1
    $x * 2
  }

  return $eval_step
}
```

Writing this plan from scratch using the Puppet language, you would probably not
use the lambda. In this example the converted Puppet code is correct, but not as
natural or readable as it could be.

### Resource step variable interpolation

When applying Puppet resources in a `resource` step, variable interpolation
behaves differently in YAML plans and Puppet language plans. To illustrate this
difference, consider this YAML plan:

```yaml
steps:
  - targets: localhost
    description: Apply a file resource
    resources:
    - type: file
      title: '/tmp/foo'
      parameters:
        content: $facts['os']['family']
        ensure: present
  - name: file_contents
    description: Read contents of file managed with file resource
    eval: >
      file::read('/tmp/foo')
      
return: $file_contents

```

This plan performs `apply_prep` on a localhost target. Then it uses a Puppet
`file` resource to write the OS family discovered from the Puppet `$facts` hash
to a temporary file. Finally, it reads the value written to the file and returns
it. Running `bolt plan convert` on this plan produces this Puppet code:

```
plan yaml_plans::interpolation_pp() {
  apply_prep('localhost')
  $interpolation = apply('localhost') {
    file { '/tmp/foo':
      content => $facts['os']['family'],
      ensure => 'present',
    }
  }
  $file_contents = file::read('/tmp/foo')

  return $file_contents
}
```

This Puppet language plan works as expected, whereas the YAML plan it was
converted from fails. The failure stems from the `$facts`variable being resolved
as a plan variable, instead of being evaluated as part of compiling the manifest
code in an `apply`block.

### Dependency order

The resources in a `resources` list are applied in order. It is possible to set
dependencies explicitly, but when doing so you must refer to them in a
particular way. Consider the following YAML plan:

```yaml
parameters:
  targets:
    type: TargetSpec
steps:
  - name: pkg
    targets: $targets
    resources:
      - title: openssh-server
        type: package
        parameters:
          ensure: present
          before: File['/etc/ssh/sshd_config']
      - title: /etc/ssh/sshd_config
        type: file
        parameters:
          ensure: file
          mode: '0600'
          content: ''
          require: Package['openssh-server']
```

Executing this plan fails during catalog compilation because of how Bolt parses
the resources referenced in the `before` and `require` parameters. You will see
the error message `Could not find resource 'File['/etc/ssh/sshd_config']' in
parameter 'before'`. The solution is to not quote the resource titles:

```yaml
parameters:
  targets:
    type: TargetSpec
steps:
  - name: pkg
    targets: $targets
    resources:
      - title: openssh-server
        type: package
        parameters:
          ensure: present
          before: File[/etc/ssh/sshd_config]
      - title: /etc/ssh/sshd_config
        type: file
        parameters:
          ensure: file
          mode: '0600'
          content: ''
          require: Package[openssh-server]
```

In general, declare resources in order. This is an unusual example to illustrate
a case where parameter parsing leads to non-intuitive results.
