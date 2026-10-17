extends RefCounted
## The screen's whole palette, sizes and motion. Screens use only these.
## Placeholder look until the brief's art direction is set.

const BG := Color("#0c0e14")
const PANEL := Color("#161a24")
const LINE := Color("#ffffff14")
const TEXT := Color("#f3f4f6")
const DIM := Color("#9ca3af")
const MUTED := Color("#6b7280")
## Cash.
const GREEN := Color("#10b981")
## The Blank Button: a chilli red with no label.
const BUTTON := Color("#d6452f")
const BUTTON_HOVER := Color("#e05139")
const BUTTON_PRESSED := Color("#b8391f")
const BUTTON_EDGE := Color("#ffffff26")
## Ordinary buttons.
const CONTROL := Color("#232a3a")
const CONTROL_PRESSED := Color("#343e55")
const CONTROL_DISABLED := Color("#181c26")

## Researched nodes, and things you can afford now.
const ORANGE := Color("#f97316")
## Heat, and the pinned node.
const HEAT := Color("#ef4444")
## Behind the "While you were away" card.
const SHADE := Color("#000000b0")

const SIZE_BODY := 22
const SIZE_SMALL := 18
const SIZE_TINY := 15

const GUTTER := 20
const RADIUS := 12
## Side of the Blank Button at the start (brief §2: "large").
const BLANK_BUTTON_SIZE := 280.0
## Its side once compressed into the upper viewport (Stage 2).
const BLANK_BUTTON_COMPACT := 150.0
const STATUS_BAR_HEIGHT := 84.0
## Sell Batch, beside the compact button.
const SELL_BATCH_WIDTH := 140.0
const SELL_BATCH_HEIGHT := 72.0
## The upper viewport's share of the screen height (brief §2: 35%).
const UPPER_FRACTION := 0.35
## Cycle progress bars.
const PROGRESS_HEIGHT := 8.0
const PROGRESS_FILL := Color("#f97316")
const PROGRESS_TRACK := Color("#0c0e14")

## The bottom navigation bar (Stage 3).
const NAV_HEIGHT := 64.0
## The Tech Tree web: grid step between nodes, and each node's size.
const WEB_STEP := Vector2(100, 88)
const WEB_NODE := Vector2(90, 70)
const SIZE_WEB := 13
const WEB_LINE := Color("#ffffff30")
const WEB_LINE_DONE := Color("#10b981")

## Motion, in seconds.
const PRESS_SQUASH := 0.12
const FADE_IN := 0.6
const SLIDE_IN := 0.45
const COMPRESS := 0.5
