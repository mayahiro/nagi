# VT output

The output encoder is pure and maps terminal operations to bytes

Operations cover cursor movement and visibility, style changes, text
writes, erasure, alternate-screen lifecycle, bracketed paste, mouse reporting,
and synchronized updates

- Widgets and views MUST NOT emit ANSI or VT byte strings directly
- The renderer converts surface differences into terminal operations
- A surface MUST NOT be passed directly to the encoder
- Capability-dependent unsupported operations are omitted or reduced to a safe
  baseline
- Encoding the same operation sequence and capability set MUST produce identical
  bytes in Rust and Go

Absolute positions are zero-based at the API and encoded as one-based CUP
coordinates. Relative motion emits vertical movement before horizontal
movement. Erasure uses the standard after, before, and all parameters

`SetStyle` resets existing SGR state and then emits foreground, background,
optional underline color, and enabled attributes in canonical order. Baseline
capabilities reduce RGB values deterministically to the 6 by 6 by 6 indexed
color cube. Unsupported underline colors, cursor shapes, and synchronized
updates are omitted. Modern capabilities preserve 24-bit and underline colors
and enable DECSCUSR and synchronized updates

`WriteText` is not a raw-byte escape hatch. Invalid UTF-8 at the Go boundary and
Unicode C0, DEL, or C1 control characters are replaced with U+FFFD before
encoding. This prevents view text from injecting terminal control sequences

Mode operations use alternate screen `1049`, bracketed paste
`2004`, focus reports `1004`, SGR mouse encoding `1006` with tracking modes
`1000`, `1002`, or `1003`, and synchronized updates `2026`. Disabling mouse
reporting resets every supported tracking mode and SGR encoding

The encoder deliberately has no public raw escape-sequence operation. Terminal
behavior must be represented by a typed operation

Legacy and xterm extension encodings follow
[XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html)
and the DEC/ANSI cursor and erasure baseline summarized by the
[VT510 reference](https://vt100.net/docs/vt510-rm/chapter4.html)
