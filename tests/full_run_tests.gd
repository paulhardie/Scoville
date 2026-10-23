extends SceneTree
## v0.6a's Pantry rules (docs/FULL_RUN.md V4–V7): its effects and the fork.
## V1–V3 and Q11 retired with v0.7 (SKELETON.md).

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")
const Helpers = preload("res://tests/button_tests.gd")


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


## v0.7 (SKELETON.md) retires V1–V3 and Q11: D004's markups, the old sauce
## ladder and one vat per station are Idle Planet Miner's numbers now (I1).
## The Pantry's rules (V4–V7) stay, on IPM's 1,000-crop batches.

func test_booster_concentrate_bulk() -> void:
	var g: Game = Helpers.with(["pantry_vinegar_bulk"])
	# The Cask's own harvest at Level 0, its survey's rate tweak (T3) included.
	var base: float = Game.new().ipm_curve(T.HARVEST_RATE, 0) * g.data.plots.vinegar.harvest_mult
	check(close(g.crop_rate("vinegar", "vinegar"), base * 2.0 * 2.0), "V4: the Booster doubles the Cask's harvest, and Bulk doubles it again (%.2f a second)" % g.crop_rate("vinegar", "vinegar"))
	check(g.recipe_inputs("pickled_brine").vinegar == 600, "V4: Concentrate: Pickled Brine takes 600 Vinegar, 40%% less (got %d)" % g.recipe_inputs("pickled_brine").vinegar)
	var z: Game = Helpers.with(["pantry_vinegar_concentrate", "zero_waste_1"])
	check(z.recipe_inputs("pickled_brine").vinegar == 480, "V4: with Zero-Waste I, 1,000 × 0.8 × 0.6 = 480 (got %d)" % z.recipe_inputs("pickled_brine").vinegar)


func test_reserve() -> void:
	var plain: Game = Helpers.with(["pantry_vinegar_concentrate"])
	var g: Game = Helpers.with(["pantry_vinegar_reserve"])
	for bottle in ["bistro_verde", "smoky_ancho"]:
		check(close(g.sale_price(bottle), plain.sale_price(bottle) * 1.25), "V5: Reserve on Vinegar sells %s, which takes Pickled Brine, for +25%%" % bottle)
	for bottle in ["classic_louisiana", "table_mild", "garden_hot_sauce"]:
		check(close(g.sale_price(bottle), plain.sale_price(bottle)), "V5: but not %s, which takes none" % bottle)
	check(close(g.appraisal("bistro_verde"), plain.appraisal("bistro_verde")), "V5: stock is valued as before")
	var both: Game = Helpers.with(["pantry_vinegar_reserve", "pantry_garlic_reserve"])
	check(close(both.sale_price("classic_louisiana"), plain.sale_price("classic_louisiana") * 1.25) and close(both.sale_price("bistro_verde"), plain.sale_price("bistro_verde") * 1.25), "V5: each Reserve on its own sauces")


func test_fork() -> void:
	var g: Game = Helpers.with(["pantry_vinegar_concentrate"])
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
	check(c.fork_taken("pantry_garlic_bulk") == "" and c.fork_taken("pantry_garlic_reserve") == "", "V6: other tracks are untouched")


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
