# Economy

What things are worth, what Operation Value counts, how long a first run should take, and when the tabs open. It settles G5, G6 and G7 ([D004–D006](DECISIONS.md)), and owns the run's pacing criteria.

## v0.6d: Idle Planet Miner's early flow (D041)

The owner asked for the early game to flow roughly as Idle Planet Miner's does. There, planets 1–4 are on sale from the start at about ×2 each, ore sells raw and is the main early income, telescopes reveal later planets, and every planet upgrade costs (planet price ÷ 20) × 1.3^(level − 1), with small gains a level. Here, until now, the bell plot was the only one until the Tech Tree opened: nothing new to buy between the first line (1:36) and the Poblano Plot (14:13), and plot upgrades cost ×2 a level.

**Changes (D041):**

- **Poblano and Jalapeño Plots are on sale from the start** (once the deck shows), with Bell. Blueprints gate crops from White Vinegar on, as telescopes gate planets. The two old blueprints keep their places in the tree and their ids (so saves load) but become cultivation nodes: E1 and E12 speed their plot up instead of unlocking it.
- **Every crop sells raw** at its value, from its plot's card, as ore does. Sell Raw Peppers stays for the Bell Pepper and the onboarding.
- **Plot upgrades on Idle Planet Miner's curve:** every plot upgrade's first level costs 5% of the plot's price, and each level after it ×1.3. Gains a level are smaller to match. Yield grows by a share of the plot's base yield (a fraction carries to the next harvest); Crop Quality takes more, smaller steps to the same 30% cap.
- **Kept from the brief:** the Blank Button start, the early vat and line (Tier 1's spine), and bottles worth 5× their raw value.
- **Saves (v9):** a v8 save's plot levels convert to the number of new levels with the same effect (rounded up), so no progress is lost.

### Criteria (v0.6d)

| Id | Criterion |
| --- | --- |
| A1 | The Bell, Poblano and Jalapeño Plots are on sale as soon as the deck shows, with no research; every other crop still needs its blueprint. Their prices rise in that order, and the Poblano and Jalapeño Plots each pay for themselves from raw sales, unupgraded, in 5–10 minutes (the Bell Plot is the onboarding's and keeps its price). Idle Planet Miner's ladder keeps payback roughly even as prices climb. **Bar moved after a result, said here:** first set at 1–4 minutes, my guess; Idle Planet Miner's own first planets pay back in about 7–8 minutes (Planet 2: $200 for 0.25 iron a second at $2), and at 1–4 minutes the two plots tripled the early income (the $10,000 band at 9:24, F8 at 16%). |
| A2 | Every plot upgrade's first level costs 5% of the plot's price, and each next level 1.3× the one before, for all three upgrades and every plot. |
| A3 | Every crop sells raw at its value from its plot's card whenever any is held; selling one crop leaves the others alone. |
| A4 | Between the first line and 14:00 the pacing player buys at least two new plots, and the longest wait between new stations (a plot or a slot) in that time is at most 6 minutes (was 12:37, 1:36 to 14:13). |
| A5 | A v8 save loads as v9 with every plot at least as fast, as productive and as likely to double as before. |
| A6 | Every criterion already set still passes: onboarding, factory, economy, tech tree, offline, full run, prestige, second run and layout. |


### Built (v0.6d)

As built, after measuring (each change's reason in D041):

- **The starting plots:** Poblano $800 and Jalapeño $1,900, each 2 crops every 2.4 s, so each pays back raw in 8 and 9½ minutes. At v0.6a's rates (3 every 1.8–2.0 s) they added $9 a second at base and halved tapping's share at 15:00 (F8 10–16%). Every planet in Idle Planet Miner starts at the same base rate too. **Ancho Mash takes 18 s, not 9,** so one base Poblano Plot still feeds one vat (V3); its value is unchanged.
- **Plot upgrades:** 5% of the price, ×1.3 a level (A2). Harvest Speed +3% a level; Yield per Cycle +6% of the base yield a level; Crop Quality 1% a level to 30 levels (`tuning.gd`). Tried and rejected: 5%/5% and 4%/8% (the run 10 minutes fast), 3%/3% (Phantom never made).
- **Forager's Luck drops what the plot grows in one base cycle,** speed levels included. Cheap speed levels meant many small harvests, and its share of the shortest ingredient swung from 6% to 37% between runs; now it holds its 2.25% chance and D025's share (T4: 19%).
- **Savina Pepper Plot $2.0M (was $2.6M) and Moruga Scorpion Plot $5M (was $9.5M):** the run reaches them with less income than before, and saving for them left 379 s (U2) and 511 s (Y4) with nothing bought.
- **Plot cards list cheapest first,** as Idle Planet Miner lists planets, each with a Sell button.
- **The pacing player** ([`engaged_player.gd`](../src/sim/engaged_player.gd)) learned what the new curve needs. Each is a GUESS at an engaged player, not a game rule:
  - It sells raw what its vats don't take.
  - It saves for a starting plot once its raw payback is under 10 minutes, still spending up to 30% of its cash on upgrades meanwhile.
  - On each plot it buys the level that pays back soonest, skipping levels that take over 10 minutes (30 while its vats are short of that crop). Before, it bought the cheapest level forever, and at ×1.3 that wasted the late game on Bell Pepper levels.
  - It keeps the old layout until the new one's plots are bought, and a slot past the layout still waits when research needs its input. Before, the Sweet Heat layout's spare Louisiana line ate the Cayenne Mash research was saving, a stall of over an hour.
  - Its Phantom layout runs two Phantom lines, not three (one Liquid Smoke vat), and lends its Brine vats first, not the Smoke vat.
  - It researches Artisan Decanters after the Oak nodes, not straight after Phantom's blueprint.

### Results (v0.6d)

**A1, A2, A3, A5 PASS; A4 FAIL; A6 PASS apart from A4** (every other suite passes: 39 pacing criteria less A4, second run 4/4).

- **A1:** Poblano $800 pays back in 8:00, Jalapeño $1,900 in 9:30; no blueprint needed; every other crop still needs one. PASS.
- **A2:** every plot and every upgrade: 5%, then ×1.3. PASS.
- **A3:** every crop sells from its card, at its value, alone. PASS (factory and UI suites).
- **A4: FAIL.** Two new plots by 14:00 (Poblano 3:15, Jalapeño 7:14), but 6:22 from the Jalapeño Plot to the Ancho vat at 13:36, against 6:00 (was 12:37). The vat waits on the Tech Tree (Ancho's blueprint). Priced at $1,000 and $2,000 the gap is 5:15, but E3 then fails (87 s with nothing new, against 75) and T4 (22%, against 20%).
- **A5:** a v8 plot with speed 3, yield 2 and quality 10 loads at least as fast and productive, and as likely to double. PASS.
- **A6:** every earlier criterion passes. The curve's bands: $10k at 12:45, $150k at 45:21, $4M at 1:37:36, the sale at 2:01:56, just inside its 2:00 floor. The ladder is on time (U3), from Smoky Ancho at 15:03 to Phantom at 2:38:37, about 14 minutes earlier than before. Tapping adds 27% at 15:00 (F8, was 53%) and 11% at 30:00 (N8, at least 10).

**Thin margins:** the sale (1:56 from its floor), E3 (74 s against 75), N6 (118 s against 120), U5 (276 s against 300). A small change to the early or middle game can tip them.

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
| N5 and U1's second band, by 50:00 | £10,000 | $150,000 (D036; first set at $200,000, ×20) |
| M3 and U1's third band, by 1:50 | £100,000 | $4,000,000 (×40) |
| U1's first band, 0:12–0:18 | £1,000 | $10,000 |
| U1's last band | £1,000,000 between 2:45 and 3:15 | **the $10M sale between 2:00 and 2:30** (owner's choice) |
| U8, a night doesn't hand over the sale | from 1:20, under £1M | **from 1:00**, under $10M (owner's choice: the sale comes earlier) |

**Measurement fix (D035):** a night (P1, P2, U8) now starts with the slots set the way the player runs them, as the tapping minute always did. Before, a night started with whatever the player had lent to research at that tick: at 1:40 two Island Heat lines sat empty all night.

### Results (v0.6c)

**All PASS** (38 criteria, after D036). Every sauce is on time (U3); the curve's bands hold (U1: $10k 15:27, $150k 49:06, $4M 1:44:42, the $10M sale 2:07:58); a night from 1:40 beats two hours' tapping ($114M against $67M) and a night from 1:00 stays under the sale ($9.4M); the longest wait on an ingredient is 209 s (U5).

As first merged (PR #14) three failed, settled by D036:
- **N5:** $200,000 at 53:20. The bar's ×20 was too high (Bistro Verde ×17 and Table Mild ×10 at that point); it's now $150,000, reached at 49:06.
- **M2:** the first Classic Louisiana 51 s after 55:00. Retired; U3 holds the same sauce to its time.
- **U5:** a 402 s wait, a Louisiana line starved of Garlic Paste in the pacing player's Savina Gold layout (one Paste vat for three Louisiana lines). The layout now has two.

**Not bounded:** after Phantom arrives (2:52) the run grows fast: $117M at 3:00 and $757M at 3:15 (31 and 51 credits). Nothing caps late growth now that U1 ends at the sale (W21).

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
| M2 | The first Classic Louisiana by 0:55. Retired by D036: U3 holds it to its time. |
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

