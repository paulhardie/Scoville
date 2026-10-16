# Handover

## Where it's at

v0.1: the prototype's Day-1 loop runs in Godot (picking, heat and Flash Boil, loose sales, Table and Smoky Sauce, shears, pickers, the capper and the jalapeño patch), with a save that autosaves every 3 s and on close. The rules live in `src/core/game.gd`, and 277 checks cover them and the screen. The headless boot and the Web export both work. CI runs the tests and the boot on every push to `main`.

## Open decisions

- **B1: should heat multiply taps?** The prototype displayed a multiplier it never applied. Recommendation: apply it (1.0× to 1.8× by heat). It gives a reason to keep tapping between boils; the cost is a faster early game, which needs B7's criteria to judge.

## Next

1. B7: set first-session pacing targets, so retuning has something to measure against.
2. B1, once B7 exists.
3. B6: open the Web build on a phone.

Touches: everything (first commit). Stubbed: B2–B5 (not ported), B6 (not checked on a device). Next: B7, because every tuning change needs it.
