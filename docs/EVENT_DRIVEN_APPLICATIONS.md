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
| One-shot asynchronous work | Effect |
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

## Choose the source by lifetime

- Use an Effect for finite work started by init or update
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

## Avoid a second UI loop

Avoid these patterns in a standard full-screen terminal application

- Calling runtime step or render from an application ticker
- Polling channels with short sleeps when a Stream can block for input
- Calling `RequestFrame` for every log record
- Performing process I/O or other blocking work in view
- Retaining unbounded logs in application state
- Using Latest delivery for records that must not be lost

Embedding Nagi in a non-terminal host can require manual Runtime driving. In
that case the host loop owns the same responsibilities as the terminal runner
and should wait on real readiness or deadlines rather than poll at a fixed rate

## Runnable reference

The matching log viewers implement this architecture with a self-contained
simulated process source. Run each command from the corresponding implementation
repository root

- [Rust source](../nagi-rs/crates/nagi-tui/examples/log_viewer/main.rs):
  `cargo run -p nagi-tui --example log_viewer`
- [Go source](../nagitui-go/examples/log-viewer/main.go):
  `go run ./examples/log-viewer`

The simulated producer uses a timer so the example needs no external process.
A product adapter should replace only that producer body with its blocking
process-output reader; the application lifecycle and render ownership stay the
same

## Testing

Use `nagi-tui-test` or Go `tuitest` with virtual time and controlled Effect or
Subscription sources. Drive Messages and deadlines explicitly instead of
sleeping in application tests
