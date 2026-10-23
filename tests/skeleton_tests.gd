extends SceneTree
## v0.7's copy of Idle Planet Miner (docs/SKELETON.md): Z2 (the data is the
## snapshot through the mapping with PR 3's tweaks applied, replacing I1), I2
## (the farm formulas), I3 (trucks), I5 (farms open in order) and I11's
## unreadable save.
##
## I1 reads tools/ipm/mapping.json, which tools/ipm/mapping.py builds from
## docs/ipm_snapshot.json (run_tests.sh checks it's current), and also reads
## the snapshot's own planets, ores, smelters, crafters and credits.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Main = preload("res://scenes/main.tscn")

const MAPPING := "res://tools/ipm/mapping.json"
const TWEAKS := "res://tools/ipm/tweaks.json"
const SNAPSHOT := "res://docs/ipm_snapshot.json"
## The snapshot's number suffixes (IPM's letters).
const SUFFIX := {"K": 1e3, "k": 1e3, "M": 1e6, "B": 1e9, "T": 1e12, "q": 1e15, "Q": 1e18, "s": 1e21, "S": 1e24, "O": 1e27, "N": 1e30, "D": 1e33}

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func run() -> void:
	test_copied()
	test_snapshot()
	test_formulas()
	test_trucks()
	test_farms_open()
	await test_bad_save()
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: skeleton tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


static func read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## A snapshot number: "1.45K", "10,938", "1q", "5q*" → a float, or NAN.
static func num(text: String) -> float:
	var t := text.strip_edges().replace(",", "").replace("*", "").replace(" ", "")
	var mult := 1.0
	if t != "" and SUFFIX.has(t.right(1)):
		mult = SUFFIX[t.right(1)]
		t = t.left(t.length() - 1)
	return float(t) * mult if t.is_valid_float() else NAN


## Prices tweaked to three figures may round a hair differently here.
static func close_price(a: float, b: float) -> bool:
	return absf(a - b) <= 1e-6 * maxf(1.0, maxf(absf(a), absf(b)))


static func near(a: float, b: float) -> bool:
	return absf(a - b) <= 1e-9 * maxf(1.0, maxf(absf(a), absf(b)))


## Item ids by name, for the mapping's [count, name] lists.
static func ids_by_name(g: Game) -> Dictionary:
	var out := {}
	for id in g.data.items:
		out[g.data.items[id].name] = id
	return out


## The tweak table's rows by op (Z2).
static func tweak(op: String) -> Dictionary:
	for t in read_json(TWEAKS).tweaks:
		if t.op == op:
			return t
	return {}


## Three significant figures, as build_data.py rounds tweaked prices.
static func sig3(x: float) -> float:
	if x <= 0.0:
		return x
	var scale := pow(10.0, floorf(log(x) / log(10.0)) - 2.0)
	return roundf(x / scale) * scale


## A farm's price after T1, from its mapped price.
static func tweaked_price(m: Dictionary, price: float, survey: int) -> float:
	var t := tweak("farm_price_curve")
	if t.is_empty() or survey < 1 or price <= t.anchor:
		return price
	var cap := 0.0
	for f in m.farms:
		if f.survey >= 1 and f.survey <= t.until_survey:
			cap = maxf(cap, f.price)
	return sig3(price * pow(minf(price, cap) / t.anchor, t.gamma - 1.0))


## A farm's harvest and cargo multiplier after T3 (the Bell Plot's ×4 is D052's).
static func tweaked_rate(id: String, survey: int) -> float:
	var t := tweak("farm_rate_per_survey")
	var m := 4.0 if id == "bell" else 1.0
	return m * (pow(t.factor, survey) if not t.is_empty() and survey >= 1 else 1.0)


## A survey's cost after T2.
static func tweaked_survey(cost: Dictionary, n: int) -> Dictionary:
	var t := tweak("survey_cost_scale")
	if t.is_empty():
		return cost
	var f: float = pow(t.factor, mini(n, int(t.exponent_cap)))
	var out := {}
	for item in cost:
		out[item] = maxi(1, floori(cost[item] * f + 0.5))
	return out


## A JSON cost as whole numbers.
static func counts_of(cost: Dictionary) -> Dictionary:
	var out := {}
	for item in cost:
		out[item] = roundi(cost[item])
	return out


## Slot prices after T4: the inserted price at its place.
static func tweaked_slots(prices: Array, station: String) -> Array:
	var out := prices.duplicate()
	var t := tweak("slot_insert")
	if not t.is_empty():
		out.insert(int(t.index), float(t[station]))
	return out


## Whole numbers, so JSON's floats compare with the loader's ints (Arrays
## compare strictly by type).
static func ints(a: Array) -> Array:
	return a.map(func(x): return roundi(x))


## A [count, name] list as {id: count}.
static func counts(pairs: Array, ids: Dictionary) -> Dictionary:
	var out := {}
	for pair in pairs:
		out[ids.get(pair[1], "?" + str(pair[1]))] = roundi(pair[0])
	return out


## Z2 (replacing I1): every number in data/ is the mapping's, with the tweak
## table applied.
func test_copied() -> void:
	var g := Game.new()
	var m: Dictionary = read_json(MAPPING)
	var ids := ids_by_name(g)
	var bad := []
	for p in m.peppers:
		if not g.data.items.has(p.id) or not near(g.data.items[p.id].value, p.value):
			bad.append("pepper " + p.id)
	var made: Array = m.mashes + m.sauces
	for ing in m.ingredients:
		made.append(ing.mash)
		if not near(g.data.items[ing.id].value, ing.value):
			bad.append("ingredient " + ing.id)
	for r in made:
		var data: Dictionary = g.data.recipes.get(r.id, {})
		if data.is_empty() or data.inputs != counts(r.inputs, ids) or not near(data.seconds, r.seconds) or not near(data.unlock, r.unlock) \
				or not near(g.data.items[r.id].value, r.value):
			bad.append("recipe " + r.id)
	for f in m.farms:
		var id := "bell" if f.n == 1 else "farm_%02d" % f.n
		var data: Dictionary = g.data.plots.get(id, {})
		var crops := {}
		for crop in f.crops:
			crops[crop] = roundi(f.crops[crop])
		# Loaded shares are fractions; the mapping's are percentages.
		var shares := {}
		for crop in data.get("crops", {}):
			shares[crop] = roundi(data.crops[crop] * 100.0)
		if data.is_empty() or not close_price(data.price, tweaked_price(m, f.price, f.survey)) or shares != crops or not near(data.distance, f.distance) or data.survey != f.survey:
			bad.append("farm %d" % f.n)
		elif not near(data.harvest_mult, tweaked_rate(id, f.survey)) or not near(data.cargo_mult, tweaked_rate(id, f.survey)):
			bad.append("farm %d rates" % f.n)
	# Ingredient stations: their value, and their survey's cheapest farm's price
	# and rates, tweaked like a farm's (T1, T3).
	for ing in m.ingredients:
		var data: Dictionary = g.data.plots.get(ing.id, {})
		var cheapest := INF
		for f in m.farms:
			if f.survey == ing.survey:
				cheapest = minf(cheapest, f.price)
		if data.is_empty() or data.survey != ing.survey or not close_price(data.price, tweaked_price(m, cheapest, ing.survey)) \
				or not near(data.harvest_mult, tweaked_rate(ing.id, ing.survey)) or not near(data.cargo_mult, tweaked_rate(ing.id, ing.survey)):
			bad.append("station " + ing.id)
	for s in m.surveys:
		var node: Dictionary = g.data.tech.get("survey_%d" % s.n, {})
		if node.is_empty() or node.cost != tweaked_survey(counts(s.cost, ids), s.n):
			bad.append("survey %d" % s.n)
	var nodes := {}
	for id in g.data.tech:
		nodes[g.data.tech[id].name] = id
	for p in m.projects:
		if not nodes.has(p.node) or g.data.tech[nodes[p.node]].cost != counts(p.cost, ids):
			bad.append("node " + p.node)
	var rooms := {}
	for id in g.data.rooms:
		rooms[g.data.rooms[id].name] = id
	for i in m.rooms.size():
		var r: Dictionary = m.rooms[i]
		var id: String = rooms.get(r.name, "")
		if id == "":
			bad.append("room " + r.name)
			continue
		var room: Dictionary = g.data.rooms[id]
		var order: String = g.data.room_order[i]
		var same: bool = order == id and room.open_cost == int(r.open_cost)
		if typeof(r.level_costs) == TYPE_ARRAY:
			same = same and ints(room.level_costs) == ints(r.level_costs) and room.cap == int(r.max)
		else:
			# Our own rooms take Engineering's (Seed Vault's) table (assumed).
			var engineering: Array = ints(m.rooms[0].level_costs)
			same = same and ints(room.level_costs) == engineering.slice(0, room.level_costs.size())
		if not same:
			bad.append("room " + r.name)
	for station in ["vat", "line"]:
		var prices: Array = g.data.slots[station].prices
		var want: Array = tweaked_slots(m.vats if station == "vat" else m.lines, station)
		check(prices.size() == want.size(), "Z2: %d %s prices, want %d" % [prices.size(), station, want.size()])
		for i in want.size():
			if i >= prices.size() or not near(prices[i], want[i]):
				bad.append("%s %d" % [station, i + 1])
	# Our own nodes' tweaks (T6–T8) are what the data holds.
	for t in read_json(TWEAKS).tweaks:
		match t.op:
			"node_effect":
				if JSON.stringify(g.data.tech[t.node].effects) != JSON.stringify(t.effects):
					bad.append("tweak %s" % t.id)
			"node_cost":
				if g.data.tech[t.node].cost != counts_of(t.cost):
					bad.append("tweak %s" % t.id)
			"node_cost_scale":
				for id in t.nodes:
					var want := {}
					for item in t.was[id]:
						want[item] = ceili(t.was[id][item] * t.factor)
					if g.data.tech[id].cost != want:
						bad.append("tweak %s %s" % [t.id, id])
	check(bad.is_empty(), "Z2: these differ from the mapping with its tweaks: %s" % str(bad))
	check(m.farms.size() == 79 and m.peppers.size() == 28 and m.rooms.size() == 15, "I1: 79 farms, 28 peppers and 15 rooms mapped (%d, %d, %d)" % [m.farms.size(), m.peppers.size(), m.rooms.size()])


## I1, straight from the snapshot: planets, ores, smelters, crafters and the
## credit table, apart from the rows SKELETON.md marks assumed.
func test_snapshot() -> void:
	var g := Game.new()
	var snap: Dictionary = read_json(SNAPSHOT)
	var m: Dictionary = read_json(MAPPING)
	var bad := []
	var ore_value := {}
	for ore in snap.ores:
		ore_value[ore.name] = num(ore.value)
	for p in m.peppers:
		if p.get("ore", "") != "" and ore_value.has(p.ore) and not near(g.data.items[p.id].value, ore_value[p.ore]):
			bad.append("pepper %s (%s)" % [p.id, p.ore])
	for f in m.farms:
		var planet: Dictionary = snap.planets[f.n - 1]
		var id := "bell" if f.n == 1 else "farm_%02d" % f.n
		check(planet.name == f.ipm, "I1: farm %d is %s, not %s" % [f.n, planet.name, f.ipm])
		# The Bell Plot's $50 is the kitchen's (D052); Balor's $100 prices its levels.
		var price: float = g.data.plots[id].upgrade_price if f.n == 1 else g.data.plots[id].price
		var ipm := num(planet.price) if f.n == 1 else tweaked_price(m, num(planet.price), f.survey)
		if not f.price_assumed and not close_price(price, ipm):
			bad.append("farm %d price" % f.n)
		if not f.distance_assumed and not near(g.data.plots[id].distance, num(planet.distance)):
			bad.append("farm %d distance" % f.n)
		var shares := []
		for pair in planet.ores:
			shares.append(roundi(num(pair[1])))
		var ours := []
		for crop in g.data.plots[id].crops:
			ours.append(roundi(g.data.plots[id].crops[crop] * 100.0))
		shares.sort()
		ours.sort()
		if not f.price_assumed and shares != ours:
			bad.append("farm %d shares" % f.n)
	# The first vat and line are the kitchen's (D052) and IPM's free first
	# smelter and crafter come next (T4), so IPM's n-th is our (n + shift)-th;
	# crafters 7–10 are doubled (SKELETON.md, assumed).
	var shift: int = 1 if not tweak("slot_insert").is_empty() else 0
	for i in range(1, snap.smelters.size()):
		if not near(g.data.slots.vat.prices[i + shift], num(snap.smelters[i])):
			bad.append("vat %d" % (i + 1 + shift))
	for i in range(1, 6):
		if not near(g.data.slots.line.prices[i + shift], num(snap.crafters[i])):
			bad.append("line %d" % (i + 1 + shift))
	var credits := []
	for row in snap.credits:
		credits.append(int(num(row[1])))
	check(credits == T.CREDIT_TABLE, "I1: the credit table is IPM's: %s against %s" % [str(T.CREDIT_TABLE), str(credits)])
	check(near(num(snap.credits[0][0]), T.PRESTIGE_OV), "I1: the table starts at the sale's $10M")
	check(bad.is_empty(), "I1: these differ from the snapshot: %s" % str(bad))


## I2: levels 1–60 of each farm curve, to 3 decimals, and each level's price.
func test_formulas() -> void:
	var g := Game.new()
	var bad := []
	for level in range(1, 61):
		var l := level - 1
		var harvest := 0.25 + 0.1 * l + 0.017 * l * l
		var speed := 1.0 + 0.2 * l + l * l / 75.0
		var cargo := 5.0 + 2.0 * l + 0.1 * l * l
		g.plots.farm_02.harvest = l
		g.plots.farm_02.truck = l
		g.plots.farm_02.cargo = l
		g.plots.bell.harvest = l
		g.plots.bell.truck = l
		g.plots.bell.cargo = l
		if absf(g.harvest_rate("farm_02") - harvest) > 5e-4 or absf(g.truck_speed("farm_02") - speed) > 5e-4:
			bad.append("Lv %d rate or speed" % level)
		if g.truck_cargo("farm_02") != even_round(cargo) or g.truck_cargo("bell") != even_round(cargo * 4.0):
			bad.append("Lv %d cargo (%d, want %d)" % [level, g.truck_cargo("farm_02"), even_round(cargo)])
		if absf(g.harvest_rate("bell") - 4.0 * harvest) > 5e-4:
			bad.append("Lv %d Bell Plot harvest" % level)
		for up in ["harvest", "truck", "cargo"]:
			if not near(g.plot_upgrade_cost("farm_02", up), 200.0 / 20.0 * pow(1.3, l)) or not near(g.plot_upgrade_cost("bell", up), 100.0 / 20.0 * pow(1.3, l)):
				bad.append("Lv %d %s price" % [level, up])
	check(bad.is_empty(), "I2: these differ from IPM's formulas: %s" % str(bad.slice(0, 8)))
	check(even_round(17.5) == 18 and even_round(18.5) == 18, "I2: half rounds to even")


static func even_round(x: float) -> int:
	var whole := floori(x)
	if absf(x - whole - 0.5) < 1e-9:
		return whole + (whole % 2)
	return roundi(x)


## I3: over 10 minutes a farm delivers min(growth, cargo × speed ÷ 2 × distance)
## a second within 1%, the most valuable crop first or the priority one.
func test_trucks() -> void:
	for priority in ["", "bell"]:
		var g := Game.new({}, 3)
		g.plots.farm_02.owned = true
		# Growing 9.05 a second, 1.81 of it Pimento; the truck carries 2.04.
		g.plots.farm_02.harvest = 20
		g.plots.farm_02.truck = 5
		g.plots.farm_02.cargo = 6
		if priority != "":
			g.fx.priority = true
			check(g.set_priority("farm_02", priority), "I3: Crop Priority picks Bell")
		var before := {"bell": g.stock.bell, "pimento": g.stock.pimento}
		var seconds := 600.0
		for i in roundi(seconds / T.TICK_SECONDS):
			g.tick()
		var got := 0
		for crop in before:
			got += g.stock[crop] - before[crop]
		var want := minf(g.plot_growth("farm_02"), g.truck_cargo("farm_02") * g.truck_speed("farm_02") / (2.0 * g.data.plots.farm_02.distance))
		check(absf(got / seconds - want) <= 0.01 * want, "I3: %.3f a second delivered, want %.3f (truck-bound)" % [got / seconds, want])
		var first := "pimento" if priority == "" else "bell"
		var other := "bell" if first == "pimento" else "pimento"
		var grown: float = g.crop_rate("farm_02", first) * seconds
		var first_got: int = g.stock[first] - before[first]
		check(first_got >= 0.97 * minf(grown, got), "I3: %s goes first%s: %d of %.0f grown, %d carried in all" % [first, " (Crop Priority)" if priority != "" else " (worth more)", first_got, grown, got])
		check(g.plots.farm_02.field[other] > 0, "I3: the rest waits at the farm (%d %s)" % [g.plots.farm_02.field[other], other])
	# A farm whose truck keeps up delivers all it grows.
	var g2 := Game.new({}, 3)
	g2.plots.farm_02.owned = true
	g2.plots.farm_02.truck = 30
	g2.plots.farm_02.cargo = 30
	var start: int = g2.stock.bell + g2.stock.pimento
	for i in roundi(600.0 / T.TICK_SECONDS):
		g2.tick()
	var rate: float = (g2.stock.bell + g2.stock.pimento - start) / 600.0
	check(absf(rate - g2.plot_growth("farm_02")) <= 0.01 * g2.plot_growth("farm_02"), "I3: a truck that keeps up brings all %.3f a second (%.3f)" % [g2.plot_growth("farm_02"), rate])


## I5: farms 1–4 from the start, the rest with their survey, ingredient
## stations with theirs.
func test_farms_open() -> void:
	var g := Game.new()
	var bad := []
	for survey in range(0, 26):
		if survey > 0:
			g.research["survey_%d" % survey] = true
			g._refresh_fx()
		for id in g.data.plots:
			if g.plot_offered(id) != (g.data.plots[id].survey <= survey):
				bad.append("%s at survey %d" % [id, survey])
		if survey == 0:
			var open := []
			for id in g.data.plots:
				if g.plot_offered(id):
					open.append(id)
			check(open == ["bell", "farm_02", "farm_03", "farm_04"], "I5: farms 1–4 on sale from the start: %s" % str(open))
	check(bad.is_empty(), "I5: these open out of turn: %s" % str(bad))
	var ingredient := {}
	for id in g.data.plots:
		if g.data.plots[id].get("ingredient", false):
			ingredient[id] = g.data.plots[id].survey
	check(ingredient == {"vinegar": 1, "garlic": 3, "pineapple": 4, "oak": 6}, "I5: ingredient stations with Surveys 1, 3, 4 and 6: %s" % str(ingredient))


## I11: an unreadable save is kept as save.json.bad, not overwritten.
func test_bad_save() -> void:
	var path := "user://skeleton_bad_save.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"version\": 11, \"run\": \"not a run\"}")
	f.close()
	var screen := Main.instantiate()
	screen.save_path = path
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame
	check(FileAccess.file_exists(path + ".bad"), "I11: an unreadable save is kept as .bad")
	var kept := FileAccess.get_file_as_string(path + ".bad")
	check(kept.contains("not a run"), "I11: unchanged")
	screen.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bad")
