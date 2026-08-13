# Event-driven TUI applications

[日本語](EVENT_DRIVEN_APPLICATIONS_ja.md)

A production Nagi terminal application should normally have one UI scheduler:
the Nagi terminal runner. The application declares event sources and reduces
their Messages into state. It does not wrap the runtime in its own polling or
render loop

This avoids periodic framework wake-ups when no source has a deadline, lets
Nagi coalesce bursts into one frame, and gives subscription cancellation one
owner

## Ownership

| Responsibility | Owner |
| --- | --- |
| Terminal input, resize, waiting, wake-up, and render timing | Nagi terminal runner |
| Opt-in startup capability observation and keyboard mode lifecycle | Nagi terminal runner |
| One-shot asynchronous work | Effect |
| One blocking operation requiring the ordinary terminal | SuspendTerminal Effect and terminal runner |
| Long-lived external input such as process output | Stream subscription |
| Clock-driven state such as uptime | Every subscription |
| Model mutation | Sequential application update |
| Semantic UI construction | Application view |

A Stream adapter may contain a blocking read loop for process stdout, a socket,
or another external source. That adapter is not a second UI loop: it only sends
Messages through its bounded sink, observes cancellation, and never calls view
or render

```text
process stdout -> Stream(Batch) --\
uptime deadline -> Every(Latest) ---> bounded queue -> update -> dirty state
terminal input --------------------/                         |
                                                             v
                                                coalesced view and render
```

One terminal read may decode several Unicode or key Events. Nagi completes
routing and every input-derived update for one Event before routing the next,
so controlled widgets always rebuild from the latest state. Only the resulting
render is coalesced across that input batch

Opt-in capability detection runs once after the terminal session opens and
before the initial application view. It does not add a polling source to the UI
loop. The runner retains unrelated bytes read during the bounded query and
routes them through the ordinary decoder after setup

If one Event requests terminal suspension, later Events already decoded from
the same read are discarded. The runner restores the ordinary terminal, runs
the application-owned task on its driver thread, resumes the configured
viewport, resets incomplete decoder state, and forces a full redraw

## Choose the source by lifetime

- Use an Effect for finite work started by init or update
- Use a SuspendTerminal Effect only for finite blocking work that requires the
  ordinary terminal, such as an interactive editor, shell, or authentication UI
- Use a keyed Latest Effect when a newer request makes older work stale
- Use a Stream subscription for a long-lived blocking or callback source
- Use an Every subscription only for state that actually changes on a clock
- Route terminal input through event handlers or the terminal event mapper

Do not create a timer solely to make the UI redraw. Source Messages mark the
application dirty, and Nagi schedules the frame

## Process-monitor pattern

A process monitor commonly declares two independent sources

1. Process records enter a Stream with Reliable or Batch delivery
2. Uptime enters a one-second Every source with Latest delivery

Batch delivery preserves FIFO records and releases them after a count or delay
limit. Each record still receives one sequential update, while rendering occurs
at most once after the ready queue is drained. Latest delivery is suitable for
uptime because only the newest value matters

Keep source keys stable across views of the same application state. Removing a
source from the subscriptions declaration asks Nagi to cancel that generation,
wake blocked sends, and discard values that have not entered update. A producer
must return after cancellation or a closed sink. Do not leave detached worker
threads or goroutines behind

Go terminal and context-aware Runtime entry points derive worker,
terminal-task, and Stream contexts from the caller context. Values, deadlines,
cancellation, and cancellation causes therefore remain available to process
adapters and tracing code. Runtime close still requests cancellation for each
active child

## Lifecycle notices

An active Stream is a long-lived source. Returning while its generation remains
active is unexpected and produces a `RuntimeNotice`; a return after requested
cancellation does not. Recovered Effect and Stream panics and worker-spawn
failures also produce notices. Panic payloads are not retained

Notices use a separate bounded FIFO, preserve the oldest retained entries, and
increment a dropped counter when full. They do not become application Messages
or mark the view dirty. A manually driven Runtime can drain and map them to
application-owned Messages. Terminal runners provide a synchronous notice
handler for logging, telemetry, or an application-defined bridge

## Rendering and backpressure

`MinimumFrameInterval` limits non-urgent frames; it is not an event-loop polling
interval. Nagi can process many source Messages, retain the latest application
state, wait for the remaining frame deadline, and render once. Framework-owned
keyboard scrolling, focus, and resize remain urgent

For high-rate sources

- Select Reliable, Batch, or Latest delivery from the data-loss contract
- Keep the application queue and source inbox bounded
- Keep retained history bounded or persist it outside the view model
- Format records when they enter update instead of rescanning the complete log
- Use a VirtualScrollViewport so view construction follows visible rows
- Do not call `RequestFrame` or `request_frame` for ordinary source data
- Return `Effect::none().without_redraw()` or
  `NoneEffect[Message]().WithoutRedraw()` when a Message changes no state read
  by the current view, such as output retained for an unselected process

`SetClipboard` is also synchronous and does not start a worker. Runtime keeps
only the latest pending request, so a custom driver should take it after each
coalesced step. The standard terminal runner drops requests unless direct,
write-only OSC 52 is explicitly enabled. When a copy Message changes no visible
application state, combine the Clipboard Effect with `without_redraw` or
`WithoutRedraw`

`SuspendTerminal` does not start a worker either. It remains pending until the
terminal driver can safely leave raw mode and its configured viewport. A
full-screen session leaves the alternate screen; an inline session finalizes
its current main-screen region. Existing workers and Streams continue using
their bounded delivery contracts while the driver task blocks, but application
update and rendering resume only after that task returns. The task maps its own
process status or domain error to a Message

## Avoid a second UI loop

Avoid these patterns in a standard terminal application

- Calling runtime step or render from an application ticker
- Polling channels with short sleeps when a Stream can block for input
- Calling `RequestFrame` for every log record
- Performing process I/O or other blocking work in view
- Retaining unbounded logs in application state
- Using Latest delivery for records that must not be lost

Embedding Nagi in a non-terminal host can require manual Runtime driving. In
that case the host loop owns the same responsibilities as the terminal runner
and should wait on real readiness or deadlines rather than poll at a fixed
rate. A manual driver that executes a pending terminal task must establish its
own safe suspend/resume boundary and invalidate the Runtime terminal surface
afterwards

## Runnable reference

The matching log viewers implement this architecture with a self-contained
simulated process source. Run each command from the corresponding implementation
repository root

- [Rust source](../nagi-rs/crates/nagi-tui/examples/log_viewer/main.rs):
  `cargo run -p nagi-tui --example log_viewer`
- [Go source](../nagitui-go/examples/log-viewer/main.go):
  `go run ./examples/log-viewer`

The matching terminal-suspension examples run an application-selected
interactive shell and resume after it exits

- [Rust source](../nagi-rs/crates/nagi-tui/examples/terminal_suspend/main.rs):
  `cargo run -p nagi-tui --example terminal_suspend`
- [Go source](../nagitui-go/examples/terminal-suspend/main.go):
  `go run ./examples/terminal-suspend`

The terminal-capability examples opt into the startup query and show the
immutable profile supplied to each view

- [Rust source](../nagi-rs/crates/nagi-tui/examples/terminal_capabilities/main.rs):
  `cargo run -p nagi-tui --example terminal_capabilities`
- [Go source](../nagitui-go/examples/terminal-capabilities/main.go):
  `go run ./examples/terminal-capabilities`

The simulated producer uses a timer so the example needs no external process.
A product adapter should replace only that producer body with its blocking
process-output reader; the application lifecycle and render ownership stay the
same

## Testing

Use `nagi-tui-test` or Go `tuitest` with virtual time and controlled Effect or
Subscription sources. Drive Messages and deadlines explicitly instead of
sleeping in application tests. Feed multi-scalar input as one chunk when testing
controlled editors so per-Event updates and render coalescing are both covered.
Use the harness terminal-task method to simulate resume, pending-input discard,
result delivery, and full redraw without changing a real terminal
