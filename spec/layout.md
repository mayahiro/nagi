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
- `ScrollViewport` separates content size from the visible rectangle
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

The solver is not a separate public API; applications configure layout through
semantic Node lengths and composition
