extends SceneTree
## v0.6a's rules (docs/FULL_RUN.md V1–V7): the sauce ladder's values, station
## sizing, the Pantry's effects and the fork; and Tier 6's (docs/PRESTIGE.md
## Q11; V1 covers its values).

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")
const Helpers = preload("res://tests/button_tests.gd")

const LADDER := ["table_mild", "smoky_ancho", "bistro_verde", "serrano_fire", "classic_louisiana", "cajun_red",
	"island_heat", "sweet_heat", "savina_gold", "phantom"]

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func close(a: float, b: float, eps: float = 1e-9) -> bool:
	return absf(a - b) <= eps * maxf(1.0, maxf(absf(a), absf(b)))


func run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			call(method.name)
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: full run tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## The recipe that makes an item, "" for a crop.
static func maker(g: Game, item: String) -> String:
	for id in g.data.recipes:
		if g.data.recipes[id].output == item:
			return id
	return ""


## Raw value inside an item (ECONOMY.md, D004): crops at their value, mash
## through its inputs, a bottle used as an input at its full value.
static func raw_inside(g: Game, item: String) -> float:
	var r := maker(g, item)
	if r == "":
		return g.value(item)
	var v := 0.0
	for input in g.data.recipes[r].inputs:
		var n: int = g.data.recipes[r].inputs[input]
		v += n * (g.value(input) if g.data.items[input].kind == "bottle" else raw_inside(g, input))
	return v


func test_values_follow_d004() -> void:
	var g := Game.new()
	for id in g.data.recipes:
		var r: Dictionary = g.data.recipes[id]
		var out: String = r.output
		if r.station == "vat":
			var inputs := 0.0
			for item in r.inputs:
				inputs += r.inputs[item] * g.value(item)
			check(absf(g.value(out) - 2.0 * inputs) < 0.01, "V1: %s is worth 2× its inputs (£%.2f against £%.2f)" % [out, g.value(out), 2.0 * inputs])
		else:
			var m: float = g.value(out) / raw_inside(g, out)
			check(m >= 4.9 and m <= 5.1, "V1: %s is worth 5× the raw value inside (%.2f×)" % [out, m])


func test_ladder_climbs() -> void:
	var g := Game.new()
	for i in range(1, LADDER.size()):
		var step: float = g.value(LADDER[i]) / g.value(LADDER[i - 1])
		check(step >= 1.6 and step <= 2.7, "V2: %s is ×1.6–2.7 the rung below (×%.2f)" % [LADDER[i], step])


func test_stations_feed_one_vat() -> void:
	var g := Game.new()
	for crop in ["poblano", "serrano", "tabasco", "sugar", "bonnet", "habanero", "savina", "oak", "ghost"]:
		var p: Dictionary = g.data.plots[crop]
		var r: Dictionary = g.data.recipes[maker(g, crop + "_mash") if maker(g, crop + "_mash") != "" else _mash_of(g, crop)]
		var supply: float = p["yield"] / p.seconds
		var need: float = r.inputs[crop] / r.seconds
		check(absf(supply - need) < 0.01, "V3: the %s feeds one vat at base (%.3f a second against %.3f)" % [p.name, supply, need])


static func _mash_of(g: Game, crop: String) -> String:
	for id in g.data.recipes:
		if g.data.recipes[id].station == "vat" and g.data.recipes[id].inputs.has(crop):
			return id
	return ""


func test_tier6() -> void:
	var g := Game.new()
	var top := ["phantom", "scorpion_sting", "widowmaker", "extinction_event"]
	for i in range(1, top.size()):
		var step: float = g.value(top[i]) / g.value(top[i - 1])
		check(step >= 1.6 and step <= 3.0, "Q11: %s is ×1.6–3.0 the rung below (×%.2f)" % [top[i], step])
	for crop in ["moruga", "reaper", "pepper_x"]:
		var p: Dictionary = g.data.plots[crop]
		var r: Dictionary = g.data.recipes[crop + "_mash"]
		var supply: float = p["yield"] / p.seconds
		var need: float = r.inputs[crop] / r.seconds
		check(absf(supply - need) < 0.01, "Q11: the %s feeds one vat at base (%.3f a second against %.3f)" % [p.name, supply, need])


func test_booster_concentrate_bulk() -> void:
	var g: Game = Helpers.with(["pantry_vinegar_bulk"])
	check(close(g.plot_cycle("vinegar"), g.data.plots.vinegar.seconds / 2.0), "V4: the Vinegar Booster halves the Cask's cycle")
	check(g.recipe_inputs("pickled_brine").vinegar == 6, "V4: Concentrate: Pickled Brine takes 6 Vinegar (got %d)" % g.recipe_inputs("pickled_brine").vinegar)
	check(g.recipe_inputs("pickled_brine").bell == 5, "V4: and the same Bell Peppers")
	check(g.plot_yield("vinegar") == 2 * g.data.plots.vinegar["yield"], "V4: Bulk doubles a harvest")
	var z: Game = Helpers.with(["pantry_vinegar_concentrate", "zero_waste_2"])
	check(z.recipe_inputs("pickled_brine").vinegar == 4, "V4: with Zero-Waste II, 10 × 0.8 × 0.6 rounds down to 4 (got %d)" % z.recipe_inputs("pickled_brine").vinegar)


func test_reserve() -> void:
	var plain: Game = Helpers.with(["pantry_vinegar_concentrate"])
	var g: Game = Helpers.with(["pantry_vinegar_reserve"])
	for bottle in ["bistro_verde", "serrano_fire", "cajun_red", "island_heat", "savina_gold"]:
		check(close(g.sale_price(bottle), plain.sale_price(bottle) * 1.25), "V5: Reserve on Vinegar sells %s for +25%%" % bottle)
	for bottle in ["classic_louisiana", "phantom", "table_mild"]:
		check(close(g.sale_price(bottle), plain.sale_price(bottle)), "V5: but not %s, which takes Brine only through a mash, or none" % bottle)
	check(close(g.appraisal("bistro_verde"), plain.appraisal("bistro_verde")), "V5: stock is valued as before")
	var both: Game = Helpers.with(["pantry_vinegar_reserve", "pantry_garlic_reserve"])
	check(close(both.sale_price("cajun_red"), plain.sale_price("cajun_red") * 1.5), "V5: Cajun Red takes both, so +50%")


func test_fork() -> void:
	var g: Game = Helpers.with(["pantry_vinegar_concentrate", "paste_blueprint"])
	for item in g.stock:
		g.stock[item] = 100000
	check(g.can_research("pantry_vinegar_bulk") and g.can_research("pantry_vinegar_reserve"), "V6: both sides are open before the choice")
	check(g.research_node("pantry_vinegar_bulk"), "V6: Bulk can be researched")
	check(not g.can_research("pantry_vinegar_reserve") and not g.research_node("pantry_vinegar_reserve"), "V6: then Reserve can't")
	check(g.fork_taken("pantry_vinegar_reserve") == "pantry_vinegar_bulk", "V6: Reserve shows Bulk was chosen")
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(g.to_state()))) == "", "V6: the save loads")
	c.account.best_ov = 1e9
	for item in c.stock:
		c.stock[item] = 100000
	check(not c.can_research("pantry_vinegar_reserve"), "V6: and the fork stays chosen")
	check(c.can_research("pantry_garlic_booster"), "V6: other tracks are untouched")


func test_bad_fork_data() -> void:
	var raw := {}
	for name in DataLoader.FILES:
		raw[name] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))
	for n in raw.tech.nodes:
		if n.id == "pantry_vinegar_reserve":
			n.excludes = []
	var result := DataLoader.check(raw)
	var named := false
	for e in result.errors:
		named = named or String(e).contains("doesn't exclude it back")
	check(result.data.is_empty() and named, "V7: a one-sided fork fails at load: %s" % str(result.errors))


func test_every_node_reachable() -> void:
	# Researching everything in file order (skipping a fork's second side) must
	# reach every node but the sides not taken: no node hangs off nothing. After
	# a sale, so the after-sale nodes count too.
	var g: Game = Helpers.with([])
	g.account.prestiges = 1
	for item in g.stock:
		g.stock[item] = 10000000
	var done := 0
	for id in g.data.tech_order:
		if g.research_node(id):
			done += 1
	var forks := 0
	for id in g.data.tech:
		if g.fork_taken(id) != "":
			forks += 1
	check(done + forks + 1 == g.data.tech.size(), "V7: every node can be researched in file order (%d done, %d forks not taken, of %d)" % [done, forks, g.data.tech.size()])
