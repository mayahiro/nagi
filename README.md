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
| [`nagicli-go`](nagicli-go/README.md) | Go Command Graph, parser, runtime, shell completion, lightweight prompts, and CLI Test | `github.com/mayahiro/nagicli-go` |

This repository coordinates the four implementation repositories as
submodules and owns the language-neutral specifications and conformance
fixtures

## Dependency boundaries

Nagi Content depends only on Nagi Text. Nagi Surface depends on Text and VT,
and Nagi TUI depends on Content, Text, VT, and Surface. Nagi CLI may depend on
Content, Text, and VT but must not depend on Surface or TUI

Geometry types (`Point`, `Size`, and `Rect`) are owned by Nagi Surface. Terminal
`Color`, `Attributes`, and `Style` are owned by Nagi VT. TUI facade packages may
re-export those canonical types for application convenience

The Go modules are intentionally separate so TUI and CLI users can version and
install their product without depending on the other product. Rust uses one
workspace because Cargo crates remain separately selectable dependencies

## Current status

The shared Rust and Go foundations provide immutable source-neutral Content,
Unicode-aware text, and typed VT codecs. The existing Nagi TUI implementation
adds immutable Terminal Presentation Rules, native runtimes, cell surfaces,
bounded Content-to-Node projection, deterministic test harnesses, 31 standard
widgets, generic anchored overlays, controlled suggestion popups, typed JSON
inspection, memoized bounded code and unified diff views, virtual
ScrollViewports, and stable variable-height VirtualFeeds for large content.
Applications can route semantic copy requests through a
coalesced Clipboard Effect, with write-only OSC 52 available as an explicit
terminal opt-in. Standard terminal runners also provide opt-in conservative
capability detection, an immutable profile for views, and balanced Kitty
keyboard enhancements for distinct modified keys without granting output
permission

Nagi CLI provides native Rust and Go Command Graphs, local and inherited
options, command-local typed value scopes, portable option groups and
validators, structured deterministic Help with controllable Help-only Usage
Variants, targeted semantic Diagnostics, staged runtime policies, cooperative
SIGINT cancellation, immutable handler-free completion engines, Bash, Zsh,
Fish, and PowerShell generators, optional line-oriented prompts, process-free
test drivers, and matching examples

## Usage and contracts

- [Runnable Rust examples](nagi-rs/README.md#examples)
- [Runnable Rust and Go Content examples](docs/CONTENT.md#projection-and-validation)
- [Runnable Rust and Go Presentation examples](docs/PRESENTATION.md#packages)
- [Runnable Go Text and VT example](nagi-go/README.md#examples)
- [Runnable Go TUI examples](nagitui-go/README.md#examples)
- [Runnable Go CLI examples](nagicli-go/README.md#examples)
- [Nagi semantic specifications](spec/README.md), including [CLI commands](spec/cli.md)
- [Source-neutral Content guide](docs/CONTENT.md) and [Japanese version](docs/CONTENT_ja.md)
- [Terminal Presentation guide](docs/PRESENTATION.md) and [Japanese version](docs/PRESENTATION_ja.md)
- [Content-to-Node projection specification](spec/content-node-projection.md)
- [JSON inspector specification](spec/json-inspector.md)
- [Code view specification](spec/code-view.md)
- [Diff view specification](spec/diff-view.md)
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
