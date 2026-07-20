# Nagi

[English](README.md)

NagiはRustとGoにネイティブ実装を持つ端末application基盤のfamilyです

全画面の対話型TUI、command実行型CLI、両者が実際に共有するTextとVTの小さな基盤を分離します

## Repository

| Repository | 責務 | Release単位 |
| --- | --- | --- |
| [`nagi-rs`](nagi-rs/README_ja.md) | RustのText、VT、Surface、TUI、CLI、Widget、test supportの全crate | 1個のCargo workspaceで協調versioning |
| [`nagi-go`](nagi-go/README_ja.md) | Goの共有`text`と`vt` package | `github.com/mayahiro/nagi-go` |
| [`nagitui-go`](nagitui-go/README_ja.md) | GoのSurface、TUI runtime、Widget、TUI Test | `github.com/mayahiro/nagitui-go` |
| [`nagicli-go`](nagicli-go/README_ja.md) | GoのCommand Graph、parser、runtime、CLI Test | `github.com/mayahiro/nagicli-go` |

このrepositoryは4個の実装repositoryをsubmoduleとして調整し、言語非依存の仕様とconformance fixtureを所有します

## 依存境界

Nagi TextとNagi VTを共有基盤とします。Nagi Surfaceは両方へ依存し、Nagi TUIはText、VT、Surfaceへ依存します。Nagi CLIはTextとVTへ依存できますが、SurfaceやTUIへ依存しません

Geometry型の`Point`、`Size`、`Rect`はNagi Surfaceが所有します。Terminalの`Color`、`Attributes`、`Style`はNagi VTが所有します。Applicationから使いやすくするため、TUI facade packageはcanonical型を再公開できます

Go moduleはTUIとCLIを別々にversioningして導入できるよう分割します。RustはCargo crateを個別に依存指定できるため1個のworkspaceを使用します

## 現在の状態

既存のNagi TUI実装はRustとGoのnative runtime、Unicode対応Text、typed VT codec、Cell Surface、決定的test harness、21個の標準Widgetを提供します

Nagi CLIはRustとGoのnative Command Graph、typed value parsing、決定的HelpとDiagnostic、注入可能runtime、協調的SIGINT cancellation、processなしのtest driver、対応するbasicとsubcommand exampleを提供します

これらの追加を予定する`v0.2.0` releaseとします

## 仕様とguide

- [Nagi semantic specification](spec/README.md)と[CLI command仕様](spec/cli.md)
- [Public TUI API guide](docs/API_ja.md)
- [Public CLI API guide](docs/CLI_API_ja.md)
- [RustとGoのAPI対応表](docs/API_MAPPING_ja.md)
- [互換性とmigration guide](docs/MIGRATION_ja.md)

Fixture headerは`nagi-fixture-v1`、Surface snapshotは`nagi-surface-v1`を使用し、実装は`NAGI_FIXTURES`から共有fixtureを探索します

## 開発用checkout

実装repositoryを初期化して全体確認を実行します

```sh
git submodule update --init --recursive
make check
```

Rootの`go.work`はこの開発checkout内だけで3個のGo moduleを接続します。公開module manifestにはlocal `replace`を置きません

## 対応環境

Terminal applicationはLinuxとmacOSのx86-64およびARM64を対象とします。Windowsには現在対応していません

## License

Nagiのsource codeはMIT Licenseで提供します。生成済みUnicode dataと取り込み済みconformance caseは[Unicode License v3](UNICODE-LICENSE)で配布します
