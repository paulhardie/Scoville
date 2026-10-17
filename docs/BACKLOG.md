# Backlog

Everything adopted and not done, one row each. Gaps (G) are things the brief leaves open that a version needs settled; work rows (W) are things to build or check. Update the status when a row moves; delete it when it's done and the handover says so.

## Gaps in the brief

| Id | Gap | Needed by | Status |
| --- | --- | --- | --- |
| G1 | Platform: native iOS and Android builds, or the Web build (as a phone PWA) until v1.0? Native needs Xcode, the Android SDK and signing. | v1.0 (testing now) | Open: recommend Web for testing, native from v1.0 |
| G2 | Title: the brief says Hot Sauce Empire, the repository is Scoville. | — | Assumed: the game is Hot Sauce Empire, the project is Scoville |
| G15 | Vat and line slots: the brief has "Parallel Vat Slots" as a cash knob and Slot Expansion as a Tech Tree unlock, but no base cap. Built as 3 vat and 2 line slots in run 1, each assigned a recipe ([FACTORY.md](FACTORY.md#v03-slots-recipes-and-tier-2)). | v0.3 | Built as assumed; owner approved the draft |
| G8 | Franchise Credits formula ("scaled logarithmically"), HQ room level costs, and when a room draft is offered. | v0.6 | Open |
| G16 | Night Watchman's Desk: the brief says "+1 Hour Offline Cap" a level with a "Hard Cap Lv 15 (+8 Hours max)". Fifteen levels of +1 hour is 15 hours, so the two can't both hold | v0.6 | Open |
| G12 | Golden Seeds: amounts per source, pack price, rarity drop rates, slot prices, duplicates per star, Mastery costs. | v0.7 | Open |
| G13 | Manager art: who makes it and in what style. | v0.7 | Open |
| G14 | Cook-Off reward table: Golden Seeds and Ribbons per threshold. | v0.8 | Open |

## Work

| Id | What | Status | Needs |
| --- | --- | --- | --- |
| W1 | Open the Web build on a phone: it exports cleanly but hasn't been tried on a device. Since v0.5 this also checks the catch-up speed on a phone (0.38 s for 8 hours on the Mac) and that backgrounding the tab counts as away | Not started | `bash tools/serve_web.sh` and a phone on the same Wi-Fi |
| W2 | Sound and haptics for the button press | Not started | Nothing |
| W3 | Pacing margins: N6 passes with 115 s of 120, and F6 with 75 s of 90 | Watch | CI runs `tests/pacing_tests.gd` on every push |
| W4 | The pacing player buys the cheapest upgrade, not the bottleneck; a smarter player would progress faster, so the criteria are measured against a fairly naive one | Open | A second, bottleneck-aware player if pacing needs a range rather than one figure |
| W5 | Shift Roster threshold: £10,000 is reached at 42:18, a little before the 45–60 minute target. £14,000 would land at 50:00 | Open | Settle in v0.7, when the tab is built |
| W6 | Tier 2 oversupply: by 30:00 the pacing player has 249 Jalapeños and 41 Verde Mash waiting, because Pickled Brine (Vinegar) is the bottleneck and the player's cheapest-first upgrades don't see that | Watch | Raw Overflow Valve (v0.4) gives the surplus a use; W4 would buy for the bottleneck |
| W7 | The run is ahead of the 3-hour curve: £100k at 1:30 (target 1:50). With offline play, one night away from 1:40 adds £3.2M, past the £1M Prestige line. The criteria are only deadlines, so nothing fails | Open, for v0.6 | Set the whole curve against D005 with "not before" bounds, offline included |
