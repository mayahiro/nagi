# Message queue and frame scheduling

- Input, effect results, subscription results, and timers enter one logical
  queue
- Application updates run sequentially on one thread or goroutine
- Queue growth is bounded or controlled by an explicit backpressure policy
- Backpressure behavior remains diagnosable
- Multiple sequential updates MAY be followed by one coalesced render
- Coalescing MUST NOT change message order or state transitions
- One asynchronous scheduling cycle applies at most the configured positive
  `MaxUpdatesPerCycle` count. The shared default is 64 updates
- A cycle moves only enough ready Effect and Subscription values into the
  application queue to fit its remaining update budget. Work retained by a
  source remains pending for a later cycle
- Between bounded asynchronous cycles, a terminal runner MUST check resize and
  terminal input before applying more source values. If application work is
  already ready, the next wait MUST be immediate rather than periodic
- The count budget bounds consecutive application updates, not the execution
  time of one update. Applications remain responsible for keeping each update
  finite and responsive
- When one terminal read decodes multiple input Events, each Event MUST complete
  routing, terminal fallback mapping, input-derived Message updates, and
  semantic-tree rebuilding before the next Event is routed. Only Surface
  rendering is coalesced across the decoded batch
- If an Event requests a terminal-suspending Effect, the runner completes that
  Event's updates, discards later Events already decoded from the same read,
  runs the terminal suspension boundary, and resumes with a fresh decoder and
  full-redraw baseline
- Polling asynchronous Effect and Subscription sources occurs at the normal
  scheduling boundary rather than between Events from the same decoded input
  batch
- The per-cycle asynchronous budget does not split one input Event transaction.
  Messages emitted while routing that Event are applied before the next decoded
  Event and do not poll asynchronous sources
- Resize, focus, cursor handling, and explicit frame requests bypass the frame
  interval and request an immediate frame
- Scheduling is event-driven and does not assume a fixed 60 frames per second
- A configurable minimum frame interval MAY limit rendering work. Zero means
  no rate limit
- The default terminal options limit non-urgent rendering to at most 120 frames
  per second
- A terminal runner MUST wait without a periodic timeout when no input,
  asynchronous notification, or clock-driven deadline is pending
- Stream values and completed asynchronous Effects MUST notify a waiting
  terminal runner. Notifications MAY be coalesced, but message values and
  required state transitions MUST follow their Delivery and queue semantics
- Stream return, Stream panic, and Effect panic lifecycle notices MUST also wake
  a waiting terminal runner
- Batch Stream notifications MAY coalesce between the first buffered value and
  the configured count or delay boundary. The first value MUST establish a
  waitable deadline, and reaching the count MUST wake a waiting runner

At one scheduling boundary, already queued input is followed by ready effect
results and then ready subscription values. Subscription values are ordered by
their source arrival sequence. Removing a subscription while processing an
earlier queued message discards later queued values from the stopped generation

Runtime time comes from a clock interface with production and virtual
implementations. ESC deadlines, delayed effects, and subscription timers MUST be
controllable through virtual time in tests
