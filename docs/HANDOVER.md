# Handover

## Where it's at

Merged: v0.1–v0.6c, D036, layout step 1 and W17's second run (PRs #1–#17). PR #17 went in with Standard Operating Procedures paying cash (D039), which failed two second-run checks, so `main` was red. This branch settles it (**D040**): SOP is back to the brief's rule, **free at 1% of an hour's bottles**, and Y2's "first node within 10 minutes" is dropped. Every suite passes again:

- **Y1:** run 2 reaches the $10M sale at 1:34, 73% of run 1's 2:08.
- **Y2:** SOP researches 32 nodes in run 2 (its first 16½ minutes after it's bought, now allowed).
- **Y3:** Tier 6's first Scorpion Sting at 2:23.
- **Y4:** no wait over 256 s from 1:50 to 3:00.

Measured three ways and recorded in [PRESTIGE.md](PRESTIGE.md#the-second-run-w17): 1% free (now), 5% free (run 2 2.3× faster) and 5% paying (SOP mostly broke).

## In progress

The owner asked for the game's flow, especially early, to be in line with roughly how Idle Planet Miner does it. Research on IPM's early game (planet prices and spacing, when smelting and crafting arrive, first projects) is under way; a comparison and criteria come next, as their own PR.

## Open decisions

- **W21, late growth:** run 2 is worth $662M at 3:00 and $936M at 3:15. Recommend leaving it until the Cook-Off (v0.8).
- **W24, how much faster a repeat run may be:** nothing bounds it from below; recommend a floor (say 50% of run 1) once runs with more rooms are measured.
- **Layout step 2** (W22): moving the button and the factory floors wait on W8's visual direction.

## Next

1. Merge this PR (turns `main` green).
2. The Idle Planet Miner early-flow comparison and its changes.

Touches: `tuning.gd` (SOP_SHARE 0.01), `game.gd` (SOP free again), the Tech Tree's SOP text, the SOP and second-run tests, docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, G1, G12–G19.
