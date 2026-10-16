# Handover

## Where it's at

Built: v0.1–v0.4 (PRs #1–#6, waiting to merge); v0.4 details in [ECONOMY.md](ECONOMY.md#results-v04). W7 (the run is ahead of the 3-hour curve) is left for v0.6, as agreed.

This branch is design only: G11 is settled and v0.5 Offline is drafted ([OFFLINE.md](OFFLINE.md)).
- **D018, cap and speed:** 4 hours at 50% to start. Night Shift Protocols I–II add +2 h and +10 points each, giving 8 h at 70%.
- **D019, while away:** production only. Heat falls to 0, the Piston keeps pressing, nothing is bought or pressed for the player, timers keep wall-clock time, and missed spikes are missed.
- **D020, the catch-up:** run 5 real minutes, measure, scale to the rest. When a pile would run dry it re-measures, up to 4 times. Stock is never negative, and the result is deterministic.
- **D021, counting as away:** the app was closed, or the screen didn't run for over 10 s. The device clock is used; a clock that went backwards counts as no time.
- **Also drafted:** the "While you were away" card, save v5 (`saved_at`), two Night Shift nodes (W5, W6), and criteria X1–X8, P1–P2.
- **New gap G16:** the brief's Night Watchman's Desk can't be both "+1 hour a level, hard cap Lv 15" and "+8 hours max". It's for v0.6.

## Open decisions

- **Review the v0.5 draft.** X3's 2% accuracy bar and P1/P2's targets are mine; the Night Shift costs are starting guesses.
- **G1, platform for testing** (unchanged): Web on the phone is recommended until v1.0. v0.5 is where it matters most, since a phone really does pause the game in the background (W1).

## Next

1. Build v0.5 against X1–X8 and P1–P2, with F, N and M kept.
2. W1: open the Web build on a phone, ideally with v0.5's offline catch-up.

Touches: docs only (D018–D021, OFFLINE.md, the tree, roadmap, backlog). Stubbed: none new; G16 added. Next: build v0.5, since every gap it needs is settled.
