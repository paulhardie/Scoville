# Onboarding

**Superseded by D044** ([LAYOUT.md](LAYOUT.md#step-2-the-dashboard-from-the-first-launch-d044)): the game opens on the full dashboard and nothing is revealed at a milestone. O1, O3's and O4's thresholds and O8 are retired; the early run is guided by one ringed next action instead. Kept below as the history of v0.1–v0.6.

Brief §2: the screen starts as one unlabelled button and reveals itself as the player crosses milestones. v0.1 builds Stages 0 and 1, v0.2 builds Stage 2 ([FACTORY.md](FACTORY.md)), and v0.3 builds Stage 3 (below).

The rules are in `src/core/game.gd`, the numbers in `src/core/tuning.gd`, and the screen in `src/ui/main.gd`.

## Stages 0 and 1

- **Stage 0:** a fresh game shows only a large, unlabelled button in the centre. Each press picks 1 Bell Pepper and plays a short squash animation. The first press fades in `Bell Peppers: 1` at the top.
- **Stage 1:** at 20 Bell Peppers, a status bar slides down with `Cash: £0.00` and `Sell Raw Peppers (£0.10/ea)`.

Assumed where the brief is open (the owner can overrule):

- "20 Peppers" counts peppers picked in total, not peppers held, so selling can't hide the bar again.
- Sell Raw Peppers sells every pepper held, and is disabled with none.
- Every reveal is permanent for the save.

## Criteria (v0.1)

| Id | Criterion | Checked by |
| --- | --- | --- |
| O1 | A fresh game shows the button and nothing else: no text, counter, bar or tab. | `ui_tests.gd`, screenshot `start.png` |
| O2 | Each press adds exactly 1 Bell Pepper. | `core_tests.gd` |
| O3 | The counter appears after the first press, not before, and reads `Bell Peppers: N`. | `core_tests.gd`, `ui_tests.gd` |
| O4 | The status bar appears at 20 peppers picked, not at 19, with `Cash: £0.00` and the sell button. | `core_tests.gd`, `ui_tests.gd` |
| O5 | Selling pays £0.10 a pepper and empties the stock; with no peppers it does nothing. | `core_tests.gd` |
| O6 | Reveals stay after selling and after a save and reload. | `core_tests.gd` |
| O7 | An unreadable save is refused without changing the game, and kept as `save.json.bad`. | `core_tests.gd` (refusal); the `.bad` copy is not tested |

## Stage 3 (v0.3)

- **At £400 Operation Value**, a bottom navigation bar slides up with five tabs: **Farms** and **Processing** open, and **Tech Tree**, **Shift Roster** and **HQ Facilities** shown as `[ ? ]`. The vats and lines move from Farms to Processing.
- Each locked tab opens at its Operation Value ([ECONOMY.md](ECONOMY.md#tab-thresholds-g5-d005)): Tech Tree at £750, Shift Roster at £10,000 (provisional, and not before v0.7 builds it), HQ at £1,000,000. Tapping a locked tab shows its threshold.
- Opened tabs stay open "for the account" (brief §2), so a Prestige (v0.6) doesn't lock them again. The account-wide record lives beside the run in the save.
- Operation Value appears under Cash in the status bar from Stage 3.

### Criteria (v0.3)

| Id | Criterion | Result |
| --- | --- | --- |
| O8 | The nav bar appears at £400 Operation Value, not before, with Farms and Processing open and three `[ ? ]` tabs. | PASS (`tech_tests.gd`, `ui_tests.gd`) |
| O9 | The Tech Tree tab opens at £750 and not before. Shift Roster and HQ stay locked in v0.3; from v0.6b HQ opens at £1,000,000 (PRESTIGE.md). | PASS |
| O10 | Opened tabs stay open after a save and reload, and are kept outside the run's state so a Prestige can't reset them. | PASS: the save holds `account.best_ov` beside `run` |

On screen, the stock line in the upper viewport switches to short names (`Bell 53 · Jalapeño 249 · …`) once more than three items are in play.
