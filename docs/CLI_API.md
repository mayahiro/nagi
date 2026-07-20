# Public CLI API guide

[日本語](CLI_API_ja.md)

Nagi CLI provides native Rust and Go APIs with the same observable command
semantics. Both implementations validate a Command Graph, parse platform
argument values into a typed Invocation, execute a Handler through an injected
Context, and return an explicit Exit Status

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
| Child command | `.subcommand(command)` | `.Subcommand(command)` |
| Handler | `.handler(handler)` | `.Handle(handler)` |

Long and short names are explicit. Value options can be required, repeatable,
environment-backed, defaulted, or related through `requires` and `conflicts`

The complete graph is validated before argv is consumed. Invalid names,
reserved built-in spellings, path-wide value ID collisions, sibling alias
collisions, invalid positional order, and cross-command option relations return
an `invalid-specification` Diagnostic

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
fallback sources

Rust retrieves typed values through `Invocation::value` and
`Invocation::values`. Go uses `cli.ValueAs[T]` for the first value or accesses
`ParsedValue.Typed()` when iterating repeated values. A missing or differently
typed ID returns absence rather than coercion

## Runtime

A Handler receives mutable access to injected stdin, stdout, stderr,
environment, current directory, and cooperative cancellation. It returns an
Outcome or a Diagnostic and must not terminate the process

`Command::run` and `Command.Run` execute with a caller-supplied Context. The
process helpers use platform argv, environment, current directory, and standard
I/O, then convert SIGINT into cancellation

- Rust `Command::run_process` temporarily installs and restores its SIGINT handler
- Go `Command.RunProcess` uses `signal.NotifyContext` and always stops notification
- Both helpers return an Exit Status instead of terminating the process

Status 0 means success, 1 general failure, 2 a usage error, and 130 SIGINT
cancellation. Custom statuses are restricted to one byte. Framework I/O
failures are returned to the caller

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

Process integration targets Linux and macOS on x86-64 and ARM64. Parsing and
injected execution do not require a terminal
