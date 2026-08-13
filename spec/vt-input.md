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

The decoder defaults to legacy modifier semantics. A caller that has enabled
Kitty keyboard mode MUST configure the decoder accordingly. This mode is
needed for the Kitty function-key form because a press may omit its event-type
subfield: for example, `CSI 1 ; 9 A` means Meta+Up under the legacy xterm
mapping but Super+Up while Kitty mode is active. Unambiguous `CSI u` reports
are decoded as Kitty input in either mode. The standard terminal runner changes
the decoder mode only after a successful Kitty query and preserves it when
discarding pending input across terminal suspend and resume

The decoder recognizes:

- C0 Enter, Tab, Backspace, Control-character keys, and DEL Backspace
- Normal and application cursor keys, Home, End, Insert, Delete, Page Up,
  Page Down, F1 through F12, and xterm modifier parameters
- Kitty keyboard protocol `CSI u` key reports, including explicit press,
  repeat, and release actions; Shift, Alt, Control, Super, Hyper, Meta,
  Caps Lock, and Num Lock modifiers; associated text; F13 through F35; and
  otherwise unmapped Kitty functional key numbers
- `CSI 200~` and `CSI 201~` bracketed paste delimiters
- SGR mouse reports `CSI < Cb ; Cx ; Cy M` and release final `m`
- Focus reports `CSI I` and `CSI O`
- Cursor-position, device-attribute, status, window, and Kitty keyboard flag
  responses retained as original bytes
- OSC and other string responses terminated by BEL or ST

For Kitty reports, the primary code point selects the logical key. A primary
code point of zero is allowed only when valid associated text is present and
produces an unknown logical key with that text. Associated text is normalized
to Unicode scalars and rejects C0, DEL, and C1 controls. A key report with an
alternate-key-code subfield is rejected as an unknown sequence because Nagi
does not request or expose the alternate-key reporting flag. Lock modifiers
remain observable on `KeyEvent`; key-map stroke normalization may ignore them
when matching logical application actions

Unsupported complete sequences and incomplete sequences resolved by
`flush_pending()` become `UnknownSequence` with bounded original bytes. CSI,
SS3, and control strings are bounded to 4,096 bytes. Paste payloads are bounded
to 1,048,576 bytes; an oversized paste emits one diagnostic event and is
discarded through its terminator

Protocol coverage includes printable UTF-8, C0 controls, navigation and basic
function keys, xterm modifier variants, bracketed paste, SGR mouse, and focus
in/out. It also includes the subset of the Kitty keyboard protocol selected by
Nagi's typed enhancement flags. The protocol definition is
[Kitty keyboard protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)

The xterm sequence definitions are the protocol reference for these legacy
extensions: [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
