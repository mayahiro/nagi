# Diff view

Diff support is an optional immutable source adapter, terminal projection, and
controlled standard widget built on the CodeView projection primitives. It is
not a diff parser, patch model, repository adapter, approval policy, file
loader, or clipboard backend

## Immutable source

DiffLine is one logical display line with a typed kind and one CodeLine

- Metadata carries exact application-provided text and no line numbers
- Hunk carries exact application-provided text plus typed old and new ranges
- Context carries positive old and new line numbers
- Addition carries one positive new line number
- Deletion carries one positive old line number
- Line-number failures are structured and identify the old or new side
- DiffRange accepts zero start only when count is zero and rejects an inclusive
  end that would overflow 64 bits
- A DiffLine clone or copy shares the immutable CodeLine and optional hunk
  metadata backing values

DiffDocument owns ordered DiffLines, an optional trailing LF, a CodeDocument
projection source, conceptual unified-text byte ranges, and a copyability
prefix index

- Metadata and Hunk copy exactly their CodeLine text
- Context, Addition, and Deletion copy an ASCII space, plus, or minus marker
  before their CodeLine text
- Unified text is generated only for a requested copy range. DiffDocument does
  not retain a second complete marker-prefixed source string
- An empty document and a document containing one empty Metadata line are
  distinct
- A trailing LF is present only when at least one logical line exists
- A contiguous logical-line range maps to an exact conceptual UTF-8 byte
  range. The separator after the last selected line is excluded, except that
  an existing trailing LF remains part of a range ending at the document end
- A range containing a Hidden CodeLine span is not copyable
- Default limits are 100,000 logical lines, 1,000,000 styled spans, and 32 MiB
  of conceptual unified UTF-8 text
- Limit failures use stable `line-limit`, `span-limit`, and `text-byte-limit`
  categories and report the configured limit plus first observed value

DiffDocument does not parse or validate hunk header text, infer line numbers,
match changed lines, or require that a partial or streaming document consumes
every declared hunk range

## Terminal projection

DiffLayout projects one DiffDocument through the CodeLayout grapheme, tab,
wrapping, WidthProfile, checkpoint, and resource-limit implementation

- Defaults use an 80-cell viewport, four-cell tab stops, Modern width, no
  wrapping, and old and new line numbers
- A full sticky gutter contains right-aligned old and new numbers, one unified
  marker, and spacing. Its width is derived from the largest supplied line
  numbers and inclusive hunk-range ends
- When the viewport cannot retain the full gutter and at least one content
  cell, projection falls back to a two-cell marker-only gutter. When that also
  cannot fit, the gutter is omitted
- Metadata and Hunk rows use a blank marker. Context, Addition, and Deletion
  rows use space, plus, and minus markers
- Wrapped continuation rows use an ASCII greater-than marker and blank line
  numbers so gutter width is independent of WidthProfile
- Horizontal offset crops only the content region. The gutter remains sticky
- Layout limits and failure categories are the CodeLayout visual-row and
  expanded-display-byte limits
- DiffLayout clones and copies share immutable storage

DiffLayoutCache is an optional single-entry memo. The application key MUST
change for every terminal option or Custom width callback behavior change

## Controlled widget

DiffViewState is the CodeViewState representation because both views use the
same controlled logical-line selection and horizontal-offset contract

- Zero state selects the first logical line and out-of-range values clamp
- Up, Down, Control-Home, Control-End, the four Shift extension bindings,
  Control-A, Left, and Right behave as in CodeView
- Navigation and selection bindings accept explicit Repeat. Copy bindings
  accept only an initial press; unmatched repeats of enabled copy bindings are
  consumed locally
- An enabled left-button press selects a logical line. Shift-press extends from
  the existing anchor
- A positive viewport height bounds constructed Nodes and follows the first
  visual row of the current logical line. Zero constructs every visual row
- Metadata, Hunk, Context, Addition, Deletion, line-number, marker,
  continuation, current-line, selected-line, focused-view, and disabled styles
  are independent replaceable slots
- A line-kind style is the semantic base. CodeLine span styles overlay that
  base for content, line-number and marker styles overlay it for the gutter,
  and current, selection, focus, and disabled styles apply afterward
- Copy Selection and Copy Document emit independently owned unified text,
  logical-line ranges, and conceptual UTF-8 byte ranges
- The root is one Tab stop. Visual rows have derived stable Node IDs but do not
  become Tab stops

Side-by-side layout, intraline matching, diff parsing, patch application,
repository access, source loading, approval policy, redaction, and clipboard
I/O remain application or optional-adapter responsibilities

The component has no Agent, Tool, Event, provider, model, session, credential,
or settings-schema semantics
