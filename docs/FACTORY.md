# Factory (v0.2 Operation Deck)

**Names since D042** ([INGREDIENTS.md](INGREDIENTS.md#the-ladder-since-d042)): Tabasco is Thai Chili, Habanero is Caribbean Red Habanero, Red Savina is Chocolate Habanero (Savina Gold is Cocoa Loco), Carolina Reaper is Alabama Grim, Pepper X is Pepper Y, and Cane Sugar is Pineapple (Caramelized Glaze is Charred Pineapple Glaze). This doc keeps the names it was written with.

Brief §2 Stage 2 and §3 Tier 1: at £10 the button moves into the upper 35% of the screen and the Farms deck slides up from below. There the player buys the Tier 1 spine: a Bell Pepper Plot, a Sweet Pepper Mash vat and a Table Mild bottling line.

The rules are in `src/core/game.gd`, the numbers in `src/core/tuning.gd`, and the screen in `src/ui/main.gd`. The pacing criteria are measured by `tests/pacing_tests.gd`.

## Rules

- **Plot** (Column 1): every cycle it harvests Bell Peppers into stock, and it never stops.
- **Vat** (Column 2): when idle and the stock has 10 Bell Peppers, it takes them and starts a cycle. When the cycle ends it puts 1 Sweet Pepper Mash into stock and starts again if it can.
- **Line** (Column 3): the same, taking 1 Mash and putting 1 Table Mild bottle into stock (£5).
- **Starter Crate**: buying the line comes with a crate of 50 bottles. While it lasts, the line runs 10× faster, so mash that built up while saving for the line gets bottled almost at once. Each bottle made uses one from the crate.
- **Sell Batch** sells every Table Mild held at £5 each. On screen it sits beside the compressed button, so it's always in reach without scrolling the deck. Sell Raw Peppers still sells every Bell Pepper held, vat or no vat; whether to keep peppers for the vat is the player's call.
- **Upgrades** are bought with cash (the brief's "cash upgrade knobs"). A speed level shortens the cycle: cycle = base ÷ (1 + step × level).
- The simulation runs on a fixed 0.1 s tick, so it's deterministic.

## Assumed where the brief is open

- **G3, Stage 2's "£10 Cash":** before Stage 2 there's nothing to spend cash on, so cash held and cash earned are always equal. The trigger uses cash earned, so it can't be undone. G3 is closed.
- **G4:** every number in the tables below is a GUESS aimed at the criteria, for the owner to review.
- Everything sits in the Farms tab in v0.2, since it's the only tab. The line appears once the vat is bought. The vat and line move to the Processing tab when tabs arrive in v0.3.
- Left for later: Crop Quality Chance (its effect isn't defined, G4), parallel vat and line slots (they need the Tech Tree's Slot Expansion), and packaging tiers (Tech Tree).
- The pacing player is a GUESS at an engaged first-time player: 3 taps a second, a decision every second (below).

## Numbers (draft for review)

All GUESSES (G4) except the recipes and the £5 bottle (brief §3). They're in `src/core/tuning.gd`.

**Since D041** plot upgrades are on Idle Planet Miner's curve: every level costs 5% of the plot's price × 1.3^level, Harvest Speed adds 3% a level and Yield per Cycle 6% of the plot's base yield a level (fractions carry), see [ECONOMY.md](ECONOMY.md#v06d-idle-planet-miners-early-flow-d041). The table is v0.2's.

| Station | Price | Base | Speed upgrade | Other |
| --- | --- | --- | --- | --- |
| Bell Pepper Plot | £5 since v0.5.1 (was £10) | 1 pepper every 1.0 s since v0.5.1 (was 2.0 s) | +15% a level; £15 × 2.0^lv | Yield per Cycle: +1 pepper a level; £40 × 2.0^lv |
| Sweet Pepper Mash vat | £15 since v0.5.1 (was £25) | 10 peppers → 1 mash in 8.0 s | +25% a level; £30 × 1.45^lv | — |
| Table Mild line | £10 since v0.5.1 (was £35) | 1 mash → 1 bottle (£5) in 8.0 s | +25% a level; £45 × 1.5^lv | Starter Crate: 50 bottles at 10× (0.8 s each) |

What the numbers are doing:
- Bottling is worth 5× selling raw: 10 peppers raw make £1.00, bottled £5.00.
- The plot is cheap to start but its upgrades double in price, so it shouldn't outgrow the vat. Peppers you tap then still feed the vat instead of only being sold raw, which is what keeps the button worth pressing (F8).
- The vat and line start evenly matched (8 s each), and their upgrades rise more slowly so there's always something to buy (F6).

## Criteria (v0.2)

Measured with the pacing player (`tests/pacing_tests.gd`) over the first 15 minutes of a fresh game.

| Id | Criterion |
| --- | --- |
| F1 | Stage 1 (the status bar) by 0:15. |
| F2 | Stage 2 (the deck) by 1:30. |
| F3 | The vat is bought by 3:00. |
| F4 | The line is bought by 5:00. |
| F5 | The first Sell Batch by 5:30. |
| F6 | From buying the line to 15:00, never more than 90 s without a purchase. |
| F7 | At 15:00, the factory alone (no taps) earns at least £18 a minute, which is what tapping alone earns selling raw. |
| F8 | At 15:00, tapping still adds at least 25% to a minute's earnings (the button never goes obsolete). |

The pacing player: taps 3 times a second. Once a second it sells every bottle; sells raw peppers (all of them before the vat; once the vat runs, all of them whenever more than 50 are waiting); buys the plot, then the vat, then the line as soon as each can be afforded; and then buys the cheapest upgrade it can afford.

## Results

Measured 2026-10-16 by `tests/pacing_tests.gd` (CI runs it on every push): **all eight pass**.

| Id | Target | Measured |
| --- | --- | --- |
| F1 | Stage 1 by 0:15 | 0:06.7 |
| F2 | Stage 2 by 1:30 | 0:34 |
| F3 | Vat by 3:00 | 1:45 |
| F4 | Line by 5:00 | 4:32 |
| F5 | First Sell Batch by 5:30 | 4:33 |
| F6 | No wait over 90 s after the line | longest 87 s |
| F7 | Factory alone ≥ £18/min at 15:00 | £70.00/min |
| F8 | Tapping adds ≥ 25% at 15:00 | +31% (£91.80 vs £70.00) |

The pacing player's 15 minutes: plot 0:34, vat 1:45, line 4:32 (the Starter Crate bottles the mash that built up while saving for it), then an upgrade every 40–87 s. At 15:00 it has earned £911 and sold 135 bottles: plot speed 4 and yield 2, vat speed 4, line speed 3.

Close to the edge: F6 (87 s of 90) and F4 (28 s to spare). Raising any upgrade's price or growth is likely to break F6.

How the draft got here from the first guesses (each change measured):
1. Plot yield was too cheap (£20 × 1.75^lv). The plot swamped the vat, so taps were only worth selling raw: F8 measured 23%. Fix: plot upgrades made dearer and steeper.
2. The line at £40 nearly missed F4 (4:56). Fix: £35.
3. Vat and line upgrades grew too fast for the income, leaving waits of 92–100 s (F6). Fix: lower base costs and slower growth, and the line's cycle cut from 10 s to 8 s to match the vat.
4. Bigger vat and line speed steps (+35%) were tried and dropped: the line became the bottleneck and F8 fell to 13%.

## v0.3: slots, recipes and Tier 2

Brief §2 Stage 3 and §3: the Processing tab takes over the vats and lines, which become slots that each run a chosen recipe. Tier 2's crops and recipes arrive through the Tech Tree's blueprints ([TECH_TREE.md](TECH_TREE.md)). Values are in [ECONOMY.md](ECONOMY.md).

### Rules

- **Farms tab:** one plot per crop. A crop's plot can be bought once its Crop Blueprint is researched (Bell Pepper needs none).
- **Processing tab:** vat slots and line slots. Each slot runs one recipe, picked from the recipes researched so far, or is switched off. It can be switched at any time. Switching hands any inputs taken for the current cycle back to stock and drops that cycle's progress.
- **Slot caps in v0.3 (G15):** 3 vat slots and 2 line slots, bought with cash. The first vat comes with the deck and the first line once a vat is owned, as in v0.2. More of either are offered once the Processing tab is open. The Tech Tree's Slot Expansion raises the caps in v0.4.
- **Recipes** set the inputs, output and base cycle time. A slot's speed level divides it, as in v0.2.
- **The Starter Crate** comes with the first line only.
- **Upgrades** keep v0.2's curves, scaled by **√(price ÷ the first of its kind)**. A plot compares with the Bell Pepper Plot (£10); a slot with vat slot 1 (£25) or line slot 1 (£35). Tier 1's prices are unchanged.
- **Data:** items, recipes, plots, slots and tech nodes are in `data/*.json`, loaded and checked only by `src/core/data_loader.gd`. Bad data fails at load with a message naming the file and row.
- **Saves:** version 3, with the run apart from the account. A v2 save migrates with its vat as vat slot 1 on Sweet Pepper Mash and its line as line slot 1 on Table Mild, keeping levels, progress and crate.

### Numbers (tuned in the build, G4)

Recipes and bottle values are the brief's; everything else is a GUESS tuned against [ECONOMY.md](ECONOMY.md#criteria-v03)'s N1–N8.

| What | Price | Base |
| --- | --- | --- |
| Jalapeño Plot | £100 | 3 Jalapeños every 2.0 s |
| Vinegar Cask (was White Vinegar Plot, D024) | £120 | 2 Vinegar every 2.0 s |
| Vat slots 1 / 2 / 3 | £25 / £100 / £120 | — |
| Line slots 1 / 2 | £35 / £120 | — |
| Sweet Pepper Mash (10 Bell) | — | 8 s (v0.2) |
| Pickled Brine (10 Vinegar + 5 Bell) | — | 10 s |
| Verde Mash (15 Jalapeño) | — | 10 s |
| Table Mild (1 Sweet Pepper Mash), £5 | — | 8 s (v0.2) |
| Bistro Verde (1 Verde Mash + 1 Pickled Brine), £25 | — | 10 s |

The Tier 2 plots are sized to feed one Verde vat, one Brine vat and the Bistro Verde line at their base speeds: 1.5 Jalapeños and 1 Vinegar a second against 1.5 and 1 needed.

### What moved from the draft (each change measured)

As the draft warned, it missed N4. It also missed N5 and N6. In order:

1. **The Jalapeño Plot starved Tier 2:** at 1 every 2.5 s, one Verde Mash took 37 s. It now gives 3 every 2.0 s, and the Vinegar Plot 2 every 2.0 s. Verde Mash and Bistro Verde went from 12 s to 10 s to match.
2. **Building Tier 2 meant 3–7-minute waits** (N6 measured 421 s) on Tier 1's £65 a minute. Prices came down: plots £150/£200 → £100/£120, slots vat £150/£400 → £100/£120, line £500 → £120.
3. **Research ate too many bottles.** The Tier 2 path fell from 105 to 53 Table Mild, and from 15 to 10 Sweet Pepper Mash. See TECH_TREE.md.
4. **Tier 2 upgrades priced at the full price ratio** (×10–×20 the Tier 1 curve) were never worth buying. They now scale by √ of it (×2–×4).
5. **The button faded:** with Tier 2, tapping added only 6% at 30:00 (N8), and F8 fell to 22%. A tap was still one Bell Pepper. The fix is the brief's own first North Wing node, Calloused Thumbs (+2 a tap), added to the slice ([D008](DECISIONS.md)). This is the one change that's a feature, not a number.
6. **Measurement fix:** "a minute's earnings" (F7, F8, N8) now counts the rise in Operation Value. Counting cash alone credited bottles saved up for research and sold in that minute.

### Results (v0.3 rules)

All pass (`tests/factory_tests.gd`, `tests/tech_tests.gd`):

| Id | Criterion | Result |
| --- | --- | --- |
| S1 | A slot runs only a researched recipe, takes exactly its inputs, gives exactly its output after its cycle | PASS |
| S2 | Switching a recipe returns the inputs and loses only that cycle | PASS |
| S3 | No more slots than the cap | PASS |
| S4 | A v2 save migrates and goes on producing as before | PASS (fixture checked against v2's plot rate) |
| S5 | Operation Value = cash earned + stock at its values, after every action and tick | PASS |
| S6 | Bad data fails at load naming the file and row | PASS (seven kinds of bad data) |

## v0.4: Tier 3 and the factory upgrades

Tier 3 arrives through the East Wing; the South Wing raises slot caps and adds packaging, Zero-Waste Piping and Overdrive ([TECH_TREE.md](TECH_TREE.md#v04-the-rest-of-the-tree)). Values are [ECONOMY.md](ECONOMY.md)'s.

### Numbers (tuned in the build)

Recipes and the £140 bottle are the brief's. The rest is GUESSES tuned against [ECONOMY.md](ECONOMY.md#criteria-v04)'s M1–M7, with the drafts in brackets.

| What | Price | Base |
| --- | --- | --- |
| Cayenne Plot | £400 (was £600) | 5 Cayenne every 2.4 s |
| Garlic Plot | £450 (was £700) | 4 Garlic every 2.4 s |
| Vat slots 4 / 5 (after S1 / S2) | £300 / £500 (were £500 / £800) | — |
| Line slots 3 / 4 (after S1 / S2) | £400 / £1,200 (were £1,000 / £2,500) | — |
| Roasted Garlic Paste (20 Garlic) | — | 12 s |
| Cayenne Mash (25 Cayenne + 1 Pickled Brine) | — | 12 s |
| Classic Louisiana (1 Cayenne Mash + 1 Garlic Paste), £140 | — | 12 s |

- The plots are sized to feed one Cayenne Mash vat and one Garlic Paste vat at base speed: 2.08 Cayenne and 1.67 Garlic a second, against 2.08 and 1.67 needed.
- A Classic Louisiana line at base makes £700 a minute, against Bistro Verde's £150.
- Cayenne Mash also needs Pickled Brine, so Brine is shared between Tier 2 and Tier 3. A second Brine vat, or speed on the first, is part of the build-out. That's the brief's "lower tiers stay relevant".
- A full Tier 3 setup (two plots, vat slots 4 and 5, line slot 3) costs £2,050 in cash (the draft's was £3,600). At v0.3's £450–500 a minute that's about 4–5 minutes after the blueprints.

### Crop Quality (D016)

**Since D041:** 1% a level to 30 levels (the same 30% cap), priced like every plot upgrade at 5% of the plot's price × 1.3^level ([ECONOMY.md](ECONOMY.md#v06d-idle-planet-miners-early-flow-d041)). As first built: a third plot upgrade beside Harvest Speed and Yield. Each level adds a 3% chance that a harvest gives double, capped at 10 levels (30%). Its price is £30 × 2^level × √(price ÷ £10), like the others.

### Saves

Version 4 adds:
- research-driven state: the pin, keep amounts, Overdrive timers and Market Ticker spikes;
- Heat;
- each plot's Crop Quality level;
- the random stream's state (D017).

A v3 save migrates with Heat at 0, quality levels at 0, no pin, default keep amounts, and a stream seeded from the save's own figures, so the same save always migrates the same way.

### Criteria (v0.4 factory rules)

All PASS (`tests/factory_tests.gd`, `tests/upgrades_tests.gd`). S9 uses a v0.3 save fixture, and S10 runs 30 minutes with every chance in play, saved and reloaded halfway.

| Id | Criterion |
| --- | --- |
| S7 | Tier 3's recipes take exactly their inputs and give exactly their output, Cayenne Mash using Pickled Brine. |
| S8 | Crop Quality: 3% a level up to 30%; over 10,000 harvests the doubled share is within 1 point of it. |
| S9 | A v3 save migrates to v4 and goes on producing exactly what it did. |
| S10 | The same seed and the same inputs give the same game, and a save mid-game plays on identically, chances included (D017). |

## v0.5.1: the early-game pass

**Why.** On a phone (W1), the owner found the start "incredibly slow". The F criteria were deadlines measured by a player tapping 3 times a second without a break, so a slow-feeling start still passed. With a realistic player, the casual player below:
- the deck came at 1:06 and the vat at 3:10;
- then **nothing new happened for 7½ minutes** until the line at 10:40, while the vat turned peppers into mash nothing could use.

### The casual player

A GUESS at a phone player (`Player.casual()` in `src/sim/engaged_player.gd`):
- taps 2 times a second in 45-second bursts with 15-second rests (1.5 a second on average);
- looks at the game every 2 seconds.

Otherwise it plays like the pacing player. Both are measured over the first 30 minutes.

### Criteria (v0.5.1)

"Something new" is a purchase, a research or a reveal (the deck, the nav bar, the Tech Tree).

| Id | Criterion | Measured |
| --- | --- | --- |
| E1 | The casual player gets the deck by 1:30 (the brief's £10, at £0.10 a pepper) | 1:06 |
| E2 | The first line by 2:30 for the pacing player, by 4:00 for the casual one | 1:35 and 3:16 |
| E3 | From the deck to 15:00, never longer than 75 s (pacing) or 100 s (casual) without something new | 64 s and 96 s |
| E4 | The plot matters: in the first 5 minutes it picks at least a third of the casual player's peppers | 37% |
| E5 | The casual player reaches the Tech Tree by 15:00 | 13:10 |
| E6 | The Starter Crate has a pile to bottle: at least 10 Sweet Pepper Mash waiting when the casual player buys the line | 11 |

**E6 was narrowed after measuring.** It was written for both players, but the pacing player buys the line 36 s after the vat, so only 3 mash waits. That's what a flat-out player gets, so it's now judged on the casual player only.

**E3 is tight** (96 s of 100). The wait is the vat-to-line saving, while the casual player keeps 50 peppers back for the vat. Trying a £12 vat didn't shorten it, because the line's price is what's being saved for.

### The 15–30 minute window (J3, this session)

E3 stops at 15:00, and N6 (15:00–50:00, at most 120 s) is measured on the flat-out pacing player only. Nothing bounds the window a phone player meets next. Set before measuring, from the owner's guide of something new every 30–60 seconds early on, with gaps stretching gradually:

| Id | Criterion |
| --- | --- |
| J3 | From 15:00 to 30:00, the casual player never goes longer than 120 s without something new (a purchase, an upgrade or a research; reveals as in E3). |

**Result: J3 PASS**, 48 s (the pacing player 38 s, not judged). Research and Tier 2 stations keep coming every 30–60 seconds through this window, so it needs no tuning. The flat spots in the first half hour are earlier: the vat-to-line saving (E3's 96 s) and the plots in between (W28 on PR #20).

### What moved

- **Bell Pepper Plot:** £10 → £5, and 1 pepper every 2.0 s → 1.0 s. It now picks about a third of a casual player's peppers, so it matters.
- **Vat slot 1:** £25 → £15.
- **Line slot 1:** £35 → £10. The pacing player waits 36 s between them, the casual one 96 s.
- **Upgrade prices are unchanged.** (Plot upgrades since D041 cost 5% of the plot's price × 1.3^level instead, [ECONOMY.md](ECONOMY.md#v06d-idle-planet-miners-early-flow-d041); `PLOT_PRICE_REFERENCE` is gone.) Upgrades scale against fixed reference prices, v0.2's £10, £25 and £35 (`PLOT_PRICE_REFERENCE` and so on in `tuning.gd`), not against the first station's price. Without that, the cheaper first stations would have raised every Tier 2 and 3 upgrade by up to 40%.
- **Brief numbers untouched:** 1 pepper a tap, £0.10 a pepper, 20 peppers to Stage 1, and £10 to Stage 2.

**Knock-on effects, all still passing:**
- Everything after the start comes earlier: Stage 3 at 6:53 (was 8:06), the Tech Tree at 11:02 (was 12:59), £10,000 at 42:46 (was 47:35), £100,000 at 1:24 (was 1:30).
- That makes W7 (the run outpacing the 3-hour curve) a little bigger, for v0.6.
- The bigger factory at 1:40 exposed two catch-up faults (OFFLINE.md):
  - **Shared Pickled Brine went to the wrong slot.** In a long step every vat ran before any line, so the Cayenne Mash vat took the Brine a waiting Bistro Verde line should have had. A vat's output is now offered to waiting slots at once, as in a tick.
  - **The Piston's presses were slow.** They are now batched in long steps.
- **P2 measurement fix:** its "2 hours of tapping" is a minute scaled by 120. At 1:40 a ×3 Market spike was running, and it was being counted for all 2 hours though a spike lasts 30 minutes. That minute is now measured without the spike.
