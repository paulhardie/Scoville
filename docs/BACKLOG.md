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
| G12 | Golden Seeds: amounts per source, pack price, rarity drop rates, slot prices, duplicates per star, Mastery costs. | v0.8 | Open |
| G13 | Manager art: who makes it and in what style. | v0.8 | Open |
| G14 | Cook-Off reward table: Golden Seeds and Ribbons per threshold. | v0.9 | Open |
| G19 | HQ room steps after Level 1, and three caps that don't add up: Cooperage and Glassworks "−5% … Lv 11 (−50% max)" (11 × 5% is 55%), Test Kitchen "−4% … Lv 11 (−40% max)" (44%). Seed Capital past its four amounts | v0.6b | Assumed (D030): steps repeat Level 1's; caps kept at Level 11, so 55% and 44%; Seed Capital ×5 a level to Level 10 |
| G20 | Idle Planet Miner's early flow (D041): the per-level gains of plot upgrades and the starting plots' prices and rates aren't Idle Planet Miner's numbers to copy (its upgrades raise mining, ship speed and cargo, not speed and yield) | v0.6d | Assumed and built (D041): speed +3%, yield +6% of base a level, Crop Quality 1% to 30; Poblano $800 and Jalapeño $1,900 at 2 every 2.4 s (v0.6d; now $520 and $1,700, D048). Superseded in v0.7 by IPM's own upgrades and planets (D050, SKELETON.md) |
| G18 | Ingredients as the bottleneck: base amounts, the Pantry's nodes and numbers | v0.6a | Assumed in [FULL_RUN.md](FULL_RUN.md#the-pantry-branch-d026-g18-as-assumed): Brine 0–3 a new sauce; booster 2×, concentrate −40%, fork Bulk 2× or Reserve +25% |
| G17 | Tier 6's new peppers (Moruga Scorpion, Pepper X) and the fictional six need recipes | v0.6b | Through Tier 5 settled (D029, accepted); Tier 6 assumed (D034). v0.7 replaces it: every pepper, real and fictional, feeds IPM's recipe graph (D051, SKELETON.md) |
| G21 | Trucks: the wiki gives IPM's ship speed and cargo but not the trip itself | v0.7 | Assumed (SKELETON.md): a round trip is 2 × distance ÷ Truck Speed, carrying Truck Cargo, most valuable crop first; checked against farm 1 at level 1 (0.25 a second each way) |
| G22 | IPM data the wiki doesn't have: farms 77–79 (Celestite's), distances from farm 71, Telescopes 24–25, the four top items' values (the wiki's "probably 500 D"), Celestite Alloy's time | v0.7 | Assumed (SKELETON.md): ×3 a farm, +2 distance a farm, the next sauce +1 and +6 mash a survey, $500Dc, 100:00 |
| G23 | Costs of our own Tech Tree nodes (the button, the West Wing, the Pantry, Bumper Crop…) on the new ladder: not IPM's to copy | v0.7 | Assumed (SKELETON.md): PR 2 prices each in the sauce the copied run makes when its old gate came, counts unchanged, before measuring |
| G24 | Names for 79 farms, 20 new mashes and 35 new sauces | v0.7 | Assumed (SKELETON.md): farms after their main crop with a numeral; mashes and sauces given default names; the owner can rename any |
| G25 | Trademarks on the new pepper names (Pimento, Cascabel, Hungarian Wax, Chile de Árbol, Pequin, Fatalii, Trinidad 7 Pot, Naga Morich): checked only against the marks D042 found, not the register | v0.7 | Open: check the register (or ask a lawyer) before store builds (v1.0) |

## Work

| Id | What | Status | Needs |
| --- | --- | --- | --- |
| W3 | Tight margins: E3 (casual) 96 s of 100, N6 91 s of 120, X3 at 1:40 1.82% of 2%, X7 2.56× of 3× (D027) | Watch | CI runs the pacing and offline tests on every push |
| W4 | The pacing player buys the cheapest upgrade, not the bottleneck; a smarter player would progress faster, so the criteria are measured against a fairly naive one | Open | A second, bottleneck-aware player if pacing needs a range rather than one figure |
| W5 | Shift Roster threshold: £10,000 is reached at 42:18, a little before the 45–60 minute target. £14,000 would land at 50:00 | Open | Settle in v0.8, when the tab is built |
| W6 | Tier 2 oversupply: by 30:00 the pacing player has 249 Jalapeños and 41 Verde Mash waiting, because Pickled Brine (Vinegar) is the bottleneck and the player's cheapest-first upgrades don't see that | Watch | Raw Overflow Valve (v0.4) gives the surplus a use; W4 would buy for the bottleneck |
| W8 | Visual pass: on a phone it "looks like a 2010 web game rather than a mobile app in 2026" (owner, after W1). The owner chose pixel art (D047); a trial of the Pixel UI Free skin is [LOOK.md](LOOK.md) | In trial | Owner: keep the kit, buy the full pack (ember theme), or commission UI art; PX8 is the owner's eye |
| W24 | How much faster a repeat run may be: nothing bounds it from below (Y1 only asks for at most 85% of run 1). At SOP 1% free run 2 took 73% of run 1, 64% since D041's plot curve; at 5% free it took 44% (PRESTIGE.md) | Open | Owner: set a floor, e.g. no faster than 50% of run 1, with more rooms (W21) |
| W21 | Late growth is unbounded: run 1 $101M at 3:00, $465M at 3:15 once Phantom runs (D041); run 2 $659M at 3:00 and $846M at 3:15 with three rooms (PRESTIGE.md, the second run). U1 ends at the sale | Open | Owner: is a fast-growing late run fine, or cap it? |
| W22 | Layout step 3 (LAYOUT.md, D037): chain diagrams, bottleneck highlights, unlock and sale ceremonies. Step 2 (the viewport with a factory view and the tab selectors under it) is built (D044), drawn in code: W8 can restyle it | Open | W8's visual direction |
| W16 | Hear and feel the click and buzz on a real phone (Android Chrome for vibration; iPhone Safari has none) | Open | The owner's next phone test |
| W9 | The pacing player never sets Bistro Verde's Auto-Sell back to 100% after Smart Stockpiling, so Bistro piles up in late runs. A measuring quirk, not a game fault | Open | Fix with W4's smarter player |
| W27 | Fermentation as a mechanic: mash that ages while away and sells for more, with salt as its ingredient (D042: the owner chose it as its own version later). Ties in with the Fermentation Cellar room | Open | Design when the owner picks it up: criteria first |
| W30 | E6 FAILS by one since D044: 9 Sweet Pepper Mash waiting for the casual player's Starter Crate, against 10. D048 measured it against plot, vat and Line 1 prices: only Line 1 moves it, in a step with the casual player's tapping bursts, so at any price either E6 or E3 fails ($110: E6 9, E3 84 s; $115: E6 13, E3 120 s) | Open | **Owner:** lower E6's bar to 9, or retire E6 now the ring guides the player to the line (D044), or change how the Starter Crate counts |
| W31 | When the first sale comes: the owner's instructions for one session said about an hour (not in the repo; D005 says about 3 hours); D035 put it at about 2:00 ($10M). Measured and options in [PRESTIGE.md](PRESTIGE.md#when-the-first-sale-comes-w31-a-proposal-not-built) | Open | Owner: keep D035, or an early sale at about $400K for 5 credits (recommended if the hour stands) |
| W32 | Whole pixels on the phone: the 540×960 screen is stretched to the phone's size, which isn't a whole multiple, so the kit's pixels can come out slightly uneven. Godot's integer stretch mode would fix it but changes how much of the screen we get (LOOK.md) | Open | The owner's next phone test; then decide on integer stretch |
| W33 | Game art in pixel style: peppers, bottles, the Blank Button's face, factory floors (layout step 2, W22) and manager portraits (G13). Needs one pixel density for the art to match the UI's 2× | Open | Owner: who draws it (Aseprite by hand, PixelLab for drafts, or an artist) once the trial is judged |
| W34 | v0.7 PR 2: build the Idle Planet Miner skeleton as SKELETON.md maps it (farms with shares, trucks, 28 peppers, 33 mashes, 48 sauces, surveys, adopted nodes, vats and lines, rooms, Galaxy Value, save v12, the Farms screen) and measure I1–I14, reporting every FAIL | Next | PR 1 merged |
| W35 | v0.7 PR 3: tweak the copy against its FAILs, set new curve checkpoints from the measured run, and make it less of a reskin (D049) | After W34 | W34's results |
| W36 | Idle Planet Miner left out for now: its markets and their projects, Beacon, managers' projects (with the Shift Roster, v0.8), 24-hour challenges (with the Cook-Off) | Later | Owner, when a version picks one up |
