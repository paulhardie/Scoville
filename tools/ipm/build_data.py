"""Writes data/items, recipes, plots, slots, tech and rooms .json for v0.7
from mapping.py's mapping.json (docs/SKELETON.md) and the pre-v0.7 data on
`main` (for the nodes of ours that stay and their old values, G23).

Usage: python3 -I tools/ipm/build_data.py <mapping.json> [<old data dir>]
Run from the repository root. The old data dir defaults to `git show main:`.
"""
import json, math, os, re, subprocess, sys

MAP = json.load(open(sys.argv[1]))
OLD_DIR = sys.argv[2] if len(sys.argv) > 2 else None


def old(name):
    if OLD_DIR:
        return json.load(open(os.path.join(OLD_DIR, name + ".json")))
    return json.loads(subprocess.check_output(["git", "show", f"main:data/{name}.json"]))


OLD_ITEMS = {i["id"]: i for i in old("items")["items"]}
OLD_TECH = old("tech")["nodes"]
OLD_ROOMS = {r["id"]: r for r in old("rooms")["rooms"]}

# --- Items -------------------------------------------------------------------
items = []
by_name = {}     # display name in mapping.json -> id
tier = {}


def add(item):
    items.append(item)
    by_name[item["name"]] = item["id"]
    tier[item["id"]] = item["tier"]


def plural(name):
    if name.endswith(("y", "o")) and not name.endswith(("ey",)):
        return name[:-1] + ("ies" if name.endswith("y") else "oes") if name.endswith("y") else name + "s"
    return name + "s"


SHORT = {"Bell Pepper": "Bell", "Chile de Árbol": "Árbol", "Hungarian Wax": "Wax", "Caribbean Red Habanero": "Carib Red",
         "Chocolate Habanero": "Choc Hab", "Ghost Pepper": "Ghost", "Trinidad 7 Pot": "7 Pot", "Naga Morich": "Naga",
         "Trinidad Moruga Scorpion": "Moruga", "Alabama Grim": "Grim", "Scotch Bonnet": "Bonnet", "Thai Chili": "Thai",
         "Capsaicin Crystal": "Crystal", "Brimstone Jolokia": "Brimstone", "Supernova Scorpion": "Supernova",
         "Lava Lantern": "Lantern", "Solar Flare": "Flare", "Event Horizon": "Horizon"}
for p in MAP["peppers"]:
    o = OLD_ITEMS.get(p["id"])
    add({"id": p["id"], "name": p["name"], "plural": o["plural"] if o else (p["name"] if p["name"].startswith("Pepper Y") else plural(p["name"])),
         "short": o["short"] if o else SHORT.get(p["name"], p["name"]), "kind": "crop",
         "tier": (p["rung"] - 1) // 4 + 1, "value": p["value"], "rung": p["rung"]})
first_survey = {}
for f in MAP["farms"]:
    for c in f["crops"]:
        first_survey.setdefault(c, f["survey"])
for ing in MAP["ingredients"]:
    first_survey[ing["id"]] = ing["survey"]
survey_lead_tier = {}
for f in MAP["farms"]:
    lead = max(f["crops"], key=lambda c: f["crops"][c])
    survey_lead_tier.setdefault(f["survey"], tier[lead])
for ing in MAP["ingredients"]:
    o = OLD_ITEMS[ing["id"]]
    add({"id": ing["id"], "name": ing["name"], "plural": o["plural"], "short": o["short"], "kind": "crop",
         "tier": survey_lead_tier[ing["survey"]], "value": ing["value"], "ingredient": True})
# The kitchen (D052): unchanged.
for k in ["sweet_mash", "table_mild"]:
    o = dict(OLD_ITEMS[k])
    add(o)


def mash_or_sauce(row, kind):
    ins = [(by_name[nm], int(n)) for n, nm in row["inputs"]]
    o = OLD_ITEMS.get(row["id"])
    t = max(tier[i] for i, _ in ins)
    add({"id": row["id"], "name": row["name"], "plural": o["plural"] if o else row["name"], "short": o["short"] if o else row["name"],
         "kind": kind, "tier": t, "value": float(row["value"])})
    return ins


recipes = [
    {"id": "sweet_mash", "station": "vat", "inputs": {"bell": 10}, "output": "sweet_mash", "seconds": 8.0, "unlock": 0.0, "kitchen": True},
    {"id": "table_mild", "station": "line", "inputs": {"sweet_mash": 1}, "output": "table_mild", "seconds": 8.0, "unlock": 0.0, "kitchen": True},
]
for ing in MAP["ingredients"]:
    m = ing["mash"]
    ins = mash_or_sauce({"id": m["id"], "name": m["name"], "inputs": m["inputs"], "value": m["value"]}, "mash")
    recipes.append({"id": m["id"], "station": "vat", "inputs": dict(ins), "output": m["id"], "seconds": float(m["seconds"]), "unlock": float(m["unlock"])})
for m in MAP["mashes"]:
    ins = mash_or_sauce(m, "mash")
    recipes.append({"id": m["id"], "station": "vat", "inputs": dict(ins), "output": m["id"], "seconds": float(m["seconds"]), "unlock": float(m["unlock"])})
for s in MAP["sauces"]:
    ins = mash_or_sauce(s, "bottle")
    recipes.append({"id": s["id"], "station": "line", "inputs": dict(ins), "output": s["id"], "seconds": float(s["seconds"]), "unlock": float(s["unlock"])})
# Order mashes before sauces in the item list, as the screen groups them.
order = {"crop": 0, "mash": 1, "bottle": 2}
items.sort(key=lambda i: (order[i["kind"]], i.get("rung", 0) if i["kind"] == "crop" else 0))
for i in items:
    i.pop("rung", None)

# --- Farms (data/plots.json) -----------------------------------------------------
plots = []
for f in MAP["farms"]:
    pid = "bell" if f["n"] == 1 else "farm_%02d" % f["n"]
    row = {"id": pid, "name": f["name"], "price": f["price"], "crops": f["crops"], "distance": f["distance"], "survey": f["survey"], "ipm": f["ipm"]}
    if f["n"] == 1:
        row.update({"upgrade_price": 100.0, "harvest_mult": 4.0, "cargo_mult": 4.0})
    plots.append(row)
cheapest = {}
for f in MAP["farms"]:
    if f["survey"] not in cheapest or f["price"] < cheapest[f["survey"]]["price"]:
        cheapest[f["survey"]] = f
for ing in MAP["ingredients"]:
    f = cheapest[ing["survey"]]
    plots.append({"id": ing["id"], "name": ing["station"], "price": f["price"], "crops": {ing["id"]: 100}, "distance": f["distance"],
                  "survey": ing["survey"], "ingredient": True})

# --- Vats and lines ------------------------------------------------------------
slots = {"vat": {"prices": MAP["vats"]}, "line": {"prices": MAP["lines"]}}

# --- Tech ------------------------------------------------------------------------
value_now = {i["id"]: i["value"] for i in items}
kind_now = {i["id"]: i["kind"] for i in items}


def nearest(old_item, count):
    """G23: an old cost item's dollar worth, in the new item of its kind nearest in log value."""
    worth = count * OLD_ITEMS[old_item]["value"]
    kind = OLD_ITEMS[old_item]["kind"]
    best = min((i for i in value_now if kind_now[i] == kind and not OLD_ITEMS.get(i, {}).get("ingredient")),
               key=lambda i: abs(math.log(value_now[i] / OLD_ITEMS[old_item]["value"])))
    return best, max(1, round(worth / value_now[best]))


ROMAN = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII",
         "XVIII", "XIX", "XX", "XXI", "XXII", "XXIII", "XXIV", "XXV"]
EFFECT = {  # adopted IPM project -> our effect
    "Advanced Mining": {"harvest_mult": 1.25}, "Superior Mining": {"harvest_mult": 1.25},
    "Advanced Thrusters": {"truck_speed": 1.25}, "Superior Thrusters": {"truck_speed": 1.25},
    "Advanced Cargo Handling": {"cargo": 1.25}, "Superior Cargo Handling": {"cargo": 1.25},
    "Cargo Logistics": {"crop_priority": True}, "Ore Targeting": {"target_bonus": 0.15}, "Advanced Ore Targeting": {"target_bonus": 0.30},
    "Alchemy": {"crossbreed": 1.0}, "Advanced Alchemy": {"crossbreed": 2.0}, "Superior Alchemy": {"crossbreed": 3.0},
    "Advanced Furnace": {"vat_speed": 1.2}, "Superior Furnace": {"vat_speed": 1.2},
    "Smelting Efficiency": {"vat_input_cut": 0.2}, "Advanced Alloy Value": {"mash_value": 1.2}, "Superior Alloy Value": {"mash_value": 1.2},
    "Smelting Specialist": {"vat_double": 0.1}, "Advanced Crafter": {"line_speed": 1.2}, "Superior Crafting": {"line_speed": 1.2},
    "Crafting Efficiency": {"line_input_cut": 0.2}, "Advanced Item Value": {"sauce_value": 1.2}, "Superior Item Value": {"sauce_value": 1.2},
    "Crafting Specialist": {"line_double": 0.1}, "Preferred Vendor": {"station_discount": 0.5},
    "Furnace Overdrive": {"pressure": 1.0}, "Advanced Furnace Overdrive": {"pressure_speed": 4.0},
    "Furnace Overdrive Efficiency": {"pressure_extra": 0.2}, "Furnace Overdrive 2": {"pressure": 1.0}, "Furnace Overdrive 3": {"pressure": 1.0},
}
MERGED = {"Hydroponic Bell Peppers": "hydroponic_bell", "Hydroponic Jalapeños": "hydroponic_jalapeno", "Zero-Waste Piping I": "zero_waste_1",
          "Zero-Waste Piping II": "zero_waste_2", "Heavy Flint Glass": "flint_glass", "Foil Neck Wraps": "foil_wraps"}
REMOVED_PREFIX = ("unlock_plot", "unlock_recipe", "slot_cap")
DROP = {"jalapeno_blueprint", "poblano_blueprint", "hydroponic_cayenne"}
old_by_id = {n["id"]: n for n in OLD_TECH}


def removed(n):
    if n["id"] in DROP or n["id"] in MERGED.values():
        return n["id"] in DROP
    return any(list(e.keys())[0] in REMOVED_PREFIX for e in n["effects"])


def main_crop(item):
    """The highest-rung pepper (or ingredient) inside an item."""
    rungs = {p["id"]: p["rung"] for p in MAP["peppers"]}
    best = None
    stack = [item]
    seen = set()
    while stack:
        i = stack.pop()
        if i in seen:
            continue
        seen.add(i)
        if kind_now.get(i) == "crop":
            r = rungs.get(i, 0)
            if best is None or r > rungs.get(best, 0):
                best = i
            continue
        for r in recipes:
            if r["output"] == i:
                stack += list(r["inputs"])
    return best


def survey_for_removed(nid):
    """A removed blueprint's place in the new tree: the survey that opens its crop."""
    n = old_by_id[nid]
    if nid in DROP or n["id"].startswith("slot_expansion"):
        return "kitchen_table"
    e = n["effects"][0]
    k = list(e.keys())[0]
    target = e[k]
    crop = target if k == "unlock_plot" else main_crop(target)
    s = first_survey.get(crop, 0)
    return "kitchen_table" if s == 0 else "survey_%d" % s


nodes = []
taken = set()


def place(want, near=None, down=True):
    x, y = want
    if (x, y) not in taken:
        taken.add((x, y))
        return [x, y]
    px, py = near or want
    v = 1 if down else -1   # south-wing nodes grow down the web, east-wing ones up
    for r in range(1, 12):
        for dx, dy in [(0, v * r), (r, v * r), (-r, v * r), (r, 0), (-r, 0), (r, -v * r), (0, -v * r), (-r, -v * r)]:
            c = (px + dx, py + dy)
            if c not in taken:
                taken.add(c)
                return [c[0], c[1]]
    raise RuntimeError("no room near %s" % (want,))


# Surveys along the east row (y = 0).
taken.add((0, 0))
for s in MAP["surveys"]:
    taken.add((s["n"], 0))

kept = []
for n in OLD_TECH:
    if removed(n):
        continue
    kept.append(n)
merged_rows = {MERGED[p["node"]]: p for p in MAP["projects"] if p["node"] in MERGED}
pos_of = {}
for n in kept:
    n = json.loads(json.dumps(n))
    if n["id"] in merged_rows:
        continue  # placed with the adopted projects
    needs = []
    for need in n["needs"]:
        nn = survey_for_removed(need) if need in old_by_id and removed(old_by_id[need]) else need
        if nn not in needs:
            needs.append(nn)
    n["needs"] = [x for x in needs if not (x == "kitchen_table" and len(needs) > 1)]
    cost = {}
    for item, c in n["cost"].items():
        new, cnt = nearest(item, c)
        cost[new] = cost.get(new, 0) + cnt
    n["cost"] = cost
    # Per-crop boosts stay per crop (the Pantry's ingredient stations).
    if n["id"] == "kitchen_table":
        pass
    elif tuple(n["pos"]) in taken:
        n["pos"] = place(tuple(n["pos"]))
    else:
        taken.add(tuple(n["pos"]))
    n["after_sale"] = n["id"] == "standard_operating_procedures"
    if not n["after_sale"]:
        n.pop("after_sale")
    nodes.append(n)
    pos_of[n["id"]] = n["pos"]

for s in MAP["surveys"]:
    k = s["n"]
    node = {"id": "survey_%d" % k, "label": "L%d" % k, "name": "Land Survey " + ROMAN[k], "wing": "east",
            "needs": ["kitchen_table" if k == 1 else "survey_%d" % (k - 1)],
            "cost": {by_name[nm]: int(c) for c, nm in s["cost"]}, "effects": [{"survey": float(k)}], "pos": [k, 0]}
    nodes.append(node)
    pos_of[node["id"]] = node["pos"]


def snake(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower().replace("'", "")).strip("_")


ids = {p["node"]: MERGED.get(p["node"], snake(p["node"])) for p in MAP["projects"]}
label_n = {"east": 0, "south": 10}
FARM_SIDE = {"Advanced Mining", "Superior Mining", "Advanced Thrusters", "Superior Thrusters", "Advanced Cargo Handling",
             "Superior Cargo Handling", "Cargo Logistics", "Ore Targeting", "Advanced Ore Targeting", "Alchemy", "Advanced Alchemy", "Superior Alchemy"}
for p in MAP["projects"]:
    nid = ids[p["node"]]
    alts = [a.strip() for a in p["needs"].split(" OR ")]
    need_ids = []
    for a in alts:
        a = re.sub(r"\s*\(.*\)$", "", a).strip()
        if a == "Kitchen Table":
            need_ids.append("kitchen_table")
        elif a.startswith("Land Survey"):
            need_ids.append("survey_" + a.split()[-1])
        else:
            need_ids.append(ids[a])
    wing = "east" if p["ipm"] in FARM_SIDE else "south"
    if nid in MERGED.values():
        label = old_by_id[nid]["label"]
    else:
        label_n[wing] += 1
        label = ("F%d" if wing == "east" else "S%d") % label_n[wing]
    parent = pos_of.get(need_ids[0], [0, 0])
    want = (parent[0], parent[1] - 1) if wing == "east" else (parent[0], parent[1] + 1)
    node = {"id": nid, "label": label, "name": p["node"], "wing": wing,
            "needs": need_ids[:1], "cost": {by_name[nm]: int(c) for c, nm in p["cost"]},
            "effects": [EFFECT[p["ipm"]]], "pos": place(want, near=tuple(parent), down=wing == "south"), "ipm": p["ipm"]}
    if len(need_ids) > 1:
        node["needs"] = []
        node["needs_any"] = need_ids
    nodes.append(node)
    pos_of[nid] = node["pos"]

# Parents before children (the loader checks needs against earlier rows).
done, out = set(), []
pending = list(nodes)
while pending:
    for n in list(pending):
        if all(x in done for x in n["needs"] + n.get("needs_any", [])):
            out.append(n)
            done.add(n["id"])
            pending.remove(n)
            break
    else:
        raise RuntimeError("tech needs loop: " + ", ".join(n["id"] for n in pending))

# --- Rooms -----------------------------------------------------------------------
EFF = {"Seed Vault": "harvest", "Fermentation Cellar": "vat_speed", "Motor Pool": "truck_speed", "Land Office": "upgrade_cost",
       "Crate Yard": "cargo", "High-Speed Cannery": "line_speed", "Test Kitchen": "tech_cost", "Ergonomics Lab": "button_yield",
       "Boardroom": "credits", "Night Watchman's Desk": "offline_hours", "Seed Capital Office": "start_cash",
       "Cooperage": "vat_input", "Glassworks": "line_input", "Tasting Room": "value", "Ad Agency": "ticker"}
OLD_ID = {"Seed Vault": "seed_vault", "Fermentation Cellar": "fermentation_cellar", "High-Speed Cannery": "high_speed_cannery",
          "Test Kitchen": "test_kitchen", "Ergonomics Lab": "ergonomics_lab", "Night Watchman's Desk": "night_watchman",
          "Seed Capital Office": "seed_capital", "Cooperage": "cooperage", "Glassworks": "glassworks", "Tasting Room": "tasting_room"}


def factor(t):
    t = t.replace(" ", "")
    if t.startswith("+") and ":" in t:   # +0:30 → hours
        h, m = t[1:].split(":")
        return int(h) + int(m) / 60
    if t.endswith("%"):
        return float(t.lstrip("x").rstrip("%")) / 100
    return float(t.lstrip("x+"))


engineering = next(r for r in MAP["rooms"] if r["name"] == "Seed Vault")["level_costs"]
rooms = []
for r in MAP["rooms"]:
    rid = OLD_ID.get(r["name"], snake(r["name"]))
    row = {"id": rid, "name": r["name"], "effect": EFF[r["name"]], "open_cost": r["open_cost"]}
    if r["ipm"]:
        base, step = factor(r["base"]), factor(r["per_level"])
        if r["per_level"].replace(" ", "").startswith("-"):
            step = -abs(step)
        row.update({"base": base, "step": step, "cap": r["max"], "level_costs": r["level_costs"][: r["max"] - 1], "ipm": r["ipm"]})
    else:
        o = OLD_ROOMS[rid]
        row.update({k: o[k] for k in ("base", "step", "amounts", "growth") if k in o})
        row.update({"cap": o["cap"], "level_costs": engineering[: o["cap"] - 1]})
    rooms.append(row)

SRC = "Built by tools/ipm/build_data.py from docs/ipm_snapshot.json through docs/SKELETON.md's mapping (v0.7, D049–D053)."
files = {
    "items": {"_source": SRC + " Values are Idle Planet Miner's (ores, alloys, items); the kitchen's two are D004's (D052). `tier` groups crops four rungs a tier, and a made item takes its highest input's.", "items": items},
    "recipes": {"_source": SRC + " IPM's recipes, seconds and cash unlock prices (`unlock`, 0 is free); four sauces also take an ingredient mash (D051). `kitchen` recipes run only in the first vat and line (D052).", "recipes": recipes},
    "plots": {"_source": SRC + " The farms: IPM's planets with their crop shares (percent), prices, distances and telescope (`survey`, 0 on sale from the start); farm 1 is the tutorial's Bell Plot (D052). Ingredient stations are priced and placed like their survey's cheapest farm. Farms 77–79 and distances from farm 71 are assumed (G22).", "plots": plots},
    "slots": {"_source": SRC + " Vat and line prices in buying order: IPM's smelters and crafters; the first of each is the kitchen's (D052); crafters 7–10 are the wiki's doubled (it quotes them after Preferred Vendor).", **slots},
    "tech": {"_source": SRC + " Land Surveys are IPM's telescopes; nodes with `ipm` are its projects at its costs; the rest are ours, with costs kept at their old dollar worth in the nearest-valued item of their kind (G23). `needs_any`: at least one of them (IPM's OR). `pos` is the node's place in the web.", "nodes": out},
    "rooms": {"_source": SRC + " IPM's rooms: `base` at Level 1, `step` a level, `cap`, `level_costs` (credits from each level to the next) and `open_cost` (credits for the n-th room bought, offered two at a time in file order). Ergonomics Lab and Seed Capital Office are ours, on Seed Vault's level costs (assumed).", "rooms": rooms},
}
for name, body in files.items():
    with open(f"data/{name}.json", "w") as fh:
        json.dump(body, fh, indent="\t", ensure_ascii=False)
        fh.write("\n")
print({k: len(v.get(k, v.get("nodes", v.get("rooms", [])))) if isinstance(v, dict) else 0 for k, v in files.items()})
