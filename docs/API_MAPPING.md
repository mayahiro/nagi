# Rust and Go API mapping

[日本語](API_MAPPING_ja.md)

Nagi keeps observable Content, TUI, and CLI behavior aligned while using each
language's normal naming and ownership conventions. This mapping covers the
main public entry points; generated API documentation remains authoritative
for complete method signatures

## Packages

| Responsibility | Rust | Go |
| --- | --- | --- |
| Source-neutral content | `nagi-content` | `github.com/mayahiro/nagi-go/content` |
| Terminal Presentation Rules | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Core runtime and nodes | `nagi-tui` | `github.com/mayahiro/nagitui-go` |
| Unicode text | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| VT codec, Color, Attributes, Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry and Surface | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| Standard widgets | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Runtime test harness | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |
| CLI command runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go` |
| CLI shell completion | `nagi-cli-completion` | `github.com/mayahiro/nagicli-go/completion` |
| CLI lightweight prompts | `nagi-cli-prompt` | `github.com/mayahiro/nagicli-go/prompt` |
| CLI TTY-aware status | `nagi-cli-status` | `github.com/mayahiro/nagicli-go/status` |
| CLI test driver | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |

The Rust `nagi-tui` facade and Go `tui` package re-export the canonical
Geometry and Style types for application-facing APIs

## Source-neutral content

| Purpose | Rust | Go |
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
| Convert element to content | `Element::into_content()` | `Element.Content()` |
| Stable identity | `ElementId::new` / `Element::with_id` | `content.NewElementID` / `Element.WithID` |
| Opaque revision | `Element::with_revision` | `Element.WithRevision` |
| Semantic role | `Role::new` / `Element::with_roles` | `content.NewRole` / `Element.WithRoles` |
| Presentation class | `Class::new` / `Element::with_classes` | `content.NewClass` / `Element.WithClasses` |
| Role membership | `Element::roles().contains(...)` | `Element.HasRole(...)` |
| Class membership | `Element::classes().contains(...)` | `Element.HasClass(...)` |
| Indexed child read | `Element::children()` | `Element.ChildCount()` / `Element.Child(index)` |
| Application annotation | `AnnotationId::new` / `Element::with_annotation` | `content.NewAnnotationID` / `Element.WithAnnotation` |
| Semantic boundary | `SemanticBoundary` / `Element::with_boundary` | `content.SemanticBoundary` / `Element.WithBoundary` |
| Identifier failure | `IdentifierError` / `IdentifierErrorKind` | `content.IdentifierError` / `IdentifierErrorKind` |
| Duplicate role or class | `DuplicateRole` / `DuplicateClass` | `content.DuplicateRoleError` / `DuplicateClassError` |
| Semantic projection | `semantic_text` / `SemanticText` | `content.ProjectSemanticText` / `SemanticText` |
| Annotation byte range | `AnnotationRange` | `content.AnnotationRange` |
| Explicit validation | `validate(content, limits)` | `content.Validate(value, limits)` |
| Unlimited validation | `Limits::UNLIMITED` | `content.UnlimitedLimits()` |
| Resource result | `Stats` | `content.Stats` |
| Validation failure | `ValidationError` / `ValidationErrorKind` | `content.ValidationError` / `ValidationErrorKind` |

Rust `Content` clones and Go `Content` value copies share immutable backing
storage. Slice accessors return immutable slices in Rust and defensive copies
in Go. Go defines zero `Content` as empty Text and zero `Element` as empty
Inline. Go modifier errors reject invalid zero-value identifiers and unknown
numeric boundaries; Rust validated identifiers and closed enums make those
states unrepresentable

## Terminal Presentation Rules

| Purpose | Rust | Go |
| --- | --- | --- |
| State token | `PresentationState::new` / `from_bytes` | `tui.NewPresentationState` / `NewPresentationStateBytes` |
| Universal selector | `PresentationSelector::Any` | `tui.AnyPresentationSelector()` |
| Exact Role selector | `PresentationSelector::Role(role)` | `tui.RolePresentationSelector(role)` |
| Exact Class selector | `PresentationSelector::Class(class)` | `tui.ClassPresentationSelector(class)` |
| Three-state property | `DeclarationValue<T>` | `tui.DeclarationValue[T]` |
| Concrete property | `DeclarationValue::Set(value)` | `tui.SetDeclarationValue(value)` |
| Initial property | `DeclarationValue::Initial` | `tui.InitialDeclarationValue[T]()` |
| Text declaration | `TextStyleDeclaration` | `tui.TextStyleDeclaration` |
| Layout and text declaration | `PresentationDeclaration` | `tui.PresentationDeclaration` |
| Visual separator declaration | `with_visual_separator` / `visual_separator` | `WithVisualSeparator` / `VisualSeparator` |
| Display | `PresentationDisplay` | `tui.PresentationDisplay` |
| Ordered rule | `PresentationRule::new` | `tui.NewPresentationRule` |
| Required states | `PresentationRule::with_required_states` | `PresentationRule.Requiring` |
| Immutable sheet | `PresentationSheet::new` | `tui.NewPresentationSheet` |
| Resolution | `PresentationSheet::resolve` | `PresentationSheet.Resolve` |
| Computed result | `ComputedPresentation` | `tui.ComputedPresentation` |
| Projection without states | `project_content` | `tui.ProjectContent[M]` |
| Projection with per-element states | `project_content_with_states` | `tui.ProjectContentWithStates[M]` |
| Projection options | `ContentProjectionOptions` | `tui.ContentProjectionOptions` |
| Projection limits | `ContentProjectionLimits` | `tui.ContentProjectionLimits` |
| Projection failure | `ContentProjectionError` / `ContentProjectionErrorKind` | `tui.ContentProjectionError` / `ContentProjectionErrorKind` |

Both implementations resolve `(element, inherited Style, active States)` in
that order. Rule order is the only cascade priority. Text Style fields inherit;
layout fields do not. The result is a value and does not create a Node

Rust computed results borrow a concrete visual separator from the Sheet. Go
computed results retain the immutable string storage as a value

Both projection APIs return ordinary frame-owned Nodes and apply the same five
resource limits. Neither API derives Node identity from Content identity or
turns annotations into application actions

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
| Priority-aware horizontal children | `Node::responsive_row(items, options)` | `tui.ResponsiveRow[M](items, options)` |
| Responsive item | `ResponsiveRowItem::new(node)` | `tui.NewResponsiveRowItem[M](node)` |
| Responsive placement and options | `ResponsiveRowPlacement` / `ResponsiveRowOptions` | `tui.ResponsiveRowPlacement` / `tui.ResponsiveRowOptions` |
| Responsive two-pane layout | `Node::split_pane(primary, secondary, options)` | `tui.SplitPane[M](primary, secondary, options)` |
| Split-pane options | `SplitPaneOptions` | `tui.SplitPaneOptions` / `DefaultSplitPaneOptions` |
| Split axis and collapse target | `SplitPaneAxis` / `SplitPaneCollapse` | `tui.SplitPaneAxis` / `tui.SplitPaneCollapse` |
| Layered children | `Node::stack(children)` | `tui.Stack[M](children...)` |
| Base-measured front layer | `Node::overlay(base, layer)` | `tui.Overlay[M](base, layer)` |
| Anchored front layer | `Node::anchored_overlay(...)` | `tui.AnchoredOverlay[M](...)` |
| Configured anchored layer | `Node::anchored_overlay_with_options(...)` | `tui.AnchoredOverlayWithOptions[M](...)` |
| Anchored placement options | `AnchoredOverlayOptions` | `tui.AnchoredOverlayOptions` |
| Insets | `Node::padding(child, insets)` | `tui.Padding[M](child, insets)` |
| Border | `Node::border(child, style)` | `tui.Border[M](child, style)` |
| Titled panel | `Node::panel(child, title)` | `tui.Panel[M](child, title)` |
| Configured panel | `Node::panel_with_options(...)` | `tui.PanelWithOptions[M](...)` |
| Alignment | `Node::align(child, horizontal, vertical)` | `tui.Align[M](child, horizontal, vertical)` |
| Clip | `Node::clip(child)` | `tui.Clip[M](child)` |
| One-line input | `Node::text_input(...)` | `tui.TextInput[M](...)` |
| Styled input | `Node::text_input_styled(...)` | `tui.StyledTextInput[M](...)` |
| Zero-width typed cursor | `Node::cursor_anchor(owner)` | `tui.CursorAnchor[M](owner)` |
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
| Hard unhandled-Event boundary | `Node::block_unhandled_events()` | `Node.BlockUnhandledEvents()` |

`TextSpan::new` and `TextSpan::with_style` map to `tui.NewTextSpan` and
`TextSpan.WithStyle`, while
`ParagraphOptions::default` maps to `tui.DefaultParagraphOptions`

## Scoped key maps

| Purpose | Rust | Go |
| --- | --- | --- |
| Action identity | `ActionId` | `ActionID` |
| Key stroke | `KeyStroke::new` / `character` / `function` | `NewKeyStroke` / `NewCharacterKeyStroke` / `NewFunctionKeyStroke` |
| Protocol functional-key stroke | `KeyStroke::new(KeyCode::Functional(...), ...)` | `NewFunctionalKeyStroke` |
| Event normalization | `KeyStroke::from_event` | `KeyStrokeFromEvent` |
| Key binding | `KeyBinding::new` | `NewKeyBinding` |
| Stroke-only blocking match | `KeyBinding::matches_stroke` | `KeyBinding.MatchesStroke` |
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
| Selection extension Action IDs | `SELECTION_EXTEND_*_ACTION_ID` | `widget.SelectionExtend*ActionID` |
| Selection previous-page Action ID | `SELECTION_PREVIOUS_PAGE_ACTION_ID` | `widget.SelectionPreviousPageActionID` |
| Selection next-page Action ID | `SELECTION_NEXT_PAGE_ACTION_ID` | `widget.SelectionNextPageActionID` |
| Horizontal-scroll Action IDs | `HORIZONTAL_SCROLL_PREVIOUS_ACTION_ID` / `HORIZONTAL_SCROLL_NEXT_ACTION_ID` | `widget.HorizontalScrollPreviousActionID` / `widget.HorizontalScrollNextActionID` |
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
| Suggestion Action IDs | `SUGGESTION_ACCEPT_ACTION_ID` / `SUGGESTION_DISMISS_ACTION_ID` | `widget.SuggestionAcceptActionID` / `widget.SuggestionDismissActionID` |
| Inspector copy Action ID | `INSPECTOR_COPY_ACTION_ID` | `widget.InspectorCopyActionID` |
| Pane focus Action IDs | `PANE_FOCUS_PREVIOUS_ACTION_ID` / `PANE_FOCUS_NEXT_ACTION_ID` | `widget.PaneFocusPreviousActionID` / `widget.PaneFocusNextActionID` |
| Pane resize Action IDs | `PANE_RESIZE_PREVIOUS_ACTION_ID` / `PANE_RESIZE_NEXT_ACTION_ID` | `widget.PaneResizePreviousActionID` / `widget.PaneResizeNextActionID` |
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
| TextArea width profile | `TextArea::width_profile` | `TextArea.WidthProfile` |
| Composer action descriptors | `Composer::action_descriptors` | `Composer.ActionDescriptors` |
| Composer row bounds | `Composer::rows` / `visible_rows` | `Composer.Rows` / `VisibleRows` |
| Composer length limits | `Composer::maximum_utf8_bytes` / `maximum_graphemes` | `Composer.MaximumUTF8Bytes` / `MaximumGraphemes` |
| Composer width profile | `Composer::width_profile` | `Composer.WidthProfile` |
| Suggestion action descriptors | `SuggestionPopup::action_descriptors` | `SuggestionPopup.ActionDescriptors` |
| Suggestion visible window | `SuggestionPopup::visible_rows` | `SuggestionPopup.VisibleRows` |
| Suggestion placement | `SuggestionPopup::placement` | `SuggestionPopup.Placement` |
| SelectableText action descriptors | `SelectableText::action_descriptors` | `SelectableText.ActionDescriptors` |
| JsonInspector action descriptors | `JsonInspector::action_descriptors` | `JSONInspector.ActionDescriptors` |
| CodeView action descriptors | `CodeView::action_descriptors` | `CodeView.ActionDescriptors` |
| DiffView action descriptors | `DiffView::action_descriptors` | `DiffView.ActionDescriptors` |
| SplitPane action descriptors | `SplitPane::action_descriptors` | `SplitPane.ActionDescriptors` |
| Drawer action descriptor | `Drawer::action_descriptor` | `Drawer.ActionDescriptor` |
| Disclosure | `Disclosure::new` / `body` | `widget.NewDisclosure` / `Disclosure.Body` |
| Disclosure actions | `Disclosure::action_descriptors` | `Disclosure.ActionDescriptors` |
| Dialog action | `DialogAction::new` | `widget.NewDialogAction` |
| Dialog role selection | `Dialog::default_action` / `cancel_action` | `Dialog.DefaultAction` / `CancelAction` |
| Dialog actions | `Dialog::action_descriptors` | `Dialog.ActionDescriptors` |
| Dialog action wrapping | `Dialog::action_wrap_width` | `Dialog.ActionWrapWidth` |
| Dialog width profile | `Dialog::width_profile` | `Dialog.WidthProfile` |
| Confirm default | `ConfirmDialogDefault` | `widget.ConfirmDialogDefaultConfirm` / `ConfirmDialogDefaultCancel` |
| ConfirmDialog width profile | `ConfirmDialog::width_profile` | `ConfirmDialog.WidthProfile` |
| Modal focus builders | `Modal::initial_focus` / `return_focus` | `Modal.InitialFocus` / `ReturnFocus` |
| Command Palette command action descriptor | `CommandPalette::command_action_descriptor` | `CommandPalette.CommandActionDescriptor` |
| Command Palette root action descriptors | `CommandPalette::action_descriptors` | `CommandPalette.ActionDescriptors` |
| Modal action descriptor | `Modal::action_descriptor` | `Modal.ActionDescriptor` |
| Paginator action descriptors | `Paginator::action_descriptors` | `Paginator.ActionDescriptors` |
| FilePicker action descriptors | `FilePicker::action_descriptors` | `FilePicker.ActionDescriptors` |
| Calendar action descriptors | `Calendar::action_descriptors` | `Calendar.ActionDescriptors` |
| Resolved-action Help | `Help::from_resolved_actions` | `widget.NewHelpFromResolvedActions` |
| Help width profile | `Help::width_profile` | `Help.WidthProfile` |
| BarChart width profile | `BarChart::width_profile` | `BarChart.WidthProfile` |
| Chart width profile | `Chart::width_profile` | `Chart.WidthProfile` |

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
operations at one focusable root. JsonInspector declares activation, four
vertical selection operations, collapse, expand, and complete-value copy at one
focusable root. CodeView declares four line-selection operations, four
selection extensions, two horizontal-scroll operations, select all, copy
selection, and copy document at one focusable root. DiffView declares the same
13 operations over typed diff logical lines. Command Palette retains query
TextInput handling before its ancestor root actions. Modal declares the shared
`nagi.dismiss` action at its
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
| SplitPane | `SplitPane::new` | `widget.NewSplitPane` |
| Drawer | `Drawer::new` | `widget.NewDrawer` |
| StatusBar | `StatusBar::new` | `widget.NewStatusBar` |
| StatusBar slot | `StatusBarSlot::new` | `widget.NewStatusBarSlot` |
| StatusBar priority | `StatusBarPriority` | `widget.StatusBarPriority` |
| Toast | `Toast::new` | `widget.NewToast` |
| ToastRegion | `ToastRegion::new` | `widget.NewToastRegion` |
| Toast tone and placement | `ToastTone` / `ToastPlacement` | `widget.ToastTone` / `widget.ToastPlacement` |
| Toast styles | `ToastStyle` | `widget.ToastStyle` / `widget.DefaultToastStyle` |
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
| Split pane state | `SplitPaneState::new` | `widget.NewSplitPaneState` / `DefaultSplitPaneState` |
| Composer overflow policy | `ComposerOverflowPolicy` | `widget.ComposerOverflowPolicy` |
| Suggestion identity | `SuggestionId::new` | `widget.NewSuggestionID` |
| Immutable suggestion order | `SuggestionItems::new` | `widget.NewSuggestionItems` |
| Duplicate suggestion error | `DuplicateSuggestionId` | `widget.DuplicateSuggestionIDError` |
| Suggestion asynchronous state | `SuggestionPopupStatus` | `widget.SuggestionPopupStatus` |
| Selectable text content | `SelectableTextContent::plain` / `styled` | `widget.NewPlainSelectableTextContent` / `NewSelectableTextContent` |
| Selectable text state | `SelectableTextState::new` / `with_selection` | `widget.NewSelectableTextState` / `NewSelectableTextStateWithSelection` |
| Semantic copy request | `TextCopyRequest` / `TextCopyKind` | `widget.TextCopyRequest` / `TextCopyKind` |
| Pointer selection | Built into enabled `SelectableText` | Built into enabled `widget.SelectableText` |
| Typed JSON value | `JsonValue` constructors | `widget.NewJSON*` constructors |
| Validated JSON number | `JsonNumber::new` | `widget.NewJSONNumber` |
| Ordered object member | `JsonMember::new` | `widget.NewJSONMember` |
| Immutable JSON document | `JsonDocument::new` / `with_limits` | `widget.NewJSONDocument` / `NewJSONDocumentWithLimits` |
| JSON document limits | `JsonDocumentLimits` | `widget.JSONDocumentLimits` |
| JSON Pointer | `JsonPointer::new` | `widget.NewJSONPointer` |
| JSON inspector state | `JsonInspectorState::new` | `widget.NewJSONInspectorState` |
| JSON copy request | `JsonInspectorCopyRequest` | `widget.JSONInspectorCopyRequest` |
| Styled code line | `CodeLine::plain` / `styled` | `widget.NewCodeLine` / `NewStyledCodeLine` |
| Immutable code document | `CodeDocument::new` / `new_with_limits` | `widget.NewCodeDocument` / `NewCodeDocumentWithLimits` |
| Code document line byte range | `CodeDocument::byte_range_for_lines` | `CodeDocument.ByteRangeForLines` |
| Terminal code layout | `CodeLayout::new` / `new_with_limits` | `widget.NewCodeLayout` / `NewCodeLayoutWithLimits` |
| Code layout memo | `CodeLayoutCache::resolve` | `widget.CodeLayoutCache.Resolve` |
| Code view state | `CodeViewState::new` / `with_selection` | `widget.NewCodeViewState` / `NewCodeViewStateWithSelection` |
| Code copy request | `CodeCopyRequest` / `CodeCopyKind` | `widget.CodeCopyRequest` / `CodeCopyKind` |
| Typed diff line | `DiffLine::metadata` / `hunk` / `context` / `addition` / `deletion` | `widget.NewDiffMetadataLine` / `NewDiffHunkLine` / `NewDiffContextLine` / `NewDiffAdditionLine` / `NewDiffDeletionLine` |
| Diff hunk range | `DiffRange::new` / `DiffHunk::new` | `widget.NewDiffRange` / `NewDiffHunk` |
| Immutable diff document | `DiffDocument::new` / `new_with_limits` | `widget.NewDiffDocument` / `NewDiffDocumentWithLimits` |
| Diff document line byte range | `DiffDocument::byte_range_for_lines` | `DiffDocument.ByteRangeForLines` |
| On-demand unified text | `DiffDocument::copy_text_for_lines` | `DiffDocument.CopyTextForLines` |
| Terminal diff layout | `DiffLayout::new` / `new_with_limits` | `widget.NewDiffLayout` / `NewDiffLayoutWithLimits` |
| Diff layout memo | `DiffLayoutCache::resolve` | `widget.DiffLayoutCache.Resolve` |
| Diff view state alias | `DiffViewState::new` / `with_selection` | `widget.NewDiffViewState` / `NewDiffViewStateWithSelection` |
| Diff copy request | `DiffCopyRequest` / `DiffCopyKind` | `widget.DiffCopyRequest` / `DiffCopyKind` |
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
| View environment | `ViewContext { size, width_profile, terminal_capabilities }` | `ViewContext{Size: ..., WidthProfile: ..., TerminalCapabilities: ...}` |
| Runtime width profile | `RuntimeConfig::width_profile` | `RuntimeConfig.WidthProfile` |
| Terminal width profile | `TerminalOptions::width_profile` | `TerminalOptions.WidthProfile` |
| Runtime capability profile | `RuntimeConfig::terminal_capabilities` | `RuntimeConfig.TerminalCapabilities` |
| Terminal capability profile | `TerminalCapabilityProfile` | `TerminalCapabilityProfile` |
| VT output color level | `nagi_vt::ColorLevel` | `vt.ColorLevel` |
| Capability evidence | `TerminalFeatureSupport` | `TerminalFeatureSupport` |
| Advertised color level | `TerminalColorLevel` | `TerminalColorLevel` |
| Active keyboard protocol | `TerminalKeyboardProtocol` | `TerminalKeyboardProtocol` |
| Binding metadata from keyboard evidence | `TerminalCapabilityProfile::modified_key_support` | `TerminalCapabilityProfile.ModifiedKeySupport` |
| Terminal capability detection | `TerminalOptions::capability_detection` / `TerminalCapabilityDetection` | `TerminalOptions.CapabilityDetection` / `TerminalCapabilityDetection` |
| Capability query timeout | `TerminalOptions::capability_query_timeout` | `TerminalOptions.CapabilityQueryTimeout` |
| Terminal clipboard mode | `TerminalOptions::clipboard` / `TerminalClipboard` | `TerminalOptions.Clipboard` / `TerminalClipboard` |
| Context-aware Runtime construction | Language-specific caller integration | `NewRuntimeContext` / `NewRuntimeWithClockContext` |
| Run a terminal app | `run_terminal` | `RunTerminal[M]` |
| Run with external cancellation | Language-specific caller integration | `RunTerminalContext[M]` |
| Run with Runtime notices | `run_terminal_with_notice_handler` | `RunTerminalWithNoticeHandler[M]` |
| Context cancellation and notices | Language-specific caller integration | `RunTerminalContextWithNoticeHandler[M]` |
| Process queued input without async polling | `Runtime::process_queued` | `Runtime.ProcessQueued` |
| Lifecycle notice | `RuntimeNotice` / `RuntimeNoticeKind` | `RuntimeNotice` / `RuntimeNoticeKind` |
| Pending and drain notices | `Runtime::pending_runtime_notices` / `drain_runtime_notices` | `Runtime.PendingRuntimeNotices` / `DrainRuntimeNotices` |
| Notice drop diagnostics | `Runtime::runtime_notice_diagnostics` | `Runtime.RuntimeNoticeDiagnostics` |
| Test harness notices | `Harness::pending_runtime_notices` / `drain_runtime_notices` / `runtime_notice_diagnostics` | `Harness.PendingRuntimeNotices` / `DrainRuntimeNotices` / `RuntimeNoticeDiagnostics` |
| Ignore event | `EventResult::ignored()` | `IgnoreResult[M]()` |
| Consume event | `EventResult::consumed()` | `ConsumeResult[M]()` |
| Emit one Message | `EventResult::message(value)` | `MessageResult(value)` |
| Geometry-aware pointer handler | `Node::on_pointer_event` | `Node.OnPointerEvent` |
| Pointer event geometry | `PointerEventContext` | `PointerEventContext` |
| Paragraph UTF-8 hit | `PointerEventContext::text_hit` / `TextHit` | `PointerEventContext.TextHit` / `TextHit` |
| Nearest pointer viewport | `PointerEventContext::viewport` / `PointerViewport` | `PointerEventContext.Viewport` / `PointerViewport` |
| Derive edge scroll | `PointerEventContext::edge_scroll` | `PointerEventContext.EdgeScroll` |
| Event-local scroll request | `EventResult::scroll_to` | `EventResult.ScrollTo` |
| Global ignore action | `EventAction::Ignore` | `IgnoreAction[M]()` |
| Global exit action | `EventAction::Exit` | `ExitAction[M]()` |
| No Effect | `Effect::none()` | `NoneEffect[M]()` |
| Effect without a view change | `effect.without_redraw()` | `effect.WithoutRedraw()` |
| Application exit Effect | `Effect::exit()` | `ExitEffect[M]()` |
| Focus Effect | `Effect::focus(id)` | `FocusEffect[M](id)` |
| Scroll Effect | `Effect::scroll_to(id, offset)` | `ScrollToEffect[M](id, offset)` |
| Clipboard Effect | `Effect::set_clipboard(text)` | `SetClipboardEffect[M](text)` |
| Terminal-suspending Effect | `Effect::suspend_terminal(task)` | `SuspendTerminalEffect[M](task)` |
| Full-screen terminal viewport | `TerminalViewport::FULLSCREEN` | zero `TerminalViewport` |
| Inline terminal viewport | `TerminalViewport::inline(height)` | `NewInlineTerminalViewport(height)` |
| Terminal viewport option | `TerminalOptions::viewport` | `TerminalOptions.Viewport` |
| Cursor query timeout | `TerminalOptions::cursor_query_timeout` | `TerminalOptions.CursorQueryTimeout` |
| Clipboard request | `ClipboardRequest` | `ClipboardRequest` |
| Pending clipboard request | `Runtime::pending_clipboard_request` | `Runtime.PendingClipboardRequest` |
| Take clipboard request | `Runtime::take_clipboard_request` | `Runtime.TakeClipboardRequest` |
| Test-harness clipboard request | `Harness::pending_clipboard_request` / `take_clipboard_request` | `Harness.PendingClipboardRequest` / `TakeClipboardRequest` |
| Pending terminal tasks | `Runtime::pending_terminal_tasks` | `Runtime.PendingTerminalTasks` |
| Run one terminal task | `Runtime::run_terminal_task` | `Runtime.RunTerminalTask` |
| Invalidate terminal diff baseline | `Runtime::invalidate_terminal_surface` | `Runtime.InvalidateTerminalSurface` |
| Test-harness terminal task | `Harness::pending_terminal_tasks` / `run_terminal_task` | `Harness.PendingTerminalTasks` / `RunTerminalTask` |
| Discard incomplete terminal input | `TimedInputDecoder::reset` | `TimedInputDecoder.Reset` |
| Ambiguous Kitty modifier mode | `Decoder::set_kitty_keyboard_mode` / `TimedInputDecoder::set_kitty_keyboard_mode` | `vt.Decoder.SetKittyKeyboardMode` / `TimedInputDecoder.SetKittyKeyboardMode` |
| No Subscription | `Subscription::none()` | `NoneSubscription[M]()` |
| Kitty key source protocol | `KeyProtocol::Kitty` | `vt.KeyProtocolKitty` |
| Kitty progressive flags | `KeyboardEnhancements::NAGI` | `vt.NagiKeyboardEnhancements` |
| Primary device attributes query | `TerminalOp::RequestPrimaryDeviceAttributes` | `vt.RequestPrimaryDeviceAttributes()` |
| Kitty flag query | `TerminalOp::QueryKeyboardEnhancements` | `vt.QueryKeyboardEnhancements()` |
| Kitty mode stack | `TerminalOp::PushKeyboardEnhancements` / `PopKeyboardEnhancements` | `vt.PushKeyboardEnhancements(...)` / `vt.PopKeyboardEnhancements()` |

Both terminal runners route and apply each Event decoded from one input chunk
before routing the next Event, then coalesce only the render. A terminal-
suspending Effect discards later decoded Events from that chunk before handing
the ordinary terminal to the task. Width-sensitive widgets receive the Runtime
profile explicitly from `ViewContext`; Core nodes use it automatically

Capability detection is disabled by default. When enabled, both standard
runners apply conservative environment hints, query Kitty keyboard support,
balance Nagi's enhancement stack across suspend and restore, and expose the
resulting immutable profile to the Runtime. Profile evidence is not output
permission; OSC 52 remains controlled by the independent clipboard option.
Detected color bounds the configured four-level VT encoder without promotion

The standard terminal runners execute each terminal task only after restoring
the original terminal and leaving the alternate screen or finalizing an inline
viewport. Resume re-enters the configured viewport and modes, reads local size,
resets incomplete decoder state, invalidates the diff baseline, and redraws.
Manual Runtime drivers own the equivalent boundary

The allocation-sensitive VT append APIs are `nagi_vt::append_encoded` and
`vt.AppendEncoded`. The origin-aware forms are `nagi_vt::append_encoded_at` and
`vt.AppendEncodedAt`. They append exactly the bytes produced by the matching
fresh-buffer encoder into caller-owned buffers

The typed write-only clipboard operation is `TerminalOp::SetClipboard` in Rust
and `vt.SetClipboard` in Go. Both encode normalized UTF-8 text as direct OSC 52;
neither API exposes clipboard reads or raw control-sequence injection

`ScrollAxis`, `ScrollOffset`, and `ScrollState` map directly to the Go types of
the same names. Rust test support uses `Harness::scroll_state` and
`Harness::exit_requested`; Go uses `Harness.ScrollState` and
`Harness.ExitRequested`

## CLI command applications

| Purpose | Rust | Go |
| --- | --- | --- |
| Command definition | `Command::new` | `cli.NewCommand` |
| Flag, count, value option | `OptionSpec::flag` / `count` / `value` | `cli.Flag` / `Count` / `ValueOption` |
| Make an option inherited | `OptionSpec::inherited` | `OptionSpec.Inherited` |
| Query inherited state | `OptionSpec::is_inherited` | `OptionSpec.IsInherited` |
| Hide a Command or Option projection | `Command::hidden` / `OptionSpec::hidden` | `Command.Hidden` / `OptionSpec.Hidden` |
| Deprecate a Command or Option | `Command::deprecated` / `OptionSpec::deprecated` | `Command.Deprecated` / `OptionSpec.Deprecated` |
| Query lifecycle metadata | `is_hidden` / `deprecation` | `IsHidden` / `Deprecation` |
| Replacement metadata | `Deprecation` | `cli.Deprecation` |
| Install a value completion provider | `OptionSpec::completion_provider` / `Argument::completion_provider` | `OptionSpec.CompletionProvider` / `Argument.CompletionProvider` |
| Positional argument | `Argument::new` | `cli.Positional` |
| Option cardinality group | `OptionGroup` | `cli.OptionGroup` |
| Raw, string, integer parser | `raw_parser` / `string_parser` / `integer_parser` | `cli.RawParser` / `StringParser` / `IntegerParser` |
| Finite-value parser | `possible_values_parser` | `cli.PossibleValuesParser` |
| Custom parser | `value_parser` | `cli.CustomParser` |
| Parsed command | `Invocation` | `cli.Invocation` |
| Structured deprecation uses | `Invocation::deprecation_notices` / `DeprecationNotice` | `Invocation.DeprecationNotices` / `cli.DeprecationNotice` |
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
| Structured inherited Help option | `HelpInheritedOption` | `cli.HelpInheritedOption` |
| Structured Help | `HelpDocument` | `cli.HelpDocument` |
| Help lifecycle metadata | `HelpDocument::deprecation` / `HelpEntry::deprecation` / `HelpInheritedOption::deprecation` | `HelpDocument.Deprecation` / `HelpEntry.Deprecation` / `HelpInheritedOption.Deprecation` |
| Help rendering | `HelpRenderer` | `cli.HelpRenderer` |
| Runtime services | `Context` | `cli.Context` |
| Handler result | `Outcome` | `cli.Outcome` |
| Structured failure | `Diagnostic` / `DiagnosticCode` | `cli.Diagnostic` / `cli.DiagnosticCode` |
| Diagnostic value target | `DiagnosticTarget` | `cli.DiagnosticTarget` |
| Diagnostic meaning | `DiagnosticCategory` | `cli.DiagnosticCategory` |
| Stable JSON Diagnostic renderer | `JsonDiagnosticRenderer` | `cli.JSONDiagnosticRenderer` |
| JSON Diagnostic schema | `JSON_DIAGNOSTIC_SCHEMA` | `cli.JSONDiagnosticSchema` |
| Optional usage presence | `Diagnostic::usage` | `Diagnostic.UsageValue` |
| Runtime compatibility | `RuntimePolicy` / `ExitCodePolicy` | `cli.RuntimePolicy` / `cli.ExitCodePolicy` |
| Optional deprecation notice output | `DeprecationNoticeRenderer` / `PlainDeprecationNoticeRenderer` | `cli.DeprecationNoticeRenderer` / `cli.PlainDeprecationNoticeRenderer` |
| Execute a Parse Result | `Command::run_parsed_with_policy` | `Command.RunParsedWithPolicy` |
| Execute an Invocation | `Command::run_invocation_with_policy` | `Command.RunInvocationWithPolicy` |
| Parser-only rendering and status | `RuntimePolicy::render_diagnostic` / `status_for_diagnostic` | `RuntimePolicy.RenderDiagnostic` / `StatusForDiagnostic` |
| Process execution | `Command::run_process` | `Command.RunProcess` |
| Manual cancellation | `cancellation_pair` | `context.WithCancel` with `NewContextWithCancellation` |
| Immutable completion model | `CompletionEngine::new` | `cli.NewCompletionEngine` |
| Tokenized completion input | `CompletionInput::new` | `cli.NewCompletionInput` |
| Completion resolution | `CompletionEngine::complete` | `CompletionEngine.Complete` |
| Dynamic provider | `CompletionProvider` | `cli.CompletionProvider` |
| Completion request and partial argv | `CompletionRequest` / `CompletionOccurrence` | `cli.CompletionRequest` / `cli.CompletionOccurrence` |
| Completion candidate | `CompletionCandidate` | `cli.CompletionCandidate` |
| Completion replacement metadata | `CompletionCandidate::deprecation` | `CompletionCandidate.Deprecation` |
| Shell script generation | `nagi_cli_completion::generate` | `completion.Generate` |
| Reserved protocol handling | `nagi_cli_completion::handle` | `completion.Handle` |
| Prompt executor | `Prompter` | `prompt.Prompter` |
| Confirm request | `Confirm` / `Prompter::confirm` | `prompt.Confirm` / `Prompter.Confirm` |
| Select request | `Select` / `Prompter::select` | `prompt.Select` / `Prompter.Select` |
| Visible input request | `Input` / `Prompter::input` | `prompt.Input` / `Prompter.Input` |
| Secret input request | `Secret` / `Prompter::secret` | `prompt.Secret` / `Prompter.Secret` |
| Injected prompt I/O | `PromptIo` | `prompt.IO` |
| Unix process prompt I/O | `ProcessIo::default` | `prompt.NewProcessIO` / `prompt.NewProcess` |
| Prompt terminal policy | `TerminalPolicy` | `prompt.TerminalPolicy` |
| Prompt resource limits | `Limits` | `prompt.Limits` |
| Prompt failure | `PromptError` / `PromptErrorKind` | `prompt.Error` / `prompt.ErrorKind` |
| Status reporter | `Reporter` | `status.Reporter` |
| Status construction | `Reporter::new` | `status.New` |
| Status snapshot | `Snapshot` / `SnapshotKind` | `status.Snapshot` / `status.SnapshotKind` |
| Plain status | `Snapshot::status` | `status.NewStatus` |
| Application-driven spinner | `Snapshot::spinner` | `status.NewSpinner` |
| Spinner frame count | `SPINNER_FRAME_COUNT` | `status.SpinnerFrameCount` |
| Determinate progress | `Snapshot::progress` | `status.NewProgress` |
| Update and final commit | `Reporter::update` / `finish` | `Reporter.Update` / `Finish` |
| Clear and permanent log | `Reporter::clear` / `log` | `Reporter.Clear` / `Log` |
| Injected status I/O | `StatusIo` | `status.IO` |
| Unix process status I/O | `ProcessIo::default` | `status.NewProcessIO` / `NewProcess` |
| Status options | `Options` | `status.Options` |
| Status failure | `StatusError` / `StatusErrorKind` | `status.Error` / `status.ErrorKind` |
| Process-free driver | `nagi_cli_test::TestDriver` | `clitest.Driver` |

Rust stores raw platform values as `OsString` and typed parser results behind
`Any`. Go preserves raw bytes in strings and exposes parser results through
`any` plus generic `ValueAs` and `RequireValueAs` helpers. Both use stable
command-ID paths to disambiguate reused local IDs. Rust cancellation is an
atomic token; Go cancellation is a `context.Context`

Both completion engines snapshot the validated graph, resolve only the selected
path, and call only the provider attached to the active value target. Rust
completion candidates contain valid UTF-8 by construction; Go validates UTF-8
before returning a result. Hidden declarations do not become candidates or
run a value provider. Deprecated static candidates carry replacement metadata
to the shell protocol. The shell layers remain separate from the command
runtime and intercept their reserved protocol before normal dispatch

Both Prompt implementations keep terminal I/O outside CLI Core and accept the
caller's cancellation source per request. Rust uses a closed `ReadResult` enum;
Go uses `ReadResult` plus `ReadResultKind` so an injected implementation can
return the same Line, End Of File, Input Too Long, or Canceled outcome. Rust
`Limits::default` and Go's zero `prompt.Limits` select the portable limits.
Secret values are ordinary `String` or `string` values in both implementations
and are not memory-zeroized by Prompt

Both Status implementations are synchronous and application-driven. Rust
`Options::default` and Go's zero `status.Options` select the portable limits
and Modern width profile. Both coalesce final rendered terminal lines or plain
fallback records, retain bounded scratch buffers, and leave cancellation and
update timing to the application. Rust Snapshot messages borrow valid `str`;
Go validates string UTF-8 before output

These representation differences do not change parsing, structured Help, or
Diagnostic semantics. Each implementation applies the same default Runtime
Policy, while applications may deliberately select a different renderer or
category-to-status mapping. See the [public CLI API guide](CLI_API.md) and
[command application semantics](../spec/cli.md) for the complete contract

See the [public API guide](API.md) and matching Rust and Go examples for
complete TUI application composition
