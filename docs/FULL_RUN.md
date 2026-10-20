# The full run (v0.6a)

Everything a first run needs to reach the £1,000,000 Prestige line in about 3 hours: the brief's Tiers 4–5, the pepper ladder's extra peppers through Tier 5 ([INGREDIENTS.md](INGREDIENTS.md), D023), the Pantry branch (D026), the rest of the GMO boosters, Slot Expansion III–IV and Artisan Decanters. It also sets the whole curve against D005 with "not before" bounds as well as deadlines (W7).

Prestige itself (Franchise Credits, HQ rooms, Tier 6, Standard Operating Procedures) is v0.6b ([D028](DECISIONS.md)). It needs G8 and G16 from the owner, and a run that actually reaches £1M to test it on.

Status: **built.** The ladder and its sauces are accepted (D023, D029). Stage 1 is in: the data, the fork rule and the Pantry's effects, against V1–V7 below. **Built: every criterion passes** (U1–U9, and every earlier F, N, M, E, P and T criterion; M6 retired by D032) as built in v0.6a. Since then D035 moved money to dollars, U1's last band and U8, and D036 retired M2 and moved N5's bar: the current record is [ECONOMY.md](ECONOMY.md#results-v06c) (38 criteria, all PASS). Numbers marked GUESS get tuned against those; recipes and the brief's bottle values don't.

Since D035 the values here are history: money is dollars at Idle Planet Miner's values, and U1's last band and U8 moved ([ECONOMY.md](ECONOMY.md#v06c-idle-planet-miners-values-in-dollars-d035)).

## The sauce ladder (G17, as assumed: D029)

Every new pepper gets a single-pepper mash and **one sauce that sits between the brief's sauces in value**, so the ladder of sauces climbs about ×2.2 a rung, close to Idle Planet Miner's ore step. Each new sauce is the best thing a line can make until the next one. Values follow D004: a mash is worth 2× its inputs, and a bottle is 5× the raw value inside it, rounded the way the brief's are.

| # | Sauce | Recipe | Raw inside | Value | Line s (GUESS) | £/min at base |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Table Mild (brief) | 1 Sweet Pepper Mash | £1.00 | £5 | 8 | 38 |
| 2 | **Smoky Ancho** | 1 Ancho Mash | £2.10 | £10.50 | 9 | 70 |
| 3 | Bistro Verde (brief) | 1 Verde Mash + 1 Pickled Brine | £5.00 | £25 | 10 | 150 |
| 4 | **Serrano Fire** | 1 Serrano Mash + 1 Verde Mash + 1 Pickled Brine | £12.00 | £60 | 11 | 327 |
| 5 | Classic Louisiana (brief) | 1 Cayenne Mash + 1 Garlic Paste | £28.00 | £140 | 12 | 700 |
| 6 | **Cajun Red** | 1 Tabasco Mash + 2 Pickled Brine + 1 Garlic Paste | £56.50 | £280 | 13 | 1,292 |
| 7 | **Island Heat** | 1 Bonnet Mash + 2 Pickled Brine + 1 Caramelized Glaze | £100.00 | £500 | 14 | 2,143 |
| 8 | Sweet Heat Reserve (brief) | 1 Habanero Mash + 2 Caramelized Glaze + 1 Table Mild | £169.00 | £850 | 14 | 3,643 |
| 9 | **Savina Gold** | 1 Savina Mash + 3 Pickled Brine + 1 Classic Louisiana | £398.00 | £2,000 | 15 | 8,000 |
| 10 | Phantom Smokehouse (brief) | 1 Ghost Mash + 1 Liquid Smoke + 1 Classic Louisiana | £1,041.50 | £5,200 | 16 | 19,500 |

New in bold. Rungs climb ×1.7–2.6 (geometric mean ×2.2).

- **Hotter needs more base (D026):** the new sauces take 0, 1, 2, 2 and 3 Pickled Brine, on top of the brief's Brine in Bistro Verde, Cayenne Mash and Liquid Smoke. Vinegar demand grows all run.
- **Lower tiers stay in use (pillar 3):** Serrano Fire takes Verde Mash, Savina Gold and Phantom take Classic Louisiana, and Sweet Heat takes Table Mild.

### Mashes

| Mash | Recipe | Value | Vat s (GUESS) |
| --- | --- | --- | --- |
| **Ancho Mash** | 15 Poblano | £4.20 | 9 |
| **Serrano Mash** | 20 Serrano | £14 | 11 |
| **Tabasco Mash** | 50 Tabasco | £83 | 13 |
| **Bonnet Mash** | 40 Scotch Bonnet | £92 | 14 |
| Caramelized Glaze (brief) | 30 Cane Sugar + 1 Garlic Paste | £122 | 14 |
| Habanero Mash (brief) | 40 Habanero | £128 | 14 |
| **Savina Mash** | 60 Red Savina | £504 | 15 |
| Liquid Smoke (brief) | 25 Smoked Oak + 2 Pickled Brine | £491 | 16 |
| Ghost Mash (brief) | 60 Ghost Pepper | £1,320 | 16 |

### Stations (GUESS)

Each crop's station is sized to feed one vat of its mash at base speed, as in v0.3–v0.4. Prices rise about ×2 a rung from the built ones.

| Station | Tier | Price | Base |
| --- | --- | --- | --- |
| Poblano Plot | 2 | £40 | 3 every 1.8 s |
| Serrano Plot | 3 | £220 | 4 every 2.2 s |
| Tabasco Plot | 3 | £800 | 10 every 2.6 s |
| Cane Sugar Plot | 4 | £1,500 | 6 every 2.8 s |
| Scotch Bonnet Plot | 4 | £2,000 | 8 every 2.8 s |
| Habanero Plot | 4 | £3,000 | 8 every 2.8 s |
| Red Savina Plot | 5 | £8,000 | 12 every 3.0 s |
| Oak Smokehouse (Smoked Oak, D024) | 5 | £12,000 | 5 every 3.2 s |
| Ghost Pepper Plot | 5 | £15,000 | 12 every 3.2 s |
| Vat slots 6 / 7 (Slot Expansion III / IV) | — | £3,000 / £20,000 | — |
| Line slots 5 / 6 (Slot Expansion III / IV) | — | £5,000 / £40,000 | — |

Ten sauces against at most six lines, and fourteen mashes against seven vats: **which sauces to run is the player's choice**, and the lower ones are still needed as inputs.

Items: Cane Sugar and Smoked Oak are ingredients (`ingredient: true`), so Forager's Luck tops them up.

## The tree (v0.6a nodes)

Costs follow D010: about 2–4 minutes of what a node is paid in, at the time it's expected, and about 8 on the outer rim. East is paid in the previous rung's bottles and mash, South mostly in mash, the Pantry in its own ingredient's mash plus the current top bottle. **Exact costs are set in the build from measured rates.**

### East Wing: blueprints and boosters

| Ids | Nodes | Needs | Expected |
| --- | --- | --- | --- |
| E12–E14 | Poblano (crop), Ancho Mash, Smoky Ancho | E1 | 0:17–0:20 |
| E15–E17 | Serrano, Serrano Mash, Serrano Fire | E5 | 0:30–0:35 |
| E18–E20 | Tabasco, Tabasco Mash, Cajun Red | E10 | 1:00–1:08 |
| E21–E22 | Cane Sugar, Caramelized Glaze | E10 | 1:20–1:25 |
| E23–E25 | Scotch Bonnet, Bonnet Mash, Island Heat | E22 | 1:28–1:35 |
| E26–E28 | Habanero, Habanero Mash, Sweet Heat Reserve | E22 | 1:45–1:55 |
| E29–E31 | Red Savina, Savina Mash, Savina Gold | E28 | 2:10–2:18 |
| E32–E36 | Smoked Oak, Liquid Smoke, Ghost Pepper, Ghost Mash, Phantom Smokehouse | E28 | 2:25–2:40 |
| E37 | Hydroponic Jalapeños (outer rim) | E11, E28 | 2:00 |
| E38 | Hydroponic Cayenne (outer rim) | E37, E31 | 2:30 |

Each chain is crop → mash → sauce, in that order. The GMO boosters make the plot 4× faster, as Hydroponic Bell Peppers does; they're there because Serrano Fire, Savina Gold and Phantom keep pulling on Tiers 2–3.

### The Pantry branch (D026; G18 as assumed)

One track per ingredient, east of the Tech Tree's centre beside the boosters. Each track is three steps, the last an either/or:

| Step | Node | Effect |
| --- | --- | --- |
| 1 | **Booster** | The ingredient's station runs 2× faster |
| 2 | **Concentrate** | Its mash recipe takes 40% less of it, rounded down, at least 1 (Pickled Brine: 6 Vinegar instead of 10) |
| 3a | **Bulk** | Its station yields 2× a harvest |
| 3b | **Reserve** | Every sauce whose recipe takes its mash sells for +25% |

- **The fork:** researching 3a or 3b locks the other for the rest of the run (Prestige unlocks it again). On screen the locked one shows "Chose Bulk" or "Chose Reserve". **Bulk is throughput, Reserve is value:** Reserve pays more per bottle but leaves the ingredient as tight as before.
- **Tracks and timing:** Vinegar (Pickled Brine) 0:55–1:30, Garlic (Garlic Paste) 1:05–1:40, Cane Sugar (Caramelized Glaze) 1:40–2:10, Smoked Oak (Liquid Smoke) 2:35–2:55. That's 16 nodes.
- **Reserve and Brine:** Reserve on Vinegar lifts every sauce that takes Pickled Brine (Bistro Verde, Serrano Fire, Cajun Red, Island Heat, Savina Gold), but not ones that take it only through a mash (Cayenne Mash, Liquid Smoke).

### South Wing

| Id | Node | Needs | Paid in | Effect | Expected |
| --- | --- | --- | --- | --- | --- |
| S8 | Slot Expansion III | S2 | Cayenne Mash + Garlic Paste | +1 vat, +1 line slot (caps 6 and 5) | 1:15 |
| S9 | Slot Expansion IV | S8 | Habanero Mash + Caramelized Glaze | +1 vat, +1 line slot (caps 7 and 6) | 2:00 |
| S10 | Embossed Artisan Decanters (brief) | S4 | Habanero Mash + Caramelized Glaze | Packaging 3.5× (D012) | 2:10 |

That's 46 new nodes in all (E12–E38, 12 Pantry, S8–S10).

## Rule criteria (v0.6a)

All PASS (`tests/full_run_tests.gd`, 66 checks).

| Id | Criterion |
| --- | --- |
| V1 | Every mash is worth 2× its inputs and every sauce 4.9–5.1× the raw value inside (D004). |
| V2 | Each rung of the sauce ladder is ×1.6–2.7 the one below. |
| V3 | Each new station feeds exactly one vat of its mash at base speed. |
| V4 | Booster halves the station's cycle; Concentrate takes 40% off the ingredient in its vat recipe (with Zero-Waste, multiplied, rounded down, at least 1); Bulk doubles a harvest. |
| V5 | Reserve adds 25% to the sale price of every sauce whose recipe takes that mash, adds up when a sauce takes two, and leaves stock value alone. |
| V6 | A fork: after one side, the other can't be researched, stays locked across a save, and other tracks are untouched. |
| V7 | A one-sided fork fails at load; every node can be researched in file order except the sides not taken. |

## Criteria (v0.6a)

Measured over the first 3:15 by the pacing player, extended to run the new content (below). Every earlier criterion stays in force, except where a "not before" bound below takes over.

| Id | Criterion |
| --- | --- |
| U1 | **The curve, with bounds both ways (W7, D005):** Operation Value £1,000 between 0:12 and 0:18; £10,000 between 0:40 and 0:55; £100,000 between 1:35 and 1:55; £1,000,000 between 2:45 and 3:15. |
| U2 | From 1:50 to 3:00, never more than 300 s without a purchase or a research (D033; was 150 s, as M4). |
| U3 | Every sauce on the ladder is made by 3:00, each rung within 20 minutes of its expected time in the tree table. |
| U4 | Lower tiers stay in use (pillar 3): from 2:30 to 2:40, Classic Louisiana and Pickled Brine are each still made (D032; was Table Mild, Verde Mash and Classic Louisiana). |
| U5 | **Ingredients are a bottleneck, not a wall (D026):** from 2:00 to 3:00 at least 30% of vat time runs an ingredient's mash (Pickled Brine, Garlic Paste, Caramelized Glaze, Liquid Smoke), and from 1:00 to 3:00 no slot waits on one for more than 5 minutes (D033; was 10–40% of time waiting). |
| U6 | The forks are real: by 3:00 the pacing player has taken at least two forks, and over the same run, each fork side gives at least a 5% edge in Operation Value at 3:00 against its other side in some track (measured by swapping one fork). |
| U7 | At 2:30, tapping with Heat still adds at least 30% to a minute's earnings (as M5). |
| U8 | **A night doesn't skip the late game (W7):** from 1:20, 8 hours away at 70% leaves Operation Value under £1,000,000 (D032; was from 1:40). P2 (a night beats 2 hours' tapping) still holds. |
| U9 | The catch-up keeps up: X3 (within 2% of tick by tick, 2 hours away) and X7 (D027) still pass at 2:30. |

U1's lower bounds are new: until now the curve only had deadlines, and the run was ahead of it (W7: £100k at 1:24). The build has to slow Tier 3 a little as it adds rungs.

### The pacing player for v0.6a

- Researches the ladder in order, Pantry boosters and concentrates as each ingredient becomes the bottleneck, and the forks Bulk on Vinegar and Garlic, Reserve on Cane Sugar and Smoked Oak (U6 swaps these).
- Runs its lines on the best sauces it can supply, keeping one line each on Table Mild and Classic Louisiana once a recipe needs them as inputs.
- Otherwise as v0.4's.

W4 (the player buys the cheapest upgrade, not the bottleneck) is a risk here: with fourteen mashes, a naive player may starve its own top line. If it does, the build gets a bottleneck-aware buyer before any criterion is retuned.

## Build log (stage 2)

**The pacing player plays the whole ladder.** It runs a layout of slots per rung, lends slots to whatever research is short of (following the recipe chain down), keeps bottles a running recipe takes, and only upgrades stations in use. Five deadlocks in the player were found and fixed on the way; they were the player's, not the game's.

**What changed to tune it (all GUESS numbers, or the owner's calls):**
- **D031 (owner):** slot upgrades priced by what the slot makes.
- **D032 (owner):** U8 from 1:20, U4 narrowed to Classic Louisiana and Pickled Brine, M6 retired. Plus three measurement fixes, said in D032.
- **Blueprints repriced in the rung before them (D010):** Tier 3 (E6–E10) in Serrano Fire, Cane Sugar and Glaze in Cajun Red, Smoked Oak and Liquid Smoke in Savina Gold. The Habanero chain costs 20, 20 + 10 Glaze and 30 Island Heat; Savina 20, 20 + 10 and 30 Sweet Heat; Ghost and Phantom 20, 20 + 10 and 30 Savina Gold.
- **Artisan Decanters** cost 60 Savina Mash + 40 Liquid Smoke and are researched after Phantom: at 2:19 they lifted every bottle held to 3.5× at once.
- **Cash gates Tier 5, not research.** Operation Value counts stock, so saving up an expensive blueprint in top bottles spiked it by hundreds of thousands. Station prices don't. Habanero Plot £20,000, Scotch Bonnet £8,000, Red Savina £60,000, Oak Smokehouse £50,000, Ghost Pepper £70,000; vat 7 £40,000, line 6 £50,000.
- **Savina Gold and Phantom lines** take 18 s (were 15 and 16).
- **The pacing player** researches the Piston after Island Heat (M7) and Artisan Decanters after Phantom.
- **Forager's Luck** is 2.25% a press (was 2.5%), because Garlic now arrives earlier, on a less upgraded station; T1's 2–3% still holds.

### Results (v0.6a)

**All pass** as of v0.6a (history; current record in [ECONOMY.md](ECONOMY.md#results-v06c)): `pacing_tests.gd` (39 criteria) and `offline_tests.gd` (U9). F1–F8, N1–N8, M1–M5 and M7, E1–E6, P1–P2 and T4 all still passed then.

| Id | Result |
| --- | --- |
| U1 | £1k 15:29, £10k 46:28, £100k 1:39:42, £1M 2:50:59 |
| U2 | Longest wait 1:50–3:00: 232 s (at most 300) |
| U3 | Every rung made within 20 minutes of its time: Smoky Ancho 17:38, Bistro Verde 20:18, Serrano Fire 35:55, Classic Louisiana 54:28, Cajun Red 1:24, Island Heat 1:42, then Sweet Heat, Savina Gold and Phantom |
| U4 | Classic Louisiana and Pickled Brine both made at 2:30–2:40 |
| U5 | 65% of vat time on ingredient mash from 2:00; the longest wait on one 249 s |
| U6 | 4 forks taken; swapping one moves Operation Value at 3:00 by up to 21% (Garlic's) |
| U7 | Tapping adds well over 30% at 2:30 |
| U8 | A night from 1:20 leaves Operation Value under £1M |
| U9 | X3 at 2:30: 1.07% off tick by tick (at most 2%); X7 at 2:30: 2.34× (at most 3×) |

**Last changes to get there:** the pacing player's Sweet Heat layout runs one Sweet Heat line on two Glaze vats and two Garlic Paste vats (three lines on two Glaze vats starved one for over 6 minutes); the Ghost Pepper Plot costs £45,000 (a £70,000 plot meant a 346 s wait); and U9 is now measured (it had been written but not checked).

## Assumed

- **G17 (D029):** one mash and one in-between sauce per new pepper, with the recipes above. Accepted by the owner with D023.
- **G18:** the Pantry's three steps and their numbers (2×, −40%, 2× or +25%), and Pickled Brine as the base that grows with heat.
- Sauce names (Smoky Ancho, Serrano Fire, Cajun Red, Island Heat, Savina Gold) and mash names. Placeholders.
- Every station price, cycle and yield marked GUESS; the brief's recipes and bottle values are fixed.
- Moruga Scorpion, Carolina Reaper and Pepper X stay in Tier 6, after the first Prestige (D006), so they're v0.6b.
- No new save version: new stations and slots load as unowned from the data, and a fork is just research. The save's shape is unchanged (v6).
