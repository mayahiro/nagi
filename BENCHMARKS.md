# Benchmarks

Nagi treats framework overhead as acceptable only while it does not dominate
the application. Performance work evaluates CPU time, allocation, retained
memory, terminal I/O, wake-ups, and long-running trends as applicable. In this
project, "resource usage" specifically means CPU and memory, and those are the
highest-priority metrics. I/O and wake-ups remain performance metrics

## ScrollViewport purpose

This benchmark compares three warmed 80 by 24 Cell frame paths over 100,000
one-Cell rows

- The eager case constructs the complete child tree on every application view
- The virtual case declares the complete extent and constructs the 24-row
  visible fragment
- The virtual-identified case additionally assigns a stable precomputed ID to
  every visible row, exercising the ID-bearing tree index path
- All cases perform semantic tree preparation, layout, rendering, and Surface
  diffing
- The workload has no terminal I/O, timers, Effects, or Subscriptions, so it
  does not measure I/O or wake-up behavior

The measured path is single-threaded and has no blocking work, so elapsed time
is used as a repeatable proxy for CPU cost. It is not operating-system process
CPU time

Rust additionally instruments allocation count, total allocated bytes, peak
additional live bytes, and retained bytes with a benchmark-only allocator. Go
uses the standard `testing` allocation metrics. Rust reports the median of 12
measured frames. The Go table uses the median of three reports, each measured
over five frames. Both reusable tree-index buffers are populated by two
unmeasured warm-up frames before sampling

## Reference environment

- Apple M1 Max, arm64
- macOS 15.7.7
- Rust 1.96.0
- Go 1.26.5

Run both implementations from the superproject root

```sh
make bench
```

## Reference results

Results recorded on 2026-07-20

| Implementation | Path | Median time per frame | Allocations per frame | Allocated bytes per frame | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | eager | 267.796 ms | 100,083 | 21,594,680 | 21,500,184 | 0 |
| Rust | virtual | 0.079 ms | 105 | 99,264 | 99,176 | 0 |
| Rust | virtual-identified | 0.082 ms | 106 | 99,280 | 99,192 | 0 |
| Go | eager | 291.618 ms | 12 | 44,910,384 | not measured | not measured |
| Go | virtual | 0.103 ms | 9 | 110,448 | not measured | not measured |
| Go | virtual-identified | 0.104 ms | 10 | 110,464 | not measured | not measured |

On this workload, virtual median frame time is about 1/3,390 of eager time in
Rust and 1/2,840 in Go. Allocated bytes are about 1/218 of eager allocation in
Rust and 1/407 in Go. Adding stable IDs to all 24 visible rows adds one
allocation and 16 allocated bytes in both implementations. The timing
difference is within run-to-run noise. The identified path does not make
tree-index work proportional to the declared 100,000 rows

Compared with the previous virtual baseline on the same reference environment,
Rust reduced median frame time from 0.228 ms to 0.079 ms, allocations from
4,683 to 105, and allocated bytes from 154,648 to 99,264. Go reduced median
frame time from 0.177 ms to 0.103 ms, allocations from 928 to 9, and allocated
bytes from 180,464 to 110,448

A Go allocation profile over 1,000 virtual frames attributes 88.8% of allocated
bytes to the fixed 80 by 24 frame Surface and 9.2% to visible-fragment
construction. Text segmentation and wrapping, linear layout, and tree-index
construction no longer appear as dominant direct allocation sites

These values are directional baselines, not performance guarantees. Machine
load, allocator behavior, compiler versions, and application content affect the
result. Timing remains a benchmark rather than a pass/fail test

## Regression checks

Deterministic tests in both implementations scroll through 256 frames and
verify that only visible rows are constructed and the semantic tree remains
bounded. The Go implementation also compares retained heap after two 512-frame
windows with garbage collection between them, allowing 1 MiB for runtime noise

The text implementations retain their materialized APIs while exposing
streaming grapheme and wrapped-line APIs for allocation-sensitive paths. Shared
Unicode conformance fixtures verify that the streaming segmentation preserves
the existing Unicode behavior. Runtime tree indexes and linear layout results
reuse frame-local capacity while keeping the current successful semantic tree
available if a later build fails

These checks cover CPU and memory structure for the virtualized path. Terminal
I/O and event-loop wake-up behavior remain part of the broader performance
policy and require workload-specific measurement when those paths change
