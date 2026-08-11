# Nagi

[日本語](README_ja.md)

Nagi is a family of native Rust and Go libraries for terminal applications

The family separates full-screen interactive TUI applications, command-style
CLI applications, and independently reusable Content, Text, and VT foundations

## Repositories

| Repository | Responsibility | Release unit |
| --- | --- | --- |
| [`nagi-rs`](nagi-rs/README.md) | All Rust Content, Text, VT, Surface, TUI, CLI, Widget, and test-support crates | One coordinated Cargo workspace version |
| [`nagi-go`](nagi-go/README.md) | Shared Go `content`, `text`, and `vt` packages | `github.com/mayahiro/nagi-go` |
| [`nagitui-go`](nagitui-go/README.md) | Go Surface, TUI runtime, Widgets, and TUI Test | `github.com/mayahiro/nagitui-go` |
| [`nagicli-go`](nagicli-go/README.md) | Go Command Graph, parser, runtime, and CLI Test | `github.com/mayahiro/nagicli-go` |

This repository coordinates the four implementation repositories as
submodules and owns the language-neutral specifications and conformance
fixtures

## Dependency boundaries

Nagi Content depends only on Nagi Text. Nagi Surface depends on Text and VT,
and Nagi TUI depends on Text, VT, and Surface. Nagi CLI may depend on Content,
Text, and VT but must not depend on Surface or TUI

Geometry types (`Point`, `Size`, and `Rect`) are owned by Nagi Surface. Terminal
`Color`, `Attributes`, and `Style` are owned by Nagi VT. TUI facade packages may
re-export those canonical types for application convenience

The Go modules are intentionally separate so TUI and CLI users can version and
install their product without depending on the other product. Rust uses one
workspace because Cargo crates remain separately selectable dependencies

## Current status

The shared Rust and Go foundations provide immutable source-neutral Content,
Unicode-aware text, and typed VT codecs. The existing Nagi TUI implementation
adds native runtimes, cell surfaces, deterministic test harnesses, 27 standard
widgets, virtual ScrollViewports, and stable variable-height VirtualFeeds for
large content

Nagi CLI provides native Rust and Go Command Graphs, command-local typed value
scopes, portable option groups and validators, structured deterministic Help
with controllable Help-only Usage Variants, targeted semantic Diagnostics,
staged runtime policies, cooperative SIGINT cancellation, process-free test
drivers, and matching examples

## Usage and contracts

- [Runnable Rust examples](nagi-rs/README.md#examples)
- [Runnable Rust and Go Content examples](docs/CONTENT.md#projection-and-validation)
- [Runnable Go Text and VT example](nagi-go/README.md#examples)
- [Runnable Go TUI examples](nagitui-go/README.md#examples)
- [Runnable Go CLI examples](nagicli-go/README.md#examples)
- [Nagi semantic specifications](spec/README.md), including [CLI commands](spec/cli.md)
- [Source-neutral Content guide](docs/CONTENT.md) and [Japanese version](docs/CONTENT_ja.md)
- [Public TUI API guide](docs/API.md) and [Japanese version](docs/API_ja.md)
- [Event-driven TUI application architecture](docs/EVENT_DRIVEN_APPLICATIONS.md) and [Japanese version](docs/EVENT_DRIVEN_APPLICATIONS_ja.md)
- [Public CLI API guide](docs/CLI_API.md) and [Japanese version](docs/CLI_API_ja.md)
- [Rust and Go API mapping](docs/API_MAPPING.md) and [Japanese version](docs/API_MAPPING_ja.md)
- [Reproducible performance baselines](BENCHMARKS.md)

## Supported environments

Terminal applications target Linux and macOS on x86-64 and ARM64. Windows is
not currently supported

## License

Nagi source code is available under the MIT License. Generated Unicode data and
imported conformance cases are distributed under the
[Unicode License v3](UNICODE-LICENSE)
