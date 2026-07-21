# Application lifecycle and state

## Lifecycle

Conceptually, an application provides four operations

```text
init()             -> Effect<Message>
update(Message)    -> Effect<Message>
subscriptions()    -> Subscription<Message>
view(ViewContext)  -> Node<Message>
```

- `update` MUST run sequentially for a given application
- Messages MUST be processed in queue order unless a subscription explicitly
  uses latest-value delivery
- Completed effects MUST return to the application as messages
- `ViewContext` contains the current terminal size in cells. Runtime and
  Interaction State are not exposed through it
- `view` MUST NOT perform I/O or mutate runtime state
- Rendering MAY be coalesced across multiple processed messages without changing
  update order
- An update MAY explicitly declare that it did not change state observed by
  `view`, allowing an otherwise clean runtime to skip that update's frame

An application MAY request normal exit from an Effect returned by `init` or
`update`. If that state transition dirties the view, the terminal loop MUST
render the resulting final frame before restoring the terminal. External
cancellation is separate from application-driven exit and returns through the
terminal runner's ordinary error or cancellation result

## State ownership

- Application State belongs to the application and represents domain meaning
- Interaction State belongs to the runtime, is keyed by stable `NodeId` values,
  and remains observable through public test support
- Render Cache is derived data and MAY be discarded and recomputed at any time

The runtime MUST NOT place user-visible continuity or event-processing state in
Render Cache

## View identity

The semantic view tree MAY be rebuilt for every frame. Stateful, focusable, or
event-receiving nodes MUST use stable identifiers across frames. Collection
items MUST derive identity from stable domain keys rather than display position

Interaction State belonging to a removed node is retired during frame-end
reconciliation, after the new semantic tree establishes its active IDs and no
later than completion of that rendered frame. This applies to focus, pointer
capture, TextInput, and ScrollViewport state
