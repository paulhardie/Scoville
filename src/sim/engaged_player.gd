extends RefCounted
## The pacing player (D003): a GUESS at an engaged first-time player. It only
## uses the game's real actions. Call step() once per tick, before the game's
## tick(). Its policy is described in docs/ECONOMY.md.

const T = preload("res://src/core/tuning.gd")

## Taps a second (GUESS: quick but not frantic). Zero for an idle player.
var taps_per_second := 3.0
## Raw peppers it lets pile up before selling them all, once a vat runs (until
## the Overflow Valve does it).
const RAW_SELL_ABOVE := 50
## Research in this order, saving for each in turn.
const RESEARCH := [
	"jalapeno_blueprint", "calloused_thumbs", "verde_blueprint", "vinegar_blueprint", "brine_blueprint",
	"bistro_blueprint", "delivery_van", "double_tap", "slot_expansion_1", "cayenne_blueprint", "garlic_blueprint",
	"paste_blueprint", "cayenne_mash_blueprint", "slot_expansion_2", "louisiana_blueprint", "ergonomic_grip",
	"heat_meter", "overflow_valve", "overclock_1", "smart_stockpiling", "flint_glass", "zero_waste_1",
	"overclock_2", "market_ticker", "slow_burn", "byproduct_recycling", "franchise_auditors", "zero_waste_2",
	"overclock_3", "automated_piston", "foil_wraps", "hydroponic_bell", "overdrive_turbines",
]
## What each slot is meant to run, in buying order.
const INTENDED := {
	"vat": ["sweet_mash", "verde_mash", "pickled_brine", "garlic_paste", "cayenne_mash"],
	"line": ["table_mild", "bistro_verde", "classic_louisiana", "classic_louisiana"],
}
## Auto-Sell share for a bottle research needs, before Smart Stockpiling.
const SAVING_AUTOSELL := 50

## Whether it buys and researches (off when measuring a minute as things stand).
var buys := true

## What it did, as [seconds, what] pairs, for the report.
var events: Array = []

var _tap_acc := 0.0


func step(g) -> void:
	_tap_acc += taps_per_second * T.TICK_SECONDS
	while _tap_acc >= 1.0:
		_tap_acc -= 1.0
		g.press()
	if g.stats.ticks % roundi(1.0 / T.TICK_SECONDS) == 0:
		decide(g)


## Once a second: research, hold back what research needs, sell, then buy.
func decide(g) -> void:
	var now: float = g.now_seconds()
	var target := next_research(g) if buys else ""
	if target != "" and g.research_node(target):
		_note(now, "research " + target)
		target = next_research(g)
	var need: Dictionary = g.data.tech[target].cost if target != "" and g.research_reachable(target) else {}

	# Hold back what the next research needs: pin it once Smart Stockpiling
	# allows, otherwise turn Auto-Sell down and raise the valve's keep amounts.
	if g.fx.stockpile:
		g.set_pin(target if not need.is_empty() else "")
	else:
		if g.has_van():
			for bottle in g.autosell:
				g.set_autosell(bottle, SAVING_AUTOSELL if need.has(bottle) else 100)
		if g.fx.valve:
			for item in g.stock:
				if g.data.items[item].kind == "bottle":
					continue
				if need.has(item):
					g.set_keep(item, maxi(g.default_keep(item), need[item]))
				elif g.keep.has(item):
					g.clear_keep(item)
	for bottle in g.autosell:
		if g.stock[bottle] > 0 and not need.has(bottle):
			g.sell_batch(bottle)
			_note(now, "sell_batch")
	if not g.fx.valve and (g.vats.is_empty() or g.stock.bell > RAW_SELL_ABOVE):
		g.sell_raw()
	# A slot that would eat what research is short of waits, unless research
	# also needs what it makes and is short of that too.
	for station in INTENDED:
		for i in g.slots(station).size():
			var recipe: String = INTENDED[station][i]
			if not g.recipe_unlocked(recipe):
				continue
			var out: String = g.data.recipes[recipe].output
			var wanted: bool = need.has(out) and g.stock[out] < need[out]
			var short := false
			for item in g.recipe_inputs(recipe):
				if need.has(item) and g.stock[item] < need[item]:
					short = true
			g.assign(station, i, "" if short and not wanted else recipe)

	if not buys:
		return
	if g.activate_overdrive():
		_note(now, "overdrive")
	# The next station in order: buy it, or save for it if it's on offer.
	for step in plan(g):
		if step.done:
			continue
		if not step.offered:
			break
		if not step.buy.call():
			return
		_note(now, step.name)
		return
	_buy_upgrades(g, now)


## The stations it buys, in order, each with whether it's done or on offer.
func plan(g) -> Array:
	var out := []
	out.append(_step("buy plot bell", g.plots.bell.owned, g.plot_offered("bell"), func(): return g.buy_plot("bell")))
	out.append(_slot(g, "vat", 0))
	out.append(_slot(g, "line", 0))
	out.append(_step("buy plot jalapeno", g.plots.jalapeno.owned, g.plot_offered("jalapeno"), func(): return g.buy_plot("jalapeno")))
	out.append(_slot(g, "vat", 1))
	out.append(_step("buy plot vinegar", g.plots.vinegar.owned, g.plot_offered("vinegar"), func(): return g.buy_plot("vinegar")))
	out.append(_slot(g, "vat", 2))
	out.append(_slot(g, "line", 1))
	out.append(_step("buy plot cayenne", g.plots.cayenne.owned, g.plot_offered("cayenne") and g.recipe_unlocked("cayenne_mash"), func(): return g.buy_plot("cayenne")))
	out.append(_step("buy plot garlic", g.plots.garlic.owned, g.plot_offered("garlic") and g.recipe_unlocked("garlic_paste"), func(): return g.buy_plot("garlic")))
	out.append(_slot(g, "vat", 3))
	out.append(_slot(g, "vat", 4))
	out.append(_slot(g, "line", 2))
	out.append(_slot(g, "line", 3))
	return out


## Buying slot `index` of a station, on offer once its recipe is researched.
func _slot(g, station: String, index: int) -> Dictionary:
	var recipe: String = INTENDED[station][index]
	var offered: bool = g.slots(station).size() == index and g.slot_offered(station) and g.recipe_unlocked(recipe)
	return _step("buy %s %d (%s)" % [station, index + 1, recipe], g.slots(station).size() > index, offered,
		func(): return g.buy_slot(station) and g.assign(station, index, recipe))


func next_research(g) -> String:
	for node in RESEARCH:
		if not g.is_researched(node):
			return node
	return ""


## Buys the cheapest upgrade it can afford, again and again.
func _buy_upgrades(g, now: float) -> void:
	while true:
		var best := {}
		var best_cost := INF
		for crop in g.plots:
			if g.plots[crop].owned:
				for upgrade in g.PLOT_UPGRADES:
					var c: float = g.plot_upgrade_cost(crop, upgrade)
					if c < best_cost:
						best_cost = c
						best = {"name": "upgrade %s.%s" % [crop, upgrade], "buy": g.upgrade_plot.bind(crop, upgrade)}
		for station in ["vat", "line"]:
			for i in g.slots(station).size():
				var c: float = g.slot_upgrade_cost(station, i)
				if c < best_cost:
					best_cost = c
					best = {"name": "upgrade %s %d" % [station, i + 1], "buy": g.upgrade_slot.bind(station, i)}
		if best.is_empty() or not best.buy.call():
			return
		_note(now, best.name)


func _step(name: String, done: bool, offered: bool, buy: Callable) -> Dictionary:
	return {"name": name, "done": done, "offered": offered, "buy": buy}


func first(what: String) -> float:
	for entry in events:
		if entry[1] == what:
			return entry[0]
	return INF


func _note(now: float, what: String) -> void:
	events.append([now, what])
