# Handover

## Where it's at

Merged: v0.1–v0.6c, D036–D042 (PRs #1–#19): Standard Operating Procedures free at 1%, Idle Planet Miner's early flow (starting plots, raw sales, 5% ×1.3 plot upgrades), and the pepper ladder by real heat with generic names (Alabama Grim, Pepper Y, Pineapple).

This branch carries **D043: Cargo replaces Crop Quality**, as the owner asked.
- **Plots grow and a truck carries.** A plot's upgrades are Harvest Speed, Yield and Cargo. Harvests land in the plot's field, and the truck carries them to stock at its cargo rate. An unupgraded truck carries twice the plot's base growth, and Tech and HQ boosts raise it alike, so only the player's own Speed and Yield levels can outgrow it.
- **Waiting crops show on the card** ("64 waiting", in orange). They count in Operation Value and are never lost.
- **The double-harvest chance moved to the Tech Tree:** Bumper Crop I–III, 10% each.
- **Saves:** save v11 turns Crop Quality levels into Cargo levels.

**Results:** C1–C7 PASS. Cargo first comes into play at 7:56. Every earlier criterion passes except **A4, by one second** (6:31 against 6:30, W29). The sale lands at 2:07, Phantom at 2:39, and the second run passes 4/4.

## Open decisions

- **W29, A4:** it flaps on seconds. Recommend a 7:00 bar, or fold it into W28.
- **W28:** the second plot feels slow to unlock on a phone; revisit the starting plots with the next early-game pass.
- **W27:** fermentation, as its own version.
- **W21, late growth; W24, a floor on how fast run 2 may be.**
- **Layout step 2** (W22) waits on W8's visual direction.

## Next

1. The owner settles W29 and merges this PR.
2. W28's early-game pass, or fermentation (W27), whichever the owner picks.

Touches: `game.gd` (field, truck, `cargo_rate`, `plot_boost`, Bumper Crop, save v11), `tuning.gd` (`CARGO_START`, `CARGO_STEP`), `data/tech.json` (E48–E50), `data_loader.gd`, `main.gd` (truck line, Cargo on the sheet), `engaged_player.gd`, tests, docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27–W29, G1, G12–G20.
