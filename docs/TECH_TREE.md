# Tech Tree

Brief §4: a web of projects radiating from `[00] Kitchen Table`, researched instantly by turning in crops, mashes and bottles from stock. v0.3 builds the slice Tier 2 needs ([D007](DECISIONS.md)): the root, the East Wing's Tier 2 blueprints, the West Wing's Delivery Van, and the North Wing's first node ([D008](DECISIONS.md)). The rest of the five wings comes in v0.4 and later (G9).

## Rules

- The tab opens at £750 Operation Value ([ECONOMY.md](ECONOMY.md#tab-thresholds-g5-d005)), with `[00] Kitchen Table` already researched (free).
- A node can be researched when every node it hangs from is researched and the stock holds its whole cost. Researching takes the items at once: no timers (brief §4).
- Research is permanent for the run. Prestige resets it (v0.6).
- The web is drawn as wings radiating from the centre, East to the right and West to the left, with each node joined to the ones it needs. Locked nodes show their cost; nodes out of reach are dimmed.

## The v0.3 slice

Costs are GUESSES tuned in the build, paid mostly in Table Mild. Tier 1 bottles are both cash and the tree's currency (brief pillar 3), so every node is a choice between selling and researching.

| Id | Node | Wing | Needs | Cost | Effect |
| --- | --- | --- | --- | --- | --- |
| 00 | Kitchen Table | Centre | — | free | The root |
| N1 | Calloused Thumbs | North | 00 | 10 Table Mild | +2 Bell Peppers a press (brief §4; [D008](DECISIONS.md)) |
| E1 | Crop Blueprint: Jalapeño | East | 00 | 3 Table Mild | Jalapeño Plot can be bought |
| E2 | Culinary Blueprint: Verde Mash | East | E1 | 10 Table Mild | Verde Mash recipe (15 Jalapeño) |
| E3 | Crop Blueprint: White Vinegar | East | E1 | 10 Table Mild + 5 Sweet Pepper Mash | White Vinegar Plot can be bought |
| E4 | Culinary Blueprint: Pickled Brine | East | E3 | 10 Table Mild + 5 Sweet Pepper Mash | Pickled Brine recipe (10 Vinegar + 5 Bell) |
| E5 | Culinary Blueprint: Bistro Verde | East | E2, E4 | 20 Table Mild | Bistro Verde recipe (1 Verde Mash + 1 Pickled Brine, £25) |
| W1 | The Delivery Van | West | 00 | 15 Table Mild | Auto-Sell sliders (below) |

The Tier 2 path (E1–E5) costs 53 Table Mild and 10 Sweet Pepper Mash, about £285 of sales given up. The draft costs (105 and 15) are in git history. Why they came down is in [FACTORY.md](FACTORY.md#what-moved-from-the-draft-each-change-measured).

On screen, the web is drawn on a grid around the Kitchen Table, with each node joined to the ones it needs. Researched nodes and their links are green; nodes that can be researched now are outlined in orange; locked ones are dimmed. Tapping a node shows what it does, its cost against what's in stock, and Research.

## The Delivery Van (brief §3, §4)

- Each sauce gets an Auto-Sell slider from 0% to 100%, in steps of 10%. It starts at 100% for every sauce when the Van is researched.
- When a line finishes a bottle, that share of it is sold at once at full value. The rest goes into stock. A fraction carries over per sauce, so at 30%, 3 bottles in every 10 are sold.
- Sell Batch still sells whatever is in stock, by hand.

## Criteria (v0.3)

The pacing criteria are in [ECONOMY.md](ECONOMY.md#criteria-v03) (N3–N6). Rule checks, all PASS (`tests/tech_tests.gd`):

| Id | Criterion | Result |
| --- | --- | --- |
| R1 | A node can't be researched before its parents, or without its whole cost in stock; a refused research changes nothing. | PASS |
| R2 | Research takes exactly its cost and is permanent across a save and reload. | PASS |
| R3 | Each blueprint opens exactly what it names: the plot can be bought, or the recipe can be assigned. | PASS |
| R4 | At 100% Auto-Sell, a factory earns the same as one sold by hand with Sell Batch, to the penny. At 0% everything goes to stock. At 30%, 3 bottles in 10 are sold. | PASS (10-minute factory runs) |
