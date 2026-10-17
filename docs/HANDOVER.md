# Handover

## Where it's at

v0.5 Offline is built, on top of v0.1–v0.4 (PRs #1–#7, still to merge).
- **Time away:** closing the app, or the screen not running for over 10 s (a phone backgrounding the tab), counts as away. It counts for up to 4 hours at 50% speed; Night Shift Protocols I–II (West Wing) take that to 8 hours at 70%.
- **The catch-up** runs the real rules in up to 4,000 longer steps (D020, revised: see below). Timers keep wall-clock time, and missed Market spikes are skipped.
- **The return card** shows the time away, the cap note, the cash, the rise in Operation Value and the top three items.
- **Saves** are v5 and carry `saved_at`.

Checks:
- All criteria pass: X1–X8, P1–P2, and F1–F8, N1–N8, M1–M7.
- 552 rule and screen checks.
- The headless boot is clean and the web export works.
- The card was captured and looked at.

**What moved from the draft:** the catch-up method. Measuring 5 minutes and scaling them missed the 2% accuracy target three ways (pins, buffers, a growing factory), up to 14% off. Running the real rules in longer steps measures within 0.74%. Speeding that up to 0.38 s for 8 hours took three changes:
- caching what research decides;
- batching harvests and cycles within a step;
- noting Operation Value once per step instead of after every sale, which also speeds up normal play.

Details: [D020](DECISIONS.md), [OFFLINE.md](OFFLINE.md#results-v05).

## Open decisions

- **W7, now with offline in it:** one night away from 1:40 adds £3.2M, past the £1M Prestige line. Agreed for v0.6: set the whole curve with "not before" bounds, offline included.
- **W1, the phone:** v0.5 is the version most worth trying on a phone. The catch-up's speed there, and how the browser pauses the tab, are both unmeasured.
- **G1, platform for testing** (unchanged): Web on the phone is recommended until v1.0.

## Next

1. W1: open the Web build on a phone (`bash tools/serve_web.sh`).
2. Settle G8 and G16 (Franchise Credits, HQ room costs, Night Watchman's Desk) for v0.6 Prestige, with W7's whole-curve work.

Touches: simulation (stepped `_step`, the catch-up, Night Shift, save v5), the screen (clock, return card), tests, docs. Stubbed or open: W1–W7, G16. Next: W1, then G8/G16, because v0.6 needs them.
