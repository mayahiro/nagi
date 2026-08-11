# Nagi semantic specifications

These documents define the observable semantics shared by the native Rust and
Go implementations of Nagi Content, TUI, and CLI

The specifications are intentionally language-neutral. Rust and Go APIs may
use different shapes when that is idiomatic, but equivalent inputs must produce
equivalent observable results

The words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY describe requirement
strength

## Specification index

- [Lifecycle and state](lifecycle.md)
- [Geometry](geometry.md)
- [Layout](layout.md)
- [Core nodes](core-nodes.md)
- [Source-neutral content](content.md)
- [Unicode and terminal text](text.md)
- [Cell surfaces](surface.md)
- [VT input](vt-input.md)
- [VT output](vt-output.md)
- [Unix terminal session](terminal-session.md)
- [Focus](focus.md)
- [Event routing](event-routing.md)
- [Scoped key maps](keymap.md)
- [Effects and subscriptions](effects.md)
- [Scheduling](scheduling.md)
- [Standard widgets](widgets.md)
- [Command applications](cli.md)
- [Testing](testing.md)
