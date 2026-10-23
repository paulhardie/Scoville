extends RefCounted
## Loads and checks the game data in data/*.json. The only place data is read.
## Bad data is reported with the file and row, never half-loaded
## (docs/FACTORY.md S6).

const FILES := ["items", "recipes", "plots", "slots", "tech", "rooms"]
## What an HQ room can change (docs/SKELETON.md): Idle Planet Miner's rooms,
## plus Ergonomics Lab and Seed Capital Office.
const ROOM_EFFECTS := ["harvest", "vat_speed", "truck_speed", "upgrade_cost", "cargo", "line_speed", "tech_cost", "button_yield",
	"credits", "offline_hours", "start_cash", "vat_input", "line_input", "value", "ticker"]
const KINDS := ["crop", "mash", "bottle"]
const STATIONS := {"vat": "mash", "line": "bottle"}

static var _default: Dictionary = {}


## The real data, loaded once. Fails loudly: a game can't run on bad data.
static func default_data() -> Dictionary:
	if _default.is_empty():
		var loaded := load_dir()
		if not loaded.errors.is_empty():
			push_error("game data: " + "; ".join(loaded.errors))
		_default = loaded.data
	return _default


## Reads every file from a folder. Returns {data, errors}; data is only usable
## when errors is empty.
static func load_dir(dir: String = "res://data") -> Dictionary:
	var raw := {}
	var errors: Array[String] = []
	for name in FILES:
		var path := dir.path_join(name + ".json")
		if not FileAccess.file_exists(path):
			errors.append("%s.json: missing" % name)
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			errors.append("%s.json: not a JSON object" % name)
			continue
		raw[name] = parsed
	if not errors.is_empty():
		return {"data": {}, "errors": errors}
	return check(raw)


## Checks parsed files and builds the lookup tables the game uses: items,
## recipes, plots (the farms, by id), slots, tech (by id), tech_order (ids in
## file order), rooms (by id) and room_order (the order they're offered).
static func check(raw: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var data := {"items": {}, "recipes": {}, "plots": {}, "slots": {}, "tech": {}, "tech_order": [], "rooms": {}, "room_order": []}

	var rows := _rows(raw, "items", "items", errors)
	for i in rows.size():
		var r: Variant = rows[i]
		var where := _where("items", i, r)
		if not _fields(r, {"id": TYPE_STRING, "name": TYPE_STRING, "plural": TYPE_STRING, "kind": TYPE_STRING, "tier": TYPE_FLOAT, "value": TYPE_FLOAT}, where, errors):
			continue
		if data.items.has(r.id):
			errors.append(where + ": duplicate id")
		elif not r.kind in KINDS:
			errors.append(where + ": kind must be one of " + str(KINDS))
		elif r.value <= 0.0:
			errors.append(where + ": value must be above 0")
		else:
			if r.get("ingredient", false) and r.kind != "crop":
				errors.append(where + ": only a crop can be an ingredient")
			data.items[r.id] = {"id": r.id, "name": r.name, "plural": r.plural, "short": str(r.get("short", r.name)), "kind": r.kind, "tier": int(r.tier), "value": float(r.value), "ingredient": bool(r.get("ingredient", false))}

	rows = _rows(raw, "recipes", "recipes", errors)
	for i in rows.size():
		var r: Variant = rows[i]
		var where := _where("recipes", i, r)
		if not _fields(r, {"id": TYPE_STRING, "station": TYPE_STRING, "inputs": TYPE_DICTIONARY, "output": TYPE_STRING, "seconds": TYPE_FLOAT}, where, errors):
			continue
		var ok := true
		if data.recipes.has(r.id):
			errors.append(where + ": duplicate id")
			ok = false
		if not STATIONS.has(r.station):
			errors.append(where + ": station must be vat or line")
			ok = false
		elif not data.items.has(r.output) or data.items[r.output].kind != STATIONS[r.station]:
			errors.append(where + ": output %s must be a %s item" % [r.output, STATIONS[r.station]])
			ok = false
		if r.seconds <= 0.0:
			errors.append(where + ": seconds must be above 0")
			ok = false
		if r.inputs.is_empty():
			errors.append(where + ": no inputs")
			ok = false
		var inputs := {}
		for item in r.inputs:
			if not data.items.has(item):
				errors.append(where + ": unknown input " + str(item))
				ok = false
			elif typeof(r.inputs[item]) != TYPE_FLOAT or r.inputs[item] < 1.0 or r.inputs[item] != floorf(r.inputs[item]):
				errors.append(where + ": input %s needs a whole count of at least 1" % item)
				ok = false
			else:
				inputs[item] = int(r.inputs[item])
		# A recipe is bought with cash, as Idle Planet Miner's are (D051); 0 is free.
		var unlock: Variant = r.get("unlock", 0.0)
		if typeof(unlock) != TYPE_FLOAT or unlock < 0.0:
			errors.append(where + ": unlock is a cash price of at least 0")
			ok = false
		if ok:
			data.recipes[r.id] = {"id": r.id, "station": r.station, "inputs": inputs, "output": r.output, "seconds": float(r.seconds),
				"unlock": float(unlock), "kitchen": bool(r.get("kitchen", false))}

	# The farms (D050): each grows its crops in shares, percent of its harvest.
	rows = _rows(raw, "plots", "plots", errors)
	for i in rows.size():
		var r: Variant = rows[i]
		var where := _where("plots", i, r)
		if not _fields(r, {"id": TYPE_STRING, "name": TYPE_STRING, "price": TYPE_FLOAT, "crops": TYPE_DICTIONARY, "distance": TYPE_FLOAT, "survey": TYPE_FLOAT}, where, errors):
			continue
		var ok := true
		if data.plots.has(r.id):
			errors.append(where + ": duplicate id")
			ok = false
		if r.price <= 0.0 or r.distance <= 0.0 or r.survey < 0.0:
			errors.append(where + ": price and distance must be above 0, survey at least 0")
			ok = false
		if r.crops.is_empty():
			errors.append(where + ": grows no crops")
			ok = false
		var crops := {}
		for crop in r.crops:
			if not data.items.has(crop) or data.items[crop].kind != "crop":
				errors.append(where + ": %s is not a crop" % crop)
				ok = false
			elif typeof(r.crops[crop]) != TYPE_FLOAT or r.crops[crop] <= 0.0:
				errors.append(where + ": %s's share must be above 0" % crop)
				ok = false
			else:
				crops[crop] = float(r.crops[crop]) / 100.0
		var extra := {}
		for k in ["upgrade_price", "harvest_mult", "cargo_mult"]:
			var v: Variant = r.get(k, r.price if k == "upgrade_price" else 1.0)
			if typeof(v) != TYPE_FLOAT or v <= 0.0:
				errors.append(where + ": %s must be a number above 0" % k)
				ok = false
			else:
				extra[k] = float(v)
		if ok:
			data.plots[r.id] = {"id": r.id, "name": r.name, "price": float(r.price), "crops": crops, "distance": float(r.distance),
				"survey": int(r.survey), "upgrade_price": extra.upgrade_price, "harvest_mult": extra.harvest_mult, "cargo_mult": extra.cargo_mult,
				"ingredient": bool(r.get("ingredient", false))}
	if not data.plots.has("bell") or data.plots.bell.crops.keys() != ["bell"]:
		errors.append("plots.json: no bell plot growing only Bell Peppers (onboarding needs one)")

	var slots: Variant = raw.get("slots", {})
	for station in STATIONS:
		var st: Variant = slots.get(station) if typeof(slots) == TYPE_DICTIONARY else null
		if typeof(st) != TYPE_DICTIONARY or typeof(st.get("prices")) != TYPE_ARRAY or st.prices.is_empty():
			errors.append("slots.json: %s needs a non-empty prices list" % station)
			continue
		var prices: Array[float] = []
		for p in st.prices:
			if typeof(p) != TYPE_FLOAT or p <= 0.0:
				errors.append("slots.json: %s prices must be numbers above 0" % station)
				break
			prices.append(float(p))
		data.slots[station] = {"prices": prices}

	rows = _rows(raw, "tech", "nodes", errors)
	for i in rows.size():
		var r: Variant = rows[i]
		var where := _where("tech", i, r)
		if not _fields(r, {"id": TYPE_STRING, "label": TYPE_STRING, "name": TYPE_STRING, "wing": TYPE_STRING, "needs": TYPE_ARRAY, "cost": TYPE_DICTIONARY, "effects": TYPE_ARRAY, "pos": TYPE_ARRAY}, where, errors):
			continue
		if data.tech.has(r.id):
			errors.append(where + ": duplicate id")
			continue
		var ok := true
		var cost := {}
		for item in r.cost:
			if not data.items.has(item) or typeof(r.cost[item]) != TYPE_FLOAT or r.cost[item] < 1.0:
				errors.append(where + ": bad cost " + str(item))
				ok = false
			else:
				cost[item] = int(r.cost[item])
		# needs: every one; needs_any: at least one (Idle Planet Miner's OR).
		var needs_any: Variant = r.get("needs_any", [])
		if typeof(needs_any) != TYPE_ARRAY:
			errors.append(where + ": needs_any is a list of node ids")
			needs_any = []
			ok = false
		for need in r.needs + needs_any:
			if not data.tech.has(need):
				errors.append(where + ": needs %s, which isn't an earlier node" % str(need))
				ok = false
		var effects: Array = []
		for e in r.effects:
			if typeof(e) != TYPE_DICTIONARY or e.size() != 1:
				errors.append(where + ": each effect is one {kind: target}")
				ok = false
				continue
			var kind: String = e.keys()[0]
			match kind:
				"survey", "crossbreed", "pressure":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] < 1.0 or e[kind] != floorf(e[kind]):
						errors.append(where + ": %s needs a whole number of at least 1" % kind)
						ok = false
				"harvest_mult", "truck_speed", "cargo", "vat_speed", "line_speed", "mash_value", "sauce_value", "pressure_speed":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] <= 1.0:
						errors.append(where + ": %s needs a multiplier above 1" % kind)
						ok = false
				"target_bonus", "vat_input_cut", "line_input_cut", "vat_double", "line_double", "station_discount", "pressure_extra":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] <= 0.0 or e[kind] >= 1.0:
						errors.append(where + ": %s needs a share between 0 and 1" % kind)
						ok = false
				"delivery_van", "heat_meter", "overdrive", "overflow_valve", "smart_stockpiling", "market_ticker", "sop", "crop_priority":
					if e[kind] != true:
						errors.append(where + ": %s takes true" % kind)
						ok = false
				"tap_yield":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] < 1.0:
						errors.append(where + ": tap_yield needs a whole number of at least 1")
						ok = false
				"double_tap", "forage", "bumper_crop", "byproduct_recycling", "stock_value_bonus", "heat_drain":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] <= 0.0 or e[kind] >= 1.0:
						errors.append(where + ": %s needs a share between 0 and 1" % kind)
						ok = false
				"grip", "piston", "overclock", "packaging":
					if typeof(e[kind]) != TYPE_FLOAT or e[kind] <= 0.0:
						errors.append(where + ": %s needs a number above 0" % kind)
						ok = false
				"plot_speed", "plot_yield":
					# A crop's harvest × mult wherever it grows (the Pantry's ingredient stations).
					var v: Variant = e[kind]
					if typeof(v) != TYPE_DICTIONARY or not data.items.has(v.get("crop")) or data.items[v.crop].kind != "crop" or typeof(v.get("mult")) != TYPE_FLOAT or v.mult <= 1.0:
						errors.append(where + ": %s needs {crop, mult above 1}" % kind)
						ok = false
				"concentrate":
					var v: Variant = e[kind]
					if typeof(v) != TYPE_DICTIONARY or not data.items.has(v.get("item")) or data.items[v.item].kind != "crop" or typeof(v.get("share")) != TYPE_FLOAT or v.share <= 0.0 or v.share >= 1.0:
						errors.append(where + ": concentrate needs {item: a crop, share between 0 and 1}")
						ok = false
				"reserve":
					var v: Variant = e[kind]
					if typeof(v) != TYPE_DICTIONARY or not data.items.has(v.get("item")) or data.items[v.item].kind != "mash" or typeof(v.get("bonus")) != TYPE_FLOAT or v.bonus <= 0.0:
						errors.append(where + ": reserve needs {item: a mash, bonus above 0}")
						ok = false
				"offline":
					var v: Variant = e[kind]
					if typeof(v) != TYPE_DICTIONARY or typeof(v.get("hours")) != TYPE_FLOAT or typeof(v.get("speed")) != TYPE_FLOAT or v.hours < 0.0 or v.speed < 0.0:
						errors.append(where + ": offline needs {hours, speed}, neither below 0")
						ok = false
				_:
					errors.append(where + ": unknown effect " + kind)
					ok = false
			effects.append(e)
		if r.pos.size() != 2:
			errors.append(where + ": pos is [x, y]")
			ok = false
		if ok:
			var excludes: Variant = r.get("excludes", [])
			if typeof(excludes) != TYPE_ARRAY:
				errors.append(where + ": excludes is a list of node ids")
				excludes = []
			var after_sale: Variant = r.get("after_sale", false)
			if typeof(after_sale) != TYPE_BOOL:
				errors.append(where + ": after_sale is true or false")
				after_sale = false
			data.tech[r.id] = {"id": r.id, "label": r.label, "name": r.name, "wing": r.wing, "needs": r.needs.duplicate(), "needs_any": needs_any.duplicate(),
				"cost": cost, "effects": effects, "pos": Vector2(r.pos[0], r.pos[1]), "excludes": excludes.duplicate(), "after_sale": after_sale}
			data.tech_order.append(r.id)
	# A fork (D026) names the nodes it locks; each side has to name the other.
	for id in data.tech:
		for other in data.tech[id].excludes:
			if not data.tech.has(other):
				errors.append("tech.json (%s): excludes unknown node %s" % [id, str(other)])
			elif not data.tech[other].excludes.has(id):
				errors.append("tech.json (%s): excludes %s, which doesn't exclude it back" % [id, other])

	rows = _rows(raw, "rooms", "rooms", errors)
	for i in rows.size():
		var r: Variant = rows[i]
		var where := _where("rooms", i, r)
		if not _fields(r, {"id": TYPE_STRING, "name": TYPE_STRING, "effect": TYPE_STRING, "cap": TYPE_FLOAT, "open_cost": TYPE_FLOAT, "level_costs": TYPE_ARRAY}, where, errors):
			continue
		if data.rooms.has(r.id):
			errors.append(where + ": duplicate id")
		elif not r.effect in ROOM_EFFECTS:
			errors.append(where + ": effect must be one of " + str(ROOM_EFFECTS))
		elif r.cap < 1.0 or r.open_cost < 1.0:
			errors.append(where + ": cap and open_cost must be at least 1")
		elif r.level_costs.size() != int(r.cap) - 1 or r.level_costs.any(func(c): return typeof(c) != TYPE_FLOAT or c < 1.0):
			errors.append(where + ": level_costs needs cap − 1 credit prices of at least 1")
		elif r.effect == "start_cash" and (typeof(r.get("amounts")) != TYPE_ARRAY or r.amounts.is_empty() or typeof(r.get("growth")) != TYPE_FLOAT):
			errors.append(where + ": start_cash needs amounts and growth")
		elif r.effect != "start_cash" and (typeof(r.get("base")) != TYPE_FLOAT or typeof(r.get("step")) != TYPE_FLOAT or r.base <= 0.0):
			errors.append(where + ": needs base above 0 and a step")
		else:
			var room := {"id": r.id, "name": r.name, "effect": r.effect, "cap": int(r.cap), "open_cost": int(r.open_cost),
				"level_costs": r.level_costs.map(func(c): return int(c))}
			for k in ["base", "step", "growth"]:
				if r.has(k):
					room[k] = float(r[k])
			if r.has("amounts"):
				room.amounts = r.amounts.map(func(a): return float(a))
			data.rooms[r.id] = room
			data.room_order.append(r.id)
	if not data.tech.has("kitchen_table"):
		errors.append("tech.json: no kitchen_table root")
	# Every farm's survey exists, so every farm can be reached.
	var surveys := {0: true}
	for id in data.tech:
		for e in data.tech[id].effects:
			if e.has("survey"):
				surveys[int(e.survey)] = true
	for id in data.plots:
		if not surveys.has(data.plots[id].survey):
			errors.append("plots.json (%s): survey %d isn't in tech.json" % [id, data.plots[id].survey])
	return {"data": data if errors.is_empty() else {}, "errors": errors}


static func _rows(raw: Dictionary, file: String, key: String, errors: Array[String]) -> Array:
	var f: Variant = raw.get(file)
	if typeof(f) != TYPE_DICTIONARY or typeof(f.get(key)) != TYPE_ARRAY:
		errors.append("%s.json: needs a %s list" % [file, key])
		return []
	return f[key]


static func _where(file: String, i: int, r: Variant) -> String:
	var id: Variant = null
	if typeof(r) == TYPE_DICTIONARY:
		id = r.get("id", r.get("crop"))
	return "%s.json row %d%s" % [file, i + 1, " (%s)" % id if id != null else ""]


static func _fields(r: Variant, want: Dictionary, where: String, errors: Array[String]) -> bool:
	if typeof(r) != TYPE_DICTIONARY:
		errors.append(where + ": not an object")
		return false
	for key in want:
		if not r.has(key) or typeof(r[key]) != want[key]:
			errors.append("%s: %s missing or the wrong type" % [where, key])
			return false
	return true
