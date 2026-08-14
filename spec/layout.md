# Layout

Layout uses two deterministic stages

```text
measure(constraints) -> desired size
layout(rect)         -> child rectangles
```

The length model contains `Auto`, `Fixed`, `Flex`, `Percent`, and `MinMax`

- All final calculations use integer cell units
- Percent values round down
- Remaining flex cells are assigned one at a time in child order
- Percent values above 100 are clamped to 100
- Under insufficient space, later children shrink first to their declared
  minimum. If the sum of minima still exceeds the parent, later children shrink
  below their minimum to zero. This preserves child order while ensuring every
  allocation fits
- Unbounded constraints use an explicit representation rather than a sentinel
  large integer
- `Clip` limits drawing to the parent rectangle
- An eager `ScrollViewport` separates an already constructed child size from
  the visible rectangle
- Scroll offsets are clamped independently to
  `max(content_extent - viewport_extent, 0)`. A zero-sized viewport may scroll
  to the complete content extent
- A ScrollViewport MAY enable both axes, only the vertical axis, or only the
  horizontal axis. Disabled-axis offsets and maxima are zero
- Resolved scroll state contains the current offset, maximum offset, and
  beginning/end flags for every enabled axis
- `StickToEnd` starts at the end and follows content growth only while the
  viewport remains at the end. User scrolling away preserves the offset; an
  End action that returns to the end resumes following
- An eager or virtual ScrollViewport MAY declaratively name one stable
  descendant Node ID as its explicit reveal target. On every semantic-frame
  preparation, the runtime adjusts enabled-axis offsets until the complete
  target rectangle is visible when possible
- An explicit reveal target takes precedence over focused-descendant tracking
  in the same viewport. A missing target, a target outside the viewport, or a
  target outside the current virtual fragment causes no reveal and does not
  fall back to the focused descendant
- Nested explicit reveal targets are adjusted from the innermost viewport to
  the outermost viewport. Automatic reveal does not invoke the user-scroll
  callback

A virtual ScrollViewport has the same retained scroll state and options, but
declares its complete content `Size` without constructing the complete child
tree

- The builder receives the clamped visible `offset`, remaining visible `size`,
  and resolved complete `content_size` in terminal cells
- Each resolved content dimension is at least the corresponding viewport
  dimension. Offsets on disabled axes remain zero
- An empty viewport does not invoke the builder. A zero declared extent on the
  enabled vertical or horizontal axis also represents empty content
- One semantic Node frame invokes the builder at most once for an identical
  resolved request
- The builder returns one fragment origin in content coordinates and one
  semantic subtree. The origin MUST be at or before the requested offset on
  each enabled axis so the subtree covers the visible request
- A builder MAY include overscan before or after the visible request, but it
  SHOULD keep that overscan explicitly bounded instead of constructing the
  complete collection
- Only the current fragment participates in tree indexing, focus, hit testing,
  event routing, preparation, and rendering. Fragment Node IDs MUST remain
  stable when the same logical item appears in later requests
- Existing eager ScrollViewport construction remains available for bounded
  child trees

A `VirtualFlow` is a vertical viewport for ordered stable items whose measured
Cell heights may differ

- The application supplies an immutable order of unique stable `NodeId` keys.
  Reusing the same order storage skips structural reconciliation
- The source supplies a width-aware estimated height and a Node builder. Both
  estimated and measured heights normalize to at least one Cell
- The source also supplies an opaque content revision. A reset invalidates all
  measurements. A changed current-index range is accepted only when its prior
  revision matches the runtime; otherwise every item is invalidated
- Item height and a prefix-height index remain in Interaction State. Prefix
  extent, point lookup, and single-height changes use logarithmic operations;
  order and width changes are linear in item count
- Overscan is expressed in Cells before and after the visible range. A builder
  is called at most once for each required index in one semantic frame.
  Estimate correction may discover and build additional items until visible
  coverage is resolved; temporary items outside the final range are discarded
- While following the end, append and tail growth retain an end-affinity
  anchor. Away from the end, prepend, reordering, height changes, and width
  changes retain the first visible stable key and its intra-item Cell offset
- A removed anchor falls forward to the next surviving key in the prior order,
  then backward to the previous surviving key, then to the start
- Semantic anchor correction does not invoke the application scroll callback
  or resume end following after the user has left the end
- The resolved `VirtualFlowState` exposes ScrollState, optional anchor,
  non-overscanned visible index range, and current item count. Domain unread,
  paging, and persistence state remains application-owned
- Only the final built item Nodes participate in semantic traversal. Explicit
  reveal and focused-descendant tracking are limited to that built fragment
- A VirtualFlow has zero intrinsic height because content extent is retained by
  Interaction State rather than the semantic Node. Applications MUST assign a
  parent layout length or otherwise place it in a supplied rectangle
- VirtualFlow reuses the existing vertical scroll actions, wheel handling,
  `ScrollTo` Effect, and ScrollState callback without timers, tasks, I/O, or a
  new wake-up source

A Core `SplitPane` lays out exactly two eager child Nodes and one optional
divider

- The axis is horizontal by default and may be vertical
- Go values outside the named axis or collapse enums normalize to horizontal
  and secondary respectively; Rust enums cannot represent unknown values
- The ratio is the primary-pane share in basis points. Values above 10,000 are
  clamped to 10,000. Rust default options use 5,000; Go callers use
  `DefaultSplitPaneOptions` for the same value
- Primary and secondary minima independently normalize to at least one Cell
- When the assigned main-axis extent is at least
  `primary_minimum + 1 + secondary_minimum`, one Cell is reserved for the
  divider. The initial primary extent is
  `floor((available - 1) * ratio / 10000)`, clamped between the primary minimum
  and `available - 1 - secondary_minimum`. The secondary receives the
  remainder after the divider
- When that threshold is not met, the configured primary or secondary pane is
  omitted, the divider is absent, and the other pane receives the complete
  rectangle. The secondary pane is the default collapse target
- An omitted pane does not participate in preparation, virtual child
  construction, semantic indexing, focus, hit testing, event routing, or
  rendering. Supplying both child Nodes remains eager; applications use lazy
  Core children for bounded hidden work
- The divider uses the selected WidthProfile and the same one-cell Unicode to
  ASCII fallback as Core borders
- Resize does not mutate Runtime or application state. The standard SplitPane
  widget maps keyboard and pointer interaction to controlled ratio messages

A Core `ResponsiveRow` lays out an eager sequence of priority-ranked items in
start, center, and end regions

- Every item contains one Node, one region, and an unsigned 16-bit retention
  priority. Start and priority zero are the Core defaults. Unknown Go region
  values normalize to start; Rust enums cannot represent unknown values
- Row height is the greatest item height by default. A positive exact height
  overrides that intrinsic height and bounds every retained item to the same
  top-aligned extent; the assigned rectangle may still reduce it
- Natural item width is measured without a horizontal bound and normalizes to
  at least one Cell. Intrinsic row width is the saturating sum of every natural
  width and every configured gap. Intrinsic height is the greatest item height
- At zero assigned width no item is retained. Otherwise candidates are
  considered by descending priority with source order breaking ties. The first
  candidate is retained and clipped to the complete available width when
  necessary
- Every later candidate requires its complete natural width plus one gap. A
  candidate that does not fit is skipped without preventing a later narrower
  candidate from being considered
- Retained items preserve source order inside each region. Start items pack
  from the left edge and end items pack from the right edge. Center items use
  the geometric center when possible and otherwise move only enough to retain
  the configured gap from the start and end groups
- Extra space between distinct regions is allowed. The configured gap is a
  minimum separation, not a request to move edge groups toward the center
- An omitted item does not participate in preparation, virtual child
  construction, semantic indexing, focus, hit testing, routing, or rendering
  Supplying its item Node remains eager
- Resolution is deterministic and linear apart from priority ordering. One
  semantic Node caches its resolved rectangles for the assigned rectangle

The solver is not a separate public API; applications configure layout through
semantic Node lengths and composition
