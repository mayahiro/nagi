# Migrating from CellTUI to Nagi

[日本語](MIGRATION_ja.md)

Nagi begins as a pre-1.0 namespace and repository migration of the CellTUI TUI
implementation. The migration preserves observable TUI semantics while
changing repository, crate, module, package, fixture, and diagnostic names

There are no compatibility aliases for the old namespace because no stable
release line depends on it

## Repository and package mapping

| Previous location | Nagi location |
| --- | --- |
| Rust repository `celltui-rs` | `nagi-rs` |
| Rust crate `celltui` | `nagi-tui` |
| Rust crates `celltui-text`, `celltui-vt`, `celltui-surface` | `nagi-text`, `nagi-vt`, `nagi-surface` |
| Rust crates `celltui-widgets`, `celltui-test` | `nagi-tui-widgets`, `nagi-tui-test` |
| Go module `github.com/mayahiro/celltui-go` | Split between `github.com/mayahiro/nagi-go` and `github.com/mayahiro/nagitui-go` |
| Go packages `text`, `vt` | `github.com/mayahiro/nagi-go/text` and `/vt` |
| Go root, `surface`, `widget`, `tuitest` | `github.com/mayahiro/nagitui-go` and its subpackages |

The Go TUI root package is named `tui`. The shared `nagi-go` module has no root
package

Nagi CLI is a separate product and is not a renamed part of CellTUI. The
`nagicli-go` repository remains a specification-only scaffold during Phase F0

## Canonical type ownership

The migration corrects two ownership boundaries without changing value
semantics

- `Point`, `Size`, and `Rect` are defined by Nagi Surface
- `Color`, `Attributes`, and `Style` are defined by Nagi VT
- Rust `nagi-tui` and Go package `tui` re-export those canonical types for
  application convenience
- Surface does not retain a duplicate Style type

Go users importing `surface.Style` must instead import
`github.com/mayahiro/nagi-go/vt` and use `vt.Style`. Existing application code
may use the `tui.Style` facade alias when it already imports the TUI root

## Fixture and diagnostic namespace

| Previous name | Nagi name |
| --- | --- |
| `celltui-fixture-v1` | `nagi-fixture-v1` |
| `celltui-surface-v1` | `nagi-surface-v1` |
| `CELLTUI_FIXTURES` | `NAGI_FIXTURES` |
| Go diagnostic prefix `celltui:` | `nagi-tui:` |

Fixture payload semantics and expected rendering results are unchanged

## Git history

Nagi repositories use independent histories rather than merging the CellTUI
histories. Consumers should treat Nagi as a new dependency and update import
paths directly. Migration source revisions are recorded in the coordination
repository's development ADRs

## Versioning before 1.0

- Patch releases preserve documented public behavior while fixing defects or
  adding compatible implementation details
- A minor release may contain a breaking public API or behavior change before
  1.0
- Rust workspace crates use one coordinated version
- The three Go modules are versioned independently and use ordinary module tags
- Matching Rust and Go TUI releases are identified by a tested Nagi
  specification and fixture revision

Use the [public API guide](API.md) and
[Rust and Go API mapping](API_MAPPING.md) for current entry points
