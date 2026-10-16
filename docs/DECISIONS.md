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

## D009: Upgrade prices scale with the square root of a station's price

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

## D020: Offline progress is measured, then scaled

**Decision:** The offline time is (time away, up to the cap) × the offline speed.
- **Up to 5 minutes of it:** the real simulation runs, with no input.
- **Longer:** the simulation runs 5 minutes for real, measures what changed, and scales that to the rest.
  - When scaling would empty a pile of stock, it stops at that point, measures again from there, and carries on, up to 4 times. Whatever time is left after the fourth measurement is credited at the last measured rate, holding every pile at zero.
  - No stock ever goes negative.
  - Chances come from the game's own random stream, so the same save and the same time away always give the same result.

**Why:** Simulating 8 hours tick by tick is 288,000 ticks: seconds on a desktop, far too long on a phone. Measuring the real factory keeps every rule and bottleneck right, without a second, simplified model of the game to keep in step. Re-measuring when a pile empties stops a draining pile from being counted as if it lasted for ever.

## D021: When the player counts as away

**Decision:** The player counts as away when the app was closed, or when the screen hasn't run for more than 10 seconds (a phone pauses a web game in the background). The save records the device time it was written, and each run of the screen records the time of its last frame. A gap counts from those. A clock that has gone backwards counts as no time; one moved forwards is only limited by the cap.

**Why:** The brief has no server, so the device clock is all there is (as for the Cook-Off). The cap bounds what moving the clock forwards can gain.
