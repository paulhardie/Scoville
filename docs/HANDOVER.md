# Handover

## Where it's at

Merged: v0.1–v0.6c, D036 and layout step 1 (PRs #1–#16). This branch is **W17: the second run measured** ([PRESTIGE.md](PRESTIGE.md#the-second-run-w17)). `tests/second_run_tests.gd` plays the pacing player through run 1 to 3:00, sells (31 credits), opens three rooms (Cooperage, Fermentation Cellar, Glassworks) and plays run 2.

With Standard Operating Procedures' bar at 5% (D038, your call; 1% failed Y2), every criterion passes:
- **Y1:** run 2 reaches the $10M sale at 57 minutes, 44% of run 1's 2:08.
- **Y2:** SOP's first node 19 s after it's bought; 67 over the run.
- **Y3:** Tier 6's first Scorpion Sting at 1:24.
- **Y4:** no wait over 89 s from 1:50 to 3:00.
- **But run 2 is now very fast:** research SOP grants is free, so it skips most research costs. Run 2 is worth $1.69B at 3:00 (14× run 1) (W24, W21).

The player learnt to sell and spend (`sell_and_spend`), skips after-sale nodes before a sale (so run 1 and the pacing suite are unchanged), and has a Scorpion Sting layout. Checks: every suite passes (pacing 38/38, second run 4/4); the headless boot is clean; SOP's text on the Tech Tree says 5%.

## Open decisions

- **W24, how much faster run 2 should be:** recommend SOP pays for what it researches (it takes the clicking away, not the cost). Run 2 would then speed up from the rooms alone, as at 1% (73% of run 1), with SOP still busy from the start.
- **W21, late growth:** run 2 hits $936M by 3:15. Fine as "the reward for pushing", or cap it? Recommend leaving it until the Cook-Off (v0.8) gives big numbers somewhere to go.
- W8 and moving the button (layout step 2), as before.

## Next

1. Merge (CI goes green with this push), then decide W24.
2. v0.7 Shift Roster, or layout step 2 once W8's direction is in.

Touches: `src/sim/engaged_player.gd` (selling, rooms, Tier 6 research and layout, after-sale skip), `tests/second_run_tests.gd` (new), docs. Stubbed or open: W3–W6, W8–W9, W16, W21, W24, G1, G12–G19.
