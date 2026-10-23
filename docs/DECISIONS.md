# Decisions

Numbered, newest last. Status is Accepted unless it says otherwise.

## D001: Build Scoville in Godot 4.7.2

**Decision:** Scoville is a Godot 4.7.2 project, set up the way Clicker Lab is: a pure simulation in `src/core/`, screens that only present and report, GDScript test suites, and every Godot run through `run_godot.sh`. Phone testing uses the Web export until native builds are decided (G1).

**Why:** The same engine, scripts and habits as Clicker Lab and Number Go Up, so tools and lessons carry over. Godot also exports to iOS and Android, which the brief targets.

## D002: The brief is the design source

**Decision:** [BRIEF.md](BRIEF.md) (Hot Sauce Empire v1.0) defines the game. It replaces the first commit's port of an older HTML hot-sauce prototype, which was removed along with that prototype. Gaps in the brief become G rows in the backlog instead of silent guesses; small ones needed to build a version are assumed in that version's design doc and listed there.

**Why:** The prototype was a different design (a different loop, heat as a tap multiplier, dollars). The owner's brief is what's being built.

## D003: Pace the first 15 minutes with a scripted player

**Decision:** Each version's pacing criteria are measured by a scripted player (`src/sim/engaged_player.gd`) that only uses the game's real actions, run by `tests/pacing_tests.gd` in CI. A retune that breaks a criterion fails the build, so a deliberate change of target has to change the criterion in the design doc in the same PR.

**Why:** The brief promises the onboarding happens "during the first 15 minutes" and the button never goes obsolete. Both are measurable, and measuring them on every change stops the numbers drifting quietly.

## D004: Item values follow the bottle (G6)

**Decision:** A bottle is worth 5× the raw value inside it, with any lower-tier bottle used as an input counted at its sale value. Mash is worth 2× its inputs. Raw crop prices come from those two rules ([ECONOMY.md](ECONOMY.md#item-values-g6-d004)). Operation Value counts stock at these values.

**Why:** The brief's Tier 1 already works this way (10 Bell Peppers: £1 raw, £5 bottled). One rule then prices every crop and mash consistently, and processing always pays.

## D005: A 3-hour first run, with tab thresholds set from it (G5)

**Decision:** A fresh game should reach the £1,000,000 Prestige threshold in about 3 hours of play, with checkpoints at £1k (0:16), £10k (0:50) and £100k (1:50). The nav bar and Processing tab open at £400, the Tech Tree at £750, the Shift Roster at £10,000 (provisional), and HQ at £1,000,000.

**Why:** The owner's target. The early thresholds put every reveal inside the brief's first 15 minutes, measured against v0.2's pacing curve. The Shift Roster's number gets re-measured once Tier 2 runs.

## D006: Carolina Reaper is Tier 6, after the first Prestige (G7)

**Decision:** Tier 6 (Carolina Reaper → Reaper Mash → Widowmaker Reserve, £40,000) unlocks only once the player has prestiged.

**Why:** Runs after the first get something the first run didn't have, and the Cook-Off's thresholds past £100M need a tier past 5.

## D007: The first Tech Tree slice comes with Tier 2 (v0.3)

**Decision:** v0.3 builds the Tech Tree tab, `[00] Kitchen Table`, the East Wing's Tier 2 blueprints and the West Wing's Delivery Van, together with Tier 2 and recipe-assigned vat and line slots. The rest of the tree, Tier 3 and Slot Expansion come in v0.4.

**Why:** The brief gates higher-tier plots and recipes behind Crop and Culinary Blueprints, so Tier 2 can't come before the Tech Tree, as the first roadmap had it.

## D008: Calloused Thumbs comes with the v0.3 slice

**Decision:** The North Wing's first node, Calloused Thumbs (+2 Bell Peppers a press, 10 Table Mild), is part of the v0.3 Tech Tree. It was added during the build, outside the drafted slice. **Confirmed by the owner.**

**Why:** Without it, Tier 2's income dwarfed a one-pepper tap. Tapping added 6% at 30:00 (N8 wanted 10%) and 22% at 15:00 (F8 wanted 25%), so the build missed the brief's "the button never becomes obsolete". The brief names this node as the button's first step, and with it N8 measures +17% and F8 +64%. The other choices were lowering the criteria, or leaving the build failing until v0.4.

## D009: Upgrade prices scale with the square root of a station's price (slots amended by D031)

**Decision:** A plot's or slot's upgrades cost v0.2's curve × √(its price ÷ the first of its kind). The draft used the full ratio.

**Why:** At the full ratio, Tier 2's upgrades cost 10–20× Tier 1's for a similar gain, so they were never worth buying, and waits ran past N6's 120 s. Tier 1 is unchanged (its ratio is 1).

## D010: The v0.4 Tech Tree (G9)

**Decision:** v0.4 adds 26 nodes ([TECH_TREE.md](TECH_TREE.md#v04-the-rest-of-the-tree)): the North Wing up to the Automated Piston, Tier 3's East Wing blueprints and Hydroponic Bell Peppers, the South Wing up to Overdrive Turbines (without Artisan Decanters), the West Wing's Raw Overflow Valve, Smart Stockpiling and Market Ticker, and two bridges (Byproduct Recycling, Franchise Auditors). Nodes that need later systems wait for them: Golden Seed Extractor and Executive Perks for v0.7, Night Shift Protocols for v0.5, Standard Operating Procedures, Artisan Decanters and the Tier 4–6 blueprints for v0.6. A node costs about 2–4 minutes of whatever it's paid in, at the time the 3-hour curve expects the player to reach it, rising to about 8 on the outer rim. North and West are paid in the current top bottle, East in the previous tier's bottles and mash, and South mostly in mash.

**Why:** It's what the brief describes, minus what can't work yet. The costing rule makes every node a few minutes' choice between selling and researching, whatever the tier.

## D011: Heat (G10)

**Decision:** Each press adds 5 Heat and Heat drains 12 a second (6 with Slow Burn), between 0 and 100. Cash from every sale is multiplied by 1 + 0.5 × Heat/100, so up to +50%. It applies to sales by hand and Auto-Sell alike, raw included. Stock is valued as normal.

**Why:** About 2.5 presses a second hold it, so an engaged player keeps the full bonus and the Automated Piston (1 a second) can't. That is the brief's "while maintained". Ergonomic Grip (2 a second) can hold it only with Slow Burn, so holding the button is a real, chosen way to play.

## D012: Packaging is one global tier

**Decision:** Packaging tiers (Heavy Flint Glass 1.5×, Foil Neck Wraps 2.2×, later Artisan Decanters 3.5×) are set by the South Wing for every line. There is no per-line packaging upgrade. The tier multiplies every bottle's sale value and its value in Operation Value.

**Why:** The brief lists packaging both as a line's cash knob and as a tree upgrade "across all lines". With per-line tiers, identical bottles in stock would be worth different amounts.

## D013: Byproduct Recycling hands out at most one level a minute

**Decision:** Keep the brief's 25% chance per vat cycle, but give at most one free plot level a minute. It goes to the owned plot with the fewest levels, on whichever of its upgrades is cheapest.

**Why:** At Tier 3 cycle speeds, 25% per cycle uncapped would be about 15 free levels a minute, which would break the economy.

## D014: The Raw Overflow Valve keeps an amount of each item

**Decision:** Each crop and mash has a "keep" amount, defaulting to 5 cycles' worth of the researched recipes that use it. The player can raise it, lower it or switch it off. Anything above it sells at its value (with Heat), except what a pinned node needs (Smart Stockpiling).

**Why:** The brief says "excess" without defining it. A keep amount makes excess concrete, and the default never starves a running recipe.

## D015: One Market Ticker spike at a time

**Decision:** Once researched, a spike starts 1–5 minutes later on a random unlocked sauce: ×2 or ×3 its sale price for 30 minutes. Each later spike starts 45–75 minutes after the last one started. The value in Operation Value is unchanged.

**Why:** "Periodic" with a 30-minute spike, kept simple: about one an hour, always visible, never stacking.

## D016: Crop Quality Chance doubles a harvest (rest of G4)

**Decision:** Crop Quality is a third plot upgrade. Each level adds a 3% chance that a harvest gives double, capped at 30% (10 levels). Its price curve is £30 × 2^level, scaled by √(price ratio) like the others.

**Why:** The brief names the knob without defining it. Doubling a harvest is the simplest reading, and it leaves Barnaby's Mutant Crops (v0.7) as a different, bigger effect.

## D017: One seeded random stream

**Decision:** Every chance (Double-Tap, Byproduct Recycling, the Market Ticker, Crop Quality) draws from one random stream seeded when a game starts. Its state is saved, as a string so JSON can't round it, so a loaded game carries on exactly as it would have.

**Why:** Randomness arrives with v0.4. Determinism keeps tests and the pacing player exact.

## D018: Offline cap and speed (G11)

**Decision:** Time away counts for up to **4 hours** to start, and production runs at **50%** of the idle online rate. The West Wing's Night Shift Protocols I and II (v0.5) each add +2 hours and +10 points, so with both: 8 hours at 70%. Night Watchman's Desk (HQ, v0.6) and Gus (v0.7) build on these.

**Why:** 4 hours rewards checking in a few times a day, and 8 hours after the Night Shift nodes covers a night's sleep. 50% leaves room for the brief's later boosts (Gus +25% to +60%), so his Mastery's "150% of active online speed" is still a real step up.

## D019: What happens while away

**Decision:** While away:
- Production runs at the offline speed. Nobody taps, so Heat falls to 0, but the Automated Piston keeps pressing.
- Nothing is bought, researched, assigned or pressed for the player, including Factory Overdrive.
- Timers keep wall-clock time: Overdrive's cooldown, Byproduct Recycling's minute and the Market Ticker's schedule. Spikes that would have started and ended while away are missed.
- Time beyond the cap is lost.

**Why:** "Offline-first" means the factory works while the player sleeps, but choices stay the player's. Missing spikes keeps the Ticker a reason to check in.

## D020: Offline progress is simulated in longer steps (revised in the build)

**Decision:** The offline time is (time away, up to the cap) × the offline speed. Up to 5 minutes of it runs tick by tick, exactly. Longer runs the game's own rules in longer steps: at most 4,000 of them, so a step is about 1 s for 2 hours and 5 s for 8. In one step:
- A plot harvests every whole cycle, with one draw for how many come up double.
- A vat or line finishes every cycle its time and inputs allow, then restarts if it can.
- The valve sells, Byproduct Recycling's chance is drawn, and the pin and keep amounts work as in play.

Chances come from the game's own random stream, so the same save and the same time away always give the same result. No stock can go negative.

**Why:** 8 hours tick by tick is 288,000 ticks: seconds on a desktop, far too long on a phone.

**Revised from the draft.** The draft measured 5 minutes and scaled them up. Built, that missed X3's 2% target three ways: by 3% at 0:30, and by 10–14% at 1:40. Patching each flaw broke another state.
- A pile rising to a pin or keep amount was scaled straight past the point where it starts selling.
- Stock flowing through a buffer looked like a pile running dry.
- A factory that grows while away (Byproduct Recycling's free levels) was scaled at its starting rate.

Stepping runs the real rules, so all three take care of themselves. It measures within 0.74% of tick by tick, and works out 8 hours in 0.38 s.

## D021: When the player counts as away

**Decision:** The player counts as away when the app was closed, or when the screen hasn't run for more than 10 seconds (a phone pauses a web game in the background). The save records the device time it was written, and each run of the screen records the time of its last frame. A gap counts from those. A clock that has gone backwards counts as no time; one moved forwards is only limited by the cap.

**Why:** The brief has no server, so the device clock is all there is (as for the Cook-Off). The cap bounds what moving the clock forwards can gain.

## D022: The early game is measured with a casual player too

**Decision:** The first 20 minutes are measured twice:
- with the pacing player (3 taps a second, always);
- with a casual phone player (2 a second in 45-second bursts with 15-second rests, looking every 2 seconds).

Early criteria (FACTORY.md E1–E6) set gaps ("never longer than … without something new") as well as deadlines.

**Why:** On a phone the start felt "incredibly slow" while every deadline passed. A tireless player and deadline-only criteria can't see a dead stretch.

## D023: The pepper ladder

**Status:** Accepted by the owner (with D029).

**Decision:** The game's crops become a ladder of 13 real peppers ordered by Scoville, Bell Pepper (0) to Pepper X (2.69M), then 6 fictional ones up to 16 billion ([INGREDIENTS.md](INGREDIENTS.md)). The brief's six peppers keep their D004 values as anchors; each new real pepper sits on the geometric line between its neighbours; past the Carolina Reaper each rung is ×2.15, Idle Planet Miner's ore step. How the new peppers are used in recipes is G17.

**Why:** The owner asked for real hot sauce peppers from Bell to Pepper X and fictional ones beyond, valued with Idle Planet Miner as the reference. Keeping the brief's values as anchors means the brief's bottles and the built, tuned Tiers 1–3 don't move.

## D024: Hot sauce ingredients are stations, unlocked by blueprints

**Decision:** Non-pepper ingredients come from their own stations, bought with cash once their East Wing Crop Blueprint is researched, and run on the same rules as a pepper plot (cycle, yield, upgrades, offline). It's how White Vinegar already works. Grown ingredients (Garlic, Cane Sugar) are shown as plots; made ones get a station of their own on screen (White Vinegar → Vinegar Cask, Smoked Oak → Oak Smokehouse). Only the name and art differ, not the rules. The button is not a source, and cash never buys ingredients (brief §3). **Accepted by the owner.**

**Why:** Idle Planet Miner gets every raw input from the same mining loop. A button source can't feed a factory, stops while away (D019), and would make tapping a chore rather than the bonus the brief wants.

## D025: Forager's Luck, the button's ingredient top-up

**Decision:** A North Wing node, N10 Forager's Luck ([TECH_TREE.md](TECH_TREE.md#n10-foragers-luck-d025)): each press has a 2.5% chance to drop one harvest of whichever ingredient the factory is shortest of. Every press counts (Double-Tap, Grip, the Piston), so it keeps working while away through the Piston. **Asked for by the owner;** the numbers are GUESSES until measured.

**Why:** It rewards active play where the factory actually hurts, without the factory depending on it. At 3 presses a second it adds about 15% to an early ingredient station; the Piston alone adds about 5%.

## D026: The Pantry branch, with either/or forks

**Decision:** Non-pepper ingredients are made a deliberate bottleneck ([INGREDIENTS.md](INGREDIENTS.md#ingredients-as-the-bottleneck-g18-proposed)): hotter recipes take more of the base, and relief comes from one Pantry branch in the East Wing, a short track per ingredient (a yield booster, then a "concentrate" node). Each track ends in a fork where only one side can be researched in a run (for example Aged, its mash worth 1.5×, or Bulk, its station yielding 2×). The other side stays locked until Prestige resets the tree. **Accepted by the owner.** Node numbers and costs are set with v0.6 (G18).

**Why:** Every other node is a question of when, not whether. Forks give real choices without a tree per ingredient, which the brief's single web argues against.

## D027: X7 is measured against the machine it runs on

**Decision:** X7 compares the catch-up with the same machine: working out 8 hours away may take at most 3× as long as ticking 10 minutes from the same save, best of 3 each ([OFFLINE.md](OFFLINE.md)). It replaces "under 0.5 s on the development Mac". **Chosen by the owner** (machine-relative); the 3× is the agent's.

**Why:** 0.5 s held only on the Mac. CI's runner takes 0.73–0.75 s, so main was red from PR #9 on with nothing wrong. A ratio means the same anywhere and still fails if the catch-up gets slower relative to play. **The bar is a little looser than before:** today's ratio is 2.38–2.56×, so 3× leaves about 20% for noise; on the Mac it's roughly 0.56 s rather than 0.5 s (estimated, assuming the Mac's ratio matches). A bar at the old 0.5 s equivalent (about 2.7×) would leave 5% over the worst run measured, too little for shared machines. The phone itself is still W1.

## D028: v0.6 is built in two halves

**Decision:** v0.6a, the full run ([FULL_RUN.md](FULL_RUN.md)): Tiers 4–5, the ladder's extra peppers through Tier 5, the Pantry branch, the last boosters and slots, and the whole curve to £1M with bounds both ways. Then v0.6b, Prestige: Franchise Credits, HQ rooms with the draft, the anti-exploit cost formula, Standard Operating Procedures and Tier 6. **Proposed;** the owner can merge them back into one.

**Why:** v0.6 as written was the biggest version yet, by far. v0.6b needs G8 and G16 from the owner and a run that reaches £1M to test on; v0.6a needs neither, so it can start now.

## D029: Each new pepper gets an in-between sauce (G17)

**Decision:** Every pepper the ladder adds through Tier 5 (Poblano, Serrano, Tabasco, Scotch Bonnet, Red Savina) gets a single-pepper mash and one sauce priced between the brief's sauces, so ten sauces climb about ×2.2 a rung ([FULL_RUN.md](FULL_RUN.md#the-sauce-ladder-g17-as-assumed-d029)). The new sauces take 0–3 Pickled Brine and some take lower-tier mash or bottles. **Accepted by the owner, with D023.**

**Why:** It's the recommendation the owner was given for G17 (Idle Planet Miner's ore → bar). Pricing each new sauce between its neighbours makes every pepper the best line until the next one, rather than a sideways copy, and smooths the climb into Idle Planet Miner's ×2-ish steps.

## D030: Prestige's numbers (G8, G16, G19, assumed)

**Decision:** Franchise Credits = ⌊10 × log₁₀(Operation Value ÷ £100,000)⌋, so 10 at £1M and 20 at £10M, × the Executive Lounge. Opening the n-th HQ room costs 5n credits and deals a 2-room draft; levelling costs 2 × the current level. Room steps after Level 1 repeat Level 1's (the speed rooms +10% a level after +15%), and Night Watchman's Desk stops at Level 8 (+8 hours). Full table in [PRESTIGE.md](PRESTIGE.md). **Assumed to build v0.6b; the owner can change any of it.**

**Why:** The brief says "scaled logarithmically" and gives each room's first level and cap, but no prices. With these, the first sale (10 credits) buys a room and a level. Opening all 12 costs 390 credits, roughly 20–30 sales at 10–20 credits each, so the full HQ is a long-term goal while each sale still buys something. G16's contradiction (+1 hour a level, cap Level 15, max +8 hours) is settled on the stated maximum.

## D031: A slot's upgrades are priced by what it makes

**Decision:** A vat's or line's speed upgrades cost v0.2's curve × the larger of √(its slot price ÷ the first slot's) (D009) and √(the value of what it makes ÷ Sweet Pepper Mash's or Table Mild's). A line bottling Phantom Smokehouse upgrades at about 32× Table Mild prices. **Chosen by the owner.**

**Why:** Priced by the slot alone, a slot bought for Table Mild upgraded at Table Mild prices while making the top sauce, so every late slot was maxed for pocket change and the run reached £1M at 2:25. It's Idle Planet Miner's model, and early slots are unchanged (their price ratio is the larger).

## D032: v0.6a's criteria and how they're measured

**Decision (chosen by the owner):** U8 is measured from 1:20, not 1:40; U4 asks for Classic Louisiana and Pickled Brine (not Table Mild and Verde Mash) at 2:30–2:40; M6 is retired, as U4 checks the same thing for the full run. **Measurement fixes (the agent's, said here):** "tapping adds X%" (F7, F8, N8, M5, U7, and P2's tapping minute) now sells the saved backlog before the minute starts and starts the idle minute at Heat 0; U6 swaps each of the four forks and takes the biggest swing, as its wording ("in some track") says.

**Why:** From 1:40 a night is worth about £1M by the curve's own maths, so U8 couldn't pass alongside U1. Nothing late takes Table Mild or Verde Mash. The tapping minute was dominated by selling a stockpile at the saved Heat in both runs, and the idle run kept the tapping run's Heat for most of the minute.

## D033: U2 and U5 for the late run

**Decision (chosen by the owner):** U2 allows waits of up to 300 s between purchases from 1:50 to 3:00 (M4 keeps 150 s to 1:50). U5 measures the ingredient bottleneck by what it costs in slots: from 2:00 to 3:00 at least 30% of vat time runs an ingredient's mash (Pickled Brine, Garlic Paste, Caramelized Glaze, Liquid Smoke), and no slot waits on one for more than 5 minutes from 1:00 to 3:00.

**Why:** Late purchases are big and few once slot upgrades cost what their sauce is worth (D031), and nothing cheap fills the gaps. A player answers the Brine squeeze with more Brine vats, as D026 intended, so slots rarely wait; the bottleneck shows as vats given to ingredients (65% measured).

## D034: v0.6b part 2, Standard Operating Procedures and Tier 6 (G17)

**Decision:** Standard Operating Procedures is a West Wing node that opens after the first sale; once researched, any node the player could research whose cost is worth under 1% of an hour of the bottles running lines make researches itself, free, except fork sides. Tier 6 (also after the first sale) adds Moruga Scorpion → Scorpion Sting £14,920, Carolina Reaper → Widowmaker Reserve £40,000 (D006's recipe) and Pepper X → Event Horizon £100,000, each with a single-pepper mash, priced by D004 ([PRESTIGE.md](PRESTIGE.md#part-2-standard-operating-procedures-and-tier-6)). **Assumed to build W12; the owner can change any of it.**

**Why:** The brief gives SOP's rule ("less than 1% of current production throughput") but not what throughput is measured in; bottles a second is what the player sees grow, and an hour makes the early nodes (a few Table Mild) fall below it as soon as a second run has a few lines going, while late nodes stay manual. D029's pattern (each new pepper gets its own mash and sauce) is the accepted way to use a pepper; following it for Tier 6 keeps Widowmaker's D006 recipe and value and puts one sauce either side of it.

## D035: Idle Planet Miner's values, in dollars, and its $10M sale

**Decision (the owner's):** every pepper maps to an Idle Planet Miner ore in order and copies its sell price, in US dollars (Bell = Copper $1 … Pepper X = Osmium $7,800); the four ingredients take the ore of the pepper nearest them before (assumed). D004's multiples stay, so bottles follow (Table Mild $50, Phantom $330,250). The first sale is Idle Planet Miner's: $10M for 10 credits, then its credit table. **The run keeps v0.6a's pace (the owner chose the agent's recommendation):** the $10M sale comes at about 2:00–2:15, and pushing on to Phantom pays more credits. The Tier 6 sauce Event Horizon is renamed Extinction Event. Save v8 converts money ×10. ([ECONOMY.md](ECONOMY.md#v06c-idle-planet-miners-values-in-dollars-d035), [INGREDIENTS.md](INGREDIENTS.md))

**Why:** the owner wants Idle Planet Miner's numbers. Its values climb ×2.1 an ore, steeper than v0.6a's ×1.65, so values rose ×10 at Tier 1 and ×65 by Tier 5; prices had to follow by tier, priced by the sauce that pays for each station rather than the station's own pepper, or the late run stalled (measured: Phantom never made). Holding $10M at 3:00 instead would have moved every sauce from Tier 3 on 45–60 minutes later and Phantom past the first run; the agent recommended keeping the pace, which is how selling a galaxy works in Idle Planet Miner. **Bars moved, said here:** U1's last band (now the sale at 2:00–2:30) and U8 (from 1:00), both by the owner's choice; every other money bar converted before measuring. **Measurement fix:** nights (P1, P2, U8) start with slots set up as the tapping minute's do.

## D036: v0.6c's three FAILs settled

**Decision (the owner's, on the agent's recommendation):** N5's bar (and U1's second band) is $150,000 by 50:00, not $200,000; M2 is retired, as U3 holds the first Classic Louisiana to its time; the pacing player's Savina Gold layout runs two Garlic Paste vats instead of a second Cayenne Mash vat.

**Why:** $200,000 came from converting the old £10,000 at ×20 (Serrano Fire), but at 50:00 most money still comes from Bistro Verde (×17) and Table Mild (×10). M2 missed by 51 s while U3 passed for the same sauce. The 402 s wait U5 caught was a Louisiana line starved of Paste (one Paste vat for three Louisiana lines), first misread as the Sweet Heat lending it later switched to; it was the player's layout, not the game. **Bars moved after a result, said here:** N5 and M2.

## D037: The layout plan, step 1 first

**Decision (the owner's, on the agent's recommendation):** the screen moves from admin tabs towards a factory you watch, in three steps ([LAYOUT.md](LAYOUT.md)): (1) readable numbers, station sheets with ×1/×10/Max, a payoff when a bottle lands, a goal bar, a warehouse drawer and a Market tab; (2) the factory as floors with moving items and the Blank Button at the foot of the screen, once the visual direction is set (W8); (3) chain diagrams, bottleneck highlights and ceremonies. Step 1 is built now.

**Why:** the systems are deep but the screen is lists of forms: by the late game 51 plot upgrade buttons, 13 slot cards, a 30-item stock line and 13 sliders, with unreadable figures ($2,931,411.49) and no goal on screen. Step 1 fixes most of the "2010 web game" feel with no art and doesn't wait on W8. Moving the button to the foot of the screen (step 2) changes the brief's split viewport (§2), so it waits for the owner's say with the visual pass.

## D038: Standard Operating Procedures' bar is 5% of an hour's bottles

**Decision (the owner's, on the agent's recommendation):** a node researches itself under SOP when its cost is worth less than 5% of an hour of the bottles running lines make (3 minutes of bottles), not 1%. This departs from the brief's "less than 1% of current production throughput" as D034 read it.

**Why:** measured on a second run (W17, Y2), at 1% SOP did nothing for its first 16½ minutes: the player had already researched every node that cheap, and the next (Double-Tap, $6,375) was over a bar of about $700. SOP's point is to take the early clicking away on repeat runs. The trade-off: it also takes mid-game nodes free sooner.

## D039: Standard Operating Procedures pays for what it researches

**Decision (the owner's, on the agent's recommendation):** a node SOP researches costs its items' worth at base values, taken from cash; if cash is short, SOP waits. It no longer researches for free. Paying in cash, not items, is the agent's assumption.

**Why:** free research made run 2 reach the sale in 57 minutes, 44% of run 1 (W24): SOP was saving most of the run's research costs, not just its taps. Paying keeps SOP an automation, as the brief's "auto-research" suggests. Cash rather than items because the Delivery Van sells bottles at 100% by default, so there's rarely stock to take; cash is what those bottles would have sold for.

## D040: Standard Operating Procedures is free, at 1%, as the brief reads

**Decision (the owner's, on the agent's recommendation):** SOP researches a node free when its cost is worth under 1% of an hour of the bottles running lines make: the brief's rule. D038 (5%) and D039 (paying cash) are reversed. Y2's "the first within 10 minutes of buying SOP" is dropped.

**Why:** measured three ways on run 2 (PRESTIGE.md): 5% free made run 2 2.3× faster than run 1 (free research saving most of its costs); paying cash left SOP broke, because a player spends cash as it comes, so it researched less and later and a late wait went over 300 s. At 1% free, run 2 takes 73% of run 1's time and SOP researches 32 nodes, picking them up as production outgrows them, which is what the brief describes. The 10-minute start was the agent's guess and it doesn't fit that reading. **Bar moved after a result, said here.**

## D041: Idle Planet Miner's early flow

**Decision (the owner's, on the agent's recommendation):** the Poblano and Jalapeño Plots are on sale from the start, each growing 2 crops every 2.4 s and priced to pay back from raw sales in 8–10 minutes ($800, $1,900); blueprints gate crops from White Vinegar on, and E1 and E12 become cultivation nodes (a speed boost) with the same ids and places. Every crop sells raw from its plot. Every plot upgrade costs 5% of the plot's price for its first level and ×1.3 a level after, with smaller gains a level. The Blank Button start, the early vat and line, and 5× bottles stay. Save v9 converts plot levels ([ECONOMY.md](ECONOMY.md#v06d-idle-planet-miners-early-flow-d041)).

**Why:** the owner wants the early game to flow like Idle Planet Miner's. Measured before this: after the first line at 1:36 nothing new was on sale until the Tech Tree opened, and the Poblano Plot came at 14:13, twelve and a half minutes of buying only upgrades. Idle Planet Miner fills that time with planets bought one after another and ore sold raw. Prices follow equal payback rather than a strict ×2, because our plots yield differently (a Jalapeño Plot makes six times what a Bell Plot does in dollars a second); a strict ×2 would pay back in under a minute and swamp the factory. The brief's E1 (Crop Blueprint: Jalapeño) is changed.

**Measured into place (the agent's assumptions, [ECONOMY.md](ECONOMY.md#built-v06d)):** Harvest Speed +3% a level, Yield per Cycle +6% of base yield a level (fractions carry), Crop Quality 1% a level to 30; Ancho Mash 18 s so one base Poblano Plot still feeds one vat; a Forager's Luck drop is what the plot grows in one base cycle (cheap speed levels had made its share swing 6–37%); Savina Pepper Plot $2.0M and Moruga Scorpion Plot $5M, reached now with less income. The pacing player learned to sell raw, save for starting plots, weigh levels by payback, and keep its old layout until the new one's plots are bought. **Bar moved after a result, said here:** A1's payback, 1–4 minutes to 5–10 (Idle Planet Miner's own is about 7–8; at 1–4 the early income tripled). **A4** measured 6:22 against 6:00; the owner moved its bar to 6:30 (W26).

## D042: The pepper ladder by real heat, generic names only, and Pineapple

**Decision (the owner's, on the agent's recommendation; the two parody names are the owner's):** the peppers are tiered by PepperScale's heat ranges, one pepper a heat band, with generic variety names: Thai Chili for Tabasco, Caribbean Red Habanero for Habanero, Chocolate Habanero for Red Savina (its sauce Savina Gold becomes Cocoa Loco). Tier 6 ends in two fictional peppers that wink at the record holders: **Alabama Grim** for the Carolina Reaper and **Pepper Y** for Pepper X. Pineapple (from a Pineapple Grove) replaces Cane Sugar, making Charred Pineapple Glaze. Every rung keeps its ore value, so pacing is unchanged. Save v10 renames the ids. ([INGREDIENTS.md](INGREDIENTS.md#the-ladder-since-d042))

**Why:** Tabasco duplicated Cayenne's heat and Habanero duplicated Scotch Bonnet's; Moruga and Reaper overlap. TABASCO (McIlhenny, enforced), RED SAVINA HABANERO and PepperX are registered marks, and "Smokin' Ed's Carolina Reaper" is registered with plain "Carolina Reaper" contested. Real names players know are the trade-off; the agent's searches used secondary sources, not the official register, so it isn't legal advice. Pepper Y and Alabama Grim are parodies by design: they nod at the marks without using them. Pineapple: Scotch Bonnet with pineapple or mango is a real Caribbean pairing, and it fits Island Heat and Sweet Heat better than cane sugar. The Trinidad 7 Pot the proposal added is dropped: the two parody peppers fill Tier 6. Fermentation as a mechanic is a later version (W27).

## D043: Cargo replaces Crop Quality; Bumper Crop in the Tech Tree

**Decision (the owner's, on the agent's recommendation):** a plot's third cash upgrade is Cargo, Idle Planet Miner's: harvests wait in the plot's field and a truck carries them to stock at a cargo rate, twice the plot's base growth at level 0 and raised by every Tech and HQ boost that raises the harvest. The double-crop chance moves to three Tech Tree nodes, Bumper Crop I–III (10% each, 30% in all). Save v11 turns Crop Quality levels into Cargo levels. This changes the brief's plot knobs (§2, "Crop Quality Chance"). ([FACTORY.md](FACTORY.md#v06e-cargo-and-bumper-crop-in-the-tech-tree-d043))

**Why:** Harvest Speed and Yield both mean more crops; Idle Planet Miner's third upgrade is delivery, which makes each plot a balance to keep rather than three ways to grow it. A chance to double is the kind of perk the Tech Tree holds. Boosts raise cargo too so research never backs a plot up by itself; only the player's own levels can outgrow the truck, the moment to rebalance.

## D044: The dashboard from the first launch; the next action, not the empty screen

**Decision (the owner's):** the game opens on the full split-viewport dashboard. Status bar, upper viewport with the button and a factory view, the tab selectors directly below the viewport, and the panel all show from the first second. Nothing waits for a milestone to appear. The start stays gentle because exactly one next action is ringed and named at a time through the early run (`Game.next_action()`). Tabs still unlock at their thresholds, shown dimmed with what opens them. This replaces the brief's Pillar 1 (Strict Progressive Disclosure) and the reveal stages of §2. It retires O1, O3's and O4's thresholds, O8 and L9's blank stage. ([LAYOUT.md](LAYOUT.md#step-2-the-dashboard-from-the-first-launch-d044))

**Why:** the owner changed their mind: progression should come from the obvious next step rather than from hiding the screen. The tab thresholds stay because the pacing is measured against them (N1, N2) and they stage the run's content. Keeping them is the agent's assumption. The factory view is drawn in code rather than waiting on W8, so step 2 can ship and be restyled later.

## D045: Bottling gets a sound, a first-bottle buzz and a bottle in the factory view

**Decision (the owner's, on the agent's recommendation):** every bottle pop plays a glass clink made in code, pitched lower for richer tiers. The first bottle of each sauce in a run gives a short buzz. Each pop drops a bottle, tinted by tier, onto the factory view's Bottling floor. The first-bottle ceremony stays in layout step 3. ([FEEL.md](FEEL.md#bottling-a-sound-a-buzz-and-a-bottle-d045))

**Why:** making a bottle is the game's core reward, but it got the same weight as any number changing: a text pop, no sound, no picture, and a $330,000 Phantom felt like a $50 Table Mild. The sound and the bottle need no art, and the visual pass (W8) can restyle them.

## D046: The return card says what's waiting to sell

**Decision:** after time away, whenever bottles are held, the "While you were away" card shows what Sell Batch would pay ("+$X of sauce waiting: tap Sell Batch") and drops the cash line when no cash came in. Crops waiting aren't counted. Criteria J1–J2 in [OFFLINE.md](OFFLINE.md#the-return-before-the-delivery-van-d046).

**Why:** before the Delivery Van nothing sells while away, so every return in the first 20 minutes said "+$0.00 cash" though the factory had kept working. Showing the waiting value fixes the feel without changing what the Van is for. The other option, selling bottles while away before the Van, changes the game's rules and the Van's worth; it's the owner's call if the card isn't enough.

## D047: Pixel art is the game's look; trial a ready-made pixel UI skin first

**Decision (the owner's: "I'd like a pixel art style for this game for sure"; the trial is the agent's recommendation):** the game's visual style is pixel art. The first step is a trial of Pixel UI Free (heyheythere, CC BY 4.0, wood theme) over today's screen, drawn at whole-number scales with its bitmap font ([LOOK.md](LOOK.md)). Whether to keep the kit, buy the full pack or commission custom UI art is the owner's call after seeing the trial.

**Why:** W8 asked for a direction; the owner gave one. A skin over the existing screen is the cheapest way to see pixel art on our real content (dense cards, long names, big numbers) before anyone draws art for it. The trade-off: the kit is a generic fantasy-RPG skin, so it shows whether the style works, not what the finished game looks like.

**Note on "colours only in style.gd":** the kit's theme carries its own colours (wood tones, button ink). Every colour of ours is still in `style.gd`, including the few kit colours we override for contrast; the kit's file is a third-party asset, left unchanged.

## D048: Idle Planet Miner's opening ladder: Poblano $520, Jalapeño $1,700

**Decision (the owner asked how Idle Planet Miner does it):** the Poblano Plot costs $520 (was $800) and the Jalapeño Plot $1,700 (was $1,900), with the same rates. After Bell, each starting plot costs 2–4× the one before (A8), as Idle Planet Miner's first planets go $200, $500, $1,250, $5,000. No fourth starting plot. ([ECONOMY.md](ECONOMY.md#v06f-idle-planet-miners-opening-ladder-w28w30-d048))

**Why:** the second plot felt slow (W28) because it was one ×16 step from the Bell Plot, and A4 failed by a second (W29) because nothing new came between the Jalapeño Plot and the Ancho vat. A cheaper Poblano brings the casual player's second plot to 3:18 (A7), and a Jalapeño ×3.3 above it lands mid-gap, so A4 passes at 6:19. A Serrano Plot from the start was tried as Idle Planet Miner's fourth planet and dropped: the pacing player never afforded it early, and any price it could afford paid back in under 4 minutes. **$520 rather than $500 was picked after a result:** $500 failed X3 by 0.05 points from an unusual 2:30 state. E6 (W30) can't be met by prices: Line 1's price trades it against E3.


## D049: Copy Idle Planet Miner's skeleton whole, then tweak

**Decision (the owner's):** Idle Planet Miner's progression comes into the game whole: its ores, planets, upgrades, telescopes, bars and alloys, items, recipe prices, smelters and crafters, the projects that fit, rooms, Galaxy Value and the sale, mapped to peppers, farms, mashes, sauces, vats, lines and HQ ([SKELETON.md](SKELETON.md)). In three pull requests: the mapping and criteria (docs only), the copy as it stands with its results reported honestly, then a tweak pass. Systems with no counterpart here (asteroids, rovers, colonies, the station, surges, dark matter, paid ships, IPM's markets) are left out; managers wait for the Shift Roster, now v0.8.

**Why:** the owner judged it easier to copy the skeleton entirely and tweak once it's in than to keep borrowing pieces (D035, D041, D043, D048 each took one). The agent flagged that a whole copy makes the game read as a reskin of Idle Planet Miner in its numbers; the tweak pass is where it becomes ours. Main never holds a half-converted economy: PR 2 lands whole.

## D050: Farms grow a mix of crops, as planets mine a mix of ores

**Decision (the owner's, on the agent's recommendation):** plots become farms, each growing several peppers in IPM's planet shares (farm 2 is 80% Bell Pepper, 20% Pimento), with IPM's three upgrades: Harvest Rate, Truck Speed and Truck Cargo, on its formulas and its price ÷ 20 × 1.3^level curve. Yield per Cycle goes. A truck makes round trips of 2 × distance ÷ speed, assumed (G21).

**Why:** IPM's planet table only works this way: a new ore arrives as a small share on one planet, grows to a majority on the next, then gets a pure planet, so each step mixes the new with the known. One crop per plot can't copy it. **The cost:** a bigger change to the Farms screen and saves, and more crops in stock at once.

## D051: IPM's recipe graph, with the brief's names on the closest slots

**Decision (the owner's, on the agent's recommendation):** mashes and sauces take IPM's bars', alloys' and items' recipes, values, times and cash unlock prices. Mashes take 1,000 crops as bars take 1,000 ore. The brief's mash and sauce names (Verde Mash, Bistro Verde, Classic Louisiana, Phantom Smokehouse…) go on the slot closest to their old recipe. The four ingredients keep their stations (D024) and each goes into two sauces as an extra input at about 10% of the inputs, the sauce's value rising by the same share. Recipes are bought with cash, not Culinary Blueprints.

**Why:** IPM's chains already do what the brief's pillar 3 asks (higher alloys take lower bars), and copying the graph keeps its markups and pacing intact. **This departs from the brief's recipes (§3) and from D029's one-pepper-one-sauce rule,** by the owner's word. Bottles still pay for research through the Land Surveys and the Tech Tree.

## D052: The kitchen stays as the tutorial

**Decision (the owner's, on the agent's recommendation):** the first minutes don't take IPM's batch sizes. The Blank Button, the Bell Plot ($50, one Bell Pepper a second: IPM's Balor at four times the rate), Sweet Pepper Mash (10 Bell Peppers), Table Mild, the Starter Crate and the first vat ($150) and line ($100) stay as they are. Kitchen recipes run only in the kitchen vat and line; IPM's ratios apply from Bell Pepper Purée (1,000 Bell Peppers) on.

**Why:** copied straight, the first mash would take 1,000 Bell Peppers, over an hour at IPM's 0.25 a second, and the button and Starter Crate would mean nothing. Keeping the kitchen to its own vat and line stops it out-earning the factory: it tops out at 1.25 Bell Peppers a second into Table Mild.

## D053: 28 peppers by Scoville, fictional past Pepper Y

**Decision (the owner's):** one pepper for each of IPM's 28 ores, ordered by heat on PepperScale's list, generic names only (D042). Real peppers run Bell Pepper to Pepper Y (21 rungs, adding Pimento, Cascabel, Hungarian Wax, Chile de Árbol, Pequin, Fatalii, Trinidad 7 Pot and Naga Morich); the fictional seven past it are D023's six and Heat Death. Every pepper we grow keeps its id; values move to their new rung's ore (Jalapeño becomes Aluminium's $17). ([SKELETON.md](SKELETON.md#the-pepper-ladder-d053))

**Why:** the owner asked for more peppers tiered by Scoville and a deep endgame of made-up ones. The ladder of 13 (D042) left 15 ores with no pepper. Trinidad 7 Pot, which D042 dropped as overlapping, comes back because there are now rungs to fill. Apollo (3,000,000 SHU) is left out so Pepper Y stays the last real-world rung.
