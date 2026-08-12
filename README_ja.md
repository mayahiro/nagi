# Nagi

[English](README.md)

NagiはRustとGoにネイティブ実装を持つ端末application基盤のfamilyです

全画面の対話型TUI、command実行型CLI、独立して再利用できるContent、Text、VTの基盤を分離します

## Repository

| Repository | 責務 | Release単位 |
| --- | --- | --- |
| [`nagi-rs`](nagi-rs/README_ja.md) | RustのContent、Text、VT、Surface、TUI、CLI、Widget、test supportの全crate | 1個のCargo workspaceで協調versioning |
| [`nagi-go`](nagi-go/README_ja.md) | Goの共有`content`、`text`、`vt` package | `github.com/mayahiro/nagi-go` |
| [`nagitui-go`](nagitui-go/README_ja.md) | GoのSurface、TUI runtime、Widget、TUI Test | `github.com/mayahiro/nagitui-go` |
| [`nagicli-go`](nagicli-go/README_ja.md) | GoのCommand Graph、parser、runtime、CLI Test | `github.com/mayahiro/nagicli-go` |

このrepositoryは4個の実装repositoryをsubmoduleとして調整し、言語非依存の仕様とconformance fixtureを所有します

## 依存境界

Nagi ContentはNagi Textだけへ依存します。Nagi SurfaceはTextとVTへ依存し、Nagi TUIはContent、Text、VT、Surfaceへ依存します。Nagi CLIはContent、Text、VTへ依存できますが、SurfaceやTUIへ依存しません

Geometry型の`Point`、`Size`、`Rect`はNagi Surfaceが所有します。Terminalの`Color`、`Attributes`、`Style`はNagi VTが所有します。Applicationから使いやすくするため、TUI facade packageはcanonical型を再公開できます

Go moduleはTUIとCLIを別々にversioningして導入できるよう分割します。RustはCargo crateを個別に依存指定できるため1個のworkspaceを使用します

## 現在の状態

共有RustとGo基盤はimmutableなsource-neutral Content、Unicode対応Text、typed VT codecを提供します。既存のNagi TUI実装はimmutableなTerminal Presentation Rules、上限付きContentからNodeへのprojection、native runtime、Cell Surface、決定的test harness、27個の標準Widget、大規模content向けvirtual ScrollViewportとstableな可変高VirtualFeedを追加します

Nagi CLIはRustとGoのnative Command Graph、localと継承Option、command-local typed value scope、portable option groupとvalidator、制御可能なHelp-only Usage Variantを持つstructured deterministic Help、target付きsemantic Diagnostic、段階実行runtime policy、協調的SIGINT cancellation、processなしのtest driver、対応するexampleを提供します

## 利用例と契約

- [実行可能なRust example](nagi-rs/README_ja.md#example)
- [実行可能なRustとGoのContent example](docs/CONTENT_ja.md#projectionとvalidation)
- [実行可能なRustとGoのPresentation example](docs/PRESENTATION_ja.md#package)
- [実行可能なGo TextとVTのexample](nagi-go/README_ja.md#example)
- [実行可能なGo TUI example](nagitui-go/README_ja.md#example)
- [実行可能なGo CLI example](nagicli-go/README_ja.md#example)
- [Nagi semantic specification](spec/README.md)と[CLI command仕様](spec/cli.md)
- [Source-neutral Content guide](docs/CONTENT_ja.md)
- [Terminal Presentation guide](docs/PRESENTATION_ja.md)
- [ContentからNodeへのprojection仕様](spec/content-node-projection.md)
- [Public TUI API guide](docs/API_ja.md)
- [Event-driven TUI application architecture](docs/EVENT_DRIVEN_APPLICATIONS_ja.md)
- [Public CLI API guide](docs/CLI_API_ja.md)
- [RustとGoのAPI対応表](docs/API_MAPPING_ja.md)
- [再現可能なperformance baseline](BENCHMARKS.md)

## 対応環境

Terminal applicationはLinuxとmacOSのx86-64およびARM64を対象とします。Windowsには現在対応していません

## License

Nagiのsource codeはMIT Licenseで提供します。生成済みUnicode dataと取り込み済みconformance caseは[Unicode License v3](UNICODE-LICENSE)で配布します
