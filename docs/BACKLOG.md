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
| W2 | Sound and haptics for the button press | Not started | Nothing |
| W3 | Tight margins: E3 (casual) 96 s of 100, N6 91 s of 120, X3 at 1:40 1.82% of 2%, X7 0.46 s of 0.5 | Watch | CI runs the pacing and offline tests on every push |
| W4 | The pacing player buys the cheapest upgrade, not the bottleneck; a smarter player would progress faster, so the criteria are measured against a fairly naive one | Open | A second, bottleneck-aware player if pacing needs a range rather than one figure |
| W5 | Shift Roster threshold: £10,000 is reached at 42:18, a little before the 45–60 minute target. £14,000 would land at 50:00 | Open | Settle in v0.7, when the tab is built |
| W6 | Tier 2 oversupply: by 30:00 the pacing player has 249 Jalapeños and 41 Verde Mash waiting, because Pickled Brine (Vinegar) is the bottleneck and the player's cheapest-first upgrades don't see that | Watch | Raw Overflow Valve (v0.4) gives the surplus a use; W4 would buy for the bottleneck |
| W7 | The run is ahead of the 3-hour curve: £100k at 1:24 (target 1:50), £454k at 1:50. One night away from 1:40 adds £3.6M, past the £1M Prestige line. The criteria are only deadlines, so nothing fails | Open, for v0.6 | Set the whole curve against D005 with "not before" bounds, offline included |
| W8 | Visual pass: on a phone it "looks like a 2010 web game rather than a mobile app in 2026" (owner, after W1). Today's look is placeholder panels, flat colours and the default font | Open | Owner: reference games and a mood, and whether art will come later |
| W9 | The pacing player never sets Bistro Verde's Auto-Sell back to 100% after Smart Stockpiling, so Bistro piles up in late runs. A measuring quirk, not a game fault | Open | Fix with W4's smarter player |
