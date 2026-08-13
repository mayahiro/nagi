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

## Clipboard encoding purpose

This benchmark measures direct, write-only OSC 52 encoding for two semantic
UTF-8 clipboard payloads

- The small path encodes `A日`, four UTF-8 bytes
- The large path encodes 1 MiB of ASCII text
- Fresh encoding starts with an empty output allocation on every call
- Reused encoding starts with a buffer already sized by one unmeasured call,
  matching the standard terminal session's retained output buffer
- Both paths include the OSC prefix, RFC 4648 Base64 transform, and canonical
  ST terminator. They exclude terminal I/O, the Clipboard Effect, rendering,
  and application text construction

Rust reports the median of 12 samples. Each small sample contains 10,000 calls
and each large sample contains four calls. Go reports the median of three
one-second benchmark runs. Rust peak-live and retained-byte values are measured
relative to the beginning of each sample

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui --bench clipboard
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkClipboardEncoding(Small|1MiB)$' -benchmem -benchtime=1s -count=3 .
```

The Rust bench target also reports the inline viewport encoder described below.
The root `make bench` command includes all paths

### Reference results

Results recorded on 2026-08-12 in the same reference environment

| Implementation | Input | Buffer | Median time per call | Allocations per call | Allocated bytes per call | Peak additional live bytes | Retained bytes |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | 4 bytes | fresh | 80 ns | 3 | 56 | 32 | 0 |
| Rust | 4 bytes | reused | 7 ns | 0 | 0 | 0 | 0 |
| Rust | 1 MiB | fresh | 0.930 ms | 19 | 4,194,296 | 2,097,152 | 0 |
| Rust | 1 MiB | reused | 0.846 ms | 0 | 0 | 0 | 0 |
| Go | 4 bytes | fresh | 57.78 ns | 3 | 56 | not measured | not measured |
| Go | 4 bytes | reused | 8.914 ns | 0 | 0 | not measured | not measured |
| Go | 1 MiB | fresh | 0.883 ms | 34 | 6,642,448 | not measured | not measured |
| Go | 1 MiB | reused | 0.574 ms | 0 | 0 | not measured | not measured |

Encoding is linear in input bytes and requires an output of roughly four
thirds the payload size plus the fixed control-sequence framing. The reusable
path performs no measured allocation in either implementation. Its output
capacity was established before measurement, so zero retained bytes means no
additional retention during a sample; the terminal session still retains a
buffer sized for its largest encoded write. Runtime separately retains only
the latest semantic clipboard request, so repeated requests do not increase
memory by request count

These measurements do not establish OSC 52 payload limits. Terminals and
intermediate multiplexers may enforce their own limits, and direct OSC 52
remains disabled unless the application opts in

## Inline viewport origin encoding purpose

This benchmark measures the warmed output-encoding work added by an inline
terminal viewport. A representative two-line frame contains 11 UTF-8 text
bytes, three absolute cursor positions, and a hidden-cursor park operation. The
encoder adds a 17-row viewport origin to absolute positions and appends into the
standard terminal session's already-sized reusable output buffer

The workload excludes Surface diffing, cursor-position discovery, row
reservation, resize handling, and terminal I/O. It therefore isolates the
per-frame coordinate translation and VT serialization cost rather than the
complete frame cost. Rust reports the median of 12 samples with 10,000 calls
per sample. Go reports the median of three one-second benchmark runs

Run only this path from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui --bench clipboard
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkViewportOriginEncoding$' -benchmem -benchtime=1s -count=3 .
```

The Rust command also reports clipboard encoding because both standalone paths
share one benchmark binary

### Reference results

Results recorded on 2026-08-13 in the same reference environment

| Implementation | Median time per call | Allocations per call | Allocated bytes per call | Peak additional live bytes | Retained bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rust | 61 ns | 0 | 0 | 0 | 0 |
| Go | 71.81 ns | 0 | 0 | not measured | not measured |

The warmed path performs no measured allocation in either implementation.
Origin translation remains a constant amount of work per absolute cursor
operation and does not add work per terminal cell

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

## CLI Prompt purpose

This benchmark measures the CPU and transient allocation of one Prompt request
through deterministic injected I/O. It excludes terminal syscalls, user think
time, blocking input, and output device latency

Two paths are measured

- Confirm writes `Proceed? [y/n] ` and parses the visible response `yes`
- Input writes `Value: `, copies and normalizes a valid UTF-8 response at the
  default 65,536-byte limit, and returns the complete string

Request definitions, cancellation sources, and injected response storage are
constructed before measurement. Each result is dropped within its measured
request. Rust reports the median of 12 groups, using 1,000 Confirm requests or
100 large Input requests per group with a benchmark-only allocation counter.
Go reports the median of three reports over 100 requests with standard
`testing` allocation metrics. Neither path creates a task, performs terminal
I/O, or retains a Prompt session after the request

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-cli-prompt --bench prompt
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagicli-go -run '^$' -bench '^BenchmarkPrompt(Confirm|Input64KiB)$' -benchmem -benchtime=100x -count=3 ./prompt
```

The root `make bench` command includes these paths

### Reference results

Results recorded on 2026-08-12 in the same reference environment

| Implementation | Request | Median time | Allocations | Allocated bytes |
| --- | --- | ---: | ---: | ---: |
| Rust | Confirm | 128 ns | 4 | 30 |
| Rust | Input at 65,536 bytes | 4,598 ns | 3 | 131,080 |
| Go | Confirm | 145 ns | 3 | 32 |
| Go | Input at 65,536 bytes | 50,818 ns | 3 | 131,082 |

The large-input paths allocate approximately twice the configured byte limit:
the injected boundary owns one byte buffer and UTF-8 normalization returns the
language-native string owned by the application. The portable limit keeps this
transient work bounded. Ordinary Confirm processing is below one microsecond in
both implementations on the reference machine, before terminal I/O

## Pointer text-hit purpose

This benchmark isolates one warmed geometry-aware pointer Move routed to a
captured Paragraph over a 100,000-byte, no-wrap ASCII document. The pointer is
at the final document Cell, so the measured path includes target-to-root
routing, Node-local geometry, Paragraph layout-cache lookup, UTF-8 hit lookup,
and handler dispatch. Application update, view reconstruction, rendering,
terminal I/O, and viewport callbacks are intentionally excluded

Paragraph units, layout entries, and Runtime route capacity are populated
before measurement. Text hit uses precomputed logical Cell positions and a
binary search within the resolved visual line. On the 64-bit reference builds,
the common per-grapheme record remains bounded to 32 bytes. Pointer use lazily
adds one four-byte logical Cell position per grapheme and shares document bases
per styled span. Independent regression tests guard the common record size and
run 1,000 warmed dispatches under allocation tracking

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui --bench pointer_selection
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkPointerTextHit100K$' -benchmem -benchtime=1s -count=3 .
```

The root `make bench` command includes these paths

### Reference results

Results recorded on 2026-08-12 in the reference environment above

| Implementation | Document bytes | Median time per Move | Allocations per Move | Allocated bytes per Move |
| --- | ---: | ---: | ---: | ---: |
| Rust | 100,000 | 214 ns | 0 | 0 |
| Go | 100,000 | 210 ns | 0 | 0 |

These numbers characterize warmed pointer routing and text hit lookup, not the
cost of rebuilding styled selection spans after a controlled-state Message.
The zero-allocation result prevents document length from adding transient
memory pressure during a drag

## SuggestionPopup purpose

This benchmark constructs one controlled SuggestionPopup semantic Node with a
midpoint selection and eight visible rows. It compares immutable candidate
orders containing 8 and 100,000 stable IDs

Candidate validation, the immutable ID-to-index map, and source data creation
occur before measurement. The measured path clones shared SuggestionItems,
resolves selection, builds eight application rows, creates the popup action
group, and composes AnchoredOverlay. It excludes Runtime preparation,
rendering, terminal I/O, asynchronous candidate acquisition, and application
update

Rust reports the median of 12 samples with 10,000 constructions per sample. Go
reports the median of three `testing` runs with 10,000 constructions each and
includes standard allocation metrics. The Rust widget crate forbids unsafe
code, so this benchmark does not replace its global allocator; unit tests
instead verify shared immutable storage and exactly bounded row-builder calls

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui-widgets --bench suggestion_popup
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkSuggestionPopupCandidates$' -benchmem -benchtime=10000x -count=3 ./widget
```

The root `make bench` command includes these paths

### Reference results

Results recorded on 2026-08-12 in the reference environment above

| Implementation | Candidate IDs | Visible rows | Median time per construction | Allocations | Allocated bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rust | 8 | 8 | 3,021 ns | not measured | not measured |
| Rust | 100,000 | 8 | 3,033 ns | not measured | not measured |
| Go | 8 | 8 | 3,722 ns | 44 | 13,656 |
| Go | 100,000 | 8 | 4,361 ns | 44 | 13,656 |

Increasing the candidate order from 8 to 100,000 does not add proportional
construction work or change Go allocation count and bytes. SuggestionItems
intentionally retains one application-owned item array and ID-to-index map
proportional to candidate count; view reconstruction shares that storage and
performs one O(1) indexed selection lookup. The component is not a
variable-height candidate virtualizer, and it still builds the configured
visible row count on each controlled view

## JSONInspector purpose

These benchmarks separate immutable JSON document preparation from bounded
JSONInspector view construction

- The document path validates and indexes one Array containing 99,999 Number
  values, then produces its deterministic compact serialization. The typed
  source value is built before measurement, and no JSON parser is involved
- The inspector path selects the midpoint of a root Array, keeps the root
  expanded, and constructs eight visible rows. It compares documents containing
  9 and 100,000 total values
- Inspector documents, selection state, and path indexes are prepared before
  measurement. The measured path clones shared immutable storage, resolves the
  visible range, and builds the controlled semantic Node
- Both paths exclude Runtime preparation, rendering, terminal I/O, clipboard
  effects, and application update

Rust reports the median of 12 document constructions and the median of 12
samples containing 10,000 inspector constructions each. Go reports the median
of three `testing` runs, with five document constructions or 10,000 inspector
constructions per run, and includes standard allocation metrics. The Rust
widget crate forbids unsafe code, so these benchmarks do not replace its global
allocator

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui-widgets --bench json_inspector
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkJSONDocument100K$' -benchmem -benchtime=5x -count=3 ./widget
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkJSONInspectorViewport$' -benchmem -benchtime=10000x -count=3 ./widget
```

The root `make bench` command includes both paths

### Reference results

Results recorded on 2026-08-12 in the reference environment above

| Implementation | Path | Total values | Visible rows | Median time | Allocations | Allocated bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | document preparation | 100,000 | not applicable | 14.324 ms | not measured | not measured |
| Go | document preparation | 100,000 | not applicable | 7.361 ms | 100,260 | 16,886,233 |
| Rust | inspector construction | 9 | 8 | 4,747 ns | not measured | not measured |
| Rust | inspector construction | 100,000 | 8 | 6,250 ns | not measured | not measured |
| Go | inspector construction | 9 | 8 | 6,390 ns | 57 | 13,720 |
| Go | inspector construction | 100,000 | 8 | 7,950 ns | 65 | 13,762 |

The inspector constructs only the resolved visible rows rather than scanning or
projecting the complete expanded document. Moving from 9 to 100,000 values adds
no proportional view-construction time or Go allocation. The small fixed
difference includes formatting the longer selected Array index

Document preparation is intentionally linear in source size and owns a compact
serialization, a preorder record per value, and a path index for O(1) lookup.
Number tokens and Boolean spellings are read from the owned serialization rather
than duplicated in every index record. Configurable node, depth, decoded-string,
and serialized-byte limits bound accepted resource use before indexing

## CodeView purpose

These benchmarks separate immutable code-source preparation, terminal-width
projection, memoized projection lookup, and bounded CodeView construction

- The document path receives 100,000 already validated, one-span ASCII
  CodeLines and builds complete semantic source text, byte ranges, and the
  copyability prefix index
- The layout path projects the resulting document at an 80-cell viewport with
  line numbers, Modern width, and no wrapping. Source spans are shared by the
  projected rows because no tab expansion or wrapping changes their text
- The cache path performs 100,000 warmed lookups of that same immutable
  document, caller key, options, and resource limits
- The viewport path constructs eight visible rows around a midpoint selection
  and compares documents containing 8 and 100,000 logical lines
- The long-line path constructs one visible row at a 1 MiB horizontal offset
  into a 1,048,579-byte ASCII line. Sparse cell checkpoints are prepared before
  measurement
- All paths exclude Runtime preparation, Surface rendering, terminal I/O,
  clipboard effects, syntax parsing, file I/O, and application update

Rust reports the median of 12 document or layout builds and the median of 12
samples containing 100,000 cache lookups or 10,000 view constructions. Go
reports the median of three `testing` runs, using five source or layout builds
and 10,000 cache or view calls per run, and includes standard allocation
metrics. The Rust widget crate forbids unsafe code, so these benchmarks do not
replace its global allocator

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui-widgets --bench code_view
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkCode(Document|Layout)100K$' -benchmem -benchtime=5x -count=3 ./widget
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkCode(LayoutCache100K|ViewViewport|ViewLongLineOffset)$' -benchmem -benchtime=10000x -count=3 ./widget
```

The root `make bench` command includes all paths

### Reference results

Results recorded on 2026-08-12 in the reference environment above

| Implementation | Path | Source lines | Constructed rows | Median time | Allocations | Allocated bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | document preparation | 100,000 | not applicable | 2.491 ms | not measured | not measured |
| Go | document preparation | 100,000 | not applicable | 1.928 ms | 5 | 5,914,720 |
| Rust | terminal layout | 100,000 | 100,000 | 4.049 ms | not measured | not measured |
| Go | terminal layout | 100,000 | 100,000 | 4.148 ms | 3 | 8,806,496 |
| Rust | warmed layout cache | 100,000 | 0 | 4 ns | not measured | not measured |
| Go | warmed layout cache | 100,000 | 0 | 14.06 ns | 0 | 0 |
| Rust | bounded view | 8 | 8 | 34,266 ns | not measured | not measured |
| Go | bounded view | 8 | 8 | 37,651 ns | 123 | 10,520 |
| Rust | bounded view | 100,000 | 8 | 34,563 ns | not measured | not measured |
| Go | bounded view | 100,000 | 8 | 37,699 ns | 139 | 10,712 |
| Rust | 1 MiB line at end offset | 1 | 1 | 36,980 ns | not measured | not measured |
| Go | 1 MiB line at end offset | 1 | 1 | 37,584 ns | 33 | 3,128 |

The controlled view constructs only the selected visible window rather than
rebuilding every source line. Increasing the document from 8 to 100,000 lines
does not add proportional view-construction time. The small fixed Go allocation
difference includes longer line-number and visual-row identifiers around the
midpoint selection

Layout preparation remains intentionally linear in projected source size and
retains one visual-row record per no-wrap logical line. The built-in Modern and
CJK profiles use an exact ASCII width fast path, while Custom profiles still
invoke the application callback for every complete grapheme. Short no-wrap
rows share validated source spans, reserve no more than the configured visual
row limit, and omit checkpoint scans; long rows retain sparse checkpoints so a
far horizontal offset is not rescanned from byte zero on each immutable view
rebuild

## DiffView purpose

These benchmarks separate typed diff-source preparation, terminal projection,
memoized lookup, on-demand unified copy, and bounded DiffView construction

- The document path receives 100,000 already validated one-span ASCII lines,
  alternating Context, Deletion, and Addition, and builds typed line records,
  conceptual unified byte ranges, a copyability prefix index, and the shared
  CodeDocument projection source
- The layout path projects the resulting document at an 80-cell viewport with
  old and new numbers, unified markers, Modern width, and no wrapping
- The cache path performs 100,000 warmed lookups of the same immutable
  document, caller key, options, and resource limits
- The copy path generates the complete 2,800,000-byte marker-prefixed unified
  text. DiffDocument does not retain that complete string before this call
- The viewport path constructs eight visible rows around a midpoint selection
  and compares documents containing 8 and 100,000 logical lines
- All paths exclude Runtime preparation, Surface rendering, terminal I/O,
  clipboard effects, diff parsing, repository I/O, and patch application

Rust reports the median of 12 builds, copies, or samples containing 100,000
cache lookups or 10,000 view constructions. Go reports the median of three
`testing` runs, using five source, layout, or copy calls and 10,000 cache or
view calls per run, and includes standard allocation metrics

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui-widgets --bench diff_view
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkDiff(Document|Layout|Copy)100K$' -benchmem -benchtime=5x -count=3 ./widget
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkDiff(LayoutCache100K|ViewViewport)$' -benchmem -benchtime=10000x -count=3 ./widget
```

The root `make bench` command includes all paths

### Reference results

Results recorded on 2026-08-12 in the reference environment above

| Implementation | Path | Source lines | Constructed rows or output bytes | Median time | Allocations | Allocated bytes |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Rust | document preparation | 100,000 | not applicable | 6.533 ms | not measured | not measured |
| Go | document preparation | 100,000 | not applicable | 4.007 ms | 10 | 17,129,664 |
| Rust | terminal layout | 100,000 | 100,000 rows | 4.098 ms | not measured | not measured |
| Go | terminal layout | 100,000 | 100,000 rows | 4.896 ms | 4 | 8,806,560 |
| Rust | warmed layout cache | 100,000 | 0 rows | 4 ns | not measured | not measured |
| Go | warmed layout cache | 100,000 | 0 rows | 14.05 ns | 0 | 0 |
| Rust | complete unified copy | 100,000 | 2,800,000 bytes | 0.834 ms | not measured | not measured |
| Go | complete unified copy | 100,000 | 2,800,000 bytes | 1.022 ms | 1 | 2,801,664 |
| Rust | bounded view | 8 | 8 rows | 35,538 ns | not measured | not measured |
| Go | bounded view | 8 | 8 rows | 41,163 ns | 147 | 11,544 |
| Rust | bounded view | 100,000 | 8 rows | 35,826 ns | not measured | not measured |
| Go | bounded view | 100,000 | 8 rows | 41,028 ns | 181 | 11,944 |

Diff source preparation is intentionally linear and retains typed line
metadata plus the marker-free CodeDocument projection used by CodeLayout. It
does not retain a second complete marker-prefixed unified string. Complete copy
therefore performs one output-sized allocation in Go and equivalent owned
output construction in Rust only when requested

Increasing the source from 8 to 100,000 lines does not add proportional
controlled-view construction time. The fixed Go allocation difference comes
from formatting wider old and new line-number fields and longer derived row
identities around the midpoint selection. Terminal layout remains linear in
the complete projected source and retains one CodeVisualRow per no-wrap logical
line, matching the CodeView projection contract

## SplitPane, Drawer, StatusBar, and Toast purpose

This benchmark constructs five controlled view compositions: one SplitPane
with focus and resize handlers, one closed Drawer, one open modal Drawer, one
three-slot StatusBar, and one ToastRegion containing eight configured records
with a visible limit of three. Each pane, slot, drawer body, or visible Toast
body contains one fixed text Node. The measured path covers widget composition
and Core Node construction, but excludes Runtime preparation, layout,
rendering, terminal I/O, pointer dispatch, timer delivery, and application
update

Rust reports the median of 12 samples containing 10,000 constructions each. Go
reports the median of three `testing` runs with 10,000 constructions each and
includes standard allocation metrics

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui-widgets --bench split_pane_drawer
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^Benchmark(SplitPane|Drawer(Closed|Open)|StatusBar|ToastRegion)' -benchmem -benchtime=10000x -count=3 ./widget
```

The root `make bench` command includes these paths

### Reference results

Results recorded on 2026-08-13 in the reference environment above

| Implementation | Path | Median time per construction | Allocations | Allocated bytes |
| --- | --- | ---: | ---: | ---: |
| Rust | SplitPane | 999 ns | not measured | not measured |
| Rust | closed Drawer | 72 ns | not measured | not measured |
| Rust | open Drawer | 374 ns | not measured | not measured |
| Rust | three-slot StatusBar | 179 ns | not measured | not measured |
| Rust | eight-record, three-visible ToastRegion | 952 ns | not measured | not measured |
| Go | SplitPane | 1,706 ns | 24 | 3,769 |
| Go | closed Drawer | 231.1 ns | 1 | 640 |
| Go | open Drawer | 1,188 ns | 11 | 4,488 |
| Go | three-slot StatusBar | 838.8 ns | 3 | 2,224 |
| Go | eight-record, three-visible ToastRegion | 1,728 ns | 30 | 7,248 |

The SplitPane and Drawer paths are constant in pane count. The closed Drawer
takes the base-node path and omits modal, border, action, and overlay
composition. Deterministic tests separately verify that a closed Drawer does
not invoke its body builder and that an automatically omitted SplitPane child
is excluded from semantic preparation, focus routing, rendering, and lazy
virtual construction. StatusBar construction is linear in configured slot
count. ToastRegion retains and scans configured records linearly but invokes at
most the visible-limit body builders

## Terminal task round-trip purpose

This benchmark measures one warmed application-requested terminal task from
the initial Message through Effect scheduling, synchronous execution on the
Runtime driver, result delivery, and the final application update. The task
returns immediately and the application declares no Subscriptions

The measured path excludes terminal mode changes, VT lifecycle writes,
terminal-size queries, input decoding, rendering, external-process execution,
and user interaction. Those costs depend on the terminal, operating system,
and application-selected operation. The benchmark therefore isolates Nagi's
framework CPU and transient-memory cost rather than the duration of a real
suspended terminal session

Rust reports the median of 12 samples containing 10,000 round trips each and
tracks allocation count, allocated bytes, peak additional live bytes, and
retained bytes. Go reports the median of three one-second `testing` runs with
standard allocation metrics

Run only these benchmarks from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-tui --bench terminal_task
GOWORK="$PWD/go.work" GOTOOLCHAIN=local go test -C nagitui-go -run '^$' -bench '^BenchmarkTerminalTaskRoundTrip$' -benchmem -benchtime=1s -count=3 .
```

The root `make bench` command includes both paths

### Reference results

Results recorded on 2026-08-13 in the reference environment above

| Implementation | Median time per round trip | Allocations | Allocated bytes | Peak additional live bytes | Retained bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Rust | 385 ns | 1 | 24 | 24 | 0 |
| Go | 359.6 ns | 4 | 200 | not measured | not measured |

The Rust allocation owns the cooperative cancellation state for the pending
task. The Go path derives a cancellable `context.Context` from the Runtime's
parent context and accounts for its cancellation state. Empty Subscription
polls and ready-Message transfer do not allocate intermediate maximum-capacity
buffers. Both implementations keep task queues and Runtime message storage
warmed across calls

These values are directional framework baselines, not estimates of editor,
shell, browser, authentication, or other application-selected work

## Enhanced keyboard input purpose

This benchmark measures one warmed Kitty keyboard protocol report,
`CSI 97;2:1;65u`, representing a Shift-modified logical `a` key with associated
text `A`

- Each call feeds one complete sequence into a persistent VT Decoder, validates
  one normalized Key Event, and drops the owned result
- The measured path includes streaming state transitions, decimal parsing,
  modifier and action normalization, associated-text construction, and Event
  collection allocation
- It excludes terminal I/O, capability querying, Runtime routing, application
  update, and rendering
- Recognized sequence scratch storage is warmed before sampling and retained at
  no more than the 4,096-byte VT sequence limit. Unit tests separately verify
  that a large paste buffer is not retained as sequence scratch

Run only this benchmark from the superproject root

```sh
cargo bench --manifest-path nagi-rs/Cargo.toml -p nagi-vt --bench input
GOWORK=off GOTOOLCHAIN=local go test -C nagi-go -run '^$' -bench '^BenchmarkDecoderKittyKey$' -benchmem -benchtime=1s -count=3 ./vt
```

The root `make bench` command includes both paths

### Reference results

Results recorded on 2026-08-13 in the same reference environment

| Implementation | Median time per key | Allocations per key | Allocated bytes per key |
| --- | ---: | ---: | ---: |
| Rust | 205 ns | 2 | 200 |
| Go | 126.4 ns | 2 | 136 |

Both measured allocations belong to the returned Event collection and its
associated text. The decoder reuses recognized control-sequence storage after
warm-up. Rust allocation tracking uses benchmark-local atomic counters, so the
timings are directional CPU measurements rather than a cross-language latency
ranking

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

SuggestionPopup tests validate duplicate rejection, immutable input ownership,
shared storage after copy, O(1) indexed selection, exact visible-row builder
bounds, and zero candidate-row builds for loading and empty notices. The Go
placement regression additionally verifies zero allocations for 1,000 warmed
AnchoredOverlay geometry resolutions

JSONInspector tests share typed-document and controlled-interaction fixtures
across Rust and Go. They cover all JSON scalar kinds, escaped paths, deterministic
compact serialization, duplicate-key rejection, resource limits, selection
normalization, collapse and expansion, hidden descendants, repeat handling,
pointer activation, syntax styles, truncated previews, and complete copy
payloads. Runtime tests verify action routing, controlled state messages,
repeat consumption, pointer activation, and copy callback behavior.
Bounded-view tests verify that inspector row construction depends on the
configured viewport rather than the complete expanded document

Content projection shares 15 rendering and failure fixtures across Rust and
Go. They cover inline style inheritance, Paragraph wrapping and alignment,
Flow and Sequence boundaries, Length, display override, ignored Inline box
properties, HardBreak, semantic-boundary separation, identity and annotation
non-mapping, and all structured resource failures. Go additionally compares
retained heap after two 512-projection windows with a 1 MiB runtime-noise
tolerance. The Rust projection benchmark reports zero retained bytes for both
paths

Prompt tests share exact transcripts, returned values, error categories, and
ordered visible or secret input modes. Unix backend tests cover bounded line
draining, cancellation while waiting without input, complete terminal-state
restoration after Secret success, and restoration during stack unwinding. Go
also injects a restoration failure and verifies that it is returned

SelectableText pointer fixtures share left press, Shift extension, capture
across controlled view rebuilds, release, disabled and non-left pass-through,
word wrapping, CRLF and empty lines, alignment, wide and combining graphemes,
CJK width, clipped drag, and vertical and horizontal edge scrolling. The long
Paragraph allocation tests verify that a warmed 100,000-byte hit lookup and
event route allocate no transient memory in either implementation

The text implementations retain their materialized APIs while exposing
streaming grapheme and wrapped-line APIs for allocation-sensitive paths. Shared
Unicode conformance fixtures verify that the streaming segmentation preserves
the existing Unicode behavior. Runtime tree indexes and linear layout results
reuse frame-local capacity while keeping the current successful semantic tree
available if a later build fails

Runtime tests also cover reusable terminal frame storage, empty output for an
unchanged frame, allocation-preserving append encoding, explicit no-redraw
Effects, and Batch wake-up coalescing until its delivery boundary

Terminal task regression tests cover Sequence and Batch ordering, panic
recovery, scoped cancellation, repeated cancellation without stale queue
growth, parent-context inheritance, decoder reset, full redraw invalidation,
and Unix suspend/resume failure recovery. Allocation checks keep the warmed
Rust round trip at one cancellation-state allocation and the Go path at no more
than four allocations

These checks cover CPU and memory structure for the virtualized path and the
state transitions around terminal I/O and event-loop wake-ups. They do not
measure a real terminal emulator or operating-system wake-up rate, which still
require workload-specific measurement
