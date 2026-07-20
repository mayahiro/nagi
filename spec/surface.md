# Cell surfaces

## Cells and styles

Geometry is owned by Nagi Surface. Terminal `Color`, `Attributes`, and `Style`
are owned by Nagi VT and used by Surface without duplication

A cell stores grapheme content, display span, continuation state, style, and
composition opacity. The display span is one or two cells

Styles support default, indexed, and RGB foreground/background
colors, an optional underline color, and the standard bold, dim, italic,
underline, blink, reverse, hidden, and strikethrough attributes

Unsupported terminal attributes MAY be omitted safely by the VT encoder

An opaque blank contains U+0020. A transparent cell has no content and carries
style only. The leading and continuation cells of a two-cell grapheme both
record span two; only the latter has the continuation marker

During transparent composition, non-default foreground and background colors
replace destination colors, an underline color replaces one only when present,
and enabled attributes are combined. Transparent composition cannot clear a
destination color or attribute. An opaque cell replaces the complete
destination cell instead

## Surface invariants

- A surface is a fixed-size cell grid
- A two-cell grapheme and its continuation cell form one indivisible unit
- Overwriting either part of a wide grapheme MUST leave a valid surface
- A standalone zero-width grapheme without a base is rendered as a one-cell
  U+FFFD fallback
- Drawing outside the surface is clipped and MUST NOT panic
- Surface code does not know about applications, nodes, effects, TTYs, or VT
  sequences

Opaque surfaces start as default-style blanks. Transparent surfaces start as
style-free transparent cells. Clear produces opaque blanks; fill and text
drawing clip to the surface. A partly visible wide grapheme is skipped as one
unit. When overwriting either half of an existing wide grapheme, the displaced
unit is first replaced with blanks retaining its style, then the new content is
placed

Surface dimensions and coordinates are unsigned and signed 32-bit values,
respectively, at public drawing boundaries. Constructors reject any dimension
or total cell count greater than 1,048,576. Rust additionally reports a storage
allocation failure. These predictable failures are returned rather than
panicking

A visible cursor is optional. Setting an out-of-bounds cursor hides it. During
composition, a source cursor replaces the destination cursor after applying the
layer offset; a layer without a cursor leaves the destination cursor unchanged

## Diff

Diffing compares complete surfaces and emits changed runs. A changed run MUST
NOT begin or end inside a wide grapheme

Runs use a half-open horizontal interval. If dimensions differ, every non-empty
row of the current surface is one changed run

## Canonical snapshots

The language-independent snapshot format is `nagi-surface-v1`. It records
dimensions and cursor in the header, followed by one line per row and one token
per cell. Each token records content as Unicode scalar values, span,
leading/continuation state, opacity, colors, and attributes. Tokens use a fixed
field order, hexadecimal values use uppercase digits, and every line including
the final line ends in LF
