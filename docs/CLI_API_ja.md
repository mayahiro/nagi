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
| MarkdownとmanのHelp rendering | `nagi-cli-document` | `github.com/mayahiro/nagicli-go/document` |
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
| HiddenなCommandまたはOption | `.hidden()` | `.Hidden()` |
| DeprecatedなCommandまたはOption | `.deprecated(replacement)` | `.Deprecated(replacement)` |
| Positional | `Argument::new("id")` | `cli.Positional("id")` |
| Sensitiveなvalue optionまたはpositional | `.sensitive()` | `.Sensitive()` |
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

## CommandとOptionのlifecycle

CommandとOptionのbuilderは互いに独立したHiddenとDeprecated metadataを公開します

このmetadataはcommand applicationへ汎用的なものであり、Agent、authorization、credential、migration policyの概念を追加しません

Hiddenは正確なsyntaxをparse可能なままgenerated projectionから宣言を省略します

Parent Help、generated Usage Variant、localと継承Option entry、completion candidate、将来のgraph派生documentはHiddenな宣言を省略します

SourceまたはtargetがHiddenなrelationと、Hiddenなmemberを含むoption groupもHelpから省略します

HiddenなValue Optionのfinite candidateは返さず、completed inputがそのOptionを明示していてもdynamic completion providerを実行しません

既知のHidden Commandへのdirect Helpは利用できます

Hidden childしかないrootは汎用`<COMMAND>` Usage formとgenerated `help` candidateを公開しません

Hiddenはsecurityまたはredaction境界ではありません

既知のHidden syntaxはparseできるため、access controlとsensitive value処理はApplicationが別に強制します

DeprecatedはUnicode control文字を含まない空でないvalid UTF-8のreplacement hintを受け取ります

Parsingとhandler実行は継続します

Structured Helpとstatic completion candidateは`Deprecation` valueを公開し、plain Help rendererはreplacement hintを追加し、任意のshell protocol adapterは挿入値を変えずcandidate descriptionを装飾します

Goの`HelpEntry`と`HelpInheritedOption`が持つlifecycle metadataはopaqueであり、`HelpDocument`だけが設定します

直接のkeyed literalで表現できるのはsyntheticなnon-deprecated entryだけです

Private metadata fieldが追加されたため、以前のfield listに対するexternal unkeyed composite literalはsource compatibleではありません

成功した各Invocationは決定的な初回使用順のstructured `DeprecationNotice`を公開します

Deprecatedなrootが最初になり、後続のCommandとOption targetはargvで最初に成功したoccurrenceの順になります

Stable targetは重複を除き、最初のalias、long spelling、short spellingを維持します

Environment、external、default fallbackはOption noticeを生成しません

Help、version、失敗したparseまたはvalidationはDiagnosticを通してnoticeを返しません

既定のRuntime Policyはnoticeを出力しません

`PlainDeprecationNoticeRenderer`を`RuntimePolicy::with_deprecation_notice_renderer`または`RuntimePolicy.WithDeprecationNoticeRenderer`から設定すると、handler実行前にstandard errorへ出力します

出力に失敗するとerrorを返し、handlerを開始しません

Output routingを所有するApplicationは`Invocation::deprecation_notices`または`Invocation.DeprecationNotices`を直接参照できます

[Rust lifecycle example](../nagi-rs/crates/nagi-cli/examples/lifecycle/README.md)と[Go lifecycle example](../nagicli-go/examples/lifecycle/README.md)を参照してください

## Sensitive Value metadata

Value Optionまたはpositional Argumentには汎用のSensitive metadataを設定できます

このmetadataはframework presentationだけを制御し、credential typeの識別やauthorization policyを追加しません

FlagまたはCountへの設定は不正なvalue-only configurationとしてgraph validationが拒否します

Generated Helpはlabel、description、required state、environment変数名を維持し、設定済みdefaultまたはfinite value setを公開`<redacted>` markerへ置換します

Frameworkが生成するparser failureはraw値とparser reasonの両方を省略します

Structured Help entry、parsed value、Diagnostic target、Completion targetはdisplay textの検査を不要にするquery可能なmetadataを公開します

Stable JSON Diagnostic schema `nagi.cli.diagnostic.v1`はraw value fieldを持たないため変更しません

Parser targetとInvocation validatorまたはHandlerが返す一致targetは宣言のmarkerを継承します

解決にはtarget kind、stable command-ID path、local value IDを使用し、未知または不一致のtargetはnon-Sensitiveのままです

CompletionはSensitive targetのfinite-value candidateを返さず、そのtargetのdynamic providerを保持も実行もしません

別targetのproviderが必要とする場合、完了済みSensitive occurrenceは明示的なraw `CompletionRequest` accessから引き続き参照でき、occurrenceとtargetのSensitive markerも維持されます

Raw `CompletionInput`はCommand Graphによる解釈前なので、format時は全tokenをopaqueとして扱います

明示的なInvocation raw／typed accessは元の値とsourceを返します

Sensitive metadataはmemory zeroization、OS argvやshell historyからの隠蔽、transport保護、明示的に値を読んだApplication codeのlogging防止を行いません

Applicationが作るDiagnostic text、Help text、parser object、runtime outputはopaqueなため、Application自身がこれらの文字列をredactする必要があります

Goは値を保持するCLIとcompletion typeにsafe formattingを定義し、再帰的なdefault struct formattingへ依存しなくなりました

未文書のformat textを比較していたcodeはsource-levelでは影響を受けませんが、v1前の観測出力は変わります

Goでframeworkが生成するnon-SensitiveなInvalid Value messageは、Rustと共有fixtureに合わせてstable value IDをsingle quoteで囲むようになりました

Consumerはhuman-readable messageではなくDiagnostic codeで分岐する必要があります

[Rust Sensitive Value example](../nagi-rs/crates/nagi-cli/examples/sensitive_values/README.md)と[Go Sensitive Value example](../nagicli-go/examples/sensitive-values/README.md)を参照してください

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

各parsed valueはcommand line、environment、external resolver、defaultのどこから得たかを記録し、同じ順序で優先されます

`Invocation::contains`と`Invocation.Contains`はresolved presence、`Invocation::supplied`と`Invocation.Supplied`はnearest visible declarationがargvから指定されたかを返します

Exact scopeにもancestor lookupを行わない同じ操作があります

Rustはoptionalなtyped valueを`Invocation::value`と`Invocation::values`で取得します

Goは最初のvalueに`cli.ValueAs[T]`を使い、repeated valueの走査では`ParsedValue.Typed()`を使用します

Schema上必要なvalueのmappingには、Rustの`Invocation::require_value`またはGoの`cli.RequireValueAs[T]`をInvocationかInvocation Scopeと組み合わせて使用します

`ValueAccessError`はmissing valueとparser-result type mismatchを区別し、stable lookup scopeとlocal value IDを保持します

どのaccessorもdynamic typeをcoerceしません

## Value Source adapter

Value ResolverはApplicationが既に読み込んだ設定をraw Value Option fallbackへ対応付けます

Nagiはcommand line、environment、external resolver、設定済みdefaultの固定優先順位を保ちます

Command-lineまたはenvironment valueがある宣言ではResolverを呼ばず、unresolved resultではdefaultを使用できます

Callbackはselected command path上の未解決Value Optionだけに対して同期的にrootからleaf、各宣言順で実行します

Flag、Count、positional、未選択Command、Help、version、completion、派生document処理では実行しません

Requestはselected pathと宣言path、それぞれのstable ID path、local value ID、repeatability、Sensitive metadataを保持します

上位sourceのraw value、設定済みdefault、Value Parserは公開しません

| 操作 | Rust | Go |
| --- | --- | --- |
| Resolver callback | `ValueResolver` | `cli.ValueResolver` |
| Parserへの注入 | `Command::parse_with_value_resolver` | `Command.ParseWithValueResolver` |
| Unresolved result | `ValueResolution::unresolved()` | zero `cli.ValueResolution` |
| Defaultの置換 | `ValueResolution::replace(...)` | `cli.ReplaceValueResolution(...)` |
| Defaultとのmerge | `ValueResolution::merge(...)` | `cli.MergeValueResolution(...)` |
| Parsed origin | `ParsedValue::origin` | `ParsedValue.Origin` |
| Runtimeへの注入 | `Context::with_value_resolver` | `Context.WithValueResolver` |
| Process統合 | `Command::run_process_with_value_resolver` | `Command.RunProcessWithValueResolver` |
| Test driverへの注入 | `TestDriver::value_resolver` | `clitest.Driver.ValueResolver` |

Replaceは設定済みdefaultを抑止します

Mergeはrepeated Value Optionだけで有効で、external valueの後に設定済みdefaultがあれば追加します

Non-repeated宣言はReplaceによる1 valueだけを受理します

Resolved source identityはstable ASCII identifier grammarを使用し、credentialではなく`project-config`のような非secret source名にします

External raw valueも宣言のValue Parserを通ります

Parser failureのstructured Diagnostic targetはExternal originを保持しますが、既定plain rendererとJSON rendererはorigin metadataを出力しません

Custom rendererはstable JSON schemaを変えずにoriginを参照できます

Value Resolutionの既定DebugとGo formattingはsource identityと全raw valueを省略します

Application codeが意図して読む場合だけ明示的なvalue accessorを使用します

Resolverは設定fileまたはnetwork I/Oを開始する場所ではなく、Application stateを投影するadapterとして使用します

Nagiは設定schema、file探索、credential、interpolation、retry、persistenceを所有しません

[Rust Value Source Adapter example](../nagi-rs/crates/nagi-cli/examples/value_sources/README.md)と[Go Value Source Adapter example](../nagicli-go/examples/value-sources/README.md)を参照してください

## Response File

Response File展開は通常のcommand parsingより前に置くopt-inのlexical layerです

展開を設定しない既存parserとRuntime entry pointは先頭の`@`をliteralのまま保持します

Standaloneの`expand_response_files`と`cli.ExpandResponseFiles`は注入したreaderとstandard inputを受け取ります

`Context`には決定的testまたはembedded実行向けの同じ境界を設定でき、`ProcessOptions`は完全なprocess統合でfilesystem-backed readerを選択します

| 操作 | Rust | Go |
| --- | --- | --- |
| Standalone展開 | `expand_response_files` | `cli.ExpandResponseFiles` |
| 展開option | `ResponseFileOptions` | `cli.ResponseFileOptions` |
| Resource上限 | `ResponseFileLimits` | `cli.ResponseFileLimits` |
| 注入reader | `ResponseFileReader` | `cli.ResponseFileReader` |
| Filesystem reader | `FilesystemResponseFileReader` | `cli.FilesystemResponseFileReader` |
| Runtime注入 | `Context::with_response_files` | `Context.WithResponseFiles` |
| Process構成 | `ProcessOptions::with_response_files` | `ProcessOptions.WithResponseFiles` |
| 完全なprocess entry | `Command::run_process_with_options` | `Command.RunProcessWithOptions` |
| Test driver注入 | `TestDriver::response_files` | `clitest.Driver.ResponseFiles` |

有効な`@path` tokenは`--`より後でもfileを再帰的にincludeします

`@@name`はliteralな`@name` argumentを生成し、単独の`@`はliteralのままです

完全一致する`@-`は個別に有効化した場合だけstandard inputを読み、1回だけ消費できます

Top-levelのrelative pathは注入したcurrent directory、nested pathはinclude元fileのdirectoryを基準にし、standard input内のnested pathは元のcurrent directoryを維持します

SourceはUTF-8でなければならず、先頭に1個のbyte-order markを置けますが、NULは含められません

ASCII whitespaceがtokenを分割し、`#`はtoken境界だけでcommentを開始します

Single quoteとdouble quoteは内容を保持し、隣接するquoted fragmentとunquoted fragmentは連結し、single quote外のbackslashは次のUnicode scalarをliteralとしてescapeします

Shell、variable、command、glob、tilde、environment、C-style escapeの展開は行いません

既定上限はdepth 16、source 64個、source byte合計8 MiB、調査token 65,536個、token byte合計8 MiBです

全上限をcallerが変更でき、zeroも実際の上限として扱います

Activeなlexical include cycleは拒否し、source内容を含まないstructured Response File targetを返します

Runtimeはfileを読む前にCommand Graphを検証します

展開後のargumentは通常のCommand Line originを持ち、同じparser、validator、Sensitive Value処理を通ります

`ProcessOptions`はResponse File、Value Resolver、Runtime Policyを順序依存のhelper variant追加なしで合成します

[Rust Response File example](../nagi-rs/crates/nagi-cli/examples/response_files/README.md)と[Go Response File example](../nagicli-go/examples/response-files/README.md)を参照してください

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

Sensitive targetはvalue candidateを返さず、そのproviderを実行しません

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

`Command::visit_help_documents`と`Command.VisitHelpDocuments`はgraphを一度だけ検証し、root、visible descendantの定義順preorderで同期的に訪問します

Hidden commandのsubtreeは省略され、callbackがfalseを返すと成功として停止します

Visitorは一度に一つのdocumentだけを受け取るため、Applicationは全pageをmemoryへ保持せず大規模なdocumentation setを書き出せます

CallbackからCommand Graphを変更しないでください

Rootにsubcommandがある場合は`-h`と`--help`に加えて`help [COMMAND...]`を提供します

Nested aliasを受理し、選択結果はcanonical pathで表します

## Help派生document

任意のRust `nagi-cli-document` crateとGo `document` packageは`MarkdownRenderer`と`ManRenderer`を提供します

どちらも既存Help Renderer interfaceを実装し、直接の`render`または`Render` methodも公開します

一つのHelp Documentに対するpure adapterであり、filesystem I/Oを行いません

Filename、directory、page separator、output routingはApplicationが所有します

Markdown outputはCommonMark 0.31.2を対象とし、Usageとexample invocationをindent code blockで出力します

Application stringはplain textとしてescapeし、安全でないlink destination文字をpercent encodeします

Man outputは決定的なsection 1の`.TH`と、慣例的な`NAME`、`SYNOPSIS`、`.SH`、`.TP`、`.PP`、`.nf`、`.fi`構造を使用します

Application text内のroff request開始文字、reverse solidus、hyphenはescapeされます

どちらも現在日時を含めず、handler、validator、Completion Provider、shell completion生成を実行しません

両rendererは改行とcontrolを正規化し、valid UTF-8と最後のLFを一つ生成します

Hidden declaration、Deprecated hint、継承元、Sensitive redactionはterminal Helpと同じstructured Help Documentから得ます

[Rust Help派生document example](../nagi-rs/crates/nagi-cli-document/examples/documentation/README.md)と[Go Help派生document example](../nagicli-go/examples/documentation/README.md)を参照してください

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

`JsonDiagnosticRenderer`とGoの`JSONDiagnosticRenderer`はCI、GUI、process統合向けにstableなcompact newline-delimited JSONを出力します

各recordはschema `nagi.cli.diagnostic.v1`と、固定された`code`、`category`、`message`、`command_path`、nullableな`usage`、順序付き`targets`、順序付き`hints` memberを持ちます

Rendererはprocess status、timestamp、severity、Application metadataを追加しません

RFC 8259のstring escapeに従い、byte-order markなしのUTF-8と最後のnewlineを出力します

Goの`Diagnostic.UsageValue`はusageなしと明示的な空文字列を区別します

既存の`Usage` accessorも維持します

PureなRuntime Policy renderingは[Rust JSON Diagnostic example](../nagi-rs/crates/nagi-cli/examples/json_diagnostic/README.md)と[Go JSON Diagnostic example](../nagicli-go/examples/json-diagnostic/README.md)を参照してください

## Runtime

Handlerは注入されたstdin、stdout、stderr、environment、current directory、協調的cancellationへmutable accessし、OutcomeまたはDiagnosticを返します

Handlerはprocessを直接終了してはいけません

`Command::run`と`Command.Run`は既定Runtime Policyとcallerが用意したContextで実行します

`Command::run_with_policy`と`Command.RunWithPolicy`はcallerが用意したpolicyで実行します

Process helperはplatform argv、environment、current directory、standard I/Oを使用し、SIGINTをcancellationへ変換します

- Rustの`Command::run_process`は一時的なSIGINT handlerを設定し、完了時に元へ戻す
- Goの`Command.RunProcess`は`signal.NotifyContext`を使用し、notificationを必ず停止する
- 両helperはprocessを終了せずExit Statusを返す

`run_process_with_value_resolver`と`RunProcessWithValueResolver`は同じprocess境界を維持しながらValue Resolverを設定します

PolicyとResolverの両方を変更するvariantも利用できます

`ProcessOptions`と`cli.ProcessOptions`はRuntime Policy、Value Resolver、Response Fileを同時に選択する場合のcomposableなentry pointです

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
| Value Resolver | `.value_resolver(...)` | `.ValueResolver(...)` |
| Response File | `.response_files(options, reader)` | `.ResponseFiles(options, reader)` |
| 実行 | `.run()` | `.Run()` |

完全なentry pointは[Rust basic example](../nagi-rs/crates/nagi-cli/examples/basic.rs)、[Rust subcommand example](../nagi-rs/crates/nagi-cli/examples/subcommands.rs)、[Rust段階導入example](../nagi-rs/crates/nagi-cli/examples/staged.rs)、[Rust JSON Diagnostic example](../nagi-rs/crates/nagi-cli/examples/json_diagnostic.rs)、[Rust lifecycle example](../nagi-rs/crates/nagi-cli/examples/lifecycle.rs)、[Rust Sensitive Value example](../nagi-rs/crates/nagi-cli/examples/sensitive_values.rs)、[Rust Value Source Adapter example](../nagi-rs/crates/nagi-cli/examples/value_sources.rs)、[Rust Response File example](../nagi-rs/crates/nagi-cli/examples/response_files.rs)、[Rust completion example](../nagi-rs/crates/nagi-cli-completion/examples/completion.rs)、[Rust Prompt example](../nagi-rs/crates/nagi-cli-prompt/examples/prompt.rs)、[Rust Status example](../nagi-rs/crates/nagi-cli-status/examples/status.rs)、[Go basic example](../nagicli-go/examples/basic/main.go)、[Go subcommand example](../nagicli-go/examples/subcommands/main.go)、[Go段階導入example](../nagicli-go/examples/staged/main.go)、[Go JSON Diagnostic example](../nagicli-go/examples/json-diagnostic/main.go)、[Go lifecycle example](../nagicli-go/examples/lifecycle/main.go)、[Go Sensitive Value example](../nagicli-go/examples/sensitive-values/main.go)、[Go Value Source Adapter example](../nagicli-go/examples/value-sources/main.go)、[Go Response File example](../nagicli-go/examples/response-files/main.go)、[Go completion example](../nagicli-go/examples/completion/main.go)、[Go Prompt example](../nagicli-go/examples/prompt/main.go)、[Go Status example](../nagicli-go/examples/status/main.go)を参照してください

## 制約

Coreは既読設定をValue Resolverで接続できますが、設定file読み込み、interactive prompt、TUI統合を行いません

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
