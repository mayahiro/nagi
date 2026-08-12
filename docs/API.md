# Public API guide

[日本語](API_ja.md)

Nagi TUI exposes equivalent observable behavior through idiomatic Rust crates
and Go packages. Applications own their model, return declarative semantic
nodes from `view`, and receive messages sequentially through `update`

## Package boundaries

| Responsibility | Rust | Go |
| --- | --- | --- |
| Application, runtime, layout, events, effects, subscriptions | `nagi-tui` | `github.com/mayahiro/nagitui-go` package `tui` |
| Source-neutral structured content | `nagi-content` | `github.com/mayahiro/nagi-go/content` |
| Terminal Presentation Rules | `nagi-tui` | `github.com/mayahiro/nagitui-go` package `tui` |
| Content-to-Node projection | `nagi-tui` | `github.com/mayahiro/nagitui-go` package `tui` |
| Unicode graphemes and terminal width | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| Typed terminal input/output, Color, Attributes, Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry, Cells, surfaces, composition, snapshots | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| Thirty-one standard widgets | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Virtual time and deterministic application driving | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |

Unix terminal bindings remain private implementation details

`nagi-tui` and Go package `tui` re-export the canonical Geometry and terminal
Style types for application convenience. Surface does not define a duplicate
Style type, and the shared Go module does not depend on the TUI module

## Terminal Presentation Rules

`PresentationSheet` is the CSS-like terminal backend for source-neutral
Content. Its ordered `PresentationRule` values use an exact universal, Role,
or Class `PresentationSelector` plus an optional all-of set of open
`PresentationState` tokens

`DeclarationValue` distinguishes Unspecified, Set, and Initial for every text
and layout property. `PresentationSheet::resolve` in Rust and
`PresentationSheet.Resolve` in Go apply matching rules in source order and
return `ComputedPresentation`. Text Style fields inherit from the Style passed
by the caller; display, Length, gap, visual separator, wrap, and alignment do
not inherit

Rule resolution does not use VT Style merging, mutate Content, create Nodes,
map Element IDs, or activate annotations. See the
[Terminal Presentation guide](PRESENTATION.md) for the complete boundary

`project_content` in Rust and `ProjectContent` in Go form the separate bounded
backend bridge. They resolve visited Elements and map Inline, Paragraph, Flow,
and Sequence to styled spans, Paragraph, Column, and Row Nodes. State-aware
variants obtain active States from a synchronous per-element callback

Projection applies explicit limits to Content nodes, generated Nodes, spans,
depth, and visual UTF-8 bytes. It rejects block displays inside inline content,
does not allocate Node IDs or activate annotations, and does not create or
cache VirtualFlow items. See the
[Content-to-Node projection specification](../spec/content-node-projection.md)
for the complete contract

## Application lifecycle

An application implements four operations

1. `init` returns one startup Effect
2. `update` applies one Message and returns follow-up Effects
3. `subscriptions` declares the current stable-key long-lived sources
4. `view` rebuilds a semantic Node tree from application state and a
   `ViewContext` containing the current terminal `Size` and `WidthProfile`

`update` always runs sequentially. Effects and subscriptions may produce work
concurrently, but their results enter the bounded runtime queue before another
update runs. When one terminal read decodes multiple Events, Nagi completes
routing, fallback mapping, input-derived updates, and semantic-tree refresh for
each Event before routing the next one. Surface rendering alone is coalesced
across the input batch. A terminal-suspending Effect discards later Events from
that decoded batch before the runner gives the ordinary terminal to the task

`RuntimeConfig` and `TerminalOptions` select one Nagi Text `WidthProfile` for
the Runtime lifetime. Core measurement, wrapping, drawing, hit geometry, and
cursor placement use it automatically. Width-sensitive widgets expose
`width_profile` in Rust and `WidthProfile` in Go; pass the value from
`ViewContext` when the Runtime does not use Modern width. A Custom override must
return a stable width for the same grapheme throughout the Runtime lifetime

Rust callers using an exhaustive `TerminalOptions` struct literal must provide
the `clipboard` field. A literal using `..TerminalOptions::default()` keeps the
disabled default without further configuration

Rust uses the `App` trait and an associated `Message` type. Go uses the generic
`App[Message]` interface. See the matching
[Rust counter](../nagi-rs/crates/nagi-tui/examples/counter/main.rs) and
[Go counter](../nagitui-go/examples/counter/main.go) for complete minimal
applications

See the [event-driven application architecture](EVENT_DRIVEN_APPLICATIONS.md)
for ownership of process output, timers, wake-up, and rendering in a production
terminal application

An application can return `Effect::exit()` or `ExitEffect` after updating its
state. The terminal runner renders the final dirty view before restoration. Go
also provides `RunTerminalContext` for external `context.Context` cancellation;
that path returns `ctx.Err()` after restoring the terminal. The caller context
is also the parent of Effect and Stream contexts, preserving its values,
deadline, cancellation, and cancellation cause. Manually driven Go runtimes can
use `NewRuntimeContext` or `NewRuntimeWithClockContext` for the same behavior

An application can return `Effect::suspend_terminal` or
`SuspendTerminalEffect` for one blocking, application-owned operation that
needs the ordinary terminal, such as an editor or interactive shell. The
standard runner restores the original terminal and leaves the alternate screen
before running the task on its driver thread. It then resumes configured modes,
re-reads size, discards incomplete pre-suspension input, and forces a full
redraw. Nagi does not select or interpret the external operation

When an update handles a Message without changing anything read by `view`, it
can return `Effect::none().without_redraw()` in Rust or
`tui.NoneEffect[Message]().WithoutRedraw()` in Go. Follow-up Effect work and
subscription reconciliation still occur. Apply the modifier to the outer
Effect returned by `update`; pending dirty state and synchronous UI commands
still produce their required frame

Production terminal runners wait for terminal input, asynchronous Effect or
Stream notifications, resize, and the nearest clock-driven deadline. They do
not poll periodically while idle. Wake-up notifications may coalesce without
changing queue or Delivery semantics. Default terminal options limit
non-urgent rendering to at most 120 frames per second; setting the minimum
frame interval to zero disables that render limit

Recovered Effect panics, unexpected active Stream returns, Stream panics, and
worker-spawn failures enter a separate bounded `RuntimeNotice` FIFO. They do not
become application Messages or dirty the view. Manual Runtime drivers can drain
the queue and inspect its dropped counter; terminal applications can use
`run_terminal_with_notice_handler` or `RunTerminalWithNoticeHandler` and the Go
context-aware variant. The application decides whether a notice becomes state,
a Message, a log record, or telemetry

## Semantic views and interaction

Core nodes include Text, RichText, Paragraph, safe ANSI Text, SurfaceNode,
TextInput, CursorAnchor, Spacer, Gap, Row, Column, ResponsiveRow, Stack,
Overlay, AnchoredOverlay, Padding, Border, Panel, Align, Clip, ScrollViewport,
and Modal. Layout uses integer terminal cells and stable rounding rules.
VirtualScrollViewport and VirtualFlow are the large-content variants

Every stateful, focusable, or event-receiving node needs an application-defined
stable `NodeId`. IDs must survive rebuilding and must not be derived only from a
collection position. Duplicate IDs are runtime errors

Event handlers return composable results that may emit messages, consume the
event, change focus, capture or release the pointer, request one viewport
offset, and request redraw. The public focus-style modifier can overlay a style
while any identified Node owns focus without changing its layout or routing

`Node::cursor_anchor` in Rust and `CursorAnchor` in Go occupy no horizontal
layout width and set the typed Surface cursor while their stable owner has
focus. They draw no caret grapheme, so following text keeps its geometry and
terminal IME placement follows the rendered cursor

`Node::anchored_overlay` in Rust and `AnchoredOverlay` in Go place one front
layer relative to an identified descendant without adding it to measurement.
The configured side, alignment, gap, flip-or-clip fallback, and size maxima are
resolved inside the primitive's visible boundary. A hidden or absent anchor
omits the layer from rendering and routing, while an overlapping visible layer
renders and receives pointer hits after the base. The primitive itself adds no
focus or modal policy. A zero-width CursorAnchor is a valid visible placement
point while its coordinate remains inside the boundary and inherited clip

`Node::responsive_row` and `ResponsiveRow` retain higher-priority arbitrary
Nodes when assigned width is insufficient, then place retained items in start,
center, and end regions. Options may set an exact cross-axis height. Hidden
items are omitted before semantic indexing and lazy virtual preparation.
`Node::overlay` and `Overlay` place one layer over a
base while measuring only the base; Stack continues to measure all layers

`Node::block_unhandled_events` in Rust and `Node.BlockUnhandledEvents` in Go
add an opt-in hard boundary to an identified Node. If its local action, Core,
pointer, and raw handling all leave an Event unconsumed, the boundary consumes
it before ancestor raw handlers or terminal fallback mapping. The default
remains soft

`Node::modal_with_focus` in Rust and `ModalWithFocus` in Go add declarative
modal entry and return policies. Entry selects the first focusable descendant,
a stable target, or no focus; close returns to previous focus, a stable target,
or no focus. The existing modal constructors default to first and previous.
Application-driven disappearance, nested modals, and overlaid sibling modals
use the same last-in-first-out lifecycle. `Node::focus_fallback` and
`Node.FocusFallback` let a disappearing focused subtree prefer an available
stable target before normal deterministic reconciliation

ANSI Text accepts terminal-like log text, applies SGR colors and attributes,
and discards every other control sequence before creating ordinary styled
spans. Both viewport forms can select their axis, follow growing content while
at the end, keep a focused descendant visible, declaratively reveal another
identified descendant, and report resolved `ScrollState`. Use
`Node::reveal_descendant` in Rust or `Node.RevealDescendant` in Go when a caret
or anchor that does not own focus must remain visible. Explicit reveal takes
precedence over focus tracking in the same viewport, nested viewports adjust
inside-out, and automatic reveal does not emit a user-scroll message.
ScrollViewport receives an eager child tree.
VirtualScrollViewport instead receives a complete cell extent and builds one
`VirtualFragment` for the resolved visible `VirtualViewport`; only that
fragment enters semantic traversal. Standard List and Table viewports use this
virtual path for semantic rows. Their existing collection APIs still
materialize all item or row metadata, and List filtering scans it. Applications
that also need lazy collection access should use the Core virtual viewport
directly. Standard List and Table rows inside their virtual viewports are one
Cell high and clip wrapped or multiline content

VirtualFlow accepts an immutable order of unique stable item IDs, a revisioned
invalidation hint, width-aware height estimates, and an item Node builder. It
retains measured heights, a prefix-height index, vertical ScrollState, and a
stable semantic anchor in Interaction State. Appends and tail growth follow the
end only while the viewport remains there. Prepend, removal, reordering,
streaming height changes, and terminal-width changes preserve the first visible
item and intra-item Cell offset while away from the end. Only visible items and
Cell-bounded overscan are built. The viewport has zero intrinsic height, so a
parent must assign a layout length or rectangle. Item content, unread policy,
paging, and persistence remain application-owned

## Scoped key-map foundation

`ActionId` in Rust and `ActionID` in Go identify operations independently from
terminal keys. `KeyStroke` normalizes Key and single-scalar Text input,
`KeyBinding` adds repeat and capability metadata, and an immutable `KeyMap`
layer replaces the complete binding list for an action

`resolve_actions` and `ResolveActions` apply active `KeyScope` values in
root-to-target order to one semantic owner. The result preserves action,
binding, and scope order, filters Help-visible actions without duplicating key
strings, and reports structured duplicate or ambiguous binding conflicts

`Action` pairs a descriptor with a Node-local semantic handler.
`Node::on_actions` and Go `Node.OnActions` attach an ordered owner group;
`Node::with_key_scope` and Go `Node.WithKeyScope` attach an override and
propagation scope. Runtime evaluates the active target-to-root route in
Node-declared action, Core semantic action, non-key Core handling,
geometry-aware pointer handler, raw handler, then ancestor order. An equal
Node-declared binding is evaluated before the separate Core semantic group at
the same owner. Ignored action results and disabled-pass-through bindings
continue routing, while disabled-consume bindings consume without calling a
handler. A disabled-consume binding also blocks an explicit repeat of an
initial-only stroke; enabled and disabled-pass-through matching still enforce
the binding repeat policy

`Node::on_pointer_event` and Go `Node.OnPointerEvent` add a mouse-only handler
without replacing raw `on_event` or `OnEvent`. `PointerEventContext` supplies
signed Node-local geometry, clipping, the Runtime width profile, capture
ownership, the nearest ancestor viewport, and `TextHit` UTF-8 boundaries for a
Paragraph. `edge_scroll` and `EdgeScroll` derive at most one Cell of movement
per received Move Event. Handlers apply it with `EventResult::scroll_to` or
`EventResult.ScrollTo`; explicit Messages are queued before a changed
viewport's callback Message

`stop-at-scope` omits outer ancestor Node-declared and Core semantic action
groups without stopping raw event routing, wheel scrolling, or root-to-target
KeyMap inheritance. Runtime rejects structured within-precedence-group
conflicts before handlers run and exposes active resolved groups through
`active_action_groups` and `ActiveActionGroups`. At one Node the Node-declared
projection precedes the Core projection, so one owner may occur twice. The test
harnesses forward the same projection

Core exposes `nagi.focus.next` and `nagi.focus.previous` Action ID constants
with exact Tab and Shift-Tab defaults. The focused target owns these actions;
without focus the active modal or identified root owns them. KeyMap scopes can
rebind or remove both defaults. A tree without a stable owner keeps default Tab
traversal as a compatibility fallback that cannot be projected or rebound

Core also exposes `nagi.scroll.page-up`, `nagi.scroll.page-down`,
`nagi.scroll.start`, and `nagi.scroll.end` Action ID constants. Each
ScrollViewport owns exact PageUp, PageDown, Home, and End defaults. The nearest
applicable viewport consumes a match, page actions pass through a
horizontal-only viewport, and Both-axis Home or End uses the vertical axis.
Mouse wheel scrolling remains non-key Core handling and is not rebound.
Modified PageUp, PageDown, Home, and End require explicit bindings

`Help::from_resolved_actions` and `NewHelpFromResolvedActions` convert the same
projection into one Help binding per effective key. They preserve action and
binding order, omit Help-hidden actions, and mark unavailable or unsupported
bindings disabled. Existing manual `HelpBinding` construction remains
available

The standard widget packages expose constants for `nagi.activate`, four
single-item and two page-scale `nagi.selection.*` operations,
four line-selection extension operations, two horizontal-scroll operations,
`nagi.navigation.back`, `nagi.collapse`, `nagi.expand`, `nagi.confirm`, and
`nagi.dismiss`. Button, Checkbox, Radio, Select, each Tabs item, List, Table,
Tree, Disclosure, Dialog action Buttons, and Command Palette declare activation
with unmodified Enter and Space defaults. Select
declares all four single-item selection actions under its single owner.
The Tabs root declares them with Left, Right, Home, and End defaults. List,
Table, Tree, and Command Palette roots declare them with Up, Down, Home, and
End defaults. Paginator declares the same four actions without activation;
previous uses Left, Up, and PageUp, while next uses Right, Down, and PageDown.
Tree adds collapse and expand with Left and Right and uses the same single root
action group in full and viewport layouts. FilePicker adds Right as an
activation fallback, page-scale selection, and navigation back. Defaults belong
to each widget even when the Action ID is shared. An active scope may replace
or remove each complete binding list. Left-button press remains raw pointer
handling and is independent from keyboard rebinding

Core also exposes 28 `nagi.text.*` Action ID constants: ten cursor movements,
the corresponding ten selection extensions, select all, backward and forward
deletion, line-break insertion, undo, redo, copy selection, and copy document.
TextArea declares its existing 18-operation editing subset under its
focus-owning root with existing keyboard defaults and explicit-repeat behavior.
Boundary movement and deletion remain enabled and consume without a message by
default. Bubble navigation can instead pass Up and Down through at the first or
last visual line. Opt-in soft wrap makes those actions preserve a preferred
visual column, while Home and End remain logical-line operations. A TextArea
uses the zero-width typed cursor anchor instead of a visible caret character;
its viewport follows an identified cursor anchor without adding a Tab stop.
Undo and redo are disabled-pass-through when their callbacks are absent. Text
and Paste remain raw editing input after local action resolution, and Paste
never invokes an action

SelectableText declares the 19-operation document subset for grapheme, word,
logical-line, and document movement, matching selection extension, select all,
copy selection, and copy document. Content and selection state are controlled
and grapheme-aligned. Copy actions emit an owned application message containing
source ID, semantic text, kind, and original UTF-8 byte range. The application
may turn that message into `Effect::set_clipboard` or `SetClipboardEffect`.
Runtime drivers can inspect or take the latest coalesced `ClipboardRequest`.
The standard terminal runner drops requests by default and emits typed,
write-only OSC 52 only with `TerminalClipboard::Osc52` or
`TerminalClipboardOSC52`. Hidden spans disable both copy actions

Composer layers controlled history recall, submit validity, automatic one-to-six
row height, optional validation content, and UTF-8-byte or grapheme insertion
limits over TextArea without owning message or persistence semantics. It
declares `nagi.composer.submit`, `nagi.history.previous`, and
`nagi.history.next` before the inherited text actions under the same root.
Enter submits without accepting repeat; Shift-Enter, Alt-Enter, and Control-O
insert a line break. Cursor movement takes precedence while another visual line
exists, then Up or Down recalls history. Active scopes can replace the complete
submit and line-break binding lists, and Paste remains editing input. When
submit is invalid, both initial and repeat Enter are consumed locally

SuggestionPopup wraps application-provided content in the generic
AnchoredOverlay and keeps focus in the supplied editor or other focus owner.
The application owns candidate acquisition, query parsing, ranking, stable
candidate IDs, selected ID, asynchronous generation, and acceptance meaning.
`SuggestionItems` validates one immutable unique order and shares its storage
across view rebuilds. The widget builds only a bounded selected window,
displays replaceable Loading and empty Nodes, and declares Enter acceptance,
repeatable Up and Down selection, and Escape dismissal. Its local scope removes
conflicting Composer and TextArea bindings only while Ready candidates are
interactive. Left-button activation emits selection before acceptance without
moving focus

The matching [Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/suggestion_popup/README.md)
and [Go example](../nagitui-go/examples/suggestion-popup/README.md) keep
cancellable latest-result search in the application

JsonInspector receives typed immutable JSON rather than parsing text or
depending on a third-party JSON value. `JsonDocument` validates bounded source
resources once, preserves object order and number spelling, and indexes stable
JSON Pointer paths. The controlled widget keeps selection and expansion in the
application, constructs a bounded selection-following window when requested,
and truncates only displayed String and Number previews. Copy callbacks retain
the complete selected compact value. See the
[JSON inspector specification](../spec/json-inspector.md) and matching
[Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/json_inspector/README.md)
and [Go example](../nagitui-go/examples/json-inspector/README.md)

CodeView receives immutable application-styled logical lines rather than
parsing source or depending on a language engine. `CodeDocument` validates
bounded semantic source once. `CodeLayout` expands tabs and projects one
terminal WidthProfile, viewport width, line-number policy, and wrap policy;
`CodeLayoutCache` avoids repeated projection during immutable view rebuilds.
The controlled view builds only a selection-following visual-row window,
supports complete-line selection and no-wrap horizontal scrolling, and emits
owned source copy requests. See the
[Code view specification](../spec/code-view.md) and matching
[Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/code_view/README.md)
and [Go example](../nagitui-go/examples/code-view/README.md)

DiffView receives immutable typed metadata, hunk, context, addition, and
deletion lines rather than parsing unified diff text. `DiffDocument` validates
line numbers, hunk ranges, conceptual unified byte ranges, copyability, and
resource limits without retaining a complete marker-prefixed string.
`DiffLayout` reuses CodeLayout tab, wrap, WidthProfile, checkpoint, and limit
behavior while adding a sticky old-number, new-number, and marker gutter with
deterministic narrow-terminal fallback. The controlled view shares CodeView
line selection and horizontal scrolling and generates owned unified text only
for copy requests. See the [Diff view specification](../spec/diff-view.md) and
matching
[Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/diff_view/README.md)
and [Go example](../nagitui-go/examples/diff-view/README.md)

Command Palette declares activation plus vertical selection at its root and
activation on each visible command row. Query TextInput editing consumes Text,
Home, and End locally before the ancestor root actions; Enter, Up, and Down
reach the root defaults. Row activation takes target-to-root precedence and
shares selection-then-activation results with raw left-button input. Disabled
or empty-filter palettes expose disabled-pass-through descriptors

Modal declares `nagi.dismiss` at its root with exact unmodified Escape as its
default. A missing dismissal handler makes the descriptor
disabled-pass-through. Child handling retains target-to-root precedence, and
the Modal does not add an implicit action or raw-Event boundary. A KeyMap
stop-at-scope boundary stops only outer semantic actions. Applications that
must isolate approval input can additionally apply the hard unhandled-Event
boundary to the Modal root

Dialog composes an optional title Node, body, controlled lazy Disclosure, and
ordered application-defined actions in a Core Modal. Its root declares
`nagi.confirm` before `nagi.dismiss`. Applications explicitly select default
and cancel action IDs; an unselected role passes through, an enabled target
emits its action message, and an absent or disabled configured target consumes
without escaping. The root confirmation defaults to non-repeating Enter, while
focused action Buttons and Disclosure headers retain child precedence. If the
configured default is absent or disabled, repeat Enter is blocked as well. A
default action also becomes the entry-focus target unless the application
overrides the focus policy. Action rows wrap greedily at an
application-supplied Cell width

ConfirmDialog accepts exactly confirm and cancel actions plus an explicit
Confirm-or-Cancel default. It reuses Dialog focus, wrapping, and lazy details.
Destructive appearance is an application-supplied ButtonStyle rather than a
Nagi policy; applications use generic Dialog for three or more choices

Paginator declares previous, next, first, and last at its stable root in both
dot and numeric modes. Every previous or next fallback moves exactly one page,
boundary actions consume without a message, and unselected dots retain a raw
left-button path independent from keyboard rebinding. Disabled and empty
Paginator descriptors are disabled-pass-through

FilePicker declares activation, four single-item selection actions, two page
selection actions, and navigation back at its selected-entry root. Page
movement uses viewport height or ten entries without a viewport. Activation and
back become disabled-pass-through when their callbacks are absent. Visible
non-selected rows retain raw selection-then-open pointer handling independent
from keyboard rebinding

Trees without actions keep existing Core, raw `OnEvent`, unmigrated-widget, and
terminal `mapEvent` behavior. Tab traversal is still handled before action
routing, and standard widgets other than Button, Checkbox, Radio, Select, Tabs,
List, Table, Tree, Disclosure, SplitPane, Drawer, TextArea, Composer,
SuggestionPopup, SelectableText, JsonInspector, CodeView, DiffView, Command
Palette, Modal, Dialog, ConfirmDialog, Paginator, FilePicker, and Calendar have not yet
migrated. See the
[scoped key-map specification](../spec/keymap.md) for the complete dispatch,
matching, override, conflict, and notation contract

## Effects and subscriptions

Effects represent one-shot work

- `Exit`, `Focus`, `ScrollTo`, and `SetClipboard` are synchronous Runtime UI
  commands and do not start worker threads or goroutines
- `SetClipboard` retains at most the latest pending semantic UTF-8 text,
  independently of view dirtiness
- `SuspendTerminal` runs one application-owned blocking task on the terminal
  driver thread between full-screen suspend and resume boundaries
- `Run` starts anonymous work
- `Latest` replaces keyed work and suppresses stale results
- `Cancel` and scoped cancellation request cooperative termination
- `After` uses the runtime clock
- `Batch` runs children concurrently and `Sequence` runs them in order
- `without_redraw` and `WithoutRedraw` suppress only the frame that an
  otherwise-clean runtime would request for the current update

Go context-aware Runtime and terminal entry points derive worker, terminal-task,
and Stream contexts from the caller context. Runtime close still requests
cooperative child cancellation

Subscriptions represent long-lived stable-key sources

- `Every` emits on the runtime clock
- `Stream` receives cooperative cancellation and a bounded sink
- Reliable delivery blocks a full source inbox
- Latest delivery retains only the newest pending value
- Batch delivery releases FIFO values by count or maximum delay

An active Stream is expected to remain alive. A normal return while its
generation is active produces a Runtime notice; return after requested
cancellation does not. A recovered panic always produces a panic notice

Use VirtualClock-based tests for time-dependent behavior. Do not sleep inside
application tests

## Standard widgets

Standard widgets use public Core composition and the public Unicode text API

- List is one composite Tab stop with root-owned activation and vertical
  selection actions, stable raw pointer targets, filtering, windows,
  pagination, and a `Length` viewport
- Button exposes `nagi.activate` with unmodified Enter and Space defaults and a
  separately routed left-button press
- Modal centers a bordered focus and routing scope, applies configurable first
  and previous focus lifecycle defaults, and declares a root-owned, rebindable
  dismissal action without imposing an ancestor-action boundary
- Progress renders bounded determinate completion without integer overflow
- Spinner renders an application-clock-driven stable frame cycle
- Scrollbar renders overflow-safe vertical or horizontal viewport geometry
- Checkbox and Radio expose the same `nagi.activate` bindings while preserving
  controlled Boolean and consume-without-duplicate group-choice behavior
- Tabs exposes per-item activation and root-owned horizontal selection actions,
  keeping application selection independent from item focus
- Select exposes widget-owned activation and selection defaults through shared
  Action IDs while preserving wrapping activation and boundary consumption
- Table is one composite Tab stop with the same root action set for eager and
  virtualized bodies, sizes columns and its optional body viewport with
  `Length`, keeps its header fixed, and follows keyboard selection
- Tree is one composite Tab stop with root-owned activation, vertical
  selection, collapse, and expand actions over a flat preorder model,
  application-owned expansion state, reusable `TreeState`, and
  selection-following viewports
- TextArea edits multiline text at extended grapheme boundaries with selection,
  no-wrap or opt-in soft-wrap visual lines, preferred-column navigation,
  optional caret-following viewport, application-owned undo and redo history,
  and a root-owned semantic action set whose complete key lists can be rebound
- Composer adds controlled submit, history recall, insertion limits, automatic
  row bounds, and application-provided validation content over TextArea without
  owning message meaning or persistence
- SuggestionPopup composes application-owned candidates and asynchronous state
  with generic anchored placement, bounded row construction, controlled
  selection, keyboard actions, and focus-preserving pointer activation
- SelectableText displays immutable styled content with application-owned,
  grapheme-aligned keyboard and left-drag selection, captures a drag across
  controlled view rebuilds, requests nearest-viewport edge scrolling, and
  emits semantic selection or document copy requests without performing
  clipboard I/O
- JsonInspector displays immutable typed JSON with application-owned selection
  and expansion, bounded visible-row construction, grapheme-safe scalar
  previews, and complete selected-value copy requests. Parsing, schema
  validation, redaction, clipboard policy, and domain meaning stay outside the
  component
- CodeView displays immutable styled logical lines with application-owned line
  selection, memoized terminal-width projection, bounded visual-row Node
  construction, no-wrap horizontal scrolling, and complete-line copy requests.
  Syntax parsing, file I/O, diff meaning, redaction, and clipboard policy stay
  outside the component
- DiffView displays immutable typed diff lines with application-owned line
  selection, memoized terminal projection, sticky old and new line numbers,
  unified markers, bounded visual-row construction, and on-demand unified copy
  requests. Diff parsing, repository access, patch application, approval
  policy, redaction, and clipboard policy stay outside the component
- VirtualFeed composes a flexible VirtualFlow that follows the end by default,
  with application-controlled centered empty, pinned loading-before and
  loading-after, and bottom-end unread-indicator slots
- Disclosure provides a controlled, focusable summary with rebindable toggle,
  collapse, and expand actions, raw pointer toggling, a body builder that is not
  called while collapsed, and nested focus fallback
- SplitPane composes the Core two-pane allocator with a controlled basis-point
  ratio, per-pane minima, deterministic automatic collapse, F6 focus movement,
  axis-aware keyboard resizing, and divider dragging. Pane meaning and state
  persistence remain application-owned
- Drawer lazily constructs a controlled edge overlay only while open. It reuses
  Core Modal focus and routing by default, supports a non-modal mode, and
  declares semantic dismissal without defining outside-click behavior or
  application meaning
- StatusBar composes arbitrary one-row slots through Core ResponsiveRow with
  configurable placement, gap, and low through critical retention categories
  without assigning meaning to status or activity
- ToastRegion overlays the newest bounded suffix of an application-controlled
  Toast sequence without constructing omitted bodies. Tone changes replaceable
  border style, optional dismissal reuses Button activation, and timeout,
  identity generation, collection mutation, and Runtime notice mapping remain
  application-owned
- Dialog composes application-defined actions with explicit default and cancel
  targets, lazy controlled details, modal focus policies, pointer activation,
  and Cell-width action wrapping
- ConfirmDialog provides the explicit-default two-action convenience and
  accepts application-supplied destructive styling
- Command Palette combines controlled query input with root-owned vertical
  actions and row-owned activation over filtered stable command IDs
- Sparkline, BarChart, and Chart provide bounded, deterministic cell graphics
- Help renders compact or aligned manual or resolved-action key bindings
- Paginator provides controlled dot or numeric page navigation through the
  same root-owned, rebindable selection actions
- FilePicker navigates inert application-supplied entry metadata through
  root-owned activation, entry and page selection, and back actions without
  performing filesystem I/O
- Calendar provides a controlled proleptic Gregorian month grid with
  independently rebindable day, week, month, and displayed-month-boundary
  selection actions owned by the active date

The widget galleries survey the complete standard library. The variable-height
feed, dashboard, filtered list, file browser, multi-pane log viewer, and form
validation examples show how the same public nodes and widgets compose into
application-shaped layouts

See the [Rust and Go API mapping](API_MAPPING.md) when translating between
implementations

## Testing

Rust `nagi-tui-test` and Go `tuitest` provide virtual input, size, time, frame
history, message history, Interaction State inspection, controlled effects,
manual subscriptions, supervisor and Runtime-notice diagnostics, resolved
ScrollState and VirtualFlowState, active resolved action groups, and application
exit-request inspection. Input helpers preserve per-Event controlled-state
updates when one byte chunk decodes multiple Events, while coalescing only the
resulting render

Use virtual time and controlled asynchronous sources in application tests so
they do not depend on real sleeps or terminal timing

## Interactive examples

Run Rust commands from `nagi-rs` and Go commands from `nagitui-go` in a real
terminal

| Example | Rust | Go |
| --- | --- | --- |
| Counter | `cargo run -p nagi-tui --example counter` | `go run ./examples/counter` |
| Command palette | `cargo run -p nagi-tui --example command_palette` | `go run ./examples/command-palette` |
| Async search | `cargo run -p nagi-tui --example async_search` | `go run ./examples/async-search` |
| JSON inspector | `cargo run -p nagi-tui-widgets --example json_inspector` | `go run ./examples/json-inspector` |
| Code view | `cargo run -p nagi-tui-widgets --example code_view` | `go run ./examples/code-view` |
| Diff view | `cargo run -p nagi-tui-widgets --example diff_view` | `go run ./examples/diff-view` |
| Event-driven log viewer | `cargo run -p nagi-tui --example log_viewer` | `go run ./examples/log-viewer` |
| Terminal suspend and resume | `cargo run -p nagi-tui --example terminal_suspend` | `go run ./examples/terminal-suspend` |
| Virtual scroll | `cargo run -p nagi-tui --example virtual_scroll` | `go run ./examples/virtual-scroll` |
| Variable-height feed | `cargo run -p nagi-tui-widgets --example virtual_feed` | `go run ./examples/virtual-feed` |
| Widget gallery | `cargo run -p nagi-tui-widgets --example widget_gallery` | `go run ./examples/widget-gallery` |
| Extended widget gallery | `cargo run -p nagi-tui-widgets --example extended_widget_gallery` | `go run ./examples/extended-widget-gallery` |
| Dashboard | `cargo run -p nagi-tui-widgets --example dashboard` | `go run ./examples/dashboard` |
| Filtered list | `cargo run -p nagi-tui-widgets --example filtered_list` | `go run ./examples/filtered-list` |
| File browser | `cargo run -p nagi-tui-widgets --example file_browser` | `go run ./examples/file-browser` |
| Multi-pane log viewer | `cargo run -p nagi-tui-widgets --example multi_pane_log_viewer` | `go run ./examples/multi-pane-log-viewer` |
| Form validation | `cargo run -p nagi-tui-widgets --example form_validation` | `go run ./examples/form-validation` |

Each example directory contains a README describing its purpose, controls, and
limitations

Terminal restoration is best effort on normal return, error, and panic paths.
Application-driven exit renders the final dirty view before restoration.
Application-requested temporary terminal suspension is supported. Process
abort, nested sessions, job-control suspension of the Nagi process, and
`/dev/tty` acquisition are not supported
