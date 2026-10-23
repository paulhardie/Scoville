# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D042 (PRs #1–#19). **Open and not merged:** #20 (D043 Cargo, D044 the dashboard from the first launch, D045 bottling feel) and #21 (the pixel-art skin trial). Both use D043, and W28–W29 for different things, so whichever merges second needs renumbering.

This branch, cut from `main`, is an autonomous first-session pass ([PLAN.md](../PLAN.md)):

- **D046, the return card says what's waiting to sell.** Before the Delivery Van nothing sells while away, so every return in the first 20 minutes read "+$0.00 cash". The card now shows "+$X of sauce waiting: tap Sell Batch" and hides a zero cash line. J1–J2 PASS ([OFFLINE.md](OFFLINE.md#the-return-before-the-delivery-van-d046)).
- **J3, the 15–30 minute window for the casual player:** longest wait 48 s against a bar of 120. PASS; nothing to tune ([FACTORY.md](FACTORY.md#the-1530-minute-window-j3-this-session)).
- **W31, when the first sale comes:** measured and written up with options, not built ([PRESTIGE.md](PRESTIGE.md#when-the-first-sale-comes-w31-a-proposal-not-built)).

**Results:** every suite passes, the headless boot is clean, and the new card was looked at in `tools/capture_ui.gd`'s `j1_return.png`. Code merges cleanly with #20 and #21; `docs/BACKLOG.md` and `docs/DECISIONS.md` conflict only where both append rows (keep both).

## Open decisions

- **W31:** first sale at about 2:00 (D035) or about an hour (the owner's pacing guide). Recommend an early sale at about $400K for 5 credits if the hour stands.
- **Before the Van, sell while away?** D046 shows the waiting sauce; actually selling it while away would change what the Delivery Van is for. Recommend the card alone.
- Still open: W28 (the second plot feels slow; on #20), W21 late growth, W24 a floor for repeat runs, thin margins (E3 casual 96 s of 100, the sale 1:56 inside its floor).

## Next

1. The owner merges #20 and #21 as they choose, then this PR (or this one first: the code doesn't overlap).
2. W28's early-game pass on top of #20; W31 once the owner picks.

Touches: `game.gd` (`bottles_waiting` in the catch-up report), `main.gd` (the card's waiting line), `tools/capture_ui.gd` (`j1_return.png`), `tests/ui_tests.gd` (J1–J2), `tests/pacing_tests.gd` (J3, the early harness runs 30 minutes), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27, W31, G1, G12–G20.
