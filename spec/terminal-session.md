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
- Reads and writes retry interrupted system calls. Writes continue until all
  bytes are written or an error occurs
- A zero timeout performs an immediate readiness check. Positive waits do not
  return ready unless input or hangup is observable
- Terminal size is returned as nonzero columns and rows. A zero dimension is an
  explicit invalid-data error
- Resize signals are coalesced into a Boolean pending state. A newly opened
  session reports one initial resize so layout establishes its starting size

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
- Process abort, `SIGKILL`, power loss, `/dev/tty` acquisition, suspend/resume,
  and nested sessions are not supported

## Supported systems and errors

- OS errors are retained as wrapped error sources for diagnostics
- Terminal sessions support Linux and macOS on x86-64 and ARM64 only
