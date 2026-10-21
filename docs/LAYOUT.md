# Layout (step 1 of the layout plan)

The owner asked how to house all the game's content and lay it out so it's satisfying to play. The answer was a plan in three steps ([D037](DECISIONS.md)):

1. **No art needed:** readable numbers, station sheets with ×1/×10/Max buying, a payoff when a bottle is made, a goal bar, a warehouse drawer, and a Market tab.
2. **Needs the visual direction (W8):** the factory shown as floors with items moving between them, and the Blank Button moved to the foot of the screen.
3. **Last:** chain diagrams, bottleneck highlights, and ceremonies for unlocks and the sale.

This doc is step 1. Status: **built**, all criteria PASS.

## Rules

- **Numbers.** Money under $10,000 keeps its cents ($1,234.50). From $10,000 it's three significant figures with a suffix: $12.3K, $2.93M, $757M, $1.20B, then T, Qa, Qi. Counts of items do the same from 10,000 (12.3K, 4.50M), without a $.
- **Station sheets.** A plot, vat or line is a compact card: its name, what it does, its cycle bar, and one **Manage** button. Manage carries a "!" when one of its upgrades is affordable. Tapping it opens the station's sheet over the bottom of the screen: its upgrades, with a **×1 / ×10 / Max** switch. ×1 buys one level; ×10 buys ten if all ten are affordable, and is otherwise disabled; Max buys as many as cash covers (at least one). Each upgrade button shows the price of what it would buy. The switch is remembered with the other settings (`user://settings.json`). Tapping outside the sheet closes it. Buying a plot or a slot, and a slot's recipe picker, stay on the card (picking a recipe is too frequent to bury).
- **A bottle lands.** Each time lines make bottles, a "+N Name $value" label floats up from Sell Batch and fades. Bottles from the same frame are gathered into one label, and at most POPS_PER_SECOND labels show a second. When a sale (Sell Batch, Auto-Sell, the valve) adds cash, a coin flies from Sell Batch to Cash, at most COINS_PER_SECOND a second.
- **Cash counts up.** A rise of COUNT_UP_FROM ($100) or more moves Cash on screen towards the real cash over COUNT_UP seconds, rather than jumping; smaller rises, and any spending, show at once (so the first $2 of raw peppers isn't animated). It never shows more than the real cash.
- **The goal bar.** One line between the status bar and the stock, from Stage 3 (the nav bar), so the early reveals stay a surprise:
  - before the Tech Tree opens: the next tab and how far Operation Value is towards it ("Tech Tree at $7,500: 62%");
  - then: the pinned node, or else the reachable node whose cost is worth least, with its scarcest cost item ("Next: Jalapeño, 2/3 Table Mild");
  - once the run is past half the sale: "Sale 64%", then "Sale ready" (the HQ tab sells).
- **The warehouse.** The stock line under the goal bar shows Bell Peppers and the bottles in stock only, on one line. Tapping it opens the warehouse drawer: every item the run has had, grouped as Bottles, Mash and Crops, each with its count and what the stock is worth.
- **The Market tab.** The Delivery Van's Auto-Sell sliders, the Raw Overflow Valve's keep amounts, and the Market Ticker's spike move from Processing to their own tab, between Tech Tree and Shift Roster. It opens with the Delivery Van; before that it says so when tapped.

## Criteria

| Id | Criterion |
| --- | --- |
| L1 | Money and counts follow the number rule above at every boundary: $9,999.99, $10.0K, $999K, $1.00M, $1.23B; 9,999 and 10.0K. |
| L2 | The ×10 and Max rules are the game's (`game.gd`), not the screen's: buying ten levels costs the sum of the next ten prices; Max buys the most levels cash covers and leaves less than the next level's price; a capped upgrade (Crop Quality at 10) stops at the cap (D043 removed Crop Quality, the only capped one, so that check is gone). |
| L3 | A station card shows no upgrade buttons; Manage opens its sheet; the sheet's ×1, ×10 and Max each buy what they say; "!" shows exactly when an upgrade is affordable; the buy mode survives a restart of the screen. |
| L4 | Bottles made show a pop from Sell Batch, at most POPS_PER_SECOND a second however fast lines run; a sale flies a coin, at most COINS_PER_SECOND a second. |
| L5 | After a sale of $X, Cash on screen shows less than the real cash within the first frame, and exactly the real cash after COUNT_UP seconds. |
| L6 | The goal bar shows the next tab's progress before the Tech Tree, then the next node with its scarcest item, and the sale's percentage from 50%. |
| L7 | The stock line holds Bell Peppers and bottles on one line; tapping it opens the drawer with every item had, grouped by kind. |
| L8 | Market is locked until the Delivery Van, then holds the Auto-Sell sliders and the valve; Processing no longer does. |
| L9 | Nothing breaks the onboarding: stage 0 still shows no text, and every earlier UI check (O1–O9, X8, Q9, Q14, K1–K5) still passes. |

## Assumed

- Thresholds: three significant figures from $10,000; ten levels for ×10; POPS_PER_SECOND 4, COINS_PER_SECOND 3, COUNT_UP 0.35 s (`style.gd`).
- "The reachable node whose cost is worth least" as the default goal; the pin overrides it.
- The sale's percentage shows from 50%, so it doesn't sit at 0% for the first two hours.
- Market sits between Tech Tree and Shift Roster; the brief's tabs otherwise stay (Shift Roster is still the fourth of the brief's five, now fifth on screen).

## Results

All PASS: `tests/layout_tests.gd` (L1–L2, 22 checks) and `tests/ui_tests.gd` (L3–L8, with every earlier UI check: L9). The whole suite passes, pacing included; the headless boot is clean. Looked at with `capture_ui.gd` (`l1_sheet.png`, `l1_market.png`, `l1_drawer.png`, and the earlier stages).

Found on the way:
- **A rounding bug in buying ten at once** (first version): the last level could fail on a cent's rounding after nine were paid, while reporting ten. Several levels are now paid in one sum.
- From looking at the screens: the pop ran off the right edge and over the stock line, a catch-up made one huge pop, and ×10 said "max" for Crop Quality with three levels left. All fixed.

**Not checked:** how it feels on a phone (the pops, the coin and the count-up are motion; W16's phone test covers them).
