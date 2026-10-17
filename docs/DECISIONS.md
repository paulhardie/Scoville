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
