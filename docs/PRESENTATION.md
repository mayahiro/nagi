# Terminal Presentation Rules

[日本語](PRESENTATION_ja.md)

Terminal Presentation Rules are Nagi's CSS-like layer for source-neutral
Content. An immutable sheet maps exact Roles, Classes, and
application-supplied States to terminal text and layout values without adding
appearance data to the Content tree

The complete observable behavior is defined by the
[Terminal Presentation specification](../spec/presentation.md)

## Packages

| Language | Package |
| --- | --- |
| Rust | `nagi-tui` |
| Go | `github.com/mayahiro/nagitui-go` package `tui` |

Presentation belongs to the terminal backend because its declarations use VT
Color and Style plus TUI layout values. The source-neutral `nagi-content` crate
and Go `content` package remain independent from VT and TUI

Run the complete resolution and projection examples from each implementation
repository:

- [Rust Presentation example](../nagi-rs/crates/nagi-tui/examples/presentation/main.rs)
- [Go Presentation example](../nagitui-go/examples/presentation/main.go)

## Rule model

A `PresentationSelector` targets every element, one exact Content Role, or one
exact Content Class. A rule can additionally require an all-of set of open
`PresentationState` tokens supplied by the application

Required States retain their unique input order for inspection, while matching
uses all-of semantics and does not depend on required or active State order

The sheet applies matching rules in declaration order. There is no selector
specificity, prefix matching, descendant matching, runtime stylesheet parser,
or global mutable theme

Every declaration value is Unspecified, Set, or Initial. This separate
cascade model is necessary because VT Style merging is transparent Cell
composition: it cannot turn an inherited Boolean attribute off or explicitly
restore a terminal-default color

Text properties inherit from the Style supplied to resolution. Layout values
do not inherit and start from the Content ElementKind plus Auto Length, zero
gap, no visual separator, word wrapping, and start alignment

Bindings that can express unknown numeric Display, Wrap, or Alignment values
ignore those concrete declarations. Visual separators are normalized UTF-8;
an explicitly set empty separator remains distinct from no separator

## Boundary with Content and Nodes

Content Roles retain meaning, while Classes are opaque hooks that can preserve
source appearance without inventing semantics. States such as selection or
disabled status remain application state and are passed only when resolving an
element

The computed result contains a concrete VT Style and terminal layout values.
It does not mutate Content and does not create a TUI Node

Content-to-Node projection is a separate operation with its own
[observable specification](../spec/content-node-projection.md). Keeping rule
resolution pure lets applications inspect computed values or construct custom
Nodes without using the standard projection

## Content-to-Node projection

Rust `project_content` and Go `ProjectContent` resolve every visited Element
and create ordinary Paragraph, Column, Row, and Gap Nodes. The state-aware
variants accept one synchronous callback whose returned States apply only to
the current Element

Paragraph and Inline displays form inline formatting contexts. A block display
inside one of those contexts returns a structured `invalid-layout-tree`
failure. Flow maps to Column and Sequence maps to Row. An inline root or an
inline direct child of either block container is promoted to its own anonymous
Paragraph

Projection never maps Element IDs to Node IDs or annotations to actions. Add
namespaced Node identity, handlers, SelectableText, and application policy
outside the returned Node

Every projection bounds visited Content nodes, generated Nodes, styled spans,
tree depth, and emitted UTF-8 bytes. Default limits are suitable for an eager
visible subtree and can be lowered or raised through
`ContentProjectionLimits`; depth remains capped at 256 because Node layout and
rendering are recursive

## Resource behavior

Sheets own their ordered rules and may share immutable storage when copied.
Resolution performs no I/O and uses no global or unbounded cache. A source
adapter that accepts untrusted rule data must bound that data before sheet
construction

Rust `ComputedPresentation` borrows a concrete visual separator from its
`PresentationSheet`, so the result cannot outlive that sheet. Go returns a
string value backed by immutable storage. Neither implementation copies a
separator during resolution

Large feeds should continue to use VirtualFlow and project only item subtrees
requested by its visible-item builder. Projection does not create VirtualFlow
or retain a Node cache. Element IDs and opaque revisions alone are not a
correct computed presentation cache key because revisions carry no automatic
metadata-change contract

The computed Hidden attribute is visual presentation, not redaction. Remove
sensitive values before they enter Content
