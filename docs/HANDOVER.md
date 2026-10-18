# Handover

## Where it's at

Merged: v0.1–v0.5.1 (PRs #1–#9) and the pepper ladder design (PR #10). **Open: PR #11, every suite passing**, waiting on the owner to merge. It holds:

- **Forager's Luck** (N10, D025): a 2.25% chance a press to drop a harvest of the shortest ingredient.
- **X7 machine-relative** (D027).
- **v0.6a, the full run** ([FULL_RUN.md](FULL_RUN.md), D028–D033), **built**. A ten-rung sauce ladder from Table Mild to Phantom Smokehouse; the pepper ladder's new peppers through Tier 5; the Pantry branch with Bulk or Reserve forks; Slot Expansion III–IV; Artisan Decanters; two GMO boosters. A pacing player that plays all of it. Every criterion passes: £1M at 2:51, every rung on time, the forks worth up to 21%, the catch-up accurate and fast at 2:30.
- **v0.6b part 1, Prestige** ([PRESTIGE.md](PRESTIGE.md), D030), **built**: selling the franchise at £1M, Franchise Credits, the 12 HQ rooms with a saved 2-card draft and levels, the brief's cost formula, the HQ tab, save v7.

Tuning decisions this round: slot upgrades priced by what the slot makes (D031); U8 from 1:20, U4 narrowed, M6 retired, three measurement fixes (D032); U2 300 s late, U5 measured by vat time spent on ingredient mash (D033). Tier 5 is gated by cash rather than research, because stock counts in Operation Value.

Checks: `bash run_tests.sh` passes all ten suites (button, core, factory, full run, offline, pacing 39 criteria, prestige, tech, ui, upgrades); the headless boot is clean.

## Open decisions

- **Prestige's numbers (D030):** credits formula, room prices, G16 at Level 8, G19's caps. Change any freely.
- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later.
- **The v0.6 split (D028)** and **E6's narrowing**: low stakes.

## Next

1. Merge #11.
2. Then, recommended: **W2, sound and haptics** (nothing blocks it; it's the cheapest lift to how it feels on a phone).
3. Then v0.6b part 2 (W12: Standard Operating Procedures; Tier 6 needs its recipes, G17), or the Shift Roster's rules with placeholder art (v0.7).

Touches: data (tuned prices and costs), the slot upgrade rule (D031), the pacing player (layouts, research order), pacing and offline tests (U criteria, U9), docs. Stubbed or open: W2–W9, W12, G1, G12–G19.
