extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## tick(), then read the state; they never change it themselves
## (docs/ONBOARDING.md, FACTORY.md, ECONOMY.md, TECH_TREE.md). Deterministic:
## time only moves through tick(), and every chance draws from one seeded stream
## whose state is saved (D017).
##
## The run (everything a Prestige will reset) is kept apart from the account
## (what survives it): `account` holds only the best Operation Value so far,
## which is what opens tabs.

const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 5

## Slack when comparing summed ticks with a cycle length, so 8 × 0.1 s counts
## as 0.8 s despite float rounding.
const EPSILON := 1e-6

const TABS := ["farms", "processing", "tech", "roster", "hq"]
const PLOT_UPGRADES := ["speed", "yield", "quality"]

var data: Dictionary

# --- The run ---
var cash := 0.0
var stock := {}                 # item id → count
var revealed := {"counter": false, "status_bar": false, "deck": false}
var plots := {}                 # crop → {owned, speed, yield, quality, progress}
var vats: Array = []            # slots in buying order: {recipe, speed, progress, running, taken}
var lines: Array = []           # the same, plus crate: Starter Crate bottles left
var research := {}              # node id → true
var autosell := {}              # bottle id → percent sold at once (Delivery Van)
var autosell_acc := {}          # bottle id → percent carried towards the next sale
var heat := 0.0                 # 0–100 (D011)
var holding := false            # the button held down (Ergonomic Grip); input, not saved
var press_acc := {"grip": 0.0, "piston": 0.0}
var overdrive := {"until": 0, "ready": 0}       # ticks
var keep := {}                  # item → keep amount set by the player; -1 = valve off for it
var pin := ""                   # the node Smart Stockpiling saves for
var ticker := {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}   # ticks
var byproduct_ready := 0        # tick from which Byproduct Recycling may give a level
var stats := {}
var rng := RandomNumberGenerator.new()

# --- The account ---
var account := {"best_ov": 0.0}

## What research adds up to, worked out when research changes (_refresh_fx).
var fx := {}


func _init(game_data: Dictionary = {}, seed_value: int = 0) -> void:
	data = game_data if not game_data.is_empty() else DataLoader.default_data()
	rng.seed = seed_value
	for item in data.items:
		stock[item] = 0
	for crop in data.plots:
		plots[crop] = {"owned": false, "speed": 0, "yield": 0, "quality": 0, "progress": 0.0}
	for item in data.items:
		if data.items[item].kind == "bottle":
			autosell[item] = 100
			autosell_acc[item] = 0
	research = {"kitchen_table": true}
	stats = _new_stats()
	_refresh_fx()


func _new_stats() -> Dictionary:
	var s := {"presses": 0, "doubles": 0, "bell_picked": 0, "cash_earned": 0.0, "ticks": 0, "researched": 0,
		"free_levels": 0, "spikes": 0, "harvested": {}, "made": {}, "sold": {}, "consumed": {}}
	for item in data.items:
		for k in ["harvested", "made", "sold", "consumed"]:
			s[k][item] = 0
	return s


## Sums every researched node's effects (D010). Called whenever research changes.
func _refresh_fx() -> void:
	fx = {"van": false, "tap_bonus": 0, "double": 0.0, "grip": 0.0, "heat": false, "heat_drain": 1.0,
		"overclock": 0.0, "piston": 0.0, "plot_speed": {}, "slot_cap": {"vat": 0, "line": 0}, "packaging": 1.0,
		"reduction": 0.0, "overdrive": false, "valve": false, "stockpile": false, "ticker": false,
		"byproduct": 0.0, "stock_bonus": 0.0, "offline_hours": 0.0, "offline_speed": 0.0, "plots": {}, "recipes": {}}
	for node in research:
		for e in data.tech[node].effects:
			var kind: String = e.keys()[0]
			var v: Variant = e[kind]
			match kind:
				"unlock_plot": fx.plots[v] = true
				"unlock_recipe": fx.recipes[v] = true
				"delivery_van": fx.van = true
				"tap_yield": fx.tap_bonus += int(v)
				"double_tap": fx.double = maxf(fx.double, v)
				"grip": fx.grip = maxf(fx.grip, v)
				"heat_meter": fx.heat = true
				"heat_drain": fx.heat_drain = minf(fx.heat_drain, v)
				"overclock": fx.overclock = maxf(fx.overclock, v)
				"piston": fx.piston = maxf(fx.piston, v)
				"plot_speed": fx.plot_speed[v.crop] = fx.plot_speed.get(v.crop, 1.0) * v.mult
				"slot_cap":
					for st in v:
						fx.slot_cap[st] += int(v[st])
				"packaging": fx.packaging = maxf(fx.packaging, v)
				"input_reduction": fx.reduction = maxf(fx.reduction, v)
				"overdrive": fx.overdrive = true
				"overflow_valve": fx.valve = true
				"smart_stockpiling": fx.stockpile = true
				"market_ticker": fx.ticker = true
				"byproduct_recycling": fx.byproduct = maxf(fx.byproduct, v)
				"stock_value_bonus": fx.stock_bonus += v
				"offline":
					fx.offline_hours += v.hours
					fx.offline_speed += v.speed
	# Worked out once per research change: recipe inputs after Zero-Waste
	# Piping, and the valve's default keep amounts.
	fx.inputs = {}
	for id in data.recipes:
		fx.inputs[id] = _inputs_after_reduction(id)
	fx.default_keep = {}
	for item in data.items:
		var n := 0
		for id in data.recipes:
			if recipe_unlocked(id):
				n += fx.inputs[id].get(item, 0) * T.OVERFLOW_KEEP_CYCLES
		fx.default_keep[item] = n


# --- Reading: value and reveals ------------------------------------------------

## An item's base value (ECONOMY.md, D004).
func value(item: String) -> float:
	return data.items[item].value


## What an item counts for in Operation Value: bottles with packaging, and stock
## with Franchise Auditors.
func appraisal(item: String) -> float:
	var v := value(item)
	if data.items[item].kind == "bottle":
		v *= fx.packaging
	return v * (1.0 + fx.stock_bonus)


## What an item sells for before Heat: bottles with packaging and any spike.
func sale_price(item: String) -> float:
	var v := value(item)
	if data.items[item].kind == "bottle":
		v *= fx.packaging
		if ticker.sauce == item:
			v *= ticker.mult
	return v


## Heat's multiplier on all sale cash (D011).
func heat_mult() -> float:
	return 1.0 + T.HEAT_BONUS * heat / T.HEAT_MAX


## Cash earned this run plus everything in stock at its appraisal (ECONOMY.md).
func operation_value() -> float:
	var v: float = stats.cash_earned
	for item in stock:
		if stock[item] > 0:
			v += stock[item] * appraisal(item)
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
	return fx.van


func now_seconds() -> float:
	return stats.ticks * T.TICK_SECONDS


func _ticks(seconds: float) -> int:
	return roundi(seconds / T.TICK_SECONDS)


# --- Reading: the button -------------------------------------------------------

## Bell Peppers a press picks: the base plus the North Wing's bonuses.
func tap_yield() -> int:
	return T.BUTTON_BASE_YIELD + fx.tap_bonus


# --- Reading: plots ------------------------------------------------------------

func plot_unlocked(crop: String) -> bool:
	return data.plots[crop].unlocked or fx.plots.has(crop)


func plot_offered(crop: String) -> bool:
	return revealed.deck and plot_unlocked(crop)


func plot_price(crop: String) -> float:
	return data.plots[crop].price


func plot_cycle(crop: String) -> float:
	return data.plots[crop].seconds / (1.0 + T.PLOT_SPEED_STEP * plots[crop].speed) / fx.plot_speed.get(crop, 1.0)


func plot_yield(crop: String) -> int:
	return data.plots[crop]["yield"] + plots[crop]["yield"]


## The chance a harvest gives double (Crop Quality, D016).
func quality_chance(crop: String) -> float:
	return T.CROP_QUALITY_STEP * plots[crop].quality


## "speed", "yield" or "quality".
func plot_upgrade_cost(crop: String, upgrade: String) -> float:
	var scale := sqrt(maxf(plot_price(crop), T.PLOT_PRICE_REFERENCE) / T.PLOT_PRICE_REFERENCE)
	var lv: int = plots[crop][upgrade]
	match upgrade:
		"speed":
			return T.PLOT_SPEED_COST * scale * pow(T.PLOT_SPEED_GROWTH, lv)
		"yield":
			return T.PLOT_YIELD_COST * scale * pow(T.PLOT_YIELD_GROWTH, lv)
		"quality":
			return T.CROP_QUALITY_COST * scale * pow(T.CROP_QUALITY_GROWTH, lv) if lv < T.CROP_QUALITY_MAX else INF
	return INF


func can_buy_plot(crop: String) -> bool:
	return plots.has(crop) and plot_offered(crop) and not plots[crop].owned and cash >= plot_price(crop)


func can_upgrade_plot(crop: String, upgrade: String) -> bool:
	return plots.has(crop) and plots[crop].owned and upgrade in PLOT_UPGRADES and cash >= plot_upgrade_cost(crop, upgrade)


# --- Reading: slots and recipes ------------------------------------------------

func slots(station: String) -> Array:
	return vats if station == "vat" else lines


## Run 1's base cap plus Slot Expansion.
func slot_cap(station: String) -> int:
	return mini(data.slots[station].base_cap + fx.slot_cap[station], data.slots[station].prices.size())


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
	var ref := T.VAT_PRICE_REFERENCE if station == "vat" else T.LINE_PRICE_REFERENCE
	var scale := sqrt(maxf(data.slots[station].prices[index], ref) / ref)
	var lv: int = slots(station)[index].speed
	if station == "vat":
		return T.VAT_SPEED_COST * scale * pow(T.VAT_SPEED_GROWTH, lv)
	return T.LINE_SPEED_COST * scale * pow(T.LINE_SPEED_GROWTH, lv)


func can_upgrade_slot(station: String, index: int) -> bool:
	return index >= 0 and index < slots(station).size() and cash >= slot_upgrade_cost(station, index)


func recipe_unlocked(recipe: String) -> bool:
	return data.recipes.has(recipe) and (data.recipes[recipe].unlocked or fx.recipes.has(recipe))


## Recipes a slot of this station can run now, in data order.
func recipes_for(station: String) -> Array:
	var out := []
	for id in data.recipes:
		if data.recipes[id].station == station and recipe_unlocked(id):
			out.append(id)
	return out


## A recipe's inputs now: a vat's raw crops cut by Zero-Waste Piping, rounded
## down, at least 1 (brief §6's Cooperage rule). Cached in fx.
func recipe_inputs(recipe: String) -> Dictionary:
	return fx.inputs[recipe]


func _inputs_after_reduction(recipe: String) -> Dictionary:
	var r: Dictionary = data.recipes[recipe]
	if r.station != "vat" or fx.reduction <= 0.0:
		return r.inputs
	var out := {}
	for item in r.inputs:
		var n: int = r.inputs[item]
		if data.items[item].kind == "crop":
			n = maxi(1, floori(n * (1.0 - fx.reduction) + 1e-9))
		out[item] = n
	return out


## Vat and line speed from Overdrive: Turbines always, the button while it runs.
func factory_speed() -> float:
	var m := 1.0
	if fx.overdrive:
		m *= 1.0 + T.TURBINE_SPEED
	if overdrive_active():
		m *= T.OVERDRIVE_BOOST
	return m


## Seconds a slot's cycle takes now, Starter Crate and Overdrive included. INF
## when it's off.
func slot_cycle(station: String, index: int) -> float:
	var s: Dictionary = slots(station)[index]
	if s.recipe == "":
		return INF
	var step := T.VAT_SPEED_STEP if station == "vat" else T.LINE_SPEED_STEP
	var crate := T.STARTER_CRATE_SPEED if station == "line" and s.crate > 0 else 1.0
	return data.recipes[s.recipe].seconds / (1.0 + step * s.speed) / crate / factory_speed()


func overdrive_active() -> bool:
	return stats.ticks < overdrive.until


func can_overdrive() -> bool:
	return fx.overdrive and stats.ticks >= overdrive.ready


# --- Reading: research, the valve and the market --------------------------------

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


## How many of an item the pinned node still needs held back (Smart Stockpiling).
func pinned_need(item: String) -> int:
	if pin == "" or is_researched(pin):
		return 0
	return data.tech[pin].cost.get(item, 0)


## The valve's keep amount for a crop or mash (D014): the player's, or 5 cycles
## of the researched recipes that use it. -1 means the valve leaves it alone.
func keep_amount(item: String) -> int:
	if keep.has(item):
		return keep[item]
	return default_keep(item)


func default_keep(item: String) -> int:
	return fx.default_keep[item]


## Sauces that can be made now, for the Market Ticker.
func unlocked_bottles() -> Array:
	var out := []
	for r in recipes_for("line"):
		out.append(data.recipes[r].output)
	return out


func can_sell_raw() -> bool:
	return revealed.status_bar and stock.bell > 0


func bottles_held() -> int:
	var n := 0
	for item in stock:
		if data.items[item].kind == "bottle":
			n += stock[item]
	return n


## What Sell Batch would bring in now, Heat included.
func bottles_value() -> float:
	var v := 0.0
	for item in stock:
		if data.items[item].kind == "bottle":
			v += stock[item] * sale_price(item)
	return v * heat_mult()


# --- Actions -------------------------------------------------------------------

## One press of the Blank Button. Returns the Bell Peppers it picked.
func press() -> int:
	var picked := _press()
	_note_value()
	return picked


## Holding the button down (Ergonomic Grip presses it while held).
func set_holding(on: bool) -> void:
	holding = on


## Sells every Bell Pepper held at its value. Returns false with none.
func sell_raw() -> bool:
	if not can_sell_raw():
		return false
	_sell("bell", stock.bell)
	_note_value()
	return true


## Sells every bottle held, or every bottle of one sauce (brief §3, Sell Batch).
func sell_batch(item: String = "") -> bool:
	var sold := false
	for b in stock:
		if data.items[b].kind == "bottle" and (item == "" or item == b) and stock[b] > 0:
			_sell(b, stock[b])
			sold = true
	_note_value()
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
	var s := {"recipe": recipes_for(station)[0], "speed": 0, "progress": 0.0, "running": false, "taken": {}}
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
		for item in s.taken:
			stock[item] += s.taken[item]
			stats.consumed[item] -= s.taken[item]
	s.recipe = recipe
	s.running = false
	s.progress = 0.0
	s.taken = {}
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
	if pin == node:
		pin = ""
	var had_ticker: bool = fx.ticker
	_refresh_fx()
	if fx.ticker and not had_ticker:
		ticker.next = stats.ticks + _ticks(rng.randi_range(T.TICKER_FIRST[0], T.TICKER_FIRST[1]))
	_start_cycles()
	return true


## Sets a sauce's Auto-Sell share (Delivery Van), in AUTOSELL_STEP steps.
func set_autosell(bottle: String, percent: int) -> bool:
	if not has_van() or not autosell.has(bottle):
		return false
	autosell[bottle] = clampi(roundi(percent / float(T.AUTOSELL_STEP)) * T.AUTOSELL_STEP, 0, 100)
	return true


## Sets a crop's or mash's keep amount for the Overflow Valve; -1 leaves it
## alone, and default_keep() is what it starts at (D014).
func set_keep(item: String, amount: int) -> bool:
	if not fx.valve or not data.items.has(item) or data.items[item].kind == "bottle" or amount < -1:
		return false
	keep[item] = amount
	return true


## How much time away counts, in seconds, and the speed it runs at (D018).
func offline_cap() -> float:
	return (T.OFFLINE_HOURS + fx.offline_hours) * 3600.0


func offline_speed() -> float:
	return T.OFFLINE_SPEED + fx.offline_speed


## Puts a crop's or mash's keep amount back to its default.
func clear_keep(item: String) -> void:
	keep.erase(item)


## Pins a node for Smart Stockpiling, or "" to unpin.
func set_pin(node: String) -> bool:
	if not fx.stockpile:
		return false
	if node != "" and (not data.tech.has(node) or is_researched(node)):
		return false
	pin = node
	return true


## Factory Overdrive: doubles vat and line speed for 60 s, then 15 minutes'
## cooldown from the press (brief §4).
func activate_overdrive() -> bool:
	if not can_overdrive():
		return false
	overdrive.until = stats.ticks + _ticks(T.OVERDRIVE_SECONDS)
	overdrive.ready = stats.ticks + _ticks(T.OVERDRIVE_COOLDOWN)
	return true


# --- Time ----------------------------------------------------------------------

## Advances one fixed tick: automatic presses, Heat, plots, then vats, then
## lines (so an item made this tick can start the next station this tick), then
## the valve and the market.
func tick() -> void:
	_step(1)


## Advances `k` ticks as one step. With k = 1 this is the game's tick; the
## offline catch-up uses longer steps (D020), where a plot can harvest and a
## slot can finish several times in one step, in the same order.
func _step(k: int) -> void:
	var dt := k * T.TICK_SECONDS
	var ticks_before: int = stats.ticks
	stats.ticks += k
	if holding and fx.grip > 0.0:
		press_acc.grip += fx.grip * dt
		while press_acc.grip >= 1.0 - EPSILON:
			press_acc.grip -= 1.0
			_press()
	if fx.piston > 0.0:
		press_acc.piston += fx.piston * dt
		if k == 1:
			while press_acc.piston >= 1.0 - EPSILON:
				press_acc.piston -= 1.0
				_press()
		else:
			var n := floori(press_acc.piston + EPSILON)
			press_acc.piston -= n
			_press_batch(n)
	if heat > 0.0:
		heat = maxf(0.0, heat - T.HEAT_DRAIN * fx.heat_drain * dt)

	for crop in plots:
		var p: Dictionary = plots[crop]
		if not p.owned:
			continue
		p.progress += dt
		if k == 1:
			while p.progress >= plot_cycle(crop) - EPSILON:
				p.progress -= plot_cycle(crop)
				var n := plot_yield(crop)
				if p.quality > 0 and rng.randf() < quality_chance(crop):
					n *= 2
				stock[crop] += n
				stats.harvested[crop] += n
		else:
			_harvest_batch(crop)
	_start_cycles()
	for i in vats.size():
		if k == 1:
			_run("vat", i, dt)
		else:
			_run_batch("vat", i, dt)
	if k > 1:
		_start_cycles()
	for i in lines.size():
		if k == 1:
			_run("line", i, dt)
		else:
			_run_batch("line", i, dt)

	var every := _ticks(T.OVERFLOW_EVERY_SECONDS)
	if fx.valve and ticks_before / every != stats.ticks / every:
		_overflow()
	_market()
	_note_value()


func advance(ticks: int) -> void:
	for i in ticks:
		tick()


## A press, from a finger, Ergonomic Grip or the Piston: Double-Tap may make it
## two, and each counts for peppers, Heat and Overclock.
func _press() -> int:
	var n := 1
	if fx.double > 0.0 and rng.randf() < fx.double:
		n = 2
		stats.doubles += 1
	var picked := 0
	for i in n:
		picked += tap_yield()
		stats.presses += 1
		if fx.heat:
			heat = minf(T.HEAT_MAX, heat + T.HEAT_PER_PRESS)
		if fx.overclock > 0.0:
			for station in ["vat", "line"]:
				for j in slots(station).size():
					var s: Dictionary = slots(station)[j]
					if s.running:
						s.progress = minf(s.progress + fx.overclock, slot_cycle(station, j))
	stock.bell += picked
	stats.bell_picked += picked
	revealed.counter = true
	if stats.bell_picked >= T.STAGE_1_PEPPERS:
		revealed.status_bar = true
	return picked


## `n` automatic presses at once, for a long step (the catch-up): the same
## peppers, Heat and Overclock as n presses, with one draw for Double-Tap.
func _press_batch(n: int) -> void:
	if n <= 0:
		return
	var doubles := 0
	if fx.double > 0.0:
		if n < 12:
			for i in n:
				if rng.randf() < fx.double:
					doubles += 1
		else:
			doubles = clampi(roundi(rng.randfn(n * fx.double, sqrt(n * fx.double * (1.0 - fx.double)))), 0, n)
	var presses := n + doubles
	stats.doubles += doubles
	stats.presses += presses
	var picked := presses * tap_yield()
	stock.bell += picked
	stats.bell_picked += picked
	if fx.heat:
		heat = minf(T.HEAT_MAX, heat + T.HEAT_PER_PRESS * presses)
	if fx.overclock > 0.0:
		for station in ["vat", "line"]:
			for j in slots(station).size():
				var s: Dictionary = slots(station)[j]
				if s.running:
					s.progress = minf(s.progress + fx.overclock * presses, slot_cycle(station, j))


## A long step's harvests at once (the catch-up, D020): every whole cycle in the
## step, with one draw for how many come up double (a binomial, by its normal
## approximation once there are enough).
func _harvest_batch(crop: String) -> void:
	var p: Dictionary = plots[crop]
	var cycle := plot_cycle(crop)
	var n := floori((p.progress + EPSILON) / cycle)
	if n <= 0:
		return
	p.progress -= n * cycle
	var doubled := 0
	var chance := quality_chance(crop)
	if chance > 0.0:
		if n < 12:
			for i in n:
				if rng.randf() < chance:
					doubled += 1
		else:
			doubled = clampi(roundi(rng.randfn(n * chance, sqrt(n * chance * (1.0 - chance)))), 0, n)
	var got := (n + doubled) * plot_yield(crop)
	stock[crop] += got
	stats.harvested[crop] += got


## A long step for a vat or line (the catch-up, D020): as many cycles as the
## time and the inputs allow, then a restart if it can.
func _run_batch(station: String, index: int, dt: float) -> void:
	var s: Dictionary = slots(station)[index]
	if not s.running:
		return
	if station == "line" and s.crate > 0:
		_run(station, index, dt)   # the Starter Crate changes speed mid-step
		return
	s.progress += dt
	var cycle := slot_cycle(station, index)
	var due := floori((s.progress + EPSILON) / cycle)
	if due <= 0:
		return
	var inputs := recipe_inputs(s.recipe)
	var more := due - 1
	for item in inputs:
		more = mini(more, stock[item] / inputs[item])
	for item in inputs:
		stock[item] -= more * inputs[item]
		stats.consumed[item] += more * inputs[item]
	var done := 1 + more
	s.progress -= done * cycle
	s.running = false
	s.taken = {}
	var out: String = data.recipes[s.recipe].output
	stats.made[out] += done
	if station == "line":
		for i in done:
			_bottle_made(out)
	else:
		stock[out] += done
		for i in done:
			_byproduct()
		# As in a tick, slots waiting for this mash take it at once, before
		# later vats in the step can (shared inputs such as Pickled Brine).
		_start_cycles()
	if not s.running and has_items(inputs):
		for item in inputs:
			stock[item] -= inputs[item]
			stats.consumed[item] += inputs[item]
		s.running = true
		s.taken = inputs.duplicate()
	if not s.running or done < due:
		s.progress = 0.0 if not s.running else minf(s.progress, cycle)


func _run(station: String, index: int, dt: float) -> void:
	var s: Dictionary = slots(station)[index]
	if not s.running:
		return
	s.progress += dt
	while s.running and s.progress >= slot_cycle(station, index) - EPSILON:
		s.progress -= slot_cycle(station, index)
		s.running = false
		s.taken = {}
		var out: String = data.recipes[s.recipe].output
		stats.made[out] += 1
		if station == "line":
			if s.crate > 0:
				s.crate -= 1
			_bottle_made(out)
		else:
			stock[out] += 1
			_byproduct()
		_start_cycles()
	if not s.running:
		s.progress = 0.0


## A finished bottle: with the Delivery Van, its Auto-Sell share is sold at once
## (3 in 10 at 30%), the rest goes to stock. A pinned node's bottles are kept.
func _bottle_made(bottle: String) -> void:
	if has_van() and stock[bottle] >= pinned_need(bottle):
		autosell_acc[bottle] += autosell[bottle]
		if autosell_acc[bottle] >= 100:
			autosell_acc[bottle] -= 100
			stats.sold[bottle] += 1
			_earn(sale_price(bottle) * heat_mult())
			return
	stock[bottle] += 1


## Byproduct Recycling (D013): a chance per vat cycle of a free level for the
## lowest-level plot, at most one a minute.
func _byproduct() -> void:
	if fx.byproduct <= 0.0 or stats.ticks < byproduct_ready:
		return
	if rng.randf() >= fx.byproduct:
		return
	if _free_level():
		byproduct_ready = stats.ticks + _ticks(T.BYPRODUCT_COOLDOWN)


## Gives the owned plot with the fewest levels a free level, on whichever of its
## upgrades is cheapest (D013). Returns false with no plot owned.
func _free_level() -> bool:
	var lowest := ""
	var lowest_levels := 1 << 30
	for crop in plots:
		var p: Dictionary = plots[crop]
		if p.owned and p.speed + p["yield"] + p.quality < lowest_levels:
			lowest = crop
			lowest_levels = p.speed + p["yield"] + p.quality
	if lowest == "":
		return false
	var best := ""
	for upgrade in PLOT_UPGRADES:
		if best == "" or plot_upgrade_cost(lowest, upgrade) < plot_upgrade_cost(lowest, best):
			best = upgrade
	plots[lowest][best] += 1
	stats.free_levels += 1
	return true


## The Raw Overflow Valve (D014): sells crops and mash above their keep amount,
## holding back what a pinned node needs.
func _overflow() -> void:
	for item in stock:
		if data.items[item].kind == "bottle":
			continue
		var k := keep_amount(item)
		if k < 0:
			continue
		var extra: int = stock[item] - maxi(k, pinned_need(item))
		if extra > 0:
			_sell(item, extra)


## The Market Ticker (D015): one spike at a time on an unlocked sauce.
func _market() -> void:
	if ticker.sauce != "" and stats.ticks >= ticker.ends:
		ticker.sauce = ""
		ticker.mult = 1.0
	if ticker.next < 0 or stats.ticks < ticker.next:
		return
	var sauces := unlocked_bottles()
	ticker.sauce = sauces[rng.randi_range(0, sauces.size() - 1)]
	ticker.mult = T.TICKER_MULTS[rng.randi_range(0, T.TICKER_MULTS.size() - 1)]
	ticker.ends = stats.ticks + _ticks(T.TICKER_SECONDS)
	ticker.next = stats.ticks + _ticks(rng.randi_range(T.TICKER_GAP[0], T.TICKER_GAP[1]))
	stats.spikes += 1


## Idle slots with a recipe take their inputs if the stock has them, vats before
## lines, each in buying order.
func _start_cycles() -> void:
	for station in ["vat", "line"]:
		for s in slots(station):
			if s.running or s.recipe == "":
				continue
			var inputs := recipe_inputs(s.recipe)
			if has_items(inputs):
				for item in inputs:
					stock[item] -= inputs[item]
					stats.consumed[item] += inputs[item]
				s.running = true
				s.taken = inputs.duplicate()


func _sell(item: String, count: int) -> void:
	stock[item] -= count
	stats.sold[item] += count
	_earn(count * sale_price(item) * heat_mult())


## Adds sale cash. The account's best Operation Value is noted by the step or
## action as a whole, not after every sale.
func _earn(amount: float) -> void:
	cash += amount
	stats.cash_earned += amount
	if stats.cash_earned >= T.STAGE_2_CASH - 1e-9:
		revealed.deck = true


## Keeps the account's best Operation Value, which opens tabs.
func _note_value() -> void:
	account.best_ov = maxf(account.best_ov, operation_value())


# --- Offline (docs/OFFLINE.md) -------------------------------------------------

## Catches up `seconds` of time away (D018–D020). Production runs for the
## counted time × the offline speed, with no input: no taps, Heat drains, and
## only the Piston presses. Up to 5 minutes runs tick by tick; longer runs the
## same rules in longer steps, at most OFFLINE_MAX_STEPS of them. The Market
## Ticker and Factory Overdrive don't act during it. Then the clock moves on by
## the whole time away, so every timer has really passed. Returns a report for
## the "While you were away" card.
func catch_up(seconds: float) -> Dictionary:
	var away := maxf(0.0, seconds)
	var counted := minf(away, offline_cap())
	var offline := counted * offline_speed()
	var report := {"away": away, "counted": counted, "capped": away > offline_cap() + EPSILON, "offline": offline,
		"cash_earned": 0.0, "ov": 0.0, "made": {}, "step": T.TICK_SECONDS, "steps": 0}
	if away <= 0.0:
		return report
	var ov_before := operation_value()
	var earned_before: float = stats.cash_earned
	var made_before: Dictionary = stats.made.duplicate()
	var harvested_before: Dictionary = stats.harvested.duplicate()
	var picked_before: int = stats.bell_picked
	var start_ticks: int = stats.ticks
	holding = false
	# The market and Overdrive are put aside, and the market's schedule is
	# replayed on wall-clock time afterwards.
	var saved_ticker: Dictionary = ticker.duplicate()
	ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
	var saved_overdrive_until: int = overdrive.until
	overdrive.until = 0

	var total := _ticks(offline)
	var k := 1
	if offline > T.OFFLINE_EXACT_SECONDS + EPSILON:
		k = maxi(1, ceili(total / float(T.OFFLINE_MAX_STEPS)))
	report.step = k * T.TICK_SECONDS
	while total > 0:
		var n := mini(k, total)
		_step(n)
		total -= n
		report.steps += 1

	# The clock moves on by the whole time away.
	stats.ticks = maxi(stats.ticks, start_ticks + _ticks(away))
	overdrive.until = saved_overdrive_until
	ticker = saved_ticker
	_replay_market()
	_note_value()

	report.cash_earned = stats.cash_earned - earned_before
	report.ov = operation_value() - ov_before
	for item in stats.made:
		var n: int = stats.made[item] - made_before.get(item, 0) + stats.harvested[item] - harvested_before.get(item, 0)
		if item == "bell":
			n += stats.bell_picked - picked_before   # the Piston's presses
		if n > 0:
			report.made[item] = n
	return report


## Replays the Market Ticker's schedule up to now on wall-clock time: spikes
## that started and ended while away are missed; one still running carries on.
func _replay_market() -> void:
	if ticker.next < 0:
		return
	while ticker.next <= stats.ticks:
		var start: int = ticker.next
		var sauces := unlocked_bottles()
		ticker.sauce = sauces[rng.randi_range(0, sauces.size() - 1)]
		ticker.mult = T.TICKER_MULTS[rng.randi_range(0, T.TICKER_MULTS.size() - 1)]
		ticker.ends = start + _ticks(T.TICKER_SECONDS)
		ticker.next = start + _ticks(rng.randi_range(T.TICKER_GAP[0], T.TICKER_GAP[1]))
		stats.spikes += 1
	if ticker.sauce != "" and stats.ticks >= ticker.ends:
		ticker.sauce = ""
		ticker.mult = 1.0


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
			"heat": heat,
			"press_acc": press_acc.duplicate(),
			"overdrive": overdrive.duplicate(),
			"keep": keep.duplicate(),
			"pin": pin,
			"ticker": ticker.duplicate(),
			"byproduct_ready": byproduct_ready,
			# Strings: JSON numbers are doubles and would round a 64-bit state.
			"rng": {"seed": str(rng.seed), "state": str(rng.state)},
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
		version = 3
	problem = _check(s, {"run": TYPE_DICTIONARY, "account": TYPE_DICTIONARY})
	if problem != "":
		return problem
	if version == 3:
		s = _migrate_3_to_4(s)
	# v5 only adds `saved_at` beside the run, for the screen (OFFLINE.md).
	var run: Dictionary = s.run
	problem = _check(run, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "revealed": TYPE_DICTIONARY, "plots": TYPE_DICTIONARY,
		"vats": TYPE_ARRAY, "lines": TYPE_ARRAY, "research": TYPE_ARRAY, "autosell": TYPE_DICTIONARY, "autosell_acc": TYPE_DICTIONARY,
		"heat": TYPE_FLOAT, "press_acc": TYPE_DICTIONARY, "overdrive": TYPE_DICTIONARY, "keep": TYPE_DICTIONARY, "pin": TYPE_STRING,
		"ticker": TYPE_DICTIONARY, "byproduct_ready": TYPE_FLOAT, "rng": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
	if problem != "":
		return problem
	for item in run.stock:
		if not data.items.has(item):
			return "save holds unknown item " + str(item)
	for item in run.keep:
		if not data.items.has(item):
			return "save keeps unknown item " + str(item)
	for crop in run.plots:
		if not data.plots.has(crop) or typeof(run.plots[crop]) != TYPE_DICTIONARY:
			return "save has a bad plot " + str(crop)
	for node in run.research:
		if not data.tech.has(node):
			return "save has unknown research " + str(node)
	if run.pin != "" and not data.tech.has(run.pin):
		return "save pins unknown node " + run.pin
	var t_sauce := str(run.ticker.get("sauce", ""))
	if t_sauce != "" and (not data.items.has(t_sauce) or data.items[t_sauce].kind != "bottle"):
		return "save's market spike is on unknown sauce " + t_sauce
	# Slot caps depend on research, so work that out first.
	var fresh = get_script().new(data)
	for node in run.research:
		fresh.research[node] = true
	fresh._refresh_fx()
	for station in ["vat", "line"]:
		var saved: Array = run.vats if station == "vat" else run.lines
		if saved.size() > fresh.slot_cap(station):
			return "save has more %s slots than the cap" % station
		for slot in saved:
			if typeof(slot) != TYPE_DICTIONARY:
				return "save has a bad %s slot" % station
			var r: String = str(slot.get("recipe", ""))
			if r != "" and (not data.recipes.has(r) or data.recipes[r].station != station):
				return "save's %s runs unknown recipe %s" % [station, r]
			if typeof(slot.get("taken", {})) != TYPE_DICTIONARY:
				return "save has a bad %s slot" % station
			for item in slot.get("taken", {}):
				if not data.items.has(item):
					return "save's %s slot took unknown item %s" % [station, item]

	# Everything checked: now load.
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
		plots[crop] = {"owned": bool(p.get("owned", false)), "speed": int(p.get("speed", 0)), "yield": int(p.get("yield", 0)),
			"quality": int(p.get("quality", 0)), "progress": float(p.get("progress", 0.0))}
	vats = []
	lines = []
	for station in ["vat", "line"]:
		for slot in (run.vats if station == "vat" else run.lines):
			var taken := {}
			for item in slot.get("taken", {}):
				taken[item] = int(slot.taken[item])
			var loaded := {"recipe": str(slot.get("recipe", "")), "speed": int(slot.get("speed", 0)), "progress": float(slot.get("progress", 0.0)),
				"running": bool(slot.get("running", false)), "taken": taken}
			if station == "line":
				loaded.crate = int(slot.get("crate", 0))
			slots(station).append(loaded)
	research = fresh.research
	autosell = fresh.autosell
	autosell_acc = fresh.autosell_acc
	for b in autosell:
		autosell[b] = int(run.autosell.get(b, 100))
		autosell_acc[b] = int(run.autosell_acc.get(b, 0))
	heat = clampf(float(run.heat), 0.0, T.HEAT_MAX)
	holding = false
	press_acc = {"grip": float(run.press_acc.get("grip", 0.0)), "piston": float(run.press_acc.get("piston", 0.0))}
	overdrive = {"until": int(run.overdrive.get("until", 0)), "ready": int(run.overdrive.get("ready", 0))}
	keep = {}
	for item in run.keep:
		keep[item] = int(run.keep[item])
	pin = run.pin
	ticker = {"sauce": t_sauce, "mult": float(run.ticker.get("mult", 1.0)), "ends": int(run.ticker.get("ends", 0)), "next": int(run.ticker.get("next", -1))}
	byproduct_ready = int(run.byproduct_ready)
	rng = RandomNumberGenerator.new()
	rng.seed = String(run.rng.get("seed", "0")).to_int()
	rng.state = String(run.rng.get("state", str(rng.state))).to_int()
	stats = fresh.stats
	for k in ["presses", "doubles", "bell_picked", "ticks", "researched", "free_levels", "spikes"]:
		stats[k] = int(run.stats.get(k, 0))
	stats.cash_earned = float(run.stats.get("cash_earned", 0.0))
	for k in ["harvested", "made", "sold", "consumed"]:
		var saved: Variant = run.stats.get(k, {})
		if typeof(saved) == TYPE_DICTIONARY:
			for item in saved:
				if stats[k].has(item):
					stats[k][item] = int(saved[item])
	account = {"best_ov": float(s.account.get("best_ov", 0.0))}
	_refresh_fx()
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


## v3 (v0.3) had no Heat, Crop Quality, valve, pin, Overdrive, market or random
## stream. A running slot's taken inputs were its recipe's, since v0.3 had no
## Zero-Waste Piping. The stream is seeded from the save's own figures, so the
## same save always migrates the same way (FACTORY.md, S9).
func _migrate_3_to_4(s: Dictionary) -> Dictionary:
	var out: Dictionary = s.duplicate(true)
	var run: Dictionary = out.run
	for station in ["vats", "lines"]:
		if typeof(run.get(station)) != TYPE_ARRAY:
			continue
		for slot in run[station]:
			if typeof(slot) == TYPE_DICTIONARY and bool(slot.get("running", false)) and data.recipes.has(str(slot.get("recipe", ""))):
				slot.taken = data.recipes[slot.recipe].inputs.duplicate()
	var st: Variant = run.get("stats", {})
	var seed_value := 0
	if typeof(st) == TYPE_DICTIONARY:
		seed_value = absi(hash([int(st.get("ticks", 0)), int(st.get("presses", 0)), float(st.get("cash_earned", 0.0))]))
	run.heat = 0.0
	run.press_acc = {"grip": 0.0, "piston": 0.0}
	run.overdrive = {"until": 0, "ready": 0}
	run.keep = {}
	run.pin = ""
	run.ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
	run.byproduct_ready = 0.0
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	run.rng = {"seed": str(r.seed), "state": str(r.state)}
	out.version = 4
	return out


func _check(s: Dictionary, want: Dictionary) -> String:
	for key in want:
		if not s.has(key):
			return "save is missing " + key
		var t := typeof(s[key])
		# JSON numbers come back as floats; a hand-built save may hold ints.
		if t != want[key] and not (want[key] == TYPE_FLOAT and t == TYPE_INT):
			return "save's %s is the wrong type" % key
	return ""
