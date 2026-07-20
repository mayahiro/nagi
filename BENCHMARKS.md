# Benchmarks

Nagi treats framework overhead as acceptable only while it does not dominate
the application. Performance work evaluates CPU time, allocation, retained
memory, terminal I/O, wake-ups, and long-running trends as applicable. In this
project, "resource usage" specifically means CPU and memory, and those are the
highest-priority metrics. I/O and wake-ups remain performance metrics

## ScrollViewport purpose

This benchmark compares one warmed 80 by 24 Cell frame over 100,000 one-Cell
rows

- The eager case constructs the complete child tree on every application view
- The virtual case declares the complete extent and constructs the 24-row
  visible fragment
- Both cases perform semantic tree preparation, layout, rendering, and Surface
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
over five frames

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
| Rust | eager | 753.638 ms | 16,600,434 | 218,000,048 | 23,593,864 | 0 |
| Rust | virtual | 0.228 ms | 4,683 | 154,648 | 100,816 | 0 |
| Go | eager | 543.122 ms | 3,300,208 | 318,551,644 | not measured | not measured |
| Go | virtual | 0.177 ms | 928 | 180,464 | not measured | not measured |

On this workload, virtual median frame time is about 1/3,305 of eager time in
Rust and 1/3,069 in Go. Allocated bytes are about 1/1,409 of eager allocation in
Rust and 1/1,765 in Go

These values are directional baselines, not performance guarantees. Machine
load, allocator behavior, compiler versions, and application content affect the
result. Timing remains a benchmark rather than a pass/fail test

## Regression checks

Deterministic tests in both implementations scroll through 256 frames and
verify that only visible rows are constructed and the semantic tree remains
bounded. The Go implementation also compares retained heap after two 512-frame
windows with garbage collection between them, allowing 1 MiB for runtime noise

These checks cover CPU and memory structure for the virtualized path. Terminal
I/O and event-loop wake-up behavior remain part of the broader performance
policy and require workload-specific measurement when those paths change
