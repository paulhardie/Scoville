# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D053 (PRs #1–#25), the last being v0.7 PR 2: Idle Planet Miner's skeleton built and measured (the first sale came at 7:56).

This branch is **v0.7 PR 3: the copy tuned (W35, D054).** The owner chose to keep I6's 2:00–2:30 and pull the copy to it. Criteria were set first (SKELETON.md, Z1–Z4), then nine tweaks, each listed with what it answers in [SKELETON.md](SKELETON.md#the-tweaks), and for data in `tools/ipm/tweaks.json`, which `build_data.py` applies and `skeleton_tests.gd` checks (Z2):

- T1–T3: surveyed farms cheaper, surveys at half, later farms ×1.15 a survey.
- T4: the kitchen's vat and line run only the kitchen, with IPM's free smelter and crafter after them.
- T5: SOP at 5% of Operation Value.
- T6–T8: a stronger Calloused Thumbs, cheaper button nodes, Night Shift I in Table Mild.
- T9: five times IPM's credits.

**Results** ([SKELETON.md](SKELETON.md#results-pr-3)):

- **Pass:** I6 (the sale at 2:07), Z3's checkpoints ($150K at 0:27, $1M at 1:04, $4M at 1:41), I8 (tapping 40%, 59%, 50%), I9 (run 2 at 69%), F6, E3, P2, Y2, Z2, Z4 and every other suite.
- **Fail:** I7 (gaps up to 15:15 against 6:30, W38), E6 (W30), and I10 (run 3 at Land Survey 19 of 25 after 24 hours, W44).

The pacing player changed too (SKELETON.md lists how). Each change fixed a stall or a choice no tapping player would make; none moved a bar.

Also fixed: the Standard Operating Procedures panel ran off the screen (already so in PR 2); `look_tests.gd` now covers it.

Checked: every suite and the headless boot. All pass except `pacing_tests.gd` (I7, E6), about 8 minutes in all. The screens were captured and looked at. Not checked: on a phone.

## Open decisions

- **W38, I7:** purchases come in bursts at each survey, about 20 minutes apart. Recommend keeping 6:30 and letting v0.8's Shift Roster (managers) fill the gaps; the alternative is setting I7 at 15:00 for the copy.
- **D054's tweaks:** they're the agent's, for your review. The structural ones are T4 (the kitchen kept apart), T5 (SOP's bar) and T9 (5× credits).
- **W30, E6:** still 2 against 10. Still recommend retiring E6.
- Still open: W8 and W32–W33 (the look), W27, W21, W24, W22.

## Next

1. The owner reviews and merges PR 3.
2. v0.8, the Shift Roster, with W38 in mind.

Touches: `data/` (rebuilt with the tweaks), `tools/ipm/` (`tweaks.json` new, `build_data.py`), `src/core/game.gd` (kitchen-only slots, SOP's bar, credit scale), `tuning.gd`, `src/sim/engaged_player.gd`, `src/ui/main.gd` (a wrapping node title, SOP's text), tests to the tweaks, docs (SKELETON, DECISIONS D054, BACKLOG, HANDOVER, AGENTS). Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, W30, W32–W33, W35–W36, W38, W44, G1, G12–G14, G16–G25.
