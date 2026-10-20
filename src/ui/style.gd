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
## The stock line under the status bar wraps to at most this many lines, so it
## never runs into the Blank Button.
const STOCK_LINES := 3
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

# --- Layout step 1 (docs/LAYOUT.md) ------------------------------------------
## A bottle's pop over Sell Batch: at most this many a second, how far it rises
## and how long it shows.
const POPS_PER_SECOND := 4.0
const POP_RISE := 36.0
const POP_SECONDS := 0.9
## A sale's coin, flying from Sell Batch to Cash.
const COINS_PER_SECOND := 3.0
const COIN_SECONDS := 0.45
const COIN_SIZE := 14.0
const COIN := Color("#fbbf24")
## Cash counts up to a rise of at least COUNT_UP_FROM over COUNT_UP seconds;
## smaller rises show at once.
const COUNT_UP := 0.35
const COUNT_UP_FROM := 100.0
## The goal bar and the one-line stock strip under the status bar.
const GOAL_TOP := 8.0
const STRIP_TOP := 36.0
## The station sheet and the warehouse drawer, over the bottom of the screen.
const SHEET_FRACTION := 0.55

## Motion, in seconds.
const PRESS_SQUASH := 0.12
const FADE_IN := 0.6
const SLIDE_IN := 0.45
const COMPRESS := 0.5

# --- Feel: the Blank Button's click and buzz (docs/FEEL.md) --------------------
## The click: a decaying tone of this pitch and length, at this volume.
const CLICK_HZ := 700.0
const CLICK_SECONDS := 0.045
const CLICK_VOLUME_DB := -8.0
## Random pitch spread either way, and the rise at full Heat.
const CLICK_PITCH_SPREAD := 0.08
const CLICK_HEAT_PITCH := 0.2
## A finger press's vibration, in milliseconds.
const HAPTIC_MS := 15
