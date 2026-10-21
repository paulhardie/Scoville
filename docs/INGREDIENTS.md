# Ingredients

The pepper ladder: every crop the game will grow, ordered by real heat, with its value. The owner asked for real hot sauce peppers from the Bell Pepper (0 Scoville) up to Pepper X (the hottest on record), then fictional ones past it, priced with Idle Planet Miner's ore ladder as the reference ([D023](DECISIONS.md), proposed).

Status: **design only.** Nothing here is in `data/` yet. The six peppers the brief already names keep their current values, so Tiers 1–3 as built don't change.

## Proposed (D042): the ladder re-tiered by heat, with generic names only

The owner asked for the peppers to be tiered from [PepperScale's hot pepper list](https://pepperscale.com/hot-pepper-list/) (read 2026-10-21). Where several peppers share a heat band, the agent keeps one, and only generic variety names are used, so nothing on the ladder is someone's trademark. **Proposed, not built.** Each rung keeps its ore value, so pacing shouldn't move.

| # | Pepper | Scoville (SHU) | Value | Change |
| --- | --- | --- | --- | --- |
| 1 | Bell Pepper | 0 | $1 | — |
| 2 | Poblano | 1,000–1,500 | $2 | — |
| 3 | Jalapeño | 2,500–8,000 | $4 | — |
| 4 | Serrano | 10,000–23,000 | $8 | — |
| 5 | Cayenne | 30,000–50,000 | $17 | — |
| 6 | Thai Chili | 50,000–100,000 | $36 | replaces Tabasco (same heat as Cayenne; TABASCO is McIlhenny's trademark) |
| 7 | Scotch Bonnet | 100,000–350,000 | $75 | — (kept over Habanero, same band: the Caribbean sauce pepper, Island Heat's) |
| 8 | Caribbean Red Habanero | 300,000–445,000 | $160 | replaces Habanero, a band hotter |
| 9 | Chocolate Habanero | 425,000–577,000 | $340 | replaces Red Savina (RED SAVINA HABANERO is a registered mark) |
| 10 | Ghost Pepper | 855,000–1,041,427 | $730 | — |
| 11 | Trinidad 7 Pot | 1,000,000–1,200,000 | $1,600 | new |
| 12 | Trinidad Moruga Scorpion | 1,200,000–2,000,000 | $3,500 | up a rung (kept over Carolina Reaper, which overlaps it) |
| 13 | open | over 2,200,000 | $7,800 | Carolina Reaper and Pepper X have trademark questions; recommended: a fictional pepper |

Scoville figures are facts and are used as such; PepperScale's descriptions and its list as a whole are not copied. Building this renames crops, their mashes (Tabasco, Habanero, Savina, Reaper and Pepper X Mash) and Savina Gold, with a save migration like v8's rename (G21).

## Since D035: each pepper is an Idle Planet Miner ore

The owner asked for each pepper to map to an ore and copy its value, in dollars. Peppers take the ores in order of heat, at the wiki's sell prices; the value rule and £ values below are the history before D035.

| # | Pepper | Ore | Value |
| --- | --- | --- | --- |
| 1 | Bell Pepper | Copper | $1 |
| 2 | Poblano | Iron | $2 |
| 3 | Jalapeño | Lead | $4 |
| 4 | Serrano | Silicon | $8 |
| 5 | Cayenne | Aluminium | $17 |
| 6 | Tabasco | Silver | $36 |
| 7 | Scotch Bonnet | Gold | $75 |
| 8 | Habanero | Diamond | $160 |
| 9 | Red Savina | Platinum | $340 |
| 10 | Ghost Pepper | Titanium | $730 |
| 11 | Trinidad Moruga Scorpion | Iridium | $1,600 |
| 12 | Carolina Reaper | Palladium | $3,500 |
| 13 | Pepper X | Osmium | $7,800 |
| 14 | *Lava Lantern* | Rhodium | $17,500 |
| 15 | *Solar Flare* | Inerton | $40,000 |
| 16 | *Capsaicin Crystal* | Quadium | $92,000 |
| 17 | *Brimstone Jolokia* | Scrith | $215,000 |
| 18 | *Supernova Scorpion* | Uru | $510,000 |
| 19 | *Event Horizon* | Vibranium | $1,250,000 |

Eight ores are left for later fictional peppers (Aether $3.2M, Viterium $9M, Xynium $28M, Quolium $90M, Luterium $300M, Wraith $1.1B, Aqualite $4.3B, Opalite $18B). The wiki now lists 27 ores, two more than the 25 counted below.

**Assumed:** the ingredients take the ore of the pepper nearest them in value before D035: White Vinegar Iron ($2), Garlic Aluminium ($17), Cane Sugar Gold ($75), Smoked Oak Titanium ($730).

Source: [Idle Planet Miner wiki, Ores](https://idle-planet-miner.fandom.com/wiki/Ores), read 2026-10-18.

## The value rule

1. **The brief's peppers are anchors.** Bell, Jalapeño, Cayenne, Habanero, Ghost and Reaper keep the values D004 already derives from the brief's bottle prices ([ECONOMY.md](ECONOMY.md#item-values-g6-d004)). Changing them would mean changing the brief's bottles or recipes, and re-pacing Tiers 1–3.
2. **A new real pepper sits on the geometric line between the anchors either side of it.** One pepper between two anchors is their geometric mean; two split the gap into three equal ratios.
3. **Past the last anchor (Reaper), each rung is ×2.15**, rounded to two significant figures. That's Idle Planet Miner's ore step: its ores start Copper $1, Iron $2, Lead $4 and keep roughly doubling up the list.
4. **Hotter is always worth more.** Two peppers with the same real range (Cayenne and Tabasco, Scotch Bonnet and Habanero) are ordered so the brief's pepper keeps its slot.

The value is what one crop sells for and counts for in Operation Value, as now. Mash and bottles follow D004 (mash 2× its inputs, a bottle 5× the raw value inside it).

## The ladder

Scoville figures are the commonly quoted ranges, or the tested average for record holders. Tier is the farm tier it unlocks with; a tier is roughly a decade of heat, the way it's roughly a decade of Operation Value (D005).

| # | Pepper | Scoville (SHU) | Tier | Value | Source of value |
| --- | --- | --- | --- | --- | --- |
| 1 | Bell Pepper | 0 | 1 | £0.10 | Brief (anchor) |
| 2 | Poblano | 1,000–2,000 | 2 | £0.14 | Between Bell and Jalapeño |
| 3 | Jalapeño | 2,500–8,000 | 2 | £0.20 | D004 (anchor) |
| 4 | Serrano | 10,000–23,000 | 3 | £0.35 | Between Jalapeño and Cayenne |
| 5 | Cayenne | 30,000–50,000 | 3 | £0.60 | D004 (anchor) |
| 6 | Tabasco | 30,000–50,000 | 3 | £0.83 | Between Cayenne and Habanero |
| 7 | Scotch Bonnet | 100,000–350,000 | 4 | £1.15 | Between Cayenne and Habanero |
| 8 | Habanero | 100,000–350,000 | 4 | £1.60 | D004 (anchor) |
| 9 | Red Savina | up to 577,000 | 5 | £4.20 | Between Habanero and Ghost |
| 10 | Ghost Pepper (Bhut Jolokia) | 855,000–1,041,000 | 5 | £11.00 | D004 (anchor) |
| 11 | Trinidad Moruga Scorpion | about 1,200,000 (peaks 2,000,000) | 6 | £16.40 | Between Ghost and Reaper |
| 12 | Carolina Reaper | 1,640,000 average | 6 | £24.40 | D004 (anchor) |
| 13 | Pepper X | 2,690,000 average (Guinness, 2023) | 6 | £52 | ×2.15 |
| 14 | *Lava Lantern* | 5,000,000 | 7 | £110 | ×2.15 |
| 15 | *Solar Flare* | 10,000,000 | 7 | £240 | ×2.15 |
| 16 | *Capsaicin Crystal* | 16,000,000 | 8 | £520 | ×2.15 |
| 17 | *Brimstone Jolokia* | 50,000,000 | 8 | £1,100 | ×2.15 |
| 18 | *Supernova Scorpion* | 500,000,000 | 9 | £2,400 | ×2.15 |
| 19 | *Event Horizon* | 16,000,000,000 | 9 | £5,200 | ×2.15 |

Fictional peppers are in italics. The joke runs on real numbers: 16 million SHU is pure capsaicin, the physical ceiling for a chilli, so the Capsaicin Crystal is "grown in a lab", and everything after it is impossible. The Event Horizon's 16 billion is resiniferatoxin's real rating, the hottest substance known.

Tier 6 is after the first Prestige ([D006](DECISIONS.md)), built in v0.6b part 2 with a mash and a sauce for each of its three peppers ([PRESTIGE.md](PRESTIGE.md#part-2-standard-operating-procedures-and-tier-6), D034); Tiers 7–9 are later runs and the Cook-Off's high thresholds.

## Supporting ingredients

The brief's non-pepper ingredients are unchanged. Each comes from its own station, unlocked by a blueprint and run like a pepper plot ([D024](DECISIONS.md)); made ingredients get a station name of their own. The button tops them up through Forager's Luck ([D025](DECISIONS.md)). Each fictional tier will need its own ingredients when its recipes are designed (G17).

| Ingredient | Tier | Value | Station | Source |
| --- | --- | --- | --- | --- |
| White Vinegar | 2 | £0.15 | Vinegar Cask | D004 |
| Garlic | 3 | £0.55 | Garlic Plot | D004 |
| Cane Sugar | 4 | £1.30 | Cane Sugar Plot | D004 |
| Smoked Oak | 5 | £9.50 | Oak Smokehouse | D004 |

### Ingredients as the bottleneck (G18, proposed)

The Pantry branch with forks is accepted ([D026](DECISIONS.md)). Its numbers are assumed in [FULL_RUN.md](FULL_RUN.md#the-pantry-branch-d026-g18-as-assumed).

The brief already makes them one: Pickled Brine (Vinegar) goes into Bistro Verde, Cayenne Mash and Liquid Smoke, and Garlic Paste into Classic Louisiana and Caramelized Glaze. Vinegar is already the binding constraint at 30:00 (W6). The proposal makes that deliberate:

- **Hotter recipes need more base.** The new peppers' mashes (G17) take Pickled Brine, more of it the higher the tier, so a growing operation needs ever more Vinegar. That keeps Tier 2's station relevant all run, which is pillar 3.
- **Relief comes from one Pantry branch in the East Wing,** next to the GMO boosters, not a tree per ingredient. Each ingredient gets a short track: a yield booster (like Hydroponic Bell Peppers), then a "concentrate" node (its recipes need 20% less of it, like Zero-Waste Piping but for that ingredient alone). HQ's Cooperage gives permanent relief across Prestiges.
- **The choice:** each track ends in a fork where only one can be researched per run, such as Aged (that ingredient's mash is worth 1.5×) or Bulk (its station yields 2×). The brief's tree has no either/or nodes, so this would be a new rule.
- **Criterion to set before building:** whenever an ingredient is the bottleneck, something that relieves it (a purchase or a node) is within the player's reach in a few minutes. A bottleneck with no way out is a wall, not a choice.

## How it compares with Idle Planet Miner

- **Idle Planet Miner climbs about ×2.1 per ore.** Bell to Reaper here climbs about ×1.65 per rung (244× over 11 steps), because the brief puts the rest of the growth into recipe sizes: a mash takes 10 Bell Peppers but 80 Reapers. Bottles climb ×5–8 a tier, which is what two or three of Idle Planet Miner's ores cover.
- **Past Pepper X it's the reference curve exactly** (×2.15 a rung), since there's no brief value to keep.
- The steps under the anchors are uneven (×1.4 Bell to Poblano, ×2.6 Habanero to Red Savina). Smoothing them would mean moving the anchors, so re-pricing the brief's bottles and re-pacing the built tiers. Not worth it: the player feels the bottle prices, not the ratio between two crops.

## Assumed

- The pepper list itself (13 real, 6 fictional). Left out as near-duplicates in heat: Pimento, Banana, Anaheim, Fresno, Thai Bird's Eye, Piri Piri, 7 Pot Douglah. Any can be swapped in at the same rule.
- Fictional names and Scoville figures. Placeholders for fun; the owner can rename them.
- Same-range order (Tabasco above Cayenne, Scotch Bonnet below Habanero) so the brief's peppers keep their slots.

## G17: how the new peppers are used

Assumed for v0.6a ([D029](DECISIONS.md)): the recommendation below, with each new sauce priced between the brief's. Recipes and values are in [FULL_RUN.md](FULL_RUN.md#the-sauce-ladder-g17-as-assumed-d029).


Each new pepper needs a use, or its plot is dead weight: nothing in the brief's recipes takes a Poblano, Serrano, Tabasco, Scotch Bonnet, Red Savina, Moruga Scorpion or Pepper X. The recommendation is Idle Planet Miner's ore→bar rule: **every pepper gets its own single-pepper mash, and each new pepper adds one sauce in its tier**, priced by D004. That's 7 more mashes, 7 more sauces and about 14 more blueprints on the East Wing for the real peppers alone, which adds to the first run (13 crops instead of 9 through Tier 5), so it belongs with v0.6's re-pacing of the whole curve (W7). The cheaper alternative, any pepper of a tier filling that tier's mash, adds no recipes but makes the new peppers interchangeable.

## Reference: Idle Planet Miner's ores and planets

From the community wiki's planet table ([Planets](https://idle-planet-miner.fandom.com/wiki/Planets), CC-BY-SA; read from a mirror on 2026-10-17, so it may predate later updates). **25 ores across 70 planets.** 20 planets mine one ore at 100%, 36 mine two and 14 mine three.

| # | Ore | First on | Planets | 100% planet |
| --- | --- | --- | --- | --- |
| 1 | Copper | P1 Balor | 7 | Balor |
| 2 | Iron | P2 Drasta | 6 | none |
| 3 | Lead | P4 Dholen | 6 | Newton |
| 4 | Silica | P7 Widow | 6 | none |
| 5 | Aluminium | P9 Yangtze | 6 | Imir |
| 6 | Silver | P12 Relic | 4 | none |
| 7 | Gold | P14 Batalla | 5 | Pranas |
| 8 | Diamond | P17 Castellus | 6 | none |
| 9 | Platinum | P19 Parnitha | 5 | Theseus |
| 10 | Titanium | P22 Zelene | 5 | none |
| 11 | Iridium | P25 Osun | 5 | Elysta |
| 12 | Palladium | P28 Tikkun | 5 | none |
| 13 | Osmium | P31 Vular | 6 | Xena |
| 14 | Rhodium | P34 Rupert | 5 | Ivyra |
| 15 | Inerton | P37 Utrits | 5 | Zulu |
| 16 | Quadium | P40 Unicae | 6 | Naraka |
| 17 | Scrith | P43 Daedalus | 6 | Zero |
| 18 | Uru | P46 Sotomi | 5 | Muse |
| 19 | Vibranium | P49 Arabis | 6 | Chandra |
| 20 | Aether | P52 Vega | 5 | Singhana |
| 21 | Viterium | P55 Zumbia | 4 | Nyota, Doral |
| 22 | Xynium | P59 Nikara | 5 | Limbo |
| 23 | Quolium | P61 Bob | 6 | Antigone |
| 24 | Luterium | P64 Hecate | 5 | Lavinia |
| 25 | Wraith | P67 Ren | 4 | Leto |

The pattern: a new ore arrives as the minority share of a mixed planet (Iron is 20% of Drasta), grows to the majority on the next one or two, usually gets a pure planet, then lingers as a 10–40% share on later planets. A new ore every 2.8 planets on average. Planets mostly cost ×2–2.5 the last. Six ores (Iron, Silica, Silver, Diamond, Titanium, Palladium) never get a pure planet.

The table has three rows that don't add up (Utrits 130/10, Arabis 110/20, Sterop gives three shares for two ores), so treat those three as unreliable.
