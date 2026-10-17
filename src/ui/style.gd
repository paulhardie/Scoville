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

const SIZE_BODY := 22
const SIZE_SMALL := 18

const GUTTER := 20
const RADIUS := 12
## Side of the Blank Button at the start (brief §2: "large").
const BLANK_BUTTON_SIZE := 280.0
const STATUS_BAR_HEIGHT := 84.0

## Motion, in seconds.
const PRESS_SQUASH := 0.12
const FADE_IN := 0.6
const SLIDE_IN := 0.45
