# Benchmarks

Nagi treats framework overhead as acceptable only while it does not dominate
the application. Performance work evaluates CPU time, allocation, retained
memory, terminal I/O, wake-ups, and long-running trends as applicable. In this
project, "resource usage" specifically means CPU and memory, and those are the
highest-priority metrics. I/O and wake-ups remain performance metrics

## ScrollViewport purpose

This benchmark compares four warmed 80 by 24 Cell frame paths over 100,000
one-Cell rows

- The eager case constructs the complete child tree on every application view
- The virtual case declares the complete extent and constructs the 24-row
  visible fragment
- The virtual stick-to-end growth case adds one row per frame while following
  the content end and constructs the final 24-row visible fragment
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
over five frames. Reusable tree-index buffers and, where ownership permits,
reusable frame storage are populated by two unmeasured warm-up frames before
sampling

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

Results recorded on 2026-07-21

| Implementation | Path | Median time per frame | Allocations per frame | Allocated bytes per frame | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | eager | 244.093 ms | 100,080 | 25,502,224 | 25,500,224 | 0 |
| Rust | virtual | 0.072 ms | 102 | 7,768 | 5,952 | 0 |
| Rust | virtual stick-to-end growth | 0.072 ms | 102 | 7,768 | 5,952 | 0 |
| Rust | virtual-identified | 0.074 ms | 103 | 7,784 | 5,968 | 0 |
| Go | eager | 256.719 ms | 10 | 45,655,264 | not measured | not measured |
| Go | virtual | 0.088 ms | 7 | 60,704 | not measured | not measured |
| Go | virtual stick-to-end growth | 0.091 ms | 7 | 60,704 | not measured | not measured |
| Go | virtual-identified | 0.085 ms | 8 | 60,720 | not measured | not measured |

On this workload, virtual median frame time is about 1/3,390 of eager time in
Rust and 1/2,920 in Go. Allocated bytes are about 1/3,280 of eager allocation
in Rust and 1/750 in Go. Adding stable IDs to all 24 visible rows adds one
allocation and 16 allocated bytes in both implementations. The timing
difference is within run-to-run noise. The identified path does not make
tree-index work proportional to the declared 100,000 rows

The stick-to-end path previews the offset that interaction preparation will
commit, so initial rendering and content growth construct only the final
visible fragment. Its allocation results match the fixed-content virtual path
in both implementations, and its timing difference is within run-to-run noise

Compared with the preceding 2026-07-20 baseline on the same reference
environment, Rust reduced virtual median frame time from 0.079 ms to 0.072 ms,
allocations from 105 to 102, and allocated bytes from 99,264 to 7,768. Go
reduced virtual median frame time from 0.103 ms to 0.088 ms, allocations from 9
to 7, and allocated bytes from 110,448 to 60,704

The current path reuses unretained Rust frame storage, stores Go Surface cells
in a compact internal representation, uses inline diff scratch for common
terminal widths, and omits a second semantic tree-index build when interaction
preparation did not change layout. Go's public frame snapshot contract retains
its rendered Surface; the production terminal path releases and reuses that
storage after encoding

These values are directional baselines, not performance guarantees. Machine
load, allocator behavior, compiler versions, and application content affect the
result. Timing remains a benchmark rather than a pass/fail test

## Regression checks

Deterministic tests in both implementations scroll through 256 frames and
verify that only visible rows are constructed and the semantic tree remains
bounded. The Go implementation also compares retained heap after two 512-frame
windows with garbage collection between them, allowing 1 MiB for runtime noise

Both implementations also verify that initial stick-to-end rendering and
content growth invoke the fragment builder once per frame, construct only the
visible rows, and preserve a manual offset after the user leaves the end

The text implementations retain their materialized APIs while exposing
streaming grapheme and wrapped-line APIs for allocation-sensitive paths. Shared
Unicode conformance fixtures verify that the streaming segmentation preserves
the existing Unicode behavior. Runtime tree indexes and linear layout results
reuse frame-local capacity while keeping the current successful semantic tree
available if a later build fails

Runtime tests also cover reusable terminal frame storage, empty output for an
unchanged frame, allocation-preserving append encoding, explicit no-redraw
Effects, and Batch wake-up coalescing until its delivery boundary

These checks cover CPU and memory structure for the virtualized path and the
state transitions around terminal I/O and event-loop wake-ups. They do not
measure a real terminal emulator or operating-system wake-up rate, which still
require workload-specific measurement
