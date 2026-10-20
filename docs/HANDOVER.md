# Handover

## Where it's at

Merged: v0.1–v0.6c (PRs #1–#14): the full first run, Prestige with the 12 HQ rooms, Standard Operating Procedures and Tier 6, the click and buzz, and Idle Planet Miner's values in dollars (D035). This branch settles v0.6c's three pacing FAILs (D036), so CI goes green again:

- **N5:** the 50:00 bar is $150,000 (it was converted too high at $200,000); reached at 49:06.
- **M2** (first Classic Louisiana by 55:00) is retired; U3 holds the same sauce to its time.
- **U5:** the pacing player's Savina Gold layout gets a second Garlic Paste vat. The 402 s wait was a Louisiana line starved of Paste, not the Sweet Heat lending I first blamed.

Checks: `bash run_tests.sh` passes all ten suites (pacing 38 of 38); the headless boot is clean. No screen change.

## Open decisions

- **Late growth (W21):** after Phantom the run is worth $757M by 3:15 (51 credits). Fine as "push on for more", or cap it? Recommend deciding with W17, a pacing player that sells and replays.
- **D034's and D030's assumptions** (SOP's bar, Tier 6, Prestige rooms) and **W8** (needs your reference games).

## Next

1. Merge this PR, then try the phone build (W16; the link still runs the £ version until it's re-published).
2. Give each finished bottle a visible moment (the bottle and its value popping out, a sound): small, and doesn't need W8.
3. W17 (second-run pacing), then v0.7 Shift Roster.

Touches: `tests/pacing_tests.gd` (N5's bar, M2 retired), `src/sim/engaged_player.gd` (one layout), docs. Stubbed or open: W3–W6, W8–W9, W15–W17, W21, G1, G12–G19.
