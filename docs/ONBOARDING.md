# Onboarding

Brief §2: the screen starts as one unlabelled button and reveals itself as the player crosses milestones. v0.1 builds Stages 0 and 1; Stages 2 and 3 come with v0.2 and v0.3 ([ROADMAP.md](ROADMAP.md)).

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
