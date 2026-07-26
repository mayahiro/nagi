# Public CLI API guide

[日本語](CLI_API_ja.md)

Nagi CLI provides native Rust and Go APIs with the same observable command
semantics. Both implementations validate a Command Graph, parse platform
argument values into a typed Invocation, execute a Handler through an injected
Context, build structured Help and Diagnostics, and return an explicit Exit
Status through a configurable Runtime Policy

The language-neutral [command application specification](../spec/cli.md) is
the public behavioral contract. Shared fixtures under `fixtures/cli` verify
parsing, diagnostics, help, runtime output, cancellation, and byte preservation

## Packages

| Responsibility | Rust | Go |
| --- | --- | --- |
| Command graph, parser, and runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` package `cli` |
| Process-free application tests | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |
| Help label width | `nagi-text` | `github.com/mayahiro/nagi-go/text` |

Nagi CLI does not depend on Nagi Surface, Nagi TUI, or a third-party CLI
framework

## Defining a command

Commands, options, and positionals use language-native builders

| Purpose | Rust | Go |
| --- | --- | --- |
| Command | `Command::new("name")` | `cli.NewCommand("name")` |
| Flag | `OptionSpec::flag("id")` | `cli.Flag("id")` |
| Count | `OptionSpec::count("id")` | `cli.Count("id")` |
| Value option | `OptionSpec::value("id")` | `cli.ValueOption("id")` |
| Positional | `Argument::new("id")` | `cli.Positional("id")` |
| Option group | `OptionGroup::exactly_one(...)` | `cli.ExactlyOne(...)` |
| Child command | `.subcommand(command)` | `.Subcommand(command)` |
| Typed validator | `.validator(validator)` | `.Validator(validator)` |
| Help example | `.example(name, invocation)` | `.Example(name, invocation)` |
| Help note | `.note(text)` | `.Note(text)` |
| Help link | `.link(label, url)` | `.Link(label, url)` |
| Custom Help section | `HelpSection::new(...)` | `cli.NewHelpSection(...)` |
| Handler | `.handler(handler)` | `.Handle(handler)` |

Long and short names are explicit. Value options can be required, repeatable,
environment-backed, defaulted, or related through `requires` and `conflicts`.
Relations can inspect resolved presence or command-line presence

Portable option groups express `at-most-one`, `exactly-one`, `at-least-one`,
and `all-or-none` cardinality over options on one command. Groups inspect
command-line presence by default so a defaulted option does not appear to have
been explicitly supplied. Application-specific typed validators run after
parsing, fallback resolution, and portable validation

The complete graph is validated before argv is consumed. Invalid names,
reserved built-in spellings, path-wide value ID collisions, sibling alias
collisions, invalid positional order, malformed groups, and cross-command
option relations return an `invalid-specification` Diagnostic

## Parsing and typed values

Public parse methods receive arguments after the program name. Rust preserves
each raw value as `OsString`; Go preserves its bytes in a string. Use the raw
parser when invalid UTF-8 must remain accepted

| Parser | Rust | Go |
| --- | --- | --- |
| Raw platform value | `raw_parser()` | `cli.RawParser()` |
| UTF-8 string | `string_parser()` | `cli.StringParser()` |
| Signed 64-bit integer | `integer_parser()` | `cli.IntegerParser()` |
| Finite values | `possible_values_parser(...)` | `cli.PossibleValuesParser(...)` |
| Custom typed value | `value_parser(...)` | `cli.CustomParser(...)` |

An Invocation contains the canonical command path and all values from commands
on that path. Each parsed value records whether it came from the command line,
environment, or default. Command-line values take precedence over both
fallback sources. `Invocation::contains` and `Invocation.Contains` report
resolved presence, while `Invocation::supplied` and `Invocation.Supplied`
report whether argv supplied the ID

Rust retrieves typed values through `Invocation::value` and
`Invocation::values`. Go uses `cli.ValueAs[T]` for the first value or accesses
`ParsedValue.Typed()` when iterating repeated values. A missing or differently
typed ID returns absence rather than coercion

## Structured Help

`Command::help_document` and `Command.HelpDocument` return a renderer-independent
Help Document. It contains the canonical command path, generated usage,
commands, arguments, options, option-relation and option-group constraints,
named examples, notes, links, and application-defined structured sections.
Standard entries and relation and group members retain stable IDs separately
from display labels

The default plain renderer preserves definition order and aligns labels by
terminal Cell width. Applications can install a custom Help Renderer through
the Runtime Policy without replacing parsing or validation

In addition to `-h` and `--help`, roots with subcommands provide
`help [COMMAND...]`. Nested aliases are accepted and the selected command is
reported by its canonical path

## Runtime

A Handler receives mutable access to injected stdin, stdout, stderr,
environment, current directory, and cooperative cancellation. It returns an
Outcome or a Diagnostic and must not terminate the process

`Command::run` and `Command.Run` execute with the default Runtime Policy.
`Command::run_with_policy` and `Command.RunWithPolicy` execute with a
caller-supplied policy. The process helpers use platform argv, environment,
current directory, and standard I/O, then convert SIGINT into cancellation

- Rust `Command::run_process` temporarily installs and restores its SIGINT handler
- Go `Command.RunProcess` uses `signal.NotifyContext` and always stops notification
- Both helpers return an Exit Status instead of terminating the process

Diagnostics carry a semantic category independently of process status:
`specification`, `usage`, `execution`, `cancellation`, or `io`. The default
Exit Code Policy maps specification and usage to 2, execution and I/O to 1,
and cancellation to 130. Applications can remap categories, for example usage
to status 1, without changing Diagnostic meaning

The Runtime Policy also selects the Help Renderer and Diagnostic Renderer. The
plain Diagnostic Renderer can change its prefix and whether usage is included.
Custom statuses are restricted to one byte. Framework I/O failures are
returned to the caller

Help and version go to stdout. Diagnostics go to stderr. User-originated C0,
DEL, and invalid UTF-8 bytes are rendered as uppercase `\xHH` escapes to prevent
terminal-control injection

## Testing applications

The CLI test packages build entirely on public runtime APIs. They inject argv,
stdin bytes, environment, current directory, and manual cancellation, then
capture stdout, stderr, and Exit Status without a child process or signal
handler

| Operation | Rust | Go |
| --- | --- | --- |
| Construct driver | `TestDriver::new(command)` | `clitest.New(command)` |
| Arguments | `.arguments(...)` | `.Arguments(...)` |
| Standard input | `.stdin(...)` | `.Stdin(...)` |
| Environment | `.environment(...)` | `.Environment(...)` |
| Current directory | `.current_directory(...)` | `.CurrentDirectory(...)` |
| Pre-cancel | `.cancelled(true)` | `.Cancelled(true)` |
| Runtime Policy | `.policy(...)` | `.Policy(...)` |
| Run | `.run()` | `.Run()` |

Use the [Rust basic example](../nagi-rs/crates/nagi-cli/examples/basic.rs),
[Rust subcommand example](../nagi-rs/crates/nagi-cli/examples/subcommands.rs),
[Go basic example](../nagicli-go/examples/basic/main.go), and
[Go subcommand example](../nagicli-go/examples/subcommands/main.go) as complete
entry points

## Limitations

The core does not load configuration files, generate shell completions, run
interactive prompts, or integrate a TUI. Long-running handlers must poll their
injected cancellation source and stop cooperatively

The portable graph does not model arbitrary invocation grammars or
parser-generator productions. Use option groups and typed validators for
bounded application rules; keep command-specific parsing outside the portable
specification when those mechanisms are insufficient

Process integration targets Linux and macOS on x86-64 and ARM64. Parsing and
injected execution do not require a terminal
