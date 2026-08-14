# Source-neutral content

[日本語](CONTENT_ja.md)

Nagi Content is the source-neutral structure shared by source adapters and
renderers. It provides the HTML-like side of the boundary: immutable text and
elements retain semantics, stable identity, and annotations while terminal
presentation remains a separate concern

The complete observable contract is the
[source-neutral content specification](../spec/content.md)

## Packages

| Language | Package |
| --- | --- |
| Rust | `nagi-content` |
| Go | `github.com/mayahiro/nagi-go/content` |

The Rust crate depends only on `nagi-text`. The Go package depends only on the
sibling `text` package. Neither implementation depends on VT, TUI, CLI domain
types, a source parser, or an application runtime

## Model

A `Content` value is an immutable Text, HardBreak, or Element node. An Element
uses one of four small mechanical kinds:

- Inline joins inline children without adding semantic text
- Flow places a line boundary between block children
- Paragraph groups inline children without adding semantic text
- Sequence places a tab boundary between ordered fields or cells

An element can override its semantic child boundary. That boundary controls
copyable and accessible text, not visual spacing. A renderer can therefore
choose a different visual separator without changing semantic output

Roles record meaning such as `heading` or `diagnostic.code`. Classes are
opaque presentation hooks such as `source.ansi.sgr-33-1`; they do not invent
semantic meaning for source-provided appearance. Annotation IDs are opaque
application references. Nagi Content never opens a link, runs a command, or
stores a callback

Stable element IDs and opaque revisions let an adapter retain identity while
replacing a changed root or subtree. Cloning a Rust Content value or copying a
Go Content value shares immutable backing storage

Go slice accessors return defensive copies. `HasRole`, `HasClass`,
`ChildCount`, and `Child` provide allocation-free membership and indexed reads
for renderers while preserving immutable ownership

## Projection and validation

`semantic_text` in Rust and `ProjectSemanticText` in Go traverse the tree from
left to right. They return normalized UTF-8 plus half-open byte ranges for
annotated elements. Nested range order follows element preorder

`validate` in Rust and `Validate` in Go apply caller-supplied limits for depth,
nodes, semantic bytes, metadata bytes, and tokens per element. They also reject
duplicate stable element IDs and return deterministic resource statistics.
Constructors do not apply hidden whole-tree limits

Run the complete examples from each implementation repository:

- [Rust content example](../nagi-rs/crates/nagi-content/examples/content/main.rs)
- [Go content example](../nagi-go/examples/content/main.go)

## Boundary with presentation

Content carries structure and meaning but no terminal Color, Style, Length,
focus target, event handler, or viewport state. A terminal presentation layer
may resolve roles and classes into backend-specific layout and computed style,
then project the result into ordinary TUI nodes

Nagi's [Terminal Presentation Rules](PRESENTATION.md) define deterministic
rule resolution. The separate bounded
[Content-to-Node projection](../spec/content-node-projection.md) maps that
result into ordinary TUI Nodes without adding terminal dependencies to Content

Markdown, ANSI, Help, Diagnostic, JSON, Diff, and application domain models
remain source adapters or renderers. They may produce Content without becoming
part of the Content Core, and their parsing, redaction, activation, and trust
policies remain with the adapter or application
