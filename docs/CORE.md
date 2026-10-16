# Core loop

The Day-1 loop, ported as it was from the web prototype (`reference/web-prototype/game.js`, [D002](DECISIONS.md)). Every number is in `src/core/guesses.gd`; the rules are in `src/core/game.gd`; `tests/core_tests.gd` checks each one.

## The loop

1. **Pick.** A tap picks `1 + shears` bell peppers. 8% of taps crit for ×3 (rounded).
2. **Heat.** Each tap adds 5.5 heat (max 100); heat drains 12 a second. At 100 (19 quick taps), **Flash Boil** runs for 10 s: taps pick ×5 and add no heat. When it ends heat drops to 0.
3. **Sell or bottle.** Loose peppers sell for $0.05 (bell) or $0.35 (jalapeño). After 20 peppers picked in total the **kitchen** opens: 20 bell make a Table Sauce that sells at once for $2.50; 15 jalapeños make a Smoky Sauce for $15.
4. **Upgrade.** The first bottle opens upgrades:
   - Sharp Shears: +1 pepper a tap. $15 × 1.5^level.
   - Field Picker: +2 bell a second. $25 × 1.4^level.
   - Hand Capper: bottles a Table Sauce every max(0.8, 4 / (1 + 0.35 × level)) s, rounded up to a tick, when there are 20 bell. $10 × 1.4^level.
   - Jalapeño Patch (once, $100): taps also pick a jalapeño 35% of the time; opens Smoky Sauce.

## Changes from the prototype

- Actions check their unlock (bottling needs the kitchen, upgrades need the first bottle). The prototype only hid the buttons.
- Flash Boil and the capper count whole ticks rather than subtracting 0.1 s each tick, so float drift can't shift them.
- Crits and jalapeño picks come from one seeded RNG stream that the save keeps, so a game replays the same.
- The prototype's heat bar showed a 1.0–1.8× multiplier that nothing applied. The port shows heat as a percentage instead; whether heat should multiply is open ([B1](BACKLOG.md)).
- Not ported yet: sound, floating "+N" pick feedback, the reset button ([B3–B5](BACKLOG.md)).

## Criteria

None measured yet. The first ones should cover pacing of a first session (time to the kitchen, to the first upgrade, to the jalapeño patch); see [B7](BACKLOG.md).
