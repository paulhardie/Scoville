# Handover

## Where it's at

Merged: v0.1–v0.6a and v0.6b part 1 (PRs #1–#12): the full first run to £1M in about 3 hours, Prestige with the 12 HQ rooms, and the click and buzz. This branch adds **v0.6b part 2 (W12), built** ([PRESTIGE.md](PRESTIGE.md#part-2-standard-operating-procedures-and-tier-6), D034): what's new on a run after the first sale.

**Standard Operating Procedures** (W7, West Wing, 10 Table Mild, after the first sale):
- Once researched, any node you could research whose cost is worth under 1% of an hour of your running lines' bottles researches itself, free, checked every second.
- Either/or (Pantry) nodes are never taken for you.
- It works during time away too.

**Tier 6** (after the first sale, E39–E47 east of Phantom):

| Pepper | Mash | Sauce |
| --- | --- | --- |
| Trinidad Moruga Scorpion (£150k plot) | Moruga Mash | Scorpion Sting £14,920 (Moruga Mash + Savina Gold) |
| Carolina Reaper (£400k plot) | Reaper Mash | Widowmaker Reserve £40,000 (D006's recipe) |
| Pepper X (£1.5M plot) | Pepper X Mash | Event Horizon £100,000 (Pepper X Mash + Scorpion Sting) |

Before a sale, these ten nodes show on the web, muted, with "Opens after your first franchise sale."

Checks: `bash run_tests.sh` passes all ten suites (Q10–Q14 new); the headless boot is clean; the two new Tech Tree states looked at with `capture_ui.gd`. **Not checked:** how a second run actually plays. Nothing measures a run after a sale yet (W17), so Tier 6's plot prices and SOP's 1% bar are untested against real play.

**Phone build:** a private test link of `main` (as of PR #12) is at https://claude.ai/artifact/8W6iHzT2vHiSLEREpT9tmu. It's the Web export with the engine gzipped to fit; it doesn't include this branch. `bash tools/serve_web.sh` still serves the full build on the LAN.

## Open decisions

- **D034's assumptions:** SOP's bar (1% of an hour of bottles, free), Tier 6's sauces, prices and plot costs. Change any freely.
- **Prestige's numbers (D030):** credits formula, room prices, G16 at Level 8, G19's caps.
- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later. The crowded stock line (W15) joins it.

## Next

1. Try the phone link for the click and buzz (W16).
2. Merge this PR.
3. Then W17 (a pacing player that sells and replays, to measure run 2 and tune Tier 6), the Shift Roster's rules with placeholder art (v0.7), or W8 once you've sent references.

Touches: data (items, plots, recipes, tech), `data_loader.gd` (`after_sale`, the `sop` effect), `game.gd` (the after-sale gate, `_sop`, `bottle_rate`, `tech_cost_value`, research split into `_grant`), `tuning.gd` (SOP constants), the Tech Tree's text, tests, the capture tool, docs. Stubbed or open: W3–W6, W8–W9, W15–W17, G1, G12–G19.
