# Command applications

Nagi CLI is a native Rust and Go framework for non-interactive command
applications. It is centered on a validated Command Graph, typed Invocation,
injected Context, structured Help and Diagnostic values, and explicit process
policy.

Nagi CLI MUST NOT depend on Nagi Surface or Nagi TUI. It MAY use Nagi Text for
terminal-cell-aware help alignment. Implementations MUST NOT wrap another CLI
framework or argument parser.

## Supported process model

Process integration targets Linux and macOS on x86-64 and ARM64.
Public parsing APIs take arguments after the program name. Process helpers
remove the executable entry from the platform argument list before parsing.

Argument values MUST preserve platform data. Rust uses `OsString`; Go uses a
string as an immutable byte sequence. Command names and option spellings are
ASCII, but option values and positionals are not required to be UTF-8.

## Command Graph

A Command has a stable identifier, canonical name, optional aliases,
description, options, positional arguments, option groups, subcommands,
structured help additions including usage variants, invocation validators, and
an optional handler.

Definitions MUST be rejected before argument parsing when any of the following
is true:

- a stable identifier does not start with an ASCII letter or contains bytes
  other than ASCII letters, digits, hyphens, or underscores;
- a command name, alias, or long option does not start with an ASCII lowercase
  letter or contains bytes other than ASCII lowercase letters, digits, or
  hyphens;
- a short option is not one ASCII alphanumeric byte;
- sibling command stable IDs, names, or aliases overlap;
- option IDs, long names, or short names overlap within a command;
- option and positional value IDs overlap within one command;
- a repeated positional is not the final positional;
- a relation names an option outside its command;
- an option group has an invalid or duplicate ID, contains fewer than two
  distinct options, or names an option outside its command; or
- a usage variant has an invalid or duplicate ID, has an invalid syntax
  suffix, conflicts with a generated usage variant, or is attached to a
  command that requires a subcommand; or
- an application definition uses the reserved `help`, `version`, `h`, or `V`
  option spelling.

Aliases select the canonical command and never appear in the resulting command
path.

## Argument parsing

Parsing starts at the root command and scans arguments from left to right.
Options and positionals MAY be interspersed until `--`. The `--` argument ends
option and subcommand recognition and is not stored. A lone `-` is positional.

Before a positional is consumed, a non-option matching a child name or alias
selects that child. After child selection, only child options are recognized.
Parent and child commands MAY declare the same option spelling and local value
ID; token position selects the command scope. Already parsed parent values
remain in the Invocation. After any positional is consumed, later tokens are
positional even if they match a child name.

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

`--help` and `-h` return help for the currently selected command. `help`
followed by zero or more child command names or aliases returns help for the
canonical target path. `--version` and `-V` return the root name and version
when a root version is configured. Flag actions ignore remaining arguments and
required-value validation. A version option is unknown when the root has no
version. An unknown target after `help` is an `unknown-command` error.

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

An Invocation distinguishes resolved presence from command-line supply.
`contains` reports a value from any source. `supplied` reports whether an
option or positional was present in argv. A default or environment fallback is
not supplied.

Implementations provide raw platform, UTF-8 string, signed 64-bit integer, and
possible-value parsers, plus a language-native custom parser API. Invalid UTF-8
MUST be accepted by the raw parser and rejected by parsers that require text.

## Validation

Required options and positionals accept a resolved value from any source.
Pairwise `requires` and `conflicts` relations declare whether presence means a
resolved value or command-line supply. Existing unqualified relations use
resolved presence.

An option group has a stable ID, one presence basis, two or more local option
IDs, and one of these kinds:

- AtMostOne accepts zero or one present member;
- ExactlyOne accepts exactly one present member;
- AtLeastOne accepts one or more present members; and
- AllOrNone accepts zero members or every member.

Option groups use command-line supply unless another basis is selected.
Unexpected positionals fail rather than being discarded.

Relationship and option-group validation runs after defaults and environment
values have been resolved. Language-native invocation validators run after
portable validation, in root-to-leaf command order. A validator receives the
immutable typed Invocation with the defining command as its current scope and
returns success or a structured Diagnostic. Validators do not run for help or
version actions. Validator predicates are application-defined and are not
portable; their execution phase and returned Diagnostic remain part of the
shared runtime contract.

## Invocation

Invocation contains the canonical command-name path, stable command-ID path,
and one value scope for every command on that path. A value identity is the
pair of a stable command-ID path and a command-local value ID. Option and
positional IDs share one local namespace but MAY be reused by parent and child
commands.

Unqualified lookup starts at the current scope and searches toward the root.
The nearest declaration shadows an ancestor declaration even when the nearer
value was not resolved. A validator uses its defining command as the current
scope. A handler uses the selected leaf command as the current scope.
Applications MAY select an exact scope by stable command-ID path.

Access is typed by option kind and Value Parser result. Looking up a missing or
differently typed value returns absence rather than coercing it.

Definition order MUST NOT affect value lookup. Repeated values preserve command
line order. Implementations also provide a fallible required typed lookup that
distinguishes a missing value from a parser-result type mismatch.

## Diagnostics

A Diagnostic contains a stable code, message, canonical command path, optional
usage text, semantic category, zero or more value targets, and zero or more
ordered hints. Framework codes are:

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
option-group
validation
missing-handler
handler-error
cancelled
io-error
```

Applications MAY use another stable code matching the identifier grammar.
A code outside the framework set has the `execution` category until the
application explicitly assigns another category.

A Diagnostic target identifies an option or positional by stable command-ID
path and command-local value ID. Targets are machine-readable metadata and do
not require the default renderer to expose internal IDs. Hints are
human-readable remediation text.

A Diagnostic also has one semantic category:

```text
specification
usage
execution
cancellation
io
```

A Diagnostic does not choose a process exit code. The default plain renderer
uses this form:

```text
error[CODE]: MESSAGE
hint: HINT
usage: USAGE
```

One `hint:` line is rendered for each hint in insertion order. Hint lines and
the usage line are omitted when unavailable. C0 controls, DEL, and invalid
UTF-8 bytes originating in user input MUST render as uppercase `\xHH` escapes
so a diagnostic cannot inject terminal controls.

## Help and version

Help is first represented as a structured Help Document containing the
canonical command path, description, usage variants and rendered usage lines,
command entries, argument entries, option entries, pairwise option-relation
metadata, option-group metadata, examples, notes, links, and custom sections.
Custom sections have a stable ID, heading, and ordered paragraph or
labeled-entry blocks.

Each Help Usage Variant contains its source stable command-ID path, a
source-local stable ID, a syntax suffix relative to the Help Document command,
and the complete command line. Applications MAY declare one or more ordered
usage variants on a command. The syntax suffix MUST be non-empty valid UTF-8,
MUST NOT start or end with an ASCII space, and MUST NOT contain C0 controls or
DEL. It does not include the Help Document command path. Usage variants are
Help metadata only: they do not change parsing, Diagnostic usage, portable or
application Invocation validation, or Invocation values.

When a command has no declared usage variants, the Help Document contains a
generated `default` variant based on its options, positionals, and required
subcommand. Declared variants replace that generated direct-invocation
variant. A command chooses one subcommand-usage presentation:

- `auto` adds a generated parent-local `subcommand` variant after direct
  variants when subcommands are optional;
- `hidden` does not add an optional-subcommand variant; and
- `expanded` replaces generic subcommand syntax with each immediate child's
  direct variants in child and variant definition order.

For a command requiring a subcommand, `expanded` omits the generic generated
parent form and emits only immediate child forms. Child expansion is shallow;
a child's direct generated form may itself contain `<COMMAND>`. A declared
parent-local `subcommand` ID conflicts with the generated `auto` variant. A
command that requires a subcommand cannot declare parent-local usage variants.

Standard command, argument, and option entries retain their stable definition
IDs independently of rendered labels. Option-group metadata retains stable
member IDs and display labels so a renderer or machine consumer does not need
to parse presentation text.

Pairwise option-relation metadata retains requires or conflicts behavior,
source and target stable IDs, display labels, and the presence basis.

Help sections appear in this order when non-empty: description, Usage,
Commands, Arguments, Options, Constraints, Examples, Notes, Links, then custom
sections in definition order. Constraints list pairwise relations in option
definition order followed by option groups in definition order. Entries
preserve definition order. Labels are aligned by Nagi Text Modern terminal-cell
width. Help always lists its built-in option; version is listed only when
configured at the root. Root help lists the built-in `help` command when
application subcommands exist.

The default renderer is deterministic. Applications MAY provide another Help
renderer without changing the Help Document. Raw or application-specific Help
content belongs in an explicit custom section rather than changing parser
semantics.

Help and version are written to stdout with one final newline. Diagnostics are
written to stderr.

## Execution

A Context injects stdin, stdout, stderr, environment, current directory, and a
cooperative cancellation source. A Handler receives mutable Context access and
an immutable Invocation. Handlers MUST NOT terminate the process directly.

Exit Status is explicit and restricted to 0 through 255. The default exit-code
policy maps semantic outcomes as follows:

- success to 0;
- specification and usage diagnostics to 2;
- execution and I/O diagnostics to 1; and
- SIGINT cancellation to 130.

Applications MAY provide another category-to-status mapping, Help renderer, or
Diagnostic renderer through runtime policy. Policy exposes pure Help
rendering, Diagnostic rendering, and Diagnostic-to-status mapping so
applications can reuse it without adopting process execution. Policy does not
change parsing, validation, Diagnostic codes, categories, or the typed
Invocation. The existing runtime entry point uses the default policy.

Applications MAY execute an already parsed Parse Result or validated
Invocation through the registered handler. This separates dispatch from I/O
and enables command-by-command adoption inside an existing CLI. The combined
runtime entry point remains a convenience over parsing and parsed execution.
Parsed execution MUST reject a Parse Result or Invocation whose canonical
command path and stable command-ID path do not identify the receiving Command
Graph.

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
