# Handover

## Where it's at

Merged: v0.1–v0.6a and v0.6b part 1 (PRs #1–#11): the full first run to £1M in about 3 hours, and Prestige with the 12 HQ rooms. This branch adds **W2, sound and haptics, built** ([FEEL.md](FEEL.md)), and fixes the stock line running over the Blank Button.

**Sound and haptics:**
- **A click on each finger press of the Blank Button.** The tone is made in code. Its pitch varies ±8% and rises up to +20% with Heat.
- **A 15 ms buzz on phones that support it.**
- **Grip and Piston presses stay silent and still.**
- **Sound and Vibration switches** in a Settings card at the foot of Farms, kept in `user://settings.json` (not the game save).
- K1–K5 pass in `ui_tests.gd`.

**The stock line:** with v0.6a's 30 items it wrapped to six lines over the button. It's now capped at three lines, most important first. Still crowded (W15, for the visual pass).

Checks: `bash run_tests.sh` passes all ten suites; the headless boot is clean; Settings and the stock line looked at with `capture_ui.gd`. **Not checked:** how the click sounds and the buzz feels on a real phone (W16).

## Open decisions

- **Prestige's numbers (D030):** credits formula, room prices, G16 at Level 8, G19's caps. Change any freely.
- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later. The crowded stock line (W15) joins it.

## Next

1. Merge this PR, then try the Web build on your phone for the click and buzz (W16).
2. Then v0.6b part 2 (W12: Standard Operating Procedures; Tier 6 needs recipes for Moruga Scorpion and Pepper X, G17), or the Shift Roster's rules with placeholder art (v0.7), or W8 once you've sent references.

Touches: the screen (click, buzz, Settings card, stock line), `style.gd` (feel constants), three item short names, ui tests (K1–K5), the capture tool, docs. Stubbed or open: W3–W6, W8–W9, W12, W15–W16, G1, G12–G19.
