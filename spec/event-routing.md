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

Within each target-to-root Node, Node-declared semantic key actions run before
Runtime-owned Core semantic actions, non-key Core input handling, and the raw
handler. Action propagation boundaries affect Node-declared and Core semantic
ancestor groups, but not raw routing. The complete order and conflict rules are
defined by the [scoped key-map specification](keymap.md)

## Pointer

- Hit testing proceeds from the frontmost stack or overlay entry
- Clipped regions do not receive pointer hits
- Pointer capture routes events to the capture node
- Capture is released when its node disappears
- Pointer hit testing is restricted to the active modal subtree and falls back
  to the modal root when no descendant is hit

Handlers must be able to ignore or consume an event, emit a message, request or
release focus, capture or release the pointer, and request a redraw. The public
result is a composable value rather than one mutually exclusive action

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
