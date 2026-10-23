extends RefCounted
## The whole simulation: state and rules, no nodes. Screens call the actions and
## tick(), then read the state; they never change it themselves
## (docs/ONBOARDING.md, FACTORY.md, ECONOMY.md, TECH_TREE.md, SKELETON.md).
## Deterministic: time only moves through tick(), and every chance draws from
## one seeded stream whose state is saved (D017).
##
## The run (everything a Prestige resets) is kept apart from the account (what
## survives it): `account` holds the best Operation Value so far (which opens
## tabs), Franchise Credits, the HQ rooms and how many times the franchise has
## been sold (docs/PRESTIGE.md).
##
## Since v0.7 the plots are Idle Planet Miner's planets as farms (D050): each
## grows a mix of crops, and its truck carries them to stock in round trips.
## `plots` and `data.plots` keep their old names; the Bell Plot is still "bell".

const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")

## Save schema version. Bump it and add a migration in load_state() whenever the
## shape of to_state() changes.
const SAVE_VERSION := 12

## Slack when comparing summed ticks with a cycle length, so 8 × 0.1 s counts
## as 0.8 s despite float rounding.
const EPSILON := 1e-6

const TABS := ["farms", "processing", "tech", "market", "roster", "hq"]
## Harvest Rate, Truck Speed and Truck Cargo (Idle Planet Miner's three).
const PLOT_UPGRADES := ["harvest", "truck", "cargo"]

var data: Dictionary

# --- The run ---
var cash := 0.0
var stock := {}                 # item id → count
## Kept in saves for older versions; since D044 everything shows from the start.
var revealed := {"counter": true, "status_bar": true, "deck": true}
## farm id → {owned, harvest, truck, cargo (levels from 0), field {crop: count},
## spare {crop: fraction}, grow (seconds to the next harvest), trip (seconds
## into the truck's round trip), priority (crop or ""), bred {from, to} or {}}
var plots := {}
var vats: Array = []            # slots in buying order: {recipe, speed, progress, running, taken, pressure}
var lines: Array = []           # the same, plus crate: Starter Crate bottles left
var research := {}              # node id → true
var bought := {}                # recipe id → true: recipes bought with cash (D051)
var bred := {}                  # Crossbreeding node id → farm id it was used on
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
var account := {"best_ov": 0.0, "credits": 0, "prestiges": 0, "rooms": {}}

## What research adds up to, worked out when research changes (_refresh_fx).
var fx := {}


func _init(game_data: Dictionary = {}, seed_value: int = 0) -> void:
	data = game_data if not game_data.is_empty() else DataLoader.default_data()
	rng.seed = seed_value
	_reset_run()


## A fresh run: everything a sale of the franchise resets (brief §6). The
## reveals and the account stay; cash starts at Seed Capital's amount.
func _reset_run() -> void:
	stock = {}
	for item in data.items:
		stock[item] = 0
	plots = {}
	for id in data.plots:
		plots[id] = _new_plot(id)
	vats = []
	lines = []
	bought = {}
	bred = {}
	autosell = {}
	autosell_acc = {}
	for item in data.items:
		if data.items[item].kind == "bottle":
			autosell[item] = 100
			autosell_acc[item] = 0
	research = {"kitchen_table": true}
	heat = 0.0
	holding = false
	press_acc = {"grip": 0.0, "piston": 0.0}
	overdrive = {"until": 0, "ready": 0}
	keep = {}
	pin = ""
	ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
	byproduct_ready = 0
	stats = _new_stats()
	cash = start_cash()
	_refresh_fx()


func _new_plot(id: String) -> Dictionary:
	var field := {}
	var spare := {}
	for crop in data.plots[id].crops:
		field[crop] = 0
		spare[crop] = 0.0
	return {"owned": false, "harvest": 0, "truck": 0, "cargo": 0, "field": field, "spare": spare, "grow": 0.0, "trip": 0.0, "priority": "", "bred": {}}


func _new_stats() -> Dictionary:
	var s := {"presses": 0, "doubles": 0, "bell_picked": 0, "cash_earned": 0.0, "spent": 0.0, "ticks": 0, "researched": 0,
		"free_levels": 0, "spikes": 0, "foraged": 0, "harvested": {}, "made": {}, "sold": {}, "consumed": {}}
	for item in data.items:
		for k in ["harvested", "made", "sold", "consumed"]:
			s[k][item] = 0
	return s


## Sums every researched node's effects (D010). Called whenever research changes.
func _refresh_fx() -> void:
	fx = {"van": false, "tap_bonus": 0, "double": 0.0, "grip": 0.0, "heat": false, "heat_drain": 1.0,
		"overclock": 0.0, "piston": 0.0, "crop_mult": {}, "concentrate": {}, "reserve": {}, "packaging": 1.0,
		"overdrive": false, "valve": false, "stockpile": false, "ticker": false,
		"byproduct": 0.0, "forage": 0.0, "bumper": 0.0, "sop": false, "stock_bonus": 0.0, "offline_hours": 0.0, "offline_speed": 0.0,
		# Idle Planet Miner's projects (SKELETON.md).
		"survey": 0, "harvest_mult": 1.0, "truck_speed": 1.0, "cargo": 1.0, "priority": false, "target": 0.0, "crossbreed": {},
		"vat_speed": 1.0, "line_speed": 1.0, "vat_cut": 0.0, "line_cut": 0.0, "mash_value": 1.0, "sauce_value": 1.0,
		"vat_double": 0.0, "line_double": 0.0, "discount": 0.0, "pressure": 0, "pressure_speed": T.PRESSURE_SPEED, "pressure_extra": T.PRESSURE_EXTRA}
	for node in research:
		for e in data.tech[node].effects:
			var kind: String = e.keys()[0]
			var v: Variant = e[kind]
			match kind:
				"survey": fx.survey = maxi(fx.survey, int(v))
				"harvest_mult": fx.harvest_mult *= v
				"truck_speed": fx.truck_speed *= v
				"cargo": fx.cargo *= v
				"crop_priority": fx.priority = true
				"target_bonus": fx.target = maxf(fx.target, v)
				"crossbreed": fx.crossbreed[node] = int(v)
				"vat_speed": fx.vat_speed *= v
				"line_speed": fx.line_speed *= v
				"vat_input_cut": fx.vat_cut = 1.0 - (1.0 - fx.vat_cut) * (1.0 - v)
				"line_input_cut": fx.line_cut = 1.0 - (1.0 - fx.line_cut) * (1.0 - v)
				"mash_value": fx.mash_value *= v
				"sauce_value": fx.sauce_value *= v
				"vat_double": fx.vat_double = maxf(fx.vat_double, v)
				"line_double": fx.line_double = maxf(fx.line_double, v)
				"station_discount": fx.discount = maxf(fx.discount, v)
				"pressure": fx.pressure += int(v)
				"pressure_speed": fx.pressure_speed = maxf(fx.pressure_speed, v)
				"pressure_extra": fx.pressure_extra = minf(fx.pressure_extra, v)
				"delivery_van": fx.van = true
				"tap_yield": fx.tap_bonus += int(v)
				"double_tap": fx.double = maxf(fx.double, v)
				"grip": fx.grip = maxf(fx.grip, v)
				"heat_meter": fx.heat = true
				"heat_drain": fx.heat_drain = minf(fx.heat_drain, v)
				"overclock": fx.overclock = maxf(fx.overclock, v)
				"piston": fx.piston = maxf(fx.piston, v)
				# The Pantry's boosters and Bulk: one crop's harvest, wherever it grows.
				"plot_speed", "plot_yield": fx.crop_mult[v.crop] = fx.crop_mult.get(v.crop, 1.0) * v.mult
				"concentrate": fx.concentrate[v.item] = maxf(fx.concentrate.get(v.item, 0.0), v.share)
				"reserve": fx.reserve[v.item] = fx.reserve.get(v.item, 0.0) + v.bonus
				"packaging": fx.packaging = maxf(fx.packaging, v)
				"overdrive": fx.overdrive = true
				"overflow_valve": fx.valve = true
				"smart_stockpiling": fx.stockpile = true
				"market_ticker": fx.ticker = true
				"sop": fx.sop = true
				"byproduct_recycling": fx.byproduct = maxf(fx.byproduct, v)
				"forage": fx.forage = maxf(fx.forage, v)
				"bumper_crop": fx.bumper += v
				"stock_value_bonus": fx.stock_bonus += v
				"offline":
					fx.offline_hours += v.hours
					fx.offline_speed += v.speed
	# HQ rooms (SKELETON.md), folded in with research: each room's value at
	# its level, base + step × (level − 1); Seed Capital's is start_cash().
	fx.hq = {}
	for id in account.rooms:
		var room: Dictionary = data.rooms[id]
		if room.effect != "start_cash":
			fx.hq[room.effect] = room.base + room.step * (account.rooms[id] - 1)
	# Worked out once per research change: recipe inputs after the cuts, and
	# the valve's default keep amounts.
	fx.inputs = {}
	for id in data.recipes:
		fx.inputs[id] = _inputs_after_reduction(id)
	# Reserve (D026): each sauce's sale bonus from the mashes its recipe takes.
	fx.sale_bonus = {}
	for id in data.recipes:
		var r: Dictionary = data.recipes[id]
		if r.station == "line":
			var bonus := 0.0
			for item in r.inputs:
				bonus += fx.reserve.get(item, 0.0)
			if bonus > 0.0:
				fx.sale_bonus[r.output] = bonus
	fx.default_keep = {}
	for item in data.items:
		var n := 0
		for id in data.recipes:
			if recipe_unlocked(id):
				n += fx.inputs[id].get(item, 0) * T.OVERFLOW_KEEP_CYCLES
		fx.default_keep[item] = n
	# Forager's Luck (D025): the most any unlocked recipe takes of each
	# ingredient a cycle; an ingredient no unlocked recipe uses isn't short.
	fx.ingredient_need = {}
	for item in data.items:
		if data.items[item].ingredient:
			for id in data.recipes:
				if recipe_unlocked(id) and fx.inputs[id].has(item):
					fx.ingredient_need[item] = maxi(fx.ingredient_need.get(item, 0), fx.inputs[id][item])


## A room's value at its level, or `none` when it isn't owned (SKELETON.md).
func hq(effect: String, none: float = 1.0) -> float:
	return fx.hq.get(effect, none)


# --- Reading: value and reveals ------------------------------------------------

## An item's base value (Idle Planet Miner's, D053; the kitchen's D004).
func value(item: String) -> float:
	return data.items[item].value


## Research and the Tasting Room on what a mash or sauce is worth (IPM's alloy
## and item values); crops sell at their value.
func _made_mult(item: String) -> float:
	match data.items[item].kind:
		"mash": return fx.mash_value * hq("value")
		"bottle": return fx.sauce_value * fx.packaging * hq("value")
	return 1.0


## What an item counts for in Operation Value: made items with their research
## and room, and stock with Franchise Auditors.
func appraisal(item: String) -> float:
	return value(item) * _made_mult(item) * (1.0 + fx.stock_bonus)


## What an item sells for before Heat: made items with research and rooms,
## sauces with Reserve (D026) and any spike.
func sale_price(item: String) -> float:
	var v := value(item) * _made_mult(item)
	if data.items[item].kind == "bottle":
		v *= 1.0 + fx.sale_bonus.get(item, 0.0)
		if ticker.sauce == item:
			v *= ticker.mult
	return v


## Heat's multiplier on all sale cash (D011).
func heat_mult() -> float:
	return 1.0 + T.HEAT_BONUS * heat / T.HEAT_MAX


## Idle Planet Miner's Galaxy Value (SKELETON.md): cash, everything spent this
## run (farms, upgrades, vats, lines, recipes, and research at its items'
## values), stock at its appraisal and crops waiting at the farms.
func operation_value() -> float:
	var v: float = cash + stats.spent
	for item in stock:
		if stock[item] > 0:
			v += stock[item] * appraisal(item)
	for id in plots:
		var p: Dictionary = plots[id]
		if p.owned:
			for crop in p.field:
				if p.field[crop] > 0:
					v += p.field[crop] * appraisal(crop)
	return v


## Whether Processing is open (it was Stage 3, when the nav bar appeared, until D044).
func nav_shown() -> bool:
	return tab_open("processing")


func tab_open(tab: String) -> bool:
	if tab == "farms":
		return true
	# Market holds the Delivery Van's levers, so it opens with the Van (LAYOUT.md).
	if tab == "market":
		return has_van()
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
	return roundi((T.BUTTON_BASE_YIELD + fx.tap_bonus) * (1.0 + hq("button_yield", 0.0)))


# --- Reading: farms (D050) -----------------------------------------------------

## On sale: farms 1–4 from the start, the rest once their Land Survey is done.
func plot_offered(id: String) -> bool:
	return data.plots.has(id) and data.plots[id].survey <= fx.survey


func plot_unlocked(id: String) -> bool:
	return plot_offered(id)


func plot_price(id: String) -> float:
	return data.plots[id].price


## a + b(L−1) + c(L−1)² at a farm's level (IPM's formulas; levels here count from 0).
static func ipm_curve(k: Array, level: int) -> float:
	return k[0] + k[1] * level + k[2] * level * level


## The crops a farm grows now, in shares: its data's, with a Crossbreeding
## applied (the bred crop's share grows the higher rung instead).
func plot_crops(id: String) -> Dictionary:
	var out: Dictionary = data.plots[id].crops.duplicate()
	var b: Dictionary = plots[id].bred
	if not b.is_empty() and out.has(b.from):
		var share: float = out[b.from]
		out.erase(b.from)
		out[b.to] = out.get(b.to, 0.0) + share
	return out


## Crops a second a farm harvests in all: IPM's Harvest Rate × research × the
## Seed Vault (the Bell Plot × 4, D052). One crop's share is boosted on top by
## the Pantry and Targeted Fertiliser (crop_rate).
func harvest_rate(id: String) -> float:
	return ipm_curve(T.HARVEST_RATE, plots[id].harvest) * data.plots[id].harvest_mult * fx.harvest_mult * hq("harvest")


## Crops a second of one crop at a farm.
func crop_rate(id: String, crop: String) -> float:
	var share: float = plot_crops(id).get(crop, 0.0)
	var m: float = fx.crop_mult.get(crop, 1.0)
	if fx.target > 0.0 and plots[id].priority == crop:
		m *= 1.0 + fx.target
	return harvest_rate(id) * share * m


## Every crop's rate at a farm, summed (what the card shows as its harvest).
func plot_growth(id: String) -> float:
	var total := 0.0
	for crop in plot_crops(id):
		total += crop_rate(id, crop)
	return total


func truck_speed(id: String) -> float:
	return ipm_curve(T.TRUCK_SPEED, plots[id].truck) * fx.truck_speed * hq("truck_speed")


## Crops a trip carries: IPM's cargo after boosts, rounded half to even.
func truck_cargo(id: String) -> int:
	var c: float = ipm_curve(T.TRUCK_CARGO, plots[id].cargo) * data.plots[id].cargo_mult * fx.cargo * hq("cargo")
	var whole := floori(c)
	if absf(c - whole - 0.5) < EPSILON:
		return whole + (whole % 2)   # a half goes to the even neighbour
	return roundi(c)


## Seconds a round trip takes: there and back at Truck Speed (G21, assumed).
func trip_seconds(id: String) -> float:
	return 2.0 * data.plots[id].distance / truck_speed(id)


## Crops a second the truck can carry (cargo every trip).
func cargo_rate(id: String) -> float:
	return truck_cargo(id) / trip_seconds(id)


## Crops waiting at a farm for the truck.
func field_total(id: String) -> int:
	var n := 0
	for crop in plots[id].field:
		n += plots[id].field[crop]
	return n


## A farm upgrade's price, `ahead` levels past its current one (for buying
## several at once, LAYOUT.md): IPM's price ÷ 20 × 1.3^level (D041), the Bell
## Plot's on Balor's $100, × the Land Office.
func plot_upgrade_cost(id: String, upgrade: String, ahead: int = 0) -> float:
	if not upgrade in PLOT_UPGRADES:
		return INF
	var lv: int = plots[id][upgrade] + ahead
	return data.plots[id].upgrade_price * T.PLOT_UPGRADE_SHARE * pow(T.PLOT_UPGRADE_GROWTH, lv) * hq("upgrade_cost")


func can_buy_plot(id: String) -> bool:
	return plots.has(id) and plot_offered(id) and not plots[id].owned and cash >= plot_price(id)


func can_upgrade_plot(id: String, upgrade: String) -> bool:
	return plots.has(id) and plots[id].owned and upgrade in PLOT_UPGRADES and cash >= plot_upgrade_cost(id, upgrade)


# --- Reading: slots and recipes ------------------------------------------------

func slots(station: String) -> Array:
	return vats if station == "vat" else lines


## Ten of each (IPM's smelters and crafters), no other cap.
func slot_cap(station: String) -> int:
	return data.slots[station].prices.size()


## The next slot is offered: the first vat with the deck, the first line once a
## vat is owned, and more of either once the Processing tab is open.
func slot_offered(station: String) -> bool:
	var owned := slots(station).size()
	if owned >= slot_cap(station):
		return false
	if owned == 0:
		return station == "vat" or not vats.is_empty()
	return tab_open("processing")


## A new slot's price: IPM's, halved by the Bulk Buyer's Club.
func slot_price(station: String) -> float:
	var owned := slots(station).size()
	return data.slots[station].prices[owned] * (1.0 - fx.discount) if owned < slot_cap(station) else INF


func can_buy_slot(station: String) -> bool:
	return slot_offered(station) and cash >= slot_price(station)


func slot_upgrade_cost(station: String, index: int, ahead: int = 0) -> float:
	var ref := T.VAT_PRICE_REFERENCE if station == "vat" else T.LINE_PRICE_REFERENCE
	var scale := pow(maxf(data.slots[station].prices[index], ref) / ref, T.COST_SCALE_POWER)
	# D031: a slot's upgrades are also priced by what it makes, so a slot
	# bottling a top sauce upgrades at its prices; whichever is dearer.
	var recipe: String = slots(station)[index].recipe
	if recipe != "":
		var ref_item: String = T.VAT_VALUE_REFERENCE if station == "vat" else T.LINE_VALUE_REFERENCE
		scale = maxf(scale, pow(value(data.recipes[recipe].output) / value(ref_item), T.COST_SCALE_POWER))
	var lv: int = slots(station)[index].speed + ahead
	if station == "vat":
		return T.VAT_SPEED_COST * scale * pow(T.VAT_SPEED_GROWTH, lv)
	return T.LINE_SPEED_COST * scale * pow(T.LINE_SPEED_GROWTH, lv)


func can_upgrade_slot(station: String, index: int) -> bool:
	return index >= 0 and index < slots(station).size() and cash >= slot_upgrade_cost(station, index)


# --- Reading: buying several levels at once (LAYOUT.md L2) ---------------------

## The price of the next `n` levels of a farm upgrade together.
func plot_upgrade_cost_n(id: String, upgrade: String, n: int) -> float:
	var total := 0.0
	for i in n:
		total += plot_upgrade_cost(id, upgrade, i)
	return total


func slot_upgrade_cost_n(station: String, index: int, n: int) -> float:
	var total := 0.0
	for i in n:
		total += slot_upgrade_cost(station, index, i)
	return total


## How many levels of a farm upgrade cash covers now (Max), up to BULK_MAX.
func plot_levels_affordable(id: String, upgrade: String) -> int:
	if not plots.has(id) or not plots[id].owned:
		return 0
	var n := 0
	var total := 0.0
	while n < T.BULK_MAX:
		total += plot_upgrade_cost(id, upgrade, n)
		if total > cash + EPSILON:
			break
		n += 1
	return n


func slot_levels_affordable(station: String, index: int) -> int:
	if index < 0 or index >= slots(station).size():
		return 0
	var n := 0
	var total := 0.0
	while n < T.BULK_MAX:
		total += slot_upgrade_cost(station, index, n)
		if total > cash + EPSILON:
			break
		n += 1
	return n


## Free recipes, and the ones bought with cash (D051).
func recipe_unlocked(recipe: String) -> bool:
	return data.recipes.has(recipe) and (data.recipes[recipe].unlock <= 0.0 or bought.has(recipe))


func recipe_price(recipe: String) -> float:
	return data.recipes[recipe].unlock


## A recipe can be bought: not yet owned, and cash covers it. Like IPM's, any
## recipe is on sale from the start; its inputs are what gate it.
func can_buy_recipe(recipe: String) -> bool:
	return data.recipes.has(recipe) and not recipe_unlocked(recipe) and cash >= recipe_price(recipe)


## Recipes a slot can run now, in data order: kitchen recipes only in the
## first vat and line (D052).
func recipes_for(station: String, index: int = 0) -> Array:
	var out := []
	for id in data.recipes:
		var r: Dictionary = data.recipes[id]
		if r.station == station and recipe_unlocked(id) and (index == 0 or not r.kitchen):
			out.append(id)
	return out


## A recipe's inputs now, after Zero-Waste Piping, the Pantry's Concentrate and
## the Cooperage or Glassworks: multiplied, rounded down, at least 1 (brief
## §6's anti-exploit rule). Cached in fx.
func recipe_inputs(recipe: String) -> Dictionary:
	return fx.inputs[recipe]


## A slot's inputs: its recipe's, and a Pressure Cooker's extra (rounded up).
func slot_inputs(station: String, index: int) -> Dictionary:
	var s: Dictionary = slots(station)[index]
	var base := recipe_inputs(s.recipe)
	if station != "vat" or not s.get("pressure", false):
		return base
	var out := {}
	for item in base:
		out[item] = ceili(base[item] * (1.0 + fx.pressure_extra) - EPSILON)
	return out


func _inputs_after_reduction(recipe: String) -> Dictionary:
	var r: Dictionary = data.recipes[recipe]
	var vat: bool = r.station == "vat"
	var cut: float = (1.0 - (fx.vat_cut if vat else fx.line_cut)) * hq("vat_input" if vat else "line_input")
	if cut >= 1.0 and (not vat or fx.concentrate.is_empty()):
		return r.inputs
	var out := {}
	for item in r.inputs:
		var n: int = r.inputs[item]
		var keep_share := cut
		if vat:
			keep_share *= 1.0 - fx.concentrate.get(item, 0.0)
		if keep_share < 1.0:
			n = maxi(1, floori(n * keep_share + 1e-9))
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


## Seconds a slot's cycle takes now, Starter Crate, Overdrive, research,
## rooms and a Pressure Cooker included. INF when it's off.
func slot_cycle(station: String, index: int) -> float:
	var s: Dictionary = slots(station)[index]
	if s.recipe == "":
		return INF
	var step := T.VAT_SPEED_STEP if station == "vat" else T.LINE_SPEED_STEP
	var crate := T.STARTER_CRATE_SPEED if station == "line" and s.crate > 0 else 1.0
	var research_speed: float = fx.vat_speed if station == "vat" else fx.line_speed
	var pressure: float = fx.pressure_speed if station == "vat" and s.get("pressure", false) else 1.0
	return data.recipes[s.recipe].seconds / (1.0 + step * s.speed) / crate / factory_speed() / research_speed / pressure / hq("vat_speed" if station == "vat" else "line_speed")


## Pressure Cookers in use, and whether another vat can go under pressure.
func pressure_used() -> int:
	var n := 0
	for s in vats:
		if s.get("pressure", false):
			n += 1
	return n


func overdrive_active() -> bool:
	return stats.ticks < overdrive.until


func can_overdrive() -> bool:
	return fx.overdrive and stats.ticks >= overdrive.ready


# --- Reading: research, the valve and the market --------------------------------

func is_researched(node: String) -> bool:
	return research.has(node)


## Every parent researched (and one of `needs_any`), and the tab open; an
## after-sale node only once the franchise has been sold (D034: now only SOP).
func research_reachable(node: String) -> bool:
	if not data.tech.has(node) or is_researched(node) or not tab_open("tech"):
		return false
	if data.tech[node].after_sale and account.prestiges < 1:
		return false
	for need in data.tech[node].needs:
		if not is_researched(need):
			return false
	var any: Array = data.tech[node].needs_any
	if not any.is_empty() and not any.any(func(n): return is_researched(n)):
		return false
	return not fork_taken(node)


## The other side of a fork already researched (D026), "" if none: then this
## node is locked for the run.
func fork_taken(node: String) -> String:
	for other in data.tech[node].excludes:
		if is_researched(other):
			return other
	return ""


## A node's cost after the Test Kitchen: max(1, round(base × its factor)) per
## item (brief §6's anti-exploit formula).
func tech_cost(node: String) -> Dictionary:
	var keep_share: float = hq("tech_cost")
	var base: Dictionary = data.tech[node].cost
	if keep_share >= 1.0:
		return base
	var out := {}
	for item in base:
		out[item] = maxi(1, roundi(base[item] * keep_share))
	return out


func can_research(node: String) -> bool:
	return research_reachable(node) and has_items(tech_cost(node))


func has_items(cost: Dictionary) -> bool:
	for item in cost:
		if stock.get(item, 0) < cost[item]:
			return false
	return true


## How many of an item the pinned node still needs held back (Smart Stockpiling).
func pinned_need(item: String) -> int:
	if pin == "" or is_researched(pin):
		return 0
	return tech_cost(pin).get(item, 0)


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
	return can_sell_crop("bell")


func can_sell_crop(crop: String) -> bool:
	return data.items.has(crop) and data.items[crop].kind == "crop" and stock[crop] > 0


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
	return sell_crop("bell")


## Sells every one of a crop held at its value, as ore sells raw (D041).
## Returns false with none.
func sell_crop(crop: String) -> bool:
	if not can_sell_crop(crop):
		return false
	_sell(crop, stock[crop])
	_note_value()
	return true


## Sells `count` of any item held (all of it with -1), as Idle Planet Miner sells
## any ore, bar or item (SKELETON.md). Returns false with none to sell.
func sell_item(item: String, count: int = -1) -> bool:
	if not stock.has(item) or stock[item] <= 0:
		return false
	_sell(item, stock[item] if count < 0 else mini(count, stock[item]))
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


func buy_plot(id: String) -> bool:
	if not can_buy_plot(id):
		return false
	_spend(plot_price(id))
	plots[id].owned = true
	return true


func upgrade_plot(id: String, upgrade: String) -> bool:
	if not can_upgrade_plot(id, upgrade):
		return false
	_spend(plot_upgrade_cost(id, upgrade))
	plots[id][upgrade] += 1
	return true


## Buys `n` levels at once, or none if cash doesn't cover all of them. Returns
## the levels bought.
func upgrade_plot_n(id: String, upgrade: String, n: int) -> int:
	if n < 1 or n > plot_levels_affordable(id, upgrade):
		return 0
	# One payment for all of them, so rounding can't stop the last level.
	_spend(minf(cash, plot_upgrade_cost_n(id, upgrade, n)))
	plots[id][upgrade] += n
	return n


## Crop Priority (IPM's Cargo Logistics): the crop a farm's truck takes first,
## and the one Targeted Fertiliser boosts; "" for the most valuable first.
func set_priority(id: String, crop: String) -> bool:
	if not fx.priority or not plots.has(id) or not plots[id].owned:
		return false
	if crop != "" and not plot_crops(id).has(crop):
		return false
	plots[id].priority = crop
	return true


## The Crossbreeding nodes researched and not yet used.
func crossbreeds_left() -> Array:
	var out := []
	for node in fx.crossbreed:
		if not bred.has(node):
			out.append(node)
	return out


## The pepper `steps` rungs above another on the ladder (D053), "" past the top
## or for an ingredient.
func rung_up(crop: String, steps: int) -> String:
	var i: int = data.ladder.find(crop)
	if i < 0 or i + steps >= data.ladder.size():
		return ""
	return data.ladder[i + steps]


## Crossbreeding (IPM's Alchemy): a node turns one of a farm's peppers into the
## pepper its rungs higher, once; a farm can only be crossbred once.
func crossbreed(node: String, id: String, crop: String) -> bool:
	if not fx.crossbreed.has(node) or bred.has(node) or not plots.has(id) or not plots[id].owned:
		return false
	if not plots[id].bred.is_empty() or not data.plots[id].crops.has(crop):
		return false
	var to := rung_up(crop, fx.crossbreed[node])
	if to == "":
		return false
	plots[id].bred = {"from": crop, "to": to}
	if not plots[id].field.has(to):
		plots[id].field[to] = 0
		plots[id].spare[to] = 0.0
	bred[node] = id
	return true


## Buys the next vat or line slot. The kitchen's (the first of each) starts on
## its recipe (Sweet Pepper Mash, Table Mild) and the first line brings the
## Starter Crate; later ones start switched off.
func buy_slot(station: String) -> bool:
	if not can_buy_slot(station):
		return false
	var index := slots(station).size()
	_spend(slot_price(station))
	var s := {"recipe": recipes_for(station, 0)[0] if index == 0 else "", "speed": 0, "progress": 0.0, "running": false, "taken": {}}
	if station == "vat":
		s.pressure = false
	else:
		s.crate = T.STARTER_CRATE_BOTTLES if lines.is_empty() else 0
	slots(station).append(s)
	_start_cycles()
	return true


func upgrade_slot(station: String, index: int) -> bool:
	if not can_upgrade_slot(station, index):
		return false
	_spend(slot_upgrade_cost(station, index))
	slots(station)[index].speed += 1
	return true


func upgrade_slot_n(station: String, index: int, n: int) -> int:
	if n < 1 or n > slot_levels_affordable(station, index):
		return 0
	_spend(minf(cash, slot_upgrade_cost_n(station, index, n)))
	slots(station)[index].speed += n
	return n


## Sets a slot's recipe, or "" to switch it off. Inputs already taken for the
## cycle go back to stock and its progress is lost (S2).
func assign(station: String, index: int, recipe: String) -> bool:
	if index < 0 or index >= slots(station).size():
		return false
	if recipe != "" and not recipe in recipes_for(station, index):
		return false
	var s: Dictionary = slots(station)[index]
	if s.recipe == recipe:
		return true
	_return_taken(s)
	s.recipe = recipe
	_start_cycles()
	return true


func _return_taken(s: Dictionary) -> void:
	if s.running:
		for item in s.taken:
			stock[item] += s.taken[item]
			stats.consumed[item] -= s.taken[item]
	s.running = false
	s.progress = 0.0
	s.taken = {}


## Puts a vat under a Pressure Cooker, or takes it off; its cycle restarts
## either way, as switching its recipe does.
func set_pressure(index: int, on: bool) -> bool:
	if index < 0 or index >= vats.size():
		return false
	var s: Dictionary = vats[index]
	if s.pressure == on:
		return true
	if on and pressure_used() >= fx.pressure:
		return false
	_return_taken(s)
	s.pressure = on
	_start_cycles()
	return true


## Buys a recipe with cash (D051, as Idle Planet Miner's alloys and items).
func buy_recipe(recipe: String) -> bool:
	if not can_buy_recipe(recipe):
		return false
	_spend(recipe_price(recipe))
	bought[recipe] = true
	_refresh_fx()
	_start_cycles()
	return true


## Researches a node by turning in its cost (brief §4: instant). What it took
## stays in Operation Value (IPM's Galaxy Value).
func research_node(node: String) -> bool:
	if not can_research(node):
		return false
	var cost: Dictionary = tech_cost(node)
	for item in cost:
		stock[item] -= cost[item]
		stats.consumed[item] += cost[item]
		stats.spent += cost[item] * appraisal(item)
	_grant(node)
	return true


## Value a second of the bottles from running lines, at base values: what
## Standard Operating Procedures measures a cost against (D034).
func bottle_rate() -> float:
	var rate := 0.0
	for i in lines.size():
		if lines[i].running:
			rate += value(data.recipes[lines[i].recipe].output) / slot_cycle("line", i)
	return rate


## A node's cost at base values, after the Test Kitchen.
func tech_cost_value(node: String) -> float:
	var cost: Dictionary = tech_cost(node)
	var v := 0.0
	for item in cost:
		v += cost[item] * value(item)
	return v


## The early run's steps, in order, for the screen to ring one at a time
## (LAYOUT.md step 2, D044).
const NEXT_STEPS := [["plot", "bell"], ["slot", "vat"], ["slot", "line"], ["sell_batch", ""], ["plot", "farm_02"],
	["plot", "farm_03"], ["tab", "tech"]]


## The next action in the early run: {"do": "press" | "sell_raw" | "sell_batch"
## | "buy_plot" | "buy_slot" | "tab", "id": the crop, station or tab}. Empty
## while the next step waits on nothing the player can do (the Tech Tree not
## yet open) and once the sequence is done.
func next_action() -> Dictionary:
	for step in NEXT_STEPS:
		match step[0]:
			"plot":
				if not plots[step[1]].owned:
					return _toward("buy_plot", step[1], plot_price(step[1]))
			"slot":
				if slots(step[1]).is_empty():
					return _toward("buy_slot", step[1], slot_price(step[1]))
			"sell_batch":
				if not _sold_a_bottle():
					return {"do": "sell_batch", "id": ""} if bottles_held() > 0 else {"do": "press", "id": ""}
			"tab":
				if stats.researched == 0:
					return {"do": "tab", "id": step[1]} if tab_open(step[1]) else {}
	return {}


## Buying something: the purchase once cash covers it, else what raises the
## cash: bottles to sell, raw peppers before the first line (when they cover
## it), or the button.
func _toward(action: String, id: String, price: float) -> Dictionary:
	if cash >= price - 1e-9:
		return {"do": action, "id": id}
	if bottles_held() > 0:
		return {"do": "sell_batch", "id": ""}
	if lines.is_empty() and stock.bell > 0 and cash + stock.bell * sale_price("bell") * heat_mult() >= price - 1e-9:
		return {"do": "sell_raw", "id": ""}
	return {"do": "press", "id": ""}


func _sold_a_bottle() -> bool:
	for item in stats.sold:
		if data.items[item].kind == "bottle" and stats.sold[item] > 0:
			return true
	return false


## The goal bar's node (LAYOUT.md): the pinned one, or else the reachable node
## whose cost is worth least; "" when nothing is reachable.
func goal_node() -> String:
	if pin != "" and research_reachable(pin):
		return pin
	var best := ""
	var best_value := INF
	for node in data.tech_order:
		if research_reachable(node):
			var v := tech_cost_value(node)
			if v < best_value:
				best = node
				best_value = v
	return best


## The cost item a node is furthest from: [item, have, need], or [] if it's free.
func scarcest_cost(node: String) -> Array:
	var cost: Dictionary = tech_cost(node)
	var out := []
	var share := INF
	for item in cost:
		var s: float = float(stock[item]) / cost[item]
		if s < share:
			share = s
			out = [item, stock[item], cost[item]]
	return out


## Standard Operating Procedures (D034): nodes the player could research whose
## cost is under the bar research themselves, free, in file order (D040: a
## cost under 1% of an hour's bottles is too small to charge). Forks are the
## player's choice.
func _sop() -> void:
	var bar: float = T.SOP_SHARE * T.SOP_WINDOW * bottle_rate()
	var due := []
	for node in data.tech_order:
		if data.tech[node].excludes.is_empty() and research_reachable(node) and tech_cost_value(node) < bar:
			due.append(node)
	for node in due:
		_grant(node)


## Marks a node researched and applies it; the caller has paid, or SOP waived it.
func _grant(node: String) -> void:
	research[node] = true
	stats.researched += 1
	if pin == node:
		pin = ""
	var had_ticker: bool = fx.ticker
	_refresh_fx()
	if fx.ticker and not had_ticker:
		ticker.next = stats.ticks + _ticks(rng.randi_range(T.TICKER_FIRST[0], T.TICKER_FIRST[1]))
	_start_cycles()


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
	return (T.OFFLINE_HOURS + fx.offline_hours + hq("offline_hours", 0.0)) * 3600.0


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

	for id in plots:
		var p: Dictionary = plots[id]
		if not p.owned:
			continue
		p.grow += dt
		var n := floori((p.grow + EPSILON) / T.HARVEST_SECONDS)
		if n > 0:
			p.grow -= n * T.HARVEST_SECONDS
			# Bumper Crop doubles a harvest: one draw a harvest, or a binomial
			# for a long step's many (D020).
			var harvests := n
			if fx.bumper > 0.0:
				harvests += (1 if rng.randf() < fx.bumper else 0) if n == 1 else _binomial(n, fx.bumper)
			_harvest(id, harvests * T.HARVEST_SECONDS)
		_haul(id, dt)
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
	var sop_every := _ticks(T.SOP_EVERY_SECONDS)
	if fx.sop and ticks_before / sop_every != stats.ticks / sop_every:
		_sop()
	_market()
	_note_value()


# --- Prestige (docs/PRESTIGE.md) ----------------------------------------------

func can_prestige() -> bool:
	return operation_value() >= T.PRESTIGE_OV - EPSILON


## Franchise Credits a sale would pay now.
func prestige_credits() -> int:
	var ov := operation_value()
	if ov < T.PRESTIGE_OV - EPSILON:
		return 0
	# Idle Planet Miner's table: straight from one decade's credits to the next.
	var decade := floori(log(ov / T.PRESTIGE_OV) / log(10.0) + 1e-9)
	var low: float = T.PRESTIGE_OV * pow(10.0, decade)
	var share := clampf((ov - low) / (9.0 * low), 0.0, 1.0)
	var credits := _credits_at(decade) + share * (_credits_at(decade + 1) - _credits_at(decade))
	return roundi(credits * hq("credits"))


## Credits at PRESTIGE_OV × 10^decade (Idle Planet Miner's table, D035).
func _credits_at(decade: int) -> float:
	var table: Array = T.CREDIT_TABLE
	if decade < table.size():
		return table[decade]
	var c: float = table[-1]
	var step: float = table[-1] - table[-2]
	for i in decade - table.size() + 1:
		step += 10.0
		c += step
	return c


## Sells the franchise: pays the credits and starts a fresh run (brief §6).
func prestige() -> bool:
	if not can_prestige():
		return false
	_note_value()
	account.credits += prestige_credits()
	account.prestiges += 1
	_reset_run()
	return true


## Starting cash from the Seed Capital Office.
func start_cash() -> float:
	for id in account.rooms:
		var room: Dictionary = data.rooms[id]
		if room.effect == "start_cash":
			var lv: int = account.rooms[id]
			var amounts: Array = room.amounts
			if lv <= amounts.size():
				return amounts[lv - 1]
			return amounts[-1] * pow(room.growth, lv - amounts.size())
	return 0.0


## The rooms on offer: the first unowned ones in rooms.json's order, two at a
## time (Idle Planet Miner's, SKELETON.md).
func rooms_offered() -> Array:
	var out := []
	for id in data.room_order:
		if not account.rooms.has(id):
			out.append(id)
			if out.size() >= T.ROOMS_OFFERED:
				break
	return out


## The n-th room bought costs the n-th row's opening price, whichever room it is.
func room_open_cost() -> int:
	var n: int = account.rooms.size()
	return data.rooms[data.room_order[n]].open_cost if n < data.room_order.size() else 1 << 30


func can_open_room(id: String) -> bool:
	return id in rooms_offered() and account.credits >= room_open_cost()


## Pays for an offered room; it opens at Level 1.
func open_room(id: String) -> bool:
	if not can_open_room(id):
		return false
	account.credits -= room_open_cost()
	account.rooms[id] = 1
	_refresh_fx()
	return true


## Credits from a room's level to the next (its IPM table).
func room_level_cost(id: String) -> int:
	var lv: int = account.rooms.get(id, 0)
	var costs: Array = data.rooms[id].level_costs
	return costs[lv - 1] if lv >= 1 and lv <= costs.size() else 1 << 30


func can_level_room(id: String) -> bool:
	return account.rooms.has(id) and account.rooms[id] < data.rooms[id].cap and account.credits >= room_level_cost(id)


func level_room(id: String) -> bool:
	if not can_level_room(id):
		return false
	account.credits -= room_level_cost(id)
	account.rooms[id] += 1
	_refresh_fx()
	return true


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
	if fx.forage > 0.0:
		for i in n:
			if _shortest_ingredient() != "" and rng.randf() < fx.forage:
				_forage_drop()
	stock.bell += picked
	stats.bell_picked += picked
	return picked


## `n` automatic presses at once, for a long step (the catch-up): the same
## peppers, Heat and Overclock as n presses, with one draw for Double-Tap.
func _press_batch(n: int) -> void:
	if n <= 0:
		return
	var doubles := _binomial(n, fx.double) if fx.double > 0.0 else 0
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
	if fx.forage > 0.0 and _shortest_ingredient() != "":
		for i in _binomial(presses, fx.forage):
			_forage_drop()


## Forager's Luck (D025): of the owned ingredient stations that an unlocked
## recipe uses, the one whose stock covers the fewest cycles of that use (ties
## in data order); "" when there is none.
func _shortest_ingredient() -> String:
	var best := ""
	var best_cycles := INF
	for crop in fx.ingredient_need:
		if plots.has(crop) and plots[crop].owned:
			var cycles: float = stock[crop] / float(fx.ingredient_need[crop])
			if cycles < best_cycles:
				best = crop
				best_cycles = cycles
	return best


## A drop of the shortest ingredient: what its station grows in FORAGE_SECONDS,
## upgrades included, straight to stock. Bumper Crop can double it (D043).
func _forage_drop() -> void:
	var crop := _shortest_ingredient()
	var harvests := 2.0 if fx.bumper > 0.0 and rng.randf() < fx.bumper else 1.0
	var n := roundi(crop_rate(crop, crop) * T.FORAGE_SECONDS * harvests)
	stock[crop] += n
	stats.harvested[crop] += n
	stats.foraged += 1


## How many of n draws at chance p come up: drawn one by one when few, by the
## binomial's normal approximation once there are enough (the catch-up, D020).
func _binomial(n: int, p: float) -> int:
	if n < 12:
		var hits := 0
		for i in n:
			if rng.randf() < p:
				hits += 1
		return hits
	return clampi(roundi(rng.randfn(n * p, sqrt(n * p * (1.0 - p)))), 0, n)


## `seconds` of a farm's growth into its field, each crop's fraction carried.
func _harvest(id: String, seconds: float) -> void:
	var p: Dictionary = plots[id]
	for crop in plot_crops(id):
		var exact: float = crop_rate(id, crop) * seconds + p.spare.get(crop, 0.0)
		var n := floori(exact + EPSILON)
		p.spare[crop] = maxf(0.0, exact - n)
		p.field[crop] = p.field.get(crop, 0) + n
		stats.harvested[crop] += n


## The truck (D050, G21): every round trip it brings up to its cargo from the
## field, the priority crop first, then the most valuable.
func _haul(id: String, dt: float) -> void:
	var p: Dictionary = plots[id]
	p.trip += dt
	var trip := trip_seconds(id)
	var trips := floori((p.trip + EPSILON) / trip)
	if trips <= 0:
		return
	p.trip -= trips * trip
	var room: int = trips * truck_cargo(id)
	for crop in _load_order(id):
		if room <= 0:
			break
		var n := mini(room, p.field[crop])
		p.field[crop] -= n
		stock[crop] += n
		room -= n


func _load_order(id: String) -> Array:
	var crops: Array = plots[id].field.keys()
	crops.sort_custom(func(a, b): return value(a) > value(b))
	var first: String = plots[id].priority
	if first != "" and crops.has(first):
		crops.erase(first)
		crops.push_front(first)
	return crops


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
	var inputs := slot_inputs(station, index)
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
	var double: float = fx.line_double if station == "line" else fx.vat_double
	var made := done + (_binomial(done, double) if double > 0.0 else 0)
	stats.made[out] += made
	if station == "line":
		for i in made:
			_bottle_made(out)
	else:
		stock[out] += made
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
		# Double Batch and Double Fill (IPM's Specialists): a chance of two.
		var double: float = fx.line_double if station == "line" else fx.vat_double
		var made := 2 if double > 0.0 and rng.randf() < double else 1
		stats.made[out] += made
		if station == "line":
			if s.crate > 0:
				s.crate -= 1
			for i in made:
				_bottle_made(out)
		else:
			stock[out] += made
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


## Gives the owned farm with the fewest levels a free level, on whichever of
## its upgrades is cheapest (D013). Returns false with no farm owned.
func _free_level() -> bool:
	var lowest := ""
	var lowest_levels := 1 << 30
	for id in plots:
		var p: Dictionary = plots[id]
		if p.owned and p.harvest + p.truck + p.cargo < lowest_levels:
			lowest = id
			lowest_levels = p.harvest + p.truck + p.cargo
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
	ticker.mult = T.TICKER_MULTS[rng.randi_range(0, T.TICKER_MULTS.size() - 1)] * hq("ticker")
	ticker.ends = stats.ticks + _ticks(T.TICKER_SECONDS)
	ticker.next = stats.ticks + _ticks(rng.randi_range(T.TICKER_GAP[0], T.TICKER_GAP[1]))
	stats.spikes += 1


## Idle slots with a recipe take their inputs if the stock has them, vats before
## lines, each in buying order.
func _start_cycles() -> void:
	for station in ["vat", "line"]:
		for i in slots(station).size():
			var s: Dictionary = slots(station)[i]
			if s.running or s.recipe == "":
				continue
			var inputs := slot_inputs(station, i)
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


## Pays cash out; it stays in Operation Value (IPM's Galaxy Value counts what
## was spent).
func _spend(amount: float) -> void:
	cash = maxf(0.0, cash - amount)
	stats.spent += amount


## Adds sale cash. The account's best Operation Value is noted by the step or
## action as a whole, not after every sale.
func _earn(amount: float) -> void:
	cash += amount
	stats.cash_earned += amount


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
		"cash_earned": 0.0, "ov": 0.0, "bottles_waiting": 0.0, "made": {}, "step": T.TICK_SECONDS, "steps": 0}
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
	# Before the Delivery Van nothing sells while away: what Sell Batch would
	# pay now is the return's real worth (D046).
	report.bottles_waiting = bottles_value()
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
		ticker.mult = T.TICKER_MULTS[rng.randi_range(0, T.TICKER_MULTS.size() - 1)] * hq("ticker")
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
			"bought": bought.keys(),
			"bred": bred.duplicate(),
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
		"account": account.duplicate(true),
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
	# Money moves to dollars once, before any migration reads it (D035).
	var dollars := version >= 8
	if version == 1:
		problem = _check(s, {"cash": TYPE_FLOAT, "bell": TYPE_FLOAT, "revealed": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _to_dollars(s, 1)
		dollars = true
		s = _migrate_1_to_2(s)
		version = 2
	if version == 2:
		problem = _check(s, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "revealed": TYPE_DICTIONARY, "stations": TYPE_DICTIONARY, "stats": TYPE_DICTIONARY})
		for k in ["plot", "vat", "line"]:
			if problem == "" and typeof(s.stations.get(k)) != TYPE_DICTIONARY:
				problem = "save's station %s is not an object" % k
		if problem != "":
			return problem
		if not dollars:
			s = _to_dollars(s, 2)
			dollars = true
		s = _migrate_2_to_3(s)
		version = 3
	problem = _check(s, {"run": TYPE_DICTIONARY, "account": TYPE_DICTIONARY})
	if problem != "":
		return problem
	if version == 3:
		s = _migrate_3_to_4(s)
	if not dollars:
		problem = _check(s.run, {"cash": TYPE_FLOAT, "stats": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _to_dollars(s, 3)
	if int(s.get("version", version)) < 8:
		s = _migrate_7_to_8(s)
	# D042's names first, so v9's plot conversion finds the plots by their new ids.
	var from_version := int(s.get("version", version))
	if from_version < 10:
		s = _migrate_9_to_10(s)
	if from_version < 9:
		problem = _check(s.run, {"plots": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _migrate_8_to_9(s)
	if from_version < 11:
		problem = _check(s.run, {"plots": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _migrate_10_to_11(s)
	if from_version < 12:
		problem = _check(s.run, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "plots": TYPE_DICTIONARY, "vats": TYPE_ARRAY, "lines": TYPE_ARRAY,
			"research": TYPE_ARRAY, "stats": TYPE_DICTIONARY})
		if problem != "":
			return problem
		s = _migrate_11_to_12(s)
	# v5 only adds `saved_at` beside the run, for the screen (OFFLINE.md); v6
	# only adds stats.foraged (Forager's Luck), read below with a default of 0;
	# v7 only adds the account's Prestige fields, read below with defaults.
	var run: Dictionary = s.run
	# `revealed` isn't required since D044: nothing reads it.
	problem = _check(run, {"cash": TYPE_FLOAT, "stock": TYPE_DICTIONARY, "plots": TYPE_DICTIONARY,
		"vats": TYPE_ARRAY, "lines": TYPE_ARRAY, "research": TYPE_ARRAY, "bought": TYPE_ARRAY, "bred": TYPE_DICTIONARY,
		"autosell": TYPE_DICTIONARY, "autosell_acc": TYPE_DICTIONARY,
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
	for id in run.plots:
		var p: Variant = run.plots[id]
		if not data.plots.has(id) or typeof(p) != TYPE_DICTIONARY or typeof(p.get("field", {})) != TYPE_DICTIONARY:
			return "save has a bad plot " + str(id)
		for crop in p.get("field", {}):
			if not data.items.has(crop) or data.items[crop].kind != "crop":
				return "save's plot %s holds unknown crop %s" % [id, str(crop)]
		var b: Variant = p.get("bred", {})
		if typeof(b) != TYPE_DICTIONARY or (not b.is_empty() and (not data.items.has(b.get("to")) or not data.plots[id].crops.has(b.get("from")))):
			return "save's plot %s has a bad crossbreed" % id
	for node in run.research:
		if not data.tech.has(node):
			return "save has unknown research " + str(node)
	for r in run.bought:
		if not data.recipes.has(r):
			return "save bought unknown recipe " + str(r)
	for node in run.bred:
		if not data.tech.has(node) or not data.plots.has(run.bred[node]):
			return "save has a bad crossbreed " + str(node)
	if run.pin != "" and not data.tech.has(run.pin):
		return "save pins unknown node " + run.pin
	var t_sauce := str(run.ticker.get("sauce", ""))
	if t_sauce != "" and (not data.items.has(t_sauce) or data.items[t_sauce].kind != "bottle"):
		return "save's market spike is on unknown sauce " + t_sauce
	var fresh = get_script().new(data)
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

	var acc: Dictionary = s.account
	var rooms: Variant = acc.get("rooms", {})
	if typeof(rooms) != TYPE_DICTIONARY:
		return "save's HQ rooms are the wrong type"
	for id in rooms:
		if not data.rooms.has(id) or int(rooms[id]) < 1 or int(rooms[id]) > data.rooms[id].cap:
			return "save has a bad HQ room " + str(id)

	# Everything checked: now load.
	cash = float(run.cash)
	stock = fresh.stock
	for item in run.stock:
		stock[item] = int(run.stock[item])
	# Since D044 nothing waits to be revealed, whatever an older save says.
	revealed = fresh.revealed
	plots = fresh.plots
	for id in run.plots:
		var p: Dictionary = run.plots[id]
		var q: Dictionary = plots[id]
		q.owned = bool(p.get("owned", false))
		for k in PLOT_UPGRADES:
			q[k] = maxi(0, int(p.get(k, 0)))
		for crop in p.get("field", {}):
			q.field[crop] = maxi(0, int(p.field[crop]))
		for crop in p.get("spare", {}):
			if q.field.has(crop):
				q.spare[crop] = maxf(0.0, float(p.spare[crop]))
		# As saved, not clamped: a timer can sit a hair under 0 (EPSILON), and
		# a reloaded game must play on identically (S10).
		q.grow = float(p.get("grow", 0.0))
		q.trip = float(p.get("trip", 0.0))
		q.priority = str(p.get("priority", ""))
		var b: Dictionary = p.get("bred", {})
		q.bred = {} if b.is_empty() else {"from": str(b.from), "to": str(b.to)}
		if not q.bred.is_empty() and not q.field.has(q.bred.to):
			q.field[q.bred.to] = 0
			q.spare[q.bred.to] = 0.0
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
			else:
				loaded.pressure = bool(slot.get("pressure", false))
			slots(station).append(loaded)
	research = fresh.research
	for node in run.research:
		research[node] = true
	bought = {}
	for r in run.bought:
		bought[str(r)] = true
	bred = {}
	for node in run.bred:
		bred[str(node)] = str(run.bred[node])
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
	for k in ["presses", "doubles", "bell_picked", "ticks", "researched", "free_levels", "spikes", "foraged"]:
		stats[k] = int(run.stats.get(k, 0))
	stats.cash_earned = float(run.stats.get("cash_earned", 0.0))
	stats.spent = float(run.stats.get("spent", 0.0))
	for k in ["harvested", "made", "sold", "consumed"]:
		var saved: Variant = run.stats.get(k, {})
		if typeof(saved) == TYPE_DICTIONARY:
			for item in saved:
				if stats[k].has(item):
					stats[k][item] = int(saved[item])
	account = {"best_ov": float(acc.get("best_ov", 0.0)), "credits": int(acc.get("credits", 0)), "prestiges": int(acc.get("prestiges", 0)), "rooms": {}}
	for id in rooms:
		account.rooms[id] = int(rooms[id])
	_refresh_fx()
	_note_value()
	return ""


## The nodes v12 removes (the blueprints, Slot Expansion, the cultivation
## nodes) with what they cost in v11: their items come back (I11).
const REMOVED_V12 := {
	"jalapeno_blueprint": {"table_mild": 3}, "verde_blueprint": {"table_mild": 10}, "vinegar_blueprint": {"table_mild": 10, "sweet_mash": 5},
	"brine_blueprint": {"table_mild": 10, "sweet_mash": 5}, "bistro_blueprint": {"table_mild": 20}, "slot_expansion_1": {"sweet_mash": 40, "verde_mash":
	20}, "slot_expansion_2": {"verde_mash": 25, "pickled_brine": 25}, "cayenne_blueprint": {"serrano_fire": 4, "verde_mash": 5}, "garlic_blueprint":
	{"serrano_fire": 4, "pickled_brine": 5}, "paste_blueprint": {"serrano_fire": 6}, "cayenne_mash_blueprint": {"serrano_fire": 5, "pickled_brine": 5},
	"louisiana_blueprint": {"serrano_fire": 5}, "poblano_blueprint": {"table_mild": 5}, "ancho_blueprint": {"table_mild": 8, "sweet_mash": 3},
	"smoky_ancho_blueprint": {"table_mild": 12}, "serrano_blueprint": {"bistro_verde": 10}, "serrano_mash_blueprint": {"bistro_verde": 10, "verde_mash":
	5}, "serrano_fire_blueprint": {"bistro_verde": 15}, "thai_chili_blueprint": {"classic_louisiana": 10}, "thai_chili_mash_blueprint":
	{"classic_louisiana": 10, "garlic_paste": 5}, "cajun_red_blueprint": {"classic_louisiana": 15}, "pineapple_blueprint": {"cajun_red": 5},
	"glaze_blueprint": {"cajun_red": 5, "garlic_paste": 5}, "bonnet_blueprint": {"cajun_red": 10}, "bonnet_mash_blueprint": {"cajun_red": 10, "glaze": 5},
	"island_heat_blueprint": {"cajun_red": 15}, "caribbean_red_blueprint": {"island_heat": 20}, "caribbean_red_mash_blueprint": {"island_heat": 20,
	"glaze": 10}, "sweet_heat_blueprint": {"island_heat": 30}, "chocolate_blueprint": {"sweet_heat": 20}, "chocolate_mash_blueprint": {"sweet_heat": 20,
	"caribbean_red_mash": 10}, "cocoa_loco_blueprint": {"sweet_heat": 30}, "oak_blueprint": {"cocoa_loco": 20}, "smoke_blueprint": {"cocoa_loco": 20,
	"glaze": 10}, "ghost_blueprint": {"cocoa_loco": 20}, "ghost_mash_blueprint": {"cocoa_loco": 20, "chocolate_mash": 10}, "phantom_blueprint":
	{"cocoa_loco": 30}, "hydroponic_cayenne": {"cocoa_loco": 30}, "slot_expansion_3": {"cayenne_mash": 40, "garlic_paste": 40}, "slot_expansion_4":
	{"caribbean_red_mash": 30, "glaze": 30}, "moruga_blueprint": {"phantom": 20}, "moruga_mash_blueprint": {"phantom": 20, "ghost_mash": 10},
	"scorpion_sting_blueprint": {"phantom": 30}, "grim_blueprint": {"scorpion_sting": 20}, "grim_mash_blueprint": {"scorpion_sting": 20, "moruga_mash":
	10}, "widowmaker_blueprint": {"scorpion_sting": 30}, "pepper_y_blueprint": {"widowmaker": 20}, "pepper_y_mash_blueprint": {"widowmaker": 20,
	"grim_mash": 10}, "extinction_event_blueprint": {"widowmaker": 30}
}


## v12 (D049–D053): the skeleton. Nothing of a v11 run's factory carries over
## as it was, so it comes back as what was spent on it (I11): cash becomes every
## dollar the run earned plus what it started with (all cash spent went on
## plots, upgrades and slots), crops waiting in fields and inputs held by slots
## go to stock, removed nodes give back their items, and every HQ room comes
## back as the credits it cost. Items keep their counts at their new values.
func _migrate_11_to_12(s: Dictionary) -> Dictionary:
	var out := s.duplicate(true)
	var run: Dictionary = out.run
	var acc: Dictionary = out.account
	var stock_v: Dictionary = run.stock
	var add := func(item: Variant, n: Variant) -> void:
		if data.items.has(str(item)) and (typeof(n) == TYPE_INT or typeof(n) == TYPE_FLOAT) and n > 0:
			stock_v[str(item)] = int(stock_v.get(str(item), 0)) + int(n)
	for crop in run.plots:
		var p: Variant = run.plots[crop]
		if typeof(p) == TYPE_DICTIONARY:
			add.call(crop, p.get("field", 0))
	for station in ["vats", "lines"]:
		for slot in run[station]:
			if typeof(slot) == TYPE_DICTIONARY and bool(slot.get("running", false)) and typeof(slot.get("taken")) == TYPE_DICTIONARY:
				for item in slot.taken:
					add.call(item, slot.taken[item])
	var kept := []
	for node in run.research:
		if REMOVED_V12.has(node):
			for item in REMOVED_V12[node]:
				add.call(item, REMOVED_V12[node][item])
		elif data.tech.has(node):
			kept.append(node)
	run.research = kept
	# Seed Capital's amount at the account's level (same room, same amounts).
	var start := 0.0
	var rooms_v: Variant = acc.get("rooms", {})
	if typeof(rooms_v) == TYPE_DICTIONARY and rooms_v.has("seed_capital") and data.rooms.has("seed_capital"):
		var room: Dictionary = data.rooms.seed_capital
		var lv := int(rooms_v.seed_capital)
		start = room.amounts[lv - 1] if lv <= room.amounts.size() else room.amounts[-1] * pow(room.growth, lv - room.amounts.size())
	run.cash = float(run.stats.get("cash_earned", 0.0)) + start
	run.plots = {}
	run.vats = []
	run.lines = []
	run.bought = []
	run.bred = {}
	# The rooms back as credits: the n-th room cost 5n, a level from L 2L, and
	# a draft waiting had been paid for (v11's prices, G8).
	var refund := 0
	if typeof(rooms_v) == TYPE_DICTIONARY:
		var n := 0
		for id in rooms_v:
			n += 1
			refund += T.ROOM_OPEN_COST * n
			for lv in range(1, int(rooms_v[id])):
				refund += T.ROOM_LEVEL_COST * lv
		var draft: Variant = acc.get("draft", [])
		if typeof(draft) == TYPE_ARRAY and not draft.is_empty():
			refund += T.ROOM_OPEN_COST * (n + 1)
	acc.credits = int(acc.get("credits", 0)) + refund
	acc.rooms = {}
	acc.erase("draft")
	out.version = 12
	return out


## v11 (D043): Crop Quality becomes Cargo, level for level (they cost the
## same), with an empty field.
func _migrate_10_to_11(s: Dictionary) -> Dictionary:
	var out := s.duplicate(true)
	for crop in out.run.plots:
		if typeof(out.run.plots[crop]) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = out.run.plots[crop]
		p.cargo = _level(p, "quality")
		p.erase("quality")
	out.version = 11
	return out


## v10 (D042): peppers named by real heat with generic names, and Pineapple
## for Cane Sugar. Ids in a save are renamed in this order (Habanero before Red
## Savina becomes Chocolate Habanero; Savina Gold before Red Savina).
const RENAMES_V10 := [["habanero", "caribbean_red"], ["savina_gold", "cocoa_loco"], ["savina", "chocolate"],
	["tabasco", "thai_chili"], ["reaper", "grim"], ["pepper_x", "pepper_y"], ["sugar", "pineapple"]]


func _migrate_9_to_10(s: Dictionary) -> Dictionary:
	var text := JSON.stringify(s)
	for pair in RENAMES_V10:
		text = text.replace(pair[0], pair[1])
	var out: Dictionary = JSON.parse_string(text)
	out.version = 10
	return out


## v9 (D041): plot upgrades take smaller steps, so each plot's levels become
## the new levels with at least the same effect: speed and Crop Quality by their
## step, yield from whole crops to shares of the plot's base yield.
func _migrate_8_to_9(s: Dictionary) -> Dictionary:
	var out := s.duplicate(true)
	for crop in out.run.plots:
		# A malformed entry is left for the load's own checks to refuse.
		if typeof(out.run.plots[crop]) != TYPE_DICTIONARY:
			continue
		var p: Dictionary = out.run.plots[crop]
		p.speed = ceili(_level(p, "speed") * T.V8_PLOT_SPEED_STEP / T.PLOT_SPEED_STEP - EPSILON)
		p.quality = mini(T.V10_CROP_QUALITY_MAX, ceili(_level(p, "quality") * T.V8_CROP_QUALITY_STEP / T.V10_CROP_QUALITY_STEP - EPSILON))
		# v9 knew each plot's base yield; v12 refunds plots, so 1 does here.
		p["yield"] = ceili(_level(p, "yield") / T.PLOT_YIELD_STEP - EPSILON)
	out.version = 9
	return out


## A saved plot level, 0 if it's missing or not a number.
static func _level(p: Dictionary, key: String) -> int:
	var v: Variant = p.get(key, 0)
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else 0


## v8 (D035): the Tier 6 sauce Event Horizon became Extinction Event (the name
## is the last fictional pepper's). Only whole ids are renamed, as keys or
## values: v12 reuses event_horizon for a pepper, so a text replace would also
## rename ids that start with it.
const V8_RENAMES := {"event_horizon": "extinction_event", "event_horizon_blueprint": "extinction_event_blueprint"}


func _migrate_7_to_8(s: Dictionary) -> Dictionary:
	var out: Dictionary = _rename_ids(s, V8_RENAMES)
	out.version = 8
	return out


## A copy of `v` with every string, and every dictionary key, found in `names`
## replaced by its new name. A renamed key that meets the new one adds to it
## when both are numbers.
static func _rename_ids(v: Variant, names: Dictionary) -> Variant:
	match typeof(v):
		TYPE_STRING:
			return names.get(v, v)
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(_rename_ids(x, names))
			return a
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				var nk: Variant = names.get(k, k)
				var nv: Variant = _rename_ids(v[k], names)
				var both_numbers := d.has(nk) and typeof(d[nk]) in [TYPE_INT, TYPE_FLOAT] and typeof(nv) in [TYPE_INT, TYPE_FLOAT]
				d[nk] = d[nk] + nv if both_numbers else nv
			return d
	return v


## A pre-v8 save's money in Idle Planet Miner's dollars (D035): about ×10 at
## Tier 1, so cash, cash earned and the best Operation Value are ×10; items keep
## their counts and are simply worth more. v1–v2 keep them at the top level.
func _to_dollars(s: Dictionary, layout: int) -> Dictionary:
	var out := s.duplicate(true)
	var run: Dictionary = out if layout <= 2 else out.run
	run.cash = float(run.cash) * T.SAVE_V8_MONEY
	if typeof(run.get("stats")) == TYPE_DICTIONARY and run.stats.has("cash_earned"):
		run.stats.cash_earned = float(run.stats.cash_earned) * T.SAVE_V8_MONEY
	if layout > 2:
		out.account.best_ov = float(out.account.get("best_ov", 0.0)) * T.SAVE_V8_MONEY
	return out


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
