# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D053 (PRs #1–#24), the last being v0.7 PR 1, the Idle Planet Miner skeleton mapped. PR #24 merged without its Haiku-review commit (Shift Roster as v0.8 everywhere, the Bell Plot's truck, criteria lists, formulas in the snapshot); PR 2 carries it.

This branch is **v0.7 PR 2: the copy built and measured (W34).** Idle Planet Miner's progression is in the game as [SKELETON.md](SKELETON.md) maps it: 79 farms growing pepper mixes with trucks, 28 peppers, 33 mashes, 48 sauces, 25 Land Surveys, 30 adopted nodes, 10 vats and 10 lines, 15 HQ rooms in IPM's order, Operation Value as Galaxy Value, save v12 (an old run comes back as cash and items). `data/*.json` is built from `tools/ipm/mapping.json` by `tools/ipm/build_data.py`.

**Results** ([SKELETON.md](SKELETON.md#results-pr-2)): I1–I3, I5, I11–I13 PASS. **FAIL:** I6 (the $10M sale at 7:56, not 2:00–2:30), I7 (1:11 with nothing new while Land Survey 3 fills), I8 (tapping 13%, 10%, 6%), I9 (run 2 at 85%), I4 (F6, E3, E6), I14 (P2 by 2%, Y2: SOP grants nothing), and I10 (run 2 is at Land Survey 5 of 25 after 48 hours). Each has a backlog row, W37–W44 and W30.

The pacing player's policy is a GUESS rewritten for the copy (goal: the next survey). Three stalls in it were fixed while measuring; a better player might be quicker, so PR 3 should judge player and curve together.

Checked: every suite and the headless boot (all pass but `pacing_tests.gd` and `second_run_tests.gd`, which fail exactly on the FAILs above; about 12 minutes in all, inside CI's 20); the screen captured and looked at, including every farm owned (I13). Not checked: on a phone.

## Open decisions

- **W31 and I6: when the first sale comes.** The copy, as played, sells at about 8 hours, not 2:00–2:30. Recommend PR 3 pulls the curve back to I6's band (survey costs and the Pimento farms first), since a first sale at 8 hours on a phone is a long wait; the alternative is moving the bar nearer IPM's own pace. Say which before PR 3.
- **W30, E6:** now 2, not 9. Still recommend retiring E6.
- Still open: W8 and W32–W33 (the look), W27, W21, W24, W22.

## Next

1. The owner reviews and merges PR 2 (merging is the owner's call).
2. PR 3 (W35): tweak against W37–W44 and set new checkpoints from the measured run.

Touches: `src/core` (game, data loader, tuning), `src/ui/main.gd`, `src/sim/engaged_player.gd`, `data/`, every test suite plus `tests/skeleton_tests.gd`, `tools/deep_run.gd`, `tools/ipm/` (`build_data.py`, `mapping.json`), `tools/capture_ui.gd`, the pixel font's extra glyphs, `run_tests.sh`, docs (SKELETON results, BACKLOG, HANDOVER, AGENTS layout). Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, W30–W33, W35, W37–W44, G1, G12–G14, G16–G25.
