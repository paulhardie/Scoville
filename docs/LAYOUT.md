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

## Step 2: the dashboard from the first launch (D044)

The owner changed their mind on progressive disclosure: the game opens on the full dashboard, and what makes the start gentle is that the next early action is unmistakable, not that the screen is empty. This builds layout step 2's viewport and puts the tab selectors directly beneath it. The factory view is drawn in code with the existing palette; it doesn't wait on W8's visual direction, which can restyle it later.

### Rules

- **The screen, top to bottom:** the status bar (Cash, Operation Value, Sell Raw Peppers); the **upper viewport** (the goal line, the stock line, the Blank Button with the Heat bar, the **factory view** and Sell Batch); the **tab selectors**; the panel of the open tab.
- **Nothing is hidden until a milestone.** Selling raw peppers and buying the first plot work from the first second.
- **Tabs:** every selector shows from the start. A locked one is dimmed and says what opens it ("$7.5K", "Van"). Tapping one explains, as now. Tabs open at the same Operation Value thresholds as before.
- **The factory view** shows three floors, Bottling over Vats over Fields. Each owned station is a tile that fills as its cycle runs; a plot whose truck can't keep up shows orange. An empty floor says what goes there. A dot climbs from Fields to Vats when crops reach stock, and from Vats to Bottling when a mash is made, at most DOTS_PER_SECOND a second.
- **The next action** (`Game.next_action()`, so the rule lives in the simulation) is one of: press the button, sell raw peppers, Sell Batch, buy a station, or open a tab. It walks a fixed early sequence: the Bell Pepper Plot, Vat 1, Line 1, the first Sell Batch, the Poblano Plot, the Jalapeño Plot, then opening the Tech Tree once it's open. While cash is short of the next purchase, it points at Sell Batch (with bottles held), else Sell Raw Peppers (before the first vat, when selling covers the price), else the button. The target is ringed with a pulsing orange outline and named on the goal line. If it's on another tab, that tab's selector is ringed. On a long page, the page scrolls to it.

### Criteria (step 2)

| Id | Criterion |
| --- | --- |
| L10 | A fresh game shows the full dashboard: status bar, viewport (goal line, stock line, button, factory view), every tab selector directly below the viewport, and the Farms panel. Nothing appears later or slides in. |
| L11 | Every tab selector shows from the start; a locked one is dimmed and names what opens it; tabs open at the thresholds they did before (N1, N2, Q9). |
| L12 | The factory view has a tile for every owned station on its floor, filling with its cycle; a backed-up plot's tile is orange; an empty floor names what goes there; dots climb when crops reach stock and when mash is made, at most DOTS_PER_SECOND. |
| L13 | Exactly one next action is shown through the early sequence, ringed on screen and named on the goal line, as `next_action()` gives it: from a fresh game, the button, then Sell Raw Peppers, then the Bell Pepper Plot, and so on to opening the Tech Tree. With the target on another tab, that tab's selector is ringed. |
| L14 | Once the sequence is done, the goal line is the goal bar (next node, the sale's progress) and nothing is ringed. |
| L15 | Every earlier criterion still passes, except those D044 retires: O1 (the blank screen), O3's and O4's "not before" (the counter and status bar show from the start), O8's nav bar appearing at a threshold, and L9's "stage 0 shows no text". F1, F2 and E1 now read 0:00.1. |

### Results (step 2)

**L10–L14 PASS; L15 FAILS on two criteria by one unit each.**

- **L10:** a fresh game shows the status bar, the viewport (the button, factory view, goal and stock lines), all six tab selectors directly under the viewport, and the Farms panel (UI suite).
- **L11:** locked selectors read "Processing $4K", "Tech Tree $7.5K", "Market Van", "Shift Roster $150K" and "HQ $10M". A locked tab doesn't open, and Processing opens at $4,000.
- **L12:** a tile per owned station on its floor, an orange tile for a backed-up plot, and dots climbing at most 6 a second.
- **L13:** from a fresh game the ring goes from the button to Sell Raw Peppers (once 50 peppers cover the plot), to the Bell Pepper Plot's Buy, and on through Vat 1, Line 1, Sell Batch and the starting plots to opening the Tech Tree. A purchase on another tab rings that tab's selector (core and UI suites).
- **L14:** with the sequence done, the goal line is the goal bar again (L6 passes).
- **L15:** every earlier criterion passes except two:
  - **A4: 6:31 against 6:30.** This is the same miss as D043's (W29).
  - **E6: 9 Sweet Pepper Mash waiting for the casual player's Starter Crate, against 10.** The first plot can now be bought at $50 straight away rather than after $100 earned, so the casual player reaches the line sooner, with less mash piled up (eager player: plot at 0:17, was 0:34). Raising Line 1 to $115 or $130 fixed E6 but failed E3 (a casual player's 120 s with nothing new) and, at $115, U7; reverted.
  - F1, F2 and E1 now read 0:00.1, since nothing is revealed.

**Not checked:** how it feels on a phone, which is W16's phone test.
