extends RefCounted
## Every number here is our guess, carried over from the web prototype
## (reference/web-prototype/game.js) unless its comment says otherwise. Each has
## a comment saying what it stands for, so it's easy to find and replace.

## Simulation tick in seconds. The prototype ran its loop at 10 ticks a second.
const TICK_SECONDS := 0.1

## Seconds between autosaves (the prototype saved every 3 s).
const AUTOSAVE_SECONDS := 3.0

# --- Picking ---------------------------------------------------------------

## Bell peppers a tap picks before shears and multipliers.
const TAP_BASE := 1
## Chance a tap is a crit, and what a crit multiplies the pick by.
const CRIT_CHANCE := 0.08
const CRIT_MULT := 3.0
## Chance a tap also picks one jalapeño, once jalapeños are unlocked.
const JALAPENO_TAP_CHANCE := 0.35

# --- Heat and Flash Boil ---------------------------------------------------

## Heat a tap adds, out of HEAT_MAX. 19 taps fill it from empty.
const HEAT_PER_TAP := 5.5
const HEAT_MAX := 100.0
## Heat lost per tick while not boiling (12 a second).
const HEAT_DECAY_PER_TICK := 1.2
## Flash Boil: how long it lasts and what it multiplies each tap by. Taps add
## no heat while it runs, and heat drops to zero when it ends.
const BOIL_SECONDS := 10.0
const BOIL_MULT := 5.0

# --- Selling and bottling --------------------------------------------------

## Cash for one loose pepper.
const BELL_LOOSE_PRICE := 0.05
const JALAPENO_LOOSE_PRICE := 0.35
## Table Sauce: bell peppers per bottle and its sale price.
const TABLE_SAUCE_PEPPERS := 20
const TABLE_SAUCE_PRICE := 2.50
## Smoky Sauce: jalapeños per bottle and its sale price.
const SMOKY_SAUCE_PEPPERS := 15
const SMOKY_SAUCE_PRICE := 15.0
## Peppers picked in total before the kitchen (bottling) appears.
const BOTTLING_UNLOCK_PEPPERS := 20

# --- Upgrades --------------------------------------------------------------

## Price of the next level is base × growth^level.
const CAPPER_BASE_COST := 10.0
const CAPPER_GROWTH := 1.4
const PICKER_BASE_COST := 25.0
const PICKER_GROWTH := 1.4
const SHEARS_BASE_COST := 15.0
const SHEARS_GROWTH := 1.5
## One-off price of the jalapeño patch.
const JALAPENO_COST := 100.0

## Field Pickers: bell peppers a second per level.
const PICKER_PEPPERS_PER_SECOND := 2.0
## Hand Capper: bottles one Table Sauce every max(floor, base / (1 + step × level))
## seconds, when there are enough peppers.
const CAPPER_BASE_SECONDS := 4.0
const CAPPER_STEP := 0.35
const CAPPER_FLOOR_SECONDS := 0.8
