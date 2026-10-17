# Factory (v0.2 Operation Deck)

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

| Station | Price | Base | Speed upgrade | Other |
| --- | --- | --- | --- | --- |
| Bell Pepper Plot | £10 | 1 pepper every 2.0 s | +15% a level; £15 × 2.0^lv | Yield per Cycle: +1 pepper a level; £40 × 2.0^lv |
| Sweet Pepper Mash vat | £25 | 10 peppers → 1 mash in 8.0 s | +25% a level; £30 × 1.45^lv | — |
| Table Mild line | £35 | 1 mash → 1 bottle (£5) in 8.0 s | +25% a level; £45 × 1.5^lv | Starter Crate: 50 bottles at 10× (0.8 s each) |

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

## v0.3: slots, recipes and Tier 2 (draft)

Brief §2 Stage 3 and §3: the Processing tab takes over the vats and lines, which become slots that each run a chosen recipe. Tier 2's crops and recipes arrive through the Tech Tree's blueprints ([TECH_TREE.md](TECH_TREE.md)). Values are in [ECONOMY.md](ECONOMY.md).

### Rules

- **Farms tab:** one plot per crop. A crop's plot can be bought once its Crop Blueprint is researched (Bell Pepper needs none).
- **Processing tab:** vat slots and line slots. Each slot runs one recipe, picked from the recipes researched so far, and can be switched at any time. Switching hands any inputs taken for the current cycle back to stock and drops that cycle's progress.
- **Slot caps in v0.3:** 3 vat slots and 2 line slots, bought with cash (the brief's "Parallel Vat Slots" knob). The Tech Tree's Slot Expansion raises the caps in v0.4.
- **Recipes** set the inputs, output and base cycle time. A slot's speed level divides it, as in v0.2.
- **The Starter Crate** comes with the first line only.
- **Upgrades** keep v0.2's curves, scaled by price. A plot's upgrades cost the Tier 1 plot's curve × (its price ÷ £10). A slot's speed upgrades cost the vat or line curve × (its price ÷ slot 1's price).
- **Data:** crops, recipes, stations, item values and tech nodes move into `data/*.json`, loaded and checked only by `src/core/data_loader.gd`. Bad data fails at load with a message naming the file and row.
- **Saves:** version 3. A v2 save migrates with its vat as vat slot 1 running Sweet Pepper Mash and its line as line slot 1 running Table Mild, with levels, progress and crate kept.

### Numbers (starting guesses, G4)

To be tuned against [ECONOMY.md](ECONOMY.md#criteria-v03)'s N1–N8 during the build. Recipes and bottle values are the brief's.

| What | Price | Base |
| --- | --- | --- |
| Jalapeño Plot | £150 | 1 Jalapeño every 2.5 s |
| White Vinegar Plot | £200 | 1 Vinegar every 2.0 s |
| Vat slot 2 / 3 | £150 / £400 | — |
| Line slot 2 | £500 | — |
| Sweet Pepper Mash (10 Bell) | — | 8 s (v0.2) |
| Pickled Brine (10 Vinegar + 5 Bell) | — | 10 s |
| Verde Mash (15 Jalapeño) | — | 12 s |
| Table Mild (1 Sweet Pepper Mash), £5 | — | 8 s (v0.2) |
| Bistro Verde (1 Verde Mash + 1 Pickled Brine), £25 | — | 12 s |

A full Tier 2 setup (two plots, two more vat slots and a second line) costs £1,400 in cash. The research costs another £555 or so in bottles that aren't sold. That's about £1,950 between the Tech Tree (13:00) and N4's first Bistro Verde (by 30:00). At v0.2's late income of about £90 a minute, those 17 minutes bring in roughly £1,530. **As drafted, N4 probably misses by a few minutes.** I expect the build to lower these prices or the research costs, and the measurement will show which.

### Criteria (v0.3 rules)

| Id | Criterion |
| --- | --- |
| S1 | A slot runs only a researched recipe, takes exactly its inputs, and gives exactly its output after its cycle. |
| S2 | Switching a slot's recipe returns the inputs taken and loses only that cycle's progress. |
| S3 | No more slots than the cap can be bought. |
| S4 | A v2 save migrates to v3 and goes on producing exactly what it did. |
| S5 | Operation Value equals cash earned plus stock at ECONOMY.md's values, after every action and tick. |
| S6 | Bad data in `data/` fails at load with a message naming the file and row. |
