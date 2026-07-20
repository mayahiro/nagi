# Public API guide

[日本語](API_ja.md)

Nagi TUI exposes equivalent observable behavior through idiomatic Rust crates
and Go packages. Applications own their model, return declarative semantic
nodes from `view`, and receive messages sequentially through `update`

## Package boundaries

| Responsibility | Rust | Go |
| --- | --- | --- |
| Application, runtime, layout, events, effects, subscriptions | `nagi-tui` | `github.com/mayahiro/nagitui-go` package `tui` |
| Unicode graphemes and terminal width | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| Typed terminal input/output, Color, Attributes, Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry, Cells, surfaces, composition, snapshots | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| Twenty-one standard widgets | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Virtual time and deterministic application driving | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |

Unix terminal bindings remain private implementation details

`nagi-tui` and Go package `tui` re-export the canonical Geometry and terminal
Style types for application convenience. Surface does not define a duplicate
Style type, and the shared Go module does not depend on the TUI module

## Application lifecycle

An application implements four operations

1. `init` returns one startup Effect
2. `update` applies one Message and returns follow-up Effects
3. `subscriptions` declares the current stable-key long-lived sources
4. `view` rebuilds a semantic Node tree from application state and a
   `ViewContext` containing the current terminal `Size`

`update` always runs sequentially. Effects and subscriptions may produce work
concurrently, but their results enter the bounded runtime queue before another
update runs

Rust uses the `App` trait and an associated `Message` type. Go uses the generic
`App[Message]` interface. See the matching
[Rust counter](../nagi-rs/crates/nagi-tui/examples/counter/main.rs) and
[Go counter](../nagitui-go/examples/counter/main.go) for complete minimal
applications

An application can return `Effect::exit()` or `ExitEffect` after updating its
state. The terminal runner renders the final dirty view before restoration. Go
also provides `RunTerminalContext` for external `context.Context` cancellation;
that path returns `ctx.Err()` after restoring the terminal

## Semantic views and interaction

Core nodes include Text, RichText, Paragraph, safe ANSI Text, SurfaceNode,
TextInput, Spacer, Gap, Row, Column, Stack, Padding, Border, Panel, Align, Clip,
ScrollViewport, and Modal. Layout uses integer terminal cells and stable
rounding rules

Every stateful, focusable, or event-receiving node needs an application-defined
stable `NodeId`. IDs must survive rebuilding and must not be derived only from a
collection position. Duplicate IDs are runtime errors

Event handlers return composable results that may emit messages, consume the
event, change focus, capture or release the pointer, and request redraw. The
public focus-style modifier can overlay a style while any identified Node owns
focus without changing its layout or routing

ANSI Text accepts terminal-like log text, applies SGR colors and attributes,
and discards every other control sequence before creating ordinary styled
spans. ScrollViewport can select its axis, follow growing content while at the
end, keep a focused descendant visible, and report resolved `ScrollState`. It
does not virtualize child construction, measurement, or render-tree traversal,
so applications must bound the supplied children for large data sets

## Effects and subscriptions

Effects represent one-shot work

- `Exit`, `Focus`, and `ScrollTo` are synchronous Runtime UI commands and do
  not start worker threads or goroutines
- `Run` starts anonymous work
- `Latest` replaces keyed work and suppresses stale results
- `Cancel` and scoped cancellation request cooperative termination
- `After` uses the runtime clock
- `Batch` runs children concurrently and `Sequence` runs them in order

Subscriptions represent long-lived stable-key sources

- `Every` emits on the runtime clock
- `Stream` receives cooperative cancellation and a bounded sink
- Reliable delivery blocks a full source inbox
- Latest delivery retains only the newest pending value
- Batch delivery releases FIFO values by count or maximum delay

Use VirtualClock-based tests for time-dependent behavior. Do not sleep inside
application tests

## Standard widgets

Standard widgets use public Core composition and the public Unicode text API

- List is one composite Tab stop with application-owned selection, stable item
  pointer targets, filtering, windows, pagination, and a `Length` viewport
- Button activates from Enter, Space, or a left-button press
- Modal centers a bordered focus and routing scope with optional Escape dismiss
- Progress renders bounded determinate completion without integer overflow
- Spinner renders an application-clock-driven stable frame cycle
- Scrollbar renders overflow-safe vertical or horizontal viewport geometry
- Checkbox and Radio expose controlled Boolean and group-choice inputs
- Tabs and Select provide horizontal and compact controlled selection
- Table is one composite Tab stop, sizes columns and its optional body viewport
  with `Length`, keeps its header fixed, and follows keyboard selection
- Tree is one composite Tab stop over a flat preorder model with
  application-owned expansion state, reusable `TreeState`, and
  selection-following viewports
- TextArea edits multiline text at extended grapheme boundaries with selection,
  horizontal scrolling, and application-owned undo and redo history
- Command Palette combines controlled query input, filtering, navigation, and
  activation over stable command IDs
- Sparkline, BarChart, and Chart provide bounded, deterministic cell graphics
- Help renders compact or aligned discoverable key bindings
- Paginator provides controlled dot or numeric page navigation
- FilePicker navigates inert application-supplied entry metadata without
  performing filesystem I/O
- Calendar provides a controlled proleptic Gregorian month grid

The widget galleries survey the complete standard library. The dashboard,
filtered list, file browser, multi-pane log viewer, and form validation examples
show how the same public nodes and widgets compose into application-shaped
layouts

See the [Rust and Go API mapping](API_MAPPING.md) when translating between
implementations

## Testing

Rust `nagi-tui-test` and Go `tuitest` provide virtual input, size, time, frame
history, message history, Interaction State inspection, controlled effects,
manual subscriptions, supervisor diagnostics, resolved ScrollState, and
application exit-request inspection

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
| Log viewer | `cargo run -p nagi-tui --example log_viewer` | `go run ./examples/log-viewer` |
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
Process abort, nested sessions, suspend and resume, and `/dev/tty` acquisition
are not supported
