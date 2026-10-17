# Handover

## Where it's at

v0.3 First Research is built (on top of v0.1 and v0.2, PRs #1–#3, still to merge):
- **Stage 3:** the nav bar at £400 Operation Value, with Processing open and the Tech Tree at £750. Shift Roster and HQ stay `[ ? ]`, and tapping one says when it opens. Operation Value shows under Cash.
- **Processing tab:** vat and line slots (caps 3 and 2), each running a picked recipe or switched off.
- **Tech Tree tab:** the web with seven nodes: Kitchen Table, Calloused Thumbs, the five Tier 2 blueprints and the Delivery Van with its Auto-Sell sliders.
- **Tier 2:** Jalapeño and White Vinegar plots, Pickled Brine, Verde Mash, and Bistro Verde (£25).
- **Data and saves:** game data lives in `data/*.json` behind a checking loader. Saves are v3, with the account (best Operation Value) kept apart from the run, and they migrate v1 and v2 saves.

Checks:
- All criteria pass: S1–S6, R1–R4, O8–O10, pacing N1–N8, and v0.2's F1–F8.
- 349 rule and screen checks.
- The headless boot is clean and the web export works.
- Every new screen was captured and looked at.

What moved to get there is in [FACTORY.md](FACTORY.md#what-moved-from-the-draft-each-change-measured): cheaper Tier 2, stronger Tier 2 plots, faster recipes, half the research cost, gentler upgrade scaling (D009), and Calloused Thumbs (D008).

## Open decisions

- **Confirm D008:** Calloused Thumbs was added to the slice so the button still counts at 30:00 (+17%; without it, 6%). Recommendation: keep it, since it's the brief's first North Wing node. The alternative is to lower N8 and F8 until v0.4.
- **W5, Shift Roster threshold:** £10,000 now arrives at 42:18, before the 45–60 minute target. It's fine to leave until v0.7 builds the tab.
- **G1, platform for testing** (unchanged): Web on the phone is recommended until v1.0.

## Next

1. Settle G9 (the rest of the tree) and G10 (Heat) for v0.4.
2. W1: open the Web build on a phone.

Touches: simulation (slots, recipes, research, Van, Operation Value, save v3), data files and loader, the screen (nav bar, Processing, Tech Tree web), the pacing player, docs. Stubbed or open: W1–W6, Shift Roster and HQ tabs (v0.6, v0.7). Next: G9/G10, because v0.4 can't be built without them.
