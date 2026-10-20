# Handover

## Where it's at

Merged: v0.1–v0.6c and D036 (PRs #1–#15): the full first run, Prestige, Tier 6 and Standard Operating Procedures, Idle Planet Miner's values in dollars, and a green pacing suite. This branch is **layout step 1** ([LAYOUT.md](LAYOUT.md), D037), the first of three steps from the layout plan:

- **Readable numbers:** $2.93M, 12.3K. Cents only under $10,000.
- **Station sheets:** each plot, vat and line card shows a Manage button (with "!" when an upgrade is affordable). It opens a sheet with its upgrades and a ×1 / ×10 / Max switch, remembered between sessions.
- **A bottle lands:** "+1 Table Mild $50.00" pops over Sell Batch, at most 4 a second; a coin flies to Cash on sales, at most 3 a second. Cash counts up to rises of $100 or more.
- **Goal bar** under the status bar: the way to the Tech Tree, then the next node with its scarcest item ("Next: Habanero, 5/20 Island"), then the sale from 50%.
- **Warehouse:** the stock line is Bell Peppers and bottles only; tapping it opens every item by kind with its worth. (W15, the crowded stock line, is done.)
- **Market tab** (opens with the Delivery Van): demand spikes, Auto-Sell and the valve, moved off Processing.

Checks: all eleven suites pass (L1–L9 new; a rounding bug in buying ten levels found and fixed); the headless boot is clean; every screen looked at with `capture_ui.gd`. **Not checked:** how the motion feels on a phone.

## Open decisions

- **Moving the Blank Button to the foot of the screen** (step 2) changes the brief's split viewport (§2). Recommend yes, with the visual pass.
- **W8:** step 2 needs your reference games and mood.
- **Late growth (W21)**, and D030/D034's assumptions, as before.

## Next

1. Merge this PR, then try the phone build: the link is republished with this branch's build.
2. W17 (a pacing player that sells and replays), or the Shift Roster (v0.7), or step 2 once W8's direction is in.

Touches: `main.gd` (sheets, drawer, goal bar, pops, count-up, Market page, number formats), `style.gd` (layout constants), `game.gd` (several levels at once, goal node, the Market tab's rule), `tuning.gd` (BULK_LEVELS, TABS_BUILT), tests (`layout_tests.gd` new, `ui_tests.gd`), the capture tool, docs. Stubbed or open: W3–W6, W8–W9, W16–W17, W21–W22, G1, G12–G19.
