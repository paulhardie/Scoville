# Handover

## Where it's at

Merged: v0.1–v0.6c, D036 and layout step 1 (PRs #1–#16). This branch is **W17: the second run measured** ([PRESTIGE.md](PRESTIGE.md#the-second-run-w17)). `tests/second_run_tests.gd` plays the pacing player through run 1 to 3:00, sells (31 credits), opens three rooms (Cooperage, Fermentation Cellar, Glassworks) and plays run 2.

- **Y1 PASS:** run 2 reaches the $10M sale at 1:34, 73% of run 1's 2:08.
- **Y2 FAIL:** Standard Operating Procedures researches 32 nodes in run 2, but its first only 16½ minutes after it's bought (W23).
- **Y3 PASS:** Tier 6's first Scorpion Sting at 2:23.
- **Y4 PASS:** no wait over 256 s from 1:50 to 3:00.
- **Late growth:** run 2 is worth $662M at 3:00 and $936M at 3:15 (W21).

The player learnt to sell and spend (`sell_and_spend`), skips after-sale nodes before a sale (so run 1 and the pacing suite are unchanged), and has a Scorpion Sting layout. Checks: all suites run; the second-run suite FAILs on Y2 only; pacing still 38/38; no screen change.

## Open decisions

- **W23, SOP's slow start:** a bigger bar (5% of an hour of bottles instead of 1%, so Double-Tap-sized nodes fall under it early), or accept that SOP only kicks in once the factory grows. Recommend 5%: SOP's point is to take the early clicking away on repeat runs, and at 1% it doesn't touch the early tree.
- **W21, late growth:** run 2 hits $936M by 3:15. Fine as "the reward for pushing", or cap it? Recommend leaving it until the Cook-Off (v0.8) gives big numbers somewhere to go.
- W8 and moving the button (layout step 2), as before.

## Next

1. Settle W23 (and so turn CI green), then merge.
2. v0.7 Shift Roster, or layout step 2 once W8's direction is in.

Touches: `src/sim/engaged_player.gd` (selling, rooms, Tier 6 research and layout, after-sale skip), `tests/second_run_tests.gd` (new), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W23, G1, G12–G19.
