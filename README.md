# Nagi

[日本語](README_ja.md)

Nagi is a family of native Rust and Go libraries for terminal applications

The family separates full-screen interactive TUI applications, command-style
CLI applications, and the small text and VT foundations they genuinely share

## Repositories

| Repository | Responsibility | Release unit |
| --- | --- | --- |
| [`nagi-rs`](nagi-rs/README.md) | All Rust Text, VT, Surface, TUI, Widget, and TUI Test crates | One coordinated Cargo workspace version |
| [`nagi-go`](nagi-go/README.md) | Shared Go `text` and `vt` packages | `github.com/mayahiro/nagi-go` |
| [`nagitui-go`](nagitui-go/README.md) | Go Surface, TUI runtime, Widgets, and TUI Test | `github.com/mayahiro/nagitui-go` |
| [`nagicli-go`](nagicli-go/README.md) | Go Nagi CLI, currently a specification-only Phase F0 scaffold | `github.com/mayahiro/nagicli-go` |

This repository coordinates the four implementation repositories as
submodules and owns the language-neutral specifications and conformance
fixtures

## Dependency boundaries

Nagi Text and Nagi VT are the shared foundations. Nagi Surface depends on both,
and Nagi TUI depends on Text, VT, and Surface. Nagi CLI may depend on Text and
VT but must not depend on Surface or TUI

Geometry types (`Point`, `Size`, and `Rect`) are owned by Nagi Surface. Terminal
`Color`, `Attributes`, and `Style` are owned by Nagi VT. TUI facade packages may
re-export those canonical types for application convenience

The Go modules are intentionally separate so TUI and CLI users can version and
install their product without depending on the other product. Rust uses one
workspace because Cargo crates remain separately selectable dependencies

## Current status

The existing Nagi TUI implementation provides native Rust and Go runtimes,
Unicode-aware text, typed VT codecs, cell surfaces, deterministic test
harnesses, and 21 standard widgets

Nagi CLI implementation has not started. Its Phase F0 repository and detailed
specification scaffold establish boundaries without committing to an API

## Specifications and guides

- [Nagi TUI semantic specifications](spec/README.md)
- [Public TUI API guide](docs/API.md) and [Japanese version](docs/API_ja.md)
- [Rust and Go API mapping](docs/API_MAPPING.md) and [Japanese version](docs/API_MAPPING_ja.md)
- [Compatibility and migration guide](docs/MIGRATION.md) and [Japanese version](docs/MIGRATION_ja.md)

Fixtures use the `nagi-fixture-v1` header, Surface snapshots use
`nagi-surface-v1`, and implementations discover shared fixtures through
`NAGI_FIXTURES`

## Development checkout

Initialize the implementation repositories and run the coordinated checks

```sh
git submodule update --init --recursive
make check
```

The root `go.work` connects the three Go modules only for this development
checkout. Published module manifests do not use local `replace` directives

## Supported environments

Terminal applications target Linux and macOS on x86-64 and ARM64. Windows is
not currently supported

## License

Nagi source code is available under the MIT License. Generated Unicode data and
imported conformance cases are distributed under the
[Unicode License v3](UNICODE-LICENSE)
