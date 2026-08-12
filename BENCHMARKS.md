# Benchmarks

Nagi treats framework overhead as acceptable only while it does not dominate
the application. Performance work evaluates CPU time, allocation, retained
memory, terminal I/O, wake-ups, and long-running trends as applicable. In this
project, "resource usage" specifically means CPU and memory, and those are the
highest-priority metrics. I/O and wake-ups remain performance metrics

## ScrollViewport purpose

This benchmark compares five warmed 80 by 24 Cell frame paths over 100,000
items

- The eager case constructs the complete child tree on every application view
- The virtual case declares the complete extent and constructs the 24-row
  visible fragment
- The virtual stick-to-end growth case adds one row per frame while following
  the content end and constructs the final 24-row visible fragment
- The virtual-identified case additionally assigns a stable precomputed ID to
  every visible row, exercising the ID-bearing tree index path
- The variable-height VirtualFlow case retains a stable 100,000-item order and
  alternates one- and two-Cell item heights. Its initial order reconciliation
  and height-index allocation occur during warm-up; measured frames construct
  only the resolved visible range and one Cell of default overscan
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
over five frames. Reusable tree-index and resolved-action-route buffers and,
where ownership permits, reusable frame storage are populated by two unmeasured
warm-up frames before sampling

## Reference environment

- Apple M1 Max, arm64
- macOS 15.7.7
- Rust 1.97.1
- Go 1.26.5

Run both implementations from the superproject root

```sh
make bench
```

## Reference results

Results recorded on 2026-08-11

| Implementation | Path | Median time per frame | Allocations per frame | Allocated bytes per frame | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | eager | 285.809 ms | 100,080 | 26,302,232 | 26,300,256 | 0 |
| Rust | virtual | 0.086 ms | 102 | 7,968 | 6,176 | 0 |
| Rust | virtual stick-to-end growth | 0.085 ms | 102 | 7,968 | 6,176 | 0 |
| Rust | virtual-identified | 0.086 ms | 103 | 7,984 | 6,192 | 0 |
| Rust | variable-height VirtualFlow | 0.059 ms | 129 | 38,610 | 18,094 | 0 |
| Go | eager | 297.122 ms | 10 | 46,458,080 | not measured | not measured |
| Go | virtual | 0.103 ms | 7 | 61,344 | not measured | not measured |
| Go | virtual stick-to-end growth | 0.101 ms | 7 | 61,344 | not measured | not measured |
| Go | virtual-identified | 0.099 ms | 8 | 61,360 | not measured | not measured |
| Go | variable-height VirtualFlow | 0.101 ms | 73 | 94,304 | not measured | not measured |

On this workload, virtual median frame time is about 1/3,323 of eager time in
Rust and 1/2,891 in Go. Allocated bytes are about 1/3,301 of eager allocation
in Rust and 1/757 in Go. Adding stable IDs to all 24 visible rows adds one
allocation and 16 allocated bytes in both implementations. The timing
difference is within run-to-run noise. The identified path does not make
tree-index work proportional to the declared 100,000 rows

The stick-to-end path previews the offset that interaction preparation will
commit, so initial rendering and content growth construct only the final
visible fragment. Its allocation results match the fixed-content virtual path
in both implementations, and its timing difference is within run-to-run noise

The variable-height path demonstrates that an unchanged stable order does not
make warmed frame CPU or allocation proportional to the declared 100,000
items. It is not directly comparable to the one-Cell VirtualScrollViewport
path: it builds fewer logical items at alternating heights, while retaining
per-item measurement and semantic-anchor state and composing two-line Nodes
for half of the built items. Initial construction, order changes, and terminal
width changes intentionally remain linear in item count

Compared with the 2026-07-21 reference on the same environment, steady-state
allocation counts remain 102 in Rust and 7 in Go after adding per-Node scoped
key-map metadata and Core semantic actions. The optional Node metadata increases
allocated bytes in proportion to constructed Nodes: about 0.8 MB in the eager
100,000-row path and 200 bytes in Rust or 640 bytes in Go on the virtual path.
Timing differences are within the run-to-run variation observed in the three
Go reports and repeated Rust frames

The current path reuses unretained Rust frame storage, stores Go Surface cells
in a compact internal representation, uses inline diff scratch for common
terminal widths, omits a second semantic tree-index build when interaction
preparation did not change layout, and shares immutable default Core actions
while double-buffering their resolved route storage. Go's public frame snapshot
contract retains its rendered Surface; the production terminal path releases
and reuses that storage after encoding

These values are directional baselines, not performance guarantees. Machine
load, allocator behavior, compiler versions, and application content affect the
result. Timing remains a benchmark rather than a pass/fail test

## Content-to-Node projection purpose

This benchmark measures two eager projection paths without layout, Surface
rendering, terminal I/O, timers, Effects, or Subscriptions

- The visible-subtree path projects one Flow containing 24 Paragraphs, 24
  nested Inline Elements, 48 source Text nodes, two Presentation Rules, and one
  visual separator per Paragraph
- The bounded-failure path receives a Flow with 100,000 direct Text children
  and a caller limit of 128 visited Content nodes. The immutable input is built
  before measurement; projection stops at the first node above the limit
- Every measured result Node or partial failure result is dropped before the
  retained-memory sample

The workload represents projection inside a VirtualFlow visible-item builder,
not projection of a complete 100,000-item feed. VirtualFlow continues to own
visibility and item ordering

Rust reports the median of 12 calls with allocation count, total allocated
bytes, peak additional live bytes, and retained bytes from its benchmark-only
allocator. Go reports the median of three reports, each measured over five
calls with standard `testing` allocation metrics

### Reference results

Results recorded on 2026-08-12 in the same reference environment

| Implementation | Path | Median time per call | Allocations per call | Allocated bytes per call | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | visible subtree | 0.005 ms | 169 | 11,318 | 11,141 | 0 |
| Rust | bounded failure over 100,000-node input | 0.012 ms | 383 | 53,307 | 37,829 | 0 |
| Go | visible subtree | 0.013 ms | 98 | 21,440 | not measured | not measured |
| Go | bounded failure over 100,000-node input | 0.026 ms | 257 | 114,528 | not measured | not measured |

The failure path visits at most 129 Content occurrences and drops all partial
output. Its measured CPU and allocation therefore depend on the configured
limit rather than the complete 100,000-child input. The visible path performs
one rule resolution per Element and does not resolve per grapheme

These numbers measure newly owned frame Nodes and styled spans, so non-zero
allocation is expected. Go's projector passes its owned span slices directly
to the internal Paragraph construction path; the public Paragraph constructor
continues to defensively copy caller-owned slices

## CLI inherited-option purpose

This benchmark measures one complete command parse, including Command Graph
validation and Invocation construction. The selected command is `root run`,
and 1,000 occurrences of a root-declared inherited Count option appear after
the child selection

Two graph shapes use the same selected path and argv

- The selected-path graph contains only `run`
- The unrelated-branches graph additionally contains 100 unselected sibling
  commands with eight inherited options each

The complete graph is validated once per parse. Argument-token option lookup
uses only the selected root-to-active path, so the additional siblings add a
fixed validation cost rather than becoming candidates for each of the 1,000
occurrences. The workload has no Handler, process I/O, cancellation, or
long-running state

Rust reports the median of 12 parses with allocation count, total allocated
bytes, peak additional live bytes, and retained bytes. Go reports the median
of three reports, each measured over 100 parses with standard `testing`
allocation metrics

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-cli --bench inherited_options
GOWORK="$PWD/go.work" make -C nagicli-go bench
```

The root `make bench` command includes these paths together with the TUI
benchmarks

### Reference results

Results recorded on 2026-08-12 in the same reference environment

| Implementation | Graph | Median time per parse | Allocations per parse | Allocated bytes per parse | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | Selected path only | 0.059 ms | 2,043 | 44,183 | 34,301 | 0 |
| Rust | 100 unrelated branches | 0.270 ms | 7,375 | 246,399 | 34,301 | 0 |
| Go | Selected path only | 0.051 ms | 20 | 17,728 | not measured | not measured |
| Go | 100 unrelated branches | 0.156 ms | 638 | 99,120 | not measured | not measured |

The 1,000-occurrence selected-path case completes below 0.1 ms in both
implementations on the reference machine. Adding 800 declarations on
unselected branches increases whole-graph validation work and transient
allocation, while the option-resolution loop remains proportional to selected
path depth and options on that path. Rust drops each measured Invocation with
zero retained bytes

## CLI completion purpose

This benchmark measures one warmed completion resolution against an immutable
`CompletionEngine`. The request has selected `root run` and completes `--v` to
the root-declared inherited `--verbose` option. Engine construction and Command
Graph validation are outside the measured path

Two graph shapes use the same selected path and request

- The selected-path graph contains only `run`
- The unrelated-branches graph additionally contains 100 unselected sibling
  commands with eight options each

Rust reports the median of 12 groups of 1,000 requests with allocation count,
total allocated bytes, peak additional live bytes, and retained bytes. Go
reports the median of three reports, each measured over 100 requests with
standard `testing` allocation metrics

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-cli --bench completion
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagicli-go -run '^$' -bench '^BenchmarkCompletion(SelectedPath|100UnrelatedBranches)$' -benchmem -benchtime=100x -count=3 .
```

The root `make bench` command includes these paths

### Reference results

Results recorded on 2026-08-12 in the same reference environment

| Implementation | Graph | Median time per request | Allocations per request | Allocated bytes per request | Peak additional live bytes | Retained bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | Selected path only | 1,032 ns | 28 | 821 | 641 | 0 |
| Rust | 100 unrelated branches | 1,030 ns | 28 | 821 | 641 | 0 |
| Go | Selected path only | 493 ns | 14 | 536 | not measured | not measured |
| Go | 100 unrelated branches | 664 ns | 14 | 536 | not measured | not measured |

Unselected branches do not change per-request allocation in either
implementation. Short-run elapsed values vary, while the stable property is
that resolution does not scan or allocate for candidates from unrelated
branches. Rust releases every result with zero retained bytes

## Regression checks

Deterministic tests in both implementations scroll through 256 frames and
verify that only visible rows are constructed and the semantic tree remains
bounded. The Go implementation also compares retained heap after two 512-frame
windows with garbage collection between them, allowing 1 MiB for runtime noise

VirtualFlow tests share 15 append, prepend, removal, height-change,
width-change, revision-mismatch, follow-end, and Cell-overscan transitions.
Runtime tests verify one builder call per required item in a semantic frame and
stable prepend and streaming-tail anchors. Go additionally compares retained
heap after two 256-frame variable-height windows with the same 1 MiB tolerance

Both implementations also verify that initial stick-to-end rendering and
content growth invoke the fragment builder once per frame, construct only the
visible rows, and preserve a manual offset after the user leaves the end

Content projection shares 15 rendering and failure fixtures across Rust and
Go. They cover inline style inheritance, Paragraph wrapping and alignment,
Flow and Sequence boundaries, Length, display override, ignored Inline box
properties, HardBreak, semantic-boundary separation, identity and annotation
non-mapping, and all structured resource failures. Go additionally compares
retained heap after two 512-projection windows with a 1 MiB runtime-noise
tolerance. The Rust projection benchmark reports zero retained bytes for both
paths

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
