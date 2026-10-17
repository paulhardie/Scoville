# Offline (v0.5, draft)

Brief header "Local, Offline-First", §4 Night Shift Protocols: the factory keeps working while the player is away. It settles G11 ([D018–D021](DECISIONS.md)).

The rules will be in `src/core/game.gd` (the catch-up) and `src/core/real_clock.gd` (the only place wall-clock time enters, as AGENTS.md requires). The return card will be in `src/ui/main.gd`.

## Rules

- **Cap (D018):** time away counts for up to **4 hours**, +2 hours for each Night Shift Protocols node: 8 hours with both. Time beyond the cap is lost.
- **Speed (D018):** production runs at **50%** of the idle online rate, +10 points for each Night Shift node: 70% with both.
- **What runs (D019):**
  - Plots, vats and lines work, and the Delivery Van and Overflow Valve sell as set. Smart Stockpiling's pin still holds things back.
  - Nobody taps, so Heat drains to 0. The Automated Piston keeps pressing, with every button perk.
  - Nothing is bought, researched, assigned or pressed for the player, including Factory Overdrive.
- **Timers keep wall-clock time (D019):** Overdrive's cooldown, Byproduct Recycling's minute and the Market Ticker all move on by the whole time away, not just the offline time. A spike that would have started and ended while away is missed. One still running when the player returns carries on.
- **When the player counts as away (D021):** the app was closed, or the screen hasn't run for more than 10 seconds (a phone pauses a web game in the background).
  - The save records the device time it was written. The screen also records the time of its last frame.
  - The gap counts from whichever is later. A clock that went backwards counts as no time.
- **Tabs and Operation Value:** offline earnings count towards Operation Value, so they can open tabs (the account's best value).

## How it's worked out (D020)

With **away** = min(time away, cap), the **offline time** is away × speed.

1. **Offline time up to 5 minutes:** run the real simulation tick by tick for the offline time, with no input except the Piston. This is exact.
2. **Longer:** run the real simulation for 5 minutes and measure how much each item's stock, the cash and every count changed. Then scale those changes to the rest of the offline time:
   - Work out how far the scale can go before any pile of stock would fall below zero.
   - If that point comes before the end, scale only to there, set that pile to 0, measure 5 minutes again from that state, and carry on.
   - Re-measure at most 4 times. Whatever time is left after that is credited at the last rate, with every pile held at zero.
3. **Afterwards:** move the clock on by the whole time away (not just the offline time), so every timer has really passed. Heat is set to what the Piston alone would hold.

Every chance draws from the game's own stream, so the same save and the same time away always give the same result. Scaling never creates stock that the measured minutes couldn't have produced.

## Night Shift Protocols (West Wing)

Brief §4: "Extends the current run's Offline production cap (+2 hours per node) and boosts offline speed." Costs follow D010, at about 2–4 minutes of Classic Louisiana. The v0.4 pacing player makes 6–10 a minute between 0:55 and 1:40. Like the rest of the tree, they reset with a Prestige (v0.6).

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| W5 | Night Shift Protocols I | W1 | 15 Classic Louisiana | Offline cap +2 hours, offline speed +10 points | 0:55 | −2, −1 |
| W6 | Night Shift Protocols II | W5 | 25 Classic Louisiana | Offline cap +2 hours, offline speed +10 points | 1:20 | −3, −1 |

## The return card

- **When it shows:** on a return from more than 60 seconds away. Shorter gaps (a glance at another app) are caught up silently.
- **What it says:**
  - "While you were away: 3 h 12 m".
  - If the cap applied: "Counted up to 4 h at 50%; Night Shift Protocols raise it."
  - The cash earned, the rise in Operation Value, and the three items made most.
- **Dismissing it:** tapping anywhere closes it. Nothing on it is a choice.

## Saves

Version 5 adds `saved_at`, the device time when the save was written, beside `run` and `account`. A v4 save migrates with no `saved_at`, so its first load gives no offline progress (a v4 game never promised any).

## Criteria (v0.5, draft)

| Id | Criterion |
| --- | --- |
| X1 | Away time counts up to the cap: 4 hours, +2 for each Night Shift node. Time beyond it is lost, and a backwards clock counts as none. |
| X2 | The offline speed is 50%, +10 points for each Night Shift node. |
| X3 | Accuracy: from the pacing player's states at 0:30, 1:00 and 1:40, being away 2 hours raises Operation Value within 2% of running 2 h × the speed tick by tick with no input. Up to 5 minutes of offline time matches it exactly. |
| X4 | Safety: no stock goes negative. Nothing is bought, researched, assigned or pressed, except by the Piston. |
| X5 | Timers: after 20 minutes away, Overdrive's cooldown is 20 minutes on. Missed spikes aren't paid, and the next spike keeps the Ticker's schedule. |
| X6 | The same save and the same time away give the same result. |
| X7 | Working out 8 hours away takes under 0.5 s on the development Mac, headless. (The phone is W1.) |
| X8 | The return card shows after more than 60 s away, not after less, with the time away, the cap note when it applied, the cash, the rise in Operation Value and the top three items. |
| P1 | Checking in pays: a player who plays 30 minutes (the pacing player), is away 8 hours, then plays another 30 minutes ends with at least twice the Operation Value the pacing player has after a straight hour. |
| P2 | A night's sleep is worth more than an evening's tapping: with both Night Shift nodes, 8 hours away from the pacing player's 1:40 state raises Operation Value at least as much as 2 hours of tapping with Heat at that same factory, buying nothing. (Measured like M5: the active rate, × 120 minutes.) |

v0.2–v0.4's F, N and M criteria stay in force. The pacing player will research W5 and W6 near their expected times; their exact place in its order gets written down with the build.
