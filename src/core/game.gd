extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## tick(), then read the state; they never change it themselves
## (docs/ONBOARDING.md, docs/FACTORY.md). Deterministic: time only moves through
## tick(), and nothing is random yet.

const T = preload("res://src/core/tuning.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 2

## Slack when comparing summed ticks with a cycle length, so 8 × 0.1 s counts
## as 0.8 s despite float rounding.
const EPSILON := 1e-6

## What each station's upgrades are called, for buy_upgrade().
const UPGRADES := {
	"plot": ["speed", "yield"],
	"vat": ["speed"],
	"line": ["speed"],
}

var cash := 0.0
var stock := {"bell": 0, "sweet_mash": 0, "table_mild": 0}
## What the screen has revealed (brief §2). Each stays true once set.
var revealed := {"counter": false, "status_bar": false, "deck": false}
## The Tier 1 spine. `progress` is seconds into the current cycle; a vat or line
## is `running` once it has taken its inputs. `crate` is Starter Crate bottles left.
var stations := _new_stations()
var stats := {
	"presses": 0, "bell_picked": 0, "bell_harvested": 0, "mash_made": 0,
	"bottles_made": 0, "bottles_sold": 0, "cash_earned": 0.0, "ticks": 0,
}


static func _new_stations() -> Dictionary:
	return {
		"plot": {"owned": false, "speed": 0, "yield": 0, "progress": 0.0},
		"vat": {"owned": false, "speed": 0, "progress": 0.0, "running": false},
		"line": {"owned": false, "speed": 0, "progress": 0.0, "running": false, "crate": 0},
	}


# --- Reading ---------------------------------------------------------------

func price(station: String) -> float:
	return {"plot": T.PLOT_PRICE, "vat": T.VAT_PRICE, "line": T.LINE_PRICE}[station]


func upgrade_cost(station: String, upgrade: String) -> float:
	var lv: int = stations[station][upgrade]
	match [station, upgrade]:
		["plot", "speed"]:
			return T.PLOT_SPEED_COST * pow(T.PLOT_SPEED_GROWTH, lv)
		["plot", "yield"]:
			return T.PLOT_YIELD_COST * pow(T.PLOT_YIELD_GROWTH, lv)
		["vat", "speed"]:
			return T.VAT_SPEED_COST * pow(T.VAT_SPEED_GROWTH, lv)
		["line", "speed"]:
			return T.LINE_SPEED_COST * pow(T.LINE_SPEED_GROWTH, lv)
	push_error("unknown upgrade %s.%s" % [station, upgrade])
	return INF


## Seconds a cycle takes now, Starter Crate included.
func cycle_seconds(station: String) -> float:
	var s: Dictionary = stations[station]
	match station:
		"plot":
			return T.PLOT_CYCLE_SECONDS / (1.0 + T.PLOT_SPEED_STEP * s.speed)
		"vat":
			return T.VAT_CYCLE_SECONDS / (1.0 + T.VAT_SPEED_STEP * s.speed)
		"line":
			var crate := T.STARTER_CRATE_SPEED if s.crate > 0 else 1.0
			return T.LINE_CYCLE_SECONDS / (1.0 + T.LINE_SPEED_STEP * s.speed) / crate
	return INF


func plot_yield() -> int:
	return T.PLOT_BASE_YIELD + stations.plot.yield


## Stations are offered in order: the plot and vat with the deck, the line once
## the vat is bought.
func is_offered(station: String) -> bool:
	if not revealed.deck:
		return false
	return station != "line" or stations.vat.owned


func can_buy(station: String) -> bool:
	return is_offered(station) and not stations[station].owned and cash >= price(station)


func can_upgrade(station: String, upgrade: String) -> bool:
	return stations[station].owned and upgrade in UPGRADES[station] and cash >= upgrade_cost(station, upgrade)


func can_sell_raw() -> bool:
	return revealed.status_bar and stock.bell > 0


func can_sell_batch() -> bool:
	return stock.table_mild > 0


# --- Actions ---------------------------------------------------------------

## One press of the Blank Button. Returns the Bell Peppers it picked.
func press() -> int:
	var picked := T.BUTTON_BASE_YIELD
	stats.presses += 1
	stock.bell += picked
	stats.bell_picked += picked
	revealed.counter = true
	if stats.bell_picked >= T.STAGE_1_PEPPERS:
		revealed.status_bar = true
	return picked


## Sells every Bell Pepper held at the raw price. Returns false with none.
func sell_raw() -> bool:
	if not can_sell_raw():
		return false
	_earn(stock.bell * T.BELL_RAW_PRICE)
	stock.bell = 0
	return true


## Sells every Table Mild held (brief §3, Sell Batch). Returns false with none.
func sell_batch() -> bool:
	if not can_sell_batch():
		return false
	_earn(stock.table_mild * T.TABLE_MILD_PRICE)
	stats.bottles_sold += stock.table_mild
	stock.table_mild = 0
	return true


func buy(station: String) -> bool:
	if not stations.has(station) or not can_buy(station):
		return false
	cash -= price(station)
	stations[station].owned = true
	if station == "line":
		stations.line.crate = T.STARTER_CRATE_BOTTLES
	_start_cycles()
	return true


func buy_upgrade(station: String, upgrade: String) -> bool:
	if not stations.has(station) or not can_upgrade(station, upgrade):
		return false
	cash -= upgrade_cost(station, upgrade)
	stations[station][upgrade] += 1
	return true


# --- Time ------------------------------------------------------------------

## Advances one fixed tick (T.TICK_SECONDS). Stations run upstream first, so a
## pepper harvested this tick can start a vat this tick.
func tick() -> void:
	stats.ticks += 1
	var plot: Dictionary = stations.plot
	if plot.owned:
		plot.progress += T.TICK_SECONDS
		while plot.progress >= cycle_seconds("plot") - EPSILON:
			plot.progress -= cycle_seconds("plot")
			stock.bell += plot_yield()
			stats.bell_harvested += plot_yield()
	_start_cycles()
	_run("vat", "sweet_mash")
	_run("line", "table_mild")


func advance(ticks: int) -> void:
	for i in ticks:
		tick()


## Advances a vat or line. A finished cycle puts its output in stock and the
## station starts again at once if it has inputs, keeping any leftover time.
func _run(station: String, output: String) -> void:
	var s: Dictionary = stations[station]
	if not s.running:
		return
	s.progress += T.TICK_SECONDS
	while s.running and s.progress >= cycle_seconds(station) - EPSILON:
		s.progress -= cycle_seconds(station)
		s.running = false
		stock[output] += 1
		if station == "vat":
			stats.mash_made += 1
		else:
			stats.bottles_made += 1
			if s.crate > 0:
				s.crate -= 1
		_start_cycles()
	if not s.running:
		s.progress = 0.0


## Idle vats and lines take their inputs if the stock has them.
func _start_cycles() -> void:
	var vat: Dictionary = stations.vat
	if vat.owned and not vat.running and stock.bell >= T.VAT_PEPPERS_IN:
		stock.bell -= T.VAT_PEPPERS_IN
		vat.running = true
	var line: Dictionary = stations.line
	if line.owned and not line.running and stock.sweet_mash >= T.LINE_MASH_IN:
		stock.sweet_mash -= T.LINE_MASH_IN
		line.running = true


func _earn(amount: float) -> void:
	cash += amount
	stats.cash_earned += amount
	if stats.cash_earned >= T.STAGE_2_CASH - 1e-9:
		revealed.deck = true


# --- Saving ----------------------------------------------------------------

func to_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"cash": cash,
		"stock": stock.duplicate(),
		"revealed": revealed.duplicate(),
		"stations": stations.duplicate(true),
		"stats": stats.duplicate(),
	}


## Loads a saved state, migrating older versions. Returns "" on success or a
## message saying what's wrong, in which case nothing has been changed.
func load_state(s: Variant) -> String:
	if typeof(s) != TYPE_DICTIONARY:
		return "save is not an object"
	var version := int(s.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return "unknown save version %s" % str(s.get("version"))
	if version == 1:
		var problem := _check_keys(s, ["cash", "bell", "revealed", "stats"], ["revealed", "stats"])
		if problem != "":
			return problem
		s = _migrate_1_to_2(s)
	var problem := _check_keys(s, ["cash", "stock", "revealed", "stations", "stats"], ["stock", "revealed", "stations", "stats"])
	if problem != "":
		return problem
	for k in stations:
		if typeof(s.stations.get(k)) != TYPE_DICTIONARY:
			return "save's station %s is not an object" % k

	cash = float(s.cash)
	for k in stock:
		stock[k] = int(s.stock.get(k, 0))
	for k in revealed:
		revealed[k] = bool(s.revealed.get(k, false))
	for k in stations:
		var saved: Dictionary = s.stations[k]
		for field in stations[k]:
			var v: Variant = saved.get(field, stations[k][field])
			match typeof(stations[k][field]):
				TYPE_BOOL: stations[k][field] = bool(v)
				TYPE_INT: stations[k][field] = int(v)
				TYPE_FLOAT: stations[k][field] = float(v)
	for k in stats:
		stats[k] = float(s.stats.get(k, 0)) if k == "cash_earned" else int(s.stats.get(k, 0))
	return ""


## v1 (onboarding only) had a top-level `bell` and no stations. Everything else
## carries over; the deck shows at once if the v1 game had already earned £10.
func _migrate_1_to_2(s: Dictionary) -> Dictionary:
	var stats_1: Dictionary = s.stats
	var earned := float(stats_1.get("cash_earned", 0.0))
	return {
		"version": 2,
		"cash": s.cash,
		"stock": {"bell": int(s.bell), "sweet_mash": 0, "table_mild": 0},
		"revealed": {
			"counter": bool(s.revealed.get("counter", false)),
			"status_bar": bool(s.revealed.get("status_bar", false)),
			"deck": earned >= T.STAGE_2_CASH - 1e-9,
		},
		"stations": _new_stations(),
		"stats": stats_1,
	}


func _check_keys(s: Dictionary, keys: Array, objects: Array) -> String:
	for key in keys:
		if not s.has(key):
			return "save is missing " + key
	for key in objects:
		if typeof(s[key]) != TYPE_DICTIONARY:
			return "save's %s is not an object" % key
	return ""
