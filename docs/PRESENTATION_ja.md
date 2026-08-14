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

各実装repositoryから完全なvalue resolutionとprojection exampleを実行できます

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

ContentからNodeへのprojectionは独立したoperationとし、外部から観測できる挙動を[専用仕様](../spec/content-node-projection.md)で定義します

Rule resolutionをpureに保つため、applicationは標準projectionを使わずcomputed valueを検査し、custom Nodeを構築することもできます

## ContentからNodeへのprojection

Rustの`project_content`とGoの`ProjectContent`は訪問する各Elementをresolveし、通常のParagraph、Column、Row、Gap Nodeを生成します

State対応variantは同期callbackを1個受け取り、返されたStateを現在のElementだけへ適用します

ParagraphとInline displayはinline formatting contextを作ります

このcontext内のblock displayはstructuredな`invalid-layout-tree` errorになります

FlowはColumn、SequenceはRowへ対応し、inline rootまたはblock container直下のinline childはchildごとに匿名Paragraphへ昇格します

ProjectionはElement IDをNode IDへ、annotationをactionへ変換しません

Namespace付きNode identity、handler、SelectableText、application policyは返されたNodeの外側で追加します

各projectionは訪問Content node数、生成Node数、styled span数、tree depth、emitted UTF-8 byte数を制限します

既定limitはeagerなvisible subtree向けであり`ContentProjectionLimits`から調整できます

Node layoutとrenderが再帰的であるためdepthは256を上限とします

## Resource挙動

Sheetは順序付きRuleを所有し、copy間でimmutable storageを共有できます

ResolutionはI/Oを行わず、globalまたはunbounded cacheを使用しません

Rustの`ComputedPresentation`はconcreteなvisual separatorを`PresentationSheet`からborrowするため、resultはSheetより長く保持できません

Goはimmutable storageを参照するstring valueを返します

どちらの実装もresolution中にseparatorをcopyしません

Untrustedなrule dataを受け取るsource adapterはsheet構築前にinputを制限する必要があります

大規模feedは引き続きVirtualFlowを使い、visible item builderが要求したitem subtreeだけをprojectionします

ProjectionはVirtualFlowを生成せずNode cacheを保持しません

Element IDとopaque revisionだけではmetadata変更を自動追跡しないため、computed presentation cacheの正しいkeyにはなりません

Computed Hidden attributeはvisual presentationでありredactionではありません

Sensitive valueはContentへ入る前に除去します
