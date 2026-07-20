# Command applications

Nagi CLI is a native Rust and Go framework for non-interactive command
applications. It is centered on a validated Command Graph, typed Invocation,
injected Context, structured Diagnostic, and explicit Exit Status.

Nagi CLI MUST NOT depend on Nagi Surface or Nagi TUI. It MAY use Nagi Text for
terminal-cell-aware help alignment. Implementations MUST NOT wrap another CLI
framework or argument parser.

## Supported process model

The v0.2.0 process integration targets Linux and macOS on x86-64 and ARM64.
Public parsing APIs take arguments after the program name. Process helpers
remove the executable entry from the platform argument list before parsing.

Argument values MUST preserve platform data. Rust uses `OsString`; Go uses a
string as an immutable byte sequence. Command names and option spellings are
ASCII, but option values and positionals are not required to be UTF-8.

## Command Graph

A Command has a stable identifier, canonical name, optional aliases,
description, options, positional arguments, subcommands, and an optional
handler.

Definitions MUST be rejected before argument parsing when any of the following
is true:

- a stable identifier does not start with an ASCII letter or contains bytes
  other than ASCII letters, digits, hyphens, or underscores;
- a command name, alias, or long option does not start with an ASCII lowercase
  letter or contains bytes other than ASCII lowercase letters, digits, or
  hyphens;
- a short option is not one ASCII alphanumeric byte;
- sibling command names or aliases overlap;
- option IDs, long names, or short names overlap within a command;
- value IDs overlap along one active command path;
- a repeated positional is not the final positional;
- a relation names an option outside its command; or
- an application definition uses the reserved `help`, `version`, `h`, or `V`
  option spelling.

Aliases select the canonical command and never appear in the resulting command
path.

## Argument parsing

Parsing starts at the root command and scans arguments from left to right.
Options and positionals MAY be interspersed until `--`. The `--` argument ends
option and subcommand recognition and is not stored. A lone `-` is positional.

Before a positional is consumed, a non-option matching a child name or alias
selects that child. After child selection, only child options are recognized;
already parsed parent values remain in the Invocation. After any positional is
consumed, later tokens are positional even if they match a child name.

If a command has children but no positionals, an unrecognized non-option is an
`unknown-command` error. If a command requires a child and none is selected,
parsing fails with `missing-subcommand`.

### Long options

Long options use `--name` or `--name=value`. Names are exact and are never
abbreviated or case-folded. A Value option consumes its attached value or the
next complete argument. The next argument is consumed even when it starts with
a hyphen. Flag and Count options reject attached values.

### Short options

Short options use one hyphen and MAY be clustered. Flag and Count options
continue through a cluster. A Value option consumes the remainder of its
cluster, or the next complete argument when no remainder exists. The Value
option ends cluster processing.

### Built-in actions

`--help` and `-h` return help for the currently selected command. `--version`
and `-V` return the root name and version when a root version is configured.
These actions ignore remaining arguments and required-value validation. A
version option is unknown when the root has no version.

## Options and values

An option has one of three kinds:

- Flag records Boolean presence and rejects duplicates;
- Count records an overflow-safe number of occurrences; and
- Value records one value, or multiple values when explicitly repeatable.

A positional records one value or, for the final positional only, multiple
values. Non-repeatable Value options reject duplicates.

Each stored value includes its raw platform value, parsed typed value, and one
of these sources:

1. CommandLine
2. Environment
3. Default

CommandLine has highest precedence, followed by Environment and Default. One
or more command-line values suppress the environment and default values for
that ID.

Implementations provide raw platform, UTF-8 string, signed 64-bit integer, and
possible-value parsers, plus a language-native custom parser API. Invalid UTF-8
MUST be accepted by the raw parser and rejected by parsers that require text.

## Validation

Required options and positionals accept a value from any source. `requires` is
checked only when its source option is present. `conflicts` fails when both
options are present. Unexpected positionals fail rather than being discarded.

Relationship validation runs after defaults and environment values have been
resolved.

## Invocation

Invocation contains the canonical command path and values for every command on
that path. Access is typed by option kind and Value Parser result. Looking up a
missing or differently typed value returns absence rather than coercing it.

Definition order MUST NOT affect value lookup. Repeated values preserve command
line order.

## Diagnostics

A Diagnostic contains a stable code, message, canonical command path, optional
usage text, and Exit Status. The v0.2.0 codes are:

```text
invalid-specification
unknown-option
unexpected-option-value
missing-option-value
duplicate-option
unknown-command
missing-subcommand
unexpected-argument
missing-required
invalid-value
requires
conflicts
missing-handler
handler-error
cancelled
io-error
```

Plain rendering is:

```text
error[CODE]: MESSAGE
usage: USAGE
```

The usage line is omitted when unavailable. C0 controls, DEL, and invalid UTF-8
bytes originating in user input MUST render as uppercase `\xHH` escapes so a
diagnostic cannot inject terminal controls.

## Help and version

Help sections appear in this order when non-empty: description, Usage,
Commands, Arguments, Options. Entries preserve definition order. Labels are
aligned by Nagi Text Modern terminal-cell width. Help always lists its built-in
option; version is listed only when configured at the root.

Help and version are written to stdout with one final newline. Diagnostics are
written to stderr.

## Execution

A Context injects stdin, stdout, stderr, environment, current directory, and a
cooperative cancellation source. A Handler receives mutable Context access and
an immutable Invocation. Handlers MUST NOT terminate the process directly.

Exit Status is explicit and restricted to 0 through 255:

- 0 for success;
- 1 for general failure;
- 2 for parsing or usage failure; and
- 130 for SIGINT cancellation.

Library execution returns I/O failures to its caller. Process helpers convert
SIGINT into cancellation, restore signal handling when execution ends, and
return an Exit Status for `main` to use.

## Test driver

Nagi CLI Test injects argv, stdin bytes, environment, current directory, and
manual cancellation. It captures stdout, stderr, and Exit Status without
starting a process or installing a signal handler. It is built only from public
Nagi CLI APIs.

## Conformance fixtures

Rust and Go read the same `nagi-fixture-v1` suites under `fixtures/cli`.
Fixture values use canonical escapes, and expected raw values use uppercase
hexadecimal so invalid UTF-8 remains comparable.
