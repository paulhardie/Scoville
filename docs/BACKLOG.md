# Backlog

Everything adopted and not done, one row each. Gaps (G) are things the brief leaves open that a version needs settled; work rows (W) are things to build or check. Update the status when a row moves; delete it when it's done and the handover says so.

## Gaps in the brief

| Id | Gap | Needed by | Status |
| --- | --- | --- | --- |
| G1 | Platform: native iOS and Android builds, or the Web build (as a phone PWA) until v1.0? Native needs Xcode, the Android SDK and signing. | v1.0 (testing now) | Open: recommend Web for testing, native from v1.0 |
| G2 | Title: the brief says Hot Sauce Empire, the repository is Scoville. | — | Assumed: the game is Hot Sauce Empire, the project is Scoville |
| G15 | Vat and line slots: the brief has "Parallel Vat Slots" as a cash knob and Slot Expansion as a Tech Tree unlock, but no base cap. Built as 3 vat and 2 line slots in run 1, each assigned a recipe ([FACTORY.md](FACTORY.md#v03-slots-recipes-and-tier-2)). | v0.3 | Built as assumed; owner approved the draft |
| G8 | Franchise Credits formula ("scaled logarithmically"), HQ room level costs, and when a room draft is offered. | v0.6b | Assumed and built (D030): 10 × log₁₀(OV ÷ £100k), 5n to open, 2 × level to level, draft on paying |
| G16 | Night Watchman's Desk: the brief says "+1 Hour Offline Cap" a level with a "Hard Cap Lv 15 (+8 Hours max)". Fifteen levels of +1 hour is 15 hours, so the two can't both hold | v0.6b | Assumed and built (D030): +1 hour a level, cap Level 8 (+8 hours) |
| G12 | Golden Seeds: amounts per source, pack price, rarity drop rates, slot prices, duplicates per star, Mastery costs. | v0.7 | Open |
| G13 | Manager art: who makes it and in what style. | v0.7 | Open |
| G14 | Cook-Off reward table: Golden Seeds and Ribbons per threshold. | v0.8 | Open |
| G19 | HQ room steps after Level 1, and three caps that don't add up: Cooperage and Glassworks "−5% … Lv 11 (−50% max)" (11 × 5% is 55%), Test Kitchen "−4% … Lv 11 (−40% max)" (44%). Seed Capital past its four amounts | v0.6b | Assumed (D030): steps repeat Level 1's; caps kept at Level 11, so 55% and 44%; Seed Capital ×5 a level to Level 10 |
| G18 | Ingredients as the bottleneck: base amounts, the Pantry's nodes and numbers | v0.6a | Assumed in [FULL_RUN.md](FULL_RUN.md#the-pantry-branch-d026-g18-as-assumed): Brine 0–3 a new sauce; booster 2×, concentrate −40%, fork Bulk 2× or Reserve +25% |
| G17 | Tier 6's new peppers (Moruga Scorpion, Pepper X) and the fictional six need recipes | v0.6b | Through Tier 5 settled (D029, accepted); Tier 6 assumed (D034); the fictional six open |

## Work

| Id | What | Status | Needs |
| --- | --- | --- | --- |
| W3 | Tight margins: E3 (casual) 96 s of 100, N6 91 s of 120, X3 at 1:40 1.82% of 2%, X7 2.56× of 3× (D027) | Watch | CI runs the pacing and offline tests on every push |
| W4 | The pacing player buys the cheapest upgrade, not the bottleneck; a smarter player would progress faster, so the criteria are measured against a fairly naive one | Open | A second, bottleneck-aware player if pacing needs a range rather than one figure |
| W5 | Shift Roster threshold: £10,000 is reached at 42:18, a little before the 45–60 minute target. £14,000 would land at 50:00 | Open | Settle in v0.7, when the tab is built |
| W6 | Tier 2 oversupply: by 30:00 the pacing player has 249 Jalapeños and 41 Verde Mash waiting, because Pickled Brine (Vinegar) is the bottleneck and the player's cheapest-first upgrades don't see that | Watch | Raw Overflow Valve (v0.4) gives the surplus a use; W4 would buy for the bottleneck |
| W8 | Visual pass: on a phone it "looks like a 2010 web game rather than a mobile app in 2026" (owner, after W1). Today's look is placeholder panels, flat colours and the default font | Open | Owner: reference games and a mood, and whether art will come later |
| W21 | Late growth is unbounded: $117M at 3:00, $757M at 3:15 once Phantom runs (D035). U1 now ends at the sale | Open | A bound on Operation Value at 3:00, or the credit curve's view of it, with W17 |
| W17 | Second-run pacing: nothing measures a run after a sale (rooms, SOP, Tier 6's plot prices and the Cook-Off's £100M+ thresholds) | Open | A pacing player that sells and replays |
| W15 | The stock line under the status bar is crowded with v0.6a's items (capped at three lines, FEEL.md) | Open | The visual pass (W8) |
| W16 | Hear and feel the click and buzz on a real phone (Android Chrome for vibration; iPhone Safari has none) | Open | The owner's next phone test |
| W9 | The pacing player never sets Bistro Verde's Auto-Sell back to 100% after Smart Stockpiling, so Bistro piles up in late runs. A measuring quirk, not a game fault | Open | Fix with W4's smarter player |
