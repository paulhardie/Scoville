extends RefCounted
## Every tuning number that isn't game data, with where it comes from: a brief
## section (docs/BRIEF.md), a decision, or GUESS (ours and open to change).
## Items, recipes, plots, slots and tech nodes live in data/*.json.

## Simulation tick in seconds (GUESS). Invisible on screen.
const TICK_SECONDS := 0.1

## Seconds between autosaves (GUESS).
const AUTOSAVE_SECONDS := 3.0

## A v7 save's money × this on loading as v8 (D035): Tier 1's change from
## pounds to Idle Planet Miner's dollars.
const SAVE_V8_MONEY := 10.0

# --- Onboarding (docs/ONBOARDING.md, docs/ECONOMY.md) -------------------------

## Bell Peppers one press of the Blank Button picks (brief §4: Calloused Thumbs
## adds +2 to this "base", so the base is 1).
const BUTTON_BASE_YIELD := 1

## Peppers picked in total that reveal Cash and Sell Raw Peppers (brief §2,
## Stage 1).
const STAGE_1_PEPPERS := 20

## Cash earned that reveals the Operation Deck (brief §2, Stage 2; ×10 for
## Idle Planet Miner's values, D035).
const STAGE_2_CASH := 100.0

## Operation Value that opens each tab (D005, ×10 for D035's values). Stage
## 3's nav bar comes with Processing. HQ opens with the first sale (D035).
const TAB_THRESHOLDS := {
	"processing": 4000.0,
	"tech": 7500.0,
	"roster": 150000.0,
	"hq": 10000000.0,
}
## Tabs that exist yet. The others stay `[ ? ]` whatever the Operation Value.
const TABS_BUILT := ["farms", "processing", "tech", "market", "hq"]

# --- Upgrades (docs/FACTORY.md, GUESSES tuned in v0.2) -------------------------
# A level's price is base × growth^level × (the station's price ÷ its kind's
# reference price)^COST_SCALE_POWER, never below × 1. The references are
# v0.2's first prices (×10 for D035), so cheaper first stations (v0.5.1) leave
# every upgrade's price alone.
const PLOT_PRICE_REFERENCE := 100.0
const VAT_PRICE_REFERENCE := 250.0
const LINE_PRICE_REFERENCE := 350.0
## D035: 0.6, not v0.2's √, so upgrades keep pace with Idle Planet Miner's
## steeper values (×2.1 a pepper rather than ×1.65).
const COST_SCALE_POWER := 0.6
## D031: slot upgrades also scale by (the value of what the slot makes ÷ the
## value of these)^COST_SCALE_POWER, Tier 1's mash and bottle.
const VAT_VALUE_REFERENCE := "sweet_mash"
const LINE_VALUE_REFERENCE := "table_mild"

## Plot Harvest Speed: +step a level.
const PLOT_SPEED_STEP := 0.15
const PLOT_SPEED_COST := 150.0
const PLOT_SPEED_GROWTH := 2.0
## Plot Yield per Cycle: +1 a level.
const PLOT_YIELD_COST := 400.0
const PLOT_YIELD_GROWTH := 2.0
## Vat slot speed.
const VAT_SPEED_STEP := 0.25
const VAT_SPEED_COST := 300.0
const VAT_SPEED_GROWTH := 1.45
## Line slot speed.
const LINE_SPEED_STEP := 0.25
const LINE_SPEED_COST := 450.0
const LINE_SPEED_GROWTH := 1.5

## Starter Crate (brief §3: 50 bottles, with the first line; the speed is a
## GUESS at "rapidly").
const STARTER_CRATE_BOTTLES := 50
const STARTER_CRATE_SPEED := 10.0

## Buying several upgrade levels at once (LAYOUT.md): the ×10 step, and the
## most levels Max looks ahead (a guard, never reached in play).
const BULK_LEVELS := 10
const BULK_MAX := 1000

## Delivery Van Auto-Sell slider step, in percent (GUESS).
const AUTOSELL_STEP := 10

# --- v0.4: the button, Heat and the factory upgrades (docs/TECH_TREE.md) -------

## Heat (D011): added a press, drained a second (× the Slow Burn share), its
## ceiling, and the most it adds to sale cash at full Heat.
const HEAT_PER_PRESS := 5.0
const HEAT_DRAIN := 12.0
const HEAT_MAX := 100.0
const HEAT_BONUS := 0.5

## Overdrive Turbines (brief §4): the lasting speed bonus, then the button's
## boost, how long it lasts and its cooldown from the press.
const TURBINE_SPEED := 0.25
const OVERDRIVE_BOOST := 2.0
const OVERDRIVE_SECONDS := 60.0
const OVERDRIVE_COOLDOWN := 900.0

## Raw Overflow Valve (D014): default keep amount, in cycles of the researched
## recipes that use an item, and how often it sells.
const OVERFLOW_KEEP_CYCLES := 5
const OVERFLOW_EVERY_SECONDS := 1.0

## Market Ticker (D015): the first spike's delay after research, the gap
## between spike starts, a spike's length (all in seconds), and its multipliers.
const TICKER_FIRST := [60, 300]
const TICKER_GAP := [2700, 4500]
const TICKER_SECONDS := 1800
const TICKER_MULTS := [2.0, 3.0]

## Byproduct Recycling (D013): seconds between free levels at most.
const BYPRODUCT_COOLDOWN := 60.0

## Crop Quality (D016): chance a level, its cap in levels, and its price curve.
const CROP_QUALITY_STEP := 0.03
const CROP_QUALITY_MAX := 10
const CROP_QUALITY_COST := 300.0
const CROP_QUALITY_GROWTH := 2.0

# --- v0.5: offline (docs/OFFLINE.md) -------------------------------------------

## Time away that counts, and production speed while away, before Night Shift
## Protocols (D018).
const OFFLINE_HOURS := 4.0
const OFFLINE_SPEED := 0.5

## The catch-up (D020): offline time run tick by tick, and beyond that the
## most steps it runs in (each step then covers several ticks).
const OFFLINE_EXACT_SECONDS := 300.0
const OFFLINE_MAX_STEPS := 4000

## A screen gap longer than this counts as away (D021), and one longer than
## this shows the "While you were away" card (OFFLINE.md).
const AWAY_SECONDS := 10.0
const RETURN_CARD_SECONDS := 60.0

# --- v0.6b: Prestige (docs/PRESTIGE.md) ----------------------------------------

## Operation Value at which the franchise can be sold: Idle Planet Miner's
## first galaxy sale (D035; the brief's £1M before).
const PRESTIGE_OV := 10000000.0
## Franchise Credits at PRESTIGE_OV × 10^n: Idle Planet Miner's credit table
## (D035), straight lines between, rounded, × the Executive Lounge. Past the
## table each decade adds 10 more than the last step did.
const CREDIT_TABLE := [10, 30, 60, 101, 150, 210, 285, 367, 459]
## Opening the n-th room costs ROOM_OPEN_COST × n credits, and levelling a room
## from level L costs ROOM_LEVEL_COST × L (GUESSES, G8).
const ROOM_OPEN_COST := 5
const ROOM_LEVEL_COST := 2
## Rooms dealt in a draft (brief §6: a 2-card draft).
const DRAFT_SIZE := 2

## Standard Operating Procedures (brief §4, D034): a node researches itself
## when its cost is worth under SOP_SHARE of SOP_WINDOW seconds of the bottles
## running lines make (the window is a GUESS at "throughput"), looked at every
## SOP_EVERY_SECONDS (GUESS).
const SOP_SHARE := 0.01
const SOP_WINDOW := 3600.0
const SOP_EVERY_SECONDS := 1.0
