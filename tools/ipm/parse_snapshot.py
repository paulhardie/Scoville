"""Parse the pages fetch_pages.sh saved into docs/ipm_snapshot.json.

Usage: python3 -I tools/ipm/parse_snapshot.py <pages_dir> docs/ipm_snapshot.json
"""
import json, re, sys, os
D = sys.argv[1]
def wt(p): return json.load(open(os.path.join(D, p + ".json")))["parse"]["wikitext"]["*"]
def clean(s):
    s = re.sub(r"\[\[File:[^\]]*\]\]", "", s)
    s = re.sub(r"\[\[(?:[^|\]]*\|)?([^\]]*)\]\]", r"\1", s)
    s = re.sub(r"</?nowiki>|</?blockquote>|<sup>|</sup>", "", s)
    s = re.sub(r'^\s*rowspan="?\d+"?\s*\|', "", s.strip())
    return s.strip()
def rows(text):
    out = []
    for t in re.findall(r"\{\|(.*?)\n\|\}", text, flags=re.S):
        for r in t.split("\n|-")[1:]:
            cells = []
            for line in r.split("\n"):
                line = line.strip()
                if line.startswith("|") and not line.startswith("|}"):
                    parts = line[1:].split("||") if "||" in line else [line[1:]]
                    cells += [clean(c) for c in parts]
            out.append(cells)
    return out
snap = {"source": "Idle Planet Miner Wiki (idle-planet-miner.fandom.com), CC BY-SA, read 2026-10-23 through the MediaWiki API"}
# Ores
snap["ores"] = [{"name": r[1], "value": r[2]} for r in rows(wt("Ores")) if len(r) >= 3]
# Alloys: picture, name, unlock, material, time, price, uses
snap["alloys"] = [{"name": r[1], "unlock": r[2], "inputs": r[3], "time": r[4], "value": r[5]} for r in rows(wt("Alloys")) if len(r) >= 6]
# Items: picture, item, unlock, sell, material, time
snap["items"] = [{"name": r[1], "unlock": r[2], "value": r[3], "inputs": r[4], "time_s": r[5]} for r in rows(wt("Items")) if len(r) >= 6]
# Planets: rowspan rows
planets = []
for r in rows(wt("Planets").split("== Mining Rate")[0]):
    if len(r) >= 7 and r[0].isdigit():
        planets.append({"n": int(r[0]), "name": r[1], "price": r[2], "telescope": r[3], "ores": [[r[4], r[5]]], "distance": r[6]})
    elif len(r) == 2 and planets:
        planets[-1]["ores"].append([r[0], r[1]])
    elif len(r) >= 4 and r[0].isdigit():  # 77-79, names only
        planets.append({"n": int(r[0]), "name": r[1], "price": r[2] or None, "telescope": r[3], "ores": [], "distance": None})
for p in planets:
    p["ores"] = [o for o in p["ores"] if o[0]]
snap["planets"] = [p for p in planets if p["n"] <= 79]
# Telescopes and projects
proj = []
for r in rows(wt("Projects")):
    if len(r) >= 4 and r[0] and not r[0].startswith("''"):
        proj.append({"name": r[0], "cost": r[1], "text": r[2], "needs": r[3] if len(r) > 3 else "", "note": r[4] if len(r) > 4 else ""})
snap["projects"] = proj
snap["smelters"] = [r[1] for r in rows(wt("Smelters")) if len(r) >= 2]
snap["crafters"] = [r[1] for r in rows(wt("Crafters")) if len(r) >= 2]
# Rooms
room_rows = rows(wt("Rooms"))
snap["rooms"] = [{"name": r[0], "boost": r[1], "min_cost": r[2], "combined": r[3], "base": r[4], "per_level": r[5], "max_level": r[6], "max_bonus": r[7]} for r in room_rows if len(r) >= 8]
levels = {}
for p in ["Engineering", "Forge", "Aeronautical", "Astronomy", "Packaging", "Workshop", "Laboratory", "Lounge", "Backup_Generator", "Underforge", "Dorm", "Sales", "Marketing"]:
    lv = []
    for r in rows(wt(p)):
        if len(r) >= 3 and r[0].isdigit() and int(r[0]) <= 100:
            lv.append({"level": int(r[0]), "cost": r[1], "boost": r[-1]})
    levels[p.replace("_", " ")] = lv
snap["room_levels"] = levels
snap["credits"] = [[r[0], r[1]] for r in rows(wt("Credit"))[:10] if len(r) == 2 and r[1].isdigit()]
snap["credits_past_table"] = "each decade 10x more: the next triangular number x10 (the wiki's words)"
# Planet upgrades: the wiki's formulas (as text) and its level table.
up = wt("Planetary_Upgrades")
snap["upgrades"] = {"formulas": [clean(l.lstrip("* ").replace("'''", "")) for l in up.splitlines() if l.startswith("* '")],
                    "levels": [{"level": int(r[0]), "mining": r[1], "ship_speed": r[2], "cargo": r[3], "price_share": r[4]}
                               for r in rows(up) if len(r) >= 5 and r[0].isdigit()]}
json.dump(snap, open(sys.argv[2], "w"), indent=1, ensure_ascii=False)
print({k: len(v) for k, v in snap.items() if isinstance(v, (list, dict))})
for k in levels: print(k, len(levels[k]), levels[k][-1])
