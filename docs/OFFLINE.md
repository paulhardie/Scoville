# Offline (v0.5)

Brief header "Local, Offline-First", §4 Night Shift Protocols: the factory keeps working while the player is away. It settles G11 ([D018–D021](DECISIONS.md)).

The rules are in `src/core/game.gd` (`catch_up`, `_step`). Wall-clock time enters only through `src/core/real_clock.gd`, as AGENTS.md requires, and the screen swaps in a fake clock for tests. The return card is in `src/ui/main.gd`.

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

## How it's worked out (D020, revised in the build)

With **away** = min(time away, cap), the **offline time** is away × speed.

1. **Offline time up to 5 minutes:** the game runs tick by tick for the offline time, with no input except the Piston. This is exact.
2. **Longer:** the same rules run in longer steps, at most 4,000 of them (`Game._step`). In one step:
   - A plot harvests every whole cycle, with one draw for how many come up double.
   - A vat or line finishes every cycle its time and inputs allow, then restarts if it can.
   - A vat's output goes straight to any slot waiting for it, as in a tick, so a shared input (Pickled Brine) is split as in play.
   - The Piston's presses come in one batch.
   - The valve, pins and keep amounts, Auto-Sell and Byproduct Recycling work as in play.
   - Plots run first, then vats, then lines, as in a tick, so what one makes feeds the next in the same step.
3. **Afterwards:** the clock moves on by the whole time away (not just the offline time), so every timer has really passed. The Market Ticker's schedule is replayed on that clock: missed spikes are skipped, and one still running carries on.

Every chance draws from the game's own stream, so the same save and the same time away always give the same result. No stock can go negative.

The draft measured 5 minutes and scaled them; why that was replaced is in [D020](DECISIONS.md).

## Night Shift Protocols (West Wing)

Brief §4: "Extends the current run's Offline production cap (+2 hours per node) and boosts offline speed." Costs follow D010, at about 2–4 minutes of Classic Louisiana. The v0.4 pacing player makes 6–10 a minute between 0:55 and 1:40. Like the rest of the tree, they reset with a Prestige (v0.6).

| Id | Node | Needs | Cost | Effect | Expected | Pos |
| --- | --- | --- | --- | --- | --- | --- |
| W5 | Night Shift Protocols I | W1 | 15 Classic Louisiana | Offline cap +2 hours, offline speed +10 points | 0:55 | −2, −1 |
| W6 | Night Shift Protocols II | W5 | 25 Classic Louisiana | Offline cap +2 hours, offline speed +10 points | 1:20 | −3, −1 |

## The return card

- **When it shows:** on a return from more than 60 seconds away. Shorter gaps (a glance at another app) are caught up silently. Gaps over 10 s count as away; shorter ones are just slow frames.
- **What it says:**
  - "While you were away: 3 h 12 m".
  - If the cap applied: "Counted up to 4 h at 50%; Night Shift Protocols raise it."
  - The cash earned, the rise in Operation Value, and the three items made that are worth most (by count, crops would always win).
  - The cap note mentions Night Shift Protocols only while one is still to research.
- **Dismissing it:** tapping anywhere closes it. Nothing on it is a choice.

## The return before the Delivery Van (D046)

**Why.** Until the Delivery Van (about 18–20 minutes in) nothing sells itself, so time away makes bottles and crops but no cash. The card led with "+$0.00 cash" even after a night that left $56,000 of Table Mild waiting (casual player away 8 hours from 8:00). Coming back is meant to feel rewarding, and this is the first return most players see.

**Rule.** The catch-up report carries what Sell Batch would pay once it's done (`bottles_waiting`, the same figure as `Game.bottles_value()`). The card shows "+$X of sauce waiting: tap Sell Batch" when that's above zero, and leaves out the cash line when no cash was earned. Crops waiting aren't counted: selling them can starve a vat, so that stays the player's choice on the plot cards.

| Id | Criterion |
| --- | --- |
| J1 | Before the Delivery Van, a return of more than 60 s that made bottles shows what Sell Batch would pay, matching `bottles_value()` after the catch-up, and doesn't show a "+$0.00 cash" line. |
| J2 | With the Delivery Van selling everything, the card is as before: the cash line shows, and no waiting line (nothing is held). |

## Saves

Version 5 adds `saved_at`, the device time when the save was written, beside `run` and `account`. A v4 save migrates with no `saved_at`, so its first load gives no offline progress (a v4 game never promised any).

## Criteria (v0.5)

| Id | Criterion |
| --- | --- |
| X1 | Away time counts up to the cap: 4 hours, +2 for each Night Shift node. Time beyond it is lost, and a backwards clock counts as none. |
| X2 | The offline speed is 50%, +10 points for each Night Shift node. |
| X3 | Accuracy: from the pacing player's states at 0:30, 1:00 and 1:40, being away 2 hours raises Operation Value within 2% of running 2 h × the speed tick by tick with no input. Up to 5 minutes of offline time matches it exactly. |
| X4 | Safety: no stock goes negative. Nothing is bought, researched, assigned or pressed, except by the Piston. |
| X5 | Timers: after 20 minutes away, Overdrive's cooldown is 20 minutes on. Missed spikes aren't paid, and the next spike keeps the Ticker's schedule. |
| X6 | The same save and the same time away give the same result. |
| X7 | Working out 8 hours away takes at most 3× as long as the same machine ticking 10 minutes from the same save, headless, best of 3 each (D027). Was: under 0.5 s on the development Mac. (The phone is W1.) |
| X8 | The return card shows after more than 60 s away, not after less, with the time away, the cap note when it applied, the cash, the rise in Operation Value and the top three items. |
| P1 | Checking in pays: a player who plays 30 minutes (the pacing player), is away 8 hours, then plays another 30 minutes ends with at least twice the Operation Value the pacing player has after a straight hour. |
| P2 | A night's sleep is worth more than an evening's tapping: with both Night Shift nodes, 8 hours away from the pacing player's 1:40 state raises Operation Value at least as much as 2 hours of tapping with Heat at that same factory, buying nothing. (Measured like M5: the active rate, × 120 minutes.) |

v0.2–v0.4's F, N and M criteria stay in force. The pacing player researches W5 after the Heat Meter and W6 after Overclock II.

## Results (v0.5)

All pass: `tests/offline_tests.gd` (X1–X7, 53 checks), `tests/ui_tests.gd` (X8, with a fake clock) and `tests/pacing_tests.gd` (P1–P2, and F, N and M).

| Id | Target | Measured |
| --- | --- | --- |
| X1–X2 | 4 h at 50%, +2 h and +10 points a node | 4 h 50%, 6 h 60%, 8 h 70%; 10 h away counts 4; a backwards clock counts 0 |
| X3 | Within 2% of tick by tick | 0:30 0.03%, 1:00 0.00%, 1:40 1.82% (2 hours away; v0.5.1, a bigger factory at 1:40); 10 minutes away exact |
| X4 | No negative stock; nothing bought or pressed | holds at 0:30, 1:00 and 1:40 over 8 hours; the Piston keeps pressing |
| X5 | Timers keep wall-clock time | Overdrive's cooldown, and the Ticker's schedule and running spike, match a tick-by-tick run |
| X6 | Deterministic | the same save and time away give identical results |
| X7 | At most 3× 10 minutes ticking | 2.38–2.56× on a cloud container (0.81–0.89 s against 0.34–0.35 s, five runs). Under the old bar: 0.46 s on the development Mac, 0.73–0.75 s on CI (FAIL) |
| X8 | The card | shows after 3 h, not after 30 s; notes the cap at 10 h; shows after reopening a save 2 h later |
| P1 | 30 min, 8 h away, 30 min ≥ 2× a straight hour | £127,126 against £35,310 (v0.5.1) |
| P2 | A night beats 2 hours' tapping (from 1:40) | +£3,605,984 against £1,600,288 (v0.5.1; the tapping minute is measured without a running Market spike) |

Researching the Night Shift nodes moved v0.4's M7 (the Piston) from 1:37 to 1:41 (by 1:50). Everything else held.

**A night away is worth a lot.** From 1:40, one night (8 hours at 70%) adds £3.2M of Operation Value, past the £1M Prestige line. That's the W7 pacing question again, now with offline time in it. It belongs with v0.6's whole-curve work.

