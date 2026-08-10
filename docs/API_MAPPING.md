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

## Scoped key maps

| Purpose | Rust | Go |
| --- | --- | --- |
| Action identity | `ActionId` | `ActionID` |
| Key stroke | `KeyStroke::new` / `character` / `function` | `NewKeyStroke` / `NewCharacterKeyStroke` / `NewFunctionKeyStroke` |
| Event normalization | `KeyStroke::from_event` | `KeyStrokeFromEvent` |
| Key binding | `KeyBinding::new` | `NewKeyBinding` |
| Repeat policy | `RepeatPolicy` | `RepeatPolicy` |
| Binding support | `BindingSupport` | `BindingSupport` |
| Action descriptor | `ActionDescriptor::new` | `NewActionDescriptor` |
| Action and semantic handler | `Action::new` | `NewAction` |
| Semantic invocation | `ActionEvent` | `ActionEvent` |
| Availability | `ActionAvailability` | `ActionAvailability` |
| Immutable override layer | `KeyMap::new().rebind(...)` | `NewKeyMap().Rebind(...)` |
| Duplicate override error | `KeyMapError::DuplicateActionOverride` | `DuplicateActionOverrideError` |
| Active scope | `KeyScope::new` | `NewKeyScope` |
| Scope propagation | `KeyScopePropagation` | `KeyScopePropagation` |
| Attach owner actions | `Node::on_actions` | `Node.OnActions` |
| Attach Key scope | `Node::with_key_scope` | `Node.WithKeyScope` |
| Pure resolution | `resolve_actions` | `ResolveActions` |
| Resolved projection | `ResolvedActions` / `ResolvedAction` | `ResolvedActions` / `ResolvedAction` |
| Structured conflict | `BindingConflictKind` / `BindingConflict` | `BindingConflictKind` / `BindingConflictError` |
| Runtime conflict | `RuntimeError::BindingConflict` | returned `*BindingConflictError` |
| Active Runtime projection | `Runtime::active_action_groups` | `Runtime.ActiveActionGroups` |
| Test-harness projection | `Harness::active_action_groups` | `Harness.ActiveActionGroups` |
| Standard activate Action ID | `ACTIVATE_ACTION_ID` | `widget.ActivateActionID` |
| Selection previous Action ID | `SELECTION_PREVIOUS_ACTION_ID` | `widget.SelectionPreviousActionID` |
| Selection next Action ID | `SELECTION_NEXT_ACTION_ID` | `widget.SelectionNextActionID` |
| Selection first Action ID | `SELECTION_FIRST_ACTION_ID` | `widget.SelectionFirstActionID` |
| Selection last Action ID | `SELECTION_LAST_ACTION_ID` | `widget.SelectionLastActionID` |
| Collapse Action ID | `COLLAPSE_ACTION_ID` | `widget.CollapseActionID` |
| Expand Action ID | `EXPAND_ACTION_ID` | `widget.ExpandActionID` |
| Standard activate descriptor | `activate_action_descriptor` | `widget.ActivateActionDescriptor` |
| Button action descriptor | `Button::action_descriptor` | `Button.ActionDescriptor` |
| Checkbox action descriptor | `Checkbox::action_descriptor` | `Checkbox.ActionDescriptor` |
| Radio action descriptor | `Radio::action_descriptor` | `Radio.ActionDescriptor` |
| Select action descriptors | `Select::action_descriptors` | `Select.ActionDescriptors` |
| Tabs item action descriptor | `Tabs::item_action_descriptor` | `Tabs.ItemActionDescriptor` |
| Tabs root action descriptors | `Tabs::navigation_action_descriptors` | `Tabs.NavigationActionDescriptors` |
| List action descriptors | `List::action_descriptors` | `List.ActionDescriptors` |
| Table action descriptors | `Table::action_descriptors` | `Table.ActionDescriptors` |
| Tree action descriptors | `Tree::action_descriptors` | `Tree.ActionDescriptors` |
| Resolved-action Help | `Help::from_resolved_actions` | `widget.NewHelpFromResolvedActions` |

Rust carries Character and Function values inside `KeyCode`. Go uses the
matching private fields exposed through the `KeyStroke.Character` and
`KeyStroke.Function` methods. This representation difference does not change
stroke equality, event matching, notation, scope replacement, or conflict
semantics

The pure resolver remains available independently. Both Runtime implementations
also attach owner groups and scopes to semantic Nodes, resolve the active route,
and expose that exact projection to Help and test consumers. Button, Checkbox,
Radio, Select, each Tabs item, List, Table, and Tree declare the shared
`nagi.activate` action. Select, the Tabs root, List, Table, and Tree declare the
four shared selection Action IDs with widget-owned default bindings. Tree also
declares the shared collapse and expand Action IDs. Rust wraps route conflicts
in `RuntimeError`; Go returns the structured conflict directly

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
| Effect without a view change | `effect.without_redraw()` | `effect.WithoutRedraw()` |
| Application exit Effect | `Effect::exit()` | `ExitEffect[M]()` |
| Focus Effect | `Effect::focus(id)` | `FocusEffect[M](id)` |
| Scroll Effect | `Effect::scroll_to(id, offset)` | `ScrollToEffect[M](id, offset)` |
| No Subscription | `Subscription::none()` | `NoneSubscription[M]()` |

The allocation-sensitive VT append APIs are `nagi_vt::append_encoded` and
`vt.AppendEncoded`. They append exactly the bytes produced by `encode` and
`Encode` into caller-owned buffers

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
| Option cardinality group | `OptionGroup` | `cli.OptionGroup` |
| Raw, string, integer parser | `raw_parser` / `string_parser` / `integer_parser` | `cli.RawParser` / `StringParser` / `IntegerParser` |
| Finite-value parser | `possible_values_parser` | `cli.PossibleValuesParser` |
| Custom parser | `value_parser` | `cli.CustomParser` |
| Parsed command | `Invocation` | `cli.Invocation` |
| Stable selected command path | `Invocation::command_id_path` | `Invocation.CommandIDPath` |
| Exact command-local scope | `Invocation::scope` / `InvocationScope` | `Invocation.Scope` / `cli.InvocationScope` |
| Command-line presence | `Invocation::supplied` | `Invocation.Supplied` |
| Required typed value | `Invocation::require_value` | `cli.RequireValueAs` |
| Typed access failure | `ValueAccessError` | `cli.ValueAccessError` |
| Typed invocation validator | `InvocationValidator` | `cli.InvocationValidator` |
| Value source | `ValueSource` | `cli.ValueSource` |
| Help Usage Variant definition | `Command::usage_variant` | `Command.UsageVariant` |
| Subcommand Usage presentation | `Command::subcommand_usage` / `SubcommandUsageMode` | `Command.SubcommandUsage` / `cli.SubcommandUsageMode` |
| Structured Help Usage Variant | `HelpUsageVariant` | `cli.HelpUsageVariant` |
| Structured Help | `HelpDocument` | `cli.HelpDocument` |
| Help rendering | `HelpRenderer` | `cli.HelpRenderer` |
| Runtime services | `Context` | `cli.Context` |
| Handler result | `Outcome` | `cli.Outcome` |
| Structured failure | `Diagnostic` / `DiagnosticCode` | `cli.Diagnostic` / `cli.DiagnosticCode` |
| Diagnostic value target | `DiagnosticTarget` | `cli.DiagnosticTarget` |
| Diagnostic meaning | `DiagnosticCategory` | `cli.DiagnosticCategory` |
| Runtime compatibility | `RuntimePolicy` / `ExitCodePolicy` | `cli.RuntimePolicy` / `cli.ExitCodePolicy` |
| Execute a Parse Result | `Command::run_parsed_with_policy` | `Command.RunParsedWithPolicy` |
| Execute an Invocation | `Command::run_invocation_with_policy` | `Command.RunInvocationWithPolicy` |
| Parser-only rendering and status | `RuntimePolicy::render_diagnostic` / `status_for_diagnostic` | `RuntimePolicy.RenderDiagnostic` / `StatusForDiagnostic` |
| Process execution | `Command::run_process` | `Command.RunProcess` |
| Manual cancellation | `cancellation_pair` | `context.WithCancel` with `NewContextWithCancellation` |
| Process-free driver | `nagi_cli_test::TestDriver` | `clitest.Driver` |

Rust stores raw platform values as `OsString` and typed parser results behind
`Any`. Go preserves raw bytes in strings and exposes parser results through
`any` plus generic `ValueAs` and `RequireValueAs` helpers. Both use stable
command-ID paths to disambiguate reused local IDs. Rust cancellation is an
atomic token; Go cancellation is a `context.Context`

These representation differences do not change parsing, structured Help, or
Diagnostic semantics. Each implementation applies the same default Runtime
Policy, while applications may deliberately select a different renderer or
category-to-status mapping. See the [public CLI API guide](CLI_API.md) and
[command application semantics](../spec/cli.md) for the complete contract

See the [public API guide](API.md) and matching Rust and Go examples for
complete TUI application composition
