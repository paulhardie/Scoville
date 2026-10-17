# Handover

## Where it's at

Merged: v0.1–v0.5.1 (PRs #1–#9). This branch (PR #10) adds the pepper ladder design and **Forager's Luck, built**.

**Forager's Luck (N10, D025), built.** A North Wing node off Double-Tap (20 Bistro Verde). Each press, the Piston's included, has a 2.5% chance to drop one harvest of whichever ingredient the factory is shortest of. All its criteria pass ([TECH_TREE.md](TECH_TREE.md#n10-foragers-luck-d025)): +13% to the shortest ingredient at 0:45 (target 10–20%). T4's window grew from 1 to 10 minutes after a noisy first measurement (+9%), bar unchanged. Save v6 (adds `stats.foraged`). The White Vinegar Plot is now shown as the Vinegar Cask (D024).

**Designed, not built:**
- **The pepper ladder ([INGREDIENTS.md](INGREDIENTS.md), D023, proposed).** 13 real peppers by Scoville, Bell to Pepper X, then 6 fictional ones up to 16 billion SHU, each with a value. The brief's six peppers keep their values. Not in `data/` yet (W10).
- **Ingredients as stations (D024, accepted)** and **as the deliberate bottleneck, with a Pantry branch whose tracks end in either/or forks (D026, accepted)**. Amounts and costs are G18, for v0.6.

Checks: button, core, factory, tech, upgrades, ui and pacing suites pass (32 pacing criteria). Offline passes except **X7** (8 hours away in under 0.5 s), which measures 0.85–1.4 s on the cloud container with or without this change; CI decides it (W3).

## Open decisions

- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later.
- **W7, the whole curve:** for v0.6, as agreed.
- **E6 was narrowed** to the casual player after measuring. Say if you'd rather the eager player saw a bigger crate moment too, which would mean a pricier line.
- **The pepper ladder (D023):** accept the list and values, or rename and swap peppers.
- **G17, how the new peppers are used:** recommend one mash and one sauce per new pepper (Idle Planet Miner's ore→bar), built with v0.6.

## Next

1. W8, once you've sent references; otherwise v0.6: G8, G16, G17 and G18, with the pepper ladder (W10) and the Pantry branch.

Touches: the simulation (Forager's Luck, a shared binomial draw), data (`ingredient`, station names, N10), the UI's node and station text, tests (T1–T4), save v6, and docs. Stubbed or open: W3–W10, G16–G18.
