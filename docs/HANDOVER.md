# Handover

## Where it's at

Merged: v0.1–v0.6c, D036, layout step 1, W17's second run and D040 (Standard Operating Procedures free at 1%; PRs #1–#18). This branch carries **D041, Idle Planet Miner's early flow**, and D042, the pepper ladder and Pineapple:

- **The Poblano and Jalapeño Plots are on sale from the start** at $800 and $1,900 (each pays back raw in 8–10 minutes, as Idle Planet Miner's first planets do). Blueprints gate crops from White Vinegar on. E1 and E12 are now Cultivation nodes (×1.5 plot speed), with the same ids.
- **Every crop sells raw** from its plot's card, and the cards list cheapest first.
- **Plot upgrades cost 5% of the plot's price, then ×1.3 a level**, with smaller gains: speed +3%, yield +6% of base (fractions carry), Crop Quality 1% to 30. Save v9 converts old levels to at least the same effect.
- Measured into place: Ancho Mash 18 s (V3), Forager's Luck drops one base cycle's growth, the Savina plot at $2.0M and the Moruga plot at $5M, and the pacing player's new habits ([ECONOMY.md](ECONOMY.md#built-v06d)).

**Results:** A1–A3, A5 PASS; every earlier criterion PASS (pacing, second run, all suites). The early flow now goes: line 1:35, Poblano Plot 3:15, Jalapeño Plot 7:14, Ancho vat 13:36. The run is about 14 minutes faster late on (Phantom at 2:38, the sale at 2:01:56).

**A4** measured 6:22 against its first bar of 6:00; the owner moved the bar to 6:30 (W26), so every suite passes.

**D042, built:** the pepper ladder by real heat with generic names: Thai Chili, Caribbean Red Habanero, Chocolate Habanero (its sauce Cocoa Loco), and the parodies Alabama Grim and Pepper Y in Tier 6. Pineapple replaces Cane Sugar, grown in a Pineapple Grove and made into Charred Pineapple Glaze. Save v10 renames the ids. Pacing is identical, since every rung keeps its value.

## Open decisions

- **Thin margins:** the sale lands 1:56 inside its 2:00 floor, and E3 is at 74 s against 75. Anything that speeds up the early or middle game will tip them.
- **W21, late growth:** run 2 is worth $659M at 3:00 and $846M at 3:15. Recommend leaving it until the Cook-Off (v0.8).
- **W24, how much faster a repeat run may be:** run 2 now takes 64% of run 1 (was 73%). Recommend a floor, say 50%.
- **Layout step 2** (W22) waits on W8's visual direction.

## Next

1. The owner merges this PR.
2. Fermentation (W27) when the owner picks it up; layout step 2 waits on W8.

Touches: `data/plots.json`, `data/recipes.json` (Ancho Mash), `data/tech.json` (E1, E12), `tuning.gd`, `game.gd` (upgrade curve, fractional yield, `sell_crop`, Forager's drop, save v9), `main.gd` (Sell on plot cards, order), `engaged_player.gd`, tests (A1–A5, updated upgrade and migration checks), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, G1, G12–G20.
