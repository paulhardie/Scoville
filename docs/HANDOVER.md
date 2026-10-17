# Handover

## Where it's at

Merged: v0.1–v0.5.1 (PRs #1–#9) and the pepper ladder design (PR #10). Open: PR #11 (green): Forager's Luck, D024–D027, the v0.6a design and v0.6a stage 1. **Not pushed:** v0.6a stage 2 (the pacing player and tuning), committed locally because its pacing criteria fail while tuning and would turn #11 red.

**v0.6a, the full run ([FULL_RUN.md](FULL_RUN.md)), is being built.** Stage 1 (data, the fork rule, the Pantry's effects, V1–V7) is in. Stage 2: the pacing player plays the whole ladder; tuning has three open questions (FULL_RUN.md's build log). v0.6 is split in two (D028): v0.6a takes the first run to £1M in about 3 hours; v0.6b is Prestige.
- **A ten-rung sauce ladder** climbing about ×2.2 a rung, from Table Mild £5 to Phantom Smokehouse £5,200. The ladder's new peppers each get a mash and an in-between sauce (D029, G17 assumed): Smoky Ancho £10.50, Serrano Fire £60, Cajun Red £280, Island Heat £500, Savina Gold £2,000.
- **Pickled Brine as the base that grows with heat,** and the Pantry branch: booster, concentrate, then a Bulk or Reserve fork per ingredient (G18 assumed).
- **9 stations, 46 nodes,** Slot Expansion III–IV, Artisan Decanters, two GMO boosters.
- **Criteria U1–U9,** including the first "not before" bounds on the curve (£100k between 1:35 and 1:55, £1M between 2:45 and 3:15) and "a night at 1:40 doesn't reach £1M" (W7).

Checks: every rule suite passes; the pacing suite fails as listed in the build log.

## Open decisions

- **v0.6a tuning (FULL_RUN.md build log):** (1) slot upgrades priced by what the slot makes, changing D009; (2) move U8 to "from 1:20"; (3) narrow U4 to Classic Louisiana and Pickled Brine, retiring M6.
- **The v0.6 split (D028):** fine as two halves?
- **G8 and G16, for v0.6b:** Franchise Credits, HQ room costs, the draft, and Night Watchman's Desk.
- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later.
- **E6 was narrowed** to the casual player after measuring. Say if you'd rather the eager player saw a bigger crate moment too.

## Next

1. Answer the three tuning questions, then tune v0.6a against U1–U9 and the earlier criteria (W10).
2. Then G8 and G16 for v0.6b, or W8 if references arrive first.

Touches: data (v0.6a content, repriced blueprints), the rules (forks, Bulk, Concentrate, Reserve), the UI text, the pacing player, pacing tests (to 3:15, U1–U8), full_run_tests (V1–V7), docs. Stubbed or open: W3–W10, G8, G16–G18.
