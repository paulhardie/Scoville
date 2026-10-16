# Backlog

Everything adopted and not done, one row each. Gaps (G) are things the brief leaves open that a version needs settled; work rows (W) are things to build or check. Update the status when a row moves; delete it when it's done and the handover says so.

## Gaps in the brief

| Id | Gap | Needed by | Status |
| --- | --- | --- | --- |
| G1 | Platform: native iOS and Android builds, or the Web build (as a phone PWA) until v1.0? Native needs Xcode, the Android SDK and signing. | v1.0 (testing now) | Open: recommend Web for testing, native from v1.0 |
| G2 | Title: the brief says Hot Sauce Empire, the repository is Scoville. | — | Assumed: the game is Hot Sauce Empire, the project is Scoville |
| G4 | Farm, vat and line numbers: cycle times, yields, prices and upgrade curves are drafted in [FACTORY.md](FACTORY.md) and pass its criteria. Still open: what Crop Quality Chance does. | v0.2 (review); v0.4 (Crop Quality) | Drafted: owner to review |
| G5 | Operation Value thresholds that unlock tabs 2–4 (only HQ's £1,000,000 is given). | v0.3 | Open |
| G6 | Value of raw crops and mashes, for Operation Value's "stockpiled inventory" (only bottle values are given; raw Bell Pepper sells at £0.10). | v0.3 | Open |
| G7 | Carolina Reaper is in the crop list but has no recipe; are there tiers past 5? | v0.3 | Open |
| G8 | Franchise Credits formula ("scaled logarithmically"), HQ room level costs, and when a room draft is offered. | v0.6 | Open |
| G9 | Tech Tree: the full node list per wing, each node's item cost, and which nodes connect. | v0.4 | Open |
| G10 | Heat meter: build and decay rates, and how "+50% while maintained" scales between 0 and 100%. | v0.4 | Open |
| G11 | Base offline cap and offline speed before upgrades. | v0.5 | Open |
| G12 | Golden Seeds: amounts per source, pack price, rarity drop rates, slot prices, duplicates per star, Mastery costs. | v0.7 | Open |
| G13 | Manager art: who makes it and in what style. | v0.7 | Open |
| G14 | Cook-Off reward table: Golden Seeds and Ribbons per threshold. | v0.8 | Open |

## Work

| Id | What | Status | Needs |
| --- | --- | --- | --- |
| W1 | Open the Web build on a phone (it exports cleanly; not yet tried on a device) | Not started | `bash tools/serve_web.sh` and a phone on the same Wi-Fi |
| W2 | Sound and haptics for the button press | Not started | Nothing |
| W3 | Pacing at 15 minutes: F6 passes with 87 s of 90 and F4 with 28 s to spare, so small retunes may break them | Watch | Re-run `tests/pacing_tests.gd` after any change to `tuning.gd` |
| W4 | The pacing player buys the cheapest upgrade, not the bottleneck; a smarter player would progress faster, so the criteria are measured against a fairly naive one | Open | A second, bottleneck-aware player if pacing needs a range rather than one figure |
