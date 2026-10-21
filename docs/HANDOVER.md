# Handover

## Where it's at

Merged: v0.1–v0.6c, D036, layout step 1, W17's second run and D040 (Standard Operating Procedures free at 1%; PRs #1–#18). This branch carries **D041, Idle Planet Miner's early flow**, and the D042 pepper-ladder proposal:

- **The Poblano and Jalapeño Plots are on sale from the start** at $800 and $1,900 (each pays back raw in 8–10 minutes, as Idle Planet Miner's first planets do). Blueprints gate crops from White Vinegar on. E1 and E12 are now Cultivation nodes (×1.5 plot speed), with the same ids.
- **Every crop sells raw** from its plot's card, and the cards list cheapest first.
- **Plot upgrades cost 5% of the plot's price, then ×1.3 a level**, with smaller gains: speed +3%, yield +6% of base (fractions carry), Crop Quality 1% to 30. Save v9 converts old levels to at least the same effect.
- Measured into place: Ancho Mash 18 s (V3), Forager's Luck drops one base cycle's growth, the Savina plot at $2.0M and the Moruga plot at $5M, and the pacing player's new habits ([ECONOMY.md](ECONOMY.md#built-v06d)).

**Results:** A1–A3, A5 PASS; every earlier criterion PASS (pacing, second run, all suites). The early flow now goes: line 1:35, Poblano Plot 3:15, Jalapeño Plot 7:14, Ancho vat 13:36. The run is about 14 minutes faster late on (Phantom at 2:38, the sale at 2:01:56).

**A4 FAILS:** 6:22 between the Jalapeño Plot and the Ancho vat, against 6:00 (W26). CI's pacing step is red until that's settled.

## Open decisions

- **W26, A4:** recommend accepting 6:30 as the bar. The gap is the Tech Tree gating the Ancho vat, down from 12:37. The alternative, dearer starting plots, fails E3 and T4 instead.
- **Thin margins:** the sale lands 1:56 inside its 2:00 floor, and E3 is at 74 s against 75. Anything that speeds up the early or middle game will tip them.
- **W21, late growth:** run 2 is worth $659M at 3:00 and $846M at 3:15. Recommend leaving it until the Cook-Off (v0.8).
- **W24, how much faster a repeat run may be:** run 2 now takes 64% of run 1 (was 73%). Recommend a floor, say 50%.
- **Layout step 2** (W22) waits on W8's visual direction.

## Next

1. The owner settles W26, then merges this PR.
2. The owner's calls on D042 (rung 13: a fictional pepper or keep Reaper and Pepper X) and on the ingredients (pineapple for Cane Sugar; fermentation as its own version); then build what's chosen.

Touches: `data/plots.json`, `data/recipes.json` (Ancho Mash), `data/tech.json` (E1, E12), `tuning.gd`, `game.gd` (upgrade curve, fractional yield, `sell_crop`, Forager's drop, save v9), `main.gd` (Sell on plot cards, order), `engaged_player.gd`, tests (A1–A5, updated upgrade and migration checks), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W26, G1, G12–G20.
