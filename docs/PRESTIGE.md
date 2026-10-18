# Prestige (v0.6b, first part)

Brief §6: once a run's Operation Value reaches £1,000,000, the player can **sell the franchise**. That resets the run and pays **Franchise Credits**, spent on **HQ Facility rooms** that last across runs. A new room comes from a **2-card draft**. This first part builds the loop itself: selling, credits, the 12 rooms with their draft and levels, and the brief's anti-exploit cost formula. Standard Operating Procedures and Tier 6 come next (D028).

Status: **built** (rules, save v7, the HQ tab), all criteria PASS. It doesn't depend on v0.6a's tuning: the rules are checked with games set up directly, at any Operation Value.

## Rules

- **Selling** is offered on the HQ tab while the run's Operation Value is at least £1,000,000. It asks for a second tap to confirm.
- **Credits** = ⌊10 × log₁₀(Operation Value ÷ £100,000) × (1 + Executive Lounge)⌋: 10 at £1M, 13 at £2M, 20 at £10M, 30 at £100M.
- **What resets (brief §6):** cash, plots, vats, lines, stock, the Tech Tree, Heat, Overdrive and the Market Ticker's schedule, the valve's keep amounts and the pin, and the run's statistics. Cash restarts at the Seed Capital Office's amount.
- **What stays:** the account: the best Operation Value (so every tab stays open), credits, rooms and the number of sales. The onboarding reveals stay too, so a new run starts on the full screen, not the blank button.
- **Opening a room** costs 5 × (rooms owned + 1) credits: 5, 10, 15… Paying deals a draft of 2 different rooms not yet owned (1 if only one is left), drawn from the game's random stream. Picking one opens it at Level 1. The draft is saved, so closing the app doesn't re-deal it, and no new room can be paid for while one is waiting.
- **Levelling a room** costs 2 × its current level in credits: 2 for Level 2, 4 for Level 3… up to its cap.
- **The anti-exploit formula (brief §6):** a discounted Tech Tree cost is max(1, round(base × (1 − HQ discount) × (1 − Tech discount) × (1 − Manager discount))). Recipe inputs cut by Cooperage, Glassworks, Zero-Waste Piping or a Pantry Concentrate multiply the same way, rounded down, at least 1.

## The 12 rooms (brief §6)

The brief gives each room's Level 1 effect and its cap. "Each level after" is assumed to repeat the Level 1 step, except the speed rooms, which follow the brief's "+15%, then +10% a level" for the Seed Vault.

| Room | Effect | Level 1 | Each level after | Cap |
| --- | --- | --- | --- | --- |
| Seed Vault | Plots harvest faster | +15% | +10% | 50 |
| Hydroponics Bay | Plots yield more a harvest | +10% | +10% | 50 |
| Fermentation Cellar | Vats run faster | +15% | +10% | 50 |
| High-Speed Cannery | Lines run faster | +15% | +10% | 50 |
| Cooperage | Vats need fewer raw crops | −5% | −5% | 11 (−55%) |
| Glassworks | Lines need less mash | −5% | −5% | 11 (−55%) |
| Test Kitchen | Tech Tree costs less | −4% | −4% | 11 (−44%) |
| Ergonomics Lab | The button picks more | +25% | +25% | 30 |
| Seed Capital Office | Starting cash | £100 | £500, £2,500, £50,000, then ×5 | 10 |
| Tasting Room | Bottles are worth more (sale and stock) | +10% | +10% | 50 |
| Executive Lounge | More Franchise Credits | +8% | +8% | 30 |
| Night Watchman's Desk | Longer offline cap | +1 hour | +1 hour | 8 (G16) |

The brief's caps for Cooperage, Glassworks and Test Kitchen say "−50% max" and "−40% max" at Level 11, but 11 levels of 5% and 4% is 55% and 44%. The cap is kept at Level 11 and the effect follows the step; say if the maximum should win instead (G19).

## Criteria (v0.6b, first part)

| Id | Criterion |
| --- | --- |
| Q1 | Selling is refused below £1,000,000 Operation Value and allowed at it. |
| Q2 | Credits follow the formula: 10 at £1M, 20 at £10M; the Executive Lounge adds its share, rounded down. |
| Q3 | A sale resets exactly the run (the list above), restarts cash at Seed Capital's amount, and keeps the account and the reveals. The game plays on from it: the Bell Pepper Plot can be bought at once. |
| Q4 | Opening a room takes its cost and deals 2 different unowned rooms (1 when one is left); a second payment is refused while a draft waits; picking a room outside the draft is refused; the draft survives a save and reload unchanged. |
| Q5 | Levelling takes 2 × the level and stops at the cap. |
| Q6 | Each room does what its row says, checked against a game without it. |
| Q7 | Discounted Tech Tree costs follow max(1, round(…)); a 1-item cost stays 1. |
| Q8 | Save v7: a v6 save loads with no credits, rooms or draft; an account with rooms, credits and a draft round-trips exactly; an unknown room is refused. |
| Q9 | On screen: HQ offers the sale with its credits, sells only on a second tap, deals the draft as cards, and levels a room from its row. |

### Results

All PASS: `tests/prestige_tests.gd` (Q1–Q8, 50 checks) and `tests/ui_tests.gd` (Q9). Looked at with `capture_ui.gd` (`v06b_hq_sell.png`, `v06b_hq_draft.png`). Every earlier rule suite passes unchanged, and the pacing suite's results are exactly as before (still the v0.6a tuning FAILs; HQ isn't reached by a pacing run that can't sell).

### On screen

- HQ is the fifth tab and opens at £1,000,000 best Operation Value, as D005 set.
- **Sell the Franchise:** what selling now pays and what it keeps; the button reads "Sell (+N credits)", then "Tap again to sell".
- **HQ Facilities:** credits, "Open a new room (N credits)", then the draft as two cards (name and Level 1 effect); then one row per room with its level, effect and "Lv N+1: cost" (or Max).
- The Tech Tree shows discounted costs once the Test Kitchen is open.

## Assumed

- **G8:** the credits formula, the room prices (5 × n to open, 2 × level to level up), and when a draft is dealt (when a room is paid for).
- **G16:** Night Watchman's Desk stops at Level 8 (+8 hours), the brief's stated maximum.
- **G19:** level steps after Level 1 as in the table, and Seed Capital beyond the brief's four amounts (×5 a level, cap 10).
- Selling needs a second tap; there's no undo.
- Victoria Sterling's lower threshold (£800,000) waits for the Shift Roster (v0.7).
