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
