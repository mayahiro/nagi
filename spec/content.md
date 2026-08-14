# Source-neutral content

Nagi Content is an immutable, source-neutral tree for carrying structured text
between a source adapter and a renderer. It preserves semantic structure and
application-owned identifiers without selecting terminal layout, style, or
interaction behavior

## Scope

Content owns only the following data:

- normalized UTF-8 text
- explicit hard breaks
- ordered mechanical elements
- semantic roles and presentation classes
- optional stable element identity and an opaque revision
- optional application-resolved annotations
- deterministic semantic-text projection and validation

Content does not own source parsing, terminal styles, TUI nodes, layout sizes,
focus, selection, callbacks, URI handling, clipboard access, or domain models
such as CLI diagnostics and agent tool calls

## Tree shape

A content node is exactly one of the following kinds:

- `text`, containing normalized UTF-8
- `hard-break`, representing one U+000A in semantic text
- `element`, containing metadata and immutable ordered children

An element has one of four mechanical kinds. The kind describes structure that
a backend can project without assigning domain meaning

| Element kind | Default semantic boundary | Intended structure |
| --- | --- | --- |
| `inline` | none | Inline children forming one semantic run |
| `flow` | U+000A | Ordered blocks |
| `paragraph` | none | Inline children forming one paragraph |
| `sequence` | U+0009 | Ordered fields or cells |

An element MAY override its default boundary with none, U+0020, U+000A, or
U+0009. A boundary is inserted only between two adjacent direct children. It
is never inserted before the first child or after the last child. Semantic
boundaries are content data and remain independent from any visual separator
chosen by a presentation backend

Elements have an opaque unsigned 64-bit revision. Its default is zero. Nagi
does not compare or increment revisions and semantic projection does not emit
them

## Identifiers and metadata

An element ID is non-empty valid UTF-8. Its remaining contents are opaque, so
applications MAY use spaces, paths, or source-specific identifiers. Element
IDs identify element occurrences and MUST be unique within a tree accepted by
validation

Roles, classes, and annotation IDs use the same portable token grammar:

```text
token   = segment *("." segment)
segment = lower *(lower / digit / "-" / "_")
lower   = %x61-7A
digit   = %x30-39
```

The grammar is ASCII and case-sensitive. Empty segments, uppercase letters,
and other bytes are invalid

A role records application or source semantics such as `heading` or
`diagnostic.code`. A class is an opaque presentation-rule hook such as
`source.ansi.sgr-33-1`; it does not assert semantic meaning. Roles and classes
preserve caller order and MUST NOT repeat within one element

An annotation ID is resolved by the application. Content stores no action,
URI, command, callback, or policy with it. The same annotation ID MAY occur on
more than one element

Byte-oriented identifier construction rejects invalid UTF-8. It never repairs
an identifier. Text construction at a byte-oriented boundary instead replaces
each maximal invalid UTF-8 run with one U+FFFD, using the Nagi Text contract

## Semantic-text projection

Semantic text is projected with a depth-first, left-to-right traversal:

1. A text node appends its stored UTF-8 bytes
2. A hard break appends U+000A
3. An element traverses its children in order and inserts its semantic boundary
   between adjacent children

Projection never derives text from element IDs, roles, classes, annotations,
revisions, or element-kind names

An annotated element produces one half-open UTF-8 byte range. Its range starts
immediately before its first child and ends immediately after its last child,
including boundaries between its children. It excludes a boundary inserted by
its parent. Empty annotated elements produce zero-length ranges

Annotation ranges preserve element preorder: an outer range precedes every
nested range, and earlier sibling ranges precede later sibling ranges. Nested
and overlapping ranges are valid

## Validation and resource limits

Validation is explicit. Constructors do not apply hidden whole-tree limits.
Each limit is an inclusive unsigned 64-bit maximum, so a value is rejected only
when its observed count is greater than the configured value. A zero limit
therefore permits zero of that resource

Validation reports these statistics for an accepted tree:

- node occurrences, including text, hard-break, and element nodes
- maximum depth, where the root has depth one
- semantic UTF-8 bytes, including hard breaks and semantic boundaries
- metadata UTF-8 bytes from element IDs, roles, classes, and annotation IDs
- annotation occurrences
- identified element occurrences
- maximum role-plus-class token count on any one element

A shared subtree used at more than one position is traversed and counted once
per occurrence. The public constructors cannot create cycles

Validation rejects duplicate element IDs. It does not require annotation IDs
to be unique. It stops at the first failure in depth-first, left-to-right
order. On entering a node it checks node count before depth. On entering an
element it then checks token count, metadata bytes, and duplicate element ID,
in that order. Semantic bytes are checked as text, hard breaks, and boundaries
are encountered

The stable validation failure kinds are:

- `node-limit`
- `depth-limit`
- `semantic-byte-limit`
- `metadata-byte-limit`
- `token-limit`
- `duplicate-element-id`

Implementations MUST use traversal that does not consume call stack in
proportion to tree depth

## Ownership and safety

Content values are immutable after construction. Copies of a content root MAY
share all backing storage, and unchanged subtrees MAY be reused in a new root

Content is data, not terminal output. It does not interpret control characters
or execute annotation values. A terminal backend MUST continue to use safe,
typed terminal encoding and a source adapter remains responsible for its own
parsing, redaction, and trust policy
