# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D047 (PRs #1–#22): Cargo (D043), the dashboard from the first launch (D044), bottling feel (D045), the return card's waiting sauce (D046) and the pixel-art skin (D047).

This branch is **the early-game pass on Idle Planet Miner's opening ladder (D048, W28–W30)**, as the owner asked:
- **Poblano Plot $520 (was $800), Jalapeño Plot $1,700 (was $1,900)**, rates unchanged. Idle Planet Miner's first planets go $200, $500, $1,250, $5,000, ×2–4 a step; ours went ×16 from Bell to Poblano, then left a gap after the Jalapeño Plot.
- **A7 PASS:** the casual player's second plot at 3:18 (was 3:54). **A8 PASS:** ×3.3, paybacks 5:12 and 8:30. **A4 PASS:** 6:19 (was 6:31, W29 closed).
- **A fourth starting plot was tried and dropped:** a Serrano Plot at $5,000 never got bought early, and cheaper ones paid back in under 4 minutes.
- **Also restored:** D046's entry in DECISIONS.md and the W31 backlog row, which #22 merged without (its code and OFFLINE.md criteria did merge), and the #21 review's doc fixes, pushed after #21 merged.

**E6 retired** by the owner (D049): prices couldn't pass it without failing E3; the suite still prints it (9).

**Results:** every suite passes; the headless boot is clean. $520 was picked over $500 after $500 failed X3 by 0.05 points: said in D048. No UI code changed.

## Open decisions

- **W31:** the first sale at about 2:00 (D035) or about an hour. Recommend an early sale at about $400K for 5 credits if the hour stands.
- **W8, the kit:** keep the free wood kit, buy the full pack (ember), or commission UI art; W32 integer stretch, W33 who draws the art.
- Still open: W27 fermentation, W21 late growth, W24 a floor for repeat runs, layout step 3 (W22).

## Next

1. The owner merges this PR (CI should go green).
2. Fermentation (W27), W31 or layout step 3, whichever the owner picks.

Touches: `data/plots.json` (Poblano, Jalapeño prices), `tests/pacing_tests.gd` (A7), `tests/factory_tests.gd` (A8), docs (ECONOMY v0.6f, D046 restored, D048, backlog). Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, W31–W33, G1, G12–G20.
