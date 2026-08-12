# Unix terminal session

The terminal loop owns TTY validation, raw-mode setup, original-mode
restoration, readable input, output writes, terminal size, resize signaling,
and alternate-screen lifecycle

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
- Opening a session enters the alternate screen, hides the cursor, and enables
  bracketed paste and focus reporting using typed VT operations. It also
  enables the configured SGR mouse tracking policy when present; mouse tracking
  is disabled by default so terminal text selection remains available
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

## Temporary suspension

An application can request a temporary full-screen suspension through the
generic terminal-suspending Effect. Nagi does not select or launch a particular
editor, shell, browser, authentication flow, or other child process

- Before the task starts, the terminal runner disables known mouse modes,
  focus reporting, and bracketed paste, resets style, shows the cursor, leaves
  the alternate screen, and restores the original terminal attributes
- Resize signaling and Runtime ownership remain active while suspended.
  Existing Effect workers, Subscription producers, clocks, bounded queues, and
  cancellation contexts continue their normal lifecycle, but application
  updates and rendering wait because the terminal driver thread is occupied
- After the task returns or its panic is recovered, the runner re-enters raw
  mode and its configured alternate-screen, cursor, bracketed-paste, focus, and
  optional mouse modes. It reads the current terminal size, discards incomplete
  pre-suspension input, invalidates the surface-diff baseline, and performs a
  full redraw at the next frame boundary
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
  resets style, shows the cursor, leaves the alternate screen, restores the
  original terminal attributes, and releases resize signaling
- Restoration is idempotent and continues after an individual cleanup failure,
  returning the first error when the language runtime permits it
- Process abort, `SIGKILL`, power loss, `/dev/tty` acquisition, job-control
  suspension of the Nagi process, and nested sessions are not supported

## Supported systems and errors

- OS errors are retained as wrapped error sources for diagnostics
- Terminal sessions support Linux and macOS on x86-64 and ARM64 only
