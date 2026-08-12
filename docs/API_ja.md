# Public API guide

[English](API.md)

Nagi TUIは、Rustの各crateとGoの各packageで言語に自然なAPIを提供しながら、外部から観測できる挙動を揃えます。Applicationはmodelを所有し、`view`から宣言的semantic Nodeを返し、`update`でMessageを逐次受信します

## Package境界

| 責務 | Rust | Go |
| --- | --- | --- |
| Application、runtime、layout、event、Effect、Subscription | `nagi-tui` | `github.com/mayahiro/nagitui-go`の`tui` package |
| Source-neutral structured Content | `nagi-content` | `github.com/mayahiro/nagi-go/content` |
| Terminal Presentation Rules | `nagi-tui` | `github.com/mayahiro/nagitui-go`の`tui` package |
| ContentからNodeへのprojection | `nagi-tui` | `github.com/mayahiro/nagitui-go`の`tui` package |
| Unicode graphemeと端末幅 | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| Typed terminal input／output、Color、Attributes、Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry、Cell、Surface、composition、snapshot | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| 29個の標準Widget | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Virtual timeと決定的application操作 | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |

Unix terminal bindingはprivateな実装詳細として維持します

`nagi-tui`とGoの`tui` packageはapplicationから使いやすくするためcanonicalなGeometry型とterminal Style型を再公開します。SurfaceはStyle型を複製せず、共有Go moduleはTUI moduleへ依存しません

## Terminal Presentation Rules

`PresentationSheet`はsource-neutral Contentに対するCSS相当のterminal backendです

順序付き`PresentationRule`は全element、exact Role、exact Classのいずれかを表す`PresentationSelector`と、任意のopenな`PresentationState` tokenのall-of条件を使用します

`DeclarationValue`は各textとlayout propertyでUnspecified、Set、Initialを区別します

Rustの`PresentationSheet::resolve`とGoの`PresentationSheet.Resolve`はmatching ruleをsource orderで適用し、`ComputedPresentation`を返します

Text Style fieldはcallerが渡すStyleからinheritし、display、Length、gap、visual separator、wrap、alignmentはinheritしません

Rule resolutionはVT Style mergeを使わず、Content変更、Node生成、Element ID mapping、annotation activationを行いません

完全な境界は[Terminal Presentation guide](PRESENTATION_ja.md)を参照してください

Rustの`project_content`とGoの`ProjectContent`は独立した上限付きbackend bridgeです

訪問Elementをresolveし、Inline、Paragraph、Flow、Sequenceをstyled span、Paragraph、Column、Row Nodeへ対応付けます

State対応variantは同期的なelement単位callbackからactive Stateを取得します

ProjectionはContent node数、生成Node数、span数、depth、visual UTF-8 byte数を明示的に制限します

Inline content内のblock displayを拒否し、Node IDの割り当て、annotation activation、VirtualFlow itemの生成またはcacheを行いません

完全な契約は[ContentからNodeへのprojection仕様](../spec/content-node-projection.md)を参照してください

## Application lifecycle

Applicationは4個のoperationを実装します

1. `init`は起動時のEffectを1個返す
2. `update`はMessageを1個適用して後続Effectを返す
3. `subscriptions`は現在の安定key付き長期sourceを宣言する
4. `view`はapplication stateと現在のterminal `Size`および`WidthProfile`を持つ`ViewContext`からsemantic Node treeを再構築する

`update`は常に逐次実行します。EffectとSubscriptionは並行して値を生成できますが、そのresultは次のupdateより前に上限付きruntime queueへ入ります。1回のterminal readから複数Eventがdecodeされた場合も、各Eventのrouting、fallback mapping、入力由来update、semantic tree更新を完了してから次のEventを処理し、Surface描画だけをbatch全体でcoalesceします

`RuntimeConfig`と`TerminalOptions`はRuntime lifetime全体で使用するNagi Textの`WidthProfile`を1個選択します。Coreのmeasure、wrap、draw、hit geometry、cursor配置は自動的に同じprofileを使います。幅計算を行うWidgetはRustの`width_profile`とGoの`WidthProfile`を提供するため、RuntimeがModern以外を使う場合は`ViewContext`の値を渡します。Custom overrideは同じgraphemeに対してRuntime lifetime中に安定した幅を返す必要があります

Rustで`TerminalOptions`を全field指定のstruct literalとして構築するcallerは`clipboard` fieldも指定する必要があります
`..TerminalOptions::default()`を使うliteralは追加設定なしでdisabled defaultを維持します

Rustはassociated `Message` typeを持つ`App` traitを使用し、Goはgenericな`App[Message]` interfaceを使用します。完全な最小applicationは対応する[Rust counter](../nagi-rs/crates/nagi-tui/examples/counter/main.rs)と[Go counter](../nagitui-go/examples/counter/main.go)を参照してください

Production terminal applicationにおけるprocess output、timer、wake-up、renderの所有関係は[event-driven application architecture](EVENT_DRIVEN_APPLICATIONS_ja.md)を参照してください

Applicationはstate更新後に`Effect::exit()`または`ExitEffect`を返して終了できます。Terminal runnerは復元前に最後のdirty viewを描画します。Goは外部`context.Context` cancellation用の`RunTerminalContext`も提供し、terminal復元後に`ctx.Err()`を返します。Caller contextはEffectとStream contextの親にもなり、value、deadline、cancellation、cancel causeを維持します。手動driveするGo Runtimeでは`NewRuntimeContext`または`NewRuntimeWithClockContext`を使用できます

Messageを処理しても`view`が参照する内容が変わらない場合、Rustでは`Effect::none().without_redraw()`、Goでは`tui.NoneEffect[Message]().WithoutRedraw()`を返せます。後続Effectの処理とSubscriptionの再調整は継続します。Modifierは`update`が返す最外側のEffectへ適用し、既存のdirty stateと同期UI commandは必要なframeを生成します

Production terminal runnerはterminal input、非同期EffectまたはStreamの通知、resize、最も近いclock-driven deadlineを待機し、idle中の周期的pollingを行いません
Wake-up通知はcoalesceできますが、queueまたはDelivery semanticsは変更しません
既定のterminal optionはnon-urgent描画を最大120 FPSへ制限し、minimum frame intervalをzeroにすると制限を無効化できます

回復したEffect panic、active Streamの予期しないreturn、Stream panic、worker spawn failureはApplication Messageと別の上限付き`RuntimeNotice` FIFOへ入ります。Noticeはviewをdirtyにしません。手動Runtime driverはqueueをdrainしてdrop counterを確認でき、terminal applicationは`run_terminal_with_notice_handler`、`RunTerminalWithNoticeHandler`、Goのcontext-aware variantを使用できます。Noticeをstate、Message、log、telemetryのどれへ変換するかはApplicationが決めます

## Semantic viewとInteraction

Core NodeにはText、RichText、Paragraph、安全なANSI Text、SurfaceNode、TextInput、CursorAnchor、Spacer、Gap、Row、Column、Stack、AnchoredOverlay、Padding、Border、Panel、Align、Clip、ScrollViewport、Modalがあります。Layoutは整数のterminal Cellと固定された丸め規則を使用します。VirtualScrollViewportとVirtualFlowは大規模content向けのvariantです

Stateful、focusable、event受信Nodeにはapplication定義の安定した`NodeId`が必要です。IDはview再構築後も維持し、collection内の位置だけから導出してはいけません。Duplicate IDはruntime errorです

Event handlerはMessage送信、event consume、focus変更、pointer captureとrelease、1個のviewport offset、redraw要求を合成できるresultを返します。Publicなfocus style modifierは、特定された任意のNodeがfocusを所有する間だけstyleをoverlayし、layoutやroutingは変更しません

Rustの`Node::cursor_anchor`とGoの`CursorAnchor`はhorizontal layout幅を消費せず、stable ownerがfocusを持つ間だけtyped Surface cursorを設定します。Caret文字を描かないため後続textを移動せず、terminal IME位置は描画cursorへ追従します

Rustの`Node::anchored_overlay`とGoの`AnchoredOverlay`はidentified descendantを基準に、measureへ加えずfront layerを配置します。Side、alignment、gap、flipまたはclip fallback、size上限をprimitiveのvisible boundary内で解決します。Anchorがhiddenまたはabsentならlayerをrenderとroutingから外し、visible layerがbaseと重なる場合はbaseより後にrenderしてpointer hitを受けます。Zero-width CursorAnchorは座標がboundaryとinherited clipの内側にある間はvisibleな配置pointです。Primitive自体はfocusやmodal policyを追加しません

Rustの`Node::block_unhandled_events`とGoの`Node.BlockUnhandledEvents`はidentified Nodeへopt-inのhard boundaryを追加します。そのNodeのlocal action、Core handling、pointer handler、raw handlerがEventをconsumeしなかった場合、ancestor raw handlerまたはterminal fallback mappingへ届く前にboundaryがconsumeします。Defaultはsoft boundaryのままです

Rustの`Node::modal_with_focus`とGoの`ModalWithFocus`はdeclarativeなModal entryとreturn policyを追加します。Entryは最初のfocusable descendant、stable target、focusなしから選び、closeは以前のfocus、stable target、focusなしから選びます。既存Modal constructorのdefaultはFirstとPreviousです。Application stateによる消滅、nested Modal、重ねたsibling Modalも同じLIFO lifecycleを使用します。Rustの`Node::focus_fallback`とGoの`Node.FocusFallback`はfocused subtreeが消える場合に通常のdeterministic reconciliationより先にavailableなstable targetを選べます

ANSI Textはterminal形式のlog textからSGR colorとattributeだけを適用し、それ以外のcontrol sequenceを破棄して通常のstyled spanへ変換します。両方のviewport形式がaxis選択、末尾表示中のcontent追従、focused descendantの表示維持、focusを持たないidentified descendantのdeclarativeなreveal、解決済み`ScrollState`の通知に対応します。同じviewportではexplicit revealがfocus追従より優先し、nested viewportは内側から外側へ調整され、automatic revealはuser scroll messageを発行しません。Rustでは`Node::reveal_descendant`、Goでは`Node.RevealDescendant`を使用します。ScrollViewportはeagerなchild treeを受け取ります。VirtualScrollViewportは代わりにcontent全体のCell extentを受け取り、解決済みのvisible `VirtualViewport`に対応する`VirtualFragment`だけを構築してsemantic traversalへ入れます。標準ListとTableのviewportはsemantic rowにこのvirtual pathを使用しますが、既存collection APIは全itemまたはrow metadataをmaterializeし、Listのfilterは全件を走査します。Collection access自体もlazyにする場合はCore virtual viewportを直接使用します。標準ListとTableのvirtual viewport内では各rowを1 Cell高とし、折り返しまたは複数行のcontentをclipします

VirtualFlowは一意なstable item IDのimmutable order、revision付きinvalidation hint、幅を考慮したheight estimate、item Node builderを受け取ります。Interaction Stateへ実測height、prefix-height index、vertical ScrollState、安定したsemantic anchorを保持します。末尾にいる間だけappendとtail growthへ追従し、末尾から離れている場合はprepend、削除、並べ替え、streaming height変更、terminal幅変更後も最初のvisible itemとitem内Cell offsetを維持します。Visible itemとCell単位の上限付きoverscanだけを構築します。Intrinsic高は0のため、親がlayout lengthまたはrectangleを割り当てる必要があります。Item content、未読policy、paging、永続化はApplicationが所有します

## Scoped KeyMap基盤

Rustの`ActionId`とGoの`ActionID`はterminal keyと独立して操作を識別します

`KeyStroke`はKeyと単一scalar Text inputを正規化し、`KeyBinding`はrepeatとcapability metadataを加え、immutableな`KeyMap` layerはactionのbinding list全体を置き換えます

`resolve_actions`と`ResolveActions`はactiveな`KeyScope`をrootからtargetの順で一つのsemantic ownerへ適用します

結果はaction、binding、scope順序を維持し、key文字列を重複させずにHelp-visible actionを抽出し、duplicateまたはambiguous bindingをstructured conflictとして返します

`Action`はdescriptorとNode-localなsemantic handlerを組み合わせます

Rustの`Node::on_actions`とGoの`Node.OnActions`は順序付きowner groupをattachし、Rustの`Node::with_key_scope`とGoの`Node.WithKeyScope`はoverrideとpropagation scopeをattachします

Runtimeはactiveなtarget-to-root routeをNodeDeclared action、CoreSemantic action、non-key Core handling、geometry-aware pointer handler、raw handler、ancestorの順で評価します

同じownerの等しいbindingではNodeDeclaredを別precedenceのCoreSemanticより先に評価します

ignored action resultとdisabled-pass-through bindingはroutingを継続し、disabled-consume bindingはhandlerを呼ばずにconsumeします。Disabled-consumeはinitial-only strokeのexplicit repeatもblockし、EnabledとDisabledPassThroughでは従来どおりbindingのrepeat policyを適用します

`stop-at-scope`はouter ancestorのNodeDeclaredとCoreSemantic action groupを除外し、raw event routing、wheel scroll、root-to-targetのKeyMap継承は止めません

Runtimeはhandler実行前に同じprecedence group内のconflictをstructured errorとして拒否し、`active_action_groups`と`ActiveActionGroups`からactiveなresolved groupを公開します

同じNodeではNodeDeclared projectionの次にCoreSemantic projectionを返すため、同じownerが2回現れる場合があります

test harnessも同じprojectionを公開します

CoreはexactなTabとShift-Tabをdefaultに持つ`nagi.focus.next`と`nagi.focus.previous`のAction ID constantを公開します

focused targetがこれらを所有し、focusがない場合はactive modalまたはidentified rootが所有します

KeyMap scopeから両方のdefaultをrebindまたは削除できます

stable ownerがないtreeではprojectまたはrebindできないcompatibility fallbackとしてdefault Tab traversalを維持します

Coreは`nagi.scroll.page-up`、`nagi.scroll.page-down`、`nagi.scroll.start`、`nagi.scroll.end`のAction ID constantも公開します

各ScrollViewportがexactなPageUp、PageDown、Home、Endのdefaultを所有します

nearest applicable viewportがmatchをconsumeし、horizontal-only viewportではpage actionがpass-throughし、Both axisのHomeとEndはvertical axisを使用します

mouse wheel scrollはrebindされないnon-key Core handlingとして残ります

modifier付きPageUp、PageDown、Home、Endには明示的なbindingが必要です

Rustの`Help::from_resolved_actions`とGoの`NewHelpFromResolvedActions`は同じprojectionをeffective keyごとに一つのHelp bindingへ変換します

actionとbinding順序を維持し、Help-hidden actionを除外して、unavailableまたはunsupportedなbindingをdisabledにします

既存の手書き`HelpBinding`も引き続き利用できます

標準Widget packageは`nagi.activate`、entry単位4個とpage単位2個の`nagi.selection.*` operation、`nagi.navigation.back`、`nagi.collapse`、`nagi.expand`、`nagi.confirm`、`nagi.dismiss`を表すconstantを公開します

Button、Checkbox、Radio、Select、Tabsの各item、List、Table、Tree、Disclosure、Dialog action Button、Command Paletteはunmodified EnterとSpaceをdefaultに持つactivationを宣言します

Selectは単一ownerで4個のselection actionを宣言し、Tabs rootはLeft、Right、Home、End、List、Table、Tree、Command Palette rootはUp、Down、Home、Endをdefaultに持つ同じactionを宣言します

Paginatorはactivationを持たず同じ4 actionを宣言し、previousはLeft、Up、PageUp、nextはRight、Down、PageDownをdefaultにします

ListとTableはeagerとvirtualized contentで同じ単一root action groupを使用します

TreeはLeftとRightをdefaultに持つcollapseとexpandを追加し、fullとviewport layoutで同じ単一root action groupを使用します

FilePickerはRightをactivation fallbackへ追加し、page単位selectionとnavigation backも宣言します

Action IDを共有する場合もdefault bindingは各Widgetが所有し、active scopeから各binding list全体を置換または削除できます

左button pressはraw pointer handlingに残り、keyboard rebindの影響を受けません

Coreはcursor移動10個、対応するselection extension 10個、select all、前後削除、改行挿入、undo、redo、copy selection、copy documentに対応する28個の`nagi.text.*` Action ID constantも公開します

TextAreaは既存の18 operationのediting subsetを、従来のdefault keyとexplicit Repeat挙動を持つfocus所有rootで宣言します

boundaryでの移動と削除はdefaultではEnabledのままMessageなしでconsumeします。Bubble navigationでは最初または最後のvisual lineにおけるUpとDownをDisabledPassThroughにできます。Opt-inのsoft wrapではUpとDownがpreferred visual columnを保持し、HomeとEndはlogical line操作のままです。TextAreaは可視caret文字ではなくzero-widthのtyped cursor anchorを使い、viewportはTab stopを増やさずidentified cursor anchorへ追従します。undoとredoは対応callbackがない場合にDisabledPassThroughになります

TextとPasteはlocal action解決後のraw editing inputとして残り、Pasteはactionを起動しません

SelectableTextはgrapheme、word、logical line、documentの移動、対応するselection extension、select all、copy selection、copy documentからなる19 operationのdocument subsetを宣言します

Contentとselection stateはcontrolledかつgrapheme境界へ揃えられます。Copy actionはsource ID、semantic text、kind、元document上のUTF-8 byte rangeを持つownedなApplication Messageを発行します。ApplicationはそのMessageを`Effect::set_clipboard`または`SetClipboardEffect`へ変換できます。Runtime driverはcoalesceされた最新`ClipboardRequest`を参照またはtakeできます。標準terminal runnerはdefaultでrequestを破棄し、`TerminalClipboard::Osc52`または`TerminalClipboardOSC52`を明示した場合だけtypedなwrite-only OSC 52を出力します。Hidden spanがある場合は両copy actionを無効にします

`Node::on_pointer_event`とGoの`Node.OnPointerEvent`はraw `on_event`または`OnEvent`を置換せずmouse専用handlerを追加します

`PointerEventContext`はsignedなNode-local geometry、clip、Runtime width profile、capture所有状態、最も近いancestor viewport、Paragraphの`TextHit` UTF-8境界を渡します

`edge_scroll`と`EdgeScroll`は受信したMove Eventごとに最大1 Cellの移動を導出し、handlerは`EventResult::scroll_to`または`EventResult.ScrollTo`で適用します

明示Messageは変更されたviewportのcallback Messageより先にqueueされます

ComposerはTextAreaへcontrolled history recall、submit validity、1行から6行までの自動高さ、任意のvalidation content、UTF-8 byte数またはgrapheme数による挿入制限を加え、messageの意味や永続化は所有しません

同じrootで継承したtext actionより先に`nagi.composer.submit`、`nagi.history.previous`、`nagi.history.next`を宣言します

EnterはRepeatを受け付けずにsubmitし、Shift-Enter、Alt-Enter、Control-Oは改行を挿入します。別のvisual lineが存在する間はcursor移動を優先し、その後にUpまたはDownでhistoryをrecallします。Active scopeはsubmitと改行のbinding list全体を置換でき、Pasteはediting inputのままです。Submitがinvalidな場合はinitialとrepeatのEnterをどちらもlocalでconsumeします

SuggestionPopupはapplication supplied contentをgeneric AnchoredOverlayで包み、supplied editorまたは別のfocus ownerへfocusを残します。Candidate取得、query解析、ranking、stable candidate ID、selected ID、async generation、acceptの意味はApplicationが所有します。`SuggestionItems`は一意なimmutable orderを一度検証し、view再構築をまたいでstorageを共有します。Widgetはselected itemを含むbounded windowだけを構築し、差し替え可能なLoadingとempty Nodeを表示して、Enter accept、repeat可能なUpとDown selection、Escape dismissを宣言します。Local scopeはReady candidateがinteractiveな間だけComposerとTextAreaの競合bindingを外し、左button activationはfocusを移さずselection後にacceptを発行します

対応する[Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/suggestion_popup/README.md)と[Go example](../nagitui-go/examples/suggestion-popup/README.md)はcancellableなlatest-result searchをApplicationへ維持します

JsonInspectorはtextをparseしたり第三者JSON valueへ依存したりせず、typed immutable JSONを受け取ります。`JsonDocument`は上限付きsource resourceを一度検証し、object順序とnumber表記を保持してstableなJSON Pointer pathをindex化します。Controlled WidgetはselectionとexpansionをApplicationへ維持し、指定時はselection追従のbounded windowだけを構築し、表示上のStringとNumber previewだけを省略します。Copy callbackはselected compact value全体を保持します。詳細は[JSON inspector仕様](../spec/json-inspector.md)、[Rust example](../nagi-rs/crates/nagi-tui-widgets/examples/json_inspector/README.md)、[Go example](../nagitui-go/examples/json-inspector/README.md)を参照してください

Command Paletteはrootでactivationとvertical selection、表示中の各command rowでactivationを宣言します

queryのTextInput editingはancestor root actionより先にText、Home、Endをlocalでconsumeし、Enter、Up、Downはroot defaultへ届きます

row activationはtarget-to-root順序でroot activationより先に処理され、raw左button入力と同じselect後activateのresultを使います

disabledまたはfilter結果が空のpaletteはDisabledPassThrough descriptorを公開します

ModalはconfigurableなFirstとPreviousのfocus lifecycle defaultを持ち、rootで`nagi.dismiss`を宣言して修飾なしEscapeだけをdefaultにします

dismiss handlerがない場合はDisabledPassThrough descriptorになります

child handlingはtarget-to-root precedenceを維持し、Modalは暗黙のaction boundaryまたはraw Event boundaryを追加しません。KeyMapのstop-at-scopeはouter semantic actionだけを止めます。Approval inputを分離するApplicationはModal rootへhard unhandled-Event boundaryも適用できます

Dialogはoptional title Node、body、controlled lazy Disclosure、順序付きapplication-defined actionをCore Modal内へ構成し、rootで`nagi.confirm`の後に`nagi.dismiss`を宣言します

Applicationはdefaultとcancelのaction IDを明示します。未選択roleはpass-throughし、enabled targetはaction Messageを発行し、設定済みtargetが欠落またはdisabledなら外へ伝播せずconsumeします。Root confirmはRepeatを受け付けないEnterをdefaultにし、focused action ButtonとDisclosure headerはchild precedenceを維持します。設定済みdefaultが欠落またはdisabledの場合はrepeat Enterもblockします。Default actionはApplicationがfocus policyをoverrideしない場合のentry targetにもなり、action rowはApplication suppliedのCell幅でgreedyにwrapします

ConfirmDialogはconfirmとcancelの二actionと明示的なConfirmまたはCancelのdefaultを受け取り、Dialogのfocus、wrapping、lazy detailsを再利用します。Destructive表現はNagi policyではなくApplication suppliedのButtonStyleとし、三択以上ではgeneric Dialogを使用します

Disclosureはcontrolledなfocusable summary、rebind可能なtoggle、collapse、expand action、raw pointer toggleを提供します。Collapsed時はbody builderを呼ばず、nested bodyが消える場合は最も近いsummaryへfocusを戻します

Paginatorはdotとnumeric modeの安定したrootでprevious、next、first、lastを宣言します

previousとnextの各fallbackは常に1 page移動し、boundary actionはMessageなしでconsumeします

非selected dotはkeyboard rebindから独立したraw左button経路を維持し、disabledまたはemptyのdescriptorはDisabledPassThroughになります

FilePickerはselected entry rootでactivation、entry単位4個とpage単位2個のselection action、navigation backを宣言します

page移動量はviewport height、viewportがない場合は10 entryです

openまたはback callbackがない場合は対応actionだけがDisabledPassThroughになり、visibleな非selected rowはkeyboard rebindから独立したrawのselect後open pointer経路を維持します

actionを宣言しないtreeでは既存Core、raw `OnEvent`、未移行Widget、terminal `mapEvent`の挙動を維持します

Tab traversalは引き続きaction routingより先に処理され、Button、Checkbox、Radio、Select、Tabs、List、Table、Tree、Disclosure、TextArea、Composer、SuggestionPopup、SelectableText、JsonInspector、Command Palette、Modal、Dialog、ConfirmDialog、Paginator、FilePicker、Calendar以外の標準Widgetはまだ移行していません

完全なdispatch、event matching、override、conflict、notationの契約は[Scoped KeyMap仕様](../spec/keymap.md)を参照してください

## EffectとSubscription

Effectはone-shot workを表します

- `Exit`、`Focus`、`ScrollTo`、`SetClipboard`はRuntimeが同期適用するUI commandで、worker threadやgoroutineを起動しない
- `SetClipboard`はviewのdirty状態と独立して、pendingなsemantic UTF-8 textを最新1件だけ保持する
- `Run`は匿名workを開始する
- `Latest`はkey付きworkを置換してstale resultを抑止する
- `Cancel`とscope cancelは協調的な終了を要求する
- `After`はruntime clockを使用する
- `Batch`はchildを並行実行し、`Sequence`は順番に実行する
- `without_redraw`と`WithoutRedraw`は、現在のupdateだけでotherwise-cleanなruntimeへ要求されるframeを抑止する

Goのcontext-aware Runtimeとterminal entry pointはcaller contextからEffect contextをderiveし、Runtime closeでも各childへ協調的cancellationを要求します

Subscriptionは安定key付きの長期sourceを表します

- `Every`はruntime clockで値を生成する
- `Stream`は協調的cancelと上限付きsinkを受け取る
- Reliable配送はsource inboxが満杯になるとblockする
- Latest配送は最新のpending値だけを保持する
- Batch配送は件数または最大delayでFIFO値を解放する

Active Streamは長期稼働を前提とし、generationがactiveな間の正常returnはRuntime noticeになります。要求済みcancellation後のreturnはnoticeにならず、回復したpanicは常にpanic noticeになります

時間依存の挙動はVirtualClockでテストし、application test内でsleepしないでください

## 標準Widget

標準Widgetはpublic Core composition APIとpublic Unicode text APIで実装されています

- Listはroot所有のactivationとvertical selection actionを持つ1個のcomposite Tab stopとして動作し、raw item pointer target、filter、window、pagination、`Length` viewportを使用する
- Buttonはunmodified EnterとSpaceをdefaultに持つ`nagi.activate`と、別routeの左button pressでactivateする
- Modalはborder付きのfocusとrouting scopeを中央配置し、ancestor action境界を強制せずroot所有のrebind可能なdismissal actionを宣言する
- Progressはinteger overflowなしで上限付きdeterminate progressを描画する
- Spinnerはapplication clockで進める安定したframe cycleを描画する
- Scrollbarはoverflowを避けてverticalまたはhorizontalのviewport geometryを描画する
- CheckboxとRadioは同じ`nagi.activate` bindingを公開しながら、controlled Boolean入力と重複Messageを出さずにconsumeするgroup choiceを提供する
- Tabsはitemごとのactivationとroot所有のhorizontal selection actionを公開し、application selectionとitem focusを独立させる
- Selectは共有Action IDを通じてWidget所有のactivationとselection defaultを公開し、wrapするactivationとboundary consumeを維持する
- Tableはeagerとvirtualized bodyで同じroot action setを持つ1個のcomposite Tab stopとして動作し、columnと任意のbody viewportを`Length`でsizeし、headerを固定してkeyboard selectionへ追従する
- Treeはroot所有のactivation、vertical selection、collapse、expand actionを持つ1個のcomposite Tab stopとして動作し、application所有の展開状態、再利用可能な`TreeState`、selection追従viewportを使ってflat preorder modelをfilterする
- TextAreaはselection、no-wrapまたはopt-in soft-wrap visual line、preferred-column navigation、任意のcaret追従viewport、application所有のundoとredo history、binding list全体をrebindできるroot所有semantic action setを使い、extended grapheme境界でmultiline textを編集する
- Composerはmessageの意味や永続化を所有せず、TextAreaへcontrolled submit、history recall、挿入制限、自動row境界、application提供のvalidation contentを加える
- SuggestionPopupはapplication所有candidateとasync stateへgeneric anchored placement、bounded row構築、controlled selection、keyboard action、focusを維持するpointer activationを組み合わせる
- SelectableTextはimmutableなstyled contentとApplication所有のgrapheme境界に揃えたkeyboardおよび左drag selectionを表示し、controlled view再構築をまたぐcaptureと最寄りviewport端のscroll requestを行い、clipboard I/Oを行わずsemanticなselectionまたはdocument copy requestを発行する
- JsonInspectorはApplication所有のselectionとexpansion、上限付きvisible row構築、grapheme境界を保つscalar preview、完全なselected valueのcopy requestを使ってimmutableなtyped JSONを表示し、parser、schema validation、redaction、clipboard policy、domain上の意味をcomponent外に維持する
- VirtualFeedはdefaultで末尾追従するflexibleなVirtualFlowへ、Application制御のcentered empty、pinned loading-beforeとloading-after、bottom-end unread-indicator slotを構成する
- Dialogはapplication-defined action、明示的なdefaultとcancel target、lazy controlled details、modal focus policy、pointer activation、Cell幅によるaction wrappingを構成する
- ConfirmDialogはdefaultを明示する二action convenienceとApplication suppliedのdestructive styleを提供する
- Command Paletteはfilterされた安定したcommand IDに対するcontrolled query、root所有vertical action、row所有activationを組み合わせる
- Sparkline、BarChart、Chartは上限付きで決定的なCell graphicsを提供する
- Helpは手書きまたはresolved action由来のkey bindingをcompactまたはaligned形式で表示する
- Paginatorは同じroot所有のrebind可能なselection actionを通じてdotまたはnumeric形式のcontrolled page navigationを提供する
- FilePickerはfilesystem I/Oを行わずroot所有のactivation、entryとpage selection、back actionを通じてapplication suppliedの不活性entry metadataをnavigateする
- Calendarはactive dateが所有する個別にrebind可能なday、week、month、表示月境界selection actionを持つcontrolledなproleptic Gregorian month gridを提供する

Widget galleryでは標準library全体を一覧できます。Variable-height feed、Dashboard、filter付きList、file browser、multi-pane log viewer、form validationのexampleでは、同じpublic NodeとWidgetをapplication形式のlayoutへ構成する方法を確認できます

実装間の移植は[RustとGoのAPI対応表](API_MAPPING_ja.md)を参照してください

## Testing

Rust `nagi-tui-test`とGo `tuitest`はvirtual input、size、time、frame history、Message history、Interaction State検査、controlled Effect、手動Subscription、supervisorとRuntime notice diagnostic、解決済みScrollStateとVirtualFlowState、activeなresolved action group、application終了要求の検査を提供します。Input helperは1個のbyte chunkから複数Eventをdecodeする場合もEvent単位のcontrolled state更新を維持し、結果のrenderだけをcoalesceします

Application testではreal sleepやterminal timingへ依存しないようにvirtual timeとcontrolled async sourceを使用してください

## Interactive example

Rust commandは`nagi-rs`、Go commandは`nagitui-go`から実terminalで実行します

| Example | Rust | Go |
| --- | --- | --- |
| Counter | `cargo run -p nagi-tui --example counter` | `go run ./examples/counter` |
| Command palette | `cargo run -p nagi-tui --example command_palette` | `go run ./examples/command-palette` |
| Async search | `cargo run -p nagi-tui --example async_search` | `go run ./examples/async-search` |
| JSON inspector | `cargo run -p nagi-tui-widgets --example json_inspector` | `go run ./examples/json-inspector` |
| Event-driven log viewer | `cargo run -p nagi-tui --example log_viewer` | `go run ./examples/log-viewer` |
| Virtual scroll | `cargo run -p nagi-tui --example virtual_scroll` | `go run ./examples/virtual-scroll` |
| Variable-height feed | `cargo run -p nagi-tui-widgets --example virtual_feed` | `go run ./examples/virtual-feed` |
| Widget gallery | `cargo run -p nagi-tui-widgets --example widget_gallery` | `go run ./examples/widget-gallery` |
| Extended widget gallery | `cargo run -p nagi-tui-widgets --example extended_widget_gallery` | `go run ./examples/extended-widget-gallery` |
| Dashboard | `cargo run -p nagi-tui-widgets --example dashboard` | `go run ./examples/dashboard` |
| Filter付きList | `cargo run -p nagi-tui-widgets --example filtered_list` | `go run ./examples/filtered-list` |
| File browser | `cargo run -p nagi-tui-widgets --example file_browser` | `go run ./examples/file-browser` |
| Multi-pane log viewer | `cargo run -p nagi-tui-widgets --example multi_pane_log_viewer` | `go run ./examples/multi-pane-log-viewer` |
| Form validation | `cargo run -p nagi-tui-widgets --example form_validation` | `go run ./examples/form-validation` |

各example directoryには用途、操作方法、制約を説明するREADMEがあります

Terminal restoreは正常return、error、panic経路でbest effortとして行います。Applicationからの終了では、復元前に最後のdirty viewを描画します。Process abort、nested session、suspendとresume、`/dev/tty`取得には対応していません
