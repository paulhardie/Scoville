# Tech Tree

Brief §4: a web of projects radiating from `[00] Kitchen Table`, researched instantly by turning in crops, mashes and bottles from stock. v0.3 builds the slice Tier 2 needs ([D007](DECISIONS.md)): the root, the East Wing's Tier 2 blueprints, the West Wing's Delivery Van, and the North Wing's first node ([D008](DECISIONS.md)). The rest of the five wings comes in v0.4 and later (G9).

## Rules

- The tab opens at £750 Operation Value ([ECONOMY.md](ECONOMY.md#tab-thresholds-g5-d005)), with `[00] Kitchen Table` already researched (free).
- A node can be researched when every node it hangs from is researched and the stock holds its whole cost. Researching takes the items at once: no timers (brief §4).
- Research is permanent for the run. Prestige resets it (v0.6).
- The web is drawn as wings radiating from the centre, East to the right and West to the left, with each node joined to the ones it needs. Locked nodes show their cost; nodes out of reach are dimmed.

## The v0.3 slice

Costs are GUESSES tuned in the build, paid mostly in Table Mild. Tier 1 bottles are both cash and the tree's currency (brief pillar 3), so every node is a choice between selling and researching.

| Id | Node | Wing | Needs | Cost | Effect |
| --- | --- | --- | --- | --- | --- |
| 00 | Kitchen Table | Centre | — | free | The root |
| N1 | Calloused Thumbs | North | 00 | 10 Table Mild | +2 Bell Peppers a press (brief §4; [D008](DECISIONS.md)) |
| E1 | Crop Blueprint: Jalapeño | East | 00 | 3 Table Mild | Jalapeño Plot can be bought |
| E2 | Culinary Blueprint: Verde Mash | East | E1 | 10 Table Mild | Verde Mash recipe (15 Jalapeño) |
| E3 | Crop Blueprint: White Vinegar | East | E1 | 10 Table Mild + 5 Sweet Pepper Mash | White Vinegar Plot can be bought |
| E4 | Culinary Blueprint: Pickled Brine | East | E3 | 10 Table Mild + 5 Sweet Pepper Mash | Pickled Brine recipe (10 Vinegar + 5 Bell) |
| E5 | Culinary Blueprint: Bistro Verde | East | E2, E4 | 20 Table Mild | Bistro Verde recipe (1 Verde Mash + 1 Pickled Brine, £25) |
| W1 | The Delivery Van | West | 00 | 15 Table Mild | Auto-Sell sliders (below) |

The Tier 2 path (E1–E5) costs 53 Table Mild and 10 Sweet Pepper Mash, about £285 of sales given up. The draft costs (105 and 15) are in git history. Why they came down is in [FACTORY.md](FACTORY.md#what-moved-from-the-draft-each-change-measured).

On screen, the web is drawn on a grid around the Kitchen Table, with each node joined to the ones it needs. Researched nodes and their links are green; nodes that can be researched now are outlined in orange; locked ones are dimmed. Tapping a node shows what it does, its cost against what's in stock, and Research.

## The Delivery Van (brief §3, §4)

- Each sauce gets an Auto-Sell slider from 0% to 100%, in steps of 10%. It starts at 100% for every sauce when the Van is researched.
- When a line finishes a bottle, that share of it is sold at once at full value. The rest goes into stock. A fraction carries over per sauce, so at 30%, 3 bottles in every 10 are sold.
- Sell Batch still sells whatever is in stock, by hand.

## Criteria (v0.3)

The pacing criteria are in [ECONOMY.md](ECONOMY.md#criteria-v03) (N3–N6). Rule checks, all PASS (`tests/tech_tests.gd`):

| Id | Criterion | Result |
| --- | --- | --- |
| R1 | A node can't be researched before its parents, or without its whole cost in stock; a refused research changes nothing. | PASS |
| R2 | Research takes exactly its cost and is permanent across a save and reload. | PASS |
| R3 | Each blueprint opens exactly what it names: the plot can be bought, or the recipe can be assigned. | PASS |
| R4 | At 100% Auto-Sell, a factory earns the same as one sold by hand with Sell Batch, to the penny. At 0% everything goes to stock. At 30%, 3 bottles in 10 are sold. | PASS (10-minute factory runs) |

## v0.4: the rest of the tree

26 more nodes ([D010](DECISIONS.md)). Each costs about 2–4 minutes of whatever it's paid in, at the time the 3-hour curve ([ECONOMY.md](ECONOMY.md#the-first-run-g5-d005)) expects the player to reach it, rising to about 8 on the outer rim. The rates come from v0.3's pacing player at 45–55 minutes: about 14 Bistro Verde, 20 Table Mild, and 15 each of Verde Mash and Pickled Brine a minute. Tier 3's rates are estimates until it's built. Costs are GUESSES, tuned in the build against [ECONOMY.md](ECONOMY.md#criteria-v04)'s M1–M7. Where the build changed a draft cost, the table shows the new one and the draft in brackets.

"Pos" is the node's place in the web, in grid steps from the Kitchen Table (x east, y south). The web now spreads four ways, so on screen it pans in both directions and opens centred on the Kitchen Table.

### North Wing: the Manual Hustle

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| N1 | Calloused Thumbs (v0.3) | 00 | 10 Table Mild | +2 Bell Peppers a press | 0:14 | 0, −1 |
| N2 | Double-Tap Mechanics | N1 | 15 Bistro Verde (was 20) | 10% of presses register twice | 0:28 | 0, −2 |
| N3 | Ergonomic Grip | N2 | 25 Bistro Verde | Holding the button presses it 2 times a second | 0:33 | 0, −3 |
| N4 | Heat Meter (right path) | N3 | 30 Bistro Verde | Heat (below), up to +50% on sales | 0:38 | 1, −3 |
| N5 | Slow Burn | N4 | 15 Classic Louisiana | Heat drains half as fast | 1:10 | 1, −4 |
| N6 | Factory Overclock I (left path) | N3 | 35 Bistro Verde | Each press takes 0.05 s off every running vat and line | 0:45 | −1, −3 |
| N7 | Factory Overclock II | N6 | 15 Classic Louisiana | 0.10 s a press | 1:05 | −1, −4 |
| N8 | Factory Overclock III | N7 | 30 Classic Louisiana | 0.15 s a press | 1:25 | −1, −5 |
| N9 | Automated Piston (capstone) | N5, N8 | 50 Classic Louisiana | Presses the button once a second, always, with every button perk | 1:40 | 0, −5 |

A press from Double-Tap, Ergonomic Grip or the Piston counts as a press for everything: peppers, Heat and Overclock. The Golden Seed Extractor waits for Golden Seeds (v0.7).

### Heat (G10, D011)

- The Heat Meter appears under the Blank Button once N4 is researched.
- Each press adds 5 Heat. Heat drains 12 a second (6 with Slow Burn), and stays between 0 and 100.
- Cash from every sale is multiplied by **1 + 0.5 × Heat/100**: by hand or Auto-Sell, bottles, raw peppers and Overflow Valve sales. Stock is valued as normal.
- What holds it, at steady state:

| Pressing | Gain a second | Drain 12 | Drain 6 (Slow Burn) |
| --- | --- | --- | --- |
| Engaged player, 3 a second | 15 | holds 100% | holds 100% |
| Ergonomic Grip, 2 a second | 10 | falls to 0 | holds 100% |
| Automated Piston, 1 a second | 5 | falls to 0 | falls to 0 |

### East Wing: Tier 3 and the first GMO booster

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| E6 | Crop Blueprint: Cayenne | E5 | 10 Bistro Verde + 5 Verde Mash (was 20 + 10) | Cayenne Plot can be bought | 0:45 | 4, −1 |
| E7 | Crop Blueprint: Garlic | E5 | 10 Bistro Verde + 5 Pickled Brine (was 20 + 10) | Garlic Plot can be bought | 0:46 | 4, 1 |
| E8 | Culinary Blueprint: Roasted Garlic Paste | E7 | 15 Bistro Verde (was 25) | Garlic Paste recipe (20 Garlic) | 0:49 | 5, 1 |
| E9 | Culinary Blueprint: Cayenne Mash | E6 | 15 Bistro Verde + 5 Pickled Brine (was 25 + 10) | Cayenne Mash recipe (25 Cayenne + 1 Pickled Brine) | 0:49 | 5, −1 |
| E10 | Culinary Blueprint: Classic Louisiana | E8, E9 | 20 Bistro Verde (was 30) | Classic Louisiana recipe (1 Cayenne Mash + 1 Garlic Paste, £140) | 0:51 | 6, 0 |
| E11 | Hydroponic Bell Peppers (outer rim) | E10 | 40 Classic Louisiana | The Bell Pepper Plot runs 4× faster | 1:30 | 7, 0 |

Tier 4–6 blueprints and the other GMO boosters come with v0.6.

### South Wing: the factory floor (paid mostly in mash)

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Slot Expansion I | 00 | 40 Sweet Pepper Mash + 20 Verde Mash | +1 vat slot, +1 line slot (caps 4 and 3) | 0:40 | 0, 1 |
| S2 | Slot Expansion II | S1 | 25 Verde Mash + 25 Pickled Brine (was 40 + 40) | +1 vat slot, +1 line slot (caps 5 and 4) | 0:50 | 0, 2 |
| S3 | Heavy Flint Glass | S1 | 40 Verde Mash + 40 Pickled Brine | Packaging 1.5× (D012) | 0:55 | −1, 2 |
| S4 | Foil Neck Wraps | S3 | 30 Cayenne Mash + 30 Garlic Paste | Packaging 2.2× | 1:25 | −1, 3 |
| S5 | Zero-Waste Piping I | S1 | 60 Sweet Pepper Mash + 30 Pickled Brine | Vats need 10% fewer raw crops | 1:00 | 1, 2 |
| S6 | Zero-Waste Piping II | S5 | 25 Cayenne Mash + 25 Garlic Paste | 20% fewer | 1:20 | 1, 3 |
| S7 | Overdrive Turbines (outer rim) | S4, S6 | 60 Cayenne Mash + 60 Garlic Paste | Vats and lines +25% speed, and the Factory Overdrive button | 1:40 | 0, 4 |

- **Zero-Waste Piping:** a vat recipe's raw crop inputs × 0.9 or × 0.8, rounded down, at least 1 (brief §6's Cooperage rule). Mash and bottle inputs are unchanged, and so are item values.
- **Factory Overdrive:** a button on the Processing tab. It doubles every vat and line's speed for 60 s, then can't be used for 15 minutes, counted from when it was pressed.
- **Packaging (D012):** one tier for every line, multiplying every bottle's sale value and its value in Operation Value. Artisan Decanters (3.5×) come with v0.6.

### West Wing: logistics and market

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | The Delivery Van (v0.3) | 00 | 15 Table Mild | Auto-Sell sliders | 0:19 | −1, 0 |
| W2 | Raw Overflow Valve | W1 | 20 Bistro Verde | Crops and mash above their keep amount sell automatically (D014) | 0:35 | −2, 0 |
| W3 | Smart Stockpiling | W2 | 30 Bistro Verde | Pin a node to hold back what it needs | 0:50 | −3, 0 |
| W4 | Market Ticker | W1 | 15 Classic Louisiana | Demand spikes (D015) | 1:05 | −2, 1 |

- **Raw Overflow Valve (D014):** each crop and mash has a keep amount, defaulting to 5 cycles' worth of the researched recipes that use it. The player can change it, or switch the valve off for that item. Anything above it sells at its value, with Heat, once a second.
- **Smart Stockpiling:** one node can be pinned at a time. Until stock meets its cost, Auto-Sell doesn't sell the bottles it needs, and the valve doesn't sell the crops and mash it needs (assumed: the brief names only bottles). Once the stock is met, the sliders and keep amounts work as set again. Researching the node unpins it.
- **Market Ticker (D015):** one spike at a time, ×2 or ×3 (even odds) on a random unlocked sauce for 30 minutes. The first comes 1–5 minutes after research, and later ones 45–75 minutes after the last one started. Shown in the status bar while it runs.

Standard Operating Procedures (needs Prestige) and Night Shift Protocols (needs offline play) wait for v0.6 and v0.5.

### Bridges

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| B1 | Byproduct Recycling (South–East) | S5, E10 | 15 Classic Louisiana + 30 Cayenne Mash | 25% of vat cycles give the lowest-level plot a free level, at most one a minute (D013) | 1:10 | 2, 2 |
| B2 | Franchise Auditors (West–South) | W3, S3 | 20 Classic Louisiana | Stock counts 20% more in Operation Value; sales are unchanged | 1:15 | −2, 2 |

- **Byproduct Recycling (D013):** the "lowest-level plot" is the owned plot with the fewest levels across its three upgrades (ties go in data order). The free level goes on whichever of its upgrades is cheapest.
- Executive Perks (North–West, the Head Chef slot) waits for the Shift Roster (v0.7).

On screen:
- The Heat Meter is a thin bar under the button, with the bonus (`HEAT +36%`) to its left, opposite Sell Batch.
- Holding the button presses it (Ergonomic Grip).
- Processing gets a Factory Overdrive card and a valve card with −/+, Off and Default per item.
- A Tech Tree node has Pin beside Research, and the pinned node is outlined red.
- A Market Ticker spike shows under Operation Value.
- The web pans both ways and opens centred on the Kitchen Table.

### Criteria (v0.4 rules)

All PASS: `tests/button_tests.gd` (R5–R8, H1–H3) and `tests/upgrades_tests.gd` (R9–R18).

| Id | Criterion |
| --- | --- |
| R5 | Double-Tap: over 10,000 presses, 9–11% register twice. A double counts twice for peppers, Heat and Overclock. |
| R6 | Ergonomic Grip: while held, the button presses 2 times a second. On release it stops. |
| R7 | Overclock: each press takes exactly its seconds off every running vat and line's cycle, never below zero, and not off idle ones. |
| R8 | Automated Piston: exactly one press a second with no input, with every perk researched. |
| R9 | Slot Expansion raises the vat and line caps by exactly one each, per node. |
| R10 | Packaging multiplies every bottle's sale value and its value in Operation Value by the tier, for every line. |
| R11 | Zero-Waste Piping: raw crop inputs × 0.9 / × 0.8, rounded down, at least 1. Mash and bottle inputs are unchanged. |
| R12 | Overdrive: +25% vat and line speed. The button doubles it for exactly 60 s, then refuses for 15 minutes from the press. |
| R13 | Overflow Valve: sells only what's above each keep amount, at its value with Heat, and never what the pinned node needs. |
| R14 | Smart Stockpiling: the pinned node's bottles aren't auto-sold until its cost is in stock, then the sliders work as set again. |
| R15 | Market Ticker: one spike at a time, ×2 or ×3 on an unlocked sauce for 30 minutes, starting 45–75 minutes apart. The same seed gives the same spikes. |
| R16 | Byproduct Recycling: 25% of vat cycles give a level, never more than one a minute, to the lowest-level owned plot. |
| R17 | Franchise Auditors: stock counts 20% more in Operation Value; cash from sales is unchanged. |
| R18 | Hydroponic Bell Peppers: the Bell Pepper Plot's cycle is exactly a quarter. |
| H1 | Heat: +5 a press, −12 a second (−6 with Slow Burn), always 0–100, and none before the Heat Meter. |
| H2 | Sale cash × (1 + 0.5 × Heat/100) on every kind of sale. Stock is valued as normal. |
| H3 | The steady states in the table above hold: Piston alone falls to 0; Grip holds 100 only with Slow Burn; 3 presses a second hold 100. |
