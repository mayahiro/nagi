# Event-driven TUI application

[English](EVENT_DRIVEN_APPLICATIONS.md)

Production用のNagi terminal applicationでは、通常Nagiのterminal runnerだけをUI schedulerとします
Applicationはevent sourceを宣言し、受信したMessageをstateへ反映します
Runtimeを独自のpolling loopやrender loopで囲みません

この構成ではdeadlineを持つsourceがなければframework由来の周期wake-upを避けられ、burstを1 frameへcoalesceし、Subscription cancellationの所有者を1個にできます

## 責務の所有

| 責務 | 所有者 |
| --- | --- |
| Terminal input、resize、wait、wake-up、render timing | Nagi terminal runner |
| Opt-inの起動時capability観測とkeyboard mode lifecycle | Nagi terminal runner |
| One-shot asynchronous work | Effect |
| 通常terminalを必要とする1個のblocking operation | SuspendTerminal Effectとterminal runner |
| Process outputなどの長期external input | Stream Subscription |
| Uptimeなどのclock-driven state | Every Subscription |
| Model変更 | Applicationの逐次update |
| Semantic UI構築 | Applicationのview |

Stream adapterはprocess stdout、socket、その他のexternal sourceを待つblocking read loopを持てます
このadapterは第2のUI loopではなく、上限付きsinkへMessageを送り、cancellationを監視し、viewやrenderを呼びません

```text
process stdout -> Stream(Batch) --\
uptime deadline -> Every(Latest) ---> bounded queue -> update -> dirty state
terminal input --------------------/                         |
                                                             v
                                                coalesced view and render
```

1回のterminal readから複数のUnicodeまたはkey Eventがdecodeされる場合があります。Nagiは1個のEventから生じるroutingと全updateを完了してから次のEventをrouteするため、controlled Widgetは常に最新stateから再構築されます。Input batch全体でcoalesceするのは結果のrenderだけです

Opt-inのcapability検出はterminal sessionを開いた後、最初のapplication viewより前に1回だけ実行します
UI loopへpolling sourceを追加せず、上限付きquery中に読んだ無関係なbyteは保持してsetup後に通常decoderへ渡します

1個のEventがterminal suspendを要求した場合、同じreadからdecode済みの後続Eventは破棄します。Runnerは通常terminalを復元し、Application所有taskをdriver threadで実行し、設定済みviewportを再開し、未完decoder stateをresetしてfull redrawを強制します

## Lifetimeに応じたsource選択

- Initまたはupdateから開始する有限workにはEffectを使う
- Interactive editor、shell、認証UIなど通常terminalを必要とする有限blocking workだけにSuspendTerminal Effectを使う
- 新しいrequestが古いworkを不要にする場合はkey付きLatest Effectを使う
- 長時間blockまたはcallbackを待つsourceにはStream Subscriptionを使う
- Clockによって実際に変化するstateだけにEvery Subscriptionを使う
- Terminal inputはevent handlerまたはterminal event mapperから渡す

UIを再描画するためだけのtimerは作りません
Source Messageがapplicationをdirtyにし、Nagiがframeをscheduleします

## Process monitor pattern

Process monitorでは通常2個の独立したsourceを宣言します

1. Process recordをReliableまたはBatch配送のStreamへ渡す
2. UptimeをLatest配送の1秒Every sourceへ渡す

Batch配送はFIFO recordを維持し、件数またはdelay上限で解放します
各recordは1回ずつ逐次updateへ届きますが、renderは上限付きscheduling cycleごとに最大1回で、frame intervalによって複数cycleをcoalesceできます
Uptimeは最新値だけが必要なためLatest配送に適しています

同じapplication stateではsource keyを安定させます
Subscriptions宣言からsourceを削除すると、Nagiはそのgenerationをcancelし、block中のsendをwakeし、updateへ入っていない値を破棄します
Producerはcancellationまたはclosed sinkを検出したらreturnし、detached threadやgoroutineを残しません

Goのterminalとcontext-aware Runtime entry pointはcaller contextからworker、terminal task、Stream contextをderiveします。Process adapterとtrace codeはvalue、deadline、cancellation、cancel causeをそのまま利用でき、Runtime closeでも各active childへcancellationを要求します

Runtime closeはcancellation要求だけを行います。Custom Runtime ownerがNagiの開始した全EffectとStream producerのreturnも確認する場合は、Rustの`close_and_wait`または`close_and_wait_timeout`、Goの`CloseAndWait(ctx)`を使います。Producerが開始したprocessやworkerのjoinはproducer自身の責務です

## Lifecycle notice

Active Streamは長期sourceであり、そのgenerationがactiveな間のreturnは予期しない`RuntimeNotice`になります。要求済みcancellation後のreturnはnoticeになりません。回復したEffectとStreamのpanic、およびworker spawn failureもnoticeになり、panic payloadは保持しません

NoticeはApplication Messageと別の上限付きFIFOを使い、保持済みの古いentryを優先し、満杯時はdrop counterを増やします。Notice自体は既定ではApplication Messageにならずviewをdirtyにしません。手動driveするRuntimeはnoticeをdrainでき、terminal runnerはlogやtelemetry向けの同期handlerと、第2のSubscriptionなしでapplication stateへ反映する任意Message mapperを提供します

## Renderとbackpressure

`MinimumFrameInterval`はnon-urgent frameを制限しますが、event-loopのpolling intervalではありません
Nagiは複数のsource Messageを処理して最新のapplication stateを保持し、描画をcoalesceできます
`MaxUpdatesPerCycle`は既定で64であり、terminal runnerがinputとresizeを再確認するまでに処理する非同期Message件数を制限します。処理可能なworkが残る場合は周期waitを挟まず次のcycleを開始します。この上限は決定的なMessage件数であり、Applicationの1 updateが遅い場合はinputも遅延し得ます
Frameworkが扱うkeyboard scroll、focus、resizeはurgentのままです

高頻度sourceでは次を守ります

- Data lossのcontractに応じてReliable、Batch、Latest配送を選ぶ
- Application queueとsource inboxを上限付きにする
- 保持履歴を上限付きにするかview model外へ永続化する
- 全logを再走査せず、recordがupdateへ入った時点でformatする
- View構築量をvisible rowへ制限するためVirtualScrollViewportを使う
- 通常のsource dataごとに`RequestFrame`または`request_frame`を呼ばない
- 未選択process用に保持するoutputなど、現在のviewが読むstateを変更しないMessageでは`Effect::none().without_redraw()`または`NoneEffect[Message]().WithoutRedraw()`を返す

`SetClipboard`も同期処理でありworkerを起動しません
Runtimeはpending requestを最新1件だけ保持するため、custom driverはcoalesced stepごとにtakeします
標準terminal runnerはdirectかつwrite-onlyのOSC 52を明示的に有効化しない限りrequestを破棄します
Copy Messageが表示中のapplication stateを変更しない場合はClipboard Effectへ`without_redraw`または`WithoutRedraw`を組み合わせます

`SuspendTerminal`もworkerを起動しません。Terminal driverがraw modeと設定済みviewportを安全に離れられるまでpendingのまま保持します。Full-screen sessionはalternate screenを離れ、Inline sessionは現在のmain-screen領域を確定します。既存workerとStreamはdriver taskがblockしている間も上限付きdelivery contractを維持しますが、Application updateとrenderはtask return後に再開します。Task自身がprocess statusまたはdomain errorをMessageへ変換します

## 第2のUI loopを避ける

標準的なterminal applicationでは次のpatternを避けます

- Application tickerからruntime stepまたはrenderを呼ぶ
- Streamでinputをblockできる場所を短いsleepでchannel pollingする
- Log recordごとに`RequestFrame`を呼ぶ
- View内でprocess I/Oやその他のblocking workを行う
- Application stateへ上限なしでlogを保持する
- 欠落できないrecordにLatest配送を使う

Terminal以外のhostへNagiを組み込む場合はRuntimeの手動driveが必要になることがあります
その場合はhost loopがterminal runnerと同じ責務を所有し、固定周期pollingではなく実際のreadinessまたはdeadlineを待ちます。Pending terminal taskを実行するmanual driverは独自の安全なsuspend／resume境界を用意し、復帰後にRuntime terminal surfaceをinvalidateする必要があります

## 実行可能なreference

対応するlog viewerは外部processなしで実行できるsimulated process sourceを使い、このarchitectureを実装します
各commandは対応するimplementation repository rootから実行します

- [Rust source](../nagi-rs/crates/nagi-tui/examples/log_viewer/main.rs):
  `cargo run -p nagi-tui --example log_viewer`
- [Go source](../nagitui-go/examples/log-viewer/main.go):
  `go run ./examples/log-viewer`

対応するterminal suspend exampleはApplicationが選択したinteractive shellを実行し、shell終了後に再開します

- [Rust source](../nagi-rs/crates/nagi-tui/examples/terminal_suspend/main.rs):
  `cargo run -p nagi-tui --example terminal_suspend`
- [Go source](../nagitui-go/examples/terminal-suspend/main.go):
  `go run ./examples/terminal-suspend`

Terminal capability exampleは起動時queryをopt-inし、各viewへ渡るimmutable profileを表示します

- [Rust source](../nagi-rs/crates/nagi-tui/examples/terminal_capabilities/main.rs):
  `cargo run -p nagi-tui --example terminal_capabilities`
- [Go source](../nagitui-go/examples/terminal-capabilities/main.go):
  `go run ./examples/terminal-capabilities`

Exampleを自己完結させるためsimulated producerはtimerを使います
Productではproducer本体だけをblocking process-output readerへ置き換え、application lifecycleとrenderの所有関係は維持します

## Test

`nagi-tui-test`またはGoの`tuitest`をvirtual timeとcontrolled Effect／Subscription sourceと組み合わせます
Application testでsleepせず、Messageとdeadlineを明示的にdriveします。Controlled editorでは複数scalar inputを1個のchunkとして渡し、Event単位updateとrender coalescingを同時に確認します。Harnessのterminal task methodを使うと、real terminalを変更せずresume、pending input破棄、result delivery、full redrawを再現できます
