# Game Design Document & Architecture Brief: Hot Sauce Empire (v1.0)

The owner's brief, kept as given (only the markdown is tidied). It's the design source for the game ([D002](DECISIONS.md)). Where it leaves a number or rule open, the gap is a row in [BACKLOG.md](BACKLOG.md); don't fill it silently.

**Platform:** Mobile (iOS / Android)
**Genre:** Idle Incremental / Factory Management
**Architecture:** Local, Offline-First (v1.0)
**Reference Frameworks:** Idle Planet Miner (Production Spine, Tech Web, Prestige Rooms, 24h Challenges) & The Tower (Split-Viewport UI, Card/Manager Deck Building, Breakthrough & Mastery Scaling)
**Currency Standard:** GBP (£)

---

## 1. Executive Summary & Core Design Pillars

Hot Sauce Empire is a mobile idle incremental game where players scale a culinary manufacturing operation from a single, uncontextualised button into a multi-million-pound franchise. The design eliminates common genre friction points—such as dead duplicate card pulls, real-time research timer bottlenecks, and obsolete early-game clicking—by weaving active input, multi-tier crafting, and permanent account progression into a unified mathematical model.

### Core Pillars

1. **Strict Progressive Disclosure:** The game launches to a blank screen containing only an unlabelled button. All counters, markets, production lines, and navigation tabs remain hidden until the player crosses specific inventory and valuation milestones during the first 15 minutes.
2. **Persistent Active Hustle:** The central Blank Button never becomes obsolete. A dedicated branch on the In-Run Tech Tree evolves its mechanical function from flat crop harvesting to factory-wide timer overclocks, global sale multipliers, and passive self-pressing pistons.
3. **Interconnected Dual-Use Economy:** Crafted sauce bottles serve both as the primary revenue source (when sold for Cash) and the literal currency spent to unlock nodes on the In-Run Tech Tree. Higher-tier recipes require lower-tier mashes and finished bottles as inputs, keeping starter farms and vats mechanically relevant throughout the entire run.
4. **Deck-Building Over Micro-Skill Trees:** Named Managers feature bespoke character art and three rarity tiers (White/Blue/Gold). Rather than managing bloated individual skill trees per character, strategic depth comes from active **Shift Roster** loadout choices and a linear 1-to-5 Star promotion track featuring **3-Star and 5-Star Breakthrough Perks**, culminating in an endgame **Mastery Tier**.

---

## 2. Progressive Onboarding & Split-Viewport UI

To preserve mobile spatial consistency and muscle memory while progressively revealing complexity, the screen transitions from a full-screen button into a permanent **Split-Viewport Dashboard**.

### The 4-Stage Onboarding Sequence

- **Stage 0 (First Launch — The Blank Hook):** The game boots to an empty canvas featuring only a large, unlabelled, tactile button in the center of the screen. No counters, no text, no tabs. Upon the first press, a tactile animation plays and a minimalist counter fades in at the top: `Bell Peppers: 1`.
- **Stage 1 (First Liquidity — 20 Peppers):** A top status bar slides down displaying `Cash: £0.00` alongside a manual action button: `Sell Raw Peppers (£0.10/ea)`.
- **Stage 2 (The Operation Deck — £10 Cash):** The Blank Button smoothly compresses into the **Upper Viewport** (top 35% of the screen, which remains fixed and eventually displays the Blank Button, the Scoville Hype bar, and live production telemetry). The **Lower Control Deck** (bottom 65%) slides up, revealing the first operational tab (`Farms`) where players buy their first automated Bell Pepper plot and Mash Vat.
- **Stage 3 (Full Navigation Reveal):** A bottom navigation bar appears with locked `[ ? ]` icons. As the player crosses specific Operation Value thresholds across their first run, the remaining tabs unlock permanently for the account:
  - **Tab 1: Farms (Harvesting)** — Automated raw crop generation.
  - **Tab 2: Processing (Vats & Bottling)** — Two-stage refinement, recipe assignment, and packaging.
  - **Tab 3: Tech Tree (In-Run Projects)** — The 5-quadrant research web.
  - **Tab 4: Shift Roster (Managers)** — Active card deck loadout and Golden Seed recruitment.
  - **Tab 5: HQ Facilities (Prestige)** — Permanent corporate rooms (unlocks upon reaching £1,000,000 Operation Value).

---

## 3. Core Production Loop & Recipe Dependencies

Every run operates on a three-stage refinement spine. Cash is never spent on recurring consumable supplies; it is used strictly for Capital Expenditure (unlocking parallel slots and upgrading station speed, yield, and packaging tiers).

### The Three Production Columns

1. **Column 1 — Farms (Raw Input):** Passively harvests raw peppers and secondary aromatics on a cycle timer.
   - Cash Upgrade Knobs: Harvest Speed, Yield per Cycle, Crop Quality Chance.
2. **Column 2 — Mash Vats (Smelting):** Consumes raw crops in fixed ratios over a set timer to produce intermediate **Sauce Mash**.
   - Cash Upgrade Knobs: Vat Cycle Speed, Parallel Vat Slots.
3. **Column 3 — Bottling Plant (Crafting):** Combines Sauce Mash, secondary ingredients, and lower-tier finished bottles into high-value **Hot Sauce Bottles**.
   - Starter Momentum Mechanic: Unlocking the first Bottling Line grants a one-time **Starter Crate of 50 Bottles** that processes available mash rapidly before settling into the line's mechanical base speed.
   - Cash Upgrade Knobs: Bottling Speed, Packaging Tier (multiplies base bottle value), Parallel Lines.

### Early-to-Mid Run Recipe Dependency Matrix

| Tier | Raw Crops (Farms) | Vat Recipes (Intermediate Mash) | Bottling Line Recipes (Finished Sauce) | Base Bottle Value |
| :--- | :--- | :--- | :--- | :--- |
| **1 (Starter)** | Bell Pepper | **Sweet Pepper Mash** (10 Bell Peppers) | **Table Mild** (1 Sweet Pepper Mash) | £5 |
| **2 (Early)** | Jalapeño, White Vinegar | **Pickled Brine** (10 Vinegar + 5 Bell Peppers)<br>**Verde Mash** (15 Jalapeños) | **Bistro Verde** (1 Verde Mash + 1 Pickled Brine) | £25 |
| **3 (Mid-Run)** | Cayenne, Garlic | **Roasted Garlic Paste** (20 Garlic)<br>**Cayenne Mash** (25 Cayenne + 1 Pickled Brine) | **Classic Louisiana** (1 Cayenne Mash + 1 Garlic Paste) | £140 |
| **4 (Late-Run)** | Habanero, Cane Sugar | **Caramelized Glaze** (30 Sugar + 1 Garlic Paste)<br>**Habanero Mash** (40 Habanero) | **Sweet Heat Reserve** (1 Habanero Mash + 2 Caramelized Glaze + 1 Table Mild) | £850 |
| **5 (Prestige Push)** | Ghost Pepper, Smoked Oak | **Liquid Smoke** (25 Oak + 2 Pickled Brine)<br>**Ghost Mash** (60 Ghost Pepper) | **Phantom Smokehouse** (1 Ghost Mash + 1 Liquid Smoke + 1 Classic Louisiana) | £5,200 |

### The Dual-Use Resource Sink & Auto-Sell Loop

Finished Hot Sauce Bottles sit in the player's inventory and serve two competing purposes:

- **Liquidation (Cash):** Initially, players manually tap `Sell Batch` to convert bottles into cash. Unlocking **The Delivery Van** early on the Tech Tree introduces an **Auto-Sell Slider (0% to 100%)** per sauce type, allowing instant passive liquidation at 100% market value.
- **Tech Tree Investment:** Players dial Auto-Sell down (or use the Smart Stockpiling pin feature) to accumulate specific bottles and mashes required to pay for nodes on the **In-Run Tech Tree**.

---

## 4. The 5-Quadrant In-Run Tech Tree

To avoid real-time timer clutter, all research during a run happens instantly by turning in stockpiled crops, mashes, and bottles on a wide, multi-directional project web radiating from the central `[00] Kitchen Table` node. The web is organized into five color-coded compass wings connected by hybrid Bridge Nodes.

### North Wing: The Manual Hustle (Blank Button Evolution)

Dedicated to active play and scaling the unlabelled button throughout the run:

- **Early Nodes:** Calloused Thumbs (+2 Base Peppers per tap) -> Double-Tap Mechanics (10% chance for a tap to register twice) -> Ergonomic Grip (holding down the button auto-taps 2 times/sec).
- **Left Sub-Path (Factory Overclock):** Each press of the Blank Button shaves 0.05s -> 0.15s off all active Mash Vat and Bottling Line timers.
- **Right Sub-Path (Scoville Hype):** Unlocks the **Heat Meter** below the button. Rapid tapping builds Heat up to 100%, granting up to a +50% global cash sale multiplier while maintained.
- **Outer Rim Capstone:** Automated Piston (passively presses the Blank Button once per second even while idle, triggering all active Button perks) and Golden Seed Extractor (0.1% chance per manual tap at 100% Heat to drop 1 Golden Seed, capped per run).

### East Wing: Agronomy & Culinary R&D (The Recipe Ladder)

The primary progression trunk required to increase Operation Value:

- **Crop Blueprints:** Unlocks the ability to purchase higher-tier Farm plots with cash (Jalapeño -> White Vinegar -> Cayenne -> Garlic -> Habanero -> Cane Sugar -> Ghost Pepper -> Smoked Oak -> Carolina Reaper).
- **Culinary Blueprints:** Unlocks the intermediate Mash and finished Sauce Bottle recipes.
- **Outer Rim GMO Boosters:** Deep nodes that supercharge early-tier crops to keep up with late-game dependencies (e.g., Hydroponic Bell Peppers multiplying Bell Pepper farm speed by 4x).

### South Wing: Industrial Engineering (Factory Floor & Efficiency)

Upgrades mechanical throughput and packaging multipliers (heavily weighted toward Mash turn-ins):

- **Slot Expansion:** Unlocks the right to purchase additional parallel Mash Vat and Bottling Line slots with cash.
- **Packaging Tiers:** Upgrades physical bottles across all lines: Thin Plastic (1.0x Base) -> Heavy Flint Glass (1.5x Value) -> Foil Neck Wraps (2.2x Value) -> Embossed Artisan Decanters (3.5x Value).
- **Zero-Waste Piping:** Reduces raw crop input ratios required for Mash Vats by 10% -> 20%.
- **Overdrive Turbines:** Boosts global Vat/Bottling speeds by +25% and unlocks the **Factory Overdrive** active button (15-minute cooldown; doubles all Vat and Bottling speeds for 60 seconds).

### West Wing: Logistics, Market & Automation

Governs cash flow, QoL automation, and offline efficiency:

- **The Delivery Van:** Unlocks the 0%–100% Auto-Sell sliders for finished bottles.
- **Raw Overflow Valve:** Allows auto-selling excess raw crops and intermediate mashes.
- **Smart Stockpiling:** Pinning any locked Tech Tree node automatically pauses Auto-Sell on the exact bottles required for that node until the target quantity is met, then automatically resumes 100% Auto-Sell.
- **Standard Operating Procedures (Auto-Research):** Automatically unlocks early-tier Tech Tree nodes on repeat runs once their item cost represents less than 1% of current production throughput.
- **Market Ticker:** Unlocks periodic local market fluctuations (2x–3x demand spikes on specific sauces for 30 minutes).
- **Night Shift Protocols:** Extends the current run's Offline production cap (+2 hours per node) and boosts offline speed.

### Cross-Wing Bridges (Synergy Nodes)

- **North-to-West Bridge (Executive Perks):** Unlocks the **Head Chef Amplifier Slot** in the Shift Roster for the run and upgrades its multiplier from 1.25x -> 1.5x -> 1.75x.
- **South-to-East Bridge (Byproduct Recycling):** Mash Vats have a 25% chance upon completing a cycle to generate seeds that automatically level up the lowest-level Farm by +1 for free.
- **West-to-South Bridge (Franchise Auditors):** Increases the Operation Value appraisal of all stockpiled inventory by +20% to accelerate Prestige thresholds.

---

## 5. The Shift Roster (Managers & Golden Seeds)

Managers are bespoke, named characters with custom art, personalities, and mechanical abilities. Players earn **Golden Seeds** (premium currency) via daily local milestones, achievements, rare button procs, and 24-Hour Challenges. Golden Seeds are used to open **Recruitment Packs** and unlock active **Shift Roster Slots** (scaling from 1 starter slot up to 15–18 slots as the total roster expands beyond the initial 12 launch characters).

(Note: In v1.1+, Golden Seeds will also serve as the currency sink for **Factory Modules**—hardware attachments slotted onto Vats and Bottling Lines with rolled substats.)

### The Head Chef Amplifier Slot & Mathematical Safeguard

The pinnacle slot at the top of the Shift Roster is the **Head Chef Slot**. Any Manager of any rarity can be placed in this slot to have their effects amplified by **1.5x** (scaling up to 1.75x via Tech Tree Bridges).

- **Anti-Exploit Multiplier Rule:** Rate, speed, yield, and cash value buffs receive the full 1.5x multiplier. Percentage trigger chances and cost reductions receive a capped additive boost (+10%) or multiplicative diminishing return so players can never reach 100% free upgrades or guaranteed infinite loops.

### Promotion, Breakthroughs & Mastery Lifecycle

1. **1-Star (Initial Unlock):** First pull unlocks the Manager and their **Core Ability**.
2. **2-Star & 4-Star (Stat Scaling):** Pulling duplicates fills the Manager's promotion bar (`1/3`, `1/5`, etc.), granting substantial numerical increases to their abilities.
3. **3-Star (Breakthrough Perk):** Unlocks a **Secondary Synergy Ability** displayed directly beneath their core text.
4. **5-Star (Max Promotion & Pool Removal):** Unlocks a **Capstone Passive** and **permanently removes that Manager from the Recruitment Pack drop pool**, guaranteeing zero wasted duplicate pulls.
5. **Endgame Manager Mastery:** Once a player unlocks every Manager in the roster and promotes all of them to 5-Stars, the **Mastery Tier** unlocks, allowing Golden Seed investment for massive late-game scaling spikes.

### Launch Roster Specifications (Initial 12 Managers)

#### Common Tier (White) — Foundational Backbone

1. **Barnaby "Dirt" Vance (The Botanist — Farms / Crit)**
   - 1-Star: Automated Farms have a 10% chance per cycle to yield a Mutant Crop worth 5x normal ingredients when fed into Mash Vats. (2/4-Star: 15% -> 20%).
   - 3-Star Breakthrough: Harvesting a Mutant Crop shaves 1 second off a random active Mash Vat timer.
   - 5-Star Max: Mutant Crops yield 10x normal ingredients and have a 5% chance to drop 1 bonus Bell Pepper per Farm level into inventory.
   - Mastery: Mutant Crop procs permanently increase that Farm's yield by +0.5% for the rest of the run (stacks infinitely).
2. **Big Sal (The Line Foreman — Bottling / Multishot)**
   - 1-Star: Bottling Lines have a 15% chance upon completing a cycle to spit out a second bottle for free without consuming extra Mash. (2/4-Star: 22% -> 30%).
   - 3-Star Breakthrough: Triggering a Double-Bottle grants that Bottling Line +25% cycle speed for 6 seconds.
   - 5-Star Max: Double-Bottle procs have a 20% chance to chain into a Triple-Bottle crate.
   - Mastery: Every 10th Double-Bottle proc produces a Golden Crate worth 25x cash value.
3. **Wrench (The Midnight Mechanic — Global / Free Upgrades)**
   - 1-Star: Every 60 seconds, automatically upgrades a random Farm, Vat, or Bottling Line by 1 level for free. (2/4-Star: 48s -> 35s).
   - 3-Star Breakthrough: Free upgrades have a 25% chance to grant +2 Levels instead of +1.
   - 5-Star Max: Always prioritizes upgrading the most expensive unlocked station first.
   - Mastery: Triggering a free upgrade makes all production lines run at 2x speed for 5 seconds.
4. **Mack "Leadfoot" (The Courier — Logistics / Auto-Sell Value)**
   - 1-Star: Increases the sale value of all Auto-Sold bottles by +20%. (2/4-Star: +35% -> +50%).
   - 3-Star Breakthrough: Every 50 bottles Auto-Sold grants an instant Cash Rebate equal to 10% of your current cheapest station upgrade cost.
   - 5-Star Max: When an Auto-Sell slider is set to 0% (while stockpiling for the Tech Tree), Mack still pays 25% of the bottle's cash value the moment it is crafted.
   - Mastery: Auto-Sold bottles count for 1.5x toward total Operation Value for Prestige calculations.

#### Uncommon Tier (Blue) — Bottleneck Breakers & Synergies

5. **Dr. Capsaicin (The Fermentation Alchemist — Vats / Conservation)**
   - 1-Star: Mash Vats have a 20% chance to start a cycle while consuming 0 raw ingredients. (2/4-Star: 30% -> 40%).
   - 3-Star Breakthrough: Free-input cycles complete in half the normal fermentation time.
   - 5-Star Max: Vats can pull raw crops directly from active Farms mid-harvest if inventory hits zero, preventing minor supply stalls.
   - Mastery: Free-input cycles produce Double Mash output.
6. **"Clicky" Vicky (The Ergonomics Coach — Blank Button / Active Scaling)**
   - 1-Star: Every manual press of the Blank Button counts as 2 presses toward all yields and Tech Tree effects. (2/4-Star: 3x -> 4x).
   - 3-Star Breakthrough: Tapping the button 10 times within 3 seconds triggers Phantom Finger, auto-tapping the button 5 times/sec for 10 seconds.
   - 5-Star Max: Each manual or Phantom tap has a 2% chance to instantly complete the progress bar of your furthest-along Bottling Line.
   - Mastery: Phantom Finger remains permanently active as long as you tap the screen at least once every 60 seconds.
7. **Penny Margins (The Supply Chain Shark — CapEx / Cost Reduction)**
   - 1-Star: Reduces Cash upgrade costs of all Farms, Vats, and Bottling Lines by 15%. (2/4-Star: 22% -> 30%).
   - 3-Star Breakthrough: Reduces Bottle and Mash item requirements for In-Run Tech Tree nodes by 20%.
   - 5-Star Max: Unlocking any Tech Tree node refunds 25% of the spent bottles back into inventory.
   - Mastery: Unlocking any Tech Tree node permanently increases global Cash earned by +5% for the rest of the run.
8. **Gus "Nightshift" (The Insomniac Guard — Global / Offline & Idle)**
   - 1-Star: Increases Offline production speed by +25% and extends Offline storage cap by +2 hours. (2/4-Star: +40% -> +60%, +4 hours).
   - 3-Star Breakthrough: While the app is open, not touching the screen for 60 seconds activates Quiet Hours (+30% Vat and Bottling speed until you tap again).
   - 5-Star Max: Returning from at least 30 minutes Offline triggers Morning Coffee Surge (3x global factory speed for 3 minutes).
   - Mastery: Offline production runs at 150% of active online speed.

#### Epic Tier (Gold) — Rule-Benders & Executive Archetypes

9. **Jean-Luc Scoville (The Artisanal Snob — Bottling / Heavy Value)**
   - 1-Star: Slows Bottling Lines by -30%, but coats bottles in wax, multiplying Bottle Cash Value by 2.5x. (2/4-Star: 3.2x -> 4.0x).
   - 3-Star Breakthrough: Wax-dipped bottles count as 2 bottles each when spent on In-Run Tech Tree nodes.
   - 5-Star Max: Eliminates the -30% speed penalty entirely while retaining the 4.0x value multiplier.
   - Mastery: Every bottle produced has a 5% chance to be a Collector's Edition worth 100x base value.
10. **Don Pepperoni (The Syndicate Boss — Global / Time Manipulation)**
    - 1-Star: Every 10 seconds, the factory has a 15% chance to instantly skip forward 4 seconds across all Farms, Vats, and Bottling Lines. (2/4-Star: 22% -> 30%).
    - 3-Star Breakthrough: Every Time Skip automatically fires the Blank Button 10 times.
    - 5-Star Max: Time Skips jump forward 8 seconds and can chain-proc back-to-back.
    - Mastery: Time Skips also reduce Wrench's Free Upgrade cooldown and multiply Cash earned during that second by 5x.
11. **Blaze (The Viral Influencer — Market / Momentum Snowball)**
    - 1-Star: Selling any batch of bottles triggers Trending, increasing all Sauce sale prices by +2% for 15 seconds (stacks up to +30%). (2/4-Star cap: +50% -> +75%).
    - 3-Star Breakthrough: At max Trending stacks, Bottling Lines gain +30% cycle speed.
    - 5-Star Max: While at max Trending stacks, every 1,000 bottles sold has a 1% chance to drop 1 Golden Seed (subject to daily/run cap).
    - Mastery: Trending stacks never expire during the run and the cap rises to +300%.
12. **Victoria Sterling (The Venture Capitalist — HQ / Prestige Speedrunner)**
    - 1-Star: Begin every new run with £500 Starting Cash and the first 2 Tech Tree nodes unlocked for free. (2/4-Star: £2,500 -> £15,000; 4 Tech nodes).
    - 3-Star Breakthrough: Lowers the minimum Operation Value threshold required to Prestige by 20% (£800,000 instead of £1,000,000).
    - 5-Star Max: Boosts total Franchise Credits earned upon selling the operation by +25%.
    - Mastery: Prestiging no longer resets the North Wing (Blank Button branch) of the Tech Tree; the button retains its full late-game evolution from second one of the next run.

---

## 6. Prestige Loop, HQ Facilities & Local Challenges

### Selling the Franchise (Prestige)

- **Trigger:** Once total **Operation Value** (cumulative cash earned + value of stockpiled inventory in the current run) reaches **£1,000,000** (or £800,000 with Victoria Sterling), the player can choose to **Sell / Franchise the Operation**.
- **Reset Scope:** Resets Cash, Farms, Vats, Bottling Lines, Inventory, and the In-Run Tech Tree.
- **Reward:** Awards **Franchise Credits** scaled logarithmically to the total Operation Value achieved.

### HQ Facility Rooms (Permanent Meta-Progression)

To keep the UI clean, unlocking a new HQ Room presents the player with a **2-Card Draft Choice** from the unowned pool. Rooms are split into high-cap scaling multipliers and hard-capped rule-benders:

| Room Name | Core Function | Base Effect (Lv 1) | Scaling & Cap Rules |
| :--- | :--- | :--- | :--- |
| **1. Seed Vault** | Base Farm Harvest Speed | +15% Harvest Speed | Scales to Lv 50 (+10%/lv). |
| **2. Hydroponics Bay** | Base Farm Crop Yield | +10% Crop Yield | Scales to Lv 50. Multiplies with Barnaby's crits. |
| **3. Fermentation Cellar** | Base Mash Vat Speed | +15% Vat Cycle Speed | Scales to Lv 50. |
| **4. High-Speed Cannery** | Base Bottling Line Speed | +15% Bottling Speed | Scales to Lv 50. |
| **5. Cooperage** | Vat Input Reduction | -5% Raw Crops needed | **Hard Cap Lv 11 (-50% max).** Rounds down (min 1). |
| **6. Glassworks** | Bottling Input Reduction | -5% Mashes needed | **Hard Cap Lv 11 (-50% max).** Rounds down (min 1). |
| **7. Test Kitchen** | Tech Tree Item Discount | -4% Items needed for Tech | **Hard Cap Lv 11 (-40% max).** |
| **8. Ergonomics Lab** | Blank Button Base Power | +25% Base Button Yield | Scales to Lv 30. |
| **9. Seed Capital Office** | Starting Cash | Start run with £100 | Scales exponentially (£100 -> £500 -> £2.5k -> £50k). |
| **10. Tasting Room** | Global Sauce Value | +10% Bottle Cash Value | Scales to Lv 50. |
| **11. Executive Lounge** | Prestige Currency Bonus | +8% Franchise Credits | Scales to Lv 30. |
| **12. Night Watchman's Desk** | Base Offline Time Cap | +1 Hour Offline Cap | **Hard Cap Lv 15 (+8 Hours max).** |

### Global Anti-Exploit Cost Formula

To prevent stacked discounts across HQ Rooms, the In-Run Tech Tree, and Managers from ever reaching 100% free recipes or upgrades, all reductions multiply remaining cost percentages together with a hard floor of 1 unit:

```
Final Cost = MAX( 1, ROUND( Base Cost * (1 - HQ_Discount) * (1 - Tech_Discount) * (1 - Manager_Discount) ) )
```

### Offline-First Live-Ops: The 24-Hour Chili Cook-Off

Provides a structured mid-week challenge and repeatable Golden Seed generation using only the local device clock (zero server dependencies):

- **Unlock & Cooldown:** Unlocks after completing 3 Prestiges. Available once every 72 hours after the previous challenge ends.
- **Format:** Starts a fresh run with a strict 24-hour countdown timer. The player can end the challenge early or let the clock expire.
- **Rewards:** Based on the highest power-of-10 Operation Value threshold crossed (£10k, £100k, £1M, £10M, £100M, £1B...), the player receives **Golden Seeds** and **Scoville Ribbons**.
- **Scoville Ribbons:** Each Ribbon permanently attaches to a randomly unlocked Crop, Mash, or Sauce Bottle in the player's compendium, permanently increasing that item's base cash value by **+20%** across all future runs.
