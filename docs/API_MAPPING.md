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
| Variable-height flow | `Node::virtual_flow(...)` | `tui.VirtualFlow[M](...)` |
| Configured variable-height flow | `Node::virtual_flow_with_options(...)` | `tui.VirtualFlowWithOptions[M](...)` |
| Stable flow item | `VirtualFlowItem::new(...)` | `tui.NewVirtualFlowItem(...)` |
| Immutable flow order | `VirtualFlowItems::new(...)` | `tui.NewVirtualFlowItems(...)` |
| Flow content source | `VirtualFlowSource::new(...)` | `tui.NewVirtualFlowSource[M](...)` |
| Flow invalidation | `VirtualFlowUpdate::reset` / `changed` | `tui.ResetVirtualFlowUpdate` / `ChangedVirtualFlowUpdate` |
| Resolved flow state | `InteractionState::virtual_flow_state(...)` | `InteractionState.VirtualFlowState(...)` |
| Modal scope | `Node::modal(...)` | `tui.Modal[M](...)` |
| Configured modal focus | `Node::modal_with_focus(...)` | `tui.ModalWithFocus[M](...)` |
| Modal focus options | `ModalFocusOptions` | `tui.ModalFocusOptions` |
| Modal entry policy | `ModalInitialFocus` | `tui.ModalInitialFocusFirst` / `Target` / `None` |
| Modal return policy | `ModalReturnFocus` | `tui.ModalReturnFocusPrevious` / `Target` / `None` |

Node modifiers follow the same mapping pattern: Rust uses `with_id`,
`focusable`, `tab_stop`, `with_focused_style`, `on_event`, and `with_length`; Go
uses `WithID`, `Focusable`, `TabStop`, `WithFocusedStyle`, `OnEvent`, and
`WithLength`

| Purpose | Rust | Go |
| --- | --- | --- |
| Explicit viewport reveal target | `Node::reveal_descendant(...)` | `Node.RevealDescendant(...)` |
| Disappearing-subtree focus fallback | `Node::focus_fallback(...)` | `Node.FocusFallback(...)` |

`TextSpan::new` and `TextSpan::with_style` map to `tui.NewTextSpan` and
`TextSpan.WithStyle`, while
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
| Focus traversal Action IDs | `FOCUS_NEXT_ACTION_ID` / `FOCUS_PREVIOUS_ACTION_ID` | `tui.FocusNextActionID` / `tui.FocusPreviousActionID` |
| Scroll page Action IDs | `SCROLL_PAGE_UP_ACTION_ID` / `SCROLL_PAGE_DOWN_ACTION_ID` | `tui.ScrollPageUpActionID` / `tui.ScrollPageDownActionID` |
| Scroll boundary Action IDs | `SCROLL_START_ACTION_ID` / `SCROLL_END_ACTION_ID` | `tui.ScrollStartActionID` / `tui.ScrollEndActionID` |
| Standard activate Action ID | `ACTIVATE_ACTION_ID` | `widget.ActivateActionID` |
| Selection previous Action ID | `SELECTION_PREVIOUS_ACTION_ID` | `widget.SelectionPreviousActionID` |
| Selection next Action ID | `SELECTION_NEXT_ACTION_ID` | `widget.SelectionNextActionID` |
| Selection first Action ID | `SELECTION_FIRST_ACTION_ID` | `widget.SelectionFirstActionID` |
| Selection last Action ID | `SELECTION_LAST_ACTION_ID` | `widget.SelectionLastActionID` |
| Selection previous-page Action ID | `SELECTION_PREVIOUS_PAGE_ACTION_ID` | `widget.SelectionPreviousPageActionID` |
| Selection next-page Action ID | `SELECTION_NEXT_PAGE_ACTION_ID` | `widget.SelectionNextPageActionID` |
| Calendar day Action IDs | `SELECTION_PREVIOUS_DAY_ACTION_ID` / `SELECTION_NEXT_DAY_ACTION_ID` | `widget.SelectionPreviousDayActionID` / `widget.SelectionNextDayActionID` |
| Calendar week Action IDs | `SELECTION_PREVIOUS_WEEK_ACTION_ID` / `SELECTION_NEXT_WEEK_ACTION_ID` | `widget.SelectionPreviousWeekActionID` / `widget.SelectionNextWeekActionID` |
| Calendar month Action IDs | `SELECTION_PREVIOUS_MONTH_ACTION_ID` / `SELECTION_NEXT_MONTH_ACTION_ID` | `widget.SelectionPreviousMonthActionID` / `widget.SelectionNextMonthActionID` |
| Calendar month-boundary Action IDs | `SELECTION_FIRST_DAY_OF_MONTH_ACTION_ID` / `SELECTION_LAST_DAY_OF_MONTH_ACTION_ID` | `widget.SelectionFirstDayOfMonthActionID` / `widget.SelectionLastDayOfMonthActionID` |
| Navigation back Action ID | `NAVIGATION_BACK_ACTION_ID` | `widget.NavigationBackActionID` |
| Collapse Action ID | `COLLAPSE_ACTION_ID` | `widget.CollapseActionID` |
| Expand Action ID | `EXPAND_ACTION_ID` | `widget.ExpandActionID` |
| Dismiss Action ID | `DISMISS_ACTION_ID` | `widget.DismissActionID` |
| Confirm Action ID | `CONFIRM_ACTION_ID` | `widget.ConfirmActionID` |
| Composer submit Action ID | `COMPOSER_SUBMIT_ACTION_ID` | `widget.ComposerSubmitActionID` |
| History recall Action IDs | `HISTORY_PREVIOUS_ACTION_ID` / `HISTORY_NEXT_ACTION_ID` | `widget.HistoryPreviousActionID` / `widget.HistoryNextActionID` |
| Text cursor Action IDs | `TEXT_CURSOR_*_ACTION_ID` | `tui.TextCursor*ActionID` |
| Text selection-extension Action IDs | `TEXT_SELECTION_EXTEND_*_ACTION_ID` | `tui.TextSelectionExtend*ActionID` |
| Select-all Action ID | `TEXT_SELECT_ALL_ACTION_ID` | `tui.TextSelectAllActionID` |
| Text deletion Action IDs | `TEXT_DELETE_*_ACTION_ID` | `tui.TextDelete*ActionID` |
| Text line-break, undo, and redo Action IDs | `TEXT_INSERT_LINE_BREAK_ACTION_ID` / `TEXT_UNDO_ACTION_ID` / `TEXT_REDO_ACTION_ID` | `tui.TextInsertLineBreakActionID` / `tui.TextUndoActionID` / `tui.TextRedoActionID` |
| Text copy Action IDs | `TEXT_COPY_SELECTION_ACTION_ID` / `TEXT_COPY_DOCUMENT_ACTION_ID` | `tui.TextCopySelectionActionID` / `tui.TextCopyDocumentActionID` |
| Standard activate descriptor | `activate_action_descriptor` | `widget.ActivateActionDescriptor` |
| Standard dismiss descriptor | `dismiss_action_descriptor` | `widget.DismissActionDescriptor` |
| Standard confirm descriptor | `confirm_action_descriptor` | `widget.ConfirmActionDescriptor` |
| Button action descriptor | `Button::action_descriptor` | `Button.ActionDescriptor` |
| Checkbox action descriptor | `Checkbox::action_descriptor` | `Checkbox.ActionDescriptor` |
| Radio action descriptor | `Radio::action_descriptor` | `Radio.ActionDescriptor` |
| Select action descriptors | `Select::action_descriptors` | `Select.ActionDescriptors` |
| Tabs item action descriptor | `Tabs::item_action_descriptor` | `Tabs.ItemActionDescriptor` |
| Tabs root action descriptors | `Tabs::navigation_action_descriptors` | `Tabs.NavigationActionDescriptors` |
| List action descriptors | `List::action_descriptors` | `List.ActionDescriptors` |
| Table action descriptors | `Table::action_descriptors` | `Table.ActionDescriptors` |
| Tree action descriptors | `Tree::action_descriptors` | `Tree.ActionDescriptors` |
| TextArea action descriptors | `TextArea::action_descriptors` | `TextArea.ActionDescriptors` |
| TextArea soft wrap and no-wrap | `TextArea::soft_wrap` / `no_wrap` | `TextArea.SoftWrap` / `NoWrap` |
| TextArea vertical boundary policy | `TextAreaBoundaryNavigation` / `TextArea::boundary_navigation` | `widget.TextAreaBoundaryNavigation` / `TextArea.BoundaryNavigation` |
| TextArea caret viewport | `TextArea::viewport` | `TextArea.Viewport` |
| Composer action descriptors | `Composer::action_descriptors` | `Composer.ActionDescriptors` |
| Composer row bounds | `Composer::rows` / `visible_rows` | `Composer.Rows` / `VisibleRows` |
| Composer length limits | `Composer::maximum_utf8_bytes` / `maximum_graphemes` | `Composer.MaximumUTF8Bytes` / `MaximumGraphemes` |
| SelectableText action descriptors | `SelectableText::action_descriptors` | `SelectableText.ActionDescriptors` |
| Disclosure | `Disclosure::new` / `body` | `widget.NewDisclosure` / `Disclosure.Body` |
| Disclosure actions | `Disclosure::action_descriptors` | `Disclosure.ActionDescriptors` |
| Dialog action | `DialogAction::new` | `widget.NewDialogAction` |
| Dialog role selection | `Dialog::default_action` / `cancel_action` | `Dialog.DefaultAction` / `CancelAction` |
| Dialog actions | `Dialog::action_descriptors` | `Dialog.ActionDescriptors` |
| Dialog action wrapping | `Dialog::action_wrap_width` | `Dialog.ActionWrapWidth` |
| Confirm default | `ConfirmDialogDefault` | `widget.ConfirmDialogDefaultConfirm` / `ConfirmDialogDefaultCancel` |
| Modal focus builders | `Modal::initial_focus` / `return_focus` | `Modal.InitialFocus` / `ReturnFocus` |
| Command Palette command action descriptor | `CommandPalette::command_action_descriptor` | `CommandPalette.CommandActionDescriptor` |
| Command Palette root action descriptors | `CommandPalette::action_descriptors` | `CommandPalette.ActionDescriptors` |
| Modal action descriptor | `Modal::action_descriptor` | `Modal.ActionDescriptor` |
| Paginator action descriptors | `Paginator::action_descriptors` | `Paginator.ActionDescriptors` |
| FilePicker action descriptors | `FilePicker::action_descriptors` | `FilePicker.ActionDescriptors` |
| Calendar action descriptors | `Calendar::action_descriptors` | `Calendar.ActionDescriptors` |
| Resolved-action Help | `Help::from_resolved_actions` | `widget.NewHelpFromResolvedActions` |

Rust carries Character and Function values inside `KeyCode`. Go uses the
matching private fields exposed through the `KeyStroke.Character` and
`KeyStroke.Function` methods. This representation difference does not change
stroke equality, event matching, notation, scope replacement, or conflict
semantics

The pure resolver remains available independently. Both Runtime implementations
also attach owner groups and scopes to semantic Nodes, resolve the active route,
and expose that exact projection to Help and test consumers. Button, Checkbox,
Radio, Select, each Tabs item, List, Table, Tree, and Command Palette declare
the shared `nagi.activate` action. Select, the Tabs root, List, Table, Tree, and
the Command Palette root declare the four shared selection Action IDs with
widget-owned default bindings. Tree also declares the shared collapse and
expand Action IDs. TextArea declares the 18 Core `nagi.text.*` operations under
its root while retaining Text and Paste as raw editing input. Composer declares
submit and both history operations before those inherited text actions under
the same root. SelectableText declares its 19 Core text selection and copy
operations at one focusable root. Command Palette retains query TextInput handling before its
ancestor root actions. Modal declares the shared `nagi.dismiss` action at its
root and leaves an outer-action propagation boundary opt-in. Dialog declares
`nagi.confirm` followed by `nagi.dismiss`, maps both roles to explicit action
IDs, and uses existing Button activation for each action. Paginator declares
the four shared selection
actions without activation and gives previous and next three ordered fallback
keys each. FilePicker declares activation, all six shared selection actions,
and navigation back at its root with callback-sensitive availability. Calendar
declares activation and eight calendar-scale selection actions at its active
date root. Rust wraps route conflicts in `RuntimeError`; Go returns the
structured conflict directly

## Standard widgets

| Widget | Rust constructor | Go constructor |
| --- | --- | --- |
| List | `List::new` | `widget.NewList` |
| Button | `Button::new` | `widget.NewButton` |
| Modal | `Modal::new` | `widget.NewModal` |
| Disclosure | `Disclosure::new` | `widget.NewDisclosure` |
| Dialog | `Dialog::new` | `widget.NewDialog` |
| ConfirmDialog | `ConfirmDialog::new` | `widget.NewConfirmDialog` |
| Progress | `Progress::new` | `widget.NewProgress` |
| Spinner | `Spinner::new` | `widget.NewSpinner` |
| Scrollbar | `Scrollbar::new` | `widget.NewScrollbar` |
| TextArea | `TextArea::new` | `widget.NewTextArea` |
| Composer | `Composer::new` | `widget.NewComposer` |
| SelectableText | `SelectableText::new` | `widget.NewSelectableText` |
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
| VirtualFeed | `VirtualFeed::new` | `widget.NewVirtualFeed` |

Rust widget builders use snake case and finish with `into_node`, while Go
builders use exported mixed case and finish with `Node`. Examples include
`List::filter` and `List.Filter`, `Table::column_alignment` and
`Table.ColumnAlignment`, `VirtualFeed::unread_indicator` and
`VirtualFeed.UnreadIndicator`, and `FilePicker::show_hidden` and
`FilePicker.ShowHidden`

## Controlled state and item values

| Purpose | Rust | Go |
| --- | --- | --- |
| Multiline edit state | `TextAreaState` | `widget.TextAreaState` |
| Preferred visual column | `TextAreaState::preferred_column` | `TextAreaState.PreferredColumn` |
| Undo and redo history | `TextAreaHistory` | `widget.TextAreaHistory` |
| Composer state | `ComposerState::new` / `at_end` | `widget.NewComposerState` / `NewComposerStateAtEnd` |
| Composer overflow policy | `ComposerOverflowPolicy` | `widget.ComposerOverflowPolicy` |
| Selectable text content | `SelectableTextContent::plain` / `styled` | `widget.NewPlainSelectableTextContent` / `NewSelectableTextContent` |
| Selectable text state | `SelectableTextState::new` / `with_selection` | `widget.NewSelectableTextState` / `NewSelectableTextStateWithSelection` |
| Semantic copy request | `TextCopyRequest` / `TextCopyKind` | `widget.TextCopyRequest` / `TextCopyKind` |
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
