# Focus

- Every focusable node has a stable `NodeId`
- Default tab traversal follows portal-aware logical tree order
- An active modal restricts focus requests and default tab traversal to its
  subtree
- A modal focus lifecycle selects `First`, a stable target ID, or `None` when
  the modal becomes active. `First` is the default. A missing, non-focusable,
  or out-of-scope target falls back to the first focusable node in the active
  modal scope
- A closing modal returns to `Previous`, a stable target ID, or `None`.
  `Previous` is the default and records the focus present immediately before
  entry. A recorded unfocused state and explicit `None` remain unfocused. An
  unavailable target uses normal deterministic reconciliation
- Modal disappearance caused directly by application state uses the same
  return policy as action-driven close. Nested and overlaid sibling modals are
  retained as a last-in-first-out focus history; the final modal in semantic
  preorder remains the active routing scope
- A Dialog derives its modal entry target from an explicitly selected default
  action unless the application supplies a separate entry policy. A Dialog
  without a default uses `First`; configured but unavailable targets use the
  normal modal target fallback
- Focus changes are Interaction State and remain observable through test support
- Any public semantic node MAY declare a focus-only style overlay. The overlay
  is merged across the node's clipped rectangle only while that node owns focus
  and does not change measurement, layout, hit testing, or event routing
- When the focused node disappears, reconciliation scans forward from its old
  logical position for the first surviving focusable node, then backward. If no
  old focusable node survives, it chooses the first focusable node in the new
  tree. An empty tree has no focus
- A subtree may declare a stable focus fallback. When a focused descendant
  disappears in the next frame, an available focusable fallback in the current
  modal scope takes precedence over forward and backward reconciliation.
  Nested declarations override outer declarations. The fallback does not run
  when focus survives, the tree was explicitly unfocused, or a modal lifecycle
  transition is being applied
- An explicitly unfocused tree remains unfocused during reconciliation
- Terminal execution starts unfocused by default. Applications MAY request the
  first focusable node before the initial frame through terminal options
- Forward and backward traversal wrap; traversal from no focus selects the
  first and last focusable node respectively
- Forward and backward traversal are the Core semantic actions
  `nagi.focus.next` and `nagi.focus.previous`; active KeyMap scopes may replace
  or remove their exact Tab and Shift-Tab defaults
- Interaction State for a removed Node ID is retired at the end of the frame in
  which the node disappears
- Composite selection widgets use their root ID as one Tab stop. Their internal
  rows remain pointer targets but do not become independent Tab stops. Arrow
  keys update application-owned selection while focus remains on the root
- A ScrollViewport configured to keep focus visible adjusts its enabled-axis
  offsets until the complete focused descendant rectangle is visible when
  possible. An explicit reveal target on the same viewport takes precedence

Position alone MUST NOT be the identity of a stateful or focusable collection
item
