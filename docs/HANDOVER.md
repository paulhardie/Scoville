# Handover

## Where it's at

Merged: v0.1–v0.6b (PRs #1–#13): the full first run, Prestige with the 12 HQ rooms, Standard Operating Procedures and Tier 6, and the click and buzz. This branch is **v0.6c (D035): Idle Planet Miner's numbers in dollars** ([ECONOMY.md](ECONOMY.md#v06c-idle-planet-miners-values-in-dollars-d035)).

- **Every pepper copies an ore:** Bell Pepper is Copper $1, up to Pepper X as Osmium $7,800 ([INGREDIENTS.md](INGREDIENTS.md)). Ingredients take the ore of their nearest pepper (assumed). Bottles follow D004: Table Mild $50, Classic Louisiana $3,950, Phantom $330,250.
- **Money is dollars** on screen and in the rules (AGENTS.md updated).
- **Prices re-tuned by tier** so the run keeps v0.6a's pace: every sauce arrives on time.
- **The first sale is Idle Planet Miner's:** $10M for 10 credits, then its credit table (30 at $100M). It arrives at about 2:08; by 3:00 a run is worth about $110M (30 credits).
- **The Tier 6 sauce Event Horizon is now Extinction Event** (the last fictional pepper is called Event Horizon).
- **Save v8:** older saves' money ×10, converted once. Two migration bugs found and fixed on the way (a v2 save's stock counted twice; a v1 save losing its deck).

Checks: every rule suite passes; pacing is **36 of 39**, with three FAILs (below); the headless boot is clean; dollars and the HQ sale looked at with `capture_ui.gd`. A night now starts with slots set up the way the player runs them (a measurement fix: it used to start with lines lent away).

**FAIL:**
- **N5:** $200k at 53:20, not by 50:00. My conversion of the old £10k bar (×20) was too high; $150k would pass (W18).
- **M2:** the first Classic Louisiana 51 s late (55:51); U3 for the same sauce passes (W19).
- **U5:** one 402 s wait on Glaze, a pacing-player lending quirk (W20).

**Not bounded:** after Phantom the run grows fast ($723M at 3:15, 51 credits). Nothing caps it now that U1 stops at the sale (W21).

## Open decisions

- **N5's bar:** accept $150,000 (recommended), or tune Tier 2 faster.
- **Late growth (W21):** is $700M by 3:15 fine (push on for big credits, as in Idle Planet Miner), or should Phantom-era growth be capped? Recommend deciding with W17, a pacing player that sells and replays.
- **D034's and D030's assumptions** still stand (SOP's bar, Tier 6, Prestige rooms).
- **W8, the visual pass:** needs your reference games.

## Next

1. Merge this PR once you're happy with the three FAILs' explanations, then try the phone build (W16).
2. Give each finished bottle a visible moment (a popped bottle and its value, a sound): suggested after the "is making a bottle enjoyable?" question; small, and doesn't need W8.
3. W17 (second-run pacing), then v0.7 Shift Roster.

Touches: data (values, prices, rooms' Seed Capital ×10, the rename), `tuning.gd` (thresholds, upgrade bases, COST_SCALE_POWER, PRESTIGE_OV, CREDIT_TABLE, SAVE_V8_MONEY), `game.gd` (credits, cost scale, save v8), the money display, every test suite, the capture tool, docs. Stubbed or open: W3–W6, W8–W9, W15–W21, G1, G12–G19.
