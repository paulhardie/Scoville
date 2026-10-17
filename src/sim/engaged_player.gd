extends RefCounted
## The pacing player (D003): a GUESS at an engaged first-time player. It only
## uses the game's real actions. Call step() once per tick, before the game's
## tick(). Its policy is described in docs/ECONOMY.md.

const T = preload("res://src/core/tuning.gd")

## Taps a second while tapping (GUESS: quick but not frantic). Zero for an
## idle player.
var taps_per_second := 3.0
## Tapping in bursts: seconds of tapping, then seconds of rest. A rest of 0
## taps all the time.
var burst_seconds := 60.0
var rest_seconds := 0.0
## Seconds between looks at the game (selling, buying, research).
var decide_every := 1.0
## Raw peppers it lets pile up before selling them all, once a vat runs (until
## the Overflow Valve does it).
const RAW_SELL_ABOVE := 50
## Research in this order, saving for each in turn. v0.6a's ladder, Pantry
## and slots are slotted in near their expected times (docs/FULL_RUN.md); the
## forks are Bulk on Vinegar and Garlic, Reserve on Cane Sugar and Smoked Oak
## (`forks` swaps them, for U6).
const RESEARCH := [
	"jalapeno_blueprint", "poblano_blueprint", "ancho_blueprint", "smoky_ancho_blueprint", "calloused_thumbs",
	"verde_blueprint", "vinegar_blueprint", "brine_blueprint", "bistro_blueprint", "delivery_van", "double_tap",
	"slot_expansion_1", "serrano_blueprint", "serrano_mash_blueprint", "serrano_fire_blueprint",
	"cayenne_blueprint", "garlic_blueprint", "paste_blueprint", "cayenne_mash_blueprint", "slot_expansion_2",
	"louisiana_blueprint", "ergonomic_grip", "heat_meter", "night_shift_1", "overflow_valve", "overclock_1",
	"smart_stockpiling", "pantry_vinegar_booster", "tabasco_blueprint", "tabasco_mash_blueprint", "cajun_red_blueprint",
	"flint_glass", "slot_expansion_3", "zero_waste_1", "pantry_garlic_booster", "pantry_vinegar_concentrate",
	"sugar_blueprint", "glaze_blueprint", "bonnet_blueprint", "bonnet_mash_blueprint", "island_heat_blueprint",
	"overclock_2", "night_shift_2", "market_ticker", "slow_burn", "pantry_vinegar_bulk", "pantry_garlic_concentrate",
	"habanero_blueprint", "habanero_mash_blueprint", "sweet_heat_blueprint", "byproduct_recycling",
	"franchise_auditors", "zero_waste_2", "slot_expansion_4", "pantry_sugar_booster", "pantry_garlic_bulk",
	"overclock_3", "automated_piston", "foil_wraps", "savina_blueprint", "savina_mash_blueprint",
	"savina_gold_blueprint", "hydroponic_bell", "pantry_sugar_concentrate", "artisan_decanters", "oak_blueprint",
	"smoke_blueprint", "ghost_blueprint", "ghost_mash_blueprint", "phantom_blueprint", "pantry_sugar_reserve",
	"hydroponic_jalapeno", "overdrive_turbines", "pantry_oak_booster", "pantry_oak_concentrate", "pantry_oak_reserve",
	"hydroponic_cayenne",
]
## What its slots run, by the best sauce researched so far: the last layout
## whose sauce is unlocked wins. Slot i runs entry i; entries past the cap
## wait for Slot Expansion. Each list is in buying order. `lend` is the order
## its vats are lent to a mash research is short of (default: from the last).
const LAYOUTS := [
	{"when": "", "vat": ["sweet_mash"], "line": ["table_mild"]},
	{"when": "smoky_ancho", "vat": ["sweet_mash", "ancho_mash"], "line": ["table_mild", "smoky_ancho"]},
	{"when": "bistro_verde", "vat": ["sweet_mash", "verde_mash", "pickled_brine"], "line": ["table_mild", "bistro_verde"]},
	{"when": "serrano_fire", "vat": ["sweet_mash", "verde_mash", "pickled_brine", "serrano_mash"],
		"line": ["table_mild", "bistro_verde", "serrano_fire"]},
	{"when": "classic_louisiana", "vat": ["sweet_mash", "verde_mash", "pickled_brine", "garlic_paste", "cayenne_mash", "serrano_mash"],
		"line": ["table_mild", "bistro_verde", "classic_louisiana", "classic_louisiana", "serrano_fire"], "lend": [5, 1]},
	# From Cajun Red on, slots move to the best sauce they can supply, keeping
	# their index where they can, and Pickled Brine gets more vats.
	{"when": "cajun_red", "vat": ["sweet_mash", "pickled_brine", "tabasco_mash", "garlic_paste", "cayenne_mash", "pickled_brine", "verde_mash"],
		"line": ["table_mild", "cajun_red", "classic_louisiana", "classic_louisiana", "cajun_red", "bistro_verde"], "lend": [0, 6, 5]},
	{"when": "island_heat", "vat": ["sweet_mash", "pickled_brine", "pickled_brine", "garlic_paste", "glaze", "bonnet_mash", "cayenne_mash"],
		"line": ["table_mild", "island_heat", "island_heat", "classic_louisiana", "classic_louisiana", "island_heat"], "lend": [0, 6]},
	{"when": "sweet_heat", "vat": ["sweet_mash", "pickled_brine", "glaze", "garlic_paste", "glaze", "habanero_mash", "bonnet_mash"],
		"line": ["table_mild", "island_heat", "sweet_heat", "sweet_heat", "island_heat", "sweet_heat"], "lend": [6, 1]},
	{"when": "savina_gold", "vat": ["pickled_brine", "pickled_brine", "pickled_brine", "garlic_paste", "cayenne_mash", "savina_mash", "cayenne_mash"],
		"line": ["classic_louisiana", "savina_gold", "savina_gold", "classic_louisiana", "savina_gold", "classic_louisiana"], "lend": [6, 2]},
	{"when": "phantom", "vat": ["pickled_brine", "pickled_brine", "pickled_brine", "garlic_paste", "cayenne_mash", "ghost_mash", "liquid_smoke"],
		"line": ["classic_louisiana", "phantom", "phantom", "classic_louisiana", "savina_gold", "phantom"], "lend": [2, 1]},
]
## Auto-Sell share for a bottle research needs, before Smart Stockpiling.
const SAVING_AUTOSELL := 50

## Whether it buys and researches (off when measuring a minute as things stand).
var buys := true
## Fork sides it takes instead of RESEARCH's, for U6: {node it skips: node it takes}.
var forks := {}

## What it did, as [seconds, what] pairs, for the report.
var events: Array = []

var _tap_acc := 0.0
## The vats as last assigned, research loans included: plan() buys their plots.
var _lent := []


## A casual phone player (GUESS, docs/FACTORY.md): 2 taps a second in
## 45-second bursts with 15-second rests (1.5 a second on average), looking at
## the game every 2 seconds.
static func casual():
	var p = load("res://src/sim/engaged_player.gd").new()
	p.taps_per_second = 2.0
	p.burst_seconds = 45.0
	p.rest_seconds = 15.0
	p.decide_every = 2.0
	return p


func step(g) -> void:
	var t: float = g.now_seconds()
	var tapping := rest_seconds <= 0.0 or fmod(t, burst_seconds + rest_seconds) < burst_seconds
	if tapping:
		_tap_acc += taps_per_second * T.TICK_SECONDS
		while _tap_acc >= 1.0:
			_tap_acc -= 1.0
			g.press()
	if g.stats.ticks % roundi(decide_every / T.TICK_SECONDS) == 0:
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
	# Bottles a running recipe takes (Table Mild for Sweet Heat, Classic
	# Louisiana for Savina Gold and Phantom) stay in stock for the lines.
	var layout := current_layout(g)
	var wanted_items := _wanted(g, layout, need)
	var lent := _slots_for_research(g, layout, wanted_items)
	var inputs := _bottle_inputs(g, lent.line)
	if g.has_van():
		for bottle in g.autosell:
			if inputs.has(bottle) and not need.has(bottle):
				g.set_autosell(bottle, 0)
			elif g.fx.stockpile:
				g.set_autosell(bottle, 100)
	for bottle in g.autosell:
		if g.stock[bottle] > 0 and not need.has(bottle) and not inputs.has(bottle):
			g.sell_batch(bottle)
			_note(now, "sell_batch")
	if not g.fx.valve and (g.vats.is_empty() or g.stock.bell > RAW_SELL_ABOVE):
		g.sell_raw()
	# A slot that would eat what research is short of waits, unless research
	# is also short of what it makes, or of something made from it (Cayenne
	# Mash for Classic Louisiana).
	for station in ["vat", "line"]:
		for i in g.slots(station).size():
			var recipe: String = lent[station][i]
			if recipe == "" or not g.recipe_unlocked(recipe):
				continue
			var out: String = g.data.recipes[recipe].output
			var wanted: bool = wanted_items.has(out)
			var short := false
			for item in g.recipe_inputs(recipe):
				if wanted_items.has(item):
					short = true
			var want := "" if short and not wanted else recipe
			if g.slots(station)[i].recipe != want:
				g.assign(station, i, want)

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


## The stations it buys, in order, each with whether it's done or on offer:
## for each vat in the layout, the plots it needs and then the vat, and each
## line once the vats so far cover its inputs.
func plan(g) -> Array:
	var layout := current_layout(g)
	var out := []
	out.append(_plot(g, "bell"))
	for recipe in _lent:
		if recipe != "" and not layout.vat.has(recipe):
			for item in g.data.recipes[recipe].inputs:
				if g.data.items[item].kind == "crop":
					out.append(_plot(g, item))
	var made := {}
	var lines_done := 0
	for i in layout.vat.size():
		var recipe: String = layout.vat[i]
		for item in g.data.recipes[recipe].inputs:
			if g.data.items[item].kind == "crop":
				out.append(_plot(g, item))
		out.append(_slot(g, "vat", i, recipe))
		made[g.data.recipes[recipe].output] = true
		while lines_done < layout.line.size() and _covered(g, layout.line[lines_done], made):
			out.append(_slot(g, "line", lines_done, layout.line[lines_done]))
			lines_done += 1
	while lines_done < layout.line.size():
		out.append(_slot(g, "line", lines_done, layout.line[lines_done]))
		lines_done += 1
	return out


## Items research is short of, and the mash and bottles they're made from,
## all the way down.
func _wanted(g, layout: Dictionary, need: Dictionary) -> Dictionary:
	var out := {}
	for item in need:
		if g.stock[item] < need[item]:
			out[item] = true
	var queue: Array = out.keys()
	while not queue.is_empty():
		var item: String = queue.pop_front()
		for station in ["vat", "line"]:
			var maker := _maker(g, item, station)
			if maker == "":
				continue
			for input in g.data.recipes[maker].inputs:
				if g.data.items[input].kind != "crop" and not out.has(input):
					out[input] = true
					queue.append(input)
	return out


## The layout's slots as owned, with some lent to whatever research is short
## of that no slot makes: a line to a bottle (Cajun Red for a Pantry fork once
## the layout has moved on to Island Heat), then a vat to each mash that the
## bottles need. Vats are lent in the layout's `lend` order, lines from the
## last.
func _slots_for_research(g, layout: Dictionary, wanted: Dictionary) -> Dictionary:
	var out := {}
	for station in ["vat", "line"]:
		var own := []
		for i in g.slots(station).size():
			own.append(layout[station][i] if i < layout[station].size() else "")
		out[station] = own
	var want := wanted.duplicate()
	for station in ["line", "vat"]:
		var own: Array = out[station]
		var order: Array = []
		if station == "vat":
			for i in layout.get("lend", []):
				if i < own.size():
					order.append(i)
		for i in range(own.size() - 1, -1, -1):
			if not order.has(i):
				order.append(i)
		# A worklist: lending a slot can make its own inputs wanted (Cayenne
		# Mash needs Pickled Brine), and a slot making a wanted item is never
		# the one lent.
		var queue: Array = want.keys()
		while not queue.is_empty():
			var item: String = queue.pop_front()
			var maker := _maker(g, item, station)
			if maker == "" or own.has(maker):
				continue
			var slot := -1
			for i in order:
				var current: String = own[i]
				if current == "" or not want.has(g.data.recipes[current].output):
					slot = i
					break
			if slot < 0:
				continue
			order.erase(slot)
			own[slot] = maker
			for input in g.data.recipes[maker].inputs:
				if g.data.items[input].kind == "mash" and not want.has(input):
					want[input] = true
					if station == "vat":
						queue.append(input)
		# What the lines now make needs its mash too.
		if station == "line":
			for recipe in own:
				if recipe != "":
					for input in g.data.recipes[recipe].inputs:
						if g.data.items[input].kind == "mash" and want.has(input) == false and not layout.vat.has(_maker(g, input, "vat")):
							want[input] = true
	_lent = out.vat
	return out


## The researched recipe at a station that makes an item, "" if none.
func _maker(g, item: String, station: String) -> String:
	for id in g.data.recipes:
		var r: Dictionary = g.data.recipes[id]
		if r.station == station and r.output == item and g.recipe_unlocked(id):
			return id
	return ""


## The layout for what's researched: the last whose sauce is unlocked.
func current_layout(g) -> Dictionary:
	var best: Dictionary = LAYOUTS[0]
	for l in LAYOUTS:
		if l.when == "" or g.recipe_unlocked(l.when):
			best = l
	return best


## Whether the vats so far make every mash a line recipe takes.
func _covered(g, recipe: String, made: Dictionary) -> bool:
	for item in g.data.recipes[recipe].inputs:
		if g.data.items[item].kind == "mash" and not made.has(item):
			return false
	return true


## Bottles these line recipes take as inputs.
func _bottle_inputs(g, lines: Array) -> Dictionary:
	var out := {}
	for recipe in lines:
		if recipe != "" and g.recipe_unlocked(recipe):
			for item in g.data.recipes[recipe].inputs:
				if g.data.items[item].kind == "bottle":
					out[item] = true
	return out


func _plot(g, crop: String) -> Dictionary:
	var ready: bool = g.plot_offered(crop)
	return _step("buy plot " + crop, g.plots[crop].owned, ready, func(): return g.buy_plot(crop))


## Buying slot `index` of a station for a recipe, on offer once it's researched.
func _slot(g, station: String, index: int, recipe: String) -> Dictionary:
	var done: bool = g.slots(station).size() > index
	var offered: bool = g.slots(station).size() == index and g.slot_offered(station) and g.recipe_unlocked(recipe)
	return _step("buy %s %d (%s)" % [station, index + 1, recipe], done, offered,
		func(): return g.buy_slot(station) and g.assign(station, index, recipe))


func next_research(g) -> String:
	for node in RESEARCH:
		var n: String = forks.get(node, node)
		if not g.is_researched(n):
			return n
	return ""


## Buys the cheapest upgrade it can afford, again and again.
func _buy_upgrades(g, now: float) -> void:
	while true:
		var best := {}
		var best_cost := INF
		var used := _used_crops(g)
		for crop in g.plots:
			if g.plots[crop].owned and used.has(crop):
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


## Crops the slots' current recipes take: only their plots get upgraded.
func _used_crops(g) -> Dictionary:
	var out := {}
	for station in ["vat", "line"]:
		for s in g.slots(station):
			if s.recipe != "":
				for item in g.data.recipes[s.recipe].inputs:
					if g.data.items[item].kind == "crop":
						out[item] = true
	return out


func _step(name: String, done: bool, offered: bool, buy: Callable) -> Dictionary:
	return {"name": name, "done": done, "offered": offered, "buy": buy}


func first(what: String) -> float:
	for entry in events:
		if entry[1] == what:
			return entry[0]
	return INF


func _note(now: float, what: String) -> void:
	events.append([now, what])
