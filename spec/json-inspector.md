# JSON inspector

JSON support is an optional source adapter and standard widget. JSON does not
become a Core Node, Content kind, Presentation selector, application message,
or clipboard backend

## Typed JSON source

The source model has Null, Boolean, Number, String, Array, and Object values

- A Number owns one validated JSON number token and preserves its spelling.
  Validation accepts the JSON grammar only and does not convert through a host
  floating-point type
- A String owns valid UTF-8. Go replaces each invalid UTF-8 run before storing
  a string or object key; Rust input is valid UTF-8 by type
- An Array owns its ordered values
- An Object owns ordered key-value members and rejects a duplicate normalized
  key with a structured error
- Value clones and copies share immutable storage. Input slices are not
  retained where the host language allows later mutation
- The initial API is a typed builder, not a JSON text parser or an adapter to a
  particular third-party JSON value type

A JsonDocument validates one root value and creates an immutable preorder
index plus one deterministic compact serialization

- Root path is the empty JSON Pointer
- Object paths append an RFC 6901 escaped key segment. Array paths append one
  base-10 index segment
- Every path is unique because duplicate object keys are rejected
- A document node exposes kind, path, zero-based depth, direct child count,
  optional object key or array index, and the complete compact serialization
  of that value
- Object member order and number spelling are preserved. Insignificant source
  whitespace is outside the typed model
- Limits bound node occurrences, one-based depth, decoded string and key
  bytes, and complete serialized bytes before the preorder index is published
- Default limits are 100,000 nodes, depth 128, 16 MiB of decoded string bytes,
  and 32 MiB of serialized bytes. The hard supported depth is 256

## Controlled widget

JsonInspector receives a stable root Node ID, one JsonDocument, controlled
selected and expanded JSON Pointers, and application callbacks

- Zero state selects and expands the root
- A missing selected path normalizes visually to the root. A selected path
  hidden below a collapsed ancestor normalizes to the outermost collapsed
  ancestor. Normalization emits no Message
- Empty Arrays and Objects are leaves for interaction. Non-empty Arrays and
  Objects are branches
- The visible order is document preorder with each collapsed subtree skipped
- The root is one Tab stop. Candidate rows have stable identities derived from
  the inspector root and complete JSON Pointer, but do not become Tab stops
- Activate toggles a selected branch. Up and Down select adjacent visible
  nodes. Home and End select the first and last visible nodes. Left collapses
  an expanded branch or selects its parent. Right expands a collapsed branch
  or selects its first child
- Navigation bindings accept explicit Repeat. Activate and an enabled Copy
  accept only an initial press; unmatched repeats of those enabled bindings are
  consumed locally. Copy is disabled-pass-through without an application
  callback
- Enabled left-button press selects a row and toggles it when it is a branch,
  emitting at most one complete next-state Message
- A positive viewport height bounds constructed rows and follows the selected
  row. Zero constructs every visible row
- String and Number previews are truncated only at extended grapheme
  boundaries after a configurable positive limit and receive one ellipsis.
  The document and Copy request always retain complete JSON text
- Copy emits the selected path, kind, and an independently owned complete
  compact JSON value to the application. Retaining a request does not retain
  the complete source document. The widget performs no clipboard I/O
- Key, String, Number, Boolean, Null, punctuation, array index, summary,
  selection, focus, and disabled styles are independent replaceable slots
- Sensitive-value detection and redaction MUST happen before JsonValue
  construction. The document and Copy request retain the complete supplied
  value
- JsonInspector starts no worker, timer, Subscription, Effect, parser, or I/O

The component has no Agent, Tool, Event, settings-schema, provider, policy, or
credential semantics
