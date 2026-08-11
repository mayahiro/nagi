# RustとGoのAPI対応表

[English](API_MAPPING.md)

Nagiは外部から観測できるTUIとCLIの挙動を揃えながら、各言語の標準的な命名と所有規約を使用します。この対応表は主要なpublic entry pointを対象とし、完全なmethod signatureは生成されるAPI documentを正とします

## Package

| 責務 | Rust | Go |
| --- | --- | --- |
| Core runtimeとNode | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Unicode text | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| VT codec、Color、Attributes、Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| GeometryとSurface | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| 標準Widget | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Runtime test harness | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |
| CLI command runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` |
| CLI test driver | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |

Rustの`nagi-tui` facadeとGoの`tui` packageはapplication向けAPIでcanonicalなGeometry型とStyle型を再公開します

## Core Node

| 用途 | Rust | Go |
| --- | --- | --- |
| Identity | `NodeId` | `NodeID` |
| Plain text | `Node::text(value)` | `tui.Text[M](value)` |
| Styled text | `Node::styled_text(value, style)` | `tui.StyledText[M](value, style)` |
| Styled span | `Node::rich_text(spans)` | `tui.RichText[M](spans...)` |
| Wrapするparagraph | `Node::paragraph(spans, options)` | `tui.Paragraph[M](spans, options)` |
| 安全なANSI SGR text | `Node::ansi_text(input, options)` | `tui.ANSIText[M](input, options)` |
| 既存Surface | `Node::surface(surface)` | `tui.SurfaceNode[M](surface)` |
| 固定empty area | `Node::spacer(width, height)` | `tui.Spacer[M](width, height)` |
| Linear gap | `Node::gap(cells)` | `tui.Gap[M](cells)` |
| Horizontal child | `Node::row(children)` | `tui.Row[M](children...)` |
| Vertical child | `Node::column(children)` | `tui.Column[M](children...)` |
| Layered child | `Node::stack(children)` | `tui.Stack[M](children...)` |
| Insets | `Node::padding(child, insets)` | `tui.Padding[M](child, insets)` |
| Border | `Node::border(child, style)` | `tui.Border[M](child, style)` |
| Title付きPanel | `Node::panel(child, title)` | `tui.Panel[M](child, title)` |
| 設定付きPanel | `Node::panel_with_options(...)` | `tui.PanelWithOptions[M](...)` |
| Alignment | `Node::align(child, horizontal, vertical)` | `tui.Align[M](child, horizontal, vertical)` |
| Clip | `Node::clip(child)` | `tui.Clip[M](child)` |
| 1行input | `Node::text_input(...)` | `tui.TextInput[M](...)` |
| Styled input | `Node::text_input_styled(...)` | `tui.StyledTextInput[M](...)` |
| Scroll viewport | `Node::scroll_viewport(...)` | `tui.ScrollViewport[M](...)` |
| 設定付きviewport | `Node::scroll_viewport_with_options(...)` | `tui.ScrollViewportWithOptions[M](...)` |
| Virtual viewport | `Node::virtual_scroll_viewport(...)` | `tui.VirtualScrollViewport[M](...)` |
| 設定付きvirtual viewport | `Node::virtual_scroll_viewport_with_options(...)` | `tui.VirtualScrollViewportWithOptions[M](...)` |
| Visible virtual request | `VirtualViewport` | `tui.VirtualViewport` |
| Virtual fragment | `VirtualFragment::new(...)` | `tui.NewVirtualFragment[M](...)` |
| Modal scope | `Node::modal(...)` | `tui.Modal[M](...)` |

Node modifierも同じ対応規則を使用します。Rustの`with_id`、`focusable`、`tab_stop`、`with_focused_style`、`on_event`、`with_length`は、Goの`WithID`、`Focusable`、`TabStop`、`WithFocusedStyle`、`OnEvent`、`WithLength`に対応します

`TextSpan::new`は`tui.NewTextSpan`、`ParagraphOptions::default`は`tui.DefaultParagraphOptions`に対応します

## Scoped KeyMap

| 用途 | Rust | Go |
| --- | --- | --- |
| Action identity | `ActionId` | `ActionID` |
| Key stroke | `KeyStroke::new` / `character` / `function` | `NewKeyStroke` / `NewCharacterKeyStroke` / `NewFunctionKeyStroke` |
| Event normalization | `KeyStroke::from_event` | `KeyStrokeFromEvent` |
| Key binding | `KeyBinding::new` | `NewKeyBinding` |
| Repeat policy | `RepeatPolicy` | `RepeatPolicy` |
| Binding support | `BindingSupport` | `BindingSupport` |
| Action descriptor | `ActionDescriptor::new` | `NewActionDescriptor` |
| Actionとsemantic handler | `Action::new` | `NewAction` |
| Semantic invocation | `ActionEvent` | `ActionEvent` |
| Availability | `ActionAvailability` | `ActionAvailability` |
| Immutable override layer | `KeyMap::new().rebind(...)` | `NewKeyMap().Rebind(...)` |
| Duplicate override error | `KeyMapError::DuplicateActionOverride` | `DuplicateActionOverrideError` |
| Active scope | `KeyScope::new` | `NewKeyScope` |
| Scope propagation | `KeyScopePropagation` | `KeyScopePropagation` |
| Owner actionのattach | `Node::on_actions` | `Node.OnActions` |
| Key scopeのattach | `Node::with_key_scope` | `Node.WithKeyScope` |
| Pure resolution | `resolve_actions` | `ResolveActions` |
| Resolved projection | `ResolvedActions` / `ResolvedAction` | `ResolvedActions` / `ResolvedAction` |
| Structured conflict | `BindingConflictKind` / `BindingConflict` | `BindingConflictKind` / `BindingConflictError` |
| Runtime conflict | `RuntimeError::BindingConflict` | 返却される`*BindingConflictError` |
| Active Runtime projection | `Runtime::active_action_groups` | `Runtime.ActiveActionGroups` |
| Test harness projection | `Harness::active_action_groups` | `Harness.ActiveActionGroups` |
| 標準activate Action ID | `ACTIVATE_ACTION_ID` | `widget.ActivateActionID` |
| Selection previous Action ID | `SELECTION_PREVIOUS_ACTION_ID` | `widget.SelectionPreviousActionID` |
| Selection next Action ID | `SELECTION_NEXT_ACTION_ID` | `widget.SelectionNextActionID` |
| Selection first Action ID | `SELECTION_FIRST_ACTION_ID` | `widget.SelectionFirstActionID` |
| Selection last Action ID | `SELECTION_LAST_ACTION_ID` | `widget.SelectionLastActionID` |
| Collapse Action ID | `COLLAPSE_ACTION_ID` | `widget.CollapseActionID` |
| Expand Action ID | `EXPAND_ACTION_ID` | `widget.ExpandActionID` |
| Text cursor Action ID | `TEXT_CURSOR_*_ACTION_ID` | `tui.TextCursor*ActionID` |
| Text selection extension Action ID | `TEXT_SELECTION_EXTEND_*_ACTION_ID` | `tui.TextSelectionExtend*ActionID` |
| Select all Action ID | `TEXT_SELECT_ALL_ACTION_ID` | `tui.TextSelectAllActionID` |
| Text deletion Action ID | `TEXT_DELETE_*_ACTION_ID` | `tui.TextDelete*ActionID` |
| Text line break、undo、redo Action ID | `TEXT_INSERT_LINE_BREAK_ACTION_ID` / `TEXT_UNDO_ACTION_ID` / `TEXT_REDO_ACTION_ID` | `tui.TextInsertLineBreakActionID` / `tui.TextUndoActionID` / `tui.TextRedoActionID` |
| 標準activate descriptor | `activate_action_descriptor` | `widget.ActivateActionDescriptor` |
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
| Command Palette command action descriptor | `CommandPalette::command_action_descriptor` | `CommandPalette.CommandActionDescriptor` |
| Command Palette root action descriptors | `CommandPalette::action_descriptors` | `CommandPalette.ActionDescriptors` |
| Resolved actionからのHelp | `Help::from_resolved_actions` | `widget.NewHelpFromResolvedActions` |

RustはCharacterとFunctionの値を`KeyCode`内に保持します

Goは対応するprivate fieldを`KeyStroke.Character`と`KeyStroke.Function`のmethodとして公開します

この表現差はstroke equality、event matching、notation、scope replacement、conflict semanticsを変えません

pure resolverは独立したAPIとして引き続き利用できます

両Runtime実装はowner groupとscopeをsemantic Nodeへattachし、active routeをresolveして、そのprojectionをHelpとtest consumerへ公開します

Button、Checkbox、Radio、Select、Tabsの各item、List、Table、Tree、Command Paletteは共有`nagi.activate` actionを宣言します

Select、Tabs root、List、Table、Tree、Command Palette rootはWidget所有のdefault bindingを持つ4個の共有selection Action IDも宣言します

Treeは共有collapseとexpand Action IDも宣言します

TextAreaは18個のCore `nagi.text.*` operationをrootで宣言し、TextとPasteをraw editing inputとして維持します

Command Paletteはancestor root actionより先にqueryのTextInput handlingを維持します

Rustはroute conflictを`RuntimeError`でwrapし、Goはstructured conflictを直接返します

## 標準Widget

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

RustのWidget builderはsnake caseを使用して`into_node`で終わり、Goはexported mixed caseを使用して`Node`で終わります。例として`List::filter`と`List.Filter`、`Table::column_alignment`と`Table.ColumnAlignment`、`FilePicker::show_hidden`と`FilePicker.ShowHidden`が対応します

## Controlled stateとitem value

| 用途 | Rust | Go |
| --- | --- | --- |
| Multiline edit state | `TextAreaState` | `widget.TextAreaState` |
| Undoとredo history | `TextAreaHistory` | `widget.TextAreaHistory` |
| Tree expansion state | `TreeState` | `widget.TreeState` |
| Gregorian date | `CalendarDate::new` | `widget.NewCalendarDate` |
| File metadata | `FilePickerEntry::file` / `directory` | `widget.NewFilePickerFile` / `NewFilePickerDirectory` |
| Chart point | `ChartPoint::new` | `widget.ChartPoint` struct value |

Selection callbackはRustで`usize`、Goで`int`を受け取ります。Rust constructorはcallbackを必須とし、document済みのGo constructorはnilのinteractive callbackをdisabledとして扱います。Goは各public contractに従って負のindexをclampし、Rustはunsigned indexを使用します

## RuntimeとEvent

| 用途 | Rust | Go |
| --- | --- | --- |
| Application contract | associated `Message`を持つ`App` | `App[Message]` |
| View環境 | `ViewContext { size }` | `ViewContext{Size: ...}` |
| Terminal application実行 | `run_terminal` | `RunTerminal[M]` |
| 外部cancellation付き実行 | 言語固有のcaller integration | `RunTerminalContext[M]` |
| Eventをignore | `EventResult::ignored()` | `IgnoreResult[M]()` |
| Eventをconsume | `EventResult::consumed()` | `ConsumeResult[M]()` |
| 1個のMessageをemit | `EventResult::message(value)` | `MessageResult(value)` |
| Global ignore action | `EventAction::Ignore` | `IgnoreAction[M]()` |
| Global exit action | `EventAction::Exit` | `ExitAction[M]()` |
| Effectなし | `Effect::none()` | `NoneEffect[M]()` |
| View変更なしのEffect | `effect.without_redraw()` | `effect.WithoutRedraw()` |
| Application終了Effect | `Effect::exit()` | `ExitEffect[M]()` |
| Focus Effect | `Effect::focus(id)` | `FocusEffect[M](id)` |
| Scroll Effect | `Effect::scroll_to(id, offset)` | `ScrollToEffect[M](id, offset)` |
| Subscriptionなし | `Subscription::none()` | `NoneSubscription[M]()` |

Allocationを抑えたいVT append APIは`nagi_vt::append_encoded`と`vt.AppendEncoded`です。Caller所有bufferへ`encode`と`Encode`が生成するbyteと同一の内容を追記します

`ScrollAxis`、`ScrollOffset`、`ScrollState`はGoの同名typeへ直接対応します。Rust test supportは`Harness::scroll_state`と`Harness::exit_requested`、Goは`Harness.ScrollState`と`Harness.ExitRequested`を使用します

## CLI command application

| 用途 | Rust | Go |
| --- | --- | --- |
| Command定義 | `Command::new` | `cli.NewCommand` |
| Flag、count、value option | `OptionSpec::flag` / `count` / `value` | `cli.Flag` / `Count` / `ValueOption` |
| Positional argument | `Argument::new` | `cli.Positional` |
| Option cardinality group | `OptionGroup` | `cli.OptionGroup` |
| Raw、string、integer parser | `raw_parser` / `string_parser` / `integer_parser` | `cli.RawParser` / `StringParser` / `IntegerParser` |
| Finite-value parser | `possible_values_parser` | `cli.PossibleValuesParser` |
| Custom parser | `value_parser` | `cli.CustomParser` |
| Parsed command | `Invocation` | `cli.Invocation` |
| Stable selected command path | `Invocation::command_id_path` | `Invocation.CommandIDPath` |
| Exact command-local scope | `Invocation::scope` / `InvocationScope` | `Invocation.Scope` / `cli.InvocationScope` |
| Command-line presence | `Invocation::supplied` | `Invocation.Supplied` |
| Required typed value | `Invocation::require_value` | `cli.RequireValueAs` |
| Typed access failure | `ValueAccessError` | `cli.ValueAccessError` |
| Typed Invocation validator | `InvocationValidator` | `cli.InvocationValidator` |
| Value source | `ValueSource` | `cli.ValueSource` |
| Help Usage Variant定義 | `Command::usage_variant` | `Command.UsageVariant` |
| Subcommand Usage presentation | `Command::subcommand_usage` / `SubcommandUsageMode` | `Command.SubcommandUsage` / `cli.SubcommandUsageMode` |
| Structured Help Usage Variant | `HelpUsageVariant` | `cli.HelpUsageVariant` |
| Structured Help | `HelpDocument` | `cli.HelpDocument` |
| Help rendering | `HelpRenderer` | `cli.HelpRenderer` |
| Runtime service | `Context` | `cli.Context` |
| Handler result | `Outcome` | `cli.Outcome` |
| Structured failure | `Diagnostic` / `DiagnosticCode` | `cli.Diagnostic` / `cli.DiagnosticCode` |
| Diagnostic value target | `DiagnosticTarget` | `cli.DiagnosticTarget` |
| Diagnosticの意味 | `DiagnosticCategory` | `cli.DiagnosticCategory` |
| Runtime互換性 | `RuntimePolicy` / `ExitCodePolicy` | `cli.RuntimePolicy` / `cli.ExitCodePolicy` |
| Parse Result実行 | `Command::run_parsed_with_policy` | `Command.RunParsedWithPolicy` |
| Invocation実行 | `Command::run_invocation_with_policy` | `Command.RunInvocationWithPolicy` |
| Parser-only renderingとstatus | `RuntimePolicy::render_diagnostic` / `status_for_diagnostic` | `RuntimePolicy.RenderDiagnostic` / `StatusForDiagnostic` |
| Process実行 | `Command::run_process` | `Command.RunProcess` |
| Manual cancellation | `cancellation_pair` | `context.WithCancel`と`NewContextWithCancellation` |
| Processなしのdriver | `nagi_cli_test::TestDriver` | `clitest.Driver` |

Rustはraw platform valueを`OsString`、typed parser resultを`Any`の背後へ保存します

Goはraw byteをstringへ保持し、parser resultを`any`とgenericな`ValueAs`および`RequireValueAs` helperで公開します

両実装は再利用されたlocal IDをstable command-ID pathで区別します

Rust cancellationはatomic token、Go cancellationは`context.Context`を使用します

これらの表現差はparsing、structured Help、Diagnostic semanticsを変更しません

両実装は同じ既定Runtime Policyを適用し、applicationはrendererまたはcategoryからstatusへのmappingを明示的に変更できます

完全な契約は[public CLI API guide](CLI_API_ja.md)と[command application semantics](../spec/cli.md)を参照してください

TUI application composition全体は[public API guide](API_ja.md)と対応するRustとGoのexampleを参照してください
