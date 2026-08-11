# Source-neutral Content

[English](CONTENT.md)

Nagi Contentはsource adapterとrendererが共有するsource-neutralな構造です

HTMLに相当する境界としてimmutableなtextとelementへsemantics、stable identity、annotationを保持し、terminal presentationは別の責務として維持します

外部から観測できる完全な契約は[source-neutral Content仕様](../spec/content.md)を参照してください

## Package

| 言語 | Package |
| --- | --- |
| Rust | `nagi-content` |
| Go | `github.com/mayahiro/nagi-go/content` |

Rust crateは`nagi-text`だけへ依存し、Go packageは同じmoduleの`text` packageだけへ依存します

どちらの実装もVT、TUI、CLI domain type、source parser、application runtimeへ依存しません

## Model

`Content` valueはimmutableなText、HardBreak、Elementのいずれかです

Elementは4個の小さなmechanical kindを使用します

- Inlineはsemantic textを追加せずinline childを結合する
- Flowはblock child間へline boundaryを置く
- Paragraphはsemantic textを追加せずinline childをgroup化する
- Sequenceは順序付きfieldまたはcell間へtab boundaryを置く

Elementはsemantic child boundaryを上書きできます

このboundaryはcopy対象またはaccessibility向けのtextを制御し、visual spacingは制御しません

そのためrendererはsemantic outputを変えずに別のvisual separatorを選択できます

Roleは`heading`や`diagnostic.code`のような意味を記録します

Classは`source.ansi.sgr-33-1`のようなopaqueなpresentation hookであり、source由来のappearanceへ存在しないsemantic meaningを追加しません

Annotation IDはopaqueなapplication参照です

Nagi Contentがlinkを開く、commandを実行する、callbackを保持することはありません

Stable element IDとopaque revisionにより、adapterは変更されたrootまたはsubtreeを置き換えてもidentityを維持できます

RustのContent cloneとGoのContent copyはimmutableなbacking storageを共有します

Goのslice accessorはdefensive copyを返します

`HasRole`、`HasClass`、`ChildCount`、`Child`はimmutableなownershipを維持しながらrendererへallocation-freeなmembershipとindex readを提供します

## Projectionとvalidation

Rustの`semantic_text`とGoの`ProjectSemanticText`はtreeを左から右へtraverseし、正規化済みUTF-8とannotated elementのhalf-open byte rangeを返します

Nested rangeの順序はelement preorderに従います

Rustの`validate`とGoの`Validate`はdepth、node数、semantic byte数、metadata byte数、elementごとのtoken数へcaller指定のlimitを適用します

Duplicate stable element IDも拒否し、決定的なresource statisticsを返します

Constructorはwhole-treeへhidden limitを適用しません

各実装repositoryから完全なexampleを実行できます

- [Rust Content example](../nagi-rs/crates/nagi-content/examples/content/main.rs)
- [Go Content example](../nagi-go/examples/content/main.go)

## Presentationとの境界

Contentは構造と意味を保持しますが、terminal Color、Style、Length、focus target、event handler、viewport stateを保持しません

Terminal presentation層はroleとclassをbackend固有のlayoutとcomputed styleへ解決し、その結果を通常のTUI Nodeへprojectできます

現在のNagiでは[Terminal Presentation Rules](PRESENTATION_ja.md)がこの境界の決定的なrule resolutionを定義します

ContentからNodeへのprojectionは別契約として維持します

Markdown、ANSI、Help、Diagnostic、JSON、Diff、application domain modelはsource adapterまたはrendererとして維持します

Content Coreへ取り込まずにContentを生成でき、parse、redaction、activation、trust policyはadapterまたはapplicationが所有します
