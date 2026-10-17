extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## read the state; they never change it themselves (docs/ONBOARDING.md).
## Nothing is random or timed yet; a fixed tick and a seeded RNG arrive with the
## first thing that needs them (v0.2's farms).

const T = preload("res://src/core/tuning.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 1

var cash := 0.0
var bell := 0
## What the screen has revealed (brief §2). Each stays true once set.
var revealed := {"counter": false, "status_bar": false}
var stats := {"presses": 0, "bell_picked": 0, "cash_earned": 0.0}


# --- Actions ---------------------------------------------------------------

## One press of the Blank Button. Returns the Bell Peppers it picked.
func press() -> int:
	var picked := T.BUTTON_BASE_YIELD
	stats.presses += 1
	bell += picked
	stats.bell_picked += picked
	revealed.counter = true
	if stats.bell_picked >= T.STAGE_1_PEPPERS:
		revealed.status_bar = true
	return picked


## Sells every Bell Pepper held at the raw price. Returns false with none.
func sell_raw() -> bool:
	if not can_sell_raw():
		return false
	var earned := bell * T.BELL_RAW_PRICE
	cash += earned
	stats.cash_earned += earned
	bell = 0
	return true


func can_sell_raw() -> bool:
	return revealed.status_bar and bell > 0


# --- Saving ----------------------------------------------------------------

func to_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"cash": cash,
		"bell": bell,
		"revealed": revealed.duplicate(),
		"stats": stats.duplicate(),
	}


## Loads a saved state. Returns "" on success or a message saying what's wrong,
## in which case nothing has been changed.
func load_state(s: Variant) -> String:
	if typeof(s) != TYPE_DICTIONARY:
		return "save is not an object"
	var version := int(s.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return "unknown save version %s" % str(s.get("version"))
	for key in ["cash", "bell", "revealed", "stats"]:
		if not s.has(key):
			return "save is missing " + key
	for key in ["revealed", "stats"]:
		if typeof(s[key]) != TYPE_DICTIONARY:
			return "save's %s is not an object" % key
	cash = float(s.cash)
	bell = int(s.bell)
	for k in revealed:
		revealed[k] = bool(s.revealed.get(k, false))
	stats.presses = int(s.stats.get("presses", 0))
	stats.bell_picked = int(s.stats.get("bell_picked", 0))
	stats.cash_earned = float(s.stats.get("cash_earned", 0.0))
	return ""
