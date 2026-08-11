# Public API guide

[English](API.md)

Nagi TUIは、Rustの各crateとGoの各packageで言語に自然なAPIを提供しながら、外部から観測できる挙動を揃えます。Applicationはmodelを所有し、`view`から宣言的semantic Nodeを返し、`update`でMessageを逐次受信します

## Package境界

| 責務 | Rust | Go |
| --- | --- | --- |
| Application、runtime、layout、event、Effect、Subscription | `nagi-tui` | `github.com/mayahiro/nagitui-go`の`tui` package |
| Unicode graphemeと端末幅 | `nagi-text` | `github.com/mayahiro/nagi-go/text` |
| Typed terminal input／output、Color、Attributes、Style | `nagi-vt` | `github.com/mayahiro/nagi-go/vt` |
| Geometry、Cell、Surface、composition、snapshot | `nagi-surface` | `github.com/mayahiro/nagitui-go/surface` |
| 25個の標準Widget | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
| Virtual timeと決定的application操作 | `nagi-tui-test` | `github.com/mayahiro/nagitui-go/tuitest` |

Unix terminal bindingはprivateな実装詳細として維持します

`nagi-tui`とGoの`tui` packageはapplicationから使いやすくするためcanonicalなGeometry型とterminal Style型を再公開します。SurfaceはStyle型を複製せず、共有Go moduleはTUI moduleへ依存しません

## Application lifecycle

Applicationは4個のoperationを実装します

1. `init`は起動時のEffectを1個返す
2. `update`はMessageを1個適用して後続Effectを返す
3. `subscriptions`は現在の安定key付き長期sourceを宣言する
4. `view`はapplication stateと現在のterminal `Size`を持つ`ViewContext`からsemantic Node treeを再構築する

`update`は常に逐次実行します。EffectとSubscriptionは並行して値を生成できますが、そのresultは次のupdateより前に上限付きruntime queueへ入ります

Rustはassociated `Message` typeを持つ`App` traitを使用し、Goはgenericな`App[Message]` interfaceを使用します。完全な最小applicationは対応する[Rust counter](../nagi-rs/crates/nagi-tui/examples/counter/main.rs)と[Go counter](../nagitui-go/examples/counter/main.go)を参照してください

Production terminal applicationにおけるprocess output、timer、wake-up、renderの所有関係は[event-driven application architecture](EVENT_DRIVEN_APPLICATIONS_ja.md)を参照してください

Applicationはstate更新後に`Effect::exit()`または`ExitEffect`を返して終了できます。Terminal runnerは復元前に最後のdirty viewを描画します。Goは外部`context.Context` cancellation用の`RunTerminalContext`も提供し、terminal復元後に`ctx.Err()`を返します

Messageを処理しても`view`が参照する内容が変わらない場合、Rustでは`Effect::none().without_redraw()`、Goでは`tui.NoneEffect[Message]().WithoutRedraw()`を返せます。後続Effectの処理とSubscriptionの再調整は継続します。Modifierは`update`が返す最外側のEffectへ適用し、既存のdirty stateと同期UI commandは必要なframeを生成します

Production terminal runnerはterminal input、非同期EffectまたはStreamの通知、resize、最も近いclock-driven deadlineを待機し、idle中の周期的pollingを行いません
Wake-up通知はcoalesceできますが、queueまたはDelivery semanticsは変更しません
既定のterminal optionはnon-urgent描画を最大120 FPSへ制限し、minimum frame intervalをzeroにすると制限を無効化できます

## Semantic viewとInteraction

Core NodeにはText、RichText、Paragraph、安全なANSI Text、SurfaceNode、TextInput、Spacer、Gap、Row、Column、Stack、Padding、Border、Panel、Align、Clip、ScrollViewport、Modalがあります。Layoutは整数のterminal Cellと固定された丸め規則を使用します。VirtualScrollViewportは大規模content向けのvariantです

Stateful、focusable、event受信Nodeにはapplication定義の安定した`NodeId`が必要です。IDはview再構築後も維持し、collection内の位置だけから導出してはいけません。Duplicate IDはruntime errorです

Event handlerはMessage送信、event consume、focus変更、pointer captureとrelease、redraw要求を合成できるresultを返します。Publicなfocus style modifierは、特定された任意のNodeがfocusを所有する間だけstyleをoverlayし、layoutやroutingは変更しません

Rustの`Node::modal_with_focus`とGoの`ModalWithFocus`はdeclarativeなModal entryとreturn policyを追加します。Entryは最初のfocusable descendant、stable target、focusなしから選び、closeは以前のfocus、stable target、focusなしから選びます。既存Modal constructorのdefaultはFirstとPreviousです。Application stateによる消滅、nested Modal、重ねたsibling Modalも同じLIFO lifecycleを使用します。Rustの`Node::focus_fallback`とGoの`Node.FocusFallback`はfocused subtreeが消える場合に通常のdeterministic reconciliationより先にavailableなstable targetを選べます

ANSI Textはterminal形式のlog textからSGR colorとattributeだけを適用し、それ以外のcontrol sequenceを破棄して通常のstyled spanへ変換します。両方のviewport形式がaxis選択、末尾表示中のcontent追従、focused descendantの表示維持、focusを持たないidentified descendantのdeclarativeなreveal、解決済み`ScrollState`の通知に対応します。同じviewportではexplicit revealがfocus追従より優先し、nested viewportは内側から外側へ調整され、automatic revealはuser scroll messageを発行しません。Rustでは`Node::reveal_descendant`、Goでは`Node.RevealDescendant`を使用します。ScrollViewportはeagerなchild treeを受け取ります。VirtualScrollViewportは代わりにcontent全体のCell extentを受け取り、解決済みのvisible `VirtualViewport`に対応する`VirtualFragment`だけを構築してsemantic traversalへ入れます。標準ListとTableのviewportはsemantic rowにこのvirtual pathを使用しますが、既存collection APIは全itemまたはrow metadataをmaterializeし、Listのfilterは全件を走査します。Collection access自体もlazyにする場合はCore virtual viewportを直接使用します。標準ListとTableのvirtual viewport内では各rowを1 Cell高とし、折り返しまたは複数行のcontentをclipします

## Scoped KeyMap基盤

Rustの`ActionId`とGoの`ActionID`はterminal keyと独立して操作を識別します

`KeyStroke`はKeyと単一scalar Text inputを正規化し、`KeyBinding`はrepeatとcapability metadataを加え、immutableな`KeyMap` layerはactionのbinding list全体を置き換えます

`resolve_actions`と`ResolveActions`はactiveな`KeyScope`をrootからtargetの順で一つのsemantic ownerへ適用します

結果はaction、binding、scope順序を維持し、key文字列を重複させずにHelp-visible actionを抽出し、duplicateまたはambiguous bindingをstructured conflictとして返します

`Action`はdescriptorとNode-localなsemantic handlerを組み合わせます

Rustの`Node::on_actions`とGoの`Node.OnActions`は順序付きowner groupをattachし、Rustの`Node::with_key_scope`とGoの`Node.WithKeyScope`はoverrideとpropagation scopeをattachします

Runtimeはactiveなtarget-to-root routeをNodeDeclared action、CoreSemantic action、non-key Core handling、raw handler、ancestorの順で評価します

同じownerの等しいbindingではNodeDeclaredを別precedenceのCoreSemanticより先に評価します

ignored action resultとdisabled-pass-through bindingはroutingを継続し、disabled-consume bindingはhandlerを呼ばずにconsumeします

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

Coreはcursor移動、selection extension、select all、削除、改行挿入、undo、redoに対応する18個の`nagi.text.*` Action ID constantも公開します

TextAreaは既存のdefault keyとexplicit Repeat挙動を持つこれらのactionをfocus所有rootで宣言します

boundaryでの移動と削除はdefaultではEnabledのままMessageなしでconsumeします。Bubble navigationでは最初または最後のvisual lineにおけるUpとDownをDisabledPassThroughにできます。Opt-inのsoft wrapではUpとDownがpreferred visual columnを保持し、HomeとEndはlogical line操作のままです。TextArea viewportはTab stopを増やさずidentified caretへ追従します。undoとredoは対応callbackがない場合にDisabledPassThroughになります

TextとPasteはlocal action解決後のraw editing inputとして残り、Pasteはactionを起動しません

ComposerはTextAreaへcontrolled history recall、submit validity、1行から6行までの自動高さ、任意のvalidation content、UTF-8 byte数またはgrapheme数による挿入制限を加え、messageの意味や永続化は所有しません

同じrootで継承したtext actionより先に`nagi.composer.submit`、`nagi.history.previous`、`nagi.history.next`を宣言します

EnterはRepeatを受け付けずにsubmitし、Shift-Enter、Alt-Enter、Control-Oは改行を挿入します。別のvisual lineが存在する間はcursor移動を優先し、その後にUpまたはDownでhistoryをrecallします。Active scopeはsubmitと改行のbinding list全体を置換でき、Pasteはediting inputのままです

Command Paletteはrootでactivationとvertical selection、表示中の各command rowでactivationを宣言します

queryのTextInput editingはancestor root actionより先にText、Home、Endをlocalでconsumeし、Enter、Up、Downはroot defaultへ届きます

row activationはtarget-to-root順序でroot activationより先に処理され、raw左button入力と同じselect後activateのresultを使います

disabledまたはfilter結果が空のpaletteはDisabledPassThrough descriptorを公開します

ModalはconfigurableなFirstとPreviousのfocus lifecycle defaultを持ち、rootで`nagi.dismiss`を宣言して修飾なしEscapeだけをdefaultにします

dismiss handlerがない場合はDisabledPassThrough descriptorになります

child handlingはtarget-to-root precedenceを維持し、Modalは暗黙のstop-at-scope境界を追加しません

applicationはraw ancestor routingを止めずにこの境界を明示的にattachできます

Dialogはoptional title Node、body、controlled lazy Disclosure、順序付きapplication-defined actionをCore Modal内へ構成し、rootで`nagi.confirm`の後に`nagi.dismiss`を宣言します

Applicationはdefaultとcancelのaction IDを明示します。未選択roleはpass-throughし、enabled targetはaction Messageを発行し、設定済みtargetが欠落またはdisabledなら外へ伝播せずconsumeします。Root confirmはRepeatを受け付けないEnterをdefaultにし、focused action ButtonとDisclosure headerはchild precedenceを維持します。Default actionはApplicationがfocus policyをoverrideしない場合のentry targetにもなり、action rowはApplication suppliedのCell幅でgreedyにwrapします

ConfirmDialogはconfirmとcancelの二actionと明示的なConfirmまたはCancelのdefaultを受け取り、Dialogのfocus、wrapping、lazy detailsを再利用します。Destructive表現はNagi policyではなくApplication suppliedのButtonStyleとし、三択以上ではgeneric Dialogを使用します

Disclosureはcontrolledなfocusable summary、rebind可能なtoggle、collapse、expand action、raw pointer toggleを提供します。Collapsed時はbody builderを呼ばず、nested bodyが消える場合は最も近いsummaryへfocusを戻します

Paginatorはdotとnumeric modeの安定したrootでprevious、next、first、lastを宣言します

previousとnextの各fallbackは常に1 page移動し、boundary actionはMessageなしでconsumeします

非selected dotはkeyboard rebindから独立したraw左button経路を維持し、disabledまたはemptyのdescriptorはDisabledPassThroughになります

FilePickerはselected entry rootでactivation、entry単位4個とpage単位2個のselection action、navigation backを宣言します

page移動量はviewport height、viewportがない場合は10 entryです

openまたはback callbackがない場合は対応actionだけがDisabledPassThroughになり、visibleな非selected rowはkeyboard rebindから独立したrawのselect後open pointer経路を維持します

actionを宣言しないtreeでは既存Core、raw `OnEvent`、未移行Widget、terminal `mapEvent`の挙動を維持します

Tab traversalは引き続きaction routingより先に処理され、Button、Checkbox、Radio、Select、Tabs、List、Table、Tree、Disclosure、TextArea、Composer、Command Palette、Modal、Dialog、ConfirmDialog、Paginator、FilePicker、Calendar以外の標準Widgetはまだ移行していません

完全なdispatch、event matching、override、conflict、notationの契約は[Scoped KeyMap仕様](../spec/keymap.md)を参照してください

## EffectとSubscription

Effectはone-shot workを表します

- `Exit`、`Focus`、`ScrollTo`はRuntimeが同期適用するUI commandで、worker threadやgoroutineを起動しない
- `Run`は匿名workを開始する
- `Latest`はkey付きworkを置換してstale resultを抑止する
- `Cancel`とscope cancelは協調的な終了を要求する
- `After`はruntime clockを使用する
- `Batch`はchildを並行実行し、`Sequence`は順番に実行する
- `without_redraw`と`WithoutRedraw`は、現在のupdateだけでotherwise-cleanなruntimeへ要求されるframeを抑止する

Subscriptionは安定key付きの長期sourceを表します

- `Every`はruntime clockで値を生成する
- `Stream`は協調的cancelと上限付きsinkを受け取る
- Reliable配送はsource inboxが満杯になるとblockする
- Latest配送は最新のpending値だけを保持する
- Batch配送は件数または最大delayでFIFO値を解放する

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
- Dialogはapplication-defined action、明示的なdefaultとcancel target、lazy controlled details、modal focus policy、pointer activation、Cell幅によるaction wrappingを構成する
- ConfirmDialogはdefaultを明示する二action convenienceとApplication suppliedのdestructive styleを提供する
- Command Paletteはfilterされた安定したcommand IDに対するcontrolled query、root所有vertical action、row所有activationを組み合わせる
- Sparkline、BarChart、Chartは上限付きで決定的なCell graphicsを提供する
- Helpは手書きまたはresolved action由来のkey bindingをcompactまたはaligned形式で表示する
- Paginatorは同じroot所有のrebind可能なselection actionを通じてdotまたはnumeric形式のcontrolled page navigationを提供する
- FilePickerはfilesystem I/Oを行わずroot所有のactivation、entryとpage selection、back actionを通じてapplication suppliedの不活性entry metadataをnavigateする
- Calendarはactive dateが所有する個別にrebind可能なday、week、month、表示月境界selection actionを持つcontrolledなproleptic Gregorian month gridを提供する

Widget galleryでは標準library全体を一覧できます。Dashboard、filter付きList、file browser、multi-pane log viewer、form validationのexampleでは、同じpublic NodeとWidgetをapplication形式のlayoutへ構成する方法を確認できます

実装間の移植は[RustとGoのAPI対応表](API_MAPPING_ja.md)を参照してください

## Testing

Rust `nagi-tui-test`とGo `tuitest`はvirtual input、size、time、frame history、Message history、Interaction State検査、controlled Effect、手動Subscription、supervisor diagnostic、解決済みScrollState、activeなresolved action group、application終了要求の検査を提供します

Application testではreal sleepやterminal timingへ依存しないようにvirtual timeとcontrolled async sourceを使用してください

## Interactive example

Rust commandは`nagi-rs`、Go commandは`nagitui-go`から実terminalで実行します

| Example | Rust | Go |
| --- | --- | --- |
| Counter | `cargo run -p nagi-tui --example counter` | `go run ./examples/counter` |
| Command palette | `cargo run -p nagi-tui --example command_palette` | `go run ./examples/command-palette` |
| Async search | `cargo run -p nagi-tui --example async_search` | `go run ./examples/async-search` |
| Event-driven log viewer | `cargo run -p nagi-tui --example log_viewer` | `go run ./examples/log-viewer` |
| Virtual scroll | `cargo run -p nagi-tui --example virtual_scroll` | `go run ./examples/virtual-scroll` |
| Widget gallery | `cargo run -p nagi-tui-widgets --example widget_gallery` | `go run ./examples/widget-gallery` |
| Extended widget gallery | `cargo run -p nagi-tui-widgets --example extended_widget_gallery` | `go run ./examples/extended-widget-gallery` |
| Dashboard | `cargo run -p nagi-tui-widgets --example dashboard` | `go run ./examples/dashboard` |
| Filter付きList | `cargo run -p nagi-tui-widgets --example filtered_list` | `go run ./examples/filtered-list` |
| File browser | `cargo run -p nagi-tui-widgets --example file_browser` | `go run ./examples/file-browser` |
| Multi-pane log viewer | `cargo run -p nagi-tui-widgets --example multi_pane_log_viewer` | `go run ./examples/multi-pane-log-viewer` |
| Form validation | `cargo run -p nagi-tui-widgets --example form_validation` | `go run ./examples/form-validation` |

各example directoryには用途、操作方法、制約を説明するREADMEがあります

Terminal restoreは正常return、error、panic経路でbest effortとして行います。Applicationからの終了では、復元前に最後のdirty viewを描画します。Process abort、nested session、suspendとresume、`/dev/tty`取得には対応していません
