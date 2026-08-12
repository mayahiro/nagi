# Public CLI API guide

[日本語](CLI_API_ja.md)

Nagi CLI provides native Rust and Go APIs with the same observable command
semantics. Both implementations validate a Command Graph, parse platform
argument values into a typed Invocation, execute a Handler through an injected
Context, build structured Help and Diagnostics, and return an explicit Exit
Status through a configurable Runtime Policy

The language-neutral [command application specification](../spec/cli.md) is
the public behavioral contract. Shared fixtures under `fixtures/cli` verify
parsing, completion, diagnostics, Help, runtime output, cancellation, and byte
preservation

## Packages

| Responsibility | Rust | Go |
| --- | --- | --- |
| Command graph, parser, and runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` package `cli` |
| Shell completion generation and protocol | `nagi-cli-completion` | `github.com/mayahiro/nagicli-go/completion` |
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
| Inherited option | `.inherited()` | `.Inherited()` |
| Positional | `Argument::new("id")` | `cli.Positional("id")` |
| Option group | `OptionGroup::exactly_one(...)` | `cli.ExactlyOne(...)` |
| Child command | `.subcommand(command)` | `.Subcommand(command)` |
| Dynamic value completion | `.completion_provider(provider)` | `.CompletionProvider(provider)` |
| Typed validator | `.validator(validator)` | `.Validator(validator)` |
| Help Usage Variant | `.usage_variant(id, syntax)` | `.UsageVariant(id, syntax)` |
| Help example | `.example(name, invocation)` | `.Example(name, invocation)` |
| Help note | `.note(text)` | `.Note(text)` |
| Help link | `.link(label, url)` | `.Link(label, url)` |
| Custom Help section | `HelpSection::new(...)` | `cli.NewHelpSection(...)` |
| Handler | `.handler(handler)` | `.Handle(handler)` |

Long and short names are explicit. Options are command-local by default.
Marking an option inherited makes it visible in its declaring command and
every selected descendant, before or after subcommand selection and
positionals until `--`. Value options can be required, repeatable,
environment-backed, defaulted, or related through `requires` and `conflicts`.
Relations can inspect resolved presence or command-line presence and remain
local to the command that declares them

Portable option groups express `at-most-one`, `exactly-one`, `at-least-one`,
and `all-or-none` cardinality over options on one command. Groups inspect
command-line presence by default so a defaulted option does not appear to have
been explicitly supplied. Application-specific typed validators run after
parsing, fallback resolution, and portable validation. Rust validators return
`Result<(), Diagnostic>`. Go validators return `*Diagnostic`, where `nil`
accepts the Invocation. Returning a structured Diagnostic preserves the
application code, semantic category, targets, and hints without
renderer-specific conversion

The complete graph is validated before argv is consumed. Invalid names,
reserved built-in spellings, local option and positional ID collisions, sibling
alias collisions, invalid positional order, malformed groups, and
cross-command option relations return an `invalid-specification` Diagnostic.
Parent and child commands may reuse the same value ID. They may also reuse an
option spelling when the ancestor declaration is local. A descendant cannot
reuse a visible inherited spelling, while unrelated branches remain independent

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

An Invocation contains a canonical command-name path, a stable command-ID path,
and one value scope for every selected command. The complete identity of a
value is its stable command-ID path plus its command-local value ID. This lets
a large command tree use local IDs such as `session` or `output` consistently
without encoding command names into every ID

Unqualified lookup starts at the current scope and searches toward the root.
The nearest declaration shadows an ancestor declaration even when the nearer
declaration has no resolved value. A validator's current scope is the command
that declared it. A handler's current scope is the selected leaf command.
Use `Invocation::scope` or `Invocation.Scope` with a stable command-ID path for
exact access to a parent or another selected scope. `Invocation::scopes` and
`Invocation.Scopes` enumerate all selected scopes in root-to-leaf order

Every inherited-option occurrence is stored in the scope that declared it,
including occurrences after a descendant was selected. Duplicate checks and
repeated-value ordering therefore span both argv positions. A parse or
validation Diagnostic targets the declaration's stable command-ID path while
retaining the selected command path and usage

Each parsed value records whether it came from the command line, environment,
or default. Command-line values take precedence over both fallback sources.
`Invocation::contains` and `Invocation.Contains` report resolved presence,
while `Invocation::supplied` and `Invocation.Supplied` report whether argv
supplied the nearest visible declaration. Exact scopes provide the same
operations without ancestor lookup

Rust retrieves optional typed values through `Invocation::value` and
`Invocation::values`. Go uses `cli.ValueAs[T]` for the first value or accesses
`ParsedValue.Typed()` when iterating repeated values. For schema-required
mapping, use `Invocation::require_value` in Rust or
`cli.RequireValueAs[T]` with either an Invocation or Invocation Scope in Go.
`ValueAccessError` distinguishes a missing value from a parser-result type
mismatch and includes the stable lookup scope and local value ID. No accessor
coerces dynamic types

## Shell and dynamic completion

`CompletionEngine::new` and `cli.NewCompletionEngine` validate and snapshot a
Command Graph as an immutable, handler-free completion model. Build one Engine
and reuse it across requests. Changes to the original graph after construction
do not affect the Engine

One request separates completed shell tokens from the token prefix at the
cursor. Rust uses `CompletionInput::new(arguments, current)` and
`CompletionEngine::complete`; Go uses `cli.NewCompletionInput(arguments,
current)` and `CompletionEngine.Complete`. The Engine resolves only the selected
command path and its visible inherited options. It understands aliases, `--`,
short-option clusters, attached values such as `--profile=dev`, repeated
positionals, and the built-in `help` path

Finite parser values are static candidates. A value Option or Argument may also
install one dynamic `CompletionProvider`. Only the provider for the active
target runs. It receives the selected canonical and stable command paths, the
target-local prefix, and recognized raw occurrences in argv order. Completion
does not run Value Parsers, fallbacks, validators, or command handlers

Rust providers receive a `CancellationToken`; Go providers receive the caller's
`context.Context`. Providers must poll cancellation during long-running work.
The Engine preserves source order, filters by exact prefix, and keeps the first
candidate for each insertion value. Empty display labels and descriptions are
treated as absent. Empty values, invalid UTF-8 in Go, and Unicode control
characters produce a completion-specific error before protocol output

Shell integration is optional. Rust crate `nagi-cli-completion` and Go package
`completion` generate deterministic Bash, Zsh, Fish, and PowerShell scripts.
Their `handle` or `Handle` helper intercepts the reserved completion request
before ordinary Command Graph dispatch and returns whether it handled the
request. Applications should call it before `Command::run_process` or
`Command.RunProcess`

Generated adapters use each shell's native completion registration and pass
already tokenized arguments to the Engine. They do not evaluate candidate text
as shell source. The Bash adapter reconstructs the cursor prefix without
evaluating expansions and shell-quotes insertion values; Zsh uses its `PREFIX`
state and compsys quoting. Zsh and PowerShell preserve per-candidate append
policy. Bash uses no-space behavior for every candidate, and Fish uses its
native default because neither public adapter surface can represent arbitrary
per-candidate suffix behavior

## Structured Help

`Command::help_document` and `Command.HelpDocument` return a renderer-independent
Help Document. It contains the canonical command path, structured Usage
Variants and rendered usage lines, commands, arguments, options,
option-relation and option-group constraints, named examples, notes, links,
and application-defined structured sections. Standard entries, Usage
Variants, and relation and group members retain stable IDs separately from
display labels

Local declarations appear under `Options`. Options inherited from selected
ancestors appear under `Inherited Options` in outermost-to-nearest ancestor
and definition order. `HelpInheritedOption` retains the source command path,
stable command-ID path, option ID, label, and unmodified description for
custom renderers. The plain renderer appends the source command path to each
inherited description

`Command::usage_variant` and `Command.UsageVariant` add ordered Help-only
invocation forms. Their syntax is a suffix such as `<NODE> [OPTIONS]`; the
framework prefixes the canonical command path. Explicit variants replace the
generated direct-invocation usage. `HelpUsageVariant` exposes the source stable
command-ID path, source-local variant ID, syntax suffix, and complete command
line

`Command::subcommand_usage` and `Command.SubcommandUsage` control parent Help
presentation without changing parsing. `Auto` emits the generic optional
`<COMMAND>` form, `Hidden` omits it, and `Expanded` emits each immediate
child's direct Usage Variants in definition order. Expansion is shallow and
retains each child's stable command-ID path, so child-local variant IDs may be
reused. On a command that requires a subcommand, `Expanded` emits only the
child forms

Usage Variants do not change argv parsing, typed validation, Diagnostic usage,
or Invocation. This lets an application document several forms implemented by
a typed validator without claiming that the portable graph selects those
forms

The default plain renderer preserves definition order and aligns labels by
terminal Cell width. Applications can install a custom Help Renderer through
the Runtime Policy without replacing parsing or validation

In addition to `-h` and `--help`, roots with subcommands provide
`help [COMMAND...]`. Nested aliases are accepted and the selected command is
reported by its canonical path

## Structured Diagnostics

A Diagnostic has a stable machine-readable code, semantic category,
human-readable message, canonical command path, optional usage, ordered value
targets, and ordered remediation hints. A target identifies an option or
argument by stable command-ID path and command-local value ID. Targets remain
available to custom renderers even though the default renderer does not expose
internal IDs

Framework codes retain their specified categories. Applications may create a
stable application code and override its category, for example a
command-specific validation code in the `usage` category. Rust uses
`DiagnosticCode::application`, while Go uses a typed
`cli.DiagnosticCode("application-code")` value. Validator and handler targets
without an explicit command-ID path receive the validator or handler current
scope. Use `with_command_id_path` or `WithCommandIDPath` when targeting another
selected scope

The plain renderer writes one `hint:` line per hint before optional usage.
Custom Diagnostic Renderers receive the complete structured Diagnostic

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

For staged adoption, parse first and inspect `ParseResult::command_id_path` or
`ParseResult.CommandIDPath`. `run_parsed_with_policy` and
`RunParsedWithPolicy` execute Help, version, or a registered handler from an
existing Parse Result. `run_invocation_with_policy` and
`RunInvocationWithPolicy` bridge an already validated Invocation to one
registered handler. Both reject results whose canonical or stable command path
does not identify the same Command Graph

Parser-only integrations can call the Runtime Policy's pure Help rendering,
Diagnostic rendering, and Diagnostic-to-status helpers. This preserves one
renderer and exit-code policy while an existing CLI continues to own process
dispatch and output routing

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
[Rust staged-adoption example](../nagi-rs/crates/nagi-cli/examples/staged.rs),
[Rust completion example](../nagi-rs/crates/nagi-cli-completion/examples/completion.rs),
[Go basic example](../nagicli-go/examples/basic/main.go),
[Go subcommand example](../nagicli-go/examples/subcommands/main.go),
[Go staged-adoption example](../nagicli-go/examples/staged/main.go), and
[Go completion example](../nagicli-go/examples/completion/main.go) as complete
entry points

## Limitations

The core does not load configuration files, run interactive prompts, or
integrate a TUI. Shell-specific generation and protocol I/O remain in the
optional completion package or crate. Long-running handlers and completion
providers must poll their injected cancellation source and stop cooperatively

The portable graph does not model arbitrary invocation grammars or
parser-generator productions. Use option groups and typed validators for
bounded application rules. Help-only Usage Variants can describe the accepted
forms, but do not return a runtime variant ID. Keep command-specific parsing
outside the portable specification when those mechanisms are insufficient

Process integration targets Linux and macOS on x86-64 and ARM64. Parsing and
injected execution do not require a terminal
