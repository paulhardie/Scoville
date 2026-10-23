extends RefCounted
## The pacing player (D003): a GUESS at an engaged first-time player. It only
## uses the game's real actions. Call step() once per tick, before the game's
## tick(). Since v0.7 (SKELETON.md) it plays Idle Planet Miner's way, from the
## wiki's Upgrade Strategy: its goal is the next Land Survey, so it buys the
## recipes, vats, lines and farms that survey's cost needs and runs them; what
## no goal needs it sells; the rest of its cash goes on whatever pays back
## soonest, farm levels above all.

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
## Seconds a farm level may take to pay for itself (GUESS: an hour; IPM's
## levels cost ×1.3 each, so paybacks lengthen as a run goes on).
const PAYBACK_MAX := 3600.0
## Minutes of income a slot for an extra recipe may cost (GUESS).
const SLOT_MINUTES := 10.0
## IPM's guide (Upgrade Strategy): unlock a new planet once every planet is at
## Mining 12, its level 11 here. GUESS that its players follow it.
const NEXT_FARM_LEVEL := 11
## Seconds it will wait for its farms to grow what the goal needs before it
## buys a farm for it (GUESS).
const SLOW_SUPPLY := 900.0
## How much more a crop the goal still needs counts in a farm level's worth
## than its sale value (GUESS: the bottleneck is what a player upgrades).
const WANTED_WEIGHT := 10.0
## Seconds of cash earned it looks back over to judge its income.
const INCOME_WINDOW := 120.0
## Cycles of a running recipe's inputs it keeps in stock before selling the
## rest (GUESS).
const KEEP_CYCLES := 2
## Rooms it opens, best first, when both are offered (PRESTIGE.md; IPM's guide:
## mining first, and the discount rooms maxed).
const ROOM_ORDER := ["seed_vault", "fermentation_cellar", "land_office", "high_speed_cannery", "test_kitchen", "motor_pool",
	"crate_yard", "boardroom", "cooperage", "glassworks", "tasting_room", "seed_capital", "ergonomics_lab", "night_watchman", "ad_agency"]

## Whether it buys and researches (off when measuring a minute as things stand).
var buys := true

## What it did, as [seconds, what] pairs, for the report.
var events: Array = []

var _tap_acc := 0.0
var _earned := []   # [seconds, cash earned so far], for its income
var _wanted_now := {}   # what the goal still needs, for weighing farm levels


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


## Once a second: research, run the factory for the goal, sell, then buy.
func decide(g) -> void:
	var now: float = g.now_seconds()
	_earned.append([now, g.stats.cash_earned])
	while _earned.size() > 1 and _earned[0][0] < now - INCOME_WINDOW:
		_earned.pop_front()
	var goal := next_research(g) if buys else ""
	if goal != "" and g.research_node(goal):
		_note(now, "research " + goal)
		goal = next_research(g)
	var need: Dictionary = g.tech_cost(goal) if goal != "" and g.research_reachable(goal) else {}
	if buys:
		_research_spare(g, now, goal, need)
		_use_crossbreeds(g)
	var wanted := _wanted(g, need)
	if g.fx.stockpile:
		g.set_pin(goal if not need.is_empty() else "")
	var plan := _plan_slots(g, wanted)
	_assign(g, plan)
	_sell(g, plan, need)
	if not buys:
		return
	if g.activate_overdrive():
		_note(now, "overdrive")
	_wanted_now = wanted
	_buy(g, now, plan, wanted)


## The next Land Survey while there is one to research; between surveys, the
## cheapest node it can reach (forks take the first side in file order).
func next_research(g) -> String:
	var survey := "survey_%d" % (g.fx.survey + 1)
	if g.data.tech.has(survey) and not g.is_researched(survey):
		if g.research_reachable(survey):
			return survey
	var best := ""
	var best_value := INF
	for node in g.data.tech_order:
		if g.research_reachable(node) and g.tech_cost_value(node) < best_value:
			best = node
			best_value = g.tech_cost_value(node)
	return best if best != "" else (survey if g.data.tech.has(survey) and not g.is_researched(survey) else "")


## Other nodes it can afford without touching what the goal needs.
func _research_spare(g, now: float, goal: String, need: Dictionary) -> void:
	for node in g.data.tech_order:
		if node == goal or not g.can_research(node):
			continue
		var cost: Dictionary = g.tech_cost(node)
		var clash := false
		for item in cost:
			if need.has(item) and g.stock[item] - cost[item] < need[item]:
				clash = true
		if not clash and g.research_node(node):
			_note(now, "research " + node)


## Crossbreeding: each unused node on the owned farm whose lead crop climbs to
## the most valuable pepper.
func _use_crossbreeds(g) -> void:
	for node in g.crossbreeds_left():
		var best := []
		var best_value := 0.0
		for id in g.plots:
			if not g.plots[id].owned or not g.plots[id].bred.is_empty() or g.data.plots[id].ingredient:
				continue
			for crop in g.data.plots[id].crops:
				var to: String = g.rung_up(crop, g.fx.crossbreed[node])
				if to != "" and g.value(to) * g.data.plots[id].crops[crop] > best_value:
					best = [id, crop]
					best_value = g.value(to) * g.data.plots[id].crops[crop]
		if not best.is_empty():
			g.crossbreed(node, best[0], best[1])


## What the goal needs that stock doesn't cover, and everything those are made
## from, all the way down to crops: item → how many more it needs. Made items
## are worked out from the most valuable down, so a mash two recipes take
## counts for both.
func _wanted(g, need: Dictionary) -> Dictionary:
	var total := {}
	for item in need:
		total[item] = need[item]
	var done := {}
	while true:
		var next := ""
		for item in total:
			if not done.has(item) and g.data.recipes.has(item) and (next == "" or g.value(item) > g.value(next)):
				next = item
		if next == "":
			break
		done[next] = true
		var short: int = total[next] - g.stock[next]
		if short <= 0:
			continue
		var inputs: Dictionary = g.recipe_inputs(next)
		for input in inputs:
			total[input] = total.get(input, 0) + short * inputs[input]
	var out := {}
	for item in total:
		if total[item] > g.stock[item]:
			out[item] = total[item] - g.stock[item]
	return out


## The recipes its vats and lines should run, in slot order: what the goal
## wants (the deepest first), then the mash its first lines take, then the
## kitchen's recipe (D052), then the most valuable it can feed.
func _plan_slots(g, wanted: Dictionary) -> Dictionary:
	var plan := {}
	for station in ["line", "vat"]:
		var kind := "mash" if station == "vat" else "bottle"
		var picks: Array = []
		var goal_items := []
		for item in wanted:
			if g.data.items[item].kind == kind and g.data.recipes.has(item):
				goal_items.append(item)
		goal_items.sort_custom(func(a, b): return g.value(a) < g.value(b))
		picks.append_array(goal_items)
		if station == "vat":
			for r in plan.line.slice(0, g.lines.size()):
				for input in g.data.recipes[r].inputs:
					if g.data.items[input].kind == "mash" and g.data.recipes.has(input) and not picks.has(input):
						picks.append(input)
		var kitchen := "sweet_mash" if station == "vat" else "table_mild"
		if not picks.has(kitchen):
			picks.append(kitchen)
		var extra := []
		for id in g.data.recipes:
			var r: Dictionary = g.data.recipes[id]
			if r.station == station and not r.kitchen and not picks.has(id) and _can_feed(g, id):
				extra.append(id)
		extra.sort_custom(func(a, b): return g.value(a) > g.value(b))
		picks.append_array(extra)
		plan[station] = picks
	return plan


func _goal_count(g, wanted: Dictionary, kind: String) -> int:
	var n := 0
	for item in wanted:
		if g.data.items[item].kind == kind and g.data.recipes.has(item):
			n += 1
	return n


## Whether its farms grow every crop a recipe takes, and it can make every
## mash in it (recipes it owns or can buy).
func _can_feed(g, recipe: String) -> bool:
	for input in g.data.recipes[recipe].inputs:
		match g.data.items[input].kind:
			"crop":
				if not _grows(g, input):
					return false
			_:
				if not g.data.recipes.has(input) or not g.recipe_unlocked(input):
					return false
	return true


func _grows(g, crop: String) -> bool:
	for id in g.plots:
		if g.plots[id].owned and g.plot_crops(id).has(crop):
			return true
	return false


## Assigns each owned slot its planned recipe, if it owns the recipe; a slot
## past the plan, or on a recipe it doesn't own yet, is left as it is.
func _assign(g, plan: Dictionary) -> void:
	for station in ["vat", "line"]:
		var picks: Array = plan[station]
		var used := 0
		for i in g.slots(station).size():
			var want := ""
			while used < picks.size():
				var r: String = picks[used]
				used += 1
				if g.recipe_unlocked(r) and r in g.recipes_for(station, i):
					want = r
					break
			if want != "" and g.slots(station)[i].recipe != want:
				g.assign(station, i, want)
		# Pressure Cookers on the first vats after the kitchen's.
		if station == "vat":
			for i in range(1, g.vats.size()):
				if g.pressure_used() < g.fx.pressure:
					g.set_pressure(i, true)


## Sells what no running recipe or the goal needs, keeping KEEP_CYCLES of each
## running recipe's inputs and the goal's cost (D041: crops sell raw too).
func _sell(g, plan: Dictionary, need: Dictionary) -> void:
	var keep := need.duplicate()
	for station in ["vat", "line"]:
		for i in g.slots(station).size():
			var r: String = g.slots(station)[i].recipe
			if r == "":
				continue
			var inputs: Dictionary = g.slot_inputs(station, i)
			for item in inputs:
				keep[item] = keep.get(item, 0) + KEEP_CYCLES * inputs[item]
	# What a recipe in the plan but not yet running would take: its crops
	# bank up towards its first batch rather than selling.
	for station in ["vat", "line"]:
		for r in plan[station]:
			if not g.recipe_unlocked(r) or not _runs(g, station, r) and not _will_run(g, station, r, plan):
				continue
			for item in g.data.recipes[r].inputs:
				keep[item] = maxi(keep.get(item, 0), KEEP_CYCLES * g.data.recipes[r].inputs[item])
	for item in g.stock:
		var extra: int = g.stock[item] - keep.get(item, 0)
		if extra > 0:
			g.sell_item(item, extra)


func _runs(g, station: String, recipe: String) -> bool:
	for s in g.slots(station):
		if s.recipe == recipe:
			return true
	return false


## Whether a planned recipe would get a slot: within the first slots' worth of
## the plan.
func _will_run(g, station: String, recipe: String, plan: Dictionary) -> bool:
	var i: int = plan[station].find(recipe)
	return i >= 0 and i < g.slots(station).size() + 1


## Buys, most needed first: a recipe the goal or the plan's next slot needs, a
## farm for a crop it wants but doesn't grow, another slot when the plan has
## more than it owns, the next farm by IPM's guide; then whatever pays back
## soonest. While saving for a needed thing, a payback is bought only if it
## pays back before the saving would be done (the guide's rule 3).
func _buy(g, now: float, plan: Dictionary, wanted: Dictionary) -> void:
	var wait := 0.0
	for step in _needs(g, plan, wanted):
		if step.cost <= g.cash:
			if step.buy.call():
				_note(now, step.name)
			return
		var rate := income()
		wait = (step.cost - g.cash) / rate if rate > 0.0 else INF
		break
	for n in 50:
		var best := _best_payback(g)
		if best.is_empty() or best.cost > g.cash or wait > 0.0 and best.payback > wait:
			return
		if not best.buy.call():
			return
		_note(now, best.name)


## Cash a second over the last INCOME_WINDOW seconds.
func income() -> float:
	if _earned.size() < 2:
		return 0.0
	var span: float = _earned[-1][0] - _earned[0][0]
	return (_earned[-1][1] - _earned[0][1]) / span if span > 0.0 else 0.0


## The things the goal needs, in order, each {name, cost, buy}.
func _needs(g, plan: Dictionary, wanted: Dictionary) -> Array:
	var out := []
	if not g.plots.bell.owned:
		out.append({"name": "buy plot bell", "cost": g.plot_price("bell"), "buy": g.buy_plot.bind("bell")})
	for station in ["vat", "line"]:
		if g.slots(station).is_empty() and g.slot_offered(station):
			out.append({"name": "buy %s 1" % station, "cost": g.slot_price(station), "buy": g.buy_slot.bind(station)})
	# The guide's shipping rule: a truck falling behind its farm gets the
	# cheaper of Truck Speed and Truck Cargo, cheapest farm first.
	var behind := []
	for id in g.plots:
		if g.plots[id].owned and g.cargo_rate(id) < g.plot_growth(id) - 1e-9:
			var up := "truck" if g.plot_upgrade_cost(id, "truck") <= g.plot_upgrade_cost(id, "cargo") else "cargo"
			behind.append({"name": "upgrade %s.%s" % [id, up], "cost": g.plot_upgrade_cost(id, up), "buy": g.upgrade_plot.bind(id, up)})
	behind.sort_custom(func(a, b): return a.cost < b.cost)
	out.append_array(behind)
	# Crops the goal wants that its farms would take longer than SLOW_SUPPLY
	# to grow: the farm on offer growing most of that crop for its price.
	for item in wanted:
		if g.data.items[item].kind != "crop":
			continue
		var short: int = wanted[item]
		var rate := _supply(g, item)
		if short > 0 and (rate <= 0.0 or short / rate > SLOW_SUPPLY):
			var farm := _best_farm_for(g, item)
			if farm != "":
				out.append({"name": "buy plot " + farm, "cost": g.plot_price(farm), "buy": g.buy_plot.bind(farm)})
	# Recipes for the goal, then for the next slot of each station's plan.
	for item in wanted:
		if g.data.recipes.has(item) and not g.recipe_unlocked(item):
			out.append({"name": "buy recipe " + item, "cost": g.recipe_price(item), "buy": g.buy_recipe.bind(item)})
	# Another slot for the next recipe in the plan: one the goal wants, the
	# kitchen's when the goal has taken its slot, or an extra it can feed for
	# under SLOT_MINUTES of income.
	for station in ["vat", "line"]:
		var n: int = g.slots(station).size()
		var picks: Array = plan[station]
		if n >= picks.size() or not g.slot_offered(station):
			continue
		var r: String = picks[n]
		var cheap: bool = g.slot_price(station) <= income() * 60.0 * SLOT_MINUTES
		if wanted.has(r) or g.data.recipes[r].kitchen or cheap and _can_feed(g, r):
			if not g.recipe_unlocked(r):
				out.append({"name": "buy recipe " + r, "cost": g.recipe_price(r), "buy": g.buy_recipe.bind(r)})
			out.append({"name": "buy %s %d (%s)" % [station, n + 1, r], "cost": g.slot_price(station), "buy": g.buy_slot.bind(station)})
	# The next farm once every farm it owns is at the guide's level.
	var ready := true
	for id in g.plots:
		if id != "bell" and g.plots[id].owned and not g.data.plots[id].ingredient and g.plots[id].harvest < NEXT_FARM_LEVEL:
			ready = false
	if ready:
		var next := ""
		for id in g.plots:
			if not g.plots[id].owned and g.plot_offered(id) and not g.data.plots[id].ingredient:
				if next == "" or g.plot_price(id) < g.plot_price(next):
					next = id
		if next != "":
			out.append({"name": "buy plot " + next, "cost": g.plot_price(next), "buy": g.buy_plot.bind(next)})
	return out


## The unowned farm on offer growing most of a crop a second for its price.
func _best_farm_for(g, crop: String) -> String:
	var best := ""
	var best_score := 0.0
	for id in g.plots:
		if not g.plots[id].owned and g.plot_offered(id) and g.data.plots[id].crops.has(crop):
			var score: float = g.data.plots[id].crops[crop] / g.plot_price(id)
			if score > best_score:
				best = id
				best_score = score
	return best


## Crops a second its farms deliver of one crop: each farm's share of the
## slower of growing and carrying.
func _supply(g, crop: String) -> float:
	var rate := 0.0
	for id in g.plots:
		if g.plots[id].owned and g.plot_crops(id).has(crop):
			var share: float = g.crop_rate(id, crop) / maxf(g.plot_growth(id), 1e-9)
			rate += minf(g.plot_growth(id), g.cargo_rate(id)) * share
	return rate


## The farm level that pays back soonest, under PAYBACK_MAX: {name, cost,
## payback, buy}, or {} if none does.
func _best_payback(g) -> Dictionary:
	var best := {}
	var best_payback := INF
	for id in g.plots:
		var p: Dictionary = g.plots[id]
		if not p.owned:
			continue
		for upgrade in g.PLOT_UPGRADES:
			var gain := _level_gain(g, id, upgrade)
			var cost: float = g.plot_upgrade_cost(id, upgrade)
			var pb := cost / gain if gain > 0.0 else INF
			if pb <= PAYBACK_MAX and pb < best_payback:
				best_payback = pb
				best = {"name": "upgrade %s.%s" % [id, upgrade], "cost": cost, "payback": pb, "buy": g.upgrade_plot.bind(id, upgrade)}
	return best


## Dollars a second a farm level adds (IPM's guide: "focus your money on
## mining", and ship only as far as it needs): a harvest level counts in full,
## as if the truck keeps up; a truck or cargo level only for the crops it
## brings that were waiting.
func _level_gain(g, id: String, upgrade: String) -> float:
	var p: Dictionary = g.plots[id]
	var lv := {"harvest": p.harvest, "truck": p.truck, "cargo": p.cargo}
	var now_grow := _rates(g, id, lv)
	lv[upgrade] += 1
	var next := _rates(g, id, lv)
	# Trucks are kept up by the shipping rule in _needs, so only harvest
	# levels are weighed by payback.
	if upgrade == "harvest":
		return (next.grow - now_grow.grow) * now_grow.mean
	return 0.0


## A farm's growth and carrying in crops a second, and its crops' mean value,
## at these levels.
func _rates(g, id: String, lv: Dictionary) -> Dictionary:
	var crops: Dictionary = g.plot_crops(id)
	var mean := 0.0
	var share := 0.0
	for crop in crops:
		var weight := WANTED_WEIGHT if _wanted_now.has(crop) else 1.0
		mean += crops[crop] * g.value(crop) * g.fx.crop_mult.get(crop, 1.0) * weight
		share += crops[crop]
	var d: Dictionary = g.data.plots[id]
	var grow: float = g.ipm_curve(T.HARVEST_RATE, lv.harvest) * d.harvest_mult * g.fx.harvest_mult * g.hq("harvest") * share
	var carry: float = g.ipm_curve(T.TRUCK_CARGO, lv.cargo) * d.cargo_mult * g.fx.cargo * g.hq("cargo") \
		* g.ipm_curve(T.TRUCK_SPEED, lv.truck) * g.fx.truck_speed * g.hq("truck_speed") / (2.0 * d.distance)
	return {"grow": grow, "carry": carry, "mean": mean / share if share > 0.0 else 0.0}


## Dollars a second a farm brings in raw at these levels: the slower of
## growing and carrying, at its crops' mean value.
func _farm_value(g, id: String, harvest: int, truck: int, cargo: int) -> float:
	var crops: Dictionary = g.plot_crops(id)
	var mean := 0.0
	var share := 0.0
	for crop in crops:
		mean += crops[crop] * g.value(crop) * g.fx.crop_mult.get(crop, 1.0)
		share += crops[crop]
	if share <= 0.0:
		return 0.0
	var d: Dictionary = g.data.plots[id]
	var grow: float = g.ipm_curve(T.HARVEST_RATE, harvest) * d.harvest_mult * g.fx.harvest_mult * g.hq("harvest")
	var carry: float = g.ipm_curve(T.TRUCK_CARGO, cargo) * d.cargo_mult * g.fx.cargo * g.hq("cargo") \
		* g.ipm_curve(T.TRUCK_SPEED, truck) * g.fx.truck_speed * g.hq("truck_speed") / (2.0 * d.distance)
	return minf(grow * share, carry) * mean / share


## Sells the franchise and spends every credit: the better of the two rooms on
## offer (ROOM_ORDER) while it can open one, then levels on the cheapest room.
## Returns what it bought, for the report.
func sell_and_spend(g) -> Array:
	var bought := []
	if not g.prestige():
		return bought
	while true:
		var offered: Array = g.rooms_offered()
		if offered.is_empty():
			break
		var pick: String = offered[0]
		for id in ROOM_ORDER:
			if offered.has(id):
				pick = id
				break
		if not g.open_room(pick):
			break
		bought.append(pick)
	while true:
		var cheapest := ""
		for id in g.account.rooms:
			if g.can_level_room(id) and (cheapest == "" or g.room_level_cost(id) < g.room_level_cost(cheapest)):
				cheapest = id
		if cheapest == "":
			break
		g.level_room(cheapest)
		bought.append("level " + cheapest)
	return bought


func first(what: String) -> float:
	for entry in events:
		if entry[1] == what:
			return entry[0]
	return INF


func _note(now: float, what: String) -> void:
	events.append([now, what])
