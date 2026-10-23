# Plan: autonomous session, 23 October 2026

Written before coding. The repo's own memory (`docs/HANDOVER.md`, `docs/BACKLOG.md`, `docs/DECISIONS.md`) stays the record; this file is the session's plan and what came of it.

## Where things stand

- `main` is v0.6d (D041, D042): all suites pass, the headless boot is clean, no open issues.
- **Two open PRs carry the newest work and aren't merged:** #20 (D043 Cargo, D044 the dashboard from the first launch with the next action ringed, D045 bottling feel; its next step is "W28's early-game pass") and #21 (the pixel-art skin trial). Both rewrite `src/ui/main.gd` heavily.
- I tried to stack this branch on #20 and was blocked, so this branch is cut from `main`. To keep merges painless I stay out of the code #20 and #21 rewrite: small, local UI edits at most, the rest in core, tests and docs.
- **Id clash to know about:** #20 and #21 both use D043, and both use W28 and W29 for different things. Whichever merges second needs renumbering. This branch uses D046 and W31 onwards, and criteria J1–J3, so it clashes with neither.

## Playing the first 30 minutes (casual phone player, measured)

- 0:00–1:06 tapping to the deck, vat 1:40, line 3:16 (a 96 s wait, E3's tightest spot), Poblano Plot 4:28, Jalapeño Plot 9:06, Tech Tree 12:00, then research every 30–60 s to 30:00. Upgrades fill the gaps. That cadence mostly meets the 30–60 s guide; the 1:40–3:16 wait and 4:28–9:06 between plots (upgrades only) are the flat bits, and #20 already lists the second plot as W28.
- **Sell Batch is a chore until the Delivery Van (about 18–20 min):** the casual player taps it every 6–8 s. That's the brief (§3) and Idle Planet Miner sells by hand too, so noted, not changed.
- **Coming back before the Delivery Van says "+$0.00 cash".** Time away does make things (an 8-hour night at 8:00 leaves $56k of Table Mild and $17k of raw crops), but nothing sells itself, so the card leads with zero. That's the worst first impression of offline earnings the game can give, and it lands exactly in the first session.
- **Nothing to save towards before Stage 3 (about 6:30):** the goal bar only shows from the nav bar on. #20's ringed next action covers this, so I leave it.
- **The first sale is at about 2:02 (pacing player), not about an hour.** That's the owner's own choice (D035: "the run keeps v0.6a's pace", sale bar 2:00–2:30), so it's a decision for the owner, not something to retune silently.

## Order of work

1. **The return card says what's waiting to sell** (criteria J1–J2 first). Fixes the "+$0.00" return in the first 20 minutes; core helper plus one card line, so it's cheap and won't fight #20/#21.
2. **Cadence criterion for 15–30 minutes, casual player** (J3). E3 stops at 15:00 and N6 only measures the flat-out player; the 10–30 minute window the owner cares about has no casual bar. Measure; a FAIL gets a backlog row, not a quiet retune.
3. **First prestige timing: numbers and a recommendation for the owner** (docs only). Changing it means moving D035's bars, U1, Y1–Y4 and the credit table, which is a big rebalance on top of #20's early-game changes: the owner's call.
4. **Hand-off:** handover, backlog rows, PR to `main`, Haiku review.

## Considered and left

- **W28, a faster second plot:** it's #20's next step and its A4 bar is a second from failing there; tuning plot prices on `main` now would conflict and be re-measured anyway. Do it on top of #20 once merged.
- **Auto-selling bottles while away before the Van:** would make the return pay cash, but it changes what the Delivery Van is for (a research reward). The card fix gets most of the feel for none of the design change; flagged as an option.
- **Pinning the first sale to about an hour:** see step 3.
- **New dependencies or architecture:** none planned.

## What came of it

1. Done: D046, J1–J2 PASS.
2. Done: J3 PASS (48 s against 120), so no tuning.
3. Written up as W31 in PRESTIGE.md, for the owner.
4. PR opened and reviewed (see the PR).
