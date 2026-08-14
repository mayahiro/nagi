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
- an inherited option spelling overlaps any option visible from that option's
  declaration through a descendant command;
- option and positional value IDs overlap within one command;
- a repeated positional is not the final positional;
- a relation names an option outside its command;
- an option group has an invalid or duplicate ID, contains fewer than two
  distinct options, or names an option outside its command; or
- a usage variant has an invalid or duplicate ID, has an invalid syntax
  suffix, conflicts with a generated usage variant, or is attached to a
  command that requires a subcommand; or
- a configured deprecation replacement is empty, is not valid UTF-8, or
  contains a Unicode control character; or
- an application definition uses the reserved `help`, `version`, `h`, or `V`
  option spelling.

Aliases select the canonical command and never appear in the resulting command
path.

## Command and option lifecycle metadata

A Command or Option MAY independently be marked Hidden, Deprecated, both, or
neither. These markers are generic Command Graph metadata. They MUST NOT add
application-specific policy, authorization, redaction, or data retention
meaning.

Hidden controls generated projections while preserving exact parsing. A Hidden
child name or alias remains selectable, and a Hidden Option remains recognized
where its ordinary local or inherited visibility permits. Direct Help for an
explicitly selected Hidden Command remains available. Hidden MUST NOT be
treated as a security boundary because a caller that knows the spelling can
still use and inspect the declaration.

The following projections MUST omit Hidden declarations:

- parent Help command entries, command Usage Variants, and the generated root
  `help` command entry when no visible child exists;
- local and inherited Help option entries;
- Help option relations whose source or target is Hidden, and option groups
  containing a Hidden member;
- command, alias, long-option, short-option, and finite-value completion
  candidates; and
- dynamic completion results for a Hidden Value Option. Its provider MUST NOT
  run, including after that Hidden Option was explicitly recognized in the
  completed input.

A command with only Hidden children does not gain a generic `<COMMAND>` Help
form or a built-in `help` completion candidate. Explicit `help HIDDEN` remains
valid because parsing is unchanged.

Deprecated preserves parsing, validation, and handler execution. It carries an
application-provided replacement hint that MUST be non-empty valid UTF-8 and
MUST NOT contain Unicode control characters. Deprecated declarations remain
visible unless they are also Hidden. Structured Help exposes replacement
metadata for the selected command, command entries, local Option entries, and
inherited Option entries. Static completion candidates expose the same
metadata. The standard Help renderer appends `[deprecated: use REPLACEMENT]`
to an entry and renders `Deprecated: use REPLACEMENT` for the selected
command. Shell protocol adapters append the same entry annotation to candidate
descriptions without changing insertion values.

A successful Invocation owns ordered structured Deprecation Notices. A notice
contains Command or Option target kind, the canonical command path when the
use was recognized, the stable command-ID path of the declaration, the local
Option ID when applicable, the first recognized spelling, and the replacement
hint. A deprecated root Command produces the first notice and uses its
canonical name as the spelling because public parsing input excludes the
executable. Other targets follow their first successful occurrence in argv.
Each stable target appears at most once. An alias, long spelling, or short
spelling used first remains the notice spelling.

Only command-line occurrences produce Option notices. Environment, external,
and default fallbacks do not. Help, version, failed parsing, portable validation failure,
and Invocation validator failure do not return an Invocation and therefore do
not expose accumulated notices through a failure Diagnostic. A Deprecation
Notice is non-fatal metadata and MUST NOT be added to Diagnostic codes,
categories, targets, or hints.

The default Runtime Policy leaves notices silent. An application MAY install a
Deprecation Notice Renderer. When installed, Runtime writes notices to standard
error in Invocation order after cancellation has been checked and before the
handler starts. Notice output failure is returned as an I/O failure and the
handler MUST NOT run. The standard plain renderer emits:

```text
warning[deprecated-option]: option '--old' is deprecated
hint: use --new
```

## Sensitive value metadata

A Value Option or positional Argument MAY be marked Sensitive. Sensitive is
generic value-presentation metadata and MUST NOT identify a credential type,
own authorization policy, or change the raw or typed Invocation value. A Flag
or Count marked Sensitive is invalid value-only configuration and MUST be
rejected before argv parsing.

The public redaction marker is the ASCII string `<redacted>`. Implementations
MUST carry the Sensitive marker into Parsed Values, structured Help entries,
Diagnostic Targets produced for that declaration, and Completion Targets.
Callers MUST be able to query this metadata without comparing display text.

Framework-controlled projections MUST behave as follows:

- Help preserves the option or argument label, description, required marker,
  and environment variable name. A Sensitive default is rendered as
  `default: <redacted>`, and a non-empty finite value set is rendered as
  `possible: <redacted>` without retaining the values in the Help Document;
- a Value Parser failure for a Sensitive declaration uses the stable message
  `invalid value <redacted> for 'ID'`. It MUST NOT include the raw value or the
  parser-provided failure reason in the Diagnostic;
- Debug or Go formatting of a Parsed Value, Invocation, Parse Result, normalized
  Completion Request, or Completion Result MUST NOT expose a Sensitive raw or
  typed value. Raw Completion Input has no Command Graph metadata and its debug
  representation MUST treat every token as opaque;
- finite value completion candidates MUST NOT be returned for a Sensitive
  target, and its dynamic completion provider MUST NOT run; and
- completed Sensitive occurrences remain available through explicit raw
  Completion Request access so an application provider for another target can
  make an authorized decision. Their structured occurrence and target metadata
  MUST remain marked Sensitive.

Parser-generated Diagnostic Targets MUST carry the declaration marker. When an
Invocation validator or Handler returns a Diagnostic, the framework MUST also
resolve each matching target by target kind, stable command-ID path, and local
value ID. An omitted path uses the validator's defining scope or the Handler's
selected scope. An explicit unknown path, unknown value ID, or mismatched target
kind MUST remain non-Sensitive

Explicit Invocation raw and typed access MUST return the original value and
source. Sensitive does not zeroize memory, remove values from OS process
inspection or shell history, protect transport, or prevent a handler,
validator, or completion provider from logging a value it explicitly reads.
Applications SHOULD prefer an injected environment value, standard input, or a
Secret Prompt over argv when process-level disclosure matters.

Application-authored Diagnostic messages and hints, Help descriptions,
examples, custom sections, parser objects, and runtime output are opaque text.
The framework MUST NOT guess which substrings are secrets. Applications MUST
redact those values before constructing public output. Environment variable
names are metadata rather than resolved values and remain visible.

## Argument parsing

Parsing starts at the root command and scans arguments from left to right.
Options and positionals MAY be interspersed until `--`. The `--` argument ends
option and subcommand recognition and is not stored. A lone `-` is positional.

Before a positional is consumed, a non-option matching a child name or alias
selects that child. After child selection, options declared by that child and
inherited options declared by selected ancestors are recognized. Parent and
child commands MAY declare the same local option spelling and local value ID;
token position selects the command scope. This spelling reuse is invalid when
the ancestor option is inherited because both declarations would be visible
after child selection. Already parsed parent values remain in the Invocation.
After any positional is consumed, later non-option tokens are positional even
if they match a child name.

Options are local unless explicitly marked Inherited. An inherited option is
recognized in its declaring command and every selected descendant, including
after positionals, until `--` disables option recognition. An inherited option
declared by a child is not visible before that child is selected. Long and short
spellings are resolved independently and short clusters MAY contain local and
inherited options from different selected scopes.

Every occurrence of an inherited option is stored in its declaration scope,
regardless of its argv position. Duplicate checks and repeated-value order
therefore span occurrences before and after subcommand selection. Required,
environment, external, default, relation, option-group, and validator behavior continues
to run in the declaration scope. Relations and groups remain command-local and
MUST NOT reference an ancestor or descendant declaration.

The complete graph is validated before parsing. A local or inherited spelling
in a descendant MUST NOT overlap a visible inherited spelling. Reusing a
non-inherited ancestor spelling remains valid, as does reuse on unrelated
sibling branches. Implementations MUST resolve an option from only the selected
root-to-active path and MUST NOT scan unrelated graph branches per argv token.

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

## Completion

Completion is a handler-free projection of a validated Command Graph. An
implementation MUST build an immutable Completion Engine before serving
requests. Later mutation of a language-native Command builder MUST NOT change
an existing Engine. The Engine contains command and option spellings,
descriptions, finite Value Parser candidates, inherited visibility, and
explicit Option or Argument completion providers. It MUST NOT retain or invoke
command handlers or Invocation validators.

### Tokenized input

A Completion Input contains:

- completed arguments after the program name and before the cursor token; and
- the current token prefix up to the cursor.

Shell adapters own tokenization and quoting. Core completion MUST NOT parse a
raw shell command line. This split represents an empty token after whitespace,
an incomplete long or short option, and a cursor in the middle of a token
without treating the request as a normal parse failure.

Completion scans completed arguments with the ordinary command, alias,
option, inherited-option, positional, short-cluster, attached-value, and `--`
recognition rules where the next state is unambiguous. It MUST NOT resolve
environment, external, or default values, run a Value Parser, enforce required values,
relations, or groups, or run an Invocation validator. Unknown or malformed
completed syntax MUST NOT produce an ordinary parsing Diagnostic. An
implementation MAY stop producing candidates after such syntax rather than
guessing whether later tokens are values or commands.

The built-in `help` path completes canonical child names and aliases. A
committed built-in Help or Version option ends useful completion. Subcommands
are candidates only before a positional starts and while option recognition is
enabled. Visible inherited options remain candidates in selected descendants.
A non-repeatable Flag or Value option already recognized in completed argv is
omitted; Count and repeatable Value options remain candidates.

For `--option=PREFIX`, `-oPREFIX`, and a short cluster ending in a Value option,
the provider receives only the target-local `PREFIX`; returned insertion text
restores the option prefix. A Value option at the end of completed arguments
targets the current token even when that token begins with a hyphen.

### Request and partial occurrences

A normalized Completion Request contains the original completed arguments and
current token, selected canonical command path, selected stable command-ID
path, active target, target-local prefix, and recognized partial occurrences
in argv order. A target is one of:

- Command, identified by the active stable command-ID path;
- Option, identified by its declaring stable command-ID path and local value
  ID; or
- Argument, identified by its declaring stable command-ID path and local value
  ID.

Partial occurrences distinguish Flag, Count, and raw Value occurrences. They
do not contain typed parser results. When a positional slot and child commands
are both valid at an empty or partial token, command candidates MAY be combined
with the positional candidates and that positional remains the provider target.

### Static and dynamic candidates

Canonical child names and aliases, visible long and short options, built-in
actions, and finite Value Parser values are static candidates. A Value option
or Argument MAY have one dynamic completion provider. Only the active target's
provider runs. Unselected branches and unrelated providers MUST NOT run.
Command handlers MUST NOT run through either the Core API or generated shell
protocol.

Go providers receive the caller's `context.Context`. Rust providers receive a
cooperative Cancellation Token. Cancellation is checked before and after the
provider call. A provider is responsible for stopping its own I/O promptly.
Provider failures and cancellation are Completion errors, not handler errors
or parsing Diagnostics.

Static candidates precede dynamic candidates. Implementations preserve source
order, filter by the exact current prefix, and remove duplicate final insertion
values with first-wins semantics. A candidate contains insertion value,
display label, optional description, Command, Option, or Value kind, and an
append-space policy.

Candidate values MUST be non-empty valid UTF-8. Candidate values, display
labels, and descriptions MUST NOT contain Unicode control characters, including
C0, DEL, and C1. An empty display label or description is treated as absent.
Unsafe dynamic or static metadata produces an Invalid Candidate completion
error before a shell protocol writes it.

### Generated shell protocol

The optional completion package or crate generates deterministic Bash, Zsh,
Fish, and PowerShell scripts. A generated script invokes the same application
with the reserved `__nagi_complete` token, a shell identifier, the current
token, and completed arguments. Applications MUST pass this request to the
completion protocol helper before ordinary Command Graph parsing. The reserved
token is outside the portable command-name grammar.

The protocol writes newline-delimited candidate records without evaluating
candidate text as shell source. Bash uses programmable completion word state,
Zsh uses compsys word state, Fish uses `commandline` token state, and
PowerShell uses native Argument Completer AST extents. The generated Zsh and
PowerShell adapters map append-space policy explicitly. Bash exposes no
per-candidate suffix policy through `COMPREPLY`, so its generated adapter uses
no-space behavior for every candidate and leaves delimiter insertion to the
user. Fish's public completion definition also cannot represent an arbitrary
per-candidate no-space flag, so its generated adapter uses Fish's default
insertion behavior.

Adapters pass only the current token prefix before the cursor. The Bash adapter
reconstructs that prefix from `COMP_LINE`, `COMP_POINT`, and `COMP_WORDS`, then
removes shell quote delimiters and escapes lexically without evaluating
expansions. It shell-quotes returned insertion values. The Zsh adapter uses
`PREFIX` and delegates insertion quoting to compsys.

## Lightweight interactive prompts

Interactive prompts are an optional package or crate layered above CLI Core.
CLI Core MUST NOT depend on the prompt component. The component is line
oriented and MUST NOT enter an alternate screen, enable raw input, or own
application concepts such as tools, providers, credentials, or approval
policy.

The component provides Confirm, Select, Input, and Secret requests. A process
backend reads standard input and writes prompts to standard error so standard
output remains available for command results. An injected I/O interface MUST
expose terminal detection, complete writes, flush, bounded line reads, visible
or secret input mode, end of input, cancellation, and input-too-long outcomes.
Tests and embedded applications MAY implement that interface without accessing
the process terminal.

By default, a prompt requires both its input and output to be terminals and
returns Not Terminal before writing when either is not. An application MAY
explicitly allow non-terminal Confirm, Select, and Input requests. Secret MUST
always require a terminal because a generic stream cannot guarantee that user
input is hidden. Terminal detection is an observed backend property and MUST
NOT be inferred from environment variables.

The Unix process backend targets the same Linux and macOS architectures as CLI
process integration. Secret input MUST derive terminal attributes with
`tcgetattr`, clear `ECHO` and `ECHONL`, apply the modified attributes, and
restore the complete saved attributes after success, end of input,
cancellation, oversized input, I/O failure, or stack unwinding. The backend
keeps canonical input and signal processing enabled. It writes one newline
after each secret read because the terminal does not echo that line ending.

A caller supplies its cancellation source to every request. Cancellation is
checked before output, around each line read, and while the Unix process
backend waits for input. The process backend MUST use an input-wait timeout no
greater than 100 milliseconds and MUST NOT keep a permanently running task.
End of input before any response byte, an input line containing only ASCII ETX,
and a line containing only Escape are also Cancellation. Cancellation and other
failures MUST NOT return a partial value.

Prompt metadata MUST be valid UTF-8 and MUST NOT contain Unicode control
characters. Messages, rendered Input defaults, and Select choice labels MUST
be non-empty. Select MUST contain at least one choice, choice order is
significant, and returned indices are zero-based even though displayed indices
are one-based. A default Select index MUST name an existing choice. Confirm
accepts ASCII `y`, `yes`, `n`, and `no` case-insensitively. Confirm and Select
trim surrounding ASCII spaces and tabs; Input and Secret preserve them.

An empty response selects an explicit default. Without a default, Confirm and
Select repeat after an invalid response. Required Input without a default and
required Secret repeat after an empty response. Invalid responses repeat
without an implicit attempt budget. Each read is limited to 65,536 bytes by
default, excluding one LF and an immediately preceding CR. A caller MAY lower
or raise that non-zero limit. The default maximum Select choice count is 1,000
and MAY also be configured to a non-zero value. An oversized line is drained
through its line ending and returns Input Too Long rather than retrying.

Input bytes are normalized to valid UTF-8 by replacing each maximal invalid
byte run with one U+FFFD. The normalized value is returned to the application;
Prompt never interprets it as a command, path, credential, or policy decision.
Secret values use ordinary language-native strings and the component does not
claim memory zeroization after return.

## TTY-aware status reporting

Status reporting is an optional package or crate layered above CLI Core. CLI
Core MUST NOT depend on the status component. The component MUST NOT own an
application task, clock, cancellation source, Agent concept, or progress
meaning. An application supplies immutable Status, Spinner, or Progress
Snapshots when its own state changes.

A Reporter is synchronous and MUST NOT create a thread, goroutine, timer, or
periodic wake-up. Spinner ticks and update frequency belong to the
application. The application also serializes a Reporter with every other
writer that uses the same output. The Reporter is not concurrently usable.
Cancellation does not implicitly change output; an application responds to
its cancellation source by finishing or clearing the Reporter as appropriate.

An injected status I/O interface MUST expose complete writes, flush, terminal
detection, and an optional positive terminal width. Tests and embedded
applications MAY implement that interface without accessing a process
terminal. The Unix process implementation writes to standard error by default
so standard output remains available for command results. Terminal detection
is an observed descriptor property and MUST NOT be inferred from environment
variables. A failed width query does not change terminal classification.

The stable terminal forms are:

- Status: the message;
- Spinner: one of `-`, `\`, `|`, `/` selected by `tick modulo 4`, followed by
  one space and a non-empty message; and
- Progress: `[###---] current/total`, followed by one space and a non-empty
  message.

Progress clamps `current` to `total`. A zero total renders current as zero and
no completed cells. Multiplication used to select completed cells MUST NOT
overflow. The default progress width is 20 Cells, and an application MAY
configure a width from 1 through 1,024 Cells.

Each emitted terminal update writes CR followed by CSI `2 K`, the rendered
line, and one flush without a line feed. The Reporter reserves the terminal's
final Cell to avoid autowrap and truncates at an extended-grapheme boundary
using its configured Text width profile. The default profile is Modern. When
terminal width is unavailable, the default is 80 columns. A width of one has
zero usable Cells. A repeated update whose final terminal line is identical
MUST NOT write or flush.

Finish commits the supplied terminal Snapshot with one final line feed and
ends the active lifecycle. If the final line is already displayed, Finish
only writes that line feed. Clear writes CR and CSI `2 K` only when a terminal
line is active. Both operations reset terminal and fallback coalescing state.
An explicit Log writes one permanent message and one line feed. When a
terminal line is active, Log clears it, writes the permanent line, and
repaints the unchanged transient line before one flush.

When output is not a terminal, Reporter MUST NOT emit control sequences or
spinner frames. Status and Spinner fall back to the message followed by one
line feed. Progress falls back to `current/total`, an optional space and
message, and one line feed. Identical fallback records are coalesced even when
Spinner ticks differ, and an empty fallback record is omitted. Finish attempts
the same fallback record and then resets coalescing state. Clear emits nothing
for non-terminal output. Explicit Log records are never coalesced.

Messages MUST be valid UTF-8, MUST NOT contain Unicode control characters, and
are limited to 65,536 bytes by default. An application MAY configure another
positive limit. Validation failure occurs before output. An I/O failure may
follow a partial stream write, returns a structured I/O error, and MUST NOT
commit new Reporter state. Retained rendering buffers are bounded by the
message and progress limits rather than the number of updates.

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
3. External
4. Default

CommandLine has highest precedence, followed by Environment, an optional
application Value Resolver, and Default. One or more command-line values
suppress every fallback for that ID. A present environment value suppresses
the resolver and Default. An unresolved resolver result permits Default.

A parsed value also has an origin. CommandLine and Default origins have no
identity. An Environment origin identifies the environment variable. An
External origin identifies the application source. A source identity MUST
start with an ASCII letter and contain only ASCII letters, digits, hyphens, or
underscores. It is portable metadata and MUST NOT contain a credential or
secret.

An application MAY provide one synchronous Value Resolver when parsing or
running a command. The resolver adapts already loaded application state into
raw Value Option fallbacks. It does not make Nagi own configuration schemas,
file formats, path discovery, credential storage, environment interpolation,
asynchronous I/O, or retries. A resolver SHOULD NOT start file or network I/O
from its callback.

The resolver receives only selected Value Options that remain unresolved after
CommandLine and Environment processing. Flag and Count options, positionals,
unselected commands, Help and version actions, completion, and derived Help
generation MUST NOT invoke it. Eligible requests run synchronously in selected
root-to-leaf command order and declaration order within each command.

Each request exposes the complete selected canonical and stable command-ID
paths, the declaring command's canonical and stable path prefixes, the
command-local value ID, repeatability, and Sensitive metadata. It MUST NOT
expose a higher-precedence raw value, configured Default, or Value Parser.

A resolver returns one of these states:

- Unresolved permits the configured Default;
- Replace supplies one or more External raw values and suppresses Default; or
- Merge supplies one or more External raw values followed by the configured
  Default when one exists.

A resolved result MUST have a valid source identity and at least one raw value.
A non-repeatable Value Option accepts only Replace with exactly one raw value.
Merge and multiple returned values are valid only for a repeatable Value
Option. Resolver value order is preserved. Every returned raw value is parsed
through the declaration's Value Parser before storage. Default language-native
Debug or formatting of a resolver result MUST NOT expose its raw values or
source identity because the result does not itself carry declaration
sensitivity. Explicit access remains available.

An invalid resolver result produces `invalid-specification`. A resolver MAY
instead return a structured application Diagnostic. If it has no target, the
framework adds the current Option target. The framework supplies the selected
command path and usage, resolves target sensitivity, and preserves the
Diagnostic code, category, message, and hints.

An Invocation distinguishes resolved presence from command-line supply.
`contains` reports a value from any source. `supplied` reports whether an
option or positional was present in argv. An environment, external, or default
fallback is not supplied.

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

Relationship and option-group validation runs after environment, external, and
default values have been resolved. Language-native invocation validators run after
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

An inherited option remains discoverable through ordinary ancestor lookup when
no nearer value ID shadows it. Applications that require its exact declaration
MAY select the declaration scope explicitly. Parse and validation Diagnostics
for an inherited option use that declaration's stable command-ID path as their
target while retaining the selected command path and usage context.

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
not require the default renderer to expose internal IDs. A parser-generated
invalid-value target also carries the raw value's origin, including its
Environment or External identity when present. Custom renderers MAY inspect
that origin. The default plain and JSON renderers MUST NOT display or serialize
it. Hints are human-readable remediation text.

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
the usage line are omitted when unavailable. An explicitly present empty usage
remains present. C0 controls, DEL, and invalid UTF-8 bytes originating in user
input MUST render as uppercase `\xHH` escapes so a diagnostic cannot inject
terminal controls.

The JSON Diagnostic Renderer implements the same Runtime Policy boundary. It
MUST emit one compact [RFC 8259](https://www.rfc-editor.org/rfc/rfc8259.html)
UTF-8 object and one final LF for each Diagnostic, without a byte-order mark.
Multiple rendered Diagnostics therefore form a newline-delimited JSON stream.
The schema identifier is `nagi.cli.diagnostic.v1`.

The complete object shape and textual member order are:

```json
{"schema":"nagi.cli.diagnostic.v1","code":"CODE","category":"CATEGORY","message":"MESSAGE","command_path":[],"usage":null,"targets":[],"hints":[]}
```

`command_path`, `targets`, and `hints` MUST always be arrays, including when
empty. A target object has `kind`, `command_id_path`, and `value_id` members in
that order. Target and hint arrays preserve insertion order. `usage` is `null`
when absent and a JSON string when present, including an explicitly present
empty string. The renderer MUST NOT add an exit status, timestamp, severity,
locale, or application-specific metadata.

Quotation mark, reverse solidus, and U+0000 through U+001F MUST be escaped.
The five predefined control escapes use `\b`, `\t`, `\n`, `\f`, and `\r`;
other C0 controls use lowercase `\u00hh`. All other Unicode scalar values are
emitted directly as UTF-8, including `/`, `<`, `>`, `&`, U+2028, and U+2029.
Language-native strings that can contain invalid UTF-8 normalize each
contiguous invalid run to one U+FFFD before JSON escaping.

## Help and version

Help is first represented as a structured Help Document containing the
canonical command path, description, usage variants and rendered usage lines,
command entries, argument entries, option entries, pairwise option-relation
metadata, option-group metadata, examples, notes, links, and custom sections.
Custom sections have a stable ID, heading, and ordered paragraph or
labeled-entry blocks.

Help for a command lists its own declarations under `Options`. Inherited
options from selected ancestors are listed separately in outermost-to-nearest
ancestor and definition order. Each inherited Help entry retains the source
canonical command path, source stable command-ID path, option ID, label, and
description. The standard renderer uses an `Inherited Options` section and
adds `[from COMMAND PATH]` to each description. Constraints remain attached to
the Help Document of their declaration command.

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
Commands, Arguments, Options, Inherited Options, Constraints, Examples, Notes,
Links, then custom sections in definition order. Constraints list pairwise
relations in option definition order followed by option groups in definition
order. Entries preserve definition order. Labels are aligned by Nagi Text
Modern terminal-cell width. Help always lists its built-in option; version is
listed only when configured at the root. Root help lists the built-in `help`
command when application subcommands exist.

The default renderer is deterministic. Applications MAY provide another Help
renderer without changing the Help Document. Raw or application-specific Help
content belongs in an explicit custom section rather than changing parser
semantics.

An implementation MUST expose a synchronous whole-graph Help traversal. It
validates the graph once, visits the root first, then visits visible descendants
in definition-order preorder. A Hidden command and its complete subtree are
omitted. The visitor receives one complete Help Document at a time and MAY stop
successfully after any document. Traversal MUST NOT execute a command handler,
Invocation validator, or Completion Provider. The Command Graph MUST NOT be
mutated during traversal. A language-native null visitor is an invalid
specification.

Markdown and man page generation are optional pure renderers over one Help
Document. They do not own filenames, output directories, filesystem I/O,
timestamps, or shell completion. Both formats use the same section and entry
order as standard Help, preserve definition order within custom blocks, and
end with exactly one LF.

The Markdown renderer targets
[CommonMark 0.31.2](https://spec.commonmark.org/0.31.2/). It emits a level-one
command-path heading, level-two Help sections, four-space indented Usage and
example code blocks, and Markdown links. Application-supplied text is plain
text rather than Markdown source. ASCII punctuation is backslash-escaped in
text contexts. The first application-supplied ASCII space on a text line is
emitted as a numeric character reference so four leading spaces cannot create
an unintended code block. Link destinations percent-encode whitespace,
controls, `<`, `>`, and reverse solidus.

The man renderer emits section 1 source using the portable `man` macro subset
described by [groff_man(7)](https://man7.org/linux/man-pages/man7/groff_man.7.html).
It emits a deterministic `.TH` without a date, conventional `NAME` and
`SYNOPSIS` sections, `.SH` section headings, `.TP` entries, `.PP` paragraphs,
and `.nf`/`.fi` literal command lines. Application text never becomes a roff
request: a text line beginning with `.` or `'` is prefixed by `\&`, reverse
solidus is emitted as `\e`, and hyphen is emitted as `\-`.

Both optional renderers normalize CRLF and CR to LF, replace other Unicode
control values with U+FFFD, and replace each invalid UTF-8 run with U+FFFD in a
language-native string that can contain invalid UTF-8. A line break used in an
inline-only position is represented by U+FFFD. The shared derived-document
golden files define exact escaping and whitespace.

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
hexadecimal so invalid UTF-8 remains comparable. Prompt fixtures also compare
the exact transcript and ordered visible or secret read modes.
