# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D048 (PRs #1–#23), the last being Idle Planet Miner's opening ladder (Poblano $520, Jalapeño $1,700).

This branch is **v0.7 PR 1: the Idle Planet Miner skeleton, mapped (D049–D053).** Docs only, no game code. The owner asked to bring Idle Planet Miner's progression in whole and tweak from there, with more peppers by Scoville and fictional ones past Pepper Y, and took the agent's three recommendations: farms grow mixes of crops (D050), IPM's recipe graph with the brief's names on the closest slots (D051), and the kitchen stays as the tutorial (D052).

- [`docs/SKELETON.md`](SKELETON.md): the full mapping. 28 peppers (D053), 79 farms, 29 mashes plus the four ingredient mashes, 48 sauces, 25 Land Surveys, 30 adopted Tech Tree nodes, 10 vats and 10 lines, 15 HQ rooms. Also what's left out and what of ours stays, criteria I1–I14, the criteria retired before measuring, and everything assumed.
- [`docs/ipm_snapshot.json`](ipm_snapshot.json): the wiki's numbers as data, read 2026-10-23. `tools/ipm/` fetches the pages, parses them and rebuilds SKELETON.md's tables (and a `mapping.json` that PR 2 can turn into `data/*.json`).
- Backlog: G21–G25 (assumed IPM gaps, our own node costs, names, a trademark check), W34 (PR 2), W35 (PR 3), W36 (IPM left out for now).
- Roadmap: v0.7 is the skeleton; the Shift Roster moves to v0.8 and the Cook-Off to v0.9.

Tests and the headless boot run on this branch unchanged (no code touched); E6 still fails as on `main` (W30).

## Open decisions

- **Look over SKELETON.md before PR 2,** above all the assumed rows: farm names, the new pepper picks, Heat Death, rooms in IPM's fixed order instead of a random draft, Operation Value counted as Galaxy Value, recipes bought with cash.
- **W30, E6:** still open from #23. Recommend retiring E6.
- **W31** (the first sale at about 2:00 or about an hour) meets I6, which keeps 2:00–2:30. Say now if the hour stands, and I6 changes before PR 2 measures.
- Still open: W8 and W32–W33 (the look), W27 fermentation, W21, W24 (I9 now proposes a 60% floor), W22.

## Next

1. The owner reads SKELETON.md and merges PR 1 (or says what to change).
2. PR 2 (W34): build the copy, measure I1–I14, report every FAIL with a backlog row.
3. PR 3 (W35): the tweaks.

Touches: docs only (SKELETON.md new, ipm_snapshot.json new, DECISIONS D049–D053, BACKLOG, ROADMAP, INGREDIENTS note, AGENTS.md layout and sources), plus `tools/ipm/`. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, W30–W36, G1, G12–G14, G16–G25.
