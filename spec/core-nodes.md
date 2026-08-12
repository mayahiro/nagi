# Core nodes

Core nodes form a closed, deterministic semantic tree. Applications may build
specialized views from public nodes and may embed typed cell surfaces, but view
text never becomes raw terminal output

## Rich text and paragraphs

A text span contains UTF-8 text and one cell style. `RichText` is a paragraph
with hard wrapping and start alignment. `Paragraph` additionally selects word,
hard, or no automatic wrapping and start, center, or end alignment

- CR, LF, and CRLF force line boundaries and are not rendered
- Wrapping never splits an extended grapheme cluster
- Hard wrapping places the final complete grapheme that fits on the current
  line. A grapheme wider than an empty line occupies that line by itself so the
  algorithm always progresses
- Word wrapping uses U+0020 as its only optional break opportunity. A space
  chosen as an automatic boundary and adjacent leading or trailing U+0020
  characters are omitted. A word wider than the available width is hard
  wrapped
- No-wrap mode preserves only explicit line boundaries and clips overflowing
  graphemes at the assigned rectangle
- Start alignment has zero offset. Center alignment uses
  `floor((available - line_width) / 2)`. End alignment uses the complete
  remainder. Lines wider than the rectangle have zero alignment offset
- Each complete grapheme retains the style of its source span, including when
  a line boundary crosses span boundaries
- Go replaces invalid UTF-8 runs before segmentation. Rust input is valid UTF-8
  by type

## ANSI styled text

ANSI Text converts untrusted terminal-like text into ordinary styled text spans
before paragraph layout

- Only SGR color and text-attribute parameters affect output style
- CSI commands other than SGR, OSC, DCS, SOS, PM, APC, standalone escape
  sequences, and non-line-breaking control characters are discarded
- CR, LF, and CRLF retain the ordinary paragraph line-boundary semantics
- No escape or control sequence is passed through to terminal output
- Wrapping and alignment use the same paragraph options as ordinary RichText

## Surface node

A Surface node embeds a fixed-size public Surface as a semantic leaf

- Go captures an independent Surface snapshot when the node is constructed.
  Rust takes ownership of the supplied Surface
- The Surface dimensions are the node's measured size
- Opaque cells replace destination cells. Transparent cells preserve content
  and merge styles using the ordinary Surface composition rules
- Drawing is clipped to both the assigned node rectangle and the inherited
  clip. A partly visible wide grapheme is skipped as one unit
- A visible source cursor is translated with the node. If that cursor is
  outside the visible node rectangle or inherited clip, the destination cursor
  is hidden
- A Go nil Surface produces an empty node
- Surface cells contain normalized graphemes and typed styles, not terminal
  byte sequences. Embedding a Surface does not create a raw VT output path

## Width profile and cursor anchor

Every Core Node uses the Runtime-selected Nagi Text width profile for
measurement and drawing. A captured Surface cell whose stored span disagrees
with that profile is skipped rather than composited with inconsistent geometry.
Built-in border glyphs are replaced by one-cell ASCII `+`, `-`, and `|` when
the selected profile does not measure the configured glyphs as one cell

A cursor anchor occupies zero layout width and one row of height. While its
stable focus owner owns focus, rendering sets the typed Surface cursor at the
anchor position. It draws no visible grapheme and does not move following text.
Out-of-bounds anchors follow the ordinary Surface rule and leave no visible
cursor

## Anchored overlay

An AnchoredOverlay places one front layer relative to a stable Node ID found in
its base subtree

- Only the base contributes to measurement. The overlay can therefore be
  added or removed without changing the surrounding layout
- The assigned AnchoredOverlay rectangle intersected with its inherited clip
  is the placement boundary. An overlay cannot escape that boundary
- The anchor must intersect both its inherited clip and the placement
  boundary. A zero-width, positive-height CursorAnchor is visible as a point
  when its x coordinate is inside both half-open horizontal ranges. An absent,
  fully hidden, or right-edge-outside anchor omits the overlay from rendering,
  semantic indexing, hit testing, and routing
- Placement defaults to below the anchor with start alignment and zero gap.
  Above placement, start, center, or end alignment, a Cell gap, and optional
  maximum width and height are configurable
- Natural overlay size is measured within the configured maxima and placement
  boundary. Zero maxima mean the complete boundary extent rather than a
  zero-sized layer
- Flip fallback uses the opposite vertical side only when the preferred side
  cannot contain the desired height and the opposite side has strictly more
  available rows. Clip fallback retains the preferred side. The result is
  always clipped to its available rows
- Horizontal placement is clamped to the complete boundary after alignment.
  No grapheme or Cell may draw outside the inherited clip
- The base is rendered and indexed first, then the overlay. Overlapping pointer
  hits therefore select the overlay
- Base and overlay are ordinary logical children of the AnchoredOverlay node.
  The primitive creates no focus, modal, action, or hard Event boundary by
  itself

Wrapping a child ScrollViewport with AnchoredOverlay lets the layer use the
outer boundary while the anchor remains clipped by that viewport. Placing the
AnchoredOverlay inside a viewport keeps the complete layer inside the viewport

## Panel

A Panel fills its assigned rectangle, draws a one-cell border, renders an
optional title over the top border, then renders its child inside configured
padding

- Built-in borders are single `┌─┐│└┘`, rounded `╭─╮│╰╯`, double
  `╔═╗║╚╝`, and thick `┏━┓┃┗┛`
- Background fill occurs before border, title, and child rendering
- Content insets are one border cell plus each configured padding component
- A title is omitted when empty or when the panel is narrower than four cells
- A rendered title is one U+0020, the longest grapheme-aligned prefix fitting
  `width - 4` cells, and one U+0020. It begins one cell after the left border
- Every operation remains clipped and zero-sized panels are valid

## Split pane

A SplitPane is the responsive two-child Core layout primitive defined by the
[layout specification](layout.md)

- The primary child, optional one-Cell divider, and secondary child follow the
  configured main-axis order
- Measurement includes both eager child measurements and one divider Cell.
  Actual layout may omit the configured collapse pane under insufficient space
- Only children present in the actual assigned layout enter semantic traversal
- The primitive owns no focus target, input binding, pointer capture, or ratio
  state. Those policies belong to standard widgets or application composition

## Spacing

`Spacer` is an invisible leaf with an explicit width and height. `Gap` is an
invisible leaf interpreted by its immediate linear parent

- A Gap contributes its configured cells to a Row width or Column height and
  contributes zero to the cross axis
- A Gap outside a Row or Column has zero measured size
- Spacer and Gap participate in ordinary `Length` allocation and never draw
  cells or receive events
