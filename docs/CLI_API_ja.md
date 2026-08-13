# Public CLI API guide

[English](CLI_API.md)

Nagi CLIは外部から観測できるcommand semanticsを揃えたnative Rust APIとGo APIを提供します

両実装はCommand Graphを検証し、platform argument valueをtyped Invocationへparseし、structured HelpとDiagnosticを構築し、注入されたContextを通じてHandlerを実行し、設定可能なRuntime Policyから明示的なExit Statusを返します

言語非依存の[command application specification](../spec/cli.md)をpublic behaviorの契約とします

`fixtures/cli`配下の共有fixtureでparsing、completion、Diagnostic、Help、runtime output、cancellation、byte保持を確認します

## Package

| 責務 | Rust | Go |
| --- | --- | --- |
| Command Graph、parser、runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go`の`cli` package |
| Shell completion生成とprotocol | `nagi-cli-completion` | `github.com/mayahiro/nagicli-go/completion` |
| 軽量interactive prompt | `nagi-cli-prompt` | `github.com/mayahiro/nagicli-go/prompt` |
| TTY-aware status report | `nagi-cli-status` | `github.com/mayahiro/nagicli-go/status` |
| Processなしのapplication test | `nagi-cli-test` | `github.com/mayahiro/nagicli-go/clitest` |
| Help label幅 | `nagi-text` | `github.com/mayahiro/nagi-go/text` |

Nagi CLIはNagi Surface、Nagi TUI、third-party CLI frameworkへ依存しません

## Command定義

Command、option、positionalは各言語に自然なbuilderで定義します

| 用途 | Rust | Go |
| --- | --- | --- |
| Command | `Command::new("name")` | `cli.NewCommand("name")` |
| Flag | `OptionSpec::flag("id")` | `cli.Flag("id")` |
| Count | `OptionSpec::count("id")` | `cli.Count("id")` |
| Value option | `OptionSpec::value("id")` | `cli.ValueOption("id")` |
| 継承Option | `.inherited()` | `.Inherited()` |
| Positional | `Argument::new("id")` | `cli.Positional("id")` |
| Option group | `OptionGroup::exactly_one(...)` | `cli.ExactlyOne(...)` |
| Child command | `.subcommand(command)` | `.Subcommand(command)` |
| Dynamic value completion | `.completion_provider(provider)` | `.CompletionProvider(provider)` |
| Typed validator | `.validator(validator)` | `.Validator(validator)` |
| Help Usage Variant | `.usage_variant(id, syntax)` | `.UsageVariant(id, syntax)` |
| Help example | `.example(name, invocation)` | `.Example(name, invocation)` |
| Help note | `.note(text)` | `.Note(text)` |
| Help link | `.link(label, url)` | `.Link(label, url)` |
| Custom Help section | `HelpSection::new(...)` | `cli.NewHelpSection(...)` |
| Handler | `.handler(handler)` | `.Handle(handler)` |

Longとshortの名前を明示します

Optionは既定でCommand-localです

継承Optionにすると、宣言したCommandと選択された全descendantで、subcommand選択やpositionalの前後を問わず`--`まで認識されます

Value optionにはrequired、repeated、environment fallback、default、`requires`、`conflicts`を設定できます

Relationはresolved presenceまたはcommand-line presenceを参照でき、宣言したCommand内に留まります

Portable option groupは同一Command上のoptionに対する`at-most-one`、`exactly-one`、`at-least-one`、`all-or-none` cardinalityを表します

Groupはdefault付きoptionを明示指定と誤認しないようcommand-line presenceを既定で使用します

Application固有のtyped validatorはparse、fallback解決、portable validationの後に実行されます

Rust validatorは`Result<(), Diagnostic>`、Go validatorはacceptを`nil`で表す`*Diagnostic`を返します

Structured Diagnosticを直接返すため、application code、semantic category、target、hintをrenderer固有の変換なしで維持できます

Argvを読む前にgraph全体を検証します

不正な名前、予約済みbuilt-in spelling、同一Command内のoptionとpositional ID衝突、sibling alias衝突、不正なpositional順序、不正なgroup、Commandをまたぐoption relationは`invalid-specification` Diagnosticになります

ParentとchildのCommandは同じvalue IDを再利用できます

Ancestorの宣言がlocalなら同じoption spellingも再利用できますが、descendantは可視な継承Optionのspellingを再利用できません

互いに無関係なbranchは独立しています

## Parsingとtyped value

Public parse methodはprogram nameを除いたargumentを受け取ります

Rustはraw valueを`OsString`、Goはbyte列を保持するstringとして保存します

不正UTF-8を許容する必要がある場合はraw parserを使用します

| Parser | Rust | Go |
| --- | --- | --- |
| Raw platform value | `raw_parser()` | `cli.RawParser()` |
| UTF-8 string | `string_parser()` | `cli.StringParser()` |
| Signed 64-bit integer | `integer_parser()` | `cli.IntegerParser()` |
| Finite value | `possible_values_parser(...)` | `cli.PossibleValuesParser(...)` |
| Custom typed value | `value_parser(...)` | `cli.CustomParser(...)` |

Invocationはcanonical command name path、stable command-ID path、選択したCommandごとのvalue scopeを保持します

Valueの完全なidentityはstable command-ID pathとcommand-local value IDの組です

このscopeにより、大規模なcommand treeでもCommand名を全IDへ埋め込まず、`session`や`output`のようなlocal IDを一貫して使用できます

Unqualified lookupはcurrent scopeからrootへ向かって検索します

近いCommandの宣言はvalueが未解決でもancestorの同名宣言をshadowします

Validatorのcurrent scopeはvalidatorを定義したCommand、Handlerのcurrent scopeは選択されたleaf Commandです

Parentなどのexact scopeを参照する場合はstable command-ID pathを指定して`Invocation::scope`または`Invocation.Scope`を使用します

`Invocation::scopes`と`Invocation.Scopes`は選択されたscopeをrootからleafの順に列挙します

継承Optionはdescendant選択後に現れた場合も、全occurrenceが宣言scopeへ保存されます

そのためduplicate checkとrepeated valueの順序はsubcommand前後を通して適用されます

Parseまたはvalidation Diagnosticは選択中のcommand pathとusageを維持しつつ、宣言元のstable command-ID pathをtargetにします

各parsed valueはcommand line、environment、defaultのどこから得たかを記録し、command-line valueが両fallbackより優先されます

`Invocation::contains`と`Invocation.Contains`はresolved presence、`Invocation::supplied`と`Invocation.Supplied`はnearest visible declarationがargvから指定されたかを返します

Exact scopeにもancestor lookupを行わない同じ操作があります

Rustはoptionalなtyped valueを`Invocation::value`と`Invocation::values`で取得します

Goは最初のvalueに`cli.ValueAs[T]`を使い、repeated valueの走査では`ParsedValue.Typed()`を使用します

Schema上必要なvalueのmappingには、Rustの`Invocation::require_value`またはGoの`cli.RequireValueAs[T]`をInvocationかInvocation Scopeと組み合わせて使用します

`ValueAccessError`はmissing valueとparser-result type mismatchを区別し、stable lookup scopeとlocal value IDを保持します

どのaccessorもdynamic typeをcoerceしません

## Shellとdynamic completion

`CompletionEngine::new`と`cli.NewCompletionEngine`はCommand Graphを検証し、handlerを含まないimmutableなcompletion modelとしてsnapshotします

Engineを1個構築してrequest間で再利用でき、構築後に元のgraphを変更してもEngineには影響しません

1個のrequestはshellが確定したtoken列とcursor位置のtoken prefixを分けて渡します

Rustは`CompletionInput::new(arguments, current)`と`CompletionEngine::complete`、Goは`cli.NewCompletionInput(arguments, current)`と`CompletionEngine.Complete`を使用します

Engineは選択されたcommand pathとそこから見える継承Optionだけを解決します

Alias、`--`、short option cluster、`--profile=dev`のようなattached value、repeated positional、built-in `help` pathを扱います

Finite parser valueはstatic candidateになります

Value OptionまたはArgumentには1個のdynamic `CompletionProvider`を設定でき、active targetのproviderだけを実行します

Providerは選択されたcanonicalとstable command path、target-local prefix、argv順の認識済みraw occurrenceを受け取ります

CompletionはValue Parser、fallback、validator、command handlerを実行しません

Rust providerは`CancellationToken`、Go providerはcallerの`context.Context`を受け取ります

長時間動くproviderはcancellationを協調的に確認する必要があります

Engineはsource順を維持し、exact prefixでfilterし、同じ挿入値では最初のcandidateを残します

空のdisplay labelとdescriptionは未指定として扱います

空value、Goの不正UTF-8、Unicode control文字はprotocol出力前にcompletion固有errorとなります

Shell統合は任意です

Rustの`nagi-cli-completion` crateとGoの`completion` packageはBash、Zsh、Fish、PowerShell向けの決定的scriptを生成します

`handle`または`Handle` helperは通常のCommand Graph dispatchより前に予約済みcompletion requestを処理し、処理したかを返します

Applicationは`Command::run_process`または`Command.RunProcess`より先にこのhelperを呼びます

生成adapterは各shellのnative completion registrationを使い、shellがtokenizeしたargumentをEngineへ渡します

Candidate textをshell sourceとしてevalしません

Bash adapterはexpansionを評価せずにcursor prefixを復元し、挿入値をshell quoteします

Zshは`PREFIX` stateとcompsysのquote処理を使用します

ZshとPowerShellはcandidate単位のappend policyを保持します

Bashは全candidateをno-spaceとして扱い、Fishはnative defaultを使用します

どちらもpublic adapter surfaceで任意のcandidate単位suffixを表現できません

## 軽量interactive prompt

PromptはCLI Core外の任意layerです

Rustの`nagi-cli-prompt` crateとGoの`prompt` packageは全画面TUIへ入らず、application policyを所有しない行指向のConfirm、Select、Input、Secretを提供します

`Prompter`は注入可能なI/O境界を通してrequestを実行します

Rustは`PromptIo`、Goは`prompt.IO`を使い、両方ともterminalの有無、prompt textのwriteとflush、visibleまたはsecret modeを指定した上限付きの完全な1行を扱います

この境界により、実terminalを変更せずtranscript、cancellation、長すぎるinput、Secret modeを決定的にtestできます

Process実装はdefaultで標準inputと標準errorを使い、command result向けに標準outputを空けます

Promptは出力前にinputとoutputのterminal接続を要求します

ApplicationはConfirm、Select、Inputに限って非terminalを明示的に許可できますが、Secretは常にterminalを要求します

Rustは`ProcessIo::default`、Goは`prompt.NewProcess`または`prompt.NewProcessIO`を使います

全requestはcallerのcancellation sourceを受け取ります

CLI handlerの`Context::cancellation`または`Context.Cancellation`を渡すと、process SIGINTをstructured Prompt cancellationとして扱えます

Response byteを読む前のEnd of input、ETXだけの行、Escapeだけの行もcancellationです

Unix process readerは常駐taskを作らず、input待機中もcancellationを確認します

ConfirmはASCIIのyes／no表現と明示的defaultを扱います

Selectは1始まりの順序付きchoiceを表示し、0始まりのindexを返します

InputとSecretは前後のspaceを保持し、ConfirmとSelectはASCII spaceとtabをtrimします

不正UTF-8 responseの各runはU+FFFDになります

既定のresponse上限は65,536 byte、Select上限は1,000 choiceで、どちらも設定できます

Secretは上限付きcanonical line readの間だけterminalの`ECHO`と`ECHONL`を解除し、成功、失敗、cancellation、長すぎるinput、stack unwindingの全経路で保存済みstate全体を復元します

返されたSecret valueは通常のstringであり、Promptはmemory zeroizationを保証しません

Credential管理、validation、authorization、approval policy、portable input ruleを超えるretryはApplicationが所有します

完全なhandler統合は[Rust Prompt example](../nagi-rs/crates/nagi-cli-prompt/examples/prompt/README.md)と[Go Prompt example](../nagicli-go/examples/prompt/README.md)を参照してください

## TTY-aware status report

Status reportもCLI Core外の任意layerです

Rustの`nagi-cli-status` crateとGoの`status` packageはApplication所有のStatus、Spinner、Progress Snapshotを標準errorへ投影し、task、timer、cancellation source、Application上の意味を所有しません

`Reporter`は同期的です

Applicationはstate変更時に`update`または`Update`を呼び、同じstreamを使う他のwriterとReporterを直列化します

安定したASCII spinner frameによりterminal fontの幅差を避け、determinate progressはtotalでclampしinteger overflowなしで完了Cellを計算します

注入可能な`StatusIo`または`status.IO`境界はterminal接続と任意の現在列数を返します

Terminalでは1本のtransient lineを消去して再描画し、同じ描画結果をcoalesceし、autowrap回避のため最終Cellを予約し、Nagi Textの設定済みModern、CJK、custom幅profileを使用します

幅を取得できない場合は80列を使用します

出力がredirectされるとterminal controlとspinner frameを出力しません

StatusとSpinnerはplain message record、Progressはclamp済み`current/total` recordになります

Tickだけが異なるSpinnerを含む同一recordはcoalesceされ、`finish`または`Finish`は最終stateをcommitしてcoalescingをresetし、`clear`または`Clear`はredirect済みoutputを消去しません

MessageはUnicode control characterを含まないvalid UTF-8で、既定上限は65,536 byteです

`log`または`Log`はactiveなtransient statusを維持しながらpermanent lineを出力します

Reporterが保持するrendering bufferには上限があり、periodic wake-upを行いません

Cancellation、更新頻度、progressの意味、Diagnosticとの調整は引き続きApplicationが所有します

完全なprocess-backed usageは[Rust Status example](../nagi-rs/crates/nagi-cli-status/examples/status/README.md)と[Go Status example](../nagicli-go/examples/status/README.md)を参照してください

## Structured Help

`Command::help_document`と`Command.HelpDocument`はrendererに依存しないHelp Documentを返します

Help Documentはcanonical command path、structured Usage Variantとrendered usage line、command、argument、option、option relationとoption-group constraint、名前付きexample、note、link、application定義のstructured sectionを保持します

標準entry、Usage Variant、option relation、option-group memberはstable IDをdisplay labelとは分離して保持します

Localな宣言は`Options`、選択されたancestorから継承したOptionは`Inherited Options`へ、外側から近いancestorの順と定義順で格納されます

`HelpInheritedOption`はcustom renderer向けに宣言元command path、stable command-ID path、option ID、label、変更前のdescriptionを保持します

既定rendererは各継承Optionのdescriptionへ宣言元command pathを付けます

`Command::usage_variant`と`Command.UsageVariant`は定義順を持つHelp-only invocation formを追加します

Syntaxには`<NODE> [OPTIONS]`のようなcommand pathを除いたsuffixを指定し、frameworkがcanonical command pathを付与します

明示variantは自動生成されるdirect-invocation usageを置き換えます

`HelpUsageVariant`はsource stable command-ID path、source-local variant ID、syntax suffix、完全なcommand lineを公開します

`Command::subcommand_usage`と`Command.SubcommandUsage`はparsingを変えずにparent Helpのpresentationを制御します

`Auto`は任意subcommand向けの汎用`<COMMAND>` formを追加し、`Hidden`は省略し、`Expanded`は各immediate childのdirect Usage Variantを定義順に展開します

展開はshallowでchildのstable command-ID pathを維持するため、child-local variant IDを再利用できます

Subcommand必須Commandで`Expanded`を選ぶとchild formだけを出力します

Usage Variantはargv parsing、typed validation、Diagnostic usage、Invocationを変更しません

これによりtyped validatorで実装した複数formを、portable graphがform選択を行うと主張せずに記述できます

既定のplain rendererは定義順を維持し、labelをterminal Cell幅で整列します

Applicationはparsingやvalidationを置き換えずにRuntime Policyから独自Help Rendererを設定できます

Rootにsubcommandがある場合は`-h`と`--help`に加えて`help [COMMAND...]`を提供します

Nested aliasを受理し、選択結果はcanonical pathで表します

## Structured Diagnostic

Diagnosticはstableなmachine-readable code、semantic category、human-readable message、canonical command path、任意usage、定義順のvalue targetとremediation hintを持ちます

Targetはstable command-ID pathとcommand-local value IDの組でoptionまたはargumentを識別します

既定rendererはinternal IDを表示しませんが、custom rendererはstructured targetを利用できます

Framework codeは仕様で定義したcategoryを維持します

Applicationはstableなapplication codeを作成し、command固有validation codeを`usage`にする場合などにcategoryを上書きできます

Rustは`DiagnosticCode::application`、Goはtyped valueの`cli.DiagnosticCode("application-code")`を使用します

明示的なcommand-ID pathを持たないvalidatorまたはhandler targetには、そのvalidatorまたはhandlerのcurrent scopeが設定されます

別のselected scopeをtargetにする場合は`with_command_id_path`または`WithCommandIDPath`を使用します

Plain rendererは任意usageの前にhintごとの`hint:`行を出力します

Custom Diagnostic Rendererは完全なstructured Diagnosticを受け取ります

## Runtime

Handlerは注入されたstdin、stdout、stderr、environment、current directory、協調的cancellationへmutable accessし、OutcomeまたはDiagnosticを返します

Handlerはprocessを直接終了してはいけません

`Command::run`と`Command.Run`は既定Runtime Policyとcallerが用意したContextで実行します

`Command::run_with_policy`と`Command.RunWithPolicy`はcallerが用意したpolicyで実行します

Process helperはplatform argv、environment、current directory、standard I/Oを使用し、SIGINTをcancellationへ変換します

- Rustの`Command::run_process`は一時的なSIGINT handlerを設定し、完了時に元へ戻す
- Goの`Command.RunProcess`は`signal.NotifyContext`を使用し、notificationを必ず停止する
- 両helperはprocessを終了せずExit Statusを返す

Diagnosticはprocess statusとは独立した`specification`、`usage`、`execution`、`cancellation`、`io`のsemantic categoryを持ちます

既定Exit Code Policyはspecificationとusageを2、executionとI/Oを1、cancellationを130へ対応付けます

ApplicationはDiagnosticの意味を変えず、例えばusageをstatus 1へ対応付けられます

Runtime PolicyはHelp RendererとDiagnostic Rendererも選択します

Plain Diagnostic Rendererはprefixとusage表示の有無を変更できます

Custom statusは1 byteへ制限され、frameworkのI/O failureはcallerへ返されます

段階導入では先にparseし、`ParseResult::command_id_path`または`ParseResult.CommandIDPath`で選択結果を確認します

`run_parsed_with_policy`と`RunParsedWithPolicy`は既存Parse ResultからHelp、version、登録済みhandlerを実行します

`run_invocation_with_policy`と`RunInvocationWithPolicy`はvalidation済みInvocationを登録済みhandlerへ橋渡しします

Canonical pathまたはstable command pathが同じCommand Graphを示さないresultは両APIとも拒否します

Parser-only統合ではRuntime Policyのpure Help rendering、Diagnostic rendering、Diagnostic-to-status helperを使用できます

これにより既存CLIがprocess dispatchとoutput routingを所有したまま、rendererとexit-code policyを共有できます

Helpとversionはstdout、Diagnosticはstderrへ出力します

User由来のC0、DEL、不正UTF-8 byteはuppercaseの`\xHH`へ変換し、terminal control injectionを防ぎます

## Application test

CLI test packageはpublic runtime APIだけで構成されます

Argv、stdin byte、environment、current directory、manual cancellationを注入し、child processやsignal handlerなしでstdout、stderr、Exit Statusを取得します

| 操作 | Rust | Go |
| --- | --- | --- |
| Driver作成 | `TestDriver::new(command)` | `clitest.New(command)` |
| Argument | `.arguments(...)` | `.Arguments(...)` |
| Standard input | `.stdin(...)` | `.Stdin(...)` |
| Environment | `.environment(...)` | `.Environment(...)` |
| Current directory | `.current_directory(...)` | `.CurrentDirectory(...)` |
| 事前cancel | `.cancelled(true)` | `.Cancelled(true)` |
| Runtime Policy | `.policy(...)` | `.Policy(...)` |
| 実行 | `.run()` | `.Run()` |

完全なentry pointは[Rust basic example](../nagi-rs/crates/nagi-cli/examples/basic.rs)、[Rust subcommand example](../nagi-rs/crates/nagi-cli/examples/subcommands.rs)、[Rust段階導入example](../nagi-rs/crates/nagi-cli/examples/staged.rs)、[Rust completion example](../nagi-rs/crates/nagi-cli-completion/examples/completion.rs)、[Rust Prompt example](../nagi-rs/crates/nagi-cli-prompt/examples/prompt.rs)、[Rust Status example](../nagi-rs/crates/nagi-cli-status/examples/status.rs)、[Go basic example](../nagicli-go/examples/basic/main.go)、[Go subcommand example](../nagicli-go/examples/subcommands/main.go)、[Go段階導入example](../nagicli-go/examples/staged/main.go)、[Go completion example](../nagicli-go/examples/completion/main.go)、[Go Prompt example](../nagicli-go/examples/prompt/main.go)、[Go Status example](../nagicli-go/examples/status/main.go)を参照してください

## 制約

Coreは設定file読み込み、interactive prompt、TUI統合を行いません

Interactive terminal I/Oは任意のPrompt packageまたはcrateに留まります

Transient status outputは任意のStatus packageまたはcrateに留まります

Status Reporter自身はcancellationを確認しません

Shell固有の生成とprotocol I/Oは任意のcompletion packageまたはcrateに留まります

長時間実行するHandlerとcompletion providerは注入されたcancellation sourceを確認して協調的に停止する必要があります

Portable graphは任意のinvocation grammarやparser-generator productionを表現しません

範囲を限定できるapplication ruleにはoption groupとtyped validatorを使用します

Help-only Usage Variantは受理するformを記述できますが、runtime variant IDは返しません

それでも不足するcommand固有parsingはportable specificationの外側へ置きます

Process統合はx86-64とARM64のLinuxおよびmacOSを対象とします

Parsingと注入実行にはterminal接続が不要です
