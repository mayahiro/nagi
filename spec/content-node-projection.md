# Content to TUI Node projection

Content-to-Node projection resolves source-neutral Content through a Terminal
Presentation Sheet and creates ordinary eager TUI Nodes. It is the backend
bridge between the HTML-like Content tree, CSS-like Presentation Rules, and
the terminal render tree

This specification defines the projection shape, failure behavior, and
resource bounds shared by the Rust and Go TUI implementations

## Scope

Projection owns the following behavior:

- per-element Presentation resolution
- inline and block formatting contexts
- anonymous Paragraph promotion
- mapping to Paragraph, Column, Row, and Gap Nodes
- bounded eager traversal and structured failures

It does not own source parsing, semantic-text projection, application state,
Node ID allocation, annotation actions, focus, events, VirtualFlow item
ordering, persistence, or domain models

## Inputs and state resolution

Projection receives one Content root, one immutable Presentation Sheet, one
root Style, bounded projection limits, and optionally a per-element State
resolver

The State resolver MUST be called synchronously exactly once for every visited
Element. Its result applies only to that Element's Presentation resolution and
MUST NOT be retained. A projection call without a State resolver uses an empty
active State set for every Element

Each Element is resolved once, before its descendants. Text Style inherits
from the parent Element's computed Style or from the root Style. Layout values
continue to use the non-inheriting behavior defined by the
[Terminal Presentation specification](presentation.md)

## Formatting contexts

Text, HardBreak, and an Element whose computed Display is Inline are inline
fragments

An inline formatting context accepts only inline fragments. Encountering an
Element whose computed Display is Paragraph, Flow, or Sequence inside an
Inline or Paragraph formatting context MUST fail with `invalid-layout-tree`

Computed Display maps as follows:

| Display | Projection |
| --- | --- |
| Inline | Flatten descendants into the surrounding styled span sequence |
| Paragraph | One Paragraph Node containing flattened inline descendants |
| Flow | One Column Node containing direct projected children vertically |
| Sequence | One Row Node containing direct projected children horizontally |

A Text, HardBreak, or computed Inline root is wrapped in one anonymous
Paragraph Node. The same promotion occurs independently for each inline
fragment that is a direct child of Flow or Sequence. Promotion does not group
adjacent fragments: every direct child retains its own block boundary for gap
and visual-separator behavior

An anonymous Paragraph uses Auto Length, zero gap, no wrapper separator, Word
wrapping, and Start alignment. It inherits the supplied text Style and still
applies text Style and visual separators declared by any flattened Inline
Elements. An adapter that needs several inline fragments to wrap as one text
unit MUST place them inside an explicit Paragraph Element

HardBreak emits one U+000A styled span. Content semantic boundaries do not
affect TUI projection; they remain part of semantic-text projection only

## Layout property application

Computed properties apply as follows:

| Property | Inline | Paragraph | Flow | Sequence |
| --- | --- | --- | --- | --- |
| Text Style | Inherited by descendants | Inherited by descendants | Inherited by descendants | Inherited by descendants |
| Length | Ignored | Paragraph Node | Column Node | Row Node |
| Gap | Ignored | Ignored | Child boundary | Child boundary |
| Visual separator | Styled span | Styled span | Paragraph Node | Paragraph Node |
| Wrap | Ignored | Paragraph Node | Ignored | Ignored |
| Alignment | Ignored | Paragraph Node | Ignored | Ignored |

An Inline Element creates no Node box, so its box-only layout properties have
no target

A visual separator occurs between every pair of adjacent direct children,
even when a child projects to empty text. Inline and Paragraph separators are
styled spans using the containing Element's computed Style. Flow and Sequence
separators are anonymous Paragraph Nodes using that Style, Auto Length, Word
wrapping, and Start alignment

At a Flow or Sequence child boundary, a non-empty visual-separator Node is
inserted first and a non-zero Gap Node is inserted second, before the next
projected child. An absent or concretely empty separator creates no Node or
span. The concrete empty value remains distinct from absence during rule
resolution

## Identity and annotations

Projection MUST NOT derive a Node ID from an Element ID. Element IDs are
scoped to a Content tree, while Node IDs must be unique across the complete
application view. Inline Elements also flatten into spans and may have no Node
counterpart

Projection MUST NOT turn an Annotation ID into an event handler, Message,
URI, command, or policy decision. Element IDs, revisions, and Annotation IDs
remain available in the input Content for application-owned composition

Applications MAY project smaller subtrees and attach namespaced Node IDs,
handlers, SelectableText, or other widgets outside the projection result

## Resource limits

Every projection is bounded by all of the following limits:

| Resource | Default |
| --- | ---: |
| Visited Content node occurrences | 100,000 |
| Generated TUI Nodes | 100,000 |
| Generated styled text spans | 100,000 |
| Content and generated Node depth | 128 |
| Emitted UTF-8 bytes | 16,777,216 |

Root depth is one. A Content child's depth is its parent depth plus one. A
generated child Node's depth is its generated parent depth plus one. Flattened
Inline Elements increase Content depth but do not create an output depth

Emitted bytes include every projected Text byte, one byte for each HardBreak,
and every concrete visual-separator occurrence. They do not include Content
semantic boundaries that projection does not emit

Zero supplied through a limit customization API restores that resource's
default. Because TUI Node measurement and rendering recurse through the Node
tree, the configurable depth is capped at 256 even when a larger value is
requested. Projection provides no unbounded mode

Implementations MUST use saturating resource counters. Before appending an
emitted text span, projection checks visual bytes and then span count. The
first failed check terminates projection

The stable failure categories are:

- `invalid-layout-tree`
- `content-node-limit`
- `output-node-limit`
- `span-limit`
- `depth-limit`
- `visual-byte-limit`

Every failure reports the one-based depth where it arose. A resource failure
also reports its configured limit and first observed value above that limit.
An invalid-layout failure also reports the rejected computed Display

Traversal and accounting are deterministic. A box occurrence accounts for
its Content node, then its generated box Node, then descendants and child
boundaries in display order. Inline and block separators occur immediately
before the following direct child; a block Gap occurs immediately after its
separator

## Ownership, caching, and VirtualFlow

Projection does not mutate Content or a Presentation Sheet and performs no
I/O. The returned Node is a normal frame-owned render tree with mutable layout
caches and MUST NOT be treated as immutable Content storage

Projection maintains no global or retained result cache. Element ID and
revision alone are not a correct cache key because revisions have no automatic
metadata-change contract and computed Style also depends on Sheet, State, and
inherited Style

Projection does not create VirtualFlow. A large feed application MUST keep
stable item order, revisions, visibility, and overscan in VirtualFlow and call
projection only for each item subtree requested by its visible-item builder

Hidden Style remains visual presentation rather than redaction. Sensitive
values MUST be removed before they enter Content
