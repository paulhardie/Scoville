extends RefCounted
## The pacing player (D003): a GUESS at an engaged first-time player. It only
## uses the game's real actions. Call step() once per tick, before the game's
## tick(). Its policy is described in docs/FACTORY.md and docs/ECONOMY.md.

const T = preload("res://src/core/tuning.gd")

## Taps a second (GUESS: quick but not frantic). Zero for an idle player.
var taps_per_second := 3.0
## Raw peppers it lets pile up before selling them all, once a vat runs.
const RAW_SELL_ABOVE := 50
## Research in this order, as soon as each can be paid for.
const RESEARCH := ["jalapeno_blueprint", "calloused_thumbs", "verde_blueprint", "vinegar_blueprint", "brine_blueprint", "bistro_blueprint", "delivery_van"]
## Auto-Sell share for Table Mild while saving bottles for research.
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


## Once a second: research, sell, then buy.
func decide(g) -> void:
	var now: float = g.stats.ticks * T.TICK_SECONDS
	var target := next_research(g) if buys else ""
	if target != "" and g.research_node(target):
		_note(now, "research " + target)
		target = next_research(g)
	var need: Dictionary = g.data.tech[target].cost if target != "" and g.research_reachable(target) else {}

	# Bottles: keep Table Mild back while research needs it; sell everything else.
	if g.has_van():
		g.set_autosell("table_mild", SAVING_AUTOSELL if need.has("table_mild") else 100)
	for bottle in g.autosell:
		if g.stock[bottle] > 0 and not need.has(bottle):
			g.sell_batch(bottle)
			_note(now, "sell_batch")
	if g.vats.is_empty() or g.stock.bell > RAW_SELL_ABOVE:
		g.sell_raw()
	# Mash wanted for research: pause the Table Mild line until there's enough.
	if not g.lines.is_empty():
		var short: bool = need.has("sweet_mash") and g.stock.sweet_mash < need.sweet_mash
		g.assign("line", 0, "" if short else "table_mild")

	if not buys:
		return
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
	out.append(_step("buy vat 1", g.vats.size() >= 1, g.slot_offered("vat"), func(): return g.buy_slot("vat")))
	out.append(_step("buy line 1", g.lines.size() >= 1, g.slot_offered("line"), func(): return g.buy_slot("line")))
	out.append(_step("buy plot jalapeno", g.plots.jalapeno.owned, g.plot_offered("jalapeno"), func(): return g.buy_plot("jalapeno")))
	out.append(_step("buy vat 2 (verde)", g.vats.size() >= 2, g.recipe_unlocked("verde_mash") and g.slot_offered("vat"),
		func(): return g.buy_slot("vat") and g.assign("vat", 1, "verde_mash")))
	out.append(_step("buy plot vinegar", g.plots.vinegar.owned, g.plot_offered("vinegar"), func(): return g.buy_plot("vinegar")))
	out.append(_step("buy vat 3 (brine)", g.vats.size() >= 3, g.recipe_unlocked("pickled_brine") and g.slot_offered("vat"),
		func(): return g.buy_slot("vat") and g.assign("vat", 2, "pickled_brine")))
	out.append(_step("buy line 2 (bistro)", g.lines.size() >= 2, g.recipe_unlocked("bistro_verde") and g.slot_offered("line"),
		func(): return g.buy_slot("line") and g.assign("line", 1, "bistro_verde")))
	return out


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
				for upgrade in ["speed", "yield"]:
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
