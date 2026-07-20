# Rust and Go API mapping

[日本語](API_MAPPING_ja.md)

Nagi keeps observable TUI and CLI behavior aligned while using each language's
normal naming and ownership conventions. This mapping covers the main public
entry points; generated API documentation remains authoritative for complete
method signatures

## Packages

| Responsibility | Rust | Go |
| --- | --- | --- |
| Core runtime and nodes | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Unicode text | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| VT codec, Color, Attributes, Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry and Surface | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| Standard widgets | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Runtime test harness | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |
| CLI command runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` |
| CLI test driver | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |

The Rust `nagi-tui` facade and Go `tui` package re-export the canonical
Geometry and Style types for application-facing APIs

## Core nodes

| Purpose | Rust | Go |
| --- | --- | --- |
| Identity | `NodeId` | `NodeID` |
| Plain text | `Node::text(value)` | `tui.Text[M](value)` |
| Styled text | `Node::styled_text(value, style)` | `tui.StyledText[M](value, style)` |
| Styled spans | `Node::rich_text(spans)` | `tui.RichText[M](spans...)` |
| Wrapped paragraph | `Node::paragraph(spans, options)` | `tui.Paragraph[M](spans, options)` |
| Safe ANSI SGR text | `Node::ansi_text(input, options)` | `tui.ANSIText[M](input, options)` |
| Existing Surface | `Node::surface(surface)` | `tui.SurfaceNode[M](surface)` |
| Fixed empty area | `Node::spacer(width, height)` | `tui.Spacer[M](width, height)` |
| Linear gap | `Node::gap(cells)` | `tui.Gap[M](cells)` |
| Horizontal children | `Node::row(children)` | `tui.Row[M](children...)` |
| Vertical children | `Node::column(children)` | `tui.Column[M](children...)` |
| Layered children | `Node::stack(children)` | `tui.Stack[M](children...)` |
| Insets | `Node::padding(child, insets)` | `tui.Padding[M](child, insets)` |
| Border | `Node::border(child, style)` | `tui.Border[M](child, style)` |
| Titled panel | `Node::panel(child, title)` | `tui.Panel[M](child, title)` |
| Configured panel | `Node::panel_with_options(...)` | `tui.PanelWithOptions[M](...)` |
| Alignment | `Node::align(child, horizontal, vertical)` | `tui.Align[M](child, horizontal, vertical)` |
| Clip | `Node::clip(child)` | `tui.Clip[M](child)` |
| One-line input | `Node::text_input(...)` | `tui.TextInput[M](...)` |
| Styled input | `Node::text_input_styled(...)` | `tui.StyledTextInput[M](...)` |
| Scroll viewport | `Node::scroll_viewport(...)` | `tui.ScrollViewport[M](...)` |
| Configured viewport | `Node::scroll_viewport_with_options(...)` | `tui.ScrollViewportWithOptions[M](...)` |
| Virtual viewport | `Node::virtual_scroll_viewport(...)` | `tui.VirtualScrollViewport[M](...)` |
| Configured virtual viewport | `Node::virtual_scroll_viewport_with_options(...)` | `tui.VirtualScrollViewportWithOptions[M](...)` |
| Visible virtual request | `VirtualViewport` | `tui.VirtualViewport` |
| Virtual fragment | `VirtualFragment::new(...)` | `tui.NewVirtualFragment[M](...)` |
| Modal scope | `Node::modal(...)` | `tui.Modal[M](...)` |

Node modifiers follow the same mapping pattern: Rust uses `with_id`,
`focusable`, `tab_stop`, `with_focused_style`, `on_event`, and `with_length`; Go
uses `WithID`, `Focusable`, `TabStop`, `WithFocusedStyle`, `OnEvent`, and
`WithLength`

`TextSpan::new` maps to `tui.NewTextSpan`, and
`ParagraphOptions::default` maps to `tui.DefaultParagraphOptions`

## Standard widgets

| Widget | Rust constructor | Go constructor |
| --- | --- | --- |
| List | `List::new` | `widget.NewList` |
| Button | `Button::new` | `widget.NewButton` |
| Modal | `Modal::new` | `widget.NewModal` |
| Progress | `Progress::new` | `widget.NewProgress` |
| Spinner | `Spinner::new` | `widget.NewSpinner` |
| Scrollbar | `Scrollbar::new` | `widget.NewScrollbar` |
| TextArea | `TextArea::new` | `widget.NewTextArea` |
| Table | `Table::new` | `widget.NewTable` |
| Tree | `Tree::new` | `widget.NewTree` |
| Tabs | `Tabs::new` | `widget.NewTabs` |
| Checkbox | `Checkbox::new` | `widget.NewCheckbox` |
| Radio | `Radio::new` | `widget.NewRadio` |
| Select | `Select::new` | `widget.NewSelect` |
| Command Palette | `CommandPalette::new` | `widget.NewCommandPalette` |
| Sparkline | `Sparkline::new` | `widget.NewSparkline` |
| BarChart | `BarChart::new` | `widget.NewBarChart` |
| Chart | `Chart::new` | `widget.NewChart` |
| Help | `Help::new` | `widget.NewHelp` |
| Paginator | `Paginator::new` | `widget.NewPaginator` |
| FilePicker | `FilePicker::new` | `widget.NewFilePicker` |
| Calendar | `Calendar::new` | `widget.NewCalendar` |

Rust widget builders use snake case and finish with `into_node`, while Go
builders use exported mixed case and finish with `Node`. Examples include
`List::filter` and `List.Filter`, `Table::column_alignment` and
`Table.ColumnAlignment`, and `FilePicker::show_hidden` and
`FilePicker.ShowHidden`

## Controlled state and item values

| Purpose | Rust | Go |
| --- | --- | --- |
| Multiline edit state | `TextAreaState` | `widget.TextAreaState` |
| Undo and redo history | `TextAreaHistory` | `widget.TextAreaHistory` |
| Tree expansion state | `TreeState` | `widget.TreeState` |
| Gregorian date | `CalendarDate::new` | `widget.NewCalendarDate` |
| File metadata | `FilePickerEntry::file` / `directory` | `widget.NewFilePickerFile` / `NewFilePickerDirectory` |
| Chart point | `ChartPoint::new` | `widget.ChartPoint` struct value |

Selection callbacks receive `usize` in Rust and `int` in Go. Rust constructors
require callbacks, while documented Go constructors treat nil interactive
callbacks as disabled. Go clamps negative indices according to each public
contract; Rust uses unsigned indices

## Runtime and events

| Purpose | Rust | Go |
| --- | --- | --- |
| Application contract | `App` with associated `Message` | `App[Message]` |
| View environment | `ViewContext { size }` | `ViewContext{Size: ...}` |
| Run a terminal app | `run_terminal` | `RunTerminal[M]` |
| Run with external cancellation | Language-specific caller integration | `RunTerminalContext[M]` |
| Ignore event | `EventResult::ignored()` | `IgnoreResult[M]()` |
| Consume event | `EventResult::consumed()` | `ConsumeResult[M]()` |
| Emit one Message | `EventResult::message(value)` | `MessageResult(value)` |
| Global ignore action | `EventAction::Ignore` | `IgnoreAction[M]()` |
| Global exit action | `EventAction::Exit` | `ExitAction[M]()` |
| No Effect | `Effect::none()` | `NoneEffect[M]()` |
| Application exit Effect | `Effect::exit()` | `ExitEffect[M]()` |
| Focus Effect | `Effect::focus(id)` | `FocusEffect[M](id)` |
| Scroll Effect | `Effect::scroll_to(id, offset)` | `ScrollToEffect[M](id, offset)` |
| No Subscription | `Subscription::none()` | `NoneSubscription[M]()` |

`ScrollAxis`, `ScrollOffset`, and `ScrollState` map directly to the Go types of
the same names. Rust test support uses `Harness::scroll_state` and
`Harness::exit_requested`; Go uses `Harness.ScrollState` and
`Harness.ExitRequested`

## CLI command applications

| Purpose | Rust | Go |
| --- | --- | --- |
| Command definition | `Command::new` | `cli.NewCommand` |
| Flag, count, value option | `OptionSpec::flag` / `count` / `value` | `cli.Flag` / `Count` / `ValueOption` |
| Positional argument | `Argument::new` | `cli.Positional` |
| Raw, string, integer parser | `raw_parser` / `string_parser` / `integer_parser` | `cli.RawParser` / `StringParser` / `IntegerParser` |
| Finite-value parser | `possible_values_parser` | `cli.PossibleValuesParser` |
| Custom parser | `value_parser` | `cli.CustomParser` |
| Parsed command | `Invocation` | `cli.Invocation` |
| Value source | `ValueSource` | `cli.ValueSource` |
| Runtime services | `Context` | `cli.Context` |
| Handler result | `Outcome` | `cli.Outcome` |
| Structured failure | `Diagnostic` / `DiagnosticCode` | `cli.Diagnostic` / `cli.DiagnosticCode` |
| Process execution | `Command::run_process` | `Command.RunProcess` |
| Manual cancellation | `cancellation_pair` | `context.WithCancel` with `NewContextWithCancellation` |
| Process-free driver | `nagi_cli_test::TestDriver` | `clitest.Driver` |

Rust stores raw platform values as `OsString` and typed parser results behind
`Any`. Go preserves raw bytes in strings and exposes parser results through
`any` plus the generic `ValueAs` helper. Rust cancellation is an atomic token;
Go cancellation is a `context.Context`

These representation differences do not change parsing, help, diagnostics, or
Exit Status. See the [public CLI API guide](CLI_API.md) and
[command application semantics](../spec/cli.md) for the complete contract

See the [public API guide](API.md) and matching Rust and Go examples for
complete TUI application composition
