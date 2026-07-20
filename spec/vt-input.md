# VT input

The VT decoder is a pure streaming state machine. It MUST NOT own I/O, file
descriptors, threads, timers, or real-time sleeps

Normalized events include keys, text, paste, mouse, focus changes,
terminal responses, and unknown-sequence diagnostics. Resize events come from
the Unix terminal layer rather than the VT decoder

- Key events preserve available logical key, modifiers, action, associated text,
  and protocol information
- Information not supplied by the terminal remains explicitly unknown
- A lone ESC byte creates pending state
- The runtime owns the ESC deadline and resolves it through `flush_pending()`
- Appending input with any byte chunk boundaries MUST produce the same final
  event sequence
- Malformed input MUST NOT panic

Ordinary text emits one event per valid Unicode scalar, independent of feed
chunk boundaries. Each maximal run of invalid UTF-8 produces one U+FFFD event,
including when the run crosses chunks. Bracketed paste produces one event for
the complete normalized payload

Legacy C0, CSI, and SS3 keys have `unknown` action because those protocols do
not distinguish press, repeat, and release. An ESC followed directly by a
printable scalar is an Alt-modified character key with associated text. A lone
ESC remains pending until more input arrives or `flush_pending()` resolves it

Input coordinates from SGR mouse reports are converted from the protocol's
one-based values to zero-based cell coordinates. The xterm modifier parameter
uses Shift, Alt, Control, and Meta bit order; the SGR mouse Meta/Alt bit is
reported as Alt because the legacy protocol cannot distinguish them

The decoder recognizes:

- C0 Enter, Tab, Backspace, Control-character keys, and DEL Backspace
- Normal and application cursor keys, Home, End, Insert, Delete, Page Up,
  Page Down, F1 through F12, and xterm modifier parameters
- `CSI 200~` and `CSI 201~` bracketed paste delimiters
- SGR mouse reports `CSI < Cb ; Cx ; Cy M` and release final `m`
- Focus reports `CSI I` and `CSI O`
- Cursor-position, device-attribute, status, and window responses retained as
  original bytes
- OSC and other string responses terminated by BEL or ST

Unsupported complete sequences and incomplete sequences resolved by
`flush_pending()` become `UnknownSequence` with bounded original bytes. CSI,
SS3, and control strings are bounded to 4,096 bytes. Paste payloads are bounded
to 1,048,576 bytes; an oversized paste emits one diagnostic event and is
discarded through its terminator

Protocol coverage includes printable UTF-8, C0 controls, navigation and basic
function keys, xterm modifier variants, bracketed paste, SGR mouse, and focus
in/out. Extended keyboard protocols are not supported

The xterm sequence definitions are the protocol reference for these legacy
extensions: [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
