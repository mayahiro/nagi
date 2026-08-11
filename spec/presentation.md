# Terminal presentation rules

Terminal Presentation resolves source-neutral Content metadata and
application-supplied state into terminal-specific computed presentation
values. It is the CSS-like side of the Content boundary: Content retains
meaning and structure, while a Presentation Sheet selects concrete text and
layout values without modifying the Content tree

This specification defines rule resolution only. It does not define a Content
to TUI Node projection

## Scope

Terminal Presentation owns the following data and behavior:

- immutable ordered presentation rules
- exact universal, Role, and Class selectors
- open application-supplied state tokens
- three-state property declarations
- deterministic cascade and limited text-style inheritance
- terminal-specific computed text and layout values

It does not own source parsing, Content mutation, application state, focus,
events, annotations, Node IDs, virtual scrolling, terminal capability policy,
or domain models

## State tokens

A Presentation State uses the portable token grammar defined by the
[Content specification](content.md). A state is supplied by the application
for one element occurrence during resolution. It is never stored in Content

Only states successfully created from the portable grammar participate in
matching. An invalid or language-specific zero state MUST NOT match a required
state

A rule MAY require zero or more states. Required states are stored as an
ordered unique sequence and MUST NOT contain duplicates. Implementations MUST
preserve the supplied order for public inspection and value identity. Matching
interprets the sequence as an all-of set: required-state order and active-state
order do not affect the result. A rule matches the state condition only when
every required state is present in the active state set. Extra active states do
not prevent a match

## Selectors

A selector is exactly one of the following:

- `any`, matching every element
- `role`, matching when the element contains the exact Role token
- `class`, matching when the element contains the exact Class token

Role and Class are separate namespaces even when their token text is equal.
Token order on an element does not affect matching. A rule is applied at most
once for an element

Prefix, suffix, substring, wildcard, ancestor, descendant, sibling, and
specificity-based matching are not part of this contract

## Declaration values

Every declared property has one of three states:

- `unspecified` leaves the current computed value unchanged
- `set(value)` replaces the current computed value with `value`
- `initial` replaces the current computed value with that property's initial
  value for the element

`initial` does not restore an inherited value and does not remove an earlier
rule from consideration

A language binding that can construct numeric enum values outside a
property's defined value set MUST treat `set(unknown)` as `unspecified`. An
unknown value MUST NOT appear in computed presentation. This rule applies to
Display, wrapping mode, and horizontal alignment

The text declaration contains foreground, background, optional underline
color, and the Bold, Dim, Italic, Underline, Blink, Reverse, Hidden, and
Strikethrough Boolean attributes

The layout declaration contains display, main-axis Length, child gap, visual
separator, wrapping mode, and horizontal alignment

## Initial values and inheritance

Text properties inherit. Resolution begins with the complete computed Style
supplied by the caller, normally the parent element's computed Style or the
application's root Style. Text `initial` values are the terminal default
foreground and background, no underline color, and `false` for every Boolean
attribute

Layout properties do not inherit. Their initial values are:

| Property | Initial value |
| --- | --- |
| Display | The corresponding Content ElementKind |
| Length | Auto |
| Child gap | zero Cells |
| Visual separator | absent |
| Wrap | Word |
| Horizontal alignment | Start |

The display correspondence is Inline to Inline, Flow to Flow, Paragraph to
Paragraph, and Sequence to Sequence

A visual separator is presentation-only normalized UTF-8 text between direct
children. A binding that accepts arbitrary bytes in its string type MUST
replace each invalid UTF-8 run with U+FFFD before storing a concrete separator,
using the [Nagi Text normalization policy](text.md). A concrete empty separator
is present and remains distinct from the absent initial value. A visual
separator MUST NOT change Content semantic boundaries or semantic-text
projection

## Cascade

A Presentation Sheet preserves rule source order. Resolution performs these
steps:

1. Start text properties from the caller-supplied inherited Style
2. Start layout properties from the element-specific initial values
3. Visit every rule once in sheet source order
4. Skip a rule unless both its selector and all required states match
5. Apply each matching declaration property independently

Later matching rules therefore win only for properties they specify. Selector
kind, token count, and required-state count add no implicit priority

The VT Style merge operation is not a cascade operation and MUST NOT be used
to resolve a Presentation Sheet. In particular, a later declaration can set a
Boolean property to `false`, set a color to the terminal default, or remove an
underline color

## Ownership and safety

Sheets, rules, declarations, selectors, and states are values with no global
mutable registry. A sheet owns its rule order and MUST NOT observe later
mutation of input collections. Copies MAY share immutable backing storage

Resolution performs no I/O, does not execute annotation values, and does not
emit terminal control bytes. Implementations MAY index or cache rules only if
source-order results remain identical and retained cache growth is bounded

The Hidden text attribute is presentation only. It MUST NOT be used as
redaction or secret protection; sensitive values must be removed before they
enter Content

Rule construction applies no hidden whole-sheet resource limit. An adapter
that accepts untrusted rule data remains responsible for bounding that input
before constructing a sheet

## Projection boundary

A later backend projection may map computed display and layout values into
ordinary TUI Nodes. That projection must separately define valid inline and
block nesting, eager-work limits, Node ID namespacing, annotation behavior,
and VirtualFlow integration

Rule resolution itself does not create Nodes, map Element IDs to Node IDs,
activate annotations, or choose a Markdown, ANSI, Help, Diagnostic, JSON,
Code, or Diff model
