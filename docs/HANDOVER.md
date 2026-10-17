# Handover

## Where it's at

v0.2 Operation Deck ([FACTORY.md](FACTORY.md)), on top of v0.1 ([ONBOARDING.md](ONBOARDING.md)):
- At £10 earned, the Blank Button compresses into the upper 35% of the screen and the Farms deck slides up from below.
- The deck has the Tier 1 spine: Bell Pepper Plot → Sweet Pepper Mash vat → Table Mild line.
- The line comes with a Starter Crate of 50 fast bottles.
- Sell Batch sits beside the button.
- Speed and yield upgrades are bought with cash.
- Saves are version 2 and migrate v1 saves.

Checks:
- All eight pacing criteria pass: the line by 4:32, an upgrade at least every 87 s to 15:00, and tapping still adds 31% at 15:00.
- 141 rule and screen checks pass.
- The headless boot is clean.
- Every stage was captured and looked at.

The numbers are a draft for review (G4).

## Open decisions

- **Review the v0.2 numbers in [FACTORY.md](FACTORY.md#numbers-draft-for-review).** They pass the criteria, but the criteria are mine too (F1–F8). Change either, and `tests/pacing_tests.gd` will say what moves.
- **G1, platform for testing:** the Web build on a phone until v1.0 (recommended; nothing to install), or native iOS and Android builds from now on.

## Next

1. Settle G5–G7 (tab thresholds, raw and mash values, tiers past 5), then build v0.3 (Full Navigation).
2. W1: open the Web build on a phone.

Touches: the simulation (stations, tick, save v2), the screen (split viewport, deck, cards), the pacing player and its criteria. Stubbed: Crop Quality Chance, parallel slots and packaging (later versions, G4), W1–W4. Next: G5–G7, because v0.3 needs them.
