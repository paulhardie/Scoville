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
