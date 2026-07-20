# CellTUIからNagiへの移行

[English](MIGRATION.md)

NagiはCellTUIのTUI実装を対象とする1.0未満のnamespaceとrepository移行として開始します。観測可能なTUIの意味論を維持しながらrepository、crate、module、package、fixture、diagnostic名称を変更します

Stable releaseが旧namespaceへ依存していないため互換aliasは提供しません

## Repositoryとpackageの対応

| 移行前 | Nagi |
| --- | --- |
| Rust repository `celltui-rs` | `nagi-rs` |
| Rust crate `celltui` | `nagi-tui` |
| Rust crate `celltui-text`、`celltui-vt`、`celltui-surface` | `nagi-text`、`nagi-vt`、`nagi-surface` |
| Rust crate `celltui-widgets`、`celltui-test` | `nagi-tui-widgets`、`nagi-tui-test` |
| Go module `github.com/mayahiro/celltui-go` | `github.com/mayahiro/nagi-go`と`github.com/mayahiro/nagitui-go`へ分割 |
| Go package `text`、`vt` | `github.com/mayahiro/nagi-go/text`と`/vt` |
| Go root、`surface`、`widget`、`tuitest` | `github.com/mayahiro/nagitui-go`と子package |

Go TUIのroot package名は`tui`です。共有`nagi-go` moduleにはroot packageを置きません

Nagi CLIは別製品であり、CellTUIの一部を改名したものではありません。`nagicli-go` repositoryはPhase F0では仕様骨格だけを保持します

## Canonical型の所有先

値の意味論を変えずに2個の所有境界を修正します

- `Point`、`Size`、`Rect`はNagi Surfaceが定義する
- `Color`、`Attributes`、`Style`はNagi VTが定義する
- Rustの`nagi-tui`とGoの`tui` packageはapplication向けにcanonical型を再公開する
- SurfaceにはStyle型を複製しない

Goで`surface.Style`をimportしていた場合は`github.com/mayahiro/nagi-go/vt`の`vt.Style`へ変更します。TUI rootを既にimportするapplicationは`tui.Style` facade aliasも使用できます

## Fixtureとdiagnostic namespace

| 移行前 | Nagi |
| --- | --- |
| `celltui-fixture-v1` | `nagi-fixture-v1` |
| `celltui-surface-v1` | `nagi-surface-v1` |
| `CELLTUI_FIXTURES` | `NAGI_FIXTURES` |
| Go diagnostic prefix `celltui:` | `nagi-tui:` |

Fixture payloadの意味論と期待する描画結果は変わりません

## Git履歴

Nagi repositoryはCellTUIの履歴をmergeせず独立した履歴を使用します。利用者はNagiを新しい依存として扱い、import pathを直接更新します。移行元revisionは調整repositoryの開発用ADRへ記録します

## 1.0より前のversioning

- Patch releaseはdocument済みpublic behaviorを維持しながらdefectを修正し、互換な実装詳細を追加する
- 1.0より前のminor releaseにはbreaking public APIまたはbehavior変更が含まれる場合がある
- Rust workspaceのcrateは1個の協調versionを使用する
- 3個のGo moduleは独立してversioningし、通常のmodule tagを使用する
- 対応するRustとGoのTUI releaseはtest済みNagi specificationとfixture revisionで識別する

現在のentry pointは[public API guide](API_ja.md)と[RustとGoのAPI対応表](API_MAPPING_ja.md)を参照してください
