extends RefCounted
## Every tuning number, with where it comes from: a brief section (docs/BRIEF.md)
## or GUESS, which means ours and open to change. Each has a comment saying what
## it stands for, so it's easy to find and replace.

## Simulation tick in seconds (GUESS). Invisible on screen.
const TICK_SECONDS := 0.1

## Seconds between autosaves (GUESS).
const AUTOSAVE_SECONDS := 3.0

# --- Onboarding (docs/ONBOARDING.md) ------------------------------------------

## Bell Peppers one press of the Blank Button picks (brief §4: Calloused Thumbs
## adds +2 to this "base", so the base is 1).
const BUTTON_BASE_YIELD := 1

## Peppers picked in total that reveal Cash and Sell Raw Peppers (brief §2,
## Stage 1).
const STAGE_1_PEPPERS := 20

## Cash earned that reveals the Operation Deck (brief §2, Stage 2).
const STAGE_2_CASH := 10.0

## Cash for one raw Bell Pepper (brief §2, Stage 1).
const BELL_RAW_PRICE := 0.10

# --- Tier 1 spine (docs/FACTORY.md) -------------------------------------------
# Recipes and the bottle's value are the brief's (§3); prices, times and
# upgrade curves are GUESSES aimed at FACTORY.md's criteria (G4).

## Bell Pepper Plot: price, base cycle, base yield.
const PLOT_PRICE := 10.0
const PLOT_CYCLE_SECONDS := 2.0
const PLOT_BASE_YIELD := 1
## Harvest Speed: +step a level; price base × growth^level.
const PLOT_SPEED_STEP := 0.15
const PLOT_SPEED_COST := 15.0
const PLOT_SPEED_GROWTH := 2.0
## Yield per Cycle: +1 pepper a level; price base × growth^level.
const PLOT_YIELD_COST := 40.0
const PLOT_YIELD_GROWTH := 2.0

## Sweet Pepper Mash vat: price, peppers in (brief §3: 10), base cycle.
const VAT_PRICE := 25.0
const VAT_PEPPERS_IN := 10
const VAT_CYCLE_SECONDS := 8.0
const VAT_SPEED_STEP := 0.25
const VAT_SPEED_COST := 30.0
const VAT_SPEED_GROWTH := 1.45

## Table Mild line: price, mash in (brief §3: 1), base cycle, bottle value
## (brief §3: £5).
const LINE_PRICE := 35.0
const LINE_MASH_IN := 1
const LINE_CYCLE_SECONDS := 8.0
const TABLE_MILD_PRICE := 5.0
const LINE_SPEED_STEP := 0.25
const LINE_SPEED_COST := 45.0
const LINE_SPEED_GROWTH := 1.5
## Starter Crate (brief §3: 50 bottles; the speed is a GUESS at "rapidly").
const STARTER_CRATE_BOTTLES := 50
const STARTER_CRATE_SPEED := 10.0
