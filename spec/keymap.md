# Scoped key maps

This specification defines the language-independent foundation for scoped key
bindings. It separates stable action identities from terminal keys without
changing the existing Runtime event-routing order

## Identities and descriptors

An Action ID is an opaque, case-sensitive string. The `nagi.` prefix is
reserved for Nagi Core and standard widgets. Applications and other libraries
use prefixes they control. Dispatch does not infer behavior from ID segments

An action descriptor contains

- One Action ID
- A user-facing label
- An ordered list of default key bindings
- Availability
- Help visibility

Availability is one of

- `enabled`: the binding is an active candidate
- `disabled-pass-through`: the binding is visible as unavailable but is not an
  active candidate
- `disabled-consume`: the binding is an active blocking candidate

The pure resolver does not execute actions. The availability values establish
the candidate and conflict semantics used by Runtime integrations

## Key strokes and bindings

A Key stroke contains one normalized logical key and an exact Shift, Alt,
Control, and Meta modifier set. Press, repeat, release, associated text, and
the source protocol are not part of stroke identity

A key binding combines a stroke with

- `initial-only` or `allow-repeat`
- `unknown`, `supported`, or `unsupported` capability metadata

Capability metadata affects presentation only. It never suppresses matching
or conflict detection

### Event matching

Key events match by exact logical key and modifiers

- Press and protocol-unknown actions are initial triggers
- Repeat matches only an `allow-repeat` binding
- Release never matches
- Associated text and protocol identity do not affect matching

A Text event containing exactly one Unicode scalar is treated as an
unmodified Character stroke. Text Space and an unmodified Character Space key
therefore have the same stroke. Text represents the produced character; an
uppercase Text `A` is not inferred to be Shift plus lowercase `a`

Paste, multi-scalar Text, Mouse, Focus, terminal response, and unknown sequence
events never match a key binding

A binding contains one stroke. Multi-key sequences and timeout prefixes are
outside this specification

### Canonical notation

Key notation uses modifier order `Ctrl`, `Alt`, `Shift`, `Meta`, followed by
the logical key. Named keys use stable English names such as `Enter`, `Tab`,
`Left`, `PageUp`, and `F5`. Character Space is `Space`. Other control
characters use uppercase `U+` notation with at least four hexadecimal digits

## Key-map layers and scopes

A KeyMap layer contains at most one override per Action ID. An override
replaces the action's complete ordered binding list. An empty replacement
unbinds the action from keyboard input without removing its descriptor

A Key scope combines a stable Node ID with one KeyMap layer and action
propagation behavior. The caller passes active scopes to the pure resolver in
root-to-target order. `continue` is the default. `stop-at-scope` affects
Runtime ancestor-action lookup but does not change pure resolution

Resolution for each action is

1. Start with the descriptor's default bindings
2. Apply active scope layers in root-to-target order
3. Replace the complete binding list whenever a layer names the Action ID

The nearest explicit layer therefore wins. Every active scope ID remains in
the resolved scope path even when its layer does not override an action

Duplicate Action ID overrides in one immutable layer are construction errors

## Resolution and conflicts

The pure resolver resolves one action owner and one precedence group at a
time. It preserves action declaration order, binding order, and active scope
order

It rejects the first conflict in those stable orders

- `duplicate-action`: the group declares one Action ID more than once
- `duplicate-binding`: one resolved action contains the same stroke more than
  once, regardless of repeat or capability metadata
- `ambiguous-binding`: two different active candidates contain the same stroke

Enabled and disabled-consume actions are active candidates.
Disabled-pass-through actions are not candidates. Help visibility and binding
capability do not affect conflict detection

A structured conflict contains the owner Node ID, the active scope ID path,
the involved Action IDs in declaration order, and the conflicting stroke when
the category has one

Child-versus-ancestor precedence and action propagation boundaries belong to
Runtime route integration. They are not inferred by this pure group resolver

## Resolved projection

A successful resolution returns

- The owner Node ID
- The ordered active scope ID path
- Ordered actions with resolved labels, bindings, availability, and Help
  visibility

This projection provides one shared representation for Runtime integrations,
Help rendering, semantic test queries, and diagnostics. Consumers do not need
to duplicate user-facing key strings

The standard Help adapter emits one Help binding for each effective key in
action and binding order. It omits actions whose Help visibility is false.
Bindings for unavailable actions or bindings marked `unsupported` are disabled;
bindings with `unknown` or `supported` capability metadata remain enabled. The
Help view's existing disabled-binding policy decides whether disabled entries
are hidden or rendered

## Runtime route integration

An Action pairs one descriptor with a semantic handler. A Node may declare an
ordered action group under its stable Node ID and may independently carry one
Key scope. Scope attachment initially uses the scope ID as the Node ID. A later
Node identity modifier replaces both observed identities; a stale scope ID is
not retained

The Runtime resolves actions only for the active semantic route. Keyboard and
Text input use the focused target. Pointer input uses capture or hit testing,
although pointer events do not currently normalize into Key strokes. Modal
routing selects the same target route used by raw event delivery

For each event, route precedence is target to root. Node-declared actions and
Runtime-owned Core semantic actions are separate precedence groups. At each
Node the order is

1. The Node-declared resolved action group
2. The Core semantic resolved action group
3. Non-key Core handling such as TextInput editing or ScrollViewport wheel input
4. The Node-local raw event handler
5. The next ancestor Node

A Node-declared group is more specific than a Core semantic group on the same
owner. Equal strokes across those two groups use deterministic precedence and
are not a conflict. If the Node-declared handler ignores the event or its
binding is disabled-pass-through, matching continues into the Core semantic
group

An enabled action invokes its handler. If the result is ignored, Core handling,
the raw handler, and ancestor routing continue. A disabled-pass-through match
is skipped. A disabled-consume match consumes without invoking the handler.
For this blocking match only, the normalized stroke is compared without the
binding's repeat policy, so an explicit repeat of an initial-only binding
cannot escape to another action or ancestor. Enabled and disabled-pass-through
matching continue to enforce the declared repeat policy

TextInput therefore gives its own action group a chance before editing. Text
that is not consumed locally enters TextInput editing before an ancestor
Character action. Paste never matches an action and continues through Core and
raw routing

The nearest target-to-root `stop-at-scope` boundary includes Node-declared and
Core semantic actions on that scope Node and descendants but omits both groups
on outer ancestors. It does not stop raw event routing or ScrollViewport wheel
handling. KeyMap inheritance is independent: every scope on the complete
root-to-target route still participates in override resolution, including
scopes outside the propagation boundary

Child and ancestor groups may use the same Key stroke; the child group has
deterministic route precedence. Conflicts are rejected only within one resolved
owner and precedence group. Before publishing a semantic frame, Runtime
validates every declared owner against its owner route and validates Core
semantic groups on the current active route. A newly selected focus or pointer
route is resolved before any subsequent action, Core, or raw handler runs.
Runtime errors preserve the structured binding conflict

Runtime exposes resolved groups for the active target-to-root route. At one
Node, the Node-declared group precedes the Core semantic group; the same owner
may therefore occur twice. The test harness forwards this projection for
deterministic semantic assertions. Help and other presentation code can consume
the same `ResolvedActions` values used for dispatch

Action resolution is cached for the current semantic tree, route, and focus
action owner. Semantic tree rebuilding replaces the action index and cache as
one frame transition. Routes with neither Node-declared nor Core semantic
actions bypass action resolution and keep existing raw `OnEvent`, widget, and
terminal `mapEvent` behavior

Core reserves `nagi.focus.next` and `nagi.focus.previous`, labeled `Focus next`
and `Focus previous`. Their exact defaults are unmodified Tab and Shift-Tab,
and both accept explicit repeat events. The focused target owns both actions.
Without focus, the active modal root or otherwise the identified tree root owns
them. Forward and backward traversal retain the wrapping and modal focus-scope
rules in the focus specification. If no stable owner exists, the same defaults
remain as a compatibility fallback but cannot be overridden or projected

Core also reserves `nagi.scroll.page-up`, `nagi.scroll.page-down`,
`nagi.scroll.start`, and `nagi.scroll.end`, labeled `Scroll page up`, `Scroll
page down`, `Scroll to start`, and `Scroll to end`. Their exact unmodified
defaults are PageUp, PageDown, Home, and End, and all accept explicit repeat
events. Each eager or virtual ScrollViewport owns these actions. Page actions
are enabled only when the vertical axis is enabled and otherwise use
disabled-pass-through; start and end use the vertical axis first and the
horizontal axis for a horizontal-only viewport. The nearest matching viewport
consumes even at a boundary. Mouse wheel input remains non-key Core handling
and is not affected by KeyMap overrides

Rust exports `FOCUS_*_ACTION_ID` and `SCROLL_*_ACTION_ID` constants. Go exports
the corresponding `Focus*ActionID` and `Scroll*ActionID` constants

Core reserves generic `nagi.text.*` Action IDs for cursor movement left,
right, up, down, to word left and right, to line start and end, and to document
start and end; selection extension in the same ten directions; select all;
backward and forward deletion; line-break insertion; undo; redo; copy
selection; and copy document. Rust exports `TEXT_*_ACTION_ID` constants and Go
exports the corresponding `Text*ActionID` constants

The standard widget package reserves `nagi.activate` for activation with the
English label `Activate`. Its ordered defaults are unmodified Enter and Space,
both accepting explicit repeat events

It also reserves `nagi.selection.previous`, `nagi.selection.next`,
`nagi.selection.first`, and `nagi.selection.last` with the English labels
`Previous`, `Next`, `First`, and `Last`. These IDs identify operations; each
widget owns its ordered default bindings according to its orientation and
existing input contract

`nagi.selection.previous-page` and `nagi.selection.next-page`, with the English
labels `Previous page` and `Next page`, identify viewport-scale selection
movement independently from single-item movement

Calendar-scale selection uses `nagi.selection.previous-day`,
`nagi.selection.next-day`, `nagi.selection.previous-week`,
`nagi.selection.next-week`, `nagi.selection.previous-month`, and
`nagi.selection.next-month`, with the English labels `Previous day`, `Next
day`, `Previous week`, `Next week`, `Previous month`, and `Next month`.
`nagi.selection.first-day-of-month` and
`nagi.selection.last-day-of-month`, labeled `First day of month` and `Last day
of month`, identify displayed-month boundaries independently from generic
collection boundaries

`nagi.navigation.back`, with the English label `Back`, identifies navigation
from the current location to its logical parent or predecessor

`nagi.collapse` and `nagi.expand`, with the English labels `Collapse` and
`Expand`, identify disclosure operations independently from a particular tree
or business model

`nagi.dismiss`, with the English label `Dismiss`, identifies dismissal of a
transient surface. Its default is exact unmodified Escape and accepts explicit
repeat events

`nagi.confirm`, with the English label `Confirm`, identifies invocation of a
Dialog's application-selected default action. Its default is exact unmodified
Enter with `initial-only` repeat policy

`nagi.composer.submit`, `nagi.history.previous`, and `nagi.history.next`, with
the English labels `Submit`, `Previous history entry`, and `Next history entry`,
identify message submission and controlled recall independently from an
application's history storage or message meaning

SelectableText declares the applicable 19 Core text actions at one focusable
root: eight cursor movements, the corresponding eight selection extensions,
select all, copy selection, and copy document. Its word, document, and copy
Action IDs are shared vocabulary rather than clipboard or document-model policy

Button, Checkbox, Radio, Select, Tabs, List, Table, Tree, Disclosure, Dialog
action Buttons, Command Palette, FilePicker, and Calendar declare
`nagi.activate` for keyboard activation.
Select declares all five actions under one owner. Each enabled Tabs item owns
one activation action, while the Tabs root owns the four selection actions with
Left, Right, Home, and End defaults. This two-level ownership allows the same
stroke in an item and root group; target-to-root route precedence selects the
item action first

Disclosure owns activation followed by collapse and expand under its summary
ID. Activation uses Enter and Space, collapse uses Left only while expanded,
and expand uses Right only while collapsed. The inapplicable direction is
disabled-pass-through so an ancestor may handle it

Enabled non-empty List and Table roots each declare activation followed by the
four selection actions. Their navigation defaults are Up, Down, Home, and End.
The same root action set is used for eager and virtualized content, including an
off-screen selected-item proxy. Rows retain only raw pointer selection and do
not duplicate action descriptors for off-screen items

An enabled non-empty Paginator root declares the four selection actions without
activation. Previous has ordered Left, Up, and PageUp defaults; next has Right,
Down, and PageDown; first and last have Home and End. Every previous or next
binding moves exactly one page. Dot and numeric modes expose the same owner and
action order, while unselected dots retain a separate raw left-button path

An enabled FilePicker with visible entries declares activation, the four
single-item selection actions, previous page, next page, and navigation back at
its selected-entry root. Defaults are Enter, Space, and Right for activation;
Up, Down, Home, and End for single-item selection; PageUp and PageDown for page
selection; and Left followed by Backspace for back. Activation and back are
disabled-pass-through when their callbacks are absent. Visible non-selected
entries retain only raw left-button selection and activation

An enabled Calendar declares activation followed by previous and next day,
previous and next week, previous and next month, and the first and last day of
the displayed month at its selected-date root. Defaults are Enter and Space,
Left, Right, Up, Down, PageUp, PageDown, Home, and End in that order. Calendar
activation and boundary no-ops consume and retain root focus without emitting a
selection message. Non-selected dates retain only raw left-button selection

An enabled non-empty Tree root declares activation, the four vertical
selection actions, collapse, and expand under one owner. Defaults are Enter and
Space, Up, Down, Home, End, Left, and Right. Collapse closes an expanded branch
or selects its nearest visible ancestor. Expand opens a collapsed branch or
selects its first visible child. Full and viewport layouts expose the same one
root action group; visible rows retain only raw pointer activation

A Modal root declares dismissal. The action is enabled when a dismissal
handler exists and disabled-pass-through otherwise. Modal routing does not
implicitly create a `stop-at-scope` boundary; an application may attach one
when outer semantic actions must be excluded while raw ancestor routing remains
available

A Dialog root declares confirmation followed by dismissal. Each role names an
application-selected Dialog action ID. An unselected role is
disabled-pass-through, a role naming an enabled action is enabled, and a role
naming an absent or disabled action is disabled-consume. This prevents a
configured confirmation or cancellation key from escaping while preserving
normal fallback when the application intentionally leaves a role unselected.
Focused action Buttons and Disclosure headers retain target-to-root precedence
over both root actions. Active KeyMap scopes may replace or remove each
complete root binding list independently

An enabled TextArea declares all 18 text actions under its focus-owning root.
Its defaults are exact unmodified movement, deletion, and Enter keys; six
Shift-modified selection-extension keys; Control-A; Control-Z; and Control-Y
followed by Control-Shift-Z for redo. All defaults accept explicit repeat
events. Movement and deletion stay enabled at boundaries by default to
preserve consume-without-message behavior. In opt-in Bubble navigation, an Up
or Down action and its corresponding selection-extension action are
disabled-pass-through when no visual line exists in that direction. Undo and
redo are disabled-pass-through when their callback is absent. Text and Paste
continue through raw editing only when no local action matches; Paste cannot
match an action

Composer declares submit, previous history, and next history before the 18
inherited TextArea actions under one focus-owning root. Submit defaults to exact
unmodified Enter with `initial-only` repeat policy. Composer replaces the line
break bindings with Shift-Enter, Alt-Enter, and Control-O; all three line-break
bindings and the Up or Down history defaults use `allow-repeat`. Control-O has
`supported` terminal metadata and is the compatibility fallback for terminals
that do not distinguish modified Enter

TextArea Up or Down is enabled when a visual line exists in that direction;
otherwise the matching history action may become enabled. At most one action
using each default stroke is therefore enabled under the shared owner. The
three Composer actions and inherited text actions use disabled-pass-through
when Composer is disabled. Submit instead uses disabled-consume when editing is
enabled but submission is invalid. A scope may replace or remove each complete
binding list, including assigning Enter to line break and another stroke to
submit. Text and Paste remain raw editing input, and Paste never invokes submit

An enabled Command Palette with at least one filtered command declares
activation followed by the four vertical selection actions under its root.
Each visible command row separately declares activation. The query remains a
Core TextInput: local text editing and unmodified Home or End consume before
the ancestor root action, while Enter, Up, and Down reach the root defaults.
At row focus, target-to-root precedence selects the row activation before the
root activation. Row keyboard and raw left-button activation both emit a
selection first when needed and then activation, using original command
indices

An active KeyMap scope may replace or remove any complete keyboard binding
list. Disabled instances and empty Selects, Tabs, Lists, Tables, or Trees expose
their descriptors as `disabled-pass-through`; disabled TextAreas and Composers
do the same for all of their actions. Disabled Command Palettes and palettes
with no filtered command expose both root and command descriptors as
`disabled-pass-through`. Left-button press remains raw pointer handling and is
not changed by a keyboard rebind. Each widget retains its own controlled
Message behavior

Focus traversal and ScrollViewport keyboard scrolling use the Core semantic
actions above. Their complete binding lists may be replaced or removed through
the same active KeyMap scopes as Node-declared actions. Exact stroke matching
means modified PageUp, PageDown, Home, or End does not invoke the unmodified
Core default unless the application explicitly binds that stroke
