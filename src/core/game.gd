extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## tick(), then read the state; they never change it themselves
## (docs/ONBOARDING.md, FACTORY.md, ECONOMY.md, TECH_TREE.md). Deterministic:
## time only moves through tick(), and nothing is random yet.
##
## The run (everything a Prestige will reset) is kept apart from the account
## (what survives it): `account` holds only the best Operation Value so far,
## which is what opens tabs.

const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 3

## Slack when comparing summed ticks with a cycle length, so 8 × 0.1 s counts
## as 0.8 s despite float rounding.
const EPSILON := 1e-6

const TABS := ["farms", "processing", "tech", "roster", "hq"]

var data: Dictionary

# --- The run ---
var cash := 0.0
var stock := {}                 # item id → count
var revealed := {"counter": false, "status_bar": false, "deck": false}
var plots := {}                 # crop → {owned, speed, yield, progress}
var vats: Array = []            # slots in buying order: {recipe, speed, progress, running}
var lines: Array = []           # the same, plus crate: Starter Crate bottles left
var research := {}              # node id → true
var autosell := {}              # bottle id → percent sold at once (Delivery Van)
var autosell_acc := {}          # bottle id → percent carried towards the next sale
var stats := {}

# --- The account ---
var account := {"best_ov": 0.0}


func _init(game_data: Dictionary = {}) -> void:
	data = game_data if not game_data.is_empty() else DataLoader.default_data()
	for item in data.items:
		stock[item] = 0
	for crop in data.plots:
		plots[crop] = {"owned": false, "speed": 0, "yield": 0, "progress": 0.0}
	for item in data.items:
		if data.items[item].kind == "bottle":
			autosell[item] = 100
			autosell_acc[item] = 0
	research = {"kitchen_table": true}
	stats = _new_stats()


func _new_stats() -> Dictionary:
	var s := {"presses": 0, "bell_picked": 0, "cash_earned": 0.0, "ticks": 0,
		"harvested": {}, "made": {}, "sold": {}, "consumed": {}, "researched": 0}
	for item in data.items:
		for k in ["harvested", "made", "sold", "consumed"]:
			s[k][item] = 0
	return s


# --- Reading: value and reveals ------------------------------------------------

func value(item: String) -> float:
	return data.items[item].value


## Cash earned this run plus everything in stock at its value (ECONOMY.md).
func operation_value() -> float:
	var v: float = stats.cash_earned
	for item in stock:
		v += stock[item] * value(item)
	return v


## Stage 3: the nav bar comes with the Processing tab.
func nav_shown() -> bool:
	return tab_open("processing")


func tab_open(tab: String) -> bool:
	if tab == "farms":
		return revealed.deck
	if not tab in T.TABS_BUILT:
		return false
	return account.best_ov >= T.TAB_THRESHOLDS[tab] - EPSILON


func has_van() -> bool:
	for node in research:
		for e in data.tech[node].effects:
			if e.has("delivery_van"):
				return true
	return false


# --- Reading: plots ------------------------------------------------------------

func plot_unlocked(crop: String) -> bool:
	return data.plots[crop].unlocked or _unlocked_by_research("unlock_plot", crop)


func plot_offered(crop: String) -> bool:
	return revealed.deck and plot_unlocked(crop)


func plot_price(crop: String) -> float:
	return data.plots[crop].price


func plot_cycle(crop: String) -> float:
	return data.plots[crop].seconds / (1.0 + T.PLOT_SPEED_STEP * plots[crop].speed)


func plot_yield(crop: String) -> int:
	return data.plots[crop]["yield"] + plots[crop]["yield"]


## "speed" or "yield".
func plot_upgrade_cost(crop: String, upgrade: String) -> float:
	var scale := sqrt(plot_price(crop) / data.plots.bell.price)
	var lv: int = plots[crop][upgrade]
	if upgrade == "speed":
		return T.PLOT_SPEED_COST * scale * pow(T.PLOT_SPEED_GROWTH, lv)
	return T.PLOT_YIELD_COST * scale * pow(T.PLOT_YIELD_GROWTH, lv)


func can_buy_plot(crop: String) -> bool:
	return plots.has(crop) and plot_offered(crop) and not plots[crop].owned and cash >= plot_price(crop)


func can_upgrade_plot(crop: String, upgrade: String) -> bool:
	return plots.has(crop) and plots[crop].owned and upgrade in ["speed", "yield"] and cash >= plot_upgrade_cost(crop, upgrade)


# --- Reading: slots and recipes ------------------------------------------------

func slots(station: String) -> Array:
	return vats if station == "vat" else lines


func slot_cap(station: String) -> int:
	return data.slots[station].prices.size()


## The next slot is offered: the first vat with the deck, the first line once a
## vat is owned, and more of either once the Processing tab is open (Stage 3).
func slot_offered(station: String) -> bool:
	var owned := slots(station).size()
	if not revealed.deck or owned >= slot_cap(station):
		return false
	if owned == 0:
		return station == "vat" or not vats.is_empty()
	return tab_open("processing")


func slot_price(station: String) -> float:
	var owned := slots(station).size()
	return data.slots[station].prices[owned] if owned < slot_cap(station) else INF


func can_buy_slot(station: String) -> bool:
	return slot_offered(station) and cash >= slot_price(station)


func slot_upgrade_cost(station: String, index: int) -> float:
	var prices: Array = data.slots[station].prices
	var scale := sqrt(prices[index] / prices[0])
	var lv: int = slots(station)[index].speed
	if station == "vat":
		return T.VAT_SPEED_COST * scale * pow(T.VAT_SPEED_GROWTH, lv)
	return T.LINE_SPEED_COST * scale * pow(T.LINE_SPEED_GROWTH, lv)


func can_upgrade_slot(station: String, index: int) -> bool:
	return index >= 0 and index < slots(station).size() and cash >= slot_upgrade_cost(station, index)


func recipe_unlocked(recipe: String) -> bool:
	return data.recipes.has(recipe) and (data.recipes[recipe].unlocked or _unlocked_by_research("unlock_recipe", recipe))


## Recipes a slot of this station can run now, in data order.
func recipes_for(station: String) -> Array:
	var out := []
	for id in data.recipes:
		if data.recipes[id].station == station and recipe_unlocked(id):
			out.append(id)
	return out


## Seconds a slot's cycle takes now, Starter Crate included. INF when it's off.
func slot_cycle(station: String, index: int) -> float:
	var s: Dictionary = slots(station)[index]
	if s.recipe == "":
		return INF
	var step := T.VAT_SPEED_STEP if station == "vat" else T.LINE_SPEED_STEP
	var crate := T.STARTER_CRATE_SPEED if station == "line" and s.crate > 0 else 1.0
	return data.recipes[s.recipe].seconds / (1.0 + step * s.speed) / crate


# --- Reading: research ---------------------------------------------------------

func is_researched(node: String) -> bool:
	return research.has(node)


## Every parent researched, and the tab open.
func research_reachable(node: String) -> bool:
	if not data.tech.has(node) or is_researched(node) or not tab_open("tech"):
		return false
	for need in data.tech[node].needs:
		if not is_researched(need):
			return false
	return true


func can_research(node: String) -> bool:
	return research_reachable(node) and has_items(data.tech[node].cost)


func has_items(cost: Dictionary) -> bool:
	for item in cost:
		if stock.get(item, 0) < cost[item]:
			return false
	return true


func can_sell_raw() -> bool:
	return revealed.status_bar and stock.bell > 0


func bottles_held() -> int:
	var n := 0
	for item in stock:
		if data.items[item].kind == "bottle":
			n += stock[item]
	return n


func bottles_value() -> float:
	var v := 0.0
	for item in stock:
		if data.items[item].kind == "bottle":
			v += stock[item] * value(item)
	return v


# --- Actions -------------------------------------------------------------------

## Bell Peppers a press picks: the base plus the North Wing's bonuses.
func tap_yield() -> int:
	var n := T.BUTTON_BASE_YIELD
	for node in research:
		for e in data.tech[node].effects:
			n += int(e.get("tap_yield", 0))
	return n


## One press of the Blank Button. Returns the Bell Peppers it picked.
func press() -> int:
	var picked := tap_yield()
	stats.presses += 1
	stock.bell += picked
	stats.bell_picked += picked
	revealed.counter = true
	if stats.bell_picked >= T.STAGE_1_PEPPERS:
		revealed.status_bar = true
	_note_value()
	return picked


## Sells every Bell Pepper held at its value. Returns false with none.
func sell_raw() -> bool:
	if not can_sell_raw():
		return false
	_sell("bell", stock.bell)
	return true


## Sells every bottle held, or every bottle of one sauce (brief §3, Sell Batch).
func sell_batch(item: String = "") -> bool:
	var sold := false
	for b in stock:
		if data.items[b].kind == "bottle" and (item == "" or item == b) and stock[b] > 0:
			_sell(b, stock[b])
			sold = true
	return sold


func buy_plot(crop: String) -> bool:
	if not can_buy_plot(crop):
		return false
	cash -= plot_price(crop)
	plots[crop].owned = true
	return true


func upgrade_plot(crop: String, upgrade: String) -> bool:
	if not can_upgrade_plot(crop, upgrade):
		return false
	cash -= plot_upgrade_cost(crop, upgrade)
	plots[crop][upgrade] += 1
	return true


## Buys the next vat or line slot. It starts on the station's first recipe
## (Sweet Pepper Mash, Table Mild); the first line comes with the Starter Crate.
func buy_slot(station: String) -> bool:
	if not can_buy_slot(station):
		return false
	cash -= slot_price(station)
	var s := {"recipe": recipes_for(station)[0], "speed": 0, "progress": 0.0, "running": false}
	if station == "line":
		s.crate = T.STARTER_CRATE_BOTTLES if lines.is_empty() else 0
	slots(station).append(s)
	_start_cycles()
	return true


func upgrade_slot(station: String, index: int) -> bool:
	if not can_upgrade_slot(station, index):
		return false
	cash -= slot_upgrade_cost(station, index)
	slots(station)[index].speed += 1
	return true


## Sets a slot's recipe, or "" to switch it off. Inputs already taken for the
## cycle go back to stock and its progress is lost (S2).
func assign(station: String, index: int, recipe: String) -> bool:
	if index < 0 or index >= slots(station).size():
		return false
	if recipe != "" and not recipe in recipes_for(station):
		return false
	var s: Dictionary = slots(station)[index]
	if s.recipe == recipe:
		return true
	if s.running:
		for item in data.recipes[s.recipe].inputs:
			stock[item] += data.recipes[s.recipe].inputs[item]
			stats.consumed[item] -= data.recipes[s.recipe].inputs[item]
	s.recipe = recipe
	s.running = false
	s.progress = 0.0
	_start_cycles()
	return true


## Researches a node by turning in its cost (brief §4: instant).
func research_node(node: String) -> bool:
	if not can_research(node):
		return false
	var cost: Dictionary = data.tech[node].cost
	for item in cost:
		stock[item] -= cost[item]
		stats.consumed[item] += cost[item]
	research[node] = true
	stats.researched += 1
	_start_cycles()
	return true


## Sets a sauce's Auto-Sell share (Delivery Van), in AUTOSELL_STEP steps.
func set_autosell(bottle: String, percent: int) -> bool:
	if not has_van() or not autosell.has(bottle):
		return false
	autosell[bottle] = clampi(roundi(percent / float(T.AUTOSELL_STEP)) * T.AUTOSELL_STEP, 0, 100)
	return true


# --- Time ----------------------------------------------------------------------

## Advances one fixed tick. Plots first, then vats, then lines, so an item made
## this tick can start the next station this tick.
func tick() -> void:
	stats.ticks += 1
	for crop in plots:
		var p: Dictionary = plots[crop]
		if not p.owned:
			continue
		p.progress += T.TICK_SECONDS
		while p.progress >= plot_cycle(crop) - EPSILON:
			p.progress -= plot_cycle(crop)
			stock[crop] += plot_yield(crop)
			stats.harvested[crop] += plot_yield(crop)
	_start_cycles()
	for i in vats.size():
		_run("vat", i)
	for i in lines.size():
		_run("line", i)
	_note_value()


func advance(ticks: int) -> void:
	for i in ticks:
		tick()


func _run(station: String, index: int) -> void:
	var s: Dictionary = slots(station)[index]
	if not s.running:
		return
	s.progress += T.TICK_SECONDS
	while s.running and s.progress >= slot_cycle(station, index) - EPSILON:
		s.progress -= slot_cycle(station, index)
		s.running = false
		var out: String = data.recipes[s.recipe].output
		stats.made[out] += 1
		if station == "line":
			if s.crate > 0:
				s.crate -= 1
			_bottle_made(out)
		else:
			stock[out] += 1
		_start_cycles()
	if not s.running:
		s.progress = 0.0


## A finished bottle: with the Delivery Van, its Auto-Sell share is sold at once
## (3 in 10 at 30%), the rest goes to stock.
func _bottle_made(bottle: String) -> void:
	if has_van():
		autosell_acc[bottle] += autosell[bottle]
		if autosell_acc[bottle] >= 100:
			autosell_acc[bottle] -= 100
			stats.sold[bottle] += 1
			_earn(value(bottle))
			return
	stock[bottle] += 1


## Idle slots with a recipe take their inputs if the stock has them, vats before
## lines, each in buying order.
func _start_cycles() -> void:
	for station in ["vat", "line"]:
		for s in slots(station):
			if s.running or s.recipe == "":
				continue
			var inputs: Dictionary = data.recipes[s.recipe].inputs
			if has_items(inputs):
				for item in inputs:
					stock[item] -= inputs[item]
					stats.consumed[item] += inputs[item]
				s.running = true


func _sell(item: String, count: int) -> void:
	stock[item] -= count
	stats.sold[item] += count
	_earn(count * value(item))


func _earn(amount: float) -> void:
	cash += amount
	stats.cash_earned += amount
	if stats.cash_earned >= T.STAGE_2_CASH - 1e-9:
		revealed.deck = true
	_note_value()


## Keeps the account's best Operation Value, which opens tabs.
func _note_value() -> void:
	account.best_ov = maxf(account.best_ov, operation_value())


func _unlocked_by_research(kind: String, target: String) -> bool:
	for node in research:
		for e in data.tech[node].effects:
			if e.get(kind) == target:
				return true
	return false


# --- Saving --------------------------------------------------------------------

func to_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"run": {
			"cash": cash,
			"stock": stock.duplicate(),
			"revealed": revealed.duplicate(),
			"plots": plots.duplicate(true),
			"vats": vats.duplicate(true),
			"lines": lines.duplicate(true),
			"research": research.keys(),
			"autosell": autosell.duplicate(),
			"autosell_acc": autosell_acc.duplicate(),
			"stats": stats.duplicate(true),
		},
		"account": account.duplicate(),
	}


## Loads a saved state, migrating older versions. Returns "" on success or a
## message saying what's wrong, in which case nothing has been changed.
func load_state(s: Variant) -> String:
	if typeof(s) != TYPE_DICTIONARY:
		return "save is not an object"
	var version := int(s.get("version", 0))
	if version < 1 or version > SAVE_VERSION:
		return "unknown save version %s" % str(s.get("version"))
	var problem := ""
	if version == 1:
		problem = _check(s, {"cash": TYPE_FLOAT, "bell": TYPE_FLOAT, "revealed": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _migrate_1_to_2(s)
		version = 2
	if version == 2:
		problem = _check(s, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "revealed": TYPE_DICTIONARY, "stations": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
		for k in ["plot", "vat", "line"]:
			if problem == "" and typeof(s.stations.get(k)) != TYPE_DICTIONARY:
				problem = "save's station %s is not an object" % k
		if problem != "":
			return problem
		s = _migrate_2_to_3(s)
	problem = _check(s, {"run": TYPE_DICTIONARY, "account": TYPE_DICTIONARY})
	if problem != "":
		return problem
	var run: Dictionary = s.run
	problem = _check(run, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "revealed": TYPE_DICTIONARY, "plots": TYPE_DICTIONARY,
		"vats": TYPE_ARRAY, "lines": TYPE_ARRAY, "research": TYPE_ARRAY, "autosell": TYPE_DICTIONARY, "autosell_acc": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
	if problem != "":
		return problem
	for item in run.stock:
		if not data.items.has(item):
			return "save holds unknown item " + str(item)
	for crop in run.plots:
		if not data.plots.has(crop) or typeof(run.plots[crop]) != TYPE_DICTIONARY:
			return "save has a bad plot " + str(crop)
	for station in ["vat", "line"]:
		var saved: Array = run.vats if station == "vat" else run.lines
		if saved.size() > slot_cap(station):
			return "save has more %s slots than the cap" % station
		for slot in saved:
			if typeof(slot) != TYPE_DICTIONARY:
				return "save has a bad %s slot" % station
			var r: String = str(slot.get("recipe", ""))
			if r != "" and (not data.recipes.has(r) or data.recipes[r].station != station):
				return "save's %s runs unknown recipe %s" % [station, r]
	for node in run.research:
		if not data.tech.has(node):
			return "save has unknown research " + str(node)

	# Everything checked: now load.
	var fresh = get_script().new(data)
	cash = float(run.cash)
	stock = fresh.stock
	for item in run.stock:
		stock[item] = int(run.stock[item])
	revealed = fresh.revealed
	for k in revealed:
		revealed[k] = bool(run.revealed.get(k, false))
	plots = fresh.plots
	for crop in run.plots:
		var p: Dictionary = run.plots[crop]
		plots[crop] = {"owned": bool(p.get("owned", false)), "speed": int(p.get("speed", 0)), "yield": int(p.get("yield", 0)), "progress": float(p.get("progress", 0.0))}
	vats = []
	for slot in run.vats:
		vats.append({"recipe": str(slot.get("recipe", "")), "speed": int(slot.get("speed", 0)), "progress": float(slot.get("progress", 0.0)), "running": bool(slot.get("running", false))})
	lines = []
	for slot in run.lines:
		lines.append({"recipe": str(slot.get("recipe", "")), "speed": int(slot.get("speed", 0)), "progress": float(slot.get("progress", 0.0)), "running": bool(slot.get("running", false)), "crate": int(slot.get("crate", 0))})
	research = {"kitchen_table": true}
	for node in run.research:
		research[node] = true
	autosell = fresh.autosell
	autosell_acc = fresh.autosell_acc
	for b in autosell:
		autosell[b] = int(run.autosell.get(b, 100))
		autosell_acc[b] = int(run.autosell_acc.get(b, 0))
	stats = fresh.stats
	for k in ["presses", "bell_picked", "ticks", "researched"]:
		stats[k] = int(run.stats.get(k, 0))
	stats.cash_earned = float(run.stats.get("cash_earned", 0.0))
	for k in ["harvested", "made", "sold", "consumed"]:
		var saved: Variant = run.stats.get(k, {})
		if typeof(saved) == TYPE_DICTIONARY:
			for item in saved:
				if stats[k].has(item):
					stats[k][item] = int(saved[item])
	account = {"best_ov": float(s.account.get("best_ov", 0.0))}
	_note_value()
	return ""


## v1 (onboarding only) had a top-level `bell` and no stations.
func _migrate_1_to_2(s: Dictionary) -> Dictionary:
	var earned := float(s.stats.get("cash_earned", 0.0))
	return {
		"version": 2,
		"cash": s.cash,
		"stock": {"bell": int(s.bell), "sweet_mash": 0, "table_mild": 0},
		"revealed": {
			"counter": bool(s.revealed.get("counter", false)),
			"status_bar": bool(s.revealed.get("status_bar", false)),
			"deck": earned >= T.STAGE_2_CASH - 1e-9,
		},
		"stations": {
			"plot": {"owned": false, "speed": 0, "yield": 0, "progress": 0.0},
			"vat": {"owned": false, "speed": 0, "progress": 0.0, "running": false},
			"line": {"owned": false, "speed": 0, "progress": 0.0, "running": false, "crate": 0},
		},
		"stats": s.stats,
	}


## v2 (the Tier 1 spine) had one plot, one vat and one line. They become the
## Bell Pepper Plot, vat slot 1 on Sweet Pepper Mash and line slot 1 on Table
## Mild, with levels, progress and crate kept (S4). The account starts from the
## run's Operation Value.
func _migrate_2_to_3(s: Dictionary) -> Dictionary:
	var st: Dictionary = s.stations
	var stats_2: Dictionary = s.stats
	var vats_3 := []
	if st.vat.get("owned", false):
		vats_3.append({"recipe": "sweet_mash", "speed": st.vat.get("speed", 0), "progress": st.vat.get("progress", 0.0), "running": st.vat.get("running", false)})
	var lines_3 := []
	if st.line.get("owned", false):
		lines_3.append({"recipe": "table_mild", "speed": st.line.get("speed", 0), "progress": st.line.get("progress", 0.0), "running": st.line.get("running", false), "crate": st.line.get("crate", 0)})
	var earned := float(stats_2.get("cash_earned", 0.0))
	var ov := earned
	for item in s.stock:
		if data.items.has(item):
			ov += float(s.stock[item]) * value(item)
	return {
		"version": 3,
		"run": {
			"cash": s.cash,
			"stock": s.stock,
			"revealed": s.revealed,
			"plots": {"bell": st.plot},
			"vats": vats_3,
			"lines": lines_3,
			"research": [],
			"autosell": {},
			"autosell_acc": {},
			"stats": {
				"presses": stats_2.get("presses", 0), "bell_picked": stats_2.get("bell_picked", 0),
				"cash_earned": earned, "ticks": stats_2.get("ticks", 0), "researched": 0,
				"harvested": {"bell": stats_2.get("bell_harvested", 0)},
				"made": {"sweet_mash": stats_2.get("mash_made", 0), "table_mild": stats_2.get("bottles_made", 0)},
				"sold": {"table_mild": stats_2.get("bottles_sold", 0)},
				"consumed": {},
			},
		},
		"account": {"best_ov": ov},
	}


func _check(s: Dictionary, want: Dictionary) -> String:
	for key in want:
		if not s.has(key):
			return "save is missing " + key
		var t := typeof(s[key])
		# JSON numbers come back as floats; a hand-built save may hold ints.
		if t != want[key] and not (want[key] == TYPE_FLOAT and t == TYPE_INT):
			return "save's %s is the wrong type" % key
	return ""
