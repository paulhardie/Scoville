# Handover

## Where it's at

Merged: v0.1–v0.6c, D036–D042 (PRs #1–#19): Standard Operating Procedures free at 1%, Idle Planet Miner's early flow (starting plots, raw sales, 5% ×1.3 plot upgrades), and the pepper ladder by real heat with generic names (Alabama Grim, Pepper Y, Pineapple).

This branch carries **D043: Cargo replaces Crop Quality**, as the owner asked.
- **Plots grow and a truck carries.** A plot's upgrades are Harvest Speed, Yield and Cargo. Harvests land in the plot's field, and the truck carries them to stock at its cargo rate. An unupgraded truck carries twice the plot's base growth, and Tech and HQ boosts raise it alike, so only the player's own Speed and Yield levels can outgrow it.
- **Waiting crops show on the card** ("64 waiting", in orange). They count in Operation Value and are never lost.
- **The double-harvest chance moved to the Tech Tree:** Bumper Crop I–III, 10% each.
- **Saves:** save v11 turns Crop Quality levels into Cargo levels.

**Results:** C1–C7 PASS. Cargo first comes into play at 7:56. Every earlier criterion passes except **A4, by one second** (6:31 against 6:30, W29). The sale lands at 2:07, Phantom at 2:39, and the second run passes 4/4.

This branch also carries **D044: the dashboard from the first launch**, as the owner asked.
- **No progressive disclosure:** the status bar, the upper viewport (the button, a factory view of Bottling, Vats and Fields with dots climbing between them, and Sell Batch), the six tab selectors directly under the viewport, and the Farms panel all show from the first second.
- **Locked tabs show what opens them** ("Tech Tree $7.5K"); the thresholds are unchanged.
- **One next action at a time** (`Game.next_action()`) is ringed in orange and named on the goal line through the early run: tap, sell, buy the plot, Vat 1, Line 1, Sell Batch, the starting plots, then open the Tech Tree.
- **Results:** L10–L14 PASS. Two misses by one unit: A4 (6:31, W29) and E6 (9 mash for the casual player's Starter Crate, against 10, W30).

## Open decisions

- **W29 (A4) and W30 (E6):** both miss by one unit after the early game sped up. Recommend settling them in W28's early-game pass.
- **W28:** the second plot feels slow to unlock on a phone; revisit the starting plots with the next early-game pass.
- **W27:** fermentation, as its own version.
- **W21, late growth; W24, a floor on how fast run 2 may be.**
- **Layout step 3** (W22) waits on W8's visual direction, which can also restyle step 2's factory view.

## Next

1. The owner tries the dashboard on a phone, settles W29/W30 and merges this PR.
2. W28's early-game pass, or fermentation (W27), whichever the owner picks.

Touches: `game.gd` (field, truck, `cargo_rate`, `plot_boost`, Bumper Crop, save v11), `tuning.gd` (`CARGO_START`, `CARGO_STEP`), `data/tech.json` (E48–E50), `data_loader.gd`, `main.gd` (truck line, Cargo on the sheet), `engaged_player.gd`, tests, docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27–W30, G1, G12–G20.
