# Focus

- Every focusable node has a stable `NodeId`
- Default tab traversal follows portal-aware logical tree order
- An active modal restricts focus requests and default tab traversal to its
  subtree
- Focus changes are Interaction State and remain observable through test support
- Any public semantic node MAY declare a focus-only style overlay. The overlay
  is merged across the node's clipped rectangle only while that node owns focus
  and does not change measurement, layout, hit testing, or event routing
- When the focused node disappears, reconciliation scans forward from its old
  logical position for the first surviving focusable node, then backward. If no
  old focusable node survives, it chooses the first focusable node in the new
  tree. An empty tree has no focus
- An explicitly unfocused tree remains unfocused during reconciliation
- Terminal execution starts unfocused by default. Applications MAY request the
  first focusable node before the initial frame through terminal options
- Forward and backward traversal wrap; traversal from no focus selects the
  first and last focusable node respectively
- Interaction State for a removed Node ID is retired at the end of the frame in
  which the node disappears
- Composite selection widgets use their root ID as one Tab stop. Their internal
  rows remain pointer targets but do not become independent Tab stops. Arrow
  keys update application-owned selection while focus remains on the root
- A ScrollViewport configured to keep focus visible adjusts its enabled-axis
  offsets until the complete focused descendant rectangle is visible when
  possible

Position alone MUST NOT be the identity of a stateful or focusable collection
item
