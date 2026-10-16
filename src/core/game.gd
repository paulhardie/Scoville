extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## tick(), then read the state; they never change it themselves (docs/CORE.md).
## Deterministic: time only moves through tick(), and randomness comes from one
## seeded stream whose state is saved.

const G = preload("res://src/core/guesses.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 1

const UPGRADES := ["capper", "picker", "shears"]

var cash := 0.0
var bell := 0.0          # fractional: Field Pickers add a share every tick
var jalapeno := 0
var bottles := {"table": 0, "smoky": 0}
var heat := 0.0
var boil_ticks := 0      # ticks of Flash Boil left; 0 means not boiling
var capper_ticks := 0    # ticks since the Hand Capper last tried to bottle
var levels := {"capper": 0, "picker": 0, "shears": 0}
var unlocked := {"bottling": false, "upgrades": false, "jalapeno": false}
var stats := {"peppers": 0.0, "bottles": 0, "revenue": 0.0, "boils": 0, "ticks": 0}

var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 0) -> void:
	rng.seed = seed_value


# --- Reading ---------------------------------------------------------------

func is_boiling() -> bool:
	return boil_ticks > 0


func tap_yield() -> int:
	return G.TAP_BASE + levels.shears


func cost(upgrade: String) -> float:
	match upgrade:
		"capper":
			return G.CAPPER_BASE_COST * pow(G.CAPPER_GROWTH, levels.capper)
		"picker":
			return G.PICKER_BASE_COST * pow(G.PICKER_GROWTH, levels.picker)
		"shears":
			return G.SHEARS_BASE_COST * pow(G.SHEARS_GROWTH, levels.shears)
		"jalapeno":
			return G.JALAPENO_COST
	push_error("unknown upgrade: " + upgrade)
	return INF


func capper_interval_ticks() -> int:
	var seconds := maxf(G.CAPPER_FLOOR_SECONDS, G.CAPPER_BASE_SECONDS / (1.0 + G.CAPPER_STEP * levels.capper))
	return ceili(seconds / G.TICK_SECONDS - 1e-9)


func can_bottle_table() -> bool:
	return unlocked.bottling and bell >= G.TABLE_SAUCE_PEPPERS


func can_bottle_smoky() -> bool:
	return unlocked.jalapeno and jalapeno >= G.SMOKY_SAUCE_PEPPERS


func can_buy(upgrade: String) -> bool:
	if not unlocked.upgrades:
		return false
	if upgrade == "jalapeno" and unlocked.jalapeno:
		return false
	return cash >= cost(upgrade)


# --- Actions ---------------------------------------------------------------

## One tap on the field. Returns the bell peppers it picked.
func tap() -> int:
	var boiling := is_boiling()
	var mult := G.BOIL_MULT if boiling else 1.0
	if rng.randf() < G.CRIT_CHANCE:
		mult *= G.CRIT_MULT
	var picked := roundi(tap_yield() * mult)
	_gain_bell(picked)
	if unlocked.jalapeno and rng.randf() < G.JALAPENO_TAP_CHANCE:
		jalapeno += 1
		stats.peppers += 1
	if not boiling:
		heat = minf(G.HEAT_MAX, heat + G.HEAT_PER_TAP)
		if heat >= G.HEAT_MAX:
			boil_ticks = roundi(G.BOIL_SECONDS / G.TICK_SECONDS)
			stats.boils += 1
	return picked


func sell_loose_bell() -> bool:
	if bell <= 0.0:
		return false
	_earn(bell * G.BELL_LOOSE_PRICE)
	bell = 0.0
	return true


func sell_loose_jalapeno() -> bool:
	if jalapeno <= 0:
		return false
	_earn(jalapeno * G.JALAPENO_LOOSE_PRICE)
	jalapeno = 0
	return true


## Bottles one Table Sauce, which sells at once. The first one opens upgrades.
func bottle_table() -> bool:
	if not can_bottle_table():
		return false
	bell -= G.TABLE_SAUCE_PEPPERS
	bottles.table += 1
	stats.bottles += 1
	_earn(G.TABLE_SAUCE_PRICE)
	unlocked.upgrades = true
	return true


func bottle_smoky() -> bool:
	if not can_bottle_smoky():
		return false
	jalapeno -= G.SMOKY_SAUCE_PEPPERS
	bottles.smoky += 1
	stats.bottles += 1
	_earn(G.SMOKY_SAUCE_PRICE)
	return true


## Buys one level of capper, picker or shears, or the one-off jalapeño patch.
func buy(upgrade: String) -> bool:
	if not (upgrade in UPGRADES or upgrade == "jalapeno") or not can_buy(upgrade):
		return false
	cash -= cost(upgrade)
	if upgrade == "jalapeno":
		unlocked.jalapeno = true
	else:
		levels[upgrade] += 1
	return true


# --- Time ------------------------------------------------------------------

## Advances one fixed tick (G.TICK_SECONDS).
func tick() -> void:
	stats.ticks += 1
	if boil_ticks > 0:
		boil_ticks -= 1
		if boil_ticks == 0:
			heat = 0.0
	elif heat > 0.0:
		heat = maxf(0.0, heat - G.HEAT_DECAY_PER_TICK)

	if levels.picker > 0:
		_gain_bell(levels.picker * G.PICKER_PEPPERS_PER_SECOND * G.TICK_SECONDS)

	if levels.capper > 0:
		capper_ticks += 1
		if capper_ticks >= capper_interval_ticks():
			capper_ticks = 0
			bottle_table()


func advance(ticks: int) -> void:
	for i in ticks:
		tick()


# --- Saving ----------------------------------------------------------------

func to_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"cash": cash,
		"bell": bell,
		"jalapeno": jalapeno,
		"bottles": bottles.duplicate(),
		"heat": heat,
		"boil_ticks": boil_ticks,
		"capper_ticks": capper_ticks,
		"levels": levels.duplicate(),
		"unlocked": unlocked.duplicate(),
		"stats": stats.duplicate(),
		# A string: JSON numbers are doubles and would round a 64-bit state.
		"rng_state": str(rng.state),
		"rng_seed": str(rng.seed),
	}


## Loads a saved state. Returns "" on success or a message saying what's wrong,
## in which case nothing has been changed.
func load_state(s: Variant) -> String:
	if typeof(s) != TYPE_DICTIONARY:
		return "save is not an object"
	var version := int(s.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return "unknown save version %s" % str(s.get("version"))
	for key in ["cash", "bell", "jalapeno", "bottles", "heat", "boil_ticks", "capper_ticks", "levels", "unlocked", "stats", "rng_state", "rng_seed"]:
		if not s.has(key):
			return "save is missing " + key
	for key in ["bottles", "levels", "unlocked", "stats"]:
		if typeof(s[key]) != TYPE_DICTIONARY:
			return "save's %s is not an object" % key
	cash = float(s.cash)
	bell = float(s.bell)
	jalapeno = int(s.jalapeno)
	heat = float(s.heat)
	boil_ticks = int(s.boil_ticks)
	capper_ticks = int(s.capper_ticks)
	for k in bottles:
		bottles[k] = int(s.bottles.get(k, 0))
	for k in levels:
		levels[k] = int(s.levels.get(k, 0))
	for k in unlocked:
		unlocked[k] = bool(s.unlocked.get(k, false))
	for k in stats:
		stats[k] = s.stats.get(k, stats[k])
	for k in ["bottles", "boils", "ticks"]:
		stats[k] = int(stats[k])
	rng.seed = String(s.rng_seed).to_int()
	rng.state = String(s.rng_state).to_int()
	return ""


# --- Internals -------------------------------------------------------------

func _gain_bell(amount: float) -> void:
	bell += amount
	stats.peppers += amount
	if not unlocked.bottling and stats.peppers >= G.BOTTLING_UNLOCK_PEPPERS:
		unlocked.bottling = true


func _earn(amount: float) -> void:
	cash += amount
	stats.revenue += amount
