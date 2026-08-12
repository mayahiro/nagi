# Event routing

## Keyboard and text

The routing order is

1. Active modal or portal
2. Focused node
3. Ancestors of the focused node
4. Screen or root handler
5. Global handler
6. Unhandled

The last modal in rendered logical order is active. While a modal is active,
keyboard, text, paste, and pointer targets outside its subtree are replaced by
the modal root. Routing still continues from a target inside the modal through
the modal's ancestors to the screen or root handler unless a handler consumes
the event

An identified Node MAY declare a hard unhandled-Event boundary. Actions,
built-in handling, the geometry-aware pointer handler, and the raw handler on
that Node retain their ordinary order. If the Event is still unhandled
afterward, the boundary consumes it and prevents ancestor raw handlers and
terminal fallback mapping. The default has no hard boundary, and this behavior
is independent from KeyMap propagation boundaries

Within each target-to-root Node, Node-declared semantic key actions run before
Runtime-owned Core semantic actions, non-key Core input handling, the
geometry-aware pointer handler for mouse input, and the raw handler. Action
propagation boundaries affect Node-declared and Core semantic ancestor groups,
but not pointer or raw routing. The complete order and conflict rules are
defined by the [scoped key-map specification](keymap.md)

## Pointer

- Hit testing proceeds from the frontmost stack or overlay entry
- An AnchoredOverlay indexes its base before its front layer. Both remain
  logical children of the identified AnchoredOverlay root, so their events use
  ordinary target-to-root routing and the layer does not create a modal scope
- Clipped regions do not receive pointer hits
- Pointer capture routes events to the capture node
- Capture is released when its node disappears
- Pointer hit testing is restricted to the active modal subtree and falls back
  to the modal root when no descendant is hit
- A geometry-aware pointer handler runs after semantic actions and non-key Core
  handling but before the raw Event handler on the same Node. Ignoring it
  preserves raw and ancestor routing
- Its context contains the normalized MouseEvent, signed Node-local position,
  Node size, clipped Node-local visible rectangle, Runtime WidthProfile,
  capture ownership, and the nearest initialized ancestor ScrollViewport
- A RichText or Paragraph Node additionally resolves the hit rendered
  grapheme as its start and end UTF-8 byte boundaries. Empty visual line
  regions resolve to one collapsed line boundary. Other Node kinds have no
  text hit
- Pointer capture may produce Node-local coordinates outside the Node size and
  clip. Paragraph hit resolution clamps rows above and below the layout to the
  document boundaries and columns outside a line to that line's boundaries
- The nearest ScrollViewport context can derive a request for a Move Event that
  moves each enabled axis by at most one Cell when the pointer is at the
  corresponding visible edge. Other Event kinds do not derive edge scrolling.
  It does not schedule a timer or continue scrolling without a new Event

Handlers must be able to ignore or consume an event, emit a message, request or
release focus, capture or release the pointer, request one ScrollViewport
offset, and request a redraw. The public result is a composable value rather
than one mutually exclusive action. The latest scroll request in one result
wins. Runtime clamps an applicable request immediately, queues explicit result
messages first and an optional ScrollViewport callback message second, then
coalesces rendering normally

TextInput cursor offsets are UTF-8 byte offsets at extended grapheme cluster
boundaries. Insertion, paste, movement, Backspace, and Delete never split a
cluster. An invalid or intra-cluster cursor is normalized to the preceding
boundary before an edit

Interaction State for TextInput cursor and ScrollViewport offset is keyed by a
stable Node ID and is retired with that node

Default keyboard and wheel scrolling uses the nearest applicable
ScrollViewport on the target-to-root route. A focused descendant therefore
scrolls its containing viewport even when the descendant handles no scrolling
itself. PageUp and PageDown move by that viewport's visible height rather than
the terminal height. Keyboard scrolling is exposed through the Core semantic
actions in the [scoped key-map specification](keymap.md); wheel input remains
non-key Core handling
