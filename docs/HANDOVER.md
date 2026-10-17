# Handover

## Where it's at

v0.4 Tech Tree is built, on top of v0.1–v0.3 (PRs #1–#5, still to merge). The tree has 34 nodes.
- **North Wing:** Double-Tap, Ergonomic Grip (hold the button), Heat (a bar under the button, up to +50% on every sale), Slow Burn, Overclock I–III, and the Automated Piston.
- **East Wing:** Tier 3 (Cayenne, Garlic, Roasted Garlic Paste, Cayenne Mash, Classic Louisiana at £140) and Hydroponic Bell Peppers.
- **South Wing:** Slot Expansion I–II (caps 5 and 4), Heavy Flint Glass and Foil Neck Wraps, Zero-Waste Piping I–II, and Overdrive Turbines with the Factory Overdrive button.
- **West Wing:** the Raw Overflow Valve with keep amounts, Smart Stockpiling (pins), and the Market Ticker.
- **Bridges:** Byproduct Recycling and Franchise Auditors.
- **Also:** Crop Quality on every plot, one seeded random stream, and saves at v4 (migrating v1–v3).

Checks:
- All criteria pass: R5–R18, H1–H3, S7–S10, pacing M1–M7, and v0.2–v0.3's F1–F8 and N1–N8.
- 535 rule and screen checks.
- The headless boot is clean and the web export works.
- Every new screen was captured and looked at.

What moved from the draft:
- Cheaper Tier 3 research and stations.
- The pacing player's research order and saving rules.

The details are in [TECH_TREE.md](TECH_TREE.md#v04-the-rest-of-the-tree), [FACTORY.md](FACTORY.md#v04-tier-3-and-the-factory-upgrades) and [ECONOMY.md](ECONOMY.md#results-v04).

## Open decisions

- **W7: the run is ahead of the 3-hour curve.** £100k arrives at 1:29 (target 1:50), and it's £379k by 1:50, because Heat, packaging, Overclock and a second Louisiana line stack from about 1:20. Recommendation: wait for v0.6. When Tiers 4–5 and Prestige exist, set the whole curve against D005 with "not before" bounds as well as deadlines. Retuning now would have to be redone once Tiers 4–5 land.
- **G1, platform for testing** (unchanged): Web on the phone is recommended until v1.0.

## Next

1. Settle G11 (offline cap and speed) for v0.5 Offline.
2. W1: open the Web build on a phone.

Touches: data (Tier 3, 26 nodes, slot caps), the simulation (Heat, presses, effects, valve, pins, market, Overdrive, Crop Quality, random stream, save v4), the pacing player, the screen, and docs. Stubbed or open: W1–W7. Next: G11, because v0.5 can't be built without it.
