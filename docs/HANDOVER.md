# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D045 (PRs #1–#20): Idle Planet Miner's early flow, the pepper ladder, Cargo in place of Crop Quality (D043), the dashboard from the first launch with the next action ringed (D044) and bottling feel (D045). **Open:** #21, the pixel-art skin trial, which also uses D043 and W28–W29 for different things and needs renumbering before it merges.

**`main` fails two pacing criteria since #20, each by one unit:** A4 (6:31 against 6:30, W29) and E6 (9 mash against 10, W30). CI is red on `main` and every branch from it until they're settled.

This branch is an autonomous first-session pass ([PLAN.md](../PLAN.md)), now merged with `main`:

- **D046, the return card says what's waiting to sell.** Before the Delivery Van nothing sells while away, so every return in the first 20 minutes read "+$0.00 cash". The card now shows "+$X of sauce waiting: tap Sell Batch" and hides a zero cash line. J1–J2 PASS ([OFFLINE.md](OFFLINE.md#the-return-before-the-delivery-van-d046)).
- **J3, the 15–30 minute window for the casual player:** longest wait 50 s against a bar of 120. PASS ([FACTORY.md](FACTORY.md#the-1530-minute-window-j3-this-session)).
- **W31, when the first sale comes:** measured and written up with options, not built ([PRESTIGE.md](PRESTIGE.md#when-the-first-sale-comes-w31-a-proposal-not-built)).

**Results:** every suite passes except A4 and E6, as on `main`; the headless boot is clean; the card was checked on the new dashboard in `tools/capture_ui.gd`'s `j1_return.png`.

## Open decisions

- **W29 and W30 (A4, E6):** both miss by one unit. Recommend settling them in W28's early-game pass (the second plot feels slow), or move A4's bar to 7:00 as W29 suggests.
- **W31:** first sale at about 2:00 (D035) or about an hour (the owner's message for this session, not in the repo; it contradicts D005). Recommend an early sale at about $400K for 5 credits if the hour stands.
- **Before the Van, sell while away?** D046 shows the waiting sauce; actually selling it would change what the Delivery Van is for. Recommend the card alone.
- **#21 and W8:** keep, swap or replace the pixel kit.
- Still open: W27 fermentation, W21 late growth, W24 a floor for repeat runs, layout step 3 (W22, waits on W8).

## Next

1. The owner settles W29/W30 (CI goes green) and merges this PR.
2. W28's early-game pass; W31 once the owner picks.

Touches (this branch): `game.gd` (`bottles_waiting` in the catch-up report), `main.gd` (the card's waiting line), `tools/capture_ui.gd` (`j1_return.png`), `tests/ui_tests.gd` (J1–J2), `tests/pacing_tests.gd` (J3; the early harness runs 30 minutes), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27–W31, G1, G12–G20.
