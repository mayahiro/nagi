# RustとGoのAPI対応表

[English](API_MAPPING.md)

Nagiは外部から観測できるContent、TUI、CLIの挙動を揃えながら、各言語の標準的な命名と所有規約を使用します。この対応表は主要なpublic entry pointを対象とし、完全なmethod signatureは生成されるAPI documentを正とします

## Package

| 責務 | Rust | Go |
| --- | --- | --- |
| Source-neutral Content | `nagi-content` | `github.com/mayahiro/nagi-go/content` |
| Terminal Presentation Rules | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Core runtimeとNode | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Unicode text | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| VT codec、Color、Attributes、Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| GeometryとSurface | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| 標準Widget | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Runtime test harness | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |
| CLI command runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` |
| CLI shell completion | `nagi-cli-completion` | `github.com/mayahiro/nagicli-go/completion` |
| CLI軽量prompt | `nagi-cli-prompt` | `github.com/mayahiro/nagicli-go/prompt` |
| CLI TTY-aware status | `nagi-cli-status` | `github.com/mayahiro/nagicli-go/status` |
| CLI test driver | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |

Rustの`nagi-tui` facadeとGoの`tui` packageはapplication向けAPIでcanonicalなGeometry型とStyle型を再公開します

## Source-neutral Content

| 用途 | Rust | Go |
| --- | --- | --- |
| Content node | `Content` | `content.Content` |
| Content kind | `ContentKind` | `content.ContentKind` |
| Text | `Content::text(value)` | `content.NewText(value)` |
| Byte-oriented text | `Content::text_bytes(bytes)` | `content.NewTextBytes(bytes)` |
| Hard break | `Content::hard_break()` | `content.NewHardBreak()` |
| Element | `Element` | `content.Element` |
| Element kind | `ElementKind` | `content.ElementKind` |
| Inline element | `Element::new(ElementKind::Inline, children)` | `content.NewInline(children)` |
| Flow element | `Element::new(ElementKind::Flow, children)` | `content.NewFlow(children)` |
| Paragraph element | `Element::new(ElementKind::Paragraph, children)` | `content.NewParagraph(children)` |
| Sequence element | `Element::new(ElementKind::Sequence, children)` | `content.NewSequence(children)` |
| ElementからContentへの変換 | `Element::into_content()` | `Element.Content()` |
| Stable identity | `ElementId::new` / `Element::with_id` | `content.NewElementID` / `Element.WithID` |
| Opaque revision | `Element::with_revision` | `Element.WithRevision` |
| Semantic role | `Role::new` / `Element::with_roles` | `content.NewRole` / `Element.WithRoles` |
| Presentation class | `Class::new` / `Element::with_classes` | `content.NewClass` / `Element.WithClasses` |
| Role membership | `Element::roles().contains(...)` | `Element.HasRole(...)` |
| Class membership | `Element::classes().contains(...)` | `Element.HasClass(...)` |
| Index指定child read | `Element::children()` | `Element.ChildCount()` / `Element.Child(index)` |
| Application annotation | `AnnotationId::new` / `Element::with_annotation` | `content.NewAnnotationID` / `Element.WithAnnotation` |
| Semantic boundary | `SemanticBoundary` / `Element::with_boundary` | `content.SemanticBoundary` / `Element.WithBoundary` |
| Identifier failure | `IdentifierError` / `IdentifierErrorKind` | `content.IdentifierError` / `IdentifierErrorKind` |
| Duplicate roleまたはclass | `DuplicateRole` / `DuplicateClass` | `content.DuplicateRoleError` / `DuplicateClassError` |
| Semantic projection | `semantic_text` / `SemanticText` | `content.ProjectSemanticText` / `SemanticText` |
| Annotation byte range | `AnnotationRange` | `content.AnnotationRange` |
| 明示的validation | `validate(content, limits)` | `content.Validate(value, limits)` |
| Unlimited validation | `Limits::UNLIMITED` | `content.UnlimitedLimits()` |
| Resource result | `Stats` | `content.Stats` |
| Validation failure | `ValidationError` / `ValidationErrorKind` | `content.ValidationError` / `ValidationErrorKind` |

Rustの`Content` cloneとGoの`Content` value copyはimmutableなbacking storageを共有します

Slice accessorはRustでimmutable sliceを返し、Goでdefensive copyを返します

Goのzero `Content`はempty Text、zero `Element`はempty Inlineです

Goのmodifier errorはinvalidなzero-value identifierと未知のnumeric boundaryを拒否し、Rustではvalidated identifierとclosed enumにより同じ状態を表現できません

## Terminal Presentation Rules

| 用途 | Rust | Go |
| --- | --- | --- |
| State token | `PresentationState::new` / `from_bytes` | `tui.NewPresentationState` / `NewPresentationStateBytes` |
| Universal selector | `PresentationSelector::Any` | `tui.AnyPresentationSelector()` |
| Exact Role selector | `PresentationSelector::Role(role)` | `tui.RolePresentationSelector(role)` |
| Exact Class selector | `PresentationSelector::Class(class)` | `tui.ClassPresentationSelector(class)` |
| 3状態property | `DeclarationValue<T>` | `tui.DeclarationValue[T]` |
| Concrete property | `DeclarationValue::Set(value)` | `tui.SetDeclarationValue(value)` |
| Initial property | `DeclarationValue::Initial` | `tui.InitialDeclarationValue[T]()` |
| Text declaration | `TextStyleDeclaration` | `tui.TextStyleDeclaration` |
| Layoutとtext declaration | `PresentationDeclaration` | `tui.PresentationDeclaration` |
| Visual separator declaration | `with_visual_separator` / `visual_separator` | `WithVisualSeparator` / `VisualSeparator` |
| Display | `PresentationDisplay` | `tui.PresentationDisplay` |
| 順序付きRule | `PresentationRule::new` | `tui.NewPresentationRule` |
| Required State | `PresentationRule::with_required_states` | `PresentationRule.Requiring` |
| Immutable Sheet | `PresentationSheet::new` | `tui.NewPresentationSheet` |
| Resolution | `PresentationSheet::resolve` | `PresentationSheet.Resolve` |
| Computed result | `ComputedPresentation` | `tui.ComputedPresentation` |
| Stateなしprojection | `project_content` | `tui.ProjectContent[M]` |
| Element単位State付きprojection | `project_content_with_states` | `tui.ProjectContentWithStates[M]` |
| Projection option | `ContentProjectionOptions` | `tui.ContentProjectionOptions` |
| Projection limit | `ContentProjectionLimits` | `tui.ContentProjectionLimits` |
| Projection failure | `ContentProjectionError` / `ContentProjectionErrorKind` | `tui.ContentProjectionError` / `ContentProjectionErrorKind` |

両実装は`element`、inherited Style、active Stateの順で解決します

Rule orderだけをcascade priorityとし、Text Style fieldはinheritし、layout fieldはinheritしません

ResultはvalueでありNodeを生成しません

Rustのcomputed resultはconcreteなvisual separatorをSheetからborrowします

Goのcomputed resultはimmutableなstring storageをvalueとして保持します

両projection APIは通常のframe-owned Nodeを返し、同じ5個のresource limitを適用します

Content identityからNode identityを導出せず、annotationをapplication actionへ変換しません

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
| Priority対応horizontal child | `Node::responsive_row(items, options)` | `tui.ResponsiveRow[M](items, options)` |
| Responsive item | `ResponsiveRowItem::new(node)` | `tui.NewResponsiveRowItem[M](node)` |
| Responsive配置とoption | `ResponsiveRowPlacement` / `ResponsiveRowOptions` | `tui.ResponsiveRowPlacement` / `tui.ResponsiveRowOptions` |
| Responsive two-pane layout | `Node::split_pane(primary, secondary, options)` | `tui.SplitPane[M](primary, secondary, options)` |
| Split-pane option | `SplitPaneOptions` | `tui.SplitPaneOptions` / `DefaultSplitPaneOptions` |
| Split axisとcollapse target | `SplitPaneAxis` / `SplitPaneCollapse` | `tui.SplitPaneAxis` / `tui.SplitPaneCollapse` |
| Layered child | `Node::stack(children)` | `tui.Stack[M](children...)` |
| Base-measured front layer | `Node::overlay(base, layer)` | `tui.Overlay[M](base, layer)` |
| Anchor付きfront layer | `Node::anchored_overlay(...)` | `tui.AnchoredOverlay[M](...)` |
| 設定付きanchor layer | `Node::anchored_overlay_with_options(...)` | `tui.AnchoredOverlayWithOptions[M](...)` |
| Anchor配置option | `AnchoredOverlayOptions` | `tui.AnchoredOverlayOptions` |
| Insets | `Node::padding(child, insets)` | `tui.Padding[M](child, insets)` |
| Border | `Node::border(child, style)` | `tui.Border[M](child, style)` |
| Title付きPanel | `Node::panel(child, title)` | `tui.Panel[M](child, title)` |
| 設定付きPanel | `Node::panel_with_options(...)` | `tui.PanelWithOptions[M](...)` |
| Alignment | `Node::align(child, horizontal, vertical)` | `tui.Align[M](child, horizontal, vertical)` |
| Clip | `Node::clip(child)` | `tui.Clip[M](child)` |
| 1行input | `Node::text_input(...)` | `tui.TextInput[M](...)` |
| Styled input | `Node::text_input_styled(...)` | `tui.StyledTextInput[M](...)` |
| Zero-width typed cursor | `Node::cursor_anchor(owner)` | `tui.CursorAnchor[M](owner)` |
| Scroll viewport | `Node::scroll_viewport(...)` | `tui.ScrollViewport[M](...)` |
| 設定付きviewport | `Node::scroll_viewport_with_options(...)` | `tui.ScrollViewportWithOptions[M](...)` |
| Virtual viewport | `Node::virtual_scroll_viewport(...)` | `tui.VirtualScrollViewport[M](...)` |
| 設定付きvirtual viewport | `Node::virtual_scroll_viewport_with_options(...)` | `tui.VirtualScrollViewportWithOptions[M](...)` |
| Visible virtual request | `VirtualViewport` | `tui.VirtualViewport` |
| Virtual fragment | `VirtualFragment::new(...)` | `tui.NewVirtualFragment[M](...)` |
| 可変高flow | `Node::virtual_flow(...)` | `tui.VirtualFlow[M](...)` |
| 設定付き可変高flow | `Node::virtual_flow_with_options(...)` | `tui.VirtualFlowWithOptions[M](...)` |
| 安定flow item | `VirtualFlowItem::new(...)` | `tui.NewVirtualFlowItem(...)` |
| Immutable flow order | `VirtualFlowItems::new(...)` | `tui.NewVirtualFlowItems(...)` |
| Flow content source | `VirtualFlowSource::new(...)` | `tui.NewVirtualFlowSource[M](...)` |
| Flow invalidation | `VirtualFlowUpdate::reset` / `changed` | `tui.ResetVirtualFlowUpdate` / `ChangedVirtualFlowUpdate` |
| 解決済みflow state | `InteractionState::virtual_flow_state(...)` | `InteractionState.VirtualFlowState(...)` |
| Modal scope | `Node::modal(...)` | `tui.Modal[M](...)` |
| Focus設定付きModal | `Node::modal_with_focus(...)` | `tui.ModalWithFocus[M](...)` |
| Modal focus option | `ModalFocusOptions` | `tui.ModalFocusOptions` |
| Modal entry policy | `ModalInitialFocus` | `tui.ModalInitialFocusFirst` / `Target` / `None` |
| Modal return policy | `ModalReturnFocus` | `tui.ModalReturnFocusPrevious` / `Target` / `None` |

Node modifierも同じ対応規則を使用します。Rustの`with_id`、`focusable`、`tab_stop`、`with_focused_style`、`on_event`、`with_length`は、Goの`WithID`、`Focusable`、`TabStop`、`WithFocusedStyle`、`OnEvent`、`WithLength`に対応します

| 用途 | Rust | Go |
| --- | --- | --- |
| 明示的なviewport内target表示 | `Node::reveal_descendant(...)` | `Node.RevealDescendant(...)` |
| 消えるsubtreeのfocus fallback | `Node::focus_fallback(...)` | `Node.FocusFallback(...)` |
| Hard unhandled-Event boundary | `Node::block_unhandled_events()` | `Node.BlockUnhandledEvents()` |

`TextSpan::new`と`TextSpan::with_style`は`tui.NewTextSpan`と`TextSpan.WithStyle`、`ParagraphOptions::default`は`tui.DefaultParagraphOptions`に対応します

## Scoped KeyMap

| 用途 | Rust | Go |
| --- | --- | --- |
| Action identity | `ActionId` | `ActionID` |
| Key stroke | `KeyStroke::new` / `character` / `function` | `NewKeyStroke` / `NewCharacterKeyStroke` / `NewFunctionKeyStroke` |
| Protocol functional-key stroke | `KeyStroke::new(KeyCode::Functional(...), ...)` | `NewFunctionalKeyStroke` |
| Event normalization | `KeyStroke::from_event` | `KeyStrokeFromEvent` |
| Key binding | `KeyBinding::new` | `NewKeyBinding` |
| Strokeだけを使うblocking match | `KeyBinding::matches_stroke` | `KeyBinding.MatchesStroke` |
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
| Focus traversal Action ID | `FOCUS_NEXT_ACTION_ID` / `FOCUS_PREVIOUS_ACTION_ID` | `tui.FocusNextActionID` / `tui.FocusPreviousActionID` |
| Scroll page Action ID | `SCROLL_PAGE_UP_ACTION_ID` / `SCROLL_PAGE_DOWN_ACTION_ID` | `tui.ScrollPageUpActionID` / `tui.ScrollPageDownActionID` |
| Scroll境界Action ID | `SCROLL_START_ACTION_ID` / `SCROLL_END_ACTION_ID` | `tui.ScrollStartActionID` / `tui.ScrollEndActionID` |
| 標準activate Action ID | `ACTIVATE_ACTION_ID` | `widget.ActivateActionID` |
| Selection previous Action ID | `SELECTION_PREVIOUS_ACTION_ID` | `widget.SelectionPreviousActionID` |
| Selection next Action ID | `SELECTION_NEXT_ACTION_ID` | `widget.SelectionNextActionID` |
| Selection first Action ID | `SELECTION_FIRST_ACTION_ID` | `widget.SelectionFirstActionID` |
| Selection last Action ID | `SELECTION_LAST_ACTION_ID` | `widget.SelectionLastActionID` |
| Selection extension Action ID | `SELECTION_EXTEND_*_ACTION_ID` | `widget.SelectionExtend*ActionID` |
| Selection previous page Action ID | `SELECTION_PREVIOUS_PAGE_ACTION_ID` | `widget.SelectionPreviousPageActionID` |
| Selection next page Action ID | `SELECTION_NEXT_PAGE_ACTION_ID` | `widget.SelectionNextPageActionID` |
| Horizontal scroll Action ID | `HORIZONTAL_SCROLL_PREVIOUS_ACTION_ID` / `HORIZONTAL_SCROLL_NEXT_ACTION_ID` | `widget.HorizontalScrollPreviousActionID` / `widget.HorizontalScrollNextActionID` |
| Calendar day Action ID | `SELECTION_PREVIOUS_DAY_ACTION_ID` / `SELECTION_NEXT_DAY_ACTION_ID` | `widget.SelectionPreviousDayActionID` / `widget.SelectionNextDayActionID` |
| Calendar week Action ID | `SELECTION_PREVIOUS_WEEK_ACTION_ID` / `SELECTION_NEXT_WEEK_ACTION_ID` | `widget.SelectionPreviousWeekActionID` / `widget.SelectionNextWeekActionID` |
| Calendar month Action ID | `SELECTION_PREVIOUS_MONTH_ACTION_ID` / `SELECTION_NEXT_MONTH_ACTION_ID` | `widget.SelectionPreviousMonthActionID` / `widget.SelectionNextMonthActionID` |
| Calendar month境界Action ID | `SELECTION_FIRST_DAY_OF_MONTH_ACTION_ID` / `SELECTION_LAST_DAY_OF_MONTH_ACTION_ID` | `widget.SelectionFirstDayOfMonthActionID` / `widget.SelectionLastDayOfMonthActionID` |
| Navigation back Action ID | `NAVIGATION_BACK_ACTION_ID` | `widget.NavigationBackActionID` |
| Collapse Action ID | `COLLAPSE_ACTION_ID` | `widget.CollapseActionID` |
| Expand Action ID | `EXPAND_ACTION_ID` | `widget.ExpandActionID` |
| Dismiss Action ID | `DISMISS_ACTION_ID` | `widget.DismissActionID` |
| Confirm Action ID | `CONFIRM_ACTION_ID` | `widget.ConfirmActionID` |
| Composer submit Action ID | `COMPOSER_SUBMIT_ACTION_ID` | `widget.ComposerSubmitActionID` |
| History recall Action ID | `HISTORY_PREVIOUS_ACTION_ID` / `HISTORY_NEXT_ACTION_ID` | `widget.HistoryPreviousActionID` / `widget.HistoryNextActionID` |
| Suggestion Action ID | `SUGGESTION_ACCEPT_ACTION_ID` / `SUGGESTION_DISMISS_ACTION_ID` | `widget.SuggestionAcceptActionID` / `widget.SuggestionDismissActionID` |
| Inspector copy Action ID | `INSPECTOR_COPY_ACTION_ID` | `widget.InspectorCopyActionID` |
| Pane focus Action ID | `PANE_FOCUS_PREVIOUS_ACTION_ID` / `PANE_FOCUS_NEXT_ACTION_ID` | `widget.PaneFocusPreviousActionID` / `widget.PaneFocusNextActionID` |
| Pane resize Action ID | `PANE_RESIZE_PREVIOUS_ACTION_ID` / `PANE_RESIZE_NEXT_ACTION_ID` | `widget.PaneResizePreviousActionID` / `widget.PaneResizeNextActionID` |
| Text cursor Action ID | `TEXT_CURSOR_*_ACTION_ID` | `tui.TextCursor*ActionID` |
| Text selection extension Action ID | `TEXT_SELECTION_EXTEND_*_ACTION_ID` | `tui.TextSelectionExtend*ActionID` |
| Select all Action ID | `TEXT_SELECT_ALL_ACTION_ID` | `tui.TextSelectAllActionID` |
| Text deletion Action ID | `TEXT_DELETE_*_ACTION_ID` | `tui.TextDelete*ActionID` |
| Text line break、undo、redo Action ID | `TEXT_INSERT_LINE_BREAK_ACTION_ID` / `TEXT_UNDO_ACTION_ID` / `TEXT_REDO_ACTION_ID` | `tui.TextInsertLineBreakActionID` / `tui.TextUndoActionID` / `tui.TextRedoActionID` |
| Text copy Action ID | `TEXT_COPY_SELECTION_ACTION_ID` / `TEXT_COPY_DOCUMENT_ACTION_ID` | `tui.TextCopySelectionActionID` / `tui.TextCopyDocumentActionID` |
| 標準activate descriptor | `activate_action_descriptor` | `widget.ActivateActionDescriptor` |
| 標準dismiss descriptor | `dismiss_action_descriptor` | `widget.DismissActionDescriptor` |
| 標準confirm descriptor | `confirm_action_descriptor` | `widget.ConfirmActionDescriptor` |
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
| TextArea soft wrapとno-wrap | `TextArea::soft_wrap` / `no_wrap` | `TextArea.SoftWrap` / `NoWrap` |
| TextArea vertical boundary policy | `TextAreaBoundaryNavigation` / `TextArea::boundary_navigation` | `widget.TextAreaBoundaryNavigation` / `TextArea.BoundaryNavigation` |
| TextArea caret viewport | `TextArea::viewport` | `TextArea.Viewport` |
| TextArea width profile | `TextArea::width_profile` | `TextArea.WidthProfile` |
| Composer action descriptor | `Composer::action_descriptors` | `Composer.ActionDescriptors` |
| Composer row境界 | `Composer::rows` / `visible_rows` | `Composer.Rows` / `VisibleRows` |
| Composer長さ制限 | `Composer::maximum_utf8_bytes` / `maximum_graphemes` | `Composer.MaximumUTF8Bytes` / `MaximumGraphemes` |
| Composer width profile | `Composer::width_profile` | `Composer.WidthProfile` |
| Suggestion action descriptor | `SuggestionPopup::action_descriptors` | `SuggestionPopup.ActionDescriptors` |
| Suggestion visible window | `SuggestionPopup::visible_rows` | `SuggestionPopup.VisibleRows` |
| Suggestion配置 | `SuggestionPopup::placement` | `SuggestionPopup.Placement` |
| SelectableText action descriptor | `SelectableText::action_descriptors` | `SelectableText.ActionDescriptors` |
| JsonInspector action descriptor | `JsonInspector::action_descriptors` | `JSONInspector.ActionDescriptors` |
| CodeView action descriptor | `CodeView::action_descriptors` | `CodeView.ActionDescriptors` |
| DiffView action descriptor | `DiffView::action_descriptors` | `DiffView.ActionDescriptors` |
| SplitPane action descriptor | `SplitPane::action_descriptors` | `SplitPane.ActionDescriptors` |
| Drawer action descriptor | `Drawer::action_descriptor` | `Drawer.ActionDescriptor` |
| Disclosure | `Disclosure::new` / `body` | `widget.NewDisclosure` / `Disclosure.Body` |
| Disclosure action | `Disclosure::action_descriptors` | `Disclosure.ActionDescriptors` |
| Dialog action | `DialogAction::new` | `widget.NewDialogAction` |
| Dialog role選択 | `Dialog::default_action` / `cancel_action` | `Dialog.DefaultAction` / `CancelAction` |
| Dialog action | `Dialog::action_descriptors` | `Dialog.ActionDescriptors` |
| Dialog action wrapping | `Dialog::action_wrap_width` | `Dialog.ActionWrapWidth` |
| Dialog width profile | `Dialog::width_profile` | `Dialog.WidthProfile` |
| Confirm default | `ConfirmDialogDefault` | `widget.ConfirmDialogDefaultConfirm` / `ConfirmDialogDefaultCancel` |
| ConfirmDialog width profile | `ConfirmDialog::width_profile` | `ConfirmDialog.WidthProfile` |
| Modal focus builder | `Modal::initial_focus` / `return_focus` | `Modal.InitialFocus` / `ReturnFocus` |
| Command Palette command action descriptor | `CommandPalette::command_action_descriptor` | `CommandPalette.CommandActionDescriptor` |
| Command Palette root action descriptors | `CommandPalette::action_descriptors` | `CommandPalette.ActionDescriptors` |
| Modal action descriptor | `Modal::action_descriptor` | `Modal.ActionDescriptor` |
| Paginator action descriptors | `Paginator::action_descriptors` | `Paginator.ActionDescriptors` |
| FilePicker action descriptors | `FilePicker::action_descriptors` | `FilePicker.ActionDescriptors` |
| Calendar action descriptors | `Calendar::action_descriptors` | `Calendar.ActionDescriptors` |
| Resolved actionからのHelp | `Help::from_resolved_actions` | `widget.NewHelpFromResolvedActions` |
| Help width profile | `Help::width_profile` | `Help.WidthProfile` |
| BarChart width profile | `BarChart::width_profile` | `BarChart.WidthProfile` |
| Chart width profile | `Chart::width_profile` | `Chart.WidthProfile` |

RustはCharacterとFunctionの値を`KeyCode`内に保持します

Goは対応するprivate fieldを`KeyStroke.Character`と`KeyStroke.Function`のmethodとして公開します

この表現差はstroke equality、event matching、notation、scope replacement、conflict semanticsを変えません

pure resolverは独立したAPIとして引き続き利用できます

両Runtime実装はowner groupとscopeをsemantic Nodeへattachし、active routeをresolveして、そのprojectionをHelpとtest consumerへ公開します

Button、Checkbox、Radio、Select、Tabsの各item、List、Table、Tree、Command Paletteは共有`nagi.activate` actionを宣言します

Select、Tabs root、List、Table、Tree、Command Palette rootはWidget所有のdefault bindingを持つ4個の共有selection Action IDも宣言します

Treeは共有collapseとexpand Action IDも宣言します

TextAreaは18個のCore `nagi.text.*` operationをrootで宣言し、TextとPasteをraw editing inputとして維持します

Composerは同じrootで継承したtext actionより先にsubmitと2個のhistory operationを宣言します

SelectableTextは1個のfocusable rootで19個のCore text selectionとcopy operationを宣言します

JsonInspectorは1個のfocusable rootでactivation、4個のvertical selection operation、collapse、expand、complete-value copyを宣言します

CodeViewは1個のfocusable rootで4個の行selection operation、4個のselection extension、2個のhorizontal scroll operation、select all、copy selection、copy documentを宣言します

DiffViewはtyped diff logical lineに対して同じ13個のoperationを宣言します

Command Paletteはancestor root actionより先にqueryのTextInput handlingを維持します

Modalはrootで共有`nagi.dismiss` actionを宣言し、outer actionのpropagation境界をopt-inのままにします。Dialogは`nagi.confirm`の後に`nagi.dismiss`を宣言し、両roleを明示的なaction IDへmapして各actionで既存Button activationを使用します

Paginatorはactivationなしで4個の共有selection actionを宣言し、previousとnextにそれぞれ3個のordered fallback keyを持たせます

FilePickerはrootでactivation、6個の共有selection action、navigation backを宣言し、openとback callbackに応じてavailabilityを切り替えます

Calendarはactive date rootでactivationと8個のcalendar scale selection actionを宣言します

Rustはroute conflictを`RuntimeError`でwrapし、Goはstructured conflictを直接返します

## 標準Widget

| Widget | Rust constructor | Go constructor |
| --- | --- | --- |
| List | `List::new` | `widget.NewList` |
| Button | `Button::new` | `widget.NewButton` |
| Modal | `Modal::new` | `widget.NewModal` |
| Disclosure | `Disclosure::new` | `widget.NewDisclosure` |
| SplitPane | `SplitPane::new` | `widget.NewSplitPane` |
| Drawer | `Drawer::new` | `widget.NewDrawer` |
| StatusBar | `StatusBar::new` | `widget.NewStatusBar` |
| StatusBar slot | `StatusBarSlot::new` | `widget.NewStatusBarSlot` |
| StatusBar priority | `StatusBarPriority` | `widget.StatusBarPriority` |
| Toast | `Toast::new` | `widget.NewToast` |
| ToastRegion | `ToastRegion::new` | `widget.NewToastRegion` |
| Toast toneと配置 | `ToastTone` / `ToastPlacement` | `widget.ToastTone` / `widget.ToastPlacement` |
| Toast style | `ToastStyle` | `widget.ToastStyle` / `widget.DefaultToastStyle` |
| Dialog | `Dialog::new` | `widget.NewDialog` |
| ConfirmDialog | `ConfirmDialog::new` | `widget.NewConfirmDialog` |
| Progress | `Progress::new` | `widget.NewProgress` |
| Spinner | `Spinner::new` | `widget.NewSpinner` |
| Scrollbar | `Scrollbar::new` | `widget.NewScrollbar` |
| TextArea | `TextArea::new` | `widget.NewTextArea` |
| Composer | `Composer::new` | `widget.NewComposer` |
| SuggestionPopup | `SuggestionPopup::new` | `widget.NewSuggestionPopup` |
| SelectableText | `SelectableText::new` | `widget.NewSelectableText` |
| JsonInspector | `JsonInspector::new` | `widget.NewJSONInspector` |
| CodeView | `CodeView::new` | `widget.NewCodeView` |
| DiffView | `DiffView::new` | `widget.NewDiffView` |
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

RustのWidget builderはsnake caseを使用して`into_node`で終わり、Goはexported mixed caseを使用して`Node`で終わります。例として`List::filter`と`List.Filter`、`Table::column_alignment`と`Table.ColumnAlignment`、`VirtualFeed::unread_indicator`と`VirtualFeed.UnreadIndicator`、`FilePicker::show_hidden`と`FilePicker.ShowHidden`が対応します

## Controlled stateとitem value

| 用途 | Rust | Go |
| --- | --- | --- |
| Multiline edit state | `TextAreaState` | `widget.TextAreaState` |
| Preferred visual column | `TextAreaState::preferred_column` | `TextAreaState.PreferredColumn` |
| Undoとredo history | `TextAreaHistory` | `widget.TextAreaHistory` |
| Composer state | `ComposerState::new` / `at_end` | `widget.NewComposerState` / `NewComposerStateAtEnd` |
| Split pane state | `SplitPaneState::new` | `widget.NewSplitPaneState` / `DefaultSplitPaneState` |
| Composer overflow policy | `ComposerOverflowPolicy` | `widget.ComposerOverflowPolicy` |
| Suggestion identity | `SuggestionId::new` | `widget.NewSuggestionID` |
| Immutable suggestion order | `SuggestionItems::new` | `widget.NewSuggestionItems` |
| Duplicate suggestion error | `DuplicateSuggestionId` | `widget.DuplicateSuggestionIDError` |
| Suggestion async state | `SuggestionPopupStatus` | `widget.SuggestionPopupStatus` |
| Selectable text content | `SelectableTextContent::plain` / `styled` | `widget.NewPlainSelectableTextContent` / `NewSelectableTextContent` |
| Selectable text state | `SelectableTextState::new` / `with_selection` | `widget.NewSelectableTextState` / `NewSelectableTextStateWithSelection` |
| Semantic copy request | `TextCopyRequest` / `TextCopyKind` | `widget.TextCopyRequest` / `TextCopyKind` |
| Pointer selection | enabledな`SelectableText`へ組み込み | enabledな`widget.SelectableText`へ組み込み |
| Typed JSON value | `JsonValue` constructor | `widget.NewJSON*` constructor |
| 検証済みJSON number | `JsonNumber::new` | `widget.NewJSONNumber` |
| 順序付きobject member | `JsonMember::new` | `widget.NewJSONMember` |
| Immutable JSON document | `JsonDocument::new` / `with_limits` | `widget.NewJSONDocument` / `NewJSONDocumentWithLimits` |
| JSON document limit | `JsonDocumentLimits` | `widget.JSONDocumentLimits` |
| JSON Pointer | `JsonPointer::new` | `widget.NewJSONPointer` |
| JSON inspector state | `JsonInspectorState::new` | `widget.NewJSONInspectorState` |
| JSON copy request | `JsonInspectorCopyRequest` | `widget.JSONInspectorCopyRequest` |
| Styled code line | `CodeLine::plain` / `styled` | `widget.NewCodeLine` / `NewStyledCodeLine` |
| Immutable code document | `CodeDocument::new` / `new_with_limits` | `widget.NewCodeDocument` / `NewCodeDocumentWithLimits` |
| Code document行byte範囲 | `CodeDocument::byte_range_for_lines` | `CodeDocument.ByteRangeForLines` |
| Terminal code layout | `CodeLayout::new` / `new_with_limits` | `widget.NewCodeLayout` / `NewCodeLayoutWithLimits` |
| Code layout memo | `CodeLayoutCache::resolve` | `widget.CodeLayoutCache.Resolve` |
| Code view state | `CodeViewState::new` / `with_selection` | `widget.NewCodeViewState` / `NewCodeViewStateWithSelection` |
| Code copy request | `CodeCopyRequest` / `CodeCopyKind` | `widget.CodeCopyRequest` / `CodeCopyKind` |
| Typed diff line | `DiffLine::metadata` / `hunk` / `context` / `addition` / `deletion` | `widget.NewDiffMetadataLine` / `NewDiffHunkLine` / `NewDiffContextLine` / `NewDiffAdditionLine` / `NewDiffDeletionLine` |
| Diff hunk range | `DiffRange::new` / `DiffHunk::new` | `widget.NewDiffRange` / `NewDiffHunk` |
| Immutable diff document | `DiffDocument::new` / `new_with_limits` | `widget.NewDiffDocument` / `NewDiffDocumentWithLimits` |
| Diff document行byte範囲 | `DiffDocument::byte_range_for_lines` | `DiffDocument.ByteRangeForLines` |
| 要求時のunified text | `DiffDocument::copy_text_for_lines` | `DiffDocument.CopyTextForLines` |
| Terminal diff layout | `DiffLayout::new` / `new_with_limits` | `widget.NewDiffLayout` / `NewDiffLayoutWithLimits` |
| Diff layout memo | `DiffLayoutCache::resolve` | `widget.DiffLayoutCache.Resolve` |
| Diff view state alias | `DiffViewState::new` / `with_selection` | `widget.NewDiffViewState` / `NewDiffViewStateWithSelection` |
| Diff copy request | `DiffCopyRequest` / `DiffCopyKind` | `widget.DiffCopyRequest` / `DiffCopyKind` |
| Tree expansion state | `TreeState` | `widget.TreeState` |
| Gregorian date | `CalendarDate::new` | `widget.NewCalendarDate` |
| File metadata | `FilePickerEntry::file` / `directory` | `widget.NewFilePickerFile` / `NewFilePickerDirectory` |
| Chart point | `ChartPoint::new` | `widget.ChartPoint` struct value |

Selection callbackはRustで`usize`、Goで`int`を受け取ります。Rust constructorはcallbackを必須とし、document済みのGo constructorはnilのinteractive callbackをdisabledとして扱います。Goは各public contractに従って負のindexをclampし、Rustはunsigned indexを使用します

## RuntimeとEvent

| 用途 | Rust | Go |
| --- | --- | --- |
| Application contract | associated `Message`を持つ`App` | `App[Message]` |
| View環境 | `ViewContext { size, width_profile, terminal_capabilities }` | `ViewContext{Size: ..., WidthProfile: ..., TerminalCapabilities: ...}` |
| Runtime width profile | `RuntimeConfig::width_profile` | `RuntimeConfig.WidthProfile` |
| Terminal width profile | `TerminalOptions::width_profile` | `TerminalOptions.WidthProfile` |
| Runtime capability profile | `RuntimeConfig::terminal_capabilities` | `RuntimeConfig.TerminalCapabilities` |
| Terminal capability profile | `TerminalCapabilityProfile` | `TerminalCapabilityProfile` |
| VT output color level | `nagi_vt::ColorLevel` | `vt.ColorLevel` |
| Capabilityの根拠 | `TerminalFeatureSupport` | `TerminalFeatureSupport` |
| 公示color level | `TerminalColorLevel` | `TerminalColorLevel` |
| 有効keyboard protocol | `TerminalKeyboardProtocol` | `TerminalKeyboardProtocol` |
| Keyboard根拠からbinding metadataへの変換 | `TerminalCapabilityProfile::modified_key_support` | `TerminalCapabilityProfile.ModifiedKeySupport` |
| Terminal capability検出 | `TerminalOptions::capability_detection` / `TerminalCapabilityDetection` | `TerminalOptions.CapabilityDetection` / `TerminalCapabilityDetection` |
| Capability query timeout | `TerminalOptions::capability_query_timeout` | `TerminalOptions.CapabilityQueryTimeout` |
| Terminal clipboard mode | `TerminalOptions::clipboard` / `TerminalClipboard` | `TerminalOptions.Clipboard` / `TerminalClipboard` |
| Context-aware Runtime構築 | 言語固有のcaller integration | `NewRuntimeContext` / `NewRuntimeWithClockContext` |
| Terminal application実行 | `run_terminal` | `RunTerminal[M]` |
| 外部cancellation付き実行 | 言語固有のcaller integration | `RunTerminalContext[M]` |
| Runtime notice付き実行 | `run_terminal_with_notice_handler` | `RunTerminalWithNoticeHandler[M]` |
| Context cancellationとnotice | 言語固有のcaller integration | `RunTerminalContextWithNoticeHandler[M]` |
| Async pollingなしのqueued input処理 | `Runtime::process_queued` | `Runtime.ProcessQueued` |
| Lifecycle notice | `RuntimeNotice` / `RuntimeNoticeKind` | `RuntimeNotice` / `RuntimeNoticeKind` |
| Pending noticeとdrain | `Runtime::pending_runtime_notices` / `drain_runtime_notices` | `Runtime.PendingRuntimeNotices` / `DrainRuntimeNotices` |
| Notice drop diagnostic | `Runtime::runtime_notice_diagnostics` | `Runtime.RuntimeNoticeDiagnostics` |
| Test harnessのnotice | `Harness::pending_runtime_notices` / `drain_runtime_notices` / `runtime_notice_diagnostics` | `Harness.PendingRuntimeNotices` / `DrainRuntimeNotices` / `RuntimeNoticeDiagnostics` |
| Eventをignore | `EventResult::ignored()` | `IgnoreResult[M]()` |
| Eventをconsume | `EventResult::consumed()` | `ConsumeResult[M]()` |
| 1個のMessageをemit | `EventResult::message(value)` | `MessageResult(value)` |
| Geometry-aware pointer handler | `Node::on_pointer_event` | `Node.OnPointerEvent` |
| Pointer Event geometry | `PointerEventContext` | `PointerEventContext` |
| Paragraph UTF-8 hit | `PointerEventContext::text_hit` / `TextHit` | `PointerEventContext.TextHit` / `TextHit` |
| 最も近いpointer viewport | `PointerEventContext::viewport` / `PointerViewport` | `PointerEventContext.Viewport` / `PointerViewport` |
| Edge scroll導出 | `PointerEventContext::edge_scroll` | `PointerEventContext.EdgeScroll` |
| Event-local scroll request | `EventResult::scroll_to` | `EventResult.ScrollTo` |
| Global ignore action | `EventAction::Ignore` | `IgnoreAction[M]()` |
| Global exit action | `EventAction::Exit` | `ExitAction[M]()` |
| Effectなし | `Effect::none()` | `NoneEffect[M]()` |
| View変更なしのEffect | `effect.without_redraw()` | `effect.WithoutRedraw()` |
| Application終了Effect | `Effect::exit()` | `ExitEffect[M]()` |
| Focus Effect | `Effect::focus(id)` | `FocusEffect[M](id)` |
| Scroll Effect | `Effect::scroll_to(id, offset)` | `ScrollToEffect[M](id, offset)` |
| Clipboard Effect | `Effect::set_clipboard(text)` | `SetClipboardEffect[M](text)` |
| Terminal suspend Effect | `Effect::suspend_terminal(task)` | `SuspendTerminalEffect[M](task)` |
| Full-screen terminal viewport | `TerminalViewport::FULLSCREEN` | zero `TerminalViewport` |
| Inline terminal viewport | `TerminalViewport::inline(height)` | `NewInlineTerminalViewport(height)` |
| Terminal viewport option | `TerminalOptions::viewport` | `TerminalOptions.Viewport` |
| Cursor query timeout | `TerminalOptions::cursor_query_timeout` | `TerminalOptions.CursorQueryTimeout` |
| Clipboard request | `ClipboardRequest` | `ClipboardRequest` |
| Pending clipboard request | `Runtime::pending_clipboard_request` | `Runtime.PendingClipboardRequest` |
| Clipboard requestのtake | `Runtime::take_clipboard_request` | `Runtime.TakeClipboardRequest` |
| Test harnessのclipboard request | `Harness::pending_clipboard_request` / `take_clipboard_request` | `Harness.PendingClipboardRequest` / `TakeClipboardRequest` |
| Pending terminal task | `Runtime::pending_terminal_tasks` | `Runtime.PendingTerminalTasks` |
| Terminal taskを1個実行 | `Runtime::run_terminal_task` | `Runtime.RunTerminalTask` |
| Terminal diff baselineをinvalidate | `Runtime::invalidate_terminal_surface` | `Runtime.InvalidateTerminalSurface` |
| Test harnessのterminal task | `Harness::pending_terminal_tasks` / `run_terminal_task` | `Harness.PendingTerminalTasks` / `RunTerminalTask` |
| 未完terminal inputを破棄 | `TimedInputDecoder::reset` | `TimedInputDecoder.Reset` |
| 曖昧なKitty modifier mode | `Decoder::set_kitty_keyboard_mode` / `TimedInputDecoder::set_kitty_keyboard_mode` | `vt.Decoder.SetKittyKeyboardMode` / `TimedInputDecoder.SetKittyKeyboardMode` |
| Subscriptionなし | `Subscription::none()` | `NoneSubscription[M]()` |
| Kitty keyのsource protocol | `KeyProtocol::Kitty` | `vt.KeyProtocolKitty` |
| Kitty progressive flag | `KeyboardEnhancements::NAGI` | `vt.NagiKeyboardEnhancements` |
| Primary device attributes query | `TerminalOp::RequestPrimaryDeviceAttributes` | `vt.RequestPrimaryDeviceAttributes()` |
| Kitty flag query | `TerminalOp::QueryKeyboardEnhancements` | `vt.QueryKeyboardEnhancements()` |
| Kitty mode stack | `TerminalOp::PushKeyboardEnhancements` / `PopKeyboardEnhancements` | `vt.PushKeyboardEnhancements(...)` / `vt.PopKeyboardEnhancements()` |

両terminal runnerは1個のinput chunkからdecodeした各Eventをrouteしてupdateへ適用してから次のEventを処理し、renderだけをcoalesceします。Terminal suspend Effectが生じた場合は通常terminalをtaskへ渡す前に同じchunkの後続decode済みEventを破棄します。幅計算を行うWidgetは`ViewContext`からRuntime profileを明示的に受け取り、Core Nodeは同じprofileを自動的に使用します

Capability検出は既定で無効です
有効時は両標準runnerが保守的なenvironment hintを適用し、Kitty keyboard対応をqueryし、suspendとrestoreにまたがってNagiのenhancement stackを釣り合わせ、immutableなprofileをRuntimeへ公開します
Profileの根拠はoutput permissionではなく、OSC 52は独立したclipboard optionで制御します
検出colorは設定済みの4段階VT encoderを昇格せず上限として制約します

標準terminal runnerはoriginal terminalを復元し、alternate screenを離れるかinline viewportを確定してからterminal taskを1個ずつ実行します。Resumeでは設定済みviewportとmodeへ戻り、local sizeを読み、未完decoder stateをresetし、diff baselineをinvalidateして再描画します。Manual Runtime driverは同等の境界を所有します

Allocationを抑えたいVT append APIは`nagi_vt::append_encoded`と`vt.AppendEncoded`です。Origin対応variantは`nagi_vt::append_encoded_at`と`vt.AppendEncodedAt`です。Caller所有bufferへ対応するfresh-buffer encoderが生成するbyteと同一の内容を追記します

Typedかつwrite-onlyのclipboard operationはRustの`TerminalOp::SetClipboard`とGoの`vt.SetClipboard`です
両APIは正規化済みUTF-8 textをdirect OSC 52としてencodeし、clipboard readやraw control sequence injectionを公開しません

`ScrollAxis`、`ScrollOffset`、`ScrollState`はGoの同名typeへ直接対応します。Rust test supportは`Harness::scroll_state`と`Harness::exit_requested`、Goは`Harness.ScrollState`と`Harness.ExitRequested`を使用します

## CLI command application

| 用途 | Rust | Go |
| --- | --- | --- |
| Command定義 | `Command::new` | `cli.NewCommand` |
| Flag、count、value option | `OptionSpec::flag` / `count` / `value` | `cli.Flag` / `Count` / `ValueOption` |
| Optionを継承可能にする | `OptionSpec::inherited` | `OptionSpec.Inherited` |
| 継承状態の参照 | `OptionSpec::is_inherited` | `OptionSpec.IsInherited` |
| Value completion providerの設定 | `OptionSpec::completion_provider` / `Argument::completion_provider` | `OptionSpec.CompletionProvider` / `Argument.CompletionProvider` |
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
| Structured継承Help option | `HelpInheritedOption` | `cli.HelpInheritedOption` |
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
| Immutable completion model | `CompletionEngine::new` | `cli.NewCompletionEngine` |
| Tokenize済みcompletion input | `CompletionInput::new` | `cli.NewCompletionInput` |
| Completion解決 | `CompletionEngine::complete` | `CompletionEngine.Complete` |
| Dynamic provider | `CompletionProvider` | `cli.CompletionProvider` |
| Completion requestとpartial argv | `CompletionRequest` / `CompletionOccurrence` | `cli.CompletionRequest` / `cli.CompletionOccurrence` |
| Completion candidate | `CompletionCandidate` | `cli.CompletionCandidate` |
| Shell script生成 | `nagi_cli_completion::generate` | `completion.Generate` |
| 予約protocol処理 | `nagi_cli_completion::handle` | `completion.Handle` |
| Prompt実行 | `Prompter` | `prompt.Prompter` |
| Confirm request | `Confirm` / `Prompter::confirm` | `prompt.Confirm` / `Prompter.Confirm` |
| Select request | `Select` / `Prompter::select` | `prompt.Select` / `Prompter.Select` |
| Visible input request | `Input` / `Prompter::input` | `prompt.Input` / `Prompter.Input` |
| Secret input request | `Secret` / `Prompter::secret` | `prompt.Secret` / `Prompter.Secret` |
| 注入可能なPrompt I/O | `PromptIo` | `prompt.IO` |
| Unix process Prompt I/O | `ProcessIo::default` | `prompt.NewProcessIO` / `prompt.NewProcess` |
| Prompt terminal policy | `TerminalPolicy` | `prompt.TerminalPolicy` |
| Prompt resource上限 | `Limits` | `prompt.Limits` |
| Prompt failure | `PromptError` / `PromptErrorKind` | `prompt.Error` / `prompt.ErrorKind` |
| Status reporter | `Reporter` | `status.Reporter` |
| Status構築 | `Reporter::new` | `status.New` |
| Status snapshot | `Snapshot` / `SnapshotKind` | `status.Snapshot` / `status.SnapshotKind` |
| Plain status | `Snapshot::status` | `status.NewStatus` |
| Application駆動spinner | `Snapshot::spinner` | `status.NewSpinner` |
| Spinner frame数 | `SPINNER_FRAME_COUNT` | `status.SpinnerFrameCount` |
| Determinate progress | `Snapshot::progress` | `status.NewProgress` |
| 更新と最終commit | `Reporter::update` / `finish` | `Reporter.Update` / `Finish` |
| Clearとpermanent log | `Reporter::clear` / `log` | `Reporter.Clear` / `Log` |
| 注入可能なstatus I/O | `StatusIo` | `status.IO` |
| Unix process status I/O | `ProcessIo::default` | `status.NewProcessIO` / `NewProcess` |
| Status option | `Options` | `status.Options` |
| Status failure | `StatusError` / `StatusErrorKind` | `status.Error` / `status.ErrorKind` |
| Processなしのdriver | `nagi_cli_test::TestDriver` | `clitest.Driver` |

Rustはraw platform valueを`OsString`、typed parser resultを`Any`の背後へ保存します

Goはraw byteをstringへ保持し、parser resultを`any`とgenericな`ValueAs`および`RequireValueAs` helperで公開します

両実装は再利用されたlocal IDをstable command-ID pathで区別します

Rust cancellationはatomic token、Go cancellationは`context.Context`を使用します

両completion engineは検証済みgraphをsnapshotし、選択pathだけを解決してactiveなvalue targetに設定されたproviderだけを呼びます

Rustのcompletion candidateは構造上valid UTF-8であり、Goはresultを返す前にUTF-8を検証します

Shell層はcommand runtimeから分離され、通常dispatchより前に予約protocolを処理します

両Prompt実装はterminal I/OをCLI Core外に保ち、requestごとにcallerのcancellation sourceを受け取ります

Rustはclosedな`ReadResult` enum、Goは`ReadResult`と`ReadResultKind`を使い、注入実装が同じLine、End Of File、Input Too Long、Canceledを返せるようにします

Rustの`Limits::default`とGoのzero `prompt.Limits`はportableな既定上限を選択します

Secret valueは両実装とも通常の`String`または`string`であり、Promptはmemory zeroizationを行いません

両Status実装は同期的でApplicationから駆動します

Rustの`Options::default`とGoのzero `status.Options`はportableな上限とModern幅profileを選択します

両実装は最終的に描画したterminal lineまたはplain fallback recordをcoalesceし、上限付きscratch bufferを保持し、cancellationと更新時点をApplicationへ委ねます

RustのSnapshot messageはvalidな`str`をborrowし、Goは出力前にstringのUTF-8を検証します

これらの表現差はparsing、structured Help、Diagnostic semanticsを変更しません

両実装は同じ既定Runtime Policyを適用し、applicationはrendererまたはcategoryからstatusへのmappingを明示的に変更できます

完全な契約は[public CLI API guide](CLI_API_ja.md)と[command application semantics](../spec/cli.md)を参照してください

TUI application composition全体は[public API guide](API_ja.md)と対応するRustとGoのexampleを参照してください
