# Decisions

Numbered, newest last. Status is Accepted unless it says otherwise.

## D001: Build Scoville in Godot 4.7.2

**Decision:** Scoville is a Godot 4.7.2 project, exported to the Web for phones, set up the way Clicker Lab is: a pure simulation in `src/core/`, screens that only present and report, GDScript test suites, and every Godot run through `run_godot.sh`.

**Why:** The same engine, scripts and habits as Clicker Lab and Number Go Up, so tools and lessons carry over. The HTML prototype stays in `reference/web-prototype/` as the design reference.

## D002: Port the prototype's Day-1 loop as it is first

**Decision:** The first version reproduces the prototype's rules and numbers, with only the changes listed in [CORE.md](CORE.md#changes-from-the-prototype). Retuning and new systems come after, each with criteria.

**Why:** It gives a working, tested baseline to measure against before anything moves.
