# Prestige (v0.6b)

**Names since D042** ([INGREDIENTS.md](INGREDIENTS.md#the-ladder-since-d042)): Tabasco is Thai Chili, Habanero is Caribbean Red Habanero, Red Savina is Chocolate Habanero (Savina Gold is Cocoa Loco), Carolina Reaper is Alabama Grim, Pepper X is Pepper Y, and Cane Sugar is Pineapple (Caramelized Glaze is Charred Pineapple Glaze). This doc keeps the names it was written with.

Brief §6: once a run's Operation Value reaches £1,000,000, the player can **sell the franchise**. That resets the run and pays **Franchise Credits**, spent on **HQ Facility rooms** that last across runs. A new room comes from a **2-card draft**. This first part builds the loop itself: selling, credits, the 12 rooms with their draft and levels, and the brief's anti-exploit cost formula. The second part adds what changes on repeat runs: Standard Operating Procedures and Tier 6 ([below](#part-2-standard-operating-procedures-and-tier-6)).

Status: **built** (rules, save v7, the HQ tab), all criteria PASS. It doesn't depend on v0.6a's tuning: the rules are checked with games set up directly, at any Operation Value.

## Rules

- **Selling** is offered on the HQ tab while the run's Operation Value is at least $10,000,000 (D035; £1,000,000 before). It asks for a second tap to confirm.
- **Credits** follow Idle Planet Miner's table (D035): 10 at $10M, 30 at $100M, 60 at $1B, 101 at $10B, 150, 210, 285, 367, 459 a decade on, each next decade 10 more than the last step after that; in a straight line in Operation Value between decades, rounded, then × (1 + Executive Lounge), rounded. So 11 at $12.5M, 12 at $17.5M. Until D035 it was ⌊10 × log₁₀(OV ÷ £100,000)⌋.
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

## Part 2: Standard Operating Procedures and Tier 6

Status: **built**, all criteria PASS ([D034](DECISIONS.md)). No save change: research and `account.prestiges` were already saved.

A sale buys HQ rooms, but the run that follows is the same ladder again. Part 2 gives repeat runs two things the first run doesn't have: the early Tech Tree researching itself (brief §4, West Wing), and a sixth tier above Phantom Smokehouse (D006).

### Rules

- **After the first sale.** Tier 6's nine nodes and Standard Operating Procedures open only once the franchise has been sold at least once (`account.prestiges`, saved since v7). Before that they show on the web, muted, saying "Opens after your first franchise sale."
- **Standard Operating Procedures** (W7, West Wing, after The Delivery Van; 10 Table Mild): once researched, every second the game looks at each node it could research now (every parent researched, not a fork, the tab open) and researches it **free** if its cost is worth less than 1% of an hour's output (D040: back to the brief's 1%, free; D038's 5% and D039's paying in cash were measured and dropped). Nodes are looked at in the tree's file order, so a node's children are looked at on a later second.
  - **A cost's worth** is its items at their base values (D004), after the Test Kitchen.
  - **An hour's output** is 3,600 × the value a second of the bottles from lines that are running: each running line's sauce value ÷ its cycle. So 1% is 36 seconds of bottles.
  - **Forks are never taken**: either/or is the player's choice (D026).
  - The same rule runs in the offline catch-up, once a step.
- **Tier 6** (G17, assumed like D029): three peppers from the ladder ([INGREDIENTS.md](INGREDIENTS.md)), each with its own mash and sauce, values by D004.

| Pepper | Value | Plot | Mash | Sauce | Line |
| --- | --- | --- | --- | --- | --- |
| Trinidad Moruga Scorpion | £16.40 | £150,000; 12 every 3.2 s | Moruga Mash: 60 Moruga, 16 s, £1,968 | **Scorpion Sting** £14,920: 1 Moruga Mash + 1 Savina Gold | 20 s |
| Carolina Reaper | £24.40 | £400,000; 16 every 3.6 s | Reaper Mash: 80 Reaper, 18 s, £3,904 | **Widowmaker Reserve** £40,000: 1 Reaper Mash + 1 Phantom Smokehouse + 1 Sweet Heat Reserve (D006) | 22 s |
| Pepper X | £52 | £1,500,000; 20 every 4.0 s | Pepper X Mash: 100 Pepper X, 20 s, £10,400 | **Extinction Event** £100,000: 1 Pepper X Mash + 1 Scorpion Sting (named Event Horizon until D035; that's the last fictional pepper's name) | 24 s |

Since D035 these are in dollars at Idle Planet Miner's values: Moruga $1,600, Reaper $3,500, Pepper X $7,800; Scorpion Sting $1.09M, Widowmaker Reserve $3.34M, Extinction Event $9.35M; plots $9.5M, $29M and $130M (Moruga $5M since D041).

Each plot feeds one vat at base, as in v0.6a. The blueprints follow v0.6a's pattern (D010): each rung's three nodes are paid in the rung below's sauce: Moruga in Phantom Smokehouse (20, 20 + 10 Ghost Mash, 30), Reaper in Scorpion Sting, Pepper X in Widowmaker Reserve. They run on east from Phantom Smokehouse (E39–E47).

### Criteria (part 2)

| Id | Criterion |
| --- | --- |
| Q10 | Before any sale, no Tier 6 node and not Standard Operating Procedures can be researched, even with every parent and the full cost in stock; after one sale they can. |
| Q11 | Tier 6's mashes are worth 2× their inputs and its sauces 5× the raw value inside (V1, which covers every recipe); Phantom Smokehouse → Scorpion Sting → Widowmaker Reserve → Extinction Event each climb ×1.6–3.0 (×2.0–3.4 since D035); each Tier 6 plot feeds one vat at base (V3). |
| Q12 | With Standard Operating Procedures: within one second a reachable node whose cost is worth under the bar (1% of an hour's bottles) is researched, free (D040); one at or over it isn't; a fork side never is; a node with a parent missing isn't, and is on the second after its parent. Without it, nothing is. |
| Q13 | After time away (the catch-up), every node under the bar with its parents done has been researched, as in play. |
| Q14 | On screen: a Tier 6 node before the first sale says it opens after the first sale; Standard Operating Procedures says what it does. |

### Results (part 2)

All PASS: `tests/prestige_tests.gd` (Q10, Q12, Q13), `tests/full_run_tests.gd` (Q11; V1 now covers Tier 6's six recipes, V7 every node after a sale) and `tests/ui_tests.gd` (Q14). Looked at with `capture_ui.gd` (`w12_tier6_locked.png`, `w12_sop.png`). The pacing suite is unchanged: a first run never reaches an after-sale node.

Q11's bound is ×1.6–3.0, not v0.6a's ×1.6–2.7: Phantom (£5,200, the brief) and Widowmaker (£40,000, D006) are 7.7× apart, so one sauce between them climbs about ×2.8 either side.

### Assumed (part 2)

- **G17:** Tier 6's recipes, values, plot prices and timings above. Plot prices and line times are GUESSES; no pacing measures a second run yet (W17).
- **Standard Operating Procedures:** the brief's "1% of current production throughput" read as 1% of an hour of the bottles running lines make (D040), valued at base; research it grants is free, since a cost that small isn't worth charging (D040); it's an in-run node (researched each run, cheap) that opens after the first sale; forks are left to the player.
- Tier 6 opens with the first sale, not with an HQ room.

## The second run (W17)

Status: **all PASS** with SOP free at 1% (D040), measured three ways (below), and again after D041. Nothing measured a run after a sale until now: rooms, Standard Operating Procedures, Tier 6's prices and late growth (W21) were all unchecked. `tests/second_run_tests.gd` plays the pacing player through run 1, sells, spends the credits, and plays run 2.

### The player's policy (assumed)

- **It sells at 3:00 of run 1**, the end of the first run's ladder (D035: the sale opens at about 2:08, and pushing on pays more).
- **It spends every credit:** it opens rooms while it can, taking the first room from each draft in this order: Fermentation Cellar, High-Speed Cannery, Seed Vault, Tasting Room, Seed Capital Office, Hydroponics Bay, Cooperage, Glassworks, Test Kitchen, Ergonomics Lab, Executive Lounge, Night Watchman's Desk. Then it levels its cheapest room until the credits run out.
- **In run 2 it plays as in run 1**, with Standard Operating Procedures researched right after The Delivery Van, the Tier 6 blueprints after the last v0.6a node, and a Scorpion Sting layout once that sauce is open. After-sale nodes are skipped in run 1, so run 1 plays exactly as the pacing suite's.

### Criteria

| Id | Criterion |
| --- | --- |
| Y1 | Run 2 reaches the $10M sale in at most 85% of the time run 1 took. |
| Y2 | In run 2, Standard Operating Procedures researches at least 15 nodes by itself. (Its first within 10 minutes of being bought was dropped by D040, after it failed: under the brief's rule SOP picks nodes up as production outgrows them, not at once.) |
| Y3 | Run 2 makes its first Scorpion Sting (Tier 6) by 3:15. |
| Y4 | From 1:50 to 3:00 of run 2, never more than 300 s without a purchase or research (as U2). |

Reported, not judged: run 1's credits at 3:00, the rooms bought, and run 2's Operation Value at 3:00 and 3:15 (for W21).

### Results

**Since D041 (Idle Planet Miner's early flow), all PASS:** run 1 reaches the sale at 2:01:56 and sells at 3:00 for 30 credits (Operation Value $101M); the player opens Test Kitchen, Ergonomics Lab and Hydroponics Bay. Run 2 reaches the sale at 1:18:33, **64% of run 1** (Y1); SOP, bought at 16:17, researches 38 nodes, the first at 21:43 (Y2); the first Scorpion Sting at 2:01:09 (Y3); the longest wait 270 s (Y4). Run 2 is worth $659M at 3:00 and $846M at 3:15. Y4 first failed at 511 s, saving for the $9.5M Moruga Scorpion Plot, which run 2 now reaches with less income; it costs $5M since.

As measured for D040, before D041: run 1 reaches the sale at 2:07:58 and sells at 3:00 for **31 credits** (Operation Value $117M). The player opens Cooperage, Fermentation Cellar and Glassworks (5 + 10 + 15 credits) and has 1 left.

| Id | SOP 1%, free (D040, now) | SOP 5%, free (D038) | SOP 5%, paying cash (D039) |
| --- | --- | --- | --- |
| Y1 | **PASS:** the sale at 1:33:44, 73% of run 1 | PASS: 56:50, 44% | **PASS:** 1:47:35, 84% |
| Y2 | **PASS:** 32 nodes (the first 16½ min after SOP; that bar is dropped) | PASS: 67 nodes, the first 19 s after | **FAIL:** 22 nodes, the first 17 min after (33:41) |
| Y3 | **PASS:** the first Scorpion Sting at 2:22:31 | PASS: 1:23:42 | **PASS:** 2:40:40 |
| Y4 | **PASS:** longest wait 256 s | PASS: 89 s | **FAIL:** 328 s |
| Run 2 at 3:00 | $662M | $1.69B | $345M |
| Run 2 at 3:15 | $936M | $2.0B | $585M |

**Why Y2 first failed at 1%** (before D040 dropped its 10-minute start): by the time SOP was bought, the player had researched every node cheap enough, and the next (Double-Tap, 15 Bistro Verde, $6,375) was over a bar of about $700.

**What 5% does beyond Y2:** research SOP grants is free, so at 5% it isn't just automation: it saves run 2 most of its research costs. Run 2 reaches the sale in under an hour and is worth **$1.69B at 3:00 and $2.0B at 3:15** (14× run 1 at 3:00), after only three rooms. Nothing bounds how much faster run 2 may be (Y1 only asks for faster): W24.

**Why paying cash fails Y2 and Y4:** the pacing player spends all its cash on stations and upgrades the moment it can, so SOP almost never finds cash to pay with; it researches less than at 1% free, and later. A real player spends much the same way. Paying in items instead fails the same way through Auto-Sell.

## When the first sale comes (W31, a proposal, not built)

**The question.** The owner's pacing guide for this session says the first prestige should arrive within roughly the first hour. Today the sale opens at $10M Operation Value, which the pacing player reaches at 2:02 (U1's bar is 2:00–2:30, the owner's choice in D035). The two don't agree, and the sale's timing is the owner's to set, so nothing here is built.

**Measured on `main` (this session, no Cargo from PR #20):**

| | 15 min | 30 min | 45 min | 1:00 | 1:15 | 1:30 |
| --- | --- | --- | --- | --- | --- | --- |
| Pacing player | $12.4K | $54.6K | $146K | $522K | $1.02M | $2.45M |
| Casual player | $9.9K | $39.8K | $109K | $364K | $640K | $1.18M |

**Options:**

1. **Keep D035** (sale at $10M, about 2:00). Nothing changes; the first hour has no reset to look forward to, only the HQ tab's price on its locked label.
2. **An early sale** (recommended if the owner wants the hour): the sale opens at about $400K, paying 5 credits, exactly one room, with a new first row in the credit table and $10M still paying 10. Two numbers in `tuning.gd` (`PRESTIGE_OV`, `CREDIT_TABLE`) and the Executive Lounge rounding. It's easy to undo. Knock-ons to re-measure, with bars set first: U1's last band, U8 (a night from 25:00 already reaches about $510K, so a night would hand over the early sale), Y1–Y4 (run 2 starts with one room, not three), and SOP's 1% bar, which is what makes a repeat run fast.
3. **Speed the whole run up** so $10M lands by about 1:00: every tier twice as fast, which undoes most of v0.6a–v0.6d's measured curve. Not recommended.

**Why option 2 rather than 3:** Idle Planet Miner's lesson is a small first reset that teaches the loop, then bigger ones; the ladder past $400K (Tiers 3–5, Phantom) still pays more credits for pushing on, so an early seller gives up credits, not content. **The cost:** a player who sells at the first chance meets Tier 3 onwards a run later, and SOP's free research makes that second run quicker, which is W24's floor question again.
