# Handover

## Where it's at

Merged: v0.1–v0.6c, D036–D042, layout step 1 and the second run (PRs #1–#19). This branch is **the pixel-art trial** (W8, D043, [LOOK.md](LOOK.md)): the owner chose pixel art as the game's look, and the trial puts a ready-made pixel UI skin over today's screen to see whether it carries the game.

- **The kit:** Pixel UI Free by heyheythere (CC BY 4.0), wood theme, copied unchanged into `addons/pixel_ui/`. `src/ui/pixel_kit.gd` builds a 2× copy of its theme so pixels stay square on the 540×960 screen. Nearest filtering everywhere.
- **Font:** the kit's bitmap font at 16 and 24 px. The five characters it lacks (ñ × · → −) are drawn to match in `assets/fonts/pixel_extra` (`tools/make_pixel_glyphs.gd`).
- **The Blank Button** is a pixel disc, 70 px across, drawn at 4× and 2× (compact is now 140 px).
- **Layout knock-ons** for a wider font: Tech Tree nodes bigger; "Roster" on the nav; Sell Raw Peppers on two lines; titles, the goal line and Market rows wrap.
- **The credit line** is in the Settings card and the README.

**Results:** PX1–PX7 PASS. `tests/look_tests.gd` (new, 7,537 checks) walks the real screen at 17 stages. Every suite passes and the headless boot is clean. PX6 was tightened after the first captures, which is recorded in LOOK.md. PX8 (does it look like a 2026 mobile game?) is the owner's: [before and after](look/trial_before_after.png).

The Web build loads and plays in a browser; at phone size the pixels come out uneven (W28, as expected). Found on the way: the texture-scaling bug and the "headless isn't the phone's shape" trap, both in [LOOK.md](LOOK.md#results).

## Open decisions

- **PX8 and the kit (W8):** keep this free wood kit, buy the full pack (ember suits hot sauce better, same files), or have UI art made in our own palette. Recommend: judge it on the phone first.
- **Mixed scales:** headlines at 3× text beside 2× borders. Say if you'd rather everything at 2×.
- **W28:** whole pixels on the phone need Godot's integer stretch, which changes how much screen we get. Check on the next phone test.
- **W29:** who draws the game's own art (peppers, bottles, factory floors, managers) and at what pixel density. The PixelLab pepper in Downloads is a finer density than the UI's 2×.
- Still open from before: thin margins on the sale and E3, W21 late growth, W24 a floor for repeat runs.

## Next

1. The owner looks at the before and after, then plays the Web build on the phone (`bash tools/serve_web.sh`).
2. Then keep, swap or replace the kit (W8). Layout step 2 (W22) follows once the look is settled.

Touches: `project.godot` (Nearest filter), `addons/pixel_ui/` (new), `assets/fonts/` (new), `src/ui/pixel_kit.gd` (new), `style.gd` (palette, sizes), `main.gd` (kit boxes, wraps, nav names, web frames, credit), `tests/look_tests.gd` (new), `ui_tests.gd` (O4's two-line button), `tools/make_pixel_glyphs.gd` (new), docs. Stubbed or open: W3–W6, W8–W9, W16, W21–W22, W24, W27–W29, G1, G12–G20.
