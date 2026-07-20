# Unicode and terminal text

## Text unit

- Public text APIs accept UTF-8
- User-perceived text operations use extended grapheme clusters rather than
  Rust `char` values or Go runes
- Text is not normalized implicitly
- Both implementations use Unicode 17.0.0 data

## Generated data

The libraries embed grapheme break, emoji, East Asian Width, and required
sequence tables derived from official Unicode 17.0.0 data. Consumer builds MUST
NOT require network access or generator execution

## Width profiles

`Modern` treats ambiguous characters as one cell. `Cjk` treats ambiguous
characters as two cells. Wide, fullwidth, and emoji-presentation clusters are
normally two cells in both profiles. Controls and clusters made only from
non-spacing extenders occupy zero cells. A custom profile layers a per-grapheme
override over either base profile and can return zero, one, or two cells

## Cell-based operations

- Width, truncation, wrapping, and positions are evaluated only at extended
  grapheme cluster boundaries
- Truncation returns the longest grapheme-aligned prefix that does not exceed
  the supplied cell limit
- Wrapping is deterministic hard wrapping. It does not perform word breaking
- CR, LF, and CRLF force a line boundary and are not included in returned lines
- A grapheme wider than the line limit occupies a line by itself. This rule
  also guarantees progress for a zero-cell line limit
- Byte-to-cell conversion succeeds only for a grapheme boundary
- Cell-to-byte conversion succeeds only for an exact cell boundary and returns
  the earliest matching byte boundary when zero-width graphemes create more
  than one match
- Previous and next cursor movement return the nearest strict grapheme boundary
  and accept offsets inside a UTF-8 sequence or grapheme

## Text-library responsibilities

The text libraries own grapheme iteration, boundaries, cell width, cell-based
truncation and wrapping, byte-to-cell position conversion, and grapheme cursor
movement. They do not own widgets, selection, clipboard, IME lifecycle, styles,
or keymaps

At byte-oriented decoding boundaries, each maximal invalid UTF-8 subsequence is
replaced by one U+FFFD. Rust and Go MUST expose the same result
