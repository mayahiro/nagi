# Unix terminal session

The terminal loop owns TTY validation, raw-mode setup, original-mode
restoration, readable input, output writes, terminal size, resize signaling,
and full-screen or inline viewport lifecycle

## Session contract

- The terminal loop uses stdin for input and stdout for output. Both descriptors
  MUST be terminals or opening the session fails without entering raw mode
- Only one Nagi TUI terminal session may be active in a process. Nested sessions
  return an explicit error
- Raw mode starts from the attributes returned by the operating system and
  applies the `cfmakeraw` contract: input translation and flow control, output
  processing, canonical input, echo, terminal-generated signals, and extended
  processing are disabled; character size is eight bits; `VMIN` is one and
  `VTIME` is zero
- The default viewport owns the complete terminal and enters the alternate
  screen. An inline viewport instead owns the complete terminal width and a
  positive requested row count on the normal screen. Its effective height is
  clamped to the current terminal height
- Opening either viewport hides the cursor and enables bracketed paste and
  focus reporting using typed VT operations. It also enables the configured
  SGR mouse tracking policy when present; mouse tracking is disabled by default
  so terminal text selection remains available
- Clipboard output is disabled by default. When the terminal runner explicitly
  selects OSC 52, it appends the latest pending clipboard request to the same
  serialized output boundary as a rendered frame. It never queries clipboard
  contents
- Reads and writes retry interrupted system calls. Writes continue until all
  bytes are written or an error occurs
- A zero timeout performs an immediate readiness check. Positive waits do not
  return ready unless input or hangup is observable
- Terminal size is returned as nonzero columns and rows. A zero dimension is an
  explicit invalid-data error
- Resize signals are coalesced into a Boolean pending state. A newly opened
  session reports one initial resize so layout establishes its starting size

## Inline viewport

An inline viewport integrates a short interactive application with ordinary
command output without giving the Runtime terminal-global coordinates

- The runner requests a Cursor Position Report with typed DSR output and uses
  the reported cursor row as the initial viewport origin. The query has a
  caller-configurable timeout. Failure, EOF, malformed-only responses, or more
  than 65,536 retained input bytes is a terminal error
- Input read while waiting for the report is preserved in original byte order,
  except for the first valid report itself, and is delivered to the normal
  decoder before waiting for more operating-system input
- The runner reserves rows after the cursor with typed next-line operations.
  When the requested region crosses the bottom margin, normal-screen rows
  scroll into terminal history and the viewport origin moves upward by the
  same count
- Surface and Runtime coordinates remain zero-based and local to the viewport.
  The serialized output boundary adds the viewport origin only to absolute
  cursor positions. Relative operations and non-position operations are not
  translated
- A hidden application cursor is parked at the viewport origin after each
  frame. A visible cursor retains its local row. This known offset is used when
  resize recomputes placement from a new Cursor Position Report. Resize clears
  from the recomputed origin through the visible display, invalidates the
  previous Surface, and performs a complete local redraw
- Mouse events inside the current viewport are translated to local rows. Mouse
  events outside its width or row interval are consumed by the terminal driver
  and do not reach Node routing or the application event mapper
- Restoration leaves the final application cells on the normal screen and
  moves the cursor to a fresh line immediately after the viewport. When that
  line is below the bottom margin, one next-line operation scrolls the final
  frame upward; every row remains in the normal-screen history even when the
  viewport occupied the full display
- Inline mode does not provide arbitrary fixed-region ownership, concurrent
  writes from another terminal producer, or insertion of application output
  above a live viewport. Applications use Nodes, messages, and Subscriptions
  for live content, or temporarily suspend the terminal before external output

## Temporary suspension

An application can request temporary terminal suspension through the generic
terminal-suspending Effect. Nagi does not select or launch a particular
editor, shell, browser, authentication flow, or other child process

- Before the task starts, the terminal runner disables known mouse modes,
  focus reporting, and bracketed paste, resets style, shows the cursor, leaves
  the alternate screen for a full-screen viewport or finalizes an inline
  viewport, and restores the original terminal attributes
- Resize signaling and Runtime ownership remain active while suspended.
  Existing Effect workers, Subscription producers, clocks, bounded queues, and
  cancellation contexts continue their normal lifecycle, but application
  updates and rendering wait because the terminal driver thread is occupied
- After the task returns or its panic is recovered, the runner re-enters raw
  mode and its configured screen, cursor, bracketed-paste, focus, and optional
  mouse modes. Full-screen mode re-enters the alternate screen. Inline mode
  reserves a new region after external output and leaves the previous final
  frame in history. The runner reads the current viewport size, discards
  incomplete pre-suspension decoder state, invalidates the surface-diff
  baseline, and performs a full redraw at the next frame boundary
- If one decoded input chunk requested suspension, remaining decoded Events
  from that chunk are discarded instead of being routed into the resumed view
- A suspension failure prevents the task from starting. A resume failure is a
  terminal-loop error; the task result is not delivered to application update
  and final restoration remains best effort
- Suspension and resume operations are idempotent at the session boundary.
  Process abort and operating-system termination still cannot be recovered

## Restoration

Normal exit, error exit, and panic unwinding perform best-effort restoration

Application-driven normal exit renders the final dirty application view before
restoration. An external cancellation mechanism, when exposed by the language
API, also restores the session before returning its cancellation result

- Restoration disables known mouse modes, focus reporting, and bracketed paste,
  resets style, shows the cursor, leaves the alternate screen when active or
  finalizes an inline viewport, restores the original terminal attributes, and
  releases resize signaling
- Restoration is idempotent and continues after an individual cleanup failure,
  returning the first error when the language runtime permits it
- Process abort, `SIGKILL`, power loss, `/dev/tty` acquisition, job-control
  suspension of the Nagi process, and nested sessions are not supported

## Supported systems and errors

- OS errors are retained as wrapped error sources for diagnostics
- Terminal sessions support Linux and macOS on x86-64 and ARM64 only
