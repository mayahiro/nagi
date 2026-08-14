# Code view

Code support is an optional source adapter and standard widget. Code does not
become a Core Node, Content kind, Presentation selector, syntax language,
application message, file loader, or clipboard backend

## Immutable source

A CodeLine owns ordered styled spans and one semantic UTF-8 logical line

- CR and LF are rejected with a structured `line-break` error because
  CodeDocument owns logical line boundaries
- A styled span boundary must also be an extended grapheme boundary. Splitting
  one grapheme is rejected with a structured `grapheme-boundary` error
- Go replaces each invalid UTF-8 run before validation and storage. Rust input
  is valid UTF-8 by type
- A line containing a Hidden span is not copyable. This prevents a presentation
  choice from implicitly exposing hidden source through a copy callback
- Line clones and copies share immutable backing storage. Input slices are not
  retained where the host language allows later mutation

A CodeDocument owns ordered CodeLines, an optional trailing LF, complete
semantic source text, line byte ranges, and a copyability prefix index

- An empty document and a document containing one empty line are distinct
- A trailing LF is stored only when at least one logical line exists
- A contiguous line range maps to an exact source byte range. The separator
  after the last selected line is excluded, except that an existing trailing LF
  remains part of a range ending at the document end
- Default limits are 100,000 logical lines, 1,000,000 styled spans, and 32 MiB
  of complete semantic UTF-8 text
- Limit failures use stable `line-limit`, `span-limit`, and `text-byte-limit`
  categories and report the configured limit plus first observed value

## Terminal projection

CodeLayout is an immutable projection of one CodeDocument for one terminal
WidthProfile and set of layout options

- The default options use an 80-cell viewport, four-cell tab stops, Modern
  width, no wrapping, and line numbers
- Tabs expand to spaces carrying the tab span style. Semantic source and copy
  requests retain the original tab
- Wrapping is a grapheme-safe hard wrap over the code region. One grapheme
  wider than the code region remains one oversized visual row
- No-wrap mode retains one visual row per logical line and records the complete
  row width for horizontal navigation
- A line-number gutter uses the decimal width of the document line count plus
  three ASCII cells for padding and a separator. The gutter is omitted when
  the viewport cannot leave at least one code cell
- Continuation rows use an ASCII marker so gutter width is independent of the
  selected Modern, CJK, or Custom width profile
- Default projection limits are 1,000,000 visual rows and 64 MiB of expanded
  display text. Limit failures use stable `visual-row-limit` and
  `display-byte-limit` categories
- Layout construction is proportional to projected display content. Layout
  clones and copies share immutable storage

An application rebuilds CodeLayout when viewport width, tab width, wrapping,
line-number visibility, or terminal WidthProfile changes. CodeView does not
silently use a different width policy from the supplied layout

CodeLayoutCache is an optional single-entry memo for immutable `view` methods.
It compares document identity and resource limits, while the application
supplies a key that MUST change whenever any projection option or Custom width
callback behavior changes. Failed projections are not cached

## Controlled widget

CodeView receives a stable root Node ID, one CodeLayout, controlled logical-line
selection and horizontal offset, a viewport height, and application callbacks

- Zero state selects the first logical line. Out-of-range cursor and anchor
  values clamp to the document
- A collapsed state still selects its current complete logical line. An anchor
  represents an inclusive multi-line selection
- Up and Down replace the selection with the previous or next line. Control-Home
  and Control-End select the first or last line
- Shift-Up and Shift-Down extend from the existing anchor. Control-Shift-Home
  and Control-Shift-End extend to the first or last line. Control-A selects all
  lines
- Left and Right change the no-wrap horizontal offset by a configurable positive
  step, four cells by default. The offset clamps to the widest row. Wrapped
  layouts always normalize it to zero
- Navigation and selection bindings accept explicit Repeat. Copy bindings
  accept only an initial press; unmatched repeats of enabled copy bindings are
  consumed locally
- An enabled left-button press selects a logical line. Shift-press extends from
  the existing anchor. Wrapped continuation rows select their source line
- A positive viewport height bounds constructed Nodes and follows the first
  visual row of the current logical line. Zero constructs every visual row
- The root is one Tab stop. Visual rows have stable identities derived from the
  root and visual-row index but do not become Tab stops
- The line-number, continuation, current-line, selected-line, focused-view, and
  disabled styles are independent replaceable slots
- Copy Selection emits independently owned text, logical-line range, and UTF-8
  byte range. Copy Document emits the complete document. Copy is unavailable
  when the requested range contains a Hidden span
- CodeView performs no clipboard I/O and starts no worker, timer, Subscription,
  Effect, parser, syntax highlighter, or file I/O

Character-level selection belongs to SelectableText. Diff parsing, patch
application, repository access, syntax parsing, language detection, and source
redaction remain application or optional-adapter responsibilities

The component has no Agent, Tool, Event, settings-schema, provider, policy, or
credential semantics
