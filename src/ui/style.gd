extends RefCounted
## The screen's whole palette, sizes and motion. Screens use only these.
## The look is pixel art (D043): the Pixel UI kit's wood theme at PIXEL_SCALE
## (src/ui/pixel_kit.gd, docs/LOOK.md). These are our colours, picked to sit
## with the kit's and to reach LOOK.md's contrast (PX5) on its surfaces.

## The kit's 1x art is drawn at this whole-number scale.
const PIXEL_SCALE := 2
## The kit's panel art is darkened to this, so cream text reaches 4.5:1 on it.
const PANEL_SHADE := 0.6

const BG := Color("#24140f")
const TEXT := Color("#ecc88e")
const DIM := Color("#d8b07c")
const MUTED := Color("#b48a64")
## Dark text on the kit's light buttons, deeper while pressed, and on its grey
## disabled ones.
const INK := Color("#1e1210")
const INK_PRESSED := Color("#0c0806")
## Cash.
const GREEN := Color("#7be495")
## The Blank Button: a chilli red with no label, a pixel disc BLANK_DISC_PX
## across drawn at whole multiples.
const BUTTON := Color("#d6452f")
const BUTTON_HOVER := Color("#e05139")
const BUTTON_PRESSED := Color("#b8391f")
const BLANK_DISC_PX := 70

## The goal line and the open tab.
const ORANGE := Color("#ffa040")
## Heat, and the pinned node.
const HEAT := Color("#ff8a70")
## The kit's credit (CC BY 4.0), in the Settings card.
const KIT_CREDIT := "Pixel UI Free by heyheythere - https://heyheythere.itch.io/pixel-ui-free - CC BY 4.0"
## Behind the "While you were away" card.
const SHADE := Color("#000000b0")

## The kit font's glyph height; text sizes are whole multiples of it (PX2).
const FONT_PX := 8
const SIZE_BODY := 24
const SIZE_SMALL := 16
const SIZE_TINY := 16

const GUTTER := 20
## Ordinary buttons are at least this tall, so tap targets don't shrink (PX6).
const BUTTON_HEIGHT := 44.0
## Side of the Blank Button at the start (brief §2: "large").
const BLANK_BUTTON_SIZE := 280.0
## Its side once compressed into the upper viewport (Stage 2).
const BLANK_BUTTON_COMPACT := 140.0
const STATUS_BAR_HEIGHT := 84.0
## The stock line under the status bar wraps to at most this many lines, so it
## never runs into the Blank Button.
const STOCK_LINES := 3
## Sell Batch, beside the compact button.
const SELL_BATCH_WIDTH := 140.0
const SELL_BATCH_HEIGHT := 72.0
## The upper viewport's share of the screen height (brief §2: 35%).
const UPPER_FRACTION := 0.35
## Cycle progress bars (the kit's gold bar).
const PROGRESS_HEIGHT := 12.0

## The bottom navigation bar (Stage 3).
const NAV_HEIGHT := 64.0
## The Tech Tree web: grid step between nodes, and each node's size.
const WEB_STEP := Vector2(180, 116)
const WEB_NODE := Vector2(164, 100)
const SIZE_WEB := 16
const WEB_LINE := Color("#ecc88e40")
const WEB_LINE_DONE := Color("#7be495")

# --- Layout step 1 (docs/LAYOUT.md) ------------------------------------------
## A bottle's pop over Sell Batch: at most this many a second, how far it rises
## and how long it shows.
const POPS_PER_SECOND := 4.0
const POP_RISE := 24.0
const POP_SECONDS := 0.9
## A sale's coin, flying from Sell Batch to Cash.
const COINS_PER_SECOND := 3.0
const COIN_SECONDS := 0.45
const COIN_SIZE := 32.0
## The bottle pop's text.
const GOLD := Color("#ffce54")
## Cash counts up to a rise of at least COUNT_UP_FROM over COUNT_UP seconds;
## smaller rises show at once.
const COUNT_UP := 0.35
const COUNT_UP_FROM := 100.0
## The goal bar (one line, or two when it wraps) and the stock strip under the status bar.
const GOAL_TOP := 8.0
const STRIP_TOP := 52.0
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
