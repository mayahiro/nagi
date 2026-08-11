# Standard widgets

Standard widgets are composed exclusively from the public Core `Node`, style,
layout, identity, and event-result APIs plus the public Unicode text APIs. They
do not emit terminal sequences, access private runtime state, or receive a
privileged rendering path. Bounded cell graphics may construct a public
Surface and embed it through the public Surface node

Widget constructors return semantic nodes rebuilt by application `view`, so
application state remains the authority for selection, enabled state, progress,
spinner ticks, and modal visibility

## List

- A List receives an application-defined root `NodeId` and one distinct stable
  `NodeId` per item. Position alone is not an item identity
- The List root is one Tab stop. Items are pointer targets but are not
  independently focusable
- A non-empty List clamps an out-of-range selected index to its final item. An
  empty List has no selection
- An enabled non-empty List root declares, in order, `nagi.activate`,
  `nagi.selection.previous`, `nagi.selection.next`, `nagi.selection.first`, and
  `nagi.selection.last`
- Activate defaults to unmodified Enter and Space. Previous defaults to Up,
  Next to Down, First to Home, and Last to End. Initial and explicit repeat
  events are accepted; release and modified keys are not
- An active KeyMap scope replaces each action's complete keyboard binding list,
  including an empty replacement that unbinds that action
- Up and Down move by one without wrapping. Home and End select the first and
  final item. Activation emits the normalized current original item index
- A left-button press selects the pointed item and remains a raw pointer path
  independent from keyboard rebinding
- Navigation that changes selection emits exactly one selection message and
  keeps focus on the List root. Navigation at a boundary is consumed and emits
  no message
- A disabled List or a List with no item after filtering and windowing declares
  every action as `disabled-pass-through` and does not respond to keyboard or
  pointer input
- The selected marker is `> ` and the unselected marker is two spaces. Selected
  and focused styles are independent overlays
- Optional filtering performs ASCII-only case folding and substring matching.
  Non-ASCII text remains exact. Filtering preserves original item indices
- Optional windows and zero-based pagination apply after filtering. Selection
  normalizes to the nearest preceding visible original index, or the first
  visible item
- An optional Core ScrollViewport uses a caller-supplied stable ID and `Length`,
  retains its offset, follows keyboard selection to keep it visible, and
  constructs semantic rows only for the visible range. Filtering and optional
  window calculation still inspect the application-supplied item metadata,
  and the existing List API materializes the complete item collection. A lazy
  collection source uses the Core virtual ScrollViewport directly. A List row
  inside the virtual viewport is exactly one Cell high and clips text that
  would otherwise wrap. The default List tree remains unchanged when no
  viewport is configured

## Button

- An enabled Button is focusable and declares the standard `nagi.activate`
  semantic action with the label `Activate`
- The ordered default bindings are unmodified Enter and Space. Initial and
  explicit repeat events emit exactly one activation message. Key release and
  modified Enter or Space do not activate it
- An active KeyMap scope replaces the complete keyboard binding list for
  `nagi.activate`, including an empty replacement that unbinds it
- Left-button press remains a raw pointer activation path, emits exactly one
  activation message, and is independent from keyboard rebinding. Other mouse
  buttons and pointer release do not activate it
- A disabled Button is neither focusable nor interactive and uses its disabled
  style. Its activation descriptor is `disabled-pass-through`
- The rendered default label is `[ LABEL ]`

## Modal

- A Modal uses the public Core modal node, so routing and tab traversal remain
  restricted to its subtree
- Modal content is centered and enclosed by the public Border primitive
- A non-empty title is the first row inside the border
- The Modal root declares the standard `nagi.dismiss` semantic action with the
  label `Dismiss`. Its default binding is exact unmodified Escape, and initial
  and explicit repeat events emit one dismissal message when a handler exists
- An active KeyMap scope replaces or removes the complete `nagi.dismiss`
  binding list. Rebinding or unbinding does not fall back to raw Escape handling
- Without a dismissal handler, the descriptor is `disabled-pass-through` and
  normal child-to-root routing continues
- Child actions, Core handling, and raw handlers precede the Modal root action.
  A Modal does not implicitly stop outer semantic action propagation; an
  application may attach a `stop-at-scope` KeyScope when that boundary is
  required, without stopping raw ancestor routing
- Visibility remains application state; dismissing does not mutate runtime
  state directly

## Progress

- Progress is determinate and receives unsigned `current`, `total`, and cell
  width values
- Completed cells are `floor(min(current, total) * width / total)`
- A zero total renders zero completed cells. A zero width renders an empty node
- Completed cells use `█` and remaining cells use `░`
- The computation MUST avoid integer overflow for the complete unsigned range

## Spinner

- Spinner is a pure view of an application-owned unsigned tick
- Frames repeat in this order: `⠋`, `⠙`, `⠹`, `⠸`, `⠼`, `⠴`, `⠦`, `⠧`,
  `⠇`, `⠏`
- A non-empty label follows the frame with one ASCII space
- Scheduling is not owned by the widget. Applications normally advance the
  tick with an `Every` subscription

## Scrollbar

- Scrollbar is a pure view of unsigned content length, viewport length, offset,
  and an unsigned 16-bit track length. It does not read or mutate Core
  ScrollViewport state
- If the track is empty, thumb start and length are zero. If content is empty or
  fits in the viewport, the thumb occupies the complete track
- Otherwise thumb length is
  `max(1, floor(viewport * track / content))`, capped to the track. Thumb start
  is `floor(clamp(offset) * (track - thumb) / (content - viewport))`
- All multiplication MUST avoid overflow for the complete unsigned 64-bit
  input range
- Vertical track and thumb cells are `│` and `█`. Horizontal track and thumb
  cells are `─` and `█`

## Checkbox and Radio

- Checkbox renders `[x] LABEL` or `[ ] LABEL` and emits the requested opposite
  Boolean value when activated
- Radio renders `(o) LABEL` or `( ) LABEL`. Activating an unselected Radio emits
  one selection message; activating the selected Radio is consumed without a
  duplicate message
- An enabled Checkbox or Radio is focusable and declares the standard
  `nagi.activate` semantic action with the label `Activate`
- The ordered default bindings are unmodified Enter and Space. Initial and
  explicit repeat events activate the widget. Key release and modified Enter
  or Space do not activate it
- An active KeyMap scope replaces the complete keyboard binding list for
  `nagi.activate`, including an empty replacement that unbinds it
- Left-button press remains a raw pointer activation path and is independent
  from keyboard rebinding. Other mouse buttons and pointer release do not
  activate either widget
- A disabled Checkbox or Radio is neither focusable nor interactive and
  declares its activation descriptor as `disabled-pass-through`
- Radio grouping and mutual exclusion remain application state

## Tabs

- Tabs receives a stable root ID and one distinct stable ID per tab. Selection
  remains application state and is normalized like List selection
- Tabs renders horizontally. The selected label is `[LABEL]`; other labels have
  one surrounding ASCII space
- Every item in enabled non-empty Tabs is independently focusable and owns one
  `nagi.activate` action. Its ordered defaults are unmodified Enter and Space
- The Tabs root owns, in order, `nagi.selection.previous`,
  `nagi.selection.next`, `nagi.selection.first`, and `nagi.selection.last`.
  Their defaults are Left, Right, Home, and End
- Initial and explicit repeat events are accepted. Release and modified keys do
  not match the default bindings
- An active KeyMap scope replaces each action's complete keyboard binding list,
  including an empty replacement that unbinds that action. Item and root groups
  may resolve the same stroke; the focused item has route precedence
- Root navigation starts from application selection rather than the focused
  item. Left and Right move by one without wrapping, while Home and End choose
  the first and final tab. It moves focus to the resulting tab
- Activation selects the focused item. A left-button press selects and focuses
  the pointed item through a raw pointer path independent from keyboard
  rebinding
- Selecting a different tab emits exactly one message. Activation of the
  selected tab and boundary navigation are consumed without a duplicate
  message
- Disabled or empty Tabs expose both item and root descriptors as
  `disabled-pass-through` and do not respond to keyboard or pointer input.
  Disabled items are not focusable

## Select

- Select is a compact, single-focus selector over application-owned option
  strings and selection state
- It renders `< LABEL >`; an empty selector renders its configured placeholder,
  is not focusable, and uses the disabled style
- An enabled non-empty Select declares, in order, `nagi.activate`,
  `nagi.selection.previous`, `nagi.selection.next`, `nagi.selection.first`, and
  `nagi.selection.last`
- Activate defaults to unmodified Enter and Space. Previous defaults to Left and
  Up, Next to Right and Down, First to Home, and Last to End. Initial and
  explicit repeat events are accepted; release and modified keys are not
- An active KeyMap scope replaces each action's complete keyboard binding list,
  including an empty replacement that unbinds that action
- Previous and Next move without wrapping. First and Last choose the boundary
  option. Activate advances to the next option with wrapping
- Left-button press remains a raw activation path, advances with wrapping, and
  is independent from keyboard rebinding
- Navigation that leaves the selection unchanged is consumed without emitting
  a duplicate message
- A disabled or empty Select declares every action as
  `disabled-pass-through` and does not respond to keyboard or pointer input

## Table

- Table receives `Length`-sized columns and stable application-defined row IDs
- Cell text is clipped by public Core layout. Missing cells render empty and
  cells beyond the declared columns are ignored
- The Table root is one Tab stop. The heading and data rows are not independent
  Tab stops. An enabled non-empty root declares the same ordered activation and
  vertical selection action set as List with the same defaults, repeat,
  modifier, override, unbind, and boundary behavior. Activation emits the
  normalized current row index
- A left-button press selects the pointed row and focuses the Table root
- A disabled or empty Table declares every action as
  `disabled-pass-through` and does not respond to keyboard or pointer input
- Column separators are ` │ `, the selected row marker is `> `, and other rows
  use two leading spaces
- Each column independently supports start, center, or end alignment without
  wrapping or splitting graphemes
- An optional body ScrollViewport keeps the header outside the viewport and
  therefore fixed. Its height uses `Length`, its stable ID and offset remain
  Core Runtime state, keyboard selection is kept visible, and semantic row
  construction is bounded by the visible body height. Eager and virtualized
  bodies expose the same single root action group; off-screen rows do not own
  duplicate action descriptors. The existing Table API still materializes the
  complete row metadata collection. A virtualized body row is exactly one Cell
  high and clips multiline content

## Tree

- Tree receives a flat preorder sequence. Each item has a stable ID, label,
  unsigned depth, branch flag, and application-owned expansion state
- A collapsed branch hides following descendants until the first item at the
  same or shallower depth. Selection and expansion callbacks use original
  preorder indices, not visible positions
- If the selected item becomes hidden, selection normalizes to the nearest
  preceding visible item, normally the collapsed ancestor
- An enabled non-empty Tree root declares, in order, `nagi.activate`,
  `nagi.selection.previous`, `nagi.selection.next`, `nagi.selection.first`,
  `nagi.selection.last`, `nagi.collapse`, and `nagi.expand`
- Activate defaults to unmodified Enter and Space. Previous, Next, First, Last,
  Collapse, and Expand default to Up, Down, Home, End, Left, and Right.
  Initial and explicit repeat events are accepted; release and modified keys
  are not
- An active KeyMap scope replaces each action's complete keyboard binding list,
  including an empty replacement that unbinds that action
- Up, Down, Home, and End navigate visible items. Collapse closes an expanded
  branch or selects its nearest visible ancestor. Expand opens a collapsed
  branch or selects its first visible child. Boundary operations are consumed
  without a duplicate message
- Keyboard activation toggles the normalized current branch and consumes leaf
  activation without a message. A missing expansion callback also consumes
  activation, collapse, or expand without a message
- A left-button press remains a raw path independent from keyboard rebinding.
  It selects the pointed item and toggles a branch, emitting selection and
  expansion messages in that order
- The Tree root is one Tab stop. Visible rows remain pointer targets without
  becoming independent Tab stops, and selection navigation keeps root focus
- A disabled or empty Tree declares every action as `disabled-pass-through`
  and does not respond to keyboard or pointer input
- Expanded, collapsed, and leaf markers are `▼ `, `▶ `, and two spaces after
  two spaces per depth level
- An optional positive-height viewport deterministically centers the normalized
  selection where possible and clamps at the first and final visible items.
  The Tree root ID becomes the stable keyboard focus target as rows enter and
  leave the rendered window. Full and viewport layouts expose the same single
  root action group, and non-rendered rows do not duplicate action descriptors
- The optional TreeState utility stores expansion by stable item ID rather than
  preorder position, so expansion survives item reordering. Applying state
  returns independent items and never mutates the source collection

## TextArea

- TextArea receives application-owned UTF-8 text and a UTF-8 byte cursor. State
  constructors clamp an invalid or intra-grapheme cursor down to the preceding
  extended grapheme boundary
- Text and paste insert without Unicode normalization. Enter inserts LF.
  Backspace and Delete remove one extended grapheme cluster, including a CRLF
  line break as one cluster
- Left and Right move by one cluster. Home and End move within the current
  logical line. Up and Down preserve the terminal-cell column where possible
  and otherwise choose the longest grapheme-aligned target prefix that does not
  exceed that column
- CR, LF, and CRLF delimit logical lines. An enabled TextArea renders `▏` at the
  application cursor and uses a focus overlay to identify active editing. A
  disabled TextArea omits the cursor and cannot receive input
- A handled no-op consumes the event without emitting unchanged state
- Go replaces invalid UTF-8 runs before state offsets are calculated; Rust text
  is valid UTF-8 by type
- Selection stores a grapheme-aligned anchor and cursor. Shift with Left,
  Right, Up, Down, Home, or End extends selection; unshifted Left and Right
  collapse it toward the corresponding boundary. Control-A selects all text
- Text, paste, Backspace, and Delete replace or remove the complete selected
  range. Editing clears selection and preserves the configured horizontal
  cell offset
- Horizontal offset omits leading complete graphemes from every logical line.
  An offset inside a wide grapheme advances to its next boundary and never
  renders a partial grapheme
- Control-Z requests undo. Control-Y and Control-Shift-Z request redo when the
  corresponding handler exists. TextAreaHistory is bounded application-owned
  history: content changes create steps, cursor and selection changes do not,
  and a divergent edit clears redo
- A TextArea root declares 18 semantic text actions in this order: cursor left,
  right, up, down, line start, and line end; selection extension for the same
  six directions; select all; delete backward and forward; insert line break;
  undo; and redo. The stable IDs are the corresponding `nagi.text.*` Core
  Action IDs
- Default bindings are exact unmodified Left, Right, Up, Down, Home, End,
  Backspace, Delete, and Enter; the six corresponding Shift-modified movement
  keys; Control-A; Control-Z; and Control-Y followed by Control-Shift-Z for
  redo. All defaults accept explicit repeat events
- Movement and deletion remain enabled at a boundary so a handled no-op is
  consumed. Undo and redo are disabled-pass-through when their corresponding
  callback is absent. Every action is disabled-pass-through when TextArea is
  disabled
- Text and Paste remain raw editing input after local action resolution. A
  KeyMap may therefore bind a single-scalar Text event to an action before raw
  insertion, while Paste always remains one edit and never invokes an action
- Rebinding replaces, and an empty replacement removes, the complete binding
  list without falling back to the former raw keyboard shortcut

## Sparkline

- Sparkline renders the newest unsigned samples within a fixed unsigned 16-bit
  width using `▁▂▃▄▅▆▇█`
- Missing leading samples render spaces. Automatic bounds include all supplied
  samples, including samples outside the visible tail; callers may instead set
  explicit inclusive bounds
- Values clamp to the bounds and scale by integer floor division across seven
  intervals. Empty or constant bounds use `▁`. Scaling is defined without
  overflow for the complete unsigned 64-bit range

## BarChart

- BarChart renders one horizontal row per application-supplied label and
  unsigned value. Labels align to the greatest terminal-cell width
- The bar portion has a fixed unsigned 16-bit width and uses `█` for completed
  cells and `░` for remaining cells. Values optionally follow the bar
- Automatic maximum is the greatest supplied value. An explicit zero maximum
  is valid and renders empty bars. Values above a nonzero maximum clamp to a
  complete bar without overflow

## Chart

- Chart plots ordered series of signed 32-bit integer points into a fixed
  unsigned 16-bit Surface. Adjacent points are connected by deterministic
  integer line rasterization and exact points overwrite lines with a one-cell
  marker
- Automatic bounds include every point in every series. Explicit bounds clamp
  out-of-range points; equal or reversed bounds normalize to a one-unit range
  at the supplied minimum, except at the signed maximum where the minimum is
  reduced by one
- Optional axes reserve the left column and bottom row and use `│`, `─`, and
  `└`. Mapping uses integer floor division and is defined for the complete
  signed 32-bit coordinate range
- A marker that is empty or not exactly one terminal cell falls back to `•`.
  Surface allocation failure returns a same-size Spacer rather than panicking

## Help

- Help renders application-supplied key notation and descriptions without
  owning input handling
- Compact mode joins enabled bindings on one row with a configurable separator.
  Full mode renders one binding per row and aligns descriptions by terminal-cell
  key width
- Disabled bindings are omitted by default. When requested, they remain visible
  with the disabled style merged over their key and description styles

## Paginator

- Paginator uses zero-based application-owned page state and clamps it into the
  supplied total. A zero total has no page and renders `0/0`
- Dot mode uses `●` for the selected page and `○` for other pages. An optional
  indicator limit centers a deterministic page window where possible; zero
  shows every page. Numeric mode renders one-based current and total values
- An enabled non-empty Paginator root declares, in order,
  `nagi.selection.previous`, `nagi.selection.next`, `nagi.selection.first`, and
  `nagi.selection.last`. The previous action has ordered Left, Up, and PageUp
  defaults; next has Right, Down, and PageDown; first and last have Home and End
- Every default is exact unmodified and accepts initial and explicit repeat
  events. An active KeyMap scope replaces or removes each complete action
  binding list without falling back to raw keyboard handling
- Every previous or next binding moves exactly one page. Movement never wraps,
  and boundary no-ops remain enabled and consume without duplicate messages
- Dot and numeric modes expose the same root action group. Neither the root nor
  an indicator declares activation because Enter and Space are not Paginator
  controls
- Left-button press on an unselected dot remains a raw pointer path, emits the
  original zero-based page, and retains the Paginator root as the stable focus
  ID. Pointer input is independent from keyboard rebinding
- A disabled or empty Paginator is not focusable and exposes the four root
  descriptors as `disabled-pass-through`

## FilePicker

- FilePicker receives inert application-owned entry metadata and MUST NOT read
  paths or access the filesystem. Selection, directory traversal, permission
  checks, and errors remain application responsibilities
- Hidden entries are omitted unless explicitly shown. Filtering, viewport
  windows, selection normalization, and callbacks preserve original entry
  indices
- An enabled FilePicker with visible entries declares, in order,
  `nagi.activate`, `nagi.selection.previous`, `nagi.selection.next`,
  `nagi.selection.first`, `nagi.selection.last`,
  `nagi.selection.previous-page`, `nagi.selection.next-page`, and
  `nagi.navigation.back` at its stable root
- Activate has ordered Enter, Space, and Right defaults. Previous, next, first,
  and last use Up, Down, Home, and End. Previous page and next page use PageUp
  and PageDown. Back has ordered Left and Backspace defaults
- Every default is exact unmodified and accepts initial and explicit repeat
  events. An active KeyMap scope replaces or removes each complete action
  binding list without falling back to raw keyboard handling
- Previous and next move one visible entry without wrapping. Page actions move
  by viewport height, or by at most ten visible entries when no viewport exists.
  Boundary no-ops remain enabled, consume without a message, and retain root
  focus
- Activate is enabled only when an open callback exists and emits the selected
  original entry index. Back is enabled only when its callback exists. The six
  selection actions remain independently enabled while selection is available
- The selected entry wrapper owns the root ID and action group as the
  selection-following viewport moves. Non-selected rows remain raw pointer-only
  targets and do not duplicate keyboard actions
- Left-button press on the selected entry retains root focus and requests open
  when available. Press on a non-selected entry emits its original-index
  selection followed by an open request when available. Pointer handling is
  independent from keyboard rebinding
- A disabled picker or one without visible entries is not focusable and exposes
  all eight root descriptors as `disabled-pass-through`. Directory rows use
  `▸ ` and file rows use two spaces

## Calendar

- Calendar uses the proleptic Gregorian calendar for years 1 through 9999 and
  clamps constructed dates, day movement, and month movement to that range
- The month grid contains a centered `YYYY-MM` header, weekday headings, and
  six seven-day rows. Monday is the default first column; Sunday is optional.
  Adjacent-month dates are hidden by default and may be shown and activated.
  Cells beyond the supported year range remain blank
- An enabled Calendar declares, in order, `nagi.activate`,
  `nagi.selection.previous-day`, `nagi.selection.next-day`,
  `nagi.selection.previous-week`, `nagi.selection.next-week`,
  `nagi.selection.previous-month`, `nagi.selection.next-month`,
  `nagi.selection.first-day-of-month`, and
  `nagi.selection.last-day-of-month` at its stable root
- Activate has ordered Enter and Space defaults. Previous and next day use Left
  and Right, previous and next week use Up and Down, previous and next month use
  PageUp and PageDown, and displayed-month boundaries use Home and End
- Every default is exact unmodified and accepts initial and explicit repeat
  events. An active KeyMap scope replaces or removes each complete action
  binding list without falling back to raw keyboard handling
- Day actions move one day, week actions move seven days, month actions move one
  month while clamping the day, and month-boundary actions choose the displayed
  month's first or final day. Supported-range and already-selected boundary
  no-ops remain enabled, consume without a message, and retain root focus
- A selected date outside the displayed month normalizes visually and for key
  movement to the first displayed day. Applications normally rebuild the
  Calendar with the month received from selection callbacks
- The selected date wrapper owns the root ID and action group. Non-selected
  visible dates remain raw left-button-only targets and do not duplicate
  keyboard actions. Pointer handling is independent from keyboard rebinding
- Activation and a left-button press on the selected date consume and retain
  root focus without a message. A left-button press on another visible date
  emits that date and requests root focus
- A disabled Calendar is not focusable and exposes all nine root descriptors as
  `disabled-pass-through`
- Date arithmetic handles Gregorian leap-year rules, including common and leap
  centuries, without locale, timezone, clock, or external date dependencies

## Command Palette

- Command Palette combines a controlled Core TextInput with stable command row
  IDs. Query text and selected original command index remain application state
- A command matches when its label or any keyword contains the query after
  ASCII-only case conversion. Non-ASCII text is compared exactly
- Filtering preserves original indices. A hidden selection normalizes to the
  nearest preceding matching command, or the first match
- Up and Down navigate filtered commands from the query or rows. Home and End
  navigate while a command row is focused; the query retains normal TextInput
  Home and End editing. Enter from the query input activates the selected
  command. Activating a command row may emit selection followed by activation
- An empty result renders a configurable notice and exposes no command focus
  target
- The palette root declares `nagi.activate` followed by the four vertical
  `nagi.selection.*` actions. Each visible command row separately declares
  `nagi.activate`, so row activation has target-to-root precedence over root
  activation. Defaults accept explicit repeat and use exact modifiers
- Query Text and unmodified Home or End are consumed by the local Core
  TextInput before ancestor root actions. Plain-character bindings on the root
  therefore do not replace query editing, while bindings ignored by TextInput
  can be rebound normally
- A disabled palette or an empty filter result exposes root and command action
  descriptors as disabled-pass-through. Left-button row activation remains raw
  pointer handling and is unaffected by keyboard rebinding

## Bounds and text

Widgets rely on Core clipping and Unicode text semantics. Labels are ordinary
UTF-8 text and MUST NOT be converted to raw terminal output. Progress and
Scrollbar track widths are represented by unsigned 16-bit values, bounding one
constructed dimension to 65,535 cells without another runtime limit. Table
columns use the Core `Length` model
