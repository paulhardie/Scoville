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
| G20 | Idle Planet Miner's early flow (D041): the per-level gains of plot upgrades and the starting plots' prices and rates aren't Idle Planet Miner's numbers to copy (its upgrades raise mining, ship speed and cargo, not speed and yield) | v0.6d | Assumed and built (D041): speed +3%, yield +6% of base a level, Crop Quality 1% to 30; Poblano $800 and Jalapeño $1,900 at 2 every 2.4 s |
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
| W24 | How much faster a repeat run may be: nothing bounds it from below (Y1 only asks for at most 85% of run 1). At SOP 1% free run 2 took 73% of run 1, 64% since D041's plot curve; at 5% free it took 44% (PRESTIGE.md) | Open | Owner: set a floor, e.g. no faster than 50% of run 1, with more rooms (W21) |
| W21 | Late growth is unbounded: run 1 $101M at 3:00, $465M at 3:15 once Phantom runs (D041); run 2 $659M at 3:00 and $846M at 3:15 with three rooms (PRESTIGE.md, the second run). U1 ends at the sale | Open | Owner: is a fast-growing late run fine, or cap it? |
| W22 | Layout step 3 (LAYOUT.md, D037): chain diagrams, bottleneck highlights, unlock and sale ceremonies. Step 2 (the viewport with a factory view and the tab selectors under it) is built (D044), drawn in code: W8 can restyle it | Open | W8's visual direction |
| W16 | Hear and feel the click and buzz on a real phone (Android Chrome for vibration; iPhone Safari has none) | Open | The owner's next phone test |
| W9 | The pacing player never sets Bistro Verde's Auto-Sell back to 100% after Smart Stockpiling, so Bistro piles up in late runs. A measuring quirk, not a game fault | Open | Fix with W4's smarter player |
| W27 | Fermentation as a mechanic: mash that ages while away and sells for more, with salt as its ingredient (D042: the owner chose it as its own version later). Ties in with the Fermentation Cellar room | Open | Design when the owner picks it up: criteria first |
| W28 | The second plot feels a little slow to unlock (the owner, playing on a phone after D041). The pacing player buys the Poblano Plot at about 3:00; a real player is slower | Open | Revisit the starting plots' prices with the next early-game pass |
| W29 | A4 FAILS by one second since D043: 6:31 against 6:30 (Jalapeño Plot to the Ancho vat). Crop Quality's early levels went, so early cash buys Cargo and the vat lands 4 s later | Open | Owner: the bar flaps on seconds; recommend 7:00, or fold it into W28's early-game pass |
| W30 | E6 FAILS by one since D044: 9 Sweet Pepper Mash waiting for the casual player's Starter Crate, against 10. The plot is on sale from the start, so the line comes sooner. Raising Line 1's price fixed it but failed E3 and U7 | Open | Fold into W28's early-game pass with A4 (W29) |
| W31 | When the first sale comes: the owner's instructions for one session said about an hour (not in the repo; D005 says about 3 hours); D035 put it at about 2:00 ($10M). Measured and options in [PRESTIGE.md](PRESTIGE.md#when-the-first-sale-comes-w31-a-proposal-not-built) | Open | Owner: keep D035, or an early sale at about $400K for 5 credits (recommended if the hour stands) |
