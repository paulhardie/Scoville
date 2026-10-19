# Economy

What things are worth, what Operation Value counts, how long a first run should take, and when the tabs open. It settles G5, G6 and G7 ([D004–D006](DECISIONS.md)), and owns the run's pacing criteria.

## v0.6c: Idle Planet Miner's values in dollars (D035)

**Superseded below:** the £ values and thresholds in the sections after this one are the history up to v0.6b. Since D035:

- **Money is US dollars.**
- **Every crop copies an Idle Planet Miner ore's sell price** ([INGREDIENTS.md](INGREDIENTS.md#the-ladder)): Bell Pepper is Copper ($1), up to Pepper X as Osmium ($7,800). D004's multiples stay: a mash is worth 2× its inputs, a bottle 5× the raw value inside it. So bottles follow from the crops instead of the brief: Table Mild $50, Bistro Verde $425, Classic Louisiana $3,950, Sweet Heat Reserve $58,150, Phantom Smokehouse $330,250, Widowmaker Reserve $3.34M. The ladder climbs ×2.1–3.3 a sauce (V2 is now ×2.0–3.4).
- **Prices follow what pays for them.** Each plot and slot costs its v0.6a price × the value change of the sauce whose sales buy it, then tuned (`data/plots.json`, `data/slots.json`). Upgrade bases and references are ×10 (Tier 1's change), and a station's upgrade scale is (price or value ratio)^0.6 instead of √, so upgrades keep pace with the steeper values.
- **The first sale is Idle Planet Miner's:** $10M Operation Value for 10 Franchise Credits, then its credit table (30 at $100M, 60 at $1B…, [PRESTIGE.md](PRESTIGE.md)).
- **The run keeps v0.6a's pace in time** (the owner's choice): every sauce on time, and the $10M sale arrives at about 2:00–2:15, with pushing on to Phantom paying more credits. It was £1M at about 3:00; the brief's "3 hours to Prestige" (D005) now means 3 hours to the end of the first run's ladder, not to the first chance to sell.
- **Thresholds:** Stage 2 at $100 earned; tabs at $4,000 (Processing), $7,500 (Tech Tree), $150,000 (Shift Roster, provisional) and $10M (HQ, with the sale).
- **Saves (v8):** a v7 or older save's cash, cash earned and best Operation Value are ×10, converted once before any older migration; items keep their counts and are worth more.

### Criteria (v0.6c)

Every v0.2–v0.6b criterion stands on time; money bars convert by the value change of the top sauce at that point, set before measuring:

| Bar | Was | Now |
| --- | --- | --- |
| F7, the factory alone at 15:00 | £18 a minute | $180 a minute |
| N1, N2 (tabs) | £400, £750 | $4,000, $7,500 |
| N5 and U1's second band, by 50:00 | £10,000 | $200,000 (×20, Serrano Fire) |
| M3 and U1's third band, by 1:50 | £100,000 | $4,000,000 (×40) |
| U1's first band, 0:12–0:18 | £1,000 | $10,000 |
| U1's last band | £1,000,000 between 2:45 and 3:15 | **the $10M sale between 2:00 and 2:30** (owner's choice) |
| U8, a night doesn't hand over the sale | from 1:20, under £1M | **from 1:00**, under $10M (owner's choice: the sale comes earlier) |

**Measurement fix (D035):** a night (P1, P2, U8) now starts with the slots set the way the player runs them, as the tapping minute always did. Before, a night started with whatever the player had lent to research at that tick: at 1:40 two Island Heat lines sat empty all night.

### Results (v0.6c)

36 of 39 PASS. Every sauce is on time (U3), the curve's bands hold (U1: $10k 15:27, $200k 53:20, $4M 1:44:42, $10M 2:07:58), a night from 1:40 beats two hours' tapping ($114M against $67M) and a night from 1:00 stays under the sale ($9.4M).

**FAIL:**
- **N5:** $200,000 at 53:20, not by 50:00 ($162,583 at 50:00). The bar's ×20 was too high: at 50:00 most money still comes from Bistro Verde (×17) and Table Mild (×10). Recommend $150,000, which it passes (W18).
- **M2:** the first Classic Louisiana at 55:51, 51 s after 55:00. Its line is bought at 50:40; the 5 minutes after are the Brine and Paste chain filling, not cash. U3 (the same sauce within 20 minutes of 50:00) passes (W19).
- **U5:** one slot waited 402 s (at most 300) on an ingredient: the pacing player lends a line to Sweet Heat for research at 2:45 with no Glaze vat in its Savina Gold layout. The ingredient share holds (65% of vat time) (W20).

**Not bounded:** after Phantom arrives (2:52) the run grows fast: $110M at 3:00, $723M at 3:15 (30 and 51 credits). Nothing caps late growth now that U1 ends at the sale (W21).

## Item values (G6, D004)

**A bottle is worth 5× the raw value inside it.** The brief's Tier 1 already works this way: 10 Bell Peppers sell raw for £1.00, and bottled for £5.00. Any lower-tier bottle used as an input counts at its full sale value. Applied to the brief's recipes and bottle values, that fixes every raw crop's price:

| Tier | Raw crops (each) | Bottle (brief) | Raw value in a bottle | Multiple |
| --- | --- | --- | --- | --- |
| 1 | Bell Pepper £0.10 | Table Mild £5 | £1.00 | 5.0× |
| 2 | Jalapeño £0.20, White Vinegar £0.15 | Bistro Verde £25 | £5.00 | 5.0× |
| 3 | Cayenne £0.60, Garlic £0.55 | Classic Louisiana £140 | £28.00 | 5.0× |
| 4 | Habanero £1.60, Cane Sugar £1.30 | Sweet Heat Reserve £850 | £169.00 | 5.0× |
| 5 | Ghost Pepper £11.00, Smoked Oak £9.50 | Phantom Smokehouse £5,200 | £1,041.50 | 5.0× |
| 6 | Carolina Reaper £24.40 | Widowmaker Reserve £40,000 | £8,002.00 | 5.0× |

**Mash is worth 2× its inputs** (inputs at their own values):

| Mash | Inputs | Value |
| --- | --- | --- |
| Sweet Pepper Mash | 10 Bell | £2.00 |
| Pickled Brine | 10 Vinegar + 5 Bell | £4.00 |
| Verde Mash | 15 Jalapeño | £6.00 |
| Roasted Garlic Paste | 20 Garlic | £22.00 |
| Cayenne Mash | 25 Cayenne + 1 Pickled Brine | £38.00 |
| Caramelized Glaze | 30 Sugar + 1 Garlic Paste | £122.00 |
| Habanero Mash | 40 Habanero | £128.00 |
| Liquid Smoke | 25 Oak + 2 Pickled Brine | £491.00 |
| Ghost Mash | 60 Ghost Pepper | £1,320.00 |
| Reaper Mash | 80 Carolina Reaper | £3,904.00 |

These values are what Operation Value counts and what the Raw Overflow Valve (v0.4) sells at. Bell Peppers are the only crop sold by hand (Sell Raw Peppers); the others are only for processing until the valve.

## Operation Value (brief §6)

**Operation Value = cash earned this run + every item in stock at the values above.** From v0.4, bottles are valued with the packaging tier (D012), and Franchise Auditors add 20% to stock (not to cash). Cash spent still counts, because it was earned. Items in stations mid-cycle don't count until they're out. It shows under Cash in the status bar from Stage 3.

## The first run (G5, D005)

**Target: about 3 hours of play from a fresh game to £1,000,000 Operation Value (Prestige)**, with idle time counted as play. Each decade has a checkpoint, and each tier carries the run through about one decade:

| Operation Value | By | Carried by | Measured |
| --- | --- | --- | --- |
| £1,000 | 0:16 | Tier 1 | 0:14 (v0.5.1; v0.2 had 0:16) |
| £10,000 | 0:50 | Tier 2 | 0:43 (v0.5.1) |
| £100,000 | 1:50 | Tier 3 | 1:24 (v0.5.1; £454k by 1:50, well ahead: W7) |
| £1,000,000 | 3:00 | Tiers 4–5 | v0.6 |

Without a new tier, Operation Value grows in a straight line: Tier 1 alone adds about £100 a minute and reaches only £2,400 at 30:00. Each tier has to arrive in time to bend the curve.

## Tab thresholds (G5, D005)

All reveals happen in the first 15 minutes, as the brief's first pillar asks. These are measured against the v0.2 pacing player's curve:

| Unlock | Operation Value | v0.2 pacing player | Notes |
| --- | --- | --- | --- |
| Stage 3: the nav bar, plus the **Processing** tab | £400 | 7:59 | The vats and lines move from Farms to Processing |
| **Tech Tree** tab | £750 | 12:42 | Opens on the free `[00] Kitchen Table` node |
| **Shift Roster** tab | £10,000 (provisional) | 42:18 | Set by the 45–60 minute target. v0.3 reaches £10,000 a little early; £14,000 would land at 50:00. Settle in v0.7, when the tab is built and opens with one free Recruitment Pack |
| **HQ Facilities** tab | £1,000,000 | 3:00 target | Brief §2, §6 |

A locked tab shows `[ ? ]`. Tapping it shows the Operation Value it unlocks at (assumed: the brief says only that the icons are locked).

## Tier 6 (G7, D006)

Carolina Reaper is a Tier 6 that **unlocks only after the first Prestige**. Runs after the first get a new goal, and Tier 6 feeds the Cook-Off's £100M+ thresholds. Built in v0.6b part 2 with Moruga Scorpion and Pepper X either side of it ([PRESTIGE.md](PRESTIGE.md#part-2-standard-operating-procedures-and-tier-6), D034):

- **Reaper Mash:** 80 Carolina Reaper.
- **Widowmaker Reserve:** 1 Reaper Mash + 1 Phantom Smokehouse + 1 Sweet Heat Reserve, worth £40,000.

## Criteria (v0.3)

Measured by the pacing player (`tests/pacing_tests.gd`, CI on every push) over the first 50 minutes. v0.2's F1–F8 stay in force.

The pacing player for v0.3:
- Taps 3 times a second.
- Researches in a fixed order (Jalapeño, Calloused Thumbs, Verde, Vinegar, Brine, Bistro Verde, Van). While research needs bottles it keeps Table Mild back: by not selling it, or at a 50% Auto-Sell once it has the Van. When research needs mash, it switches the Table Mild line off until there's enough.
- Buys Tier 2's stations in order as each is unlocked, saving for the next.
- Otherwise buys the cheapest upgrade.

| Id | Criterion |
| --- | --- |
| N1 | Stage 3 (Operation Value £400) by 9:00. |
| N2 | The Tech Tree tab (£750) by 14:00. |
| N3 | The Jalapeño blueprint researched by 20:00. |
| N4 | The first Bistro Verde bottle by 30:00. |
| N5 | Operation Value £10,000 by 50:00 (the 3-hour curve's checkpoint). |
| N6 | From 15:00 to 50:00, never more than 120 s without a purchase or a research. |
| N7 | Tier 1 stays in use (brief pillar 3): from 40:00 to 50:00 the Table Mild line runs at least half the time, and Bell Peppers still go into Pickled Brine. |
| N8 | At 30:00, tapping still adds at least 10% to a minute's earnings. |

N8 is lower than v0.2's F8 (25%) on purpose. Until the North Wing (v0.4) evolves the button, a tap is one Bell Pepper, and Tier 2's earnings dwarf it. v0.4's criteria raise the bar again.

### Results (v0.3)

All pass. "Waits" count purchases and research.

| Id | Target | Measured |
| --- | --- | --- |
| N1 | Stage 3 by 9:00 | 7:59 |
| N2 | Tech Tree by 14:00 | 12:42 |
| N3 | Jalapeño blueprint by 20:00 | 12:53 |
| N4 | First Bistro Verde by 30:00 | 21:39 |
| N5 | £10,000 by 50:00 | 42:18 (£14,037 at 50:00; £1,000 at 16:15) |
| N6 | No wait over 120 s, 15:00–50:00 | longest 104 s |
| N7 | Table Mild line busy ≥ 50%, Brine made, 40:00–50:00 | 100%, 146 Pickled Brine |
| N8 | Tapping adds ≥ 10% at 30:00 | +17% |

v0.2's criteria at 15:00 still pass: F6's longest wait is 85 s (of 90), F7 £84.60 a minute, F8 +64%.

Timeline: research starts at 12:53 and Tier 2 is fully built by 21:29, with the first Bistro Verde at 21:39. After that, an upgrade comes every 35–104 s.

Close to the edge: F6 (85 s of 90) and N6 (104 s of 120).

## Criteria (v0.4)

Measured by the pacing player over the first 110 minutes. v0.2's F1–F8 and v0.3's N1–N8 stay in force.

| Id | Criterion |
| --- | --- |
| M1 | The first Tier 3 blueprint by 0:48. |
| M2 | The first Classic Louisiana by 0:55. |
| M3 | Operation Value £100,000 by 1:50 (the 3-hour curve's checkpoint). |
| M4 | From 0:50 to 1:50, never more than 150 s without a purchase or a research. |
| M5 | At 1:30, tapping (with Heat) adds at least 30% to a minute's earnings. |
| M6 | Tiers 1 and 2 stay in use (brief pillar 3): from 1:30 to 1:40 the Table Mild and Bistro Verde lines are each busy at least half the time. |
| M7 | The button evolves within the run: the Automated Piston is researched by 1:50. |

For v0.4 the pacing player (`src/sim/engaged_player.gd`):
- **Researches in this order:** the Tier 2 path and Van as before, then Double-Tap, Slot Expansion I, the five Tier 3 blueprints with Slot Expansion II, then Ergonomic Grip, Heat Meter, Overflow Valve, Overclock I, Smart Stockpiling, Flint Glass, Zero-Waste I, Overclock II, Market Ticker, Slow Burn, Byproduct Recycling, Franchise Auditors, Zero-Waste II, Overclock III, Automated Piston, Foil Wraps, Hydroponic Bell, Overdrive Turbines.
- **Holds back what the next node needs.** Once it has Smart Stockpiling it pins the node. Before that, it turns Auto-Sell down to 50% for the bottles and raises the valve's keep amounts for the crops and mash.
- **Switches off a slot that would eat a needed item it's short of,** unless the node also needs that slot's output.
- Buys Tier 3's stations in order as each is unlocked, including a second Classic Louisiana line.
- Taps 3 times a second, which keeps Heat full.
- Presses Factory Overdrive whenever it's ready.
- Otherwise buys the cheapest upgrade, Crop Quality included.

### Results (v0.4)

All 23 criteria pass (F1–F8, N1–N8, M1–M7).

| Id | Target | Measured |
| --- | --- | --- |
| M1 | First Tier 3 blueprint by 48:00 | 28:54 |
| M2 | First Classic Louisiana by 55:00 | 46:09 |
| M3 | £100,000 by 1:50 | 1:29:32 (£378,814 at 1:50) |
| M4 | No wait over 150 s, 50:00–1:50 | longest 81 s |
| M5 | Tapping adds ≥ 30% at 1:30 | +69% (£16,696 against £9,907 a minute) |
| M6 | Table Mild and Bistro Verde lines each busy ≥ 50%, 1:30–1:40 | 100% and 54% |
| M7 | Automated Piston by 1:50 | 1:37:00 |

v0.3's N criteria moved a little, with Tier 3 research now spending Bistro Verde before 50:00:
- N5 (£10,000) went from 42:18 to 47:35.
- N6's longest wait went from 104 s to 115 s, of 120.

**The run is now well ahead of the 3-hour curve.** £100,000 comes at 1:29, not 1:50, and Operation Value is £379k by 1:50. The criteria are "by" deadlines, so nothing fails. But with Tiers 4–5 still to come (v0.6), £1M would land long before 3:00. Most of the late surge comes from multipliers stacking from about 1:20:
- Heat: up to ×1.5
- Flint Glass, then Foil Wraps: ×1.5, then ×2.2
- Overclock
- two Classic Louisiana lines
- a ×3 Market spike

This is the open question in [HANDOVER.md](HANDOVER.md) and backlog row W7.

