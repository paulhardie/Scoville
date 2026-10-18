# Handover

## Where it's at

Merged: v0.1–v0.5.1 (PRs #1–#9) and the pepper ladder design (PR #10). **Open: PR #11, red on two of v0.6a's pacing criteria (U2, U5)**, waiting on the owner. It holds Forager's Luck, D024–D027, v0.6a (design, stage 1, stage 2 in progress) and now **v0.6b part 1, Prestige, built**.

**Prestige ([PRESTIGE.md](PRESTIGE.md), D030), built.** All criteria pass: Q1–Q8 in `prestige_tests.gd` (50 checks), and Q9 on screen in `ui_tests.gd`.
- **Sell the franchise** at £1M Operation Value, on the HQ tab, with a second tap to confirm. It pays Franchise Credits: 10 × log₁₀(OV ÷ £100k), so 10 at £1M and 20 at £10M.
- **What resets:** the run (cash, plots, slots, stock, the Tech Tree, Heat, timers, statistics).
- **What stays:** the account (credits, rooms, best Operation Value, sales) and the reveals.
- **The 12 HQ rooms** from the brief's table, each wired in. Opening the n-th costs 5n credits and deals a 2-card draft, which is saved so it can't be re-dealt. Levels cost 2 × level, up to each room's cap.
- **The brief's anti-exploit cost formula** applies to Tech Tree costs, and discounted recipe inputs multiply, rounded down, at least 1.
- **Save v7:** v6 saves load as an account that has never sold.
- Assumed: G8, G16, G19 (D030), listed in PRESTIGE.md.

**v0.6a, the full run ([FULL_RUN.md](FULL_RUN.md)): 39 of 41 pacing criteria pass.**
- £1M lands at 2:47, and every rung arrives on time.
- The forks matter: up to a 21% swing.
- Tapping adds 64% at 2:30.
- U2 (late waits) and U5 (the ingredient bottleneck) fail, and each needs your call.

The tuning: slot upgrades priced by what they make (D031), U8 from 1:20, U4 narrowed, M6 retired, plus three measurement fixes (D032). Tier 5 is gated by cash rather than research, because stock counts in Operation Value; FULL_RUN.md has the details.

Checks: every rule suite passes (button, core, factory, full run, offline, prestige, tech, ui, upgrades); the headless boot is clean. The pacing suite passes 39 of 41 (U2, U5 FAIL).

## Open decisions

- **U2 (W13):** relax to 300 s for 1:50–3:00, or add cheap late purchases. Recommend relaxing.
- **U5 (W14):** measure the bottleneck by the share of vat slots spent on ingredient mash (Brine, Paste, Glaze, Smoke), at least 30% from 2:00, and keep "no single wait over 5 minutes". Recommend.
- **Prestige's numbers (D030):** credits formula, room prices, G16 at Level 8, G19's caps. Change any freely.
- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later.
- **The v0.6 split (D028)** and **E6's narrowing**: still open, low stakes.

## Next

1. Your call on U2 and U5, then the pacing suite goes green and #11 can merge.
2. Without them: W2 (sound and haptics), v0.6b part 2 (W12: Standard Operating Procedures; Tier 6 needs its recipes, G17), or the Shift Roster's rules with placeholder art (v0.7, G12 numbers assumed).

Touches: data (`rooms.json`), the rules (prestige, rooms, the cost formula, save v7), the HQ tab, tests (`prestige_tests.gd`, ui Q9), the capture tool, docs. Stubbed or open: W3–W12, G16–G19.
