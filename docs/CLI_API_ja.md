# Public CLI API guide

[English](CLI_API.md)

Nagi CLIは外部から観測できるcommand semanticsを揃えたnative Rust APIとGo APIを提供します

両実装はCommand Graphを検証し、platform argument valueをtyped Invocationへparseし、structured HelpとDiagnosticを構築し、注入されたContextを通じてHandlerを実行し、設定可能なRuntime Policyから明示的なExit Statusを返します

言語非依存の[command application specification](../spec/cli.md)をpublic behaviorの契約とします

`fixtures/cli`配下の共有fixtureでparsing、Diagnostic、Help、runtime output、cancellation、byte保持を確認します

## Package

| 責務 | Rust | Go |
| --- | --- | --- |
| Command Graph、parser、runtime | `nagi-cli` | `github.com/mayahiro/nagicli-go`の`cli` package |
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
| Positional | `Argument::new("id")` | `cli.Positional("id")` |
| Option group | `OptionGroup::exactly_one(...)` | `cli.ExactlyOne(...)` |
| Child command | `.subcommand(command)` | `.Subcommand(command)` |
| Typed validator | `.validator(validator)` | `.Validator(validator)` |
| Help Usage Variant | `.usage_variant(id, syntax)` | `.UsageVariant(id, syntax)` |
| Help example | `.example(name, invocation)` | `.Example(name, invocation)` |
| Help note | `.note(text)` | `.Note(text)` |
| Help link | `.link(label, url)` | `.Link(label, url)` |
| Custom Help section | `HelpSection::new(...)` | `cli.NewHelpSection(...)` |
| Handler | `.handler(handler)` | `.Handle(handler)` |

Longとshortの名前を明示します

Value optionにはrequired、repeated、environment fallback、default、`requires`、`conflicts`を設定できます

Relationはresolved presenceまたはcommand-line presenceを参照できます

Portable option groupは同一Command上のoptionに対する`at-most-one`、`exactly-one`、`at-least-one`、`all-or-none` cardinalityを表します

Groupはdefault付きoptionを明示指定と誤認しないようcommand-line presenceを既定で使用します

Application固有のtyped validatorはparse、fallback解決、portable validationの後に実行されます

Argvを読む前にgraph全体を検証します

不正な名前、予約済みbuilt-in spelling、active path上のvalue ID衝突、sibling alias衝突、不正なpositional順序、不正なgroup、Commandをまたぐoption relationは`invalid-specification` Diagnosticになります

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

Invocationはcanonical command pathと、そのpath上の全Commandから得たvalueを保持します

各parsed valueはcommand line、environment、defaultのどこから得たかを記録し、command-line valueが両fallbackより優先されます

`Invocation::contains`と`Invocation.Contains`はresolved presence、`Invocation::supplied`と`Invocation.Supplied`はargvからIDが指定されたかを返します

Rustは`Invocation::value`と`Invocation::values`でtyped valueを取得します

Goは最初のvalueに`cli.ValueAs[T]`を使い、repeated valueの走査では`ParsedValue.Typed()`を使用します

存在しないIDやtypeが異なるIDはcoerceせずabsenceを返します

## Structured Help

`Command::help_document`と`Command.HelpDocument`はrendererに依存しないHelp Documentを返します

Help Documentはcanonical command path、structured Usage Variantとrendered usage line、command、argument、option、option relationとoption-group constraint、名前付きexample、note、link、application定義のstructured sectionを保持します

標準entry、Usage Variant、option relation、option-group memberはstable IDをdisplay labelとは分離して保持します

`Command::usage_variant`と`Command.UsageVariant`は定義順を持つHelp-only invocation formを追加します

Syntaxには`<NODE> [OPTIONS]`のようなcommand pathを除いたsuffixを指定し、frameworkがcanonical command pathを付与します

明示variantは自動生成されるdirect-invocation usageを置き換え、Command Graphから得られる任意subcommand向けusageは引き続き自動生成されます

`HelpUsageVariant`はstable ID、syntax suffix、完全なcommand lineを公開します

Usage Variantはargv parsing、typed validation、Diagnostic usage、Invocationを変更しません

これによりtyped validatorで実装した複数formを、portable graphがform選択を行うと主張せずに記述できます

既定のplain rendererは定義順を維持し、labelをterminal Cell幅で整列します

Applicationはparsingやvalidationを置き換えずにRuntime Policyから独自Help Rendererを設定できます

Rootにsubcommandがある場合は`-h`と`--help`に加えて`help [COMMAND...]`を提供します

Nested aliasを受理し、選択結果はcanonical pathで表します

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

完全なentry pointは[Rust basic example](../nagi-rs/crates/nagi-cli/examples/basic.rs)、[Rust subcommand example](../nagi-rs/crates/nagi-cli/examples/subcommands.rs)、[Go basic example](../nagicli-go/examples/basic/main.go)、[Go subcommand example](../nagicli-go/examples/subcommands/main.go)を参照してください

## 制約

Coreは設定file読み込み、shell completion生成、interactive prompt、TUI統合を行いません

長時間実行するHandlerは注入されたcancellation sourceを確認して協調的に停止する必要があります

Portable graphは任意のinvocation grammarやparser-generator productionを表現しません

範囲を限定できるapplication ruleにはoption groupとtyped validatorを使用します

Help-only Usage Variantは受理するformを記述できますが、runtime variant IDは返しません

それでも不足するcommand固有parsingはportable specificationの外側へ置きます

Process統合はx86-64とARM64のLinuxおよびmacOSを対象とします

Parsingと注入実行にはterminal接続が不要です
