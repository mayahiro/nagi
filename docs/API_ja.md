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
| 21個の標準Widget | `nagi-tui-widgets` | `github.com/mayahiro/nagitui-go/widget` |
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

Applicationはstate更新後に`Effect::exit()`または`ExitEffect`を返して終了できます。Terminal runnerは復元前に最後のdirty viewを描画します。Goは外部`context.Context` cancellation用の`RunTerminalContext`も提供し、terminal復元後に`ctx.Err()`を返します

## Semantic viewとInteraction

Core NodeにはText、RichText、Paragraph、安全なANSI Text、SurfaceNode、TextInput、Spacer、Gap、Row、Column、Stack、Padding、Border、Panel、Align、Clip、ScrollViewport、Modalがあります。Layoutは整数のterminal Cellと固定された丸め規則を使用します。VirtualScrollViewportは大規模content向けのvariantです

Stateful、focusable、event受信Nodeにはapplication定義の安定した`NodeId`が必要です。IDはview再構築後も維持し、collection内の位置だけから導出してはいけません。Duplicate IDはruntime errorです

Event handlerはMessage送信、event consume、focus変更、pointer captureとrelease、redraw要求を合成できるresultを返します。Publicなfocus style modifierは、特定された任意のNodeがfocusを所有する間だけstyleをoverlayし、layoutやroutingは変更しません

ANSI Textはterminal形式のlog textからSGR colorとattributeだけを適用し、それ以外のcontrol sequenceを破棄して通常のstyled spanへ変換します。両方のviewport形式がaxis選択、末尾表示中のcontent追従、focused descendantの表示維持、解決済み`ScrollState`の通知に対応します。ScrollViewportはeagerなchild treeを受け取ります。VirtualScrollViewportは代わりにcontent全体のCell extentを受け取り、解決済みのvisible `VirtualViewport`に対応する`VirtualFragment`だけを構築してsemantic traversalへ入れます。標準ListとTableのviewportはsemantic rowにこのvirtual pathを使用しますが、既存collection APIは全itemまたはrow metadataをmaterializeし、Listのfilterは全件を走査します。Collection access自体もlazyにする場合はCore virtual viewportを直接使用します。標準ListとTableのvirtual viewport内では各rowを1 Cell高とし、折り返しまたは複数行のcontentをclipします

## EffectとSubscription

Effectはone-shot workを表します

- `Exit`、`Focus`、`ScrollTo`はRuntimeが同期適用するUI commandで、worker threadやgoroutineを起動しない
- `Run`は匿名workを開始する
- `Latest`はkey付きworkを置換してstale resultを抑止する
- `Cancel`とscope cancelは協調的な終了を要求する
- `After`はruntime clockを使用する
- `Batch`はchildを並行実行し、`Sequence`は順番に実行する

Subscriptionは安定key付きの長期sourceを表します

- `Every`はruntime clockで値を生成する
- `Stream`は協調的cancelと上限付きsinkを受け取る
- Reliable配送はsource inboxが満杯になるとblockする
- Latest配送は最新のpending値だけを保持する
- Batch配送は件数または最大delayでFIFO値を解放する

時間依存の挙動はVirtualClockでテストし、application test内でsleepしないでください

## 標準Widget

標準Widgetはpublic Core composition APIとpublic Unicode text APIで実装されています

- Listは1個のcomposite Tab stopとして動作し、application所有のselection、安定したitem pointer target、filter、window、pagination、`Length` viewportを使用する
- ButtonはEnter、Space、左button pressでactivateする
- Modalはborder付きのfocusとrouting scopeを中央配置し、任意でEscape dismissを扱う
- Progressはinteger overflowなしで上限付きdeterminate progressを描画する
- Spinnerはapplication clockで進める安定したframe cycleを描画する
- Scrollbarはoverflowを避けてverticalまたはhorizontalのviewport geometryを描画する
- CheckboxとRadioはcontrolled Boolean入力とgroup choiceを提供する
- TabsとSelectはhorizontalまたはcompactなcontrolled selectionを提供する
- Tableは1個のcomposite Tab stopとして動作し、columnと任意のbody viewportを`Length`でsizeし、headerを固定してkeyboard selectionへ追従する
- Treeは1個のcomposite Tab stopとして動作し、application所有の展開状態、再利用可能な`TreeState`、selection追従viewportを使ってflat preorder modelをfilterする
- TextAreaはselection、horizontal scroll、application所有のundoとredo historyを使い、extended grapheme境界でmultiline textを編集する
- Command Paletteは安定したcommand IDに対するcontrolled query、filter、navigation、activationを組み合わせる
- Sparkline、BarChart、Chartは上限付きで決定的なCell graphicsを提供する
- Helpはcompactまたはaligned形式でkey bindingを表示する
- Paginatorはdotまたはnumeric形式のcontrolled page navigationを提供する
- FilePickerはfilesystem I/Oを行わずapplication suppliedの不活性entry metadataをnavigateする
- Calendarはcontrolledなproleptic Gregorian month gridを提供する

Widget galleryでは標準library全体を一覧できます。Dashboard、filter付きList、file browser、multi-pane log viewer、form validationのexampleでは、同じpublic NodeとWidgetをapplication形式のlayoutへ構成する方法を確認できます

実装間の移植は[RustとGoのAPI対応表](API_MAPPING_ja.md)を参照してください

## Testing

Rust `nagi-tui-test`とGo `tuitest`はvirtual input、size、time、frame history、Message history、Interaction State検査、controlled Effect、手動Subscription、supervisor diagnostic、解決済みScrollState、application終了要求の検査を提供します

Application testではreal sleepやterminal timingへ依存しないようにvirtual timeとcontrolled async sourceを使用してください

## Interactive example

Rust commandは`nagi-rs`、Go commandは`nagitui-go`から実terminalで実行します

| Example | Rust | Go |
| --- | --- | --- |
| Counter | `cargo run -p nagi-tui --example counter` | `go run ./examples/counter` |
| Command palette | `cargo run -p nagi-tui --example command_palette` | `go run ./examples/command-palette` |
| Async search | `cargo run -p nagi-tui --example async_search` | `go run ./examples/async-search` |
| Log viewer | `cargo run -p nagi-tui --example log_viewer` | `go run ./examples/log-viewer` |
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
