# Effects, task supervision, and subscriptions

## Effects

The effect algebra contains `None`, `Exit`, `Focus`, `ScrollTo`,
`SetClipboard`, `Run`, `Latest`, `Cancel`, `Scoped`, `CancelScope`, `After`,
`Batch`, and `Sequence`. Debounce is composed from `Latest` and `After` unless
evidence requires another primitive

`Exit`, `Focus`, `ScrollTo`, and `SetClipboard` are synchronous UI commands
applied by the Runtime. They MUST NOT start a worker thread or goroutine.
`Exit` requests normal application termination after the final dirty frame,
`Focus` requests a focusable stable Node ID in the next view, and `ScrollTo`
requests a clamped offset for a stable ScrollViewport ID in the next view

`SetClipboard` carries owned semantic UTF-8 text without choosing a domain
meaning. Go normalizes invalid UTF-8 runs to U+FFFD at the Effect boundary.
The Runtime retains at most one pending clipboard request, and a later request
replaces an earlier request that has not been taken by a driver. Taking the
request clears it. Custom Runtime drivers can route it to an application-owned
backend. The standard terminal runner drops it while terminal clipboard output
is disabled and encodes it as typed OSC 52 output only when explicitly enabled.
Clipboard reads, raw terminal sequences, redaction policy, and OS-specific
clipboard commands are not part of this Effect

Rust tasks use standard threads and cooperative cancellation. Go tasks use
goroutines and `context.Context`. A Go context-aware Runtime derives Effect and
Stream contexts from its caller so values, deadlines, cancellation, and
cancellation causes are retained. Closing the Runtime still cancels each active
child. Neither implementation embeds a general network or async runtime

`Run` starts an anonymous one-shot task. `Latest` starts a keyed task. `Cancel`
targets the current Latest generation for its key. `Scoped` associates all
nested tasks and timers with a scope generation, while `CancelScope` cancels
the current generation without preventing a later reuse of the same scope ID

`After` uses the injected runtime clock rather than worker sleep. `Batch`
starts every child independently and completes after all children finish.
`Sequence` starts one child at a time and starts the next after delivery,
cancellation, or failure completes the current child

An Effect returned directly from `update` MAY declare that the update did not
change state observed by `view`. The runtime MUST still schedule that Effect
and reconcile subscriptions, but MUST NOT dirty an otherwise clean view solely
for that update. An already-dirty runtime stays dirty. Synchronous `Exit`,
`Focus`, and `ScrollTo` commands still request their required frame.
`SetClipboard` does not independently dirty the view, but is flushed at the
next terminal scheduling boundary even when no frame is produced

Concurrent task execution is bounded by runtime configuration. Cancellation
does not free a worker slot until a running task returns. Task panics are caught
at the task boundary, suppress their result, and advance enclosing Batch or
Sequence completion

## Latest-result guarantee

Starting `Latest(key, task)` cancels the previous task cooperatively, advances a
generation, and starts the replacement. A result from an older generation MUST
NOT enter the application message queue even if the old task finishes later

Cancellation guarantees stale-result suppression, not immediate task
termination

## Scope and subscriptions

Scopes group tasks for explicit cancellation. They do not automatically couple
task lifetime to a component or Node lifetime

Subscriptions have stable keys and a lifecycle separate from one-shot effects.
The runtime compares the declared set after initialization and each application
update, then starts, retains, or stops sources deterministically. A retained key
keeps its existing source. Removing and later reintroducing a key starts a new
generation. Duplicate keys in one declaration are runtime errors

`Batch` combines declarations without creating a source. `Every` emits after
each positive interval according to the injected runtime clock, with its first
tick one full interval after startup. `Stream` runs a cooperatively cancellable
producer on a supervised standard thread in Rust or goroutine in Go

Stopping a subscription requests cancellation, closes its sink, discards its
not-yet-delivered values, and removes values from that generation that are
still in the application queue. A source that ignores cancellation is not
forcibly terminated, but its closed sink cannot deliver more values

## Subscription delivery and backpressure

Each source has a bounded inbox configured by the runtime. Values from all
sources receive one monotonic arrival order before entering the application
queue

- `Reliable` blocks a stream producer when its inbox is full and preserves
  every value in FIFO order
- `Latest` retains only the newest value that has not entered application
  update, replacing an older pending value without blocking the producer
- `Batch` preserves FIFO values in a bounded inbox and releases them after its
  configured message count or maximum delay is reached

A Reliable or Batch producer blocked by capacity is released when space is
available or the subscription stops. Every subscriptions preserve Reliable
and Batch catch-up implicitly through their next due timestamp instead of
allocating an unbounded backlog. Latest Every subscriptions skip missed
intervals and produce one value at a scheduling boundary

Backpressure, replacement, discarded-value, lifecycle, and producer-failure
counters remain observable through runtime and test-support diagnostics

## Asynchronous lifecycle notices

The Runtime retains a separate bounded FIFO of lifecycle notices. This queue
does not inject an application Message or dirty the view. When full, it keeps
the oldest notices, drops newer notices, and increments an observable dropped
counter

Notice kinds are Effect panic, Effect worker spawn failure, active Stream
return, Stream panic, and Stream worker spawn failure. Go worker primitives do
not currently report spawn failure, but the kind remains shared across the
public model. A Latest Effect notice contains its Task key and generation; an
anonymous Run notice has no task identity. Every Stream notice contains its
Subscription key and generation. Panic payloads and stack traces are not
retained

A Stream that returns while its generation remains active emits the active
Stream return notice because Stream is a long-lived source. Returning after the
Runtime requested cancellation or closed the sink does not emit that notice. A
recovered panic remains a panic notice

Custom Runtime drivers drain notices explicitly. Terminal runners provide a
synchronous notice-handler entry point and drain after each asynchronous
scheduling boundary. Applications decide whether a notice becomes domain
state, a Message, a log record, or process-level telemetry
