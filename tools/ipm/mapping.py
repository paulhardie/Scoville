"""Build the skeleton mapping tables (markdown) from docs/ipm_snapshot.json.

Usage: python3 -I mapping.py <snapshot.json> <out_dir>
Writes one .md fragment per table into out_dir, plus mapping.json.
"""
import json, re, sys, os, math

snap = json.load(open(sys.argv[1]))
OUT = sys.argv[2]
os.makedirs(OUT, exist_ok=True)

SUF = {"": 1, "K": 1e3, "k": 1e3, "M": 1e6, "B": 1e9, "T": 1e12, "q": 1e15, "Q": 1e18,
       "s": 1e21, "S": 1e24, "O": 1e27, "N": 1e30, "D": 1e33}
NAMES = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


def num(t):
    t = t.replace(",", "").strip()
    m = re.match(r"^([0-9.]+)\s*([A-Za-z]?)", t)
    if not m:
        return None
    return float(m.group(1)) * SUF[m.group(2)]


def fmt(x, money=True):
    """Three figures and our suffixes (D035 money style past $10,000)."""
    if x is None:
        return "unverified"
    if x < 10000:
        s = f"{x:,.0f}" if x == int(x) else f"{x:,.2f}"
        return ("$" if money else "") + s
    k = int(math.floor(math.log10(x) / 3))
    v = x / 1000 ** k
    if round(v, 2) >= 1000:
        k += 1
        v /= 1000
    s = f"{v:.0f}" if v >= 100 else (f"{v:.1f}" if v >= 10 else f"{v:.2f}")
    return ("$" if money else "") + s + NAMES[k]


# --- Peppers: one per IPM ore, by Scoville (PepperScale, read 2026-10-23) ------
PEPPERS = [
    # id, name, SHU, note
    ("bell", "Bell Pepper", "0", ""),
    ("pimento", "Pimento", "100–500", "new"),
    ("poblano", "Poblano", "1,000–1,500", ""),
    ("cascabel", "Cascabel", "1,000–3,000", "new"),
    ("jalapeno", "Jalapeño", "2,500–8,000", ""),
    ("hungarian_wax", "Hungarian Wax", "5,000–10,000", "new"),
    ("serrano", "Serrano", "10,000–23,000", ""),
    ("arbol", "Chile de Árbol", "15,000–30,000", "new"),
    ("cayenne", "Cayenne", "30,000–50,000", ""),
    ("pequin", "Pequin", "40,000–60,000", "new"),
    ("thai_chili", "Thai Chili", "50,000–100,000", ""),
    ("bonnet", "Scotch Bonnet", "100,000–350,000", ""),
    ("fatalii", "Fatalii", "125,000–400,000", "new"),
    ("caribbean_red", "Caribbean Red Habanero", "300,000–445,000", ""),
    ("chocolate", "Chocolate Habanero", "425,000–577,000", ""),
    ("ghost", "Ghost Pepper", "855,000–1,041,427", ""),
    ("seven_pot", "Trinidad 7 Pot", "1,000,000–1,200,000", "new (D042 had dropped it; back for more rungs)"),
    ("naga", "Naga Morich", "1,000,000–1,500,000", "new"),
    ("moruga", "Trinidad Moruga Scorpion", "1,200,000–2,000,000", ""),
    ("grim", "*Alabama Grim*", "the Reaper's band, 1,400,000–2,200,000", "parody (D042)"),
    ("pepper_y", "*Pepper Y*", "2,693,001", "parody (D042)"),
    ("lava_lantern", "*Lava Lantern*", "5,000,000", "fictional (D023)"),
    ("solar_flare", "*Solar Flare*", "10,000,000", "fictional (D023)"),
    ("capsaicin_crystal", "*Capsaicin Crystal*", "16,000,000 (pure capsaicin)", "fictional (D023)"),
    ("brimstone", "*Brimstone Jolokia*", "50,000,000", "fictional (D023)"),
    ("supernova", "*Supernova Scorpion*", "500,000,000", "fictional (D023)"),
    ("event_horizon", "*Event Horizon*", "16,000,000,000 (resiniferatoxin)", "fictional (D023)"),
    ("heat_death", "*Heat Death*", "past measuring", "fictional, new: the last rung"),
]
ORES = snap["ores"]
assert len(ORES) == len(PEPPERS) == 28
ORE2P = {}
for (pid, pname, shu, note), ore in zip(PEPPERS, ORES):
    ORE2P[ore["name"]] = (pid, pname.strip("*"))
ORE2P["Aluminium"] = ORE2P["Aluminum"]
ORE2P["Silica"] = ORE2P["Silicon"]
ORE2P["Paladium"] = ORE2P["Palladium"]
PVAL = {pid: num(o["value"]) for (pid, *_), o in zip(PEPPERS, ORES)}

# first planet of each ore
first_on = {}
for p in snap["planets"]:
    for o, _ in p["ores"]:
        if o and o not in first_on:
            first_on[o] = (p["n"], p["telescope"])

# --- Mashes: IPM's 29 bars and alloys --------------------------------------
MASH = {
    "Copper Bar": ("bell_puree", "Bell Pepper Purée"),
    "Iron Bar": ("pimento_mash", "Pimento Mash"),
    "Lead Bar": ("ancho_mash", "Ancho Mash"),
    "Silicon Bar": ("cascabel_mash", "Cascabel Mash"),
    "Aluminum Bar": ("verde_mash", "Verde Mash"),
    "Silver Bar": ("hungarian_wax_mash", "Hungarian Wax Mash"),
    "Gold Bar": ("serrano_mash", "Serrano Mash"),
    "Bronze Bar": ("sofrito_base", "Sofrito Base"),
    "Steel Bar": ("mole_base", "Mole Base"),
    "Platinum Bar": ("cayenne_mash", "Cayenne Mash"),
    "Titanium Bar": ("pequin_mash", "Pequin Mash"),
    "Iridium Bar": ("thai_chili_mash", "Thai Chili Mash"),
    "Palladium Bar": ("bonnet_mash", "Bonnet Mash"),
    "Osmium Bar": ("fatalii_mash", "Fatalii Mash"),
    "Rhodium Bar": ("caribbean_red_mash", "Caribbean Red Mash"),
    "Inerton Alloy": ("chocolate_mash", "Chocolate Habanero Mash"),
    "Quadium Alloy": ("ghost_mash", "Ghost Mash"),
    "Scrith Alloy": ("seven_pot_mash", "Seven Pot Mash"),
    "Uru Alloy": ("naga_mash", "Naga Mash"),
    "Vibranium Alloy": ("moruga_mash", "Moruga Mash"),
    "Aether Alloy": ("grim_mash", "Grim Mash"),
    "Viterium Alloy": ("pepper_y_mash", "Pepper Y Mash"),
    "Xynium Alloy": ("lava_lantern_mash", "Lava Lantern Mash"),
    "Quolium Alloy": ("solar_flare_mash", "Solar Flare Mash"),
    "Luterium Alloy": ("crystal_extract", "Crystal Extract"),
    "Wraith Alloy": ("brimstone_mash", "Brimstone Mash"),
    "Aqualite Alloy": ("supernova_mash", "Supernova Mash"),
    "Opalite Alloy": ("event_horizon_mash", "Event Horizon Mash"),
    "Celestite Alloy": ("heat_death_mash", "Heat Death Mash"),
}
# --- Sauces: IPM's 48 items ------------------------------------------------
SAUCE = {
    "Copper Wire": ("sweet_pepper_relish", "Sweet Pepper Relish"),
    "Iron Nails": ("pimento_spread", "Pimento Spread"),
    "Battery": ("garden_hot_sauce", "Garden Hot Sauce"),
    "Hammer": ("smoky_ancho", "Smoky Ancho"),
    "Glass": ("cascabel_salsa", "Cascabel Salsa"),
    "Circuit": ("bistro_verde", "Bistro Verde"),
    "Lens": ("garlic_gold", "Garlic Gold"),
    "Laser": ("serrano_fire", "Serrano Fire"),
    "Basic Computer": ("salsa_verde_reserve", "Salsa Verde Reserve"),
    "Solar Panel": ("sunshine_sauce", "Sunshine Sauce"),
    "Laser Torch": ("pineapple_picante", "Pineapple Picante"),
    "Advanced Battery": ("mole_poblano", "Mole Poblano"),
    "Thermal Scanner": ("classic_louisiana", "Classic Louisiana"),
    "Advanced Computer": ("phantom", "Phantom Smokehouse"),
    "Navigation Module": ("cajun_red", "Cajun Red"),
    "Plasma Torch": ("bangkok_burn", "Bangkok Burn"),
    "Radio Tower": ("pitmaster_bbq", "Pitmaster BBQ"),
    "Telescope": ("smoked_paprika", "Smoked Paprika Reserve"),
    "Satellite Dish": ("island_heat", "Island Heat"),
    "Motor": ("ranchero", "Ranchero"),
    "Accumulator": ("fatalii_fire", "Fatalii Fire"),
    "Nuclear Capsule": ("sweet_heat", "Sweet Heat Reserve"),
    "Wind Turbine": ("jalapeno_ranch", "Jalapeño Ranch"),
    "Space Probe": ("tropical_storm", "Tropical Storm"),
    "Nuclear Reactor": ("volcano_sauce", "Volcano Sauce"),
    "Collider": ("cocoa_loco", "Cocoa Loco"),
    "Gravity Chamber": ("black_hole", "Black Hole Sauce"),
    "Robot": ("seven_pot_stew", "Seven Pot Stew"),
    "Fusion Capsule": ("naga_sunrise", "Naga Sunrise"),
    "Teleporter": ("ghost_town", "Ghost Town"),
    "Fusion Reactor": ("scorpion_sting", "Scorpion Sting"),
    "Subspace Relay": ("hurricane_reserve", "Hurricane Reserve"),
    "Advanced Robot": ("widowmaker", "Widowmaker Reserve"),
    "Advanced Teleporter": ("lava_flow", "Lava Flow"),
    "Quantum CPU": ("solar_wind", "Solar Wind"),
    "Deflector Shield": ("crystal_clear", "Crystal Clear"),
    "Warp Core": ("hyperdrive", "Hyperdrive"),
    "Deep Space Scanner": ("cosmic_drizzle", "Cosmic Drizzle"),
    "Antimatter Cell": ("dark_star", "Dark Star"),
    "Atmospheric Processor": ("stratosphere", "Stratosphere"),
    "Orbital Dock": ("brimstone_reserve", "Brimstone Reserve"),
    "Solar Collector": ("supernova_glaze", "Supernova Glaze"),
    "Phase Gate": ("wormhole", "Wormhole"),
    "Neural Matrix": ("mind_melt", "Mind Melt"),
    "Stellar Capacitor": ("big_bang", "Big Bang"),
    "Plasma Conduit": ("extinction_event", "Extinction Event"),
    "Graviton Lance": ("singularity", "Singularity"),
    "System Regulator": ("last_drop", "The Last Drop"),
}
assert len(MASH) == len(snap["alloys"]) and len(SAUCE) == len(snap["items"])

# Name lookup for any IPM thing in a cost or recipe string.
LOOK = {}
for k, v in MASH.items():
    LOOK[k] = v[1]
    LOOK[k.replace(" Bar", " Alloy")] = v[1]
    LOOK[k.replace(" Alloy", " Bar")] = v[1]
for k, v in SAUCE.items():
    LOOK[k] = v[1]
    LOOK[k + "s"] = v[1]
LOOK["Iron Nail"] = SAUCE["Iron Nails"][1]
LOOK["Fusion Capsules"] = SAUCE["Fusion Capsule"][1]
LOOK["Satellite"] = SAUCE["Satellite Dish"][1]
LOOK["Aluminium Bar"] = MASH["Aluminum Bar"][1]
LOOK["Paladium Bar"] = MASH["Palladium Bar"][1]
LOOK["Inerton Bar"] = MASH["Inerton Alloy"][1]
LOOK["Quadium Bar"] = MASH["Quadium Alloy"][1]
LOOK["Teleporters"] = SAUCE["Teleporter"][1]
LOOK["AntiMatter Cell"] = SAUCE["Antimatter Cell"][1]
LOOK["Advanced Robots"] = SAUCE["Advanced Robot"][1]
LOOK["Copper Wire"] = SAUCE["Copper Wire"][1]
for o, (pid, pn) in ORE2P.items():
    LOOK[o] = pn
    LOOK[o + " Ore"] = pn

VALUE = {}  # IPM name -> value
INPUTS = {}  # IPM name -> list[(count, IPM name)]


def parse_inputs(s):
    s = re.sub(r"\(with epic.*?\)", "", s)
    out = []
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        m = re.match(r"^([0-9.,]+)\s*([kK]?)\s+(.+)$", part)
        if m:
            n = float(m.group(1).replace(",", "")) * (1000 if m.group(2) else 1)
            name = m.group(3).strip()
        else:
            n, name = 1, part
        name = re.sub(r"\bbar\b", "Bar", name)
        out.append([n, name])
    return out


def ours(name):
    if name in LOOK:
        return LOOK[name]
    raise KeyError(name)


def fmt_count(n):
    if n >= 1000 and n % 1000 == 0:
        return f"{int(n/1000)}K"
    if n >= 1000:
        return f"{n/1000:g}K"
    return f"{n:g}"


def render_inputs(lst):
    return ", ".join(f"{fmt_count(n)} {ours(nm)}" for n, nm in lst)


for a in snap["alloys"]:
    VALUE[a["name"]] = num(a["value"])
    INPUTS[a["name"]] = parse_inputs(a["inputs"])
for it in snap["items"]:
    VALUE[it["name"]] = num(it["value"]) if not it["value"].startswith("probably") else None
    INPUTS[it["name"]] = parse_inputs(it["inputs"])
# The four top recipes are quoted with a 10% suit discount: undo it (15.12K / 0.9 = 16.8K).
for k in ["Stellar Capacitor", "Plasma Conduit", "Graviton Lance", "System Regulator"]:
    INPUTS[k] = [[16800 if n == 15120 else n, nm] for n, nm in INPUTS[k]]
for o in snap["ores"]:
    VALUE[o["name"]] = num(o["value"])
VALUE["Aluminium"] = VALUE["Aluminum"]
VALUE["Silica"] = VALUE["Silicon"]


def vname(nm):
    for k in (nm, nm.replace(" Bar", " Alloy"), nm.replace(" Alloy", " Bar"), nm.rstrip("s"),
              {"Iron Nail": "Iron Nails", "Satellite": "Satellite Dish", "Aluminium Bar": "Aluminum Bar",
               "Paladium Bar": "Palladium Bar", "AntiMatter Cell": "Antimatter Cell", "Fusion Capsules": "Fusion Capsule"}.get(nm, nm)):
        if k in VALUE:
            return k
    raise KeyError(nm)


def input_value(lst):
    tot = 0
    for n, nm in lst:
        v = VALUE.get(vname(nm))
        if v is None:
            return None
        tot += n * v
    return tot


# --- Ingredients (ours, D051): stations, mashes, where they enter ------------
ING = [
    # id, name, station, value (ore of same value), survey, mash id, mash name, IPM bar whose markup/time/unlock it takes
    ("vinegar", "White Vinegar", "Vinegar Cask", 2.0, 1, "pickled_brine", "Pickled Brine", "Iron Bar"),
    ("garlic", "Garlic", "Garlic Plot", 17.0, 3, "garlic_paste", "Roasted Garlic Paste", "Aluminum Bar"),
    ("pineapple", "Pineapple", "Pineapple Grove", 75.0, 4, "glaze", "Charred Pineapple Glaze", "Gold Bar"),
    ("oak", "Smoked Oak", "Oak Smokehouse", 730.0, 6, "liquid_smoke", "Liquid Smoke", "Titanium Bar"),
]
ING_MASH_VAL = {}
alloy_by = {a["name"]: a for a in snap["alloys"]}
for iid, iname, station, v, survey, mid, mname, bar in ING:
    markup = VALUE[bar] / input_value(INPUTS[bar])
    ING_MASH_VAL[mid] = round(1000 * v * markup, -1 if 1000 * v * markup < 1e5 else -4)
# Each ingredient mash enters two sauces as an extra input worth about 10% of the
# sauce's IPM inputs; the sauce's value rises by the same share (IPM's markup kept).
ING_USES = {
    "Hammer": ("pickled_brine", "Pickled Brine"),
    "Circuit": ("pickled_brine", "Pickled Brine"),
    "Lens": ("garlic_paste", "Roasted Garlic Paste"),
    "Thermal Scanner": ("garlic_paste", "Roasted Garlic Paste"),
    "Laser Torch": ("glaze", "Charred Pineapple Glaze"),
    "Satellite Dish": ("glaze", "Charred Pineapple Glaze"),
    "Advanced Computer": ("liquid_smoke", "Liquid Smoke"),
    "Radio Tower": ("liquid_smoke", "Liquid Smoke"),
}


def sig3(x):
    if x == 0:
        return 0
    d = math.floor(math.log10(x)) - 2
    return round(x / 10 ** d) * 10 ** d


ING_ROWS = {}
for item, (mid, mname) in ING_USES.items():
    iv = input_value(INPUTS[item])
    mv = ING_MASH_VAL[mid]
    n = max(1, round(0.10 * iv / mv))
    newv = sig3(VALUE[item] * (iv + n * mv) / iv)
    ING_ROWS[item] = (n, mname, newv, iv)

mapping = {"peppers": [], "mashes": [], "sauces": [], "farms": [], "surveys": [], "ingredients": []}

# --- Table: peppers ---------------------------------------------------------
L = ["| # | Pepper | Scoville (SHU) | IPM ore | Value | IPM's first planet (telescope) | Note |",
     "| --- | --- | --- | --- | --- | --- | --- |"]
for i, ((pid, pname, shu, note), ore) in enumerate(zip(PEPPERS, ORES), 1):
    fo = first_on.get(ore["name"]) or first_on.get({"Aluminum": "Aluminium", "Silicon": "Silica"}.get(ore["name"], ""))
    fos = f"P{fo[0]} ({fo[1]})" if fo else "none priced (P77–79 assumed)"
    L.append(f"| {i} | {pname} | {shu} | {ore['name']} | {fmt(num(ore['value']))} | {fos} | {note} |")
    mapping["peppers"].append({"rung": i, "id": pid, "name": pname.strip("*"), "shu": shu, "ore": ore["name"], "value": num(ore["value"])})
open(f"{OUT}/peppers.md", "w").write("\n".join(L) + "\n")

# --- Table: farms -------------------------------------------------------------
farms = []
for p in snap["planets"]:
    farms.append(dict(p))
# P77–79: names only on the wiki. Assumed (G22): ×3 a farm (IPM's step from P57),
# Celestite arriving as IPM's new ores do.
last = num(farms[75]["price"])
ext = {77: [["Opalite", "70"], ["Celestite", "30"]], 78: [["Celestite", "70"], ["Opalite", "30"]], 79: [["Celestite", "100"]]}
for f in farms[76:]:
    last *= 3
    f["price_guess"] = last
    f["ores"] = ext[f["n"]]
# Distances unknown from P71: +2 a farm from Leto's 134 (IPM's recent step), assumed.
for f in farms:
    if f["distance"] in ("Unknown", "", None):
        f["distance_guess"] = 134 + 2 * (f["n"] - 70)
lead_count = {}
L = ["| Farm | Name | Price | Crops (%) | Distance | Opened by | IPM planet |", "| --- | --- | --- | --- | --- | --- | --- |"]
for f in farms:
    shares = [(ORE2P[o][0], ORE2P[o][1], int(pc.rstrip("*"))) for o, pc in f["ores"] if o]
    SHORT = {"Bell Pepper": "Bell", "Ghost Pepper": "Ghost", "Caribbean Red Habanero": "Caribbean Red",
             "Trinidad Moruga Scorpion": "Moruga", "Chocolate Habanero": "Chocolate", "Trinidad 7 Pot": "7 Pot",
             "Naga Morich": "Naga", "Scotch Bonnet": "Bonnet", "Chile de Árbol": "Árbol", "Capsaicin Crystal": "Crystal",
             "Brimstone Jolokia": "Brimstone", "Supernova Scorpion": "Supernova", "Alabama Grim": "Grim"}
    lead = SHORT.get(shares[0][1], shares[0][1])
    if f["n"] > 1:
        lead_count[lead] = lead_count.get(lead, 0) + 1
    roman = ["", " II", " III", " IV", " V", " VI", " VII", " VIII"][lead_count.get(lead, 1) - 1]
    name = "Bell Plot" if f["n"] == 1 else f"{lead} Farm{roman}"
    price = num(f["price"]) if f.get("price") else None
    pshow = fmt(price) if price else fmt(f["price_guess"]) + " (assumed)"
    if f["n"] == 1:
        pshow = "$50 (tutorial, IPM $100)"
    dist = f["distance"] if not f.get("distance_guess") else f"{f['distance_guess']} (assumed)"
    tel = f["telescope"].strip()
    opened = "on sale from the start" if tel.startswith("Default") else f"Land Survey {tel}"
    crops = ", ".join(f"{n} {pc}" for _, n, pc in shares)
    tot = sum(pc for *_, pc in shares)
    if tot != 100:
        crops += f" (sums to {tot}, as the wiki has it)"
    L.append(f"| {f['n']} | {name} | {pshow} | {crops} | {dist} | {opened} | {f['name']} |")
    mapping["farms"].append({"n": f["n"], "name": name, "price": 50.0 if f["n"] == 1 else (price or f["price_guess"]),
                             "price_assumed": price is None, "crops": {pid: pc for pid, _, pc in shares},
                             "distance": float(f["distance_guess"] if f.get("distance_guess") else f["distance"]),
                             "distance_assumed": bool(f.get("distance_guess")),
                             "survey": 0 if tel.startswith("Default") else int(tel), "ipm": f["name"]})
open(f"{OUT}/farms.md", "w").write("\n".join(L) + "\n")

# --- Table: mashes --------------------------------------------------------------
L = ["| # | Mash | IPM | Inputs | Seconds | Unlock (cash) | Value |", "| --- | --- | --- | --- | --- | --- | --- |"]


def secs(t):
    t = t.strip()
    if not t:
        return None
    parts = [int(x) for x in t.split(":")]
    s = 0
    for x in parts:
        s = s * 60 + x
    return s


for i, a in enumerate(snap["alloys"], 1):
    mid, mname = MASH[a["name"]]
    t = secs(a["time"])
    unlock = "free" if a["unlock"].lower() == "free" else fmt(num(a["unlock"]))
    L.append(f"| {i} | {mname} | {a['name']} | {render_inputs(INPUTS[a['name']])} | {t if t else 'unverified (assumed 100:00)'} | {unlock} | {fmt(VALUE[a['name']])} |")
    mapping["mashes"].append({"id": mid, "name": mname, "ipm": a["name"], "inputs": [[n, ours(nm)] for n, nm in INPUTS[a["name"]]],
                              "seconds": t or 6000, "unlock": 0 if unlock == "free" else num(a["unlock"]), "value": VALUE[a["name"]]})
open(f"{OUT}/mashes.md", "w").write("\n".join(L) + "\n")

# ingredient mashes
L = ["| Ingredient | Value | Station | Opens with | Its mash | Inputs | Seconds | Unlock | Value | Priced like |", "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
for iid, iname, station, v, survey, mid, mname, bar in ING:
    a = alloy_by[bar]
    L.append(f"| {iname} | {fmt(v)} | {station} | Land Survey {survey} | {mname} | 1K {iname} | {secs(a['time'])} | {fmt(num(a['unlock']))} | {fmt(ING_MASH_VAL[mid])} | {MASH[bar][1]} ({bar}) |")
    mapping["ingredients"].append({"id": iid, "name": iname, "station": station, "value": v, "survey": survey,
                                   "mash": {"id": mid, "name": mname, "inputs": [[1000, iname]], "seconds": secs(a["time"]),
                                            "unlock": num(a["unlock"]), "value": ING_MASH_VAL[mid]}})
open(f"{OUT}/ingredients.md", "w").write("\n".join(L) + "\n")

# --- Table: sauces --------------------------------------------------------------
L = ["| # | Sauce | IPM | Inputs | Seconds | Unlock (cash) | IPM value | Our value |", "| --- | --- | --- | --- | --- | --- | --- | --- |"]
for i, it in enumerate(snap["items"], 1):
    sid, sname = SAUCE[it["name"]]
    inp = render_inputs(INPUTS[it["name"]])
    v = VALUE[it["name"]]
    ourv = v
    if it["name"] in ING_ROWS:
        n, mname, ourv, _ = ING_ROWS[it["name"]]
        inp += f", **{n} {mname}**"
    t = it["time_s"].replace(",", "").split("s")[0].split(" ")[0]
    unlock = "free" if it["unlock"].lower() == "free" else fmt(num(it["unlock"]))
    vshow = fmt(v) if v else "unverified (wiki: \"probably 500 D\")"
    oshow = fmt(ourv) if ourv else "$500Dc (assumed)"
    L.append(f"| {i} | {sname} | {it['name']} | {inp} | {int(t):,} | {unlock} | {vshow} | {oshow} |")
    ins = [[n, ours(nm)] for n, nm in INPUTS[it["name"]]]
    if it["name"] in ING_ROWS:
        ins.append([ING_ROWS[it["name"]][0], ING_ROWS[it["name"]][1]])
    mapping["sauces"].append({"id": sid, "name": sname, "ipm": it["name"], "inputs": ins, "seconds": int(t),
                              "unlock": 0 if unlock == "free" else num(it["unlock"]), "value": ourv or 5e35,
                              "value_assumed": ourv is None})
open(f"{OUT}/sauces.md", "w").write("\n".join(L) + "\n")

# --- Table: surveys (telescopes) ----------------------------------------------
tel = [p for p in snap["projects"] if re.match(r"^Telescope \d+$", p["name"]) and p["text"].startswith("Extends")]
L = ["| Survey | IPM | Cost | Opens farms |", "| --- | --- | --- | --- |"]
for p in tel:
    k = int(p["name"].split()[1])
    L.append(f"| Land Survey {k} | {p['name']} | {render_inputs(parse_inputs(p['cost']))} | {3*k+2}–{3*k+4} |")
    mapping["surveys"].append({"n": k, "cost": [[n, ours(nm)] for n, nm in parse_inputs(p["cost"])], "assumed": False})
for k, cost in [(24, "7 Teleporter, 36 Aqualite Alloy"), (25, "7 Fusion Reactor, 42 Opalite Alloy")]:
    L.append(f"| Land Survey {k} | Telescope {k} (not on the wiki) | {render_inputs(parse_inputs(cost))} (assumed: the next sauce, +1 count, +6 mash) | {3*k+2}–{3*k+4} |")
    mapping["surveys"].append({"n": k, "cost": [[n, ours(nm)] for n, nm in parse_inputs(cost)], "assumed": True})
open(f"{OUT}/surveys.md", "w").write("\n".join(L) + "\n")

# --- Table: adopted projects ----------------------------------------------------
ADOPT = [
    # IPM project, our node, effect (ours), merges with
    ("Advanced Mining", "Hydroponic Bell Peppers", "every farm harvests ×1.25", "E11 (brief name kept)"),
    ("Superior Mining", "Hydroponic Jalapeños", "every farm harvests ×1.25 more (the wiki says it may only add to ×1.2: assumed ×1.25 multiplied)", "E37 (name kept)"),
    ("Advanced Thrusters", "Truck Tune-Up", "trucks ×1.25 faster", ""),
    ("Superior Thrusters", "Highway Route", "trucks ×1.25 faster again", ""),
    ("Advanced Cargo Handling", "Bigger Crates", "truck cargo ×1.25", ""),
    ("Superior Cargo Handling", "Pallet Racking", "truck cargo ×1.25 again", ""),
    ("Cargo Logistics", "Crop Priority", "choose which crop a farm's truck takes first", ""),
    ("Ore Targeting", "Targeted Fertiliser", "a farm's priority crop +15%", ""),
    ("Advanced Ore Targeting", "Precision Fertiliser", "+30% instead (not added to the 15%)", ""),
    ("Alchemy", "Crossbreed I", "one farm's crop becomes the next rung up (you pick the farm)", ""),
    ("Advanced Alchemy", "Crossbreed II", "two rungs up, a farm not already crossbred", ""),
    ("Superior Alchemy", "Crossbreed III", "three rungs up", ""),
    ("Advanced Furnace", "Hotter Burners", "vats ×1.2 faster", ""),
    ("Superior Furnace", "Steam Jackets", "vats ×1.2 faster again", ""),
    ("Smelting Efficiency", "Zero-Waste Piping I", "vat recipes take 20% fewer inputs", "S5 (brief name kept)"),
    ("Advanced Alloy Value", "Slow Roasting", "mashes worth ×1.2", ""),
    ("Superior Alloy Value", "Wood-Fired Roasting", "mashes worth ×1.2 again", ""),
    ("Smelting Specialist", "Double Batch", "10% chance a vat makes two", ""),
    ("Advanced Crafter", "Faster Cappers", "lines ×1.2 faster", ""),
    ("Superior Crafting", "Rotary Filler", "lines ×1.2 faster again", ""),
    ("Crafting Efficiency", "Zero-Waste Piping II", "line recipes take 20% fewer inputs", "S6 (brief name kept)"),
    ("Advanced Item Value", "Heavy Flint Glass", "sauces worth ×1.2", "S3 (brief name kept)"),
    ("Superior Item Value", "Foil Neck Wraps", "sauces worth ×1.2 again", "S4 (brief name kept)"),
    ("Crafting Specialist", "Double Fill", "10% chance a line makes two", ""),
    ("Preferred Vendor", "Bulk Buyer's Club", "new vats and lines cost half", ""),
    ("Furnace Overdrive", "Pressure Cooker", "one vat ×2 speed, inputs +50%", ""),
    ("Advanced Furnace Overdrive", "Pressure Cooker II", "the Pressure Cooker ×4 instead", ""),
    ("Furnace Overdrive Efficiency", "Pressure Valve", "its extra inputs +20% instead of +50%", ""),
    ("Furnace Overdrive 2", "Second Pressure Cooker", "a second vat under pressure", ""),
    ("Furnace Overdrive 3", "Third Pressure Cooker", "a third", ""),
]
proj = {p["name"]: p for p in snap["projects"]}
L = ["| Our node | IPM project | Cost | Needs (IPM's) | Effect | Note |", "| --- | --- | --- | --- | --- | --- |"]
mapping["projects"] = []
for ipm, node, eff, note in ADOPT:
    p = proj[ipm]
    cost = render_inputs(parse_inputs(p["cost"]))
    needs = p["needs"]
    for k, (_, nm) in [(x, (None, y)) for x, y in []]:
        pass
    needs_ours = needs.replace("Telescope ", "Land Survey ")
    subs = {a[0].lower(): a[1] for a in ADOPT}
    subs.update({"rover": "Kitchen Table (IPM's Rover, left out)",
                 "smelter": "Kitchen Table (IPM's Smelter: our first vat is the kitchen's)",
                 "crafter": "Kitchen Table (IPM's Crafter: our first line)"})
    alt = "|".join(re.escape(k) for k in sorted(subs, key=len, reverse=True))
    needs_ours = re.sub(rf"\b({alt})\b", lambda m: subs[m.group(1).lower()], needs_ours, flags=re.I)
    L.append(f"| {node} | {ipm} | {cost} | {needs_ours} | {eff} | {note} |")
    mapping["projects"].append({"node": node, "ipm": ipm, "cost": [[n, ours(nm)] for n, nm in parse_inputs(p["cost"])], "needs": needs_ours, "effect": eff})
open(f"{OUT}/projects.md", "w").write("\n".join(L) + "\n")

# --- Rooms --------------------------------------------------------------------
ROOMS = [
    ("Engineering", "Seed Vault", "farm harvest speed"),
    ("Forge", "Fermentation Cellar", "vat speed"),
    ("Aeronautical", "Motor Pool", "truck speed (new)"),
    ("Astronomy", "Land Office", "farm upgrade prices (new)"),
    ("Packaging", "Crate Yard", "truck cargo (new)"),
    ("Workshop", "High-Speed Cannery", "line speed"),
    ("Laboratory", "Test Kitchen", "Tech Tree costs"),
    (None, "Ergonomics Lab", "button yield (ours, brief; in Robotics's place)"),
    ("Lounge", "Boardroom", "credits (was the Executive Lounge)"),
    ("Backup Generator", "Night Watchman's Desk", "offline time"),
    (None, "Seed Capital Office", "starting cash (ours, brief; in Terrarium's place)"),
    ("Underforge", "Cooperage", "vat inputs"),
    ("Dorm", "Glassworks", "line inputs"),
    ("Sales", "Tasting Room", "mash and sauce values"),
    ("Marketing", "Ad Agency", "Market Ticker spikes (new)"),
]
rinfo = {r["name"]: r for r in snap["rooms"]}


def level_cost(t):
    """A room level's credits. Aeronautical's and Packaging's level 31 read "10.938" on the wiki,
    a typo for 10,938 (Engineering's same row), so a dot before three digits is a thousands mark."""
    t = t.strip()
    if re.fullmatch(r"\d{1,3}(\.\d{3})+", t):
        t = t.replace(".", "")
    return int(t.replace(",", ""))
# The n-th room bought costs this many credits. The wiki's Min Cost column gives
# Engineering and the Forge 3 each because either can be first; its Combined
# Min Cost column (3, 3, 9, 21, 42…) shows the second purchase costs 6, so the
# Forge's row is skipped.
mins = [int(r["min_cost"].replace(",", "")) for r in snap["rooms"] if r["min_cost"].replace(",", "").isdigit()]
open_costs = [mins[0]] + mins[2:]
L = ["| Offered | Our room | IPM room | Effect | Level 1 | Per level | Max level | Opening cost (credits, as the n-th room bought) |", "| --- | --- | --- | --- | --- | --- | --- | --- |"]
mapping["rooms"] = []
for i, (ipm, ours_r, eff) in enumerate(ROOMS):
    if ipm:
        r = rinfo[ipm]
        L.append(f"| {i+1} | {ours_r} | {ipm} | {eff} | {r['base']} | {r['per_level']} | {r['max_level']} | {open_costs[i]} |")
        lv = snap["room_levels"][ipm]
        mapping["rooms"].append({"name": ours_r, "ipm": ipm, "base": r["base"], "per_level": r["per_level"], "max": int(r["max_level"]),
                                 "level_costs": [level_cost(x["cost"]) for x in lv if x["level"] > 1], "open_cost": open_costs[i]})
    else:
        L.append(f"| {i+1} | {ours_r} | (none) | {eff} | as now (rooms.json) | as now | as now | {open_costs[i]} |")
        mapping["rooms"].append({"name": ours_r, "ipm": None, "open_cost": open_costs[i], "level_costs": "Engineering's (assumed)"})
open(f"{OUT}/rooms.md", "w").write("\n".join(L) + "\n")

# vats and lines
def doubled(x):
    return x.endswith("*")
L = ["| # | Vat (IPM smelter) | Line (IPM crafter) |", "| --- | --- | --- |"]
mapping["vats"], mapping["lines"] = [], []
for i, (s, c) in enumerate(zip(snap["smelters"], snap["crafters"]), 1):
    sv = 150.0 if i == 1 else num(s)
    cv = 100.0 if i == 1 else (num(c.rstrip("*")) * 2 if doubled(c) else num(c))
    ss = "$150 (the kitchen vat, as now; IPM free)" if i == 1 else fmt(sv)
    cs = "$100 (the kitchen line, as now; IPM free)" if i == 1 else (fmt(cv) + f" (the wiki's {c} is after a 50% project: doubled)" if doubled(c) else fmt(cv))
    L.append(f"| {i} | {ss} | {cs} |")
    mapping["vats"].append(sv)
    mapping["lines"].append(cv)
open(f"{OUT}/stations.md", "w").write("\n".join(L) + "\n")

json.dump(mapping, open(f"{OUT}/mapping.json", "w"), indent=1, ensure_ascii=False)
print("ok", {k: len(v) for k, v in mapping.items()})
print("ingredient uses", {k: (v[0], v[1], fmt(v[2])) for k, v in ING_ROWS.items()})
print("ing mash values", {k: fmt(v) for k, v in ING_MASH_VAL.items()})
