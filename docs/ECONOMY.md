# Economy

What things are worth, what Operation Value counts, how long a first run should take, and when the tabs open. It settles G5, G6 and G7 ([D004–D006](DECISIONS.md)), and owns the run's pacing criteria.

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
| £1,000 | 0:16 | Tier 1 | 0:16 (v0.2's pacing player passes £943 at 15:00 and £1,030 at 16:00) |
| £10,000 | 0:50 | Tier 2 | 0:42 (v0.3) |
| £100,000 | 1:50 | Tier 3 | 1:29 (v0.4; £379k by 1:50, well ahead: see below) |
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

Carolina Reaper is a Tier 6 that **unlocks only after the first Prestige**. Runs after the first get a new goal, and Tier 6 feeds the Cook-Off's £100M+ thresholds. Draft recipes:

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

