# Terminal Presentation Rules

[English](PRESENTATION.md)

Terminal Presentation Rulesはsource-neutral Contentに対するNagiのCSS相当の層です

Immutableなsheetがexact Role、Class、application supplied Stateをterminal textとlayout valueへ対応付け、Content treeへappearance dataを追加しません

外部から観測できる完全な挙動は[Terminal Presentation仕様](../spec/presentation.md)を参照してください

## Package

| 言語 | Package |
| --- | --- |
| Rust | `nagi-tui` |
| Go | `github.com/mayahiro/nagitui-go` package `tui` |

DeclarationがVTのColorとStyle、TUIのlayout valueを使用するため、Presentationはterminal backendに属します

Source-neutralな`nagi-content` crateとGoの`content` packageはVTとTUIから独立したまま維持します

各実装repositoryから完全なvalue resolution exampleを実行できます

- [Rust Presentation example](../nagi-rs/crates/nagi-tui/examples/presentation/main.rs)
- [Go Presentation example](../nagitui-go/examples/presentation/main.go)

## Rule model

`PresentationSelector`は全element、1個のexact Content Role、1個のexact Content Classのいずれかを対象にします

Ruleはapplicationが供給するopenな`PresentationState` tokenをall-of条件として追加できます

Required Stateはuniqueな入力順をinspection用に保持しますが、matchingはall-of semanticsでありrequiredまたはactive Stateの順序に依存しません

Sheetはmatching ruleを宣言順に適用します

Selector specificity、prefix match、descendant match、runtime stylesheet parser、global mutable themeはありません

各declaration valueはUnspecified、Set、Initialのいずれかです

VT Style mergeはtransparentなCell compositionであり、inherited Boolean attributeをfalseに戻すことやterminal default colorを明示的に復元することができないため、cascadeを別modelとして扱います

Text propertyはresolutionへ渡したStyleからinheritします

Layout valueはinheritせず、Content ElementKind、Auto Length、gap 0、visual separatorなし、word wrap、start alignmentから開始します

未知のnumeric Display、Wrap、Alignment valueを表現できるbindingでは、そのconcrete declarationを無視します

Visual separatorは正規化済みUTF-8とし、明示的に設定したempty separatorとseparatorなしを区別します

## ContentとNodeとの境界

Content Roleは意味を保持し、Classはsemantic meaningを捏造せずsource appearanceを維持できるopaque hookです

SelectionやdisabledなどのStateはapplication stateとして維持し、element解決時だけ渡します

Computed resultはconcreteなVT Styleとterminal layout valueを保持します

Contentを変更せず、TUI Nodeも生成しません

ContentからNodeへのprojectionは意図的に別契約としています

Inlineとblockのnesting、eager work limit、Node ID namespace、annotation、VirtualFlow item境界を明示的に確定する必要があります

Projectionを分離している間もapplicationは通常のNodeを構築し、resolved valueを直接適用できます

## Resource挙動

Sheetは順序付きRuleを所有し、copy間でimmutable storageを共有できます

ResolutionはI/Oを行わず、globalまたはunbounded cacheを使用しません

Rustの`ComputedPresentation`はconcreteなvisual separatorを`PresentationSheet`からborrowするため、resultはSheetより長く保持できません

Goはimmutable storageを参照するstring valueを返します

どちらの実装もresolution中にseparatorをcopyしません

Untrustedなrule dataを受け取るsource adapterはsheet構築前にinputを制限する必要があります

大規模feedは引き続きVirtualFlowを使い、visible item subtreeだけを解決します

Element IDとopaque revisionだけではmetadata変更を自動追跡しないため、computed presentation cacheの正しいkeyにはなりません

Computed Hidden attributeはvisual presentationでありredactionではありません

Sensitive valueはContentへ入る前に除去します
