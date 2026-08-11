# Application test harness

Rust `nagi-tui-test` and Go `tuitest` expose deterministic control over an
application without opening a real terminal

The harnesses provide equivalent observable behavior for

- Initial terminal size and resize events
- Direct messages and decoded terminal input
- Virtual time and due scheduled work
- Controlled Effect completion and cancellation
- Manual Subscription delivery and lifecycle inspection
- Interaction State inspection and focus control
- Resolved ScrollViewport state and application exit-request inspection
- Explicit reveal-target scrolling without terminal timing
- TextArea visual wrapping, preferred-column movement, boundary availability,
  and caret-viewport following
- Composer submission, line-break rebinding, controlled history recall, length
  limits, automatic height, validation placement, and viewport following
- Modal first, target, none, nested, replacement, and return-focus lifecycle
  across application-driven view changes
- Disclosure state-dependent actions, rebinding, pointer toggling, collapsed
  lazy construction, and nested focus fallback
- Dialog and ConfirmDialog default and cancel availability, child precedence,
  rebinding, repeat behavior, pointer activation, lazy details, explicit focus,
  destructive styling, and Cell-width action wrapping
- Active target-to-root resolved action-group inspection
- Message history, frame history, and canonical Surface snapshots
- Active-task, stale-result, and backpressure diagnostics

Time-dependent application tests SHOULD use the virtual clock instead of real
sleep. Controlled asynchronous work SHOULD be completed explicitly so tests do
not depend on host scheduling

Surface snapshots use the canonical `nagi-surface-v1` representation and
include normalized grapheme content, span and continuation state, style, and
cursor state rather than raw ANSI output

Equivalent application state, input, size, and virtual time MUST produce the
same observable frames in the Rust and Go harnesses
