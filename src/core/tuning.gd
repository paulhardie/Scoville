extends RefCounted
## Every tuning number that isn't game data, with where it comes from: a brief
## section (docs/BRIEF.md), a decision, or GUESS (ours and open to change).
## Items, recipes, plots, slots and tech nodes live in data/*.json.

## Simulation tick in seconds (GUESS). Invisible on screen.
const TICK_SECONDS := 0.1

## Seconds between autosaves (GUESS).
const AUTOSAVE_SECONDS := 3.0

# --- Onboarding (docs/ONBOARDING.md, docs/ECONOMY.md) -------------------------

## Bell Peppers one press of the Blank Button picks (brief §4: Calloused Thumbs
## adds +2 to this "base", so the base is 1).
const BUTTON_BASE_YIELD := 1

## Peppers picked in total that reveal Cash and Sell Raw Peppers (brief §2,
## Stage 1).
const STAGE_1_PEPPERS := 20

## Cash earned that reveals the Operation Deck (brief §2, Stage 2).
const STAGE_2_CASH := 10.0

## Operation Value that opens each tab (D005). Stage 3's nav bar comes with
## Processing. HQ is the brief's (§2).
const TAB_THRESHOLDS := {
	"processing": 400.0,
	"tech": 750.0,
	"roster": 10000.0,
	"hq": 1000000.0,
}
## Tabs that exist yet. The others stay `[ ? ]` whatever the Operation Value.
const TABS_BUILT := ["farms", "processing", "tech"]

# --- Upgrades (docs/FACTORY.md, GUESSES tuned in v0.2) -------------------------
# A level's price is base × growth^level × √(the station's price ÷ the first
# one of its kind: the Bell Pepper Plot, vat slot 1, line slot 1).

## Plot Harvest Speed: +step a level.
const PLOT_SPEED_STEP := 0.15
const PLOT_SPEED_COST := 15.0
const PLOT_SPEED_GROWTH := 2.0
## Plot Yield per Cycle: +1 a level.
const PLOT_YIELD_COST := 40.0
const PLOT_YIELD_GROWTH := 2.0
## Vat slot speed.
const VAT_SPEED_STEP := 0.25
const VAT_SPEED_COST := 30.0
const VAT_SPEED_GROWTH := 1.45
## Line slot speed.
const LINE_SPEED_STEP := 0.25
const LINE_SPEED_COST := 45.0
const LINE_SPEED_GROWTH := 1.5

## Starter Crate (brief §3: 50 bottles, with the first line; the speed is a
## GUESS at "rapidly").
const STARTER_CRATE_BOTTLES := 50
const STARTER_CRATE_SPEED := 10.0

## Delivery Van Auto-Sell slider step, in percent (GUESS).
const AUTOSELL_STEP := 10
