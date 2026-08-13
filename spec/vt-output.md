# VT output

The output encoder is pure and maps terminal operations to bytes

Operations cover cursor movement and visibility, style changes, text
writes, erasure, alternate-screen lifecycle, bracketed paste, mouse reporting,
clipboard writes, synchronized updates, and typed terminal capability queries

- Widgets and views MUST NOT emit ANSI or VT byte strings directly
- The renderer converts surface differences into terminal operations
- Equal cell content and cursor state produce an empty operation sequence
- A surface MUST NOT be passed directly to the encoder
- Capability-dependent unsupported operations are omitted or reduced to a safe
  baseline
- Encoding the same operation sequence and capability set MUST produce identical
  bytes in Rust and Go
- Encoding MAY append into caller-owned storage; the appended bytes MUST equal
  standalone encoding for the same operations and capabilities

Absolute positions are zero-based at the API and encoded as one-based CUP
coordinates. Relative motion emits vertical movement before horizontal
movement. Erasure uses the standard after, before, and all parameters

An encoder call MAY supply an origin for a bounded terminal viewport. The
origin is added only to absolute positions, saturating each coordinate at the
unsigned 32-bit maximum. Relative movement and every other operation remain
unchanged. Cursor-position requests use DSR `CSI 6 n`. Next-line movement uses
NEL `ESC E`, moves to column zero, and scrolls when the cursor is at the bottom
margin

`SetStyle` resets existing SGR state and then emits foreground, background,
optional underline color, and enabled attributes in canonical order. The color
capability is an ordered maximum: monochrome suppresses non-default color,
ANSI 16 reduces indexed and RGB values to standard or bright SGR colors,
indexed 256 reduces RGB values deterministically to the 6 by 6 by 6 color cube,
and true color preserves 24-bit values. The baseline is indexed 256 for
compatibility when detection is disabled. Unsupported underline colors, cursor
shapes, and synchronized updates are omitted. Modern capabilities preserve
24-bit and underline colors and enable DECSCUSR and synchronized updates

ANSI 16 reduction retains source indices 0 through 15. Other indexed and RGB
colors set the red, green, and blue ANSI bits at the midpoint of their source
range and select the bright bank when a cube component reaches its maximum.
Dark and light grayscale palette entries map to black and bright white.
Underline colors are omitted below indexed 256 because ANSI 16 has no matching
underline-color SGR form

`WriteText` is not a raw-byte escape hatch. Invalid UTF-8 at the Go boundary and
Unicode C0, DEL, or C1 control characters are replaced with U+FFFD before
encoding. This prevents view text from injecting terminal control sequences

Mode operations use alternate screen `1049`, bracketed paste
`2004`, focus reports `1004`, SGR mouse encoding `1006` with tracking modes
`1000`, `1002`, or `1003`, and synchronized updates `2026`. Disabling mouse
reporting resets every supported tracking mode and SGR encoding

Keyboard capability operations encode Primary Device Attributes as `CSI c`,
the Kitty keyboard flag query as `CSI ? u`, a flag-stack push as
`CSI > flags u`, and a flag-stack pop as `CSI < u`. Nagi's standard enhanced
keyboard mode uses flags 1, 2, 8, and 16, whose combined numeric value is 27:
disambiguated escape codes, event types, reporting all keys as escape codes,
and associated text. The alternate-key flag is not requested. Unknown flag
bits are omitted at the typed operation boundary. The protocol definition is
[Kitty keyboard protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)

`SetClipboard` is an explicit write-only OSC 52 operation for the standard
clipboard selection `c`. It normalizes invalid UTF-8 at the Go boundary,
encodes the resulting UTF-8 bytes as unwrapped RFC 4648 Base64, and uses the
canonical `ESC \\` String Terminator. Empty text emits an empty payload and may
clear the terminal clipboard. The encoder does not expose clipboard reads,
selection queries, arbitrary OSC parameters, or multiplexer passthrough

The encoder deliberately has no public raw escape-sequence operation. Terminal
behavior must be represented by a typed operation

Legacy and xterm extension encodings follow
[XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
and the DEC/ANSI cursor and erasure baseline summarized by the
[VT510 reference](https://vt100.net/docs/vt510-rm/chapter4.html)
