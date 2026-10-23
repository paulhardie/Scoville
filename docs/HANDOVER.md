# Handover

## Where it's at

Merged: v0.1–v0.6d, layout step 1, the second run, D036–D045 (PRs #1–#20): Cargo in place of Crop Quality (D043), the dashboard from the first launch with the next action ringed (D044), bottling feel (D045). Open beside this one: #22 (the return card shows sauce waiting to sell, D046; J3; the W31 first-sale proposal).

**`main` fails two pacing criteria since #20, each by one unit:** A4 (6:31 against 6:30, W29) and E6 (9 mash against 10, W30). CI stays red on `main` and every branch from it until they're settled.

This branch is **the pixel-art trial** (W8, D047, [LOOK.md](LOOK.md)), now merged with `main`: the owner chose pixel art as the game's look, and the trial puts a ready-made pixel UI skin over the real screen to see whether it carries the game.

- **The kit:** Pixel UI Free by heyheythere (CC BY 4.0), wood theme, copied unchanged into `addons/pixel_ui/`. `src/ui/pixel_kit.gd` builds a 2× copy of its theme so pixels stay square on the 540×960 screen. Nearest filtering everywhere.
- **Font:** the kit's bitmap font at 16 and 24 px, with the five missing characters drawn to match (`tools/make_pixel_glyphs.gd`).
- **The Blank Button** is a pixel disc, 140 px on the dashboard.
- **On the dashboard (after the merge):** the factory view in the wood palette with its floor names at the right, 64 px tab selectors, a square 4 px ring round the next action. PX4 was narrowed to let that outline through ([LOOK.md](LOOK.md#after-merging-20-d043d045-on-main)).

**Results:** PX1–PX7 PASS; every suite passes except A4 and E6, as on `main`; the headless boot is clean and the captures were looked at. PX8 (does it look like a 2026 mobile game?) is the owner's: [before and after](look/trial_before_after.png), taken before the dashboard.

## Open decisions

- **PX8 and the kit (W8):** keep this free wood kit, buy the full pack (the ember theme suits hot sauce better, same files), or have UI art made in our own palette. Recommend: judge it on the phone first.
- **Mixed scales:** headlines at 3× beside 2× borders.
- **W32:** whole pixels on the phone need Godot's integer stretch. **W33:** who draws the game's own art, and at what pixel density.
- **W29 and W30 (A4, E6):** settle in W28's early-game pass, or move A4's bar to 7:00.
- Still open: W31 the first sale (on #22), W21 late growth, W24 a floor for repeat runs.

## Next

1. The owner plays the Web build on the phone (`bash tools/serve_web.sh`), then keeps, swaps or replaces the kit (W8).
2. Layout step 3 (W22) once the look is settled.

Touches: `project.godot` (Nearest filter), `addons/pixel_ui/`, `assets/fonts/`, `src/ui/pixel_kit.gd`, `style.gd`, `main.gd` (kit boxes, wraps, nav names, the factory view's pixel dress), `tests/look_tests.gd`, `ui_tests.gd` (O4, L10, L11), `tools/make_pixel_glyphs.gd`, docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27–W30, W32–W33, G1, G12–G20.
