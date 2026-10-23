# The Idle Planet Miner skeleton (v0.7)

The owner asked for Idle Planet Miner's progression to come into the game whole, then be tweaked from there, with more peppers ordered by Scoville and fictional ones past Pepper Y for the deep endgame ([D049–D053](DECISIONS.md)). This doc owns that version: the mapping from every Idle Planet Miner row to ours, what's left out, what of ours stays, the criteria, and what's assumed.

Status: **built and measured (PR 2 of 3); PR 3 tuning.** The copy is in the game as mapped here; [Results](#results-pr-2) has every criterion's measurement, FAILs included. PR 3 tweaks against [its criteria](#pr-3-tuning-criteria-set-before-tuning), each tweak naming the result it answers.

**Source.** Every Idle Planet Miner number below is from the community wiki (idle-planet-miner.fandom.com, CC BY-SA), read 2026-10-23 through its MediaWiki API, and kept as data in [`ipm_snapshot.json`](ipm_snapshot.json): ores, alloys, items, the 79-planet table, projects, smelters and crafters, rooms with their level tables, and the credit table. The wiki is fan-made; a few of its rows are estimates or don't add up, and those are marked. Scoville ranges are [PepperScale's hot pepper list](https://pepperscale.com/hot-pepper-list/), read 2026-10-23.

## How it maps

| Idle Planet Miner | Ours |
| --- | --- |
| 28 ores, $1 to $78B | 28 peppers by Scoville, each worth its ore's value |
| 76 planets with ore shares and prices, 70 with distances (77–79 are names only) | 79 farms, each growing a mix of peppers in IPM's shares (D050); 77–79 assumed |
| Planet upgrades: mining rate, ship speed, cargo | Farm upgrades: Harvest Rate, Truck Speed, Truck Cargo, on IPM's formulas and price curve |
| Telescopes 1–23, three planets each | Land Surveys 1–25, three farms each (24–25 assumed) |
| 29 bars and alloys, 1,000 ore a bar | 29 mashes, 1,000 crops a mash, same recipe graph and values (D051) |
| 48 items | 48 sauces, same recipe graph and values; four of ours take an ingredient mash too |
| Recipes bought with cash ("cost to unlock") | Recipes bought with cash at the same price |
| 10 smelters, 10 crafters | 10 vats, 10 lines at the same prices (the first of each is the kitchen's) |
| Production, Planets and Ore & Logistics projects | 30 Tech Tree nodes at IPM's costs, in our items |
| Galaxy Value; selling at $10M; the credit table | Operation Value counted as Galaxy Value; selling at $10M; the same table (already, D035) |
| 13 of the 21 rooms, offered two at a time in a fixed order | 13 HQ rooms with IPM's effects, levels and prices, plus two of ours |

**Left out of Idle Planet Miner:** asteroids and debris, rovers, colonies, the Ark, dark matter, the space station, surges, ships bought with money, Beacon, Resource Details and Bottleneck Optimizations (screen features: our factory view already marks a backed-up farm), IPM's markets and their projects (our Market Ticker stays), and the rooms that only serve those (Robotics, Terrarium, Probability Drive, Classroom, Planet Relations, Belt Studies, Crew Quarters, Eleven Forward). Managers and their projects wait for the Shift Roster (now v0.8), 24-hour challenges for the Cook-Off.

**Ours that stays (the brief's, layered on top):** the Blank Button and its North Wing (Calloused Thumbs to the Automated Piston, Heat, Overclock), the kitchen chain (D052), the Starter Crate, Sell Batch and the Delivery Van with Auto-Sell, the Raw Overflow Valve, Smart Stockpiling, the Market Ticker, Night Shift Protocols, Standard Operating Procedures, Byproduct Recycling, Franchise Auditors, Overdrive Turbines, Embossed Artisan Decanters, Bumper Crop I–III, the four ingredients and their Pantry branch with its forks, vat and line speed upgrades, offline progress (OFFLINE.md), and the tab thresholds. All of them get re-tuned in PR 3.

## The pepper ladder (D053)

One pepper per heat band, in order, so both ends of each range climb (or hold) rung to rung. Generic names only, as D042 settled: no Tabasco, Red Savina, Carolina Reaper or Pepper X. Every pepper we grow today keeps its id; eight real ones and one fictional one are new. Apollo (3,000,000 SHU on PepperScale) is left out: it would sit above Pepper Y, which stays the last real-world rung by the owner's word.

| # | Pepper | Scoville (SHU) | IPM ore | Value | IPM's first planet (telescope) | Note |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Bell Pepper | 0 | Copper | $1 | P1 (Default) |  |
| 2 | Pimento | 100–500 | Iron | $2 | P2 (Default) | new |
| 3 | Poblano | 1,000–1,500 | Lead | $4 | P4 (Default) |  |
| 4 | Cascabel | 1,000–3,000 | Silicon | $8 | P7 (1) | new |
| 5 | Jalapeño | 2,500–8,000 | Aluminum | $17 | P9 (2) |  |
| 6 | Hungarian Wax | 5,000–10,000 | Silver | $36 | P12 (3) | new |
| 7 | Serrano | 10,000–23,000 | Gold | $75 | P14 (4) |  |
| 8 | Chile de Árbol | 15,000–30,000 | Diamond | $160 | P17 (5) | new |
| 9 | Cayenne | 30,000–50,000 | Platinum | $340 | P19 (5) |  |
| 10 | Pequin | 40,000–60,000 | Titanium | $730 | P22 (6) | new |
| 11 | Thai Chili | 50,000–100,000 | Iridium | $1,600 | P25 (7) |  |
| 12 | Scotch Bonnet | 100,000–350,000 | Palladium | $3,500 | P28 (8) |  |
| 13 | Fatalii | 125,000–400,000 | Osmium | $7,800 | P31 (9) | new |
| 14 | Caribbean Red Habanero | 300,000–445,000 | Rhodium | $17.5K | P34 (10) |  |
| 15 | Chocolate Habanero | 425,000–577,000 | Inerton | $40.0K | P37 (11) |  |
| 16 | Ghost Pepper | 855,000–1,041,427 | Quadium | $92.0K | P40 (12) |  |
| 17 | Trinidad 7 Pot | 1,000,000–1,200,000 | Scrith | $215K | P43 (13) | new (D042 had dropped it; back for more rungs) |
| 18 | Naga Morich | 1,000,000–1,500,000 | Uru | $510K | P46 (14) | new |
| 19 | Trinidad Moruga Scorpion | 1,200,000–2,000,000 | Vibranium | $1.25M | P49 (15) |  |
| 20 | *Alabama Grim* | the Reaper's band, 1,400,000–2,200,000 | Aether | $3.20M | P52 (16) | parody (D042) |
| 21 | *Pepper Y* | 2,693,001 | Viterium | $9.00M | P55 (17) | parody (D042) |
| 22 | *Lava Lantern* | 5,000,000 | Xynium | $28.0M | P58 (18) | fictional (D023) |
| 23 | *Solar Flare* | 10,000,000 | Quolium | $90.0M | P61 (19) | fictional (D023) |
| 24 | *Capsaicin Crystal* | 16,000,000 (pure capsaicin) | Luterium | $300M | P64 (20) | fictional (D023) |
| 25 | *Brimstone Jolokia* | 50,000,000 | Wraith | $1.10B | P67 (21) | fictional (D023) |
| 26 | *Supernova Scorpion* | 500,000,000 | Aqualite | $4.30B | P71 (23) | fictional (D023) |
| 27 | *Event Horizon* | 16,000,000,000 (resiniferatoxin) | Opalite | $18.0B | P74 (24) | fictional (D023) |
| 28 | *Heat Death* | past measuring | Celestite | $78.0B | none priced (P77–79 assumed) | fictional, new: the last rung |

Values are the ore's sell price on the wiki. Chile de Árbol takes Diamond's rung, and Diamond has no bar in Idle Planet Miner, so **Chile de Árbol has no mash**: it sells raw and pays for Wood-Fired Roasting, as Diamond pays for Superior Alloy Value.

## Farms (D050)

A farm grows its crops in the shares below at its Harvest Rate, and its truck carries them to stock. Names follow the main crop (assumed, G24). Prices and shares are IPM's planet table; farm 1 is the tutorial's Bell Plot (D052).

| Farm | Name | Price | Crops (%) | Distance | Opened by | IPM planet |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Bell Plot | $50 (tutorial, IPM $100) | Bell Pepper 100 | 10 | on sale from the start | Balor |
| 2 | Bell Farm | $200 | Bell Pepper 80, Pimento 20 | 12 | on sale from the start | Drasta |
| 3 | Bell Farm II | $500 | Bell Pepper 50, Pimento 50 | 14 | on sale from the start | Anadius |
| 4 | Pimento Farm | $1,250 | Pimento 80, Poblano 20 | 15 | on sale from the start | Dholen |
| 5 | Poblano Farm | $5,000 | Poblano 50, Pimento 30, Bell Pepper 20 | 16 | Land Survey 1 | Verr |
| 6 | Poblano Farm II | $9,000 | Poblano 100 | 18 | Land Survey 1 | Newton |
| 7 | Pimento Farm II | $15.0K | Pimento 40, Bell Pepper 40, Cascabel 20 | 20 | Land Survey 1 | Widow |
| 8 | Cascabel Farm | $25.0K | Cascabel 60, Bell Pepper 40 | 22 | Land Survey 2 | Acheron |
| 9 | Cascabel Farm II | $40.0K | Cascabel 80, Jalapeño 20 | 23 | Land Survey 2 | Yangtze |
| 10 | Jalapeño Farm | $75.0K | Jalapeño 50, Cascabel 30, Poblano 20 | 25 | Land Survey 2 | Solveig |
| 11 | Jalapeño Farm II | $150K | Jalapeño 100 | 26 | Land Survey 3 | Imir |
| 12 | Poblano Farm III | $250K | Poblano 45, Cascabel 35, Hungarian Wax 20 | 28 | Land Survey 3 | Relic |
| 13 | Hungarian Wax Farm | $400K | Hungarian Wax 80, Jalapeño 20 | 30 | Land Survey 3 | Nith |
| 14 | Bell Farm III | $800K | Bell Pepper 40, Pimento 40, Serrano 20 | 33 | Land Survey 4 | Batalla |
| 15 | Serrano Farm | $1.50M | Serrano 50, Hungarian Wax 50 | 35 | Land Survey 4 | Micah |
| 16 | Serrano Farm II | $3.00M | Serrano 100 | 37 | Land Survey 4 | Pranas |
| 17 | Jalapeño Farm III | $6.00M | Jalapeño 40, Cascabel 35, Chile de Árbol 25 | 40 | Land Survey 5 | Castellus |
| 18 | Árbol Farm | $12.0M | Chile de Árbol 80, Poblano 20 | 43 | Land Survey 5 | Gorgon |
| 19 | Serrano Farm III | $25.0M | Serrano 70, Cayenne 30 | 45 | Land Survey 5 | Parnitha |
| 20 | Cayenne Farm | $50.0M | Cayenne 70, Chile de Árbol 30 | 48 | Land Survey 6 | Orisoni |
| 21 | Cayenne Farm II | $100M | Cayenne 100 | 51 | Land Survey 6 | Theseus |
| 22 | Hungarian Wax Farm II | $200M | Hungarian Wax 70, Pequin 30 | 54 | Land Survey 6 | Zelene |
| 23 | Pequin Farm | $400M | Pequin 70, Chile de Árbol 20, Serrano 10 | 57 | Land Survey 7 | Han |
| 24 | Pequin Farm II | $800M | Pequin 70, Cayenne 30 | 58 | Land Survey 7 | Strennus |
| 25 | Jalapeño Farm IV | $1.60B | Jalapeño 60, Thai Chili 40 | 60 | Land Survey 7 | Osun |
| 26 | Thai Chili Farm | $3.20B | Thai Chili 50, Chile de Árbol 50 | 63 | Land Survey 8 | Ploitari |
| 27 | Thai Chili Farm II | $6.40B | Thai Chili 100 | 67 | Land Survey 8 | Elysta |
| 28 | Thai Chili Farm III | $12.5B | Thai Chili 40, Pequin 35, Scotch Bonnet 25 | 70 | Land Survey 8 | Tikkun |
| 29 | Bonnet Farm | $25.0B | Scotch Bonnet 60, Pequin 40 | 72 | Land Survey 9 | Satent |
| 30 | Bonnet Farm II | $50.0B | Scotch Bonnet 90, Chile de Árbol 10 | 73 | Land Survey 9 | Urla Rast |
| 31 | Bonnet Farm III | $100B | Scotch Bonnet 70, Fatalii 30 | 75 | Land Survey 9 | Vular |
| 32 | Fatalii Farm | $250B | Fatalii 60, Thai Chili 40 | 76 | Land Survey 10 | Nibiru |
| 33 | Fatalii Farm II | $600B | Fatalii 100 | 78 | Land Survey 10 | Xena |
| 34 | Bonnet Farm IV | $1.50T | Scotch Bonnet 55, Fatalii 30, Caribbean Red Habanero 15 | 78 | Land Survey 10 | Rupert |
| 35 | Caribbean Red Farm | $4.00T | Caribbean Red Habanero 50, Cayenne 50 | 80 | Land Survey 11 | Pax |
| 36 | Caribbean Red Farm II | $10.0T | Caribbean Red Habanero 100 | 81 | Land Survey 11 | Ivyra |
| 37 | Caribbean Red Farm III | $25.0T | Caribbean Red Habanero 75, Chocolate Habanero 25 | 82 | Land Survey 11 | Utritis |
| 38 | Chocolate Farm | $62.0T | Chocolate Habanero 50, Fatalii 50 | 84 | Land Survey 12 | Dosie |
| 39 | Chocolate Farm II | $160T | Chocolate Habanero 100 | 84 | Land Survey 12 | Zulu |
| 40 | Chocolate Farm III | $400T | Chocolate Habanero 80, Ghost Pepper 20 | 85 | Land Survey 12 | Unicae |
| 41 | Fatalii Farm III | $1.00Qa | Fatalii 60, Ghost Pepper 40 | 87 | Land Survey 13 | Dune |
| 42 | Ghost Farm | $2.50Qa | Ghost Pepper 100 | 88 | Land Survey 13 | Naraka |
| 43 | Ghost Farm II | $6.20Qa | Ghost Pepper 60, Chocolate Habanero 25, Trinidad 7 Pot 15 | 89 | Land Survey 13 | Daedalus |
| 44 | 7 Pot Farm | $15.0Qa | Trinidad 7 Pot 50, Ghost Pepper 50 | 91 | Land Survey 14 | Clovis |
| 45 | 7 Pot Farm II | $40.0Qa | Trinidad 7 Pot 100 | 92 | Land Survey 14 | Zero |
| 46 | 7 Pot Farm III | $100Qa | Trinidad 7 Pot 75, Naga Morich 25 | 92 | Land Survey 14 | Sotomi |
| 47 | Naga Farm | $250Qa | Naga Morich 60, Ghost Pepper 40 | 93 | Land Survey 15 | Remidian |
| 48 | Naga Farm II | $600Qa | Naga Morich 100 | 95 | Land Survey 15 | Muse |
| 49 | Naga Farm III | $1.50Qi | Naga Morich 50, Trinidad Moruga Scorpion 50 | 97 | Land Survey 15 | Arabis |
| 50 | Moruga Farm | $3.80Qi | Trinidad Moruga Scorpion 60, Trinidad 7 Pot 40 | 100 | Land Survey 16 | Vesna |
| 51 | Moruga Farm II | $10.0Qi | Trinidad Moruga Scorpion 100 | 102 | Land Survey 16 | Chandra |
| 52 | Moruga Farm III | $25.0Qi | Trinidad Moruga Scorpion 70, Alabama Grim 20, Caribbean Red Habanero 10 | 103 | Land Survey 16 | Vega |
| 53 | Grim Farm | $60.0Qi | Alabama Grim 50, Trinidad 7 Pot 50 | 105 | Land Survey 17 | Crius |
| 54 | Grim Farm II | $150Qi | Alabama Grim 100 | 107 | Land Survey 17 | Singhana |
| 55 | Grim Farm III | $360Qi | Alabama Grim 70, Trinidad Moruga Scorpion 20, Pepper Y 10 | 108 | Land Survey 17 | Zumbia |
| 56 | Pepper Y Farm | $900Qi | Pepper Y 60, Naga Morich 40 | 109 | Land Survey 18 | Elysium |
| 57 | Pepper Y Farm II | $2.60Sx | Pepper Y 100 | 110 | Land Survey 18 | Nyota |
| 58 | Pepper Y Farm III | $7.50Sx | Pepper Y 40, Alabama Grim 40, Lava Lantern 20 | 112 | Land Survey 18 | Doral |
| 59 | Lava Lantern Farm | $21.0Sx | Lava Lantern 70, Trinidad Moruga Scorpion 30 | 114 | Land Survey 19 | Nikara |
| 60 | Lava Lantern Farm II | $59.0Sx | Lava Lantern 100 | 115 | Land Survey 19 | Limbo |
| 61 | Lava Lantern Farm III | $170Sx | Lava Lantern 70, Solar Flare 30 | 116 | Land Survey 19 | Bob |
| 62 | Solar Flare Farm | $460Sx | Solar Flare 55, Alabama Grim 45 | 118 | Land Survey 20 | Midas |
| 63 | Solar Flare Farm II | $1.30Sp | Solar Flare 100 | 120 | Land Survey 20 | Antigone |
| 64 | Solar Flare Farm III | $3.90Sp | Solar Flare 50, Lava Lantern 25, Capsaicin Crystal 25 | 122 | Land Survey 20 | Hecate |
| 65 | Crystal Farm | $11.0Sp | Capsaicin Crystal 60, Solar Flare 20, Pepper Y 17 (sums to 97, as the wiki has it) | 124 | Land Survey 21 | Sterop |
| 66 | Crystal Farm II | $33.0Sp | Capsaicin Crystal 100 | 125 | Land Survey 21 | Lavinia |
| 67 | Crystal Farm III | $95.0Sp | Capsaicin Crystal 70, Solar Flare 20, Brimstone Jolokia 10 | 127 | Land Survey 21 | Ren |
| 68 | Brimstone Farm | $270Sp | Brimstone Jolokia 60, Lava Lantern 40 | 129 | Land Survey 22 | Gorgons |
| 69 | Brimstone Farm II | $800Sp | Brimstone Jolokia 80, Capsaicin Crystal 20 | 131 | Land Survey 22 | Pontus |
| 70 | Brimstone Farm III | $2.40Oc | Brimstone Jolokia 100 | 134 | Land Survey 22 | Leto |
| 71 | Brimstone Farm IV | $6.92Oc | Brimstone Jolokia 40, Capsaicin Crystal 40, Supernova Scorpion 20 | 136 (assumed) | Land Survey 23 | Laconia |
| 72 | Supernova Farm | $20.8Oc | Supernova Scorpion 70, Solar Flare 30 | 138 (assumed) | Land Survey 23 | Awohali |
| 73 | Supernova Farm II | $62.3Oc | Supernova Scorpion 100 | 140 (assumed) | Land Survey 23 | Pegasi |
| 74 | Supernova Farm III | $178Oc | Supernova Scorpion 60, Event Horizon 40 | 142 (assumed) | Land Survey 24 | Typhon |
| 75 | Event Horizon Farm | $516Oc | Event Horizon 70, Brimstone Jolokia 30 | 144 (assumed) | Land Survey 24 | Surtur |
| 76 | Event Horizon Farm II | $1.81No | Event Horizon 100 | 146 (assumed) | Land Survey 24 | Vesta |
| 77 | Event Horizon Farm III | $5.43No (assumed) | Event Horizon 70, Heat Death 30 | 148 (assumed) | Land Survey 25 | Jolrael |
| 78 | Heat Death Farm | $16.3No (assumed) | Heat Death 70, Event Horizon 30 | 150 (assumed) | Land Survey 25 | Hyperion |
| 79 | Heat Death Farm II | $48.9No (assumed) | Heat Death 100 | 152 (assumed) | Land Survey 25 | Astrea |

**Farm upgrades**, IPM's exactly (the wiki's Planetary Upgrades page, kept in the snapshot as `upgrades` with its level table), for a farm at level L:

- Harvest Rate = 0.25 + 0.1(L−1) + 0.017(L−1)² crops a second, split by the farm's shares.
- Truck Speed = 1 + 0.2(L−1) + (L−1)²/75.
- Truck Cargo = 5 + 2(L−1) + 0.1(L−1)², rounded half to even after boosts.
- Each upgrade's next level costs the farm's price ÷ 20 × 1.3^(L−1), as now (D041). The Bell Plot's use Balor's $100, not its tutorial $50 (D052).

**Trucks (assumed, G21).** The wiki gives no trip formula. Assumed: a round trip takes 2 × distance ÷ Truck Speed seconds and carries up to Truck Cargo crops, the most valuable first unless Crop Priority says otherwise; what isn't carried waits at the farm. At level 1, IPM's Balor (distance 10) carries 5 every 20 s, exactly the 0.25 a second it mines (our Bell Plot, at four times the harvest and cargo, carries 20 every 20 s, its 1 a second), and farm 2's truck (distance 12) falls a little behind, which is the backlog IPM's guides describe.

**Harvests** come once a second, with fractions carried, so Bumper Crop still has a harvest to double.

## Mashes and sauces (D051)

IPM's recipe graph, values, times and unlock prices, with our names. Mashes take 1,000 crops (1,500 from Lava Lantern), as bars take 1,000 ore. Brief names go on the slot closest to their old recipe; the others are new defaults the owner can rename.

### Mashes (29)

| # | Mash | IPM | Inputs | Seconds | Unlock (cash) | Value |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Bell Pepper Purée | Copper Bar | 1K Bell Pepper | 20 | free | $1,450 |
| 2 | Pimento Mash | Iron Bar | 1K Pimento | 30 | $3,000 | $3,000 |
| 3 | Ancho Mash | Lead Bar | 1K Poblano | 40 | $9,000 | $6,100 |
| 4 | Cascabel Mash | Silicon Bar | 1K Cascabel | 60 | $25.0K | $12.5K |
| 5 | Verde Mash | Aluminum Bar | 1K Jalapeño | 80 | $75.0K | $27.6K |
| 6 | Hungarian Wax Mash | Silver Bar | 1K Hungarian Wax | 120 | $225K | $60.0K |
| 7 | Serrano Mash | Gold Bar | 1K Serrano | 180 | $500K | $120K |
| 8 | Sofrito Base | Bronze Bar | 2 Hungarian Wax Mash, 10 Bell Pepper Purée | 240 | $1.00M | $234K |
| 9 | Mole Base | Steel Bar | 15 Ancho Mash, 30 Pimento Mash | 480 | $2.00M | $340K |
| 10 | Cayenne Mash | Platinum Bar | 2 Serrano Mash, 1K Cayenne | 600 | $4.00M | $780K |
| 11 | Pequin Mash | Titanium Bar | 2 Sofrito Base, 1K Pequin | 720 | $8.00M | $1.63M |
| 12 | Thai Chili Mash | Iridium Bar | 2 Mole Base, 1K Thai Chili | 840 | $15.0M | $3.11M |
| 13 | Bonnet Mash | Palladium Bar | 2 Cayenne Mash, 1K Scotch Bonnet | 960 | $30.0M | $7.00M |
| 14 | Fatalii Mash | Osmium Bar | 2 Pequin Mash, 1K Fatalii | 1080 | $60.0M | $14.5M |
| 15 | Caribbean Red Mash | Rhodium Bar | 2 Thai Chili Mash, 1K Caribbean Red Habanero | 1200 | $120M | $31.0M |
| 16 | Chocolate Habanero Mash | Inerton Alloy | 2 Bonnet Mash, 1K Chocolate Habanero | 1440 | $250M | $68.0M |
| 17 | Ghost Mash | Quadium Alloy | 2 Fatalii Mash, 1K Ghost Pepper | 1680 | $500M | $152M |
| 18 | Seven Pot Mash | Scrith Alloy | 2 Caribbean Red Mash, 1K Trinidad 7 Pot | 1920 | $1.00B | $352M |
| 19 | Naga Mash | Uru Alloy | 2 Chocolate Habanero Mash, 1K Naga Morich | 2160 | $2.00B | $832M |
| 20 | Moruga Mash | Vibranium Alloy | 2 Ghost Mash, 1K Trinidad Moruga Scorpion | 2400 | $4.00B | $2.05B |
| 21 | Grim Mash | Aether Alloy | 2 Seven Pot Mash, 1K Alabama Grim | 2640 | $8.00B | $5.12B |
| 22 | Pepper Y Mash | Viterium Alloy | 2 Naga Mash, 1K Pepper Y | 2880 | $16.0B | $15.5B |
| 23 | Lava Lantern Mash | Xynium Alloy | 5 Moruga Mash, 1.5K Lava Lantern | 3300 | $84.0B | $48.0B |
| 24 | Solar Flare Mash | Quolium Alloy | 5 Grim Mash, 1.5K Solar Flare | 3720 | $275B | $160B |
| 25 | Crystal Extract | Luterium Alloy | 5 Pepper Y Mash, 1.5K Capsaicin Crystal | 4140 | $1.00T | $600B |
| 26 | Brimstone Mash | Wraith Alloy | 5 Lava Lantern Mash, 1.5K Brimstone Jolokia | 4560 | $4.20T | $2.40T |
| 27 | Supernova Mash | Aqualite Alloy | 5 Solar Flare Mash, 1.5K Supernova Scorpion | 4980 | $12.0T | $17.5T |
| 28 | Event Horizon Mash | Opalite Alloy | 5 Brimstone Mash, 1.5K Event Horizon | 5520 | $30.0T | $277T |
| 29 | Heat Death Mash | Celestite Alloy | 10 Supernova Mash, 1.5K Heat Death | unverified (assumed 100:00) | $70.0T | $1.20Qa |

Heat Death Mash's time isn't on the wiki: assumed 100:00 (each alloy before it adds about 7 minutes).

### Ingredients and their mashes (ours)

The four ingredients stay on their own stations (D024) and open with the survey whose sauces first need them. A station is priced, placed and upgraded like the cheapest farm its survey opens, and grows 0.25 a second at level 1. Its mash takes 1,000 of it and is worth what IPM's bar of the same ore value is worth for its inputs (the bar's markup).

| Ingredient | Value | Station | Opens with | Its mash | Inputs | Seconds | Unlock | Value | Priced like |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| White Vinegar | $2 | Vinegar Cask | Land Survey 1 | Pickled Brine | 1K White Vinegar | 30 | $3,000 | $3,000 | Pimento Mash (Iron Bar) |
| Garlic | $17 | Garlic Plot | Land Survey 3 | Roasted Garlic Paste | 1K Garlic | 80 | $75.0K | $27.6K | Verde Mash (Aluminum Bar) |
| Pineapple | $75 | Pineapple Grove | Land Survey 4 | Charred Pineapple Glaze | 1K Pineapple | 180 | $500K | $120K | Serrano Mash (Gold Bar) |
| Smoked Oak | $730 | Oak Smokehouse | Land Survey 6 | Liquid Smoke | 1K Smoked Oak | 720 | $8.00M | $990K | Pequin Mash (Titanium Bar) |

Each ingredient mash goes into two sauces as an extra input (bold in the table below), sized to about 10% of that sauce's IPM inputs, and the sauce's value rises by the same share, so IPM's markup holds. Only those eight sauces' values differ from IPM's; sauces made from them keep IPM's values.

### Sauces (48)

| # | Sauce | IPM | Inputs | Seconds | Unlock (cash) | IPM value | Our value |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Sweet Pepper Relish | Copper Wire | 5 Bell Pepper Purée | 60 | free | $10.0K | $10.0K |
| 2 | Pimento Spread | Iron Nails | 5 Pimento Mash | 120 | $20.0K | $20.0K | $20.0K |
| 3 | Garden Hot Sauce | Battery | 2 Sweet Pepper Relish, 10 Bell Pepper Purée | 240 | $50.0K | $70.0K | $70.0K |
| 4 | Smoky Ancho | Hammer | 2 Pimento Spread, 5 Ancho Mash, **2 Pickled Brine** | 480 | $100K | $135K | $146K |
| 5 | Cascabel Salsa | Glass | 10 Cascabel Mash | 720 | $200K | $220K | $220K |
| 6 | Bistro Verde | Circuit | 5 Cascabel Mash, 5 Verde Mash, 10 Sweet Pepper Relish, **10 Pickled Brine** | 1,200 | $400K | $620K | $682K |
| 7 | Garlic Gold | Lens | 1 Cascabel Salsa, 5 Hungarian Wax Mash, **2 Roasted Garlic Paste** | 2,400 | $1.00M | $1.10M | $1.22M |
| 8 | Serrano Fire | Laser | 5 Serrano Mash, 1 Garlic Gold, 10 Pimento Mash | 3,600 | $2.00M | $3.20M | $3.20M |
| 9 | Salsa Verde Reserve | Basic Computer | 5 Bistro Verde, 5 Hungarian Wax Mash | 4,800 | $5.00M | $7.60M | $7.60M |
| 10 | Sunshine Sauce | Solar Panel | 5 Bistro Verde, 10 Cascabel Salsa | 6,000 | $10.0M | $12.5M | $12.5M |
| 11 | Pineapple Picante | Laser Torch | 5 Sofrito Base, 2 Serrano Fire, 5 Garlic Gold, **11 Charred Pineapple Glaze** | 7,200 | $20.0M | $31.0M | $34.1M |
| 12 | Mole Poblano | Advanced Battery | 20 Mole Base, 30 Garden Hot Sauce | 9,000 | $30.0M | $35.0M | $35.0M |
| 13 | Classic Louisiana | Thermal Scanner | 5 Cayenne Mash, 2 Serrano Fire, 5 Cascabel Salsa, **41 Roasted Garlic Paste** | 10,800 | $50.0M | $71.5M | $78.6M |
| 14 | Phantom Smokehouse | Advanced Computer | 5 Pequin Mash, 5 Salsa Verde Reserve, **5 Liquid Smoke** | 12,600 | $120M | $180M | $199M |
| 15 | Cajun Red | Navigation Module | 1 Classic Louisiana, 2 Pineapple Picante | 13,500 | $250M | $1.00B | $1.00B |
| 16 | Bangkok Burn | Plasma Torch | 15 Thai Chili Mash, 5 Pineapple Picante | 15,000 | $550M | $1.15B | $1.15B |
| 17 | Pitmaster BBQ | Radio Tower | 75 Cayenne Mash, 150 Verde Mash, 50 Pequin Mash, **15 Liquid Smoke** | 15,600 | $1.50B | $1.45B | $1.60B |
| 18 | Smoked Paprika Reserve | Telescope | 20 Garlic Gold, 1 Phantom Smokehouse | 16,800 | $5.00B | $2.70B | $2.70B |
| 19 | Island Heat | Satellite Dish | 150 Mole Base, 30 Bonnet Mash, **218 Charred Pineapple Glaze** | 18,000 | $17.5B | $3.40B | $3.74B |
| 20 | Ranchero | Motor | 500 Sofrito Base, 200 Smoky Ancho | 19,200 | $60.0B | $7.00B | $7.00B |
| 21 | Fatalii Fire | Accumulator | 20 Fatalii Mash, 3 Mole Poblano | 20,400 | $100B | $12.0B | $12.0B |
| 22 | Sweet Heat Reserve | Nuclear Capsule | 5 Caribbean Red Mash, 1 Bangkok Burn | 21,000 | $200B | $26.0B | $26.0B |
| 23 | Jalapeño Ranch | Wind Turbine | 300 Verde Mash, 1 Ranchero | 21,600 | $500B | $140B | $140B |
| 24 | Tropical Storm | Space Probe | 1 Island Heat, 1 Smoked Paprika Reserve, 25 Sunshine Sauce | 22,200 | $1.00T | $180B | $180B |
| 25 | Volcano Sauce | Nuclear Reactor | 1 Sweet Heat Reserve, 300 Thai Chili Mash | 22,800 | $2.00T | $1.00T | $1.00T |
| 26 | Cocoa Loco | Collider | 500 Chocolate Habanero Mash, 100 Ghost Mash | 23,100 | $3.00T | $2.00T | $2.00T |
| 27 | Black Hole Sauce | Gravity Chamber | 60 Phantom Smokehouse, 1 Volcano Sauce | 24,300 | $6.00T | $15.0T | $15.0T |
| 28 | Seven Pot Stew | Robot | 300 Seven Pot Mash, 90 Fatalii Fire | 26,000 | $15.0T | $50.0T | $50.0T |
| 29 | Naga Sunrise | Fusion Capsule | 200 Naga Mash, 100 Moruga Mash, 100 Sweet Heat Reserve | 27,000 | $75.0T | $240T | $240T |
| 30 | Ghost Town | Teleporter | 250 Cajun Red, 1 Black Hole Sauce | 29,000 | $500T | $1.80Qa | $1.80Qa |
| 31 | Scorpion Sting | Fusion Reactor | 1 Naga Sunrise, 40 Cocoa Loco, 50 Volcano Sauce | 31,000 | $2.50Qa | $40.0Qa | $40.0Qa |
| 32 | Hurricane Reserve | Subspace Relay | 70 Tropical Storm, 100 Island Heat, 1 Ghost Town | 32,300 | $15.0Qa | $1.00Qi | $1.00Qi |
| 33 | Widowmaker Reserve | Advanced Robot | 100 Seven Pot Stew, 5 Scorpion Sting | 62,300 | $142Qa | $29.5Qi | $29.5Qi |
| 34 | Lava Flow | Advanced Teleporter | 5 Hurricane Reserve, 100 Ghost Town, 1K Lava Lantern Mash | 115,200 | $1.49Qi | $650Qi | $650Qi |
| 35 | Solar Wind | Quantum CPU | 4 Widowmaker Reserve, 500 Solar Flare Mash | 120,000 | $20.0Qi | $14.0Sx | $14.0Sx |
| 36 | Crystal Clear | Deflector Shield | 4 Lava Flow, 400 Crystal Extract | 125,000 | $270Qi | $320Sx | $320Sx |
| 37 | Hyperdrive | Warp Core | 160 Jalapeño Ranch, 40 Scorpion Sting, 4 Solar Wind | 180,000 | $3.65Sx | $6.80Sp | $6.80Sp |
| 38 | Cosmic Drizzle | Deep Space Scanner | 250 Mole Poblano, 1K Supernova Mash, 4 Crystal Clear | 188,000 | $49.3Sx | $145Sp | $145Sp |
| 39 | Dark Star | Antimatter Cell | 50 Volcano Sauce, 10K Bonnet Mash, 4 Hyperdrive | 194,000 | $665Sx | $3.20Oc | $3.20Oc |
| 40 | Stratosphere | Atmospheric Processor | 10K Thai Chili Mash, 4 Cosmic Drizzle, 15 Solar Wind | 244,000 | $500Sp | $68.0Oc | $68.0Oc |
| 41 | Brimstone Reserve | Orbital Dock | 6K Brimstone Mash, 4 Dark Star, 10 Hyperdrive | 399,000 | $100Oc | $2.80No | $2.80No |
| 42 | Supernova Glaze | Solar Collector | 1K Sunshine Sauce, 20 Crystal Clear, 132 Cosmic Drizzle | 399,000 | $100Oc | $2.80No | $2.80No |
| 43 | Wormhole | Phase Gate | 100 Cosmic Drizzle, 350 Lava Flow, 1 Brimstone Reserve | 699,000 | $50.0No | $452No | $452No |
| 44 | Mind Melt | Neural Matrix | 20 Dark Star, 1 Supernova Glaze, 16K Fatalii Mash | 699,000 | $50.0No | $452No | $452No |
| 45 | Big Bang | Stellar Capacitor | 9 Stratosphere, 3 Wormhole, 16.8K Event Horizon Mash | 19,976,068 | $80.0Dc | unverified (wiki: "probably 500 D") | $500Dc (assumed) |
| 46 | Extinction Event | Plasma Conduit | 9 Stratosphere, 3 Wormhole, 16.8K Heat Death Mash | 19,976,068 | $80.0Dc | unverified (wiki: "probably 500 D") | $500Dc (assumed) |
| 47 | Singularity | Graviton Lance | 9 Stratosphere, 3 Mind Melt, 16.8K Event Horizon Mash | 19,976,068 | $80.0Dc | unverified (wiki: "probably 500 D") | $500Dc (assumed) |
| 48 | The Last Drop | System Regulator | 9 Stratosphere, 3 Mind Melt, 16.8K Heat Death Mash | 19,976,068 | $80.0Dc | unverified (wiki: "probably 500 D") | $500Dc (assumed) |

The four top sauces' recipes are quoted on the wiki with a 10% suit discount; the table undoes it (16.8K, not 15.12K). Their values are the wiki's own guess, "probably 500 D": assumed $500Dc (G22).

### The kitchen (D052)

The tutorial stays as it is: the Blank Button picks Bell Peppers, the Bell Plot grows one a second, **Sweet Pepper Mash** (10 Bell Peppers, $20, 8 s) and **Table Mild** (1 Sweet Pepper Mash, $50, 8 s) are free recipes, the Starter Crate bottles 50, and the first vat ($150) and line ($100) are the kitchen's. Kitchen recipes run only in the kitchen vat and line, so they stay a small, steady income (at most 1.25 Bell Peppers a second into Table Mild) that the factory overtakes; the kitchen vat and line can run any other recipe too, as IPM's free first smelter and crafter. The Bell Plot is IPM's Balor at four times the rate: its price is the tutorial's $50, its Harvest Rate and Truck Cargo are IPM's × 4 (Truck Speed is IPM's, so the truck keeps up as Balor's does), and its upgrades cost $100 ÷ 20 × 1.3^(L−1), Balor's.

## Vats and lines

Bought with cash once the Processing tab is open, no cap but the ten. Slot Expansion I–IV go (IPM has no cap). Vat and line speed upgrades stay (ours).

| # | Vat (IPM smelter) | Line (IPM crafter) |
| --- | --- | --- |
| 1 | $150 (the kitchen vat, as now; IPM free) | $100 (the kitchen line, as now; IPM free) |
| 2 | $50.0K | $1.00M |
| 3 | $500K | $100M |
| 4 | $10.0M | $50.0B |
| 5 | $5.00B | $1.00T |
| 6 | $100B | $500T |
| 7 | $50.0T | $10.0Qa (the wiki's 5q* is after a 50% project: doubled) |
| 8 | $1.00Qa | $5.00Qi (the wiki's 2.50Q* is after a 50% project: doubled) |
| 9 | $500Qa | $100Qi (the wiki's 50Q* is after a 50% project: doubled) |
| 10 | $10.0Qi | $50.0Sx (the wiki's 25s* is after a 50% project: doubled) |

## The Tech Tree

**Land Surveys** replace the Crop Blueprints: each opens the next three farms at IPM's telescope cost, in our items.

| Survey | IPM | Cost | Opens farms |
| --- | --- | --- | --- |
| Land Survey 1 | Telescope 1 | 1.5K Pimento, 5 Bell Pepper Purée | 5–7 |
| Land Survey 2 | Telescope 2 | 10 Ancho Mash, 500 Cascabel | 8–10 |
| Land Survey 3 | Telescope 3 | 10 Pimento Spread, 15 Cascabel Mash | 11–13 |
| Land Survey 4 | Telescope 4 | 5 Smoky Ancho, 20 Verde Mash | 14–16 |
| Land Survey 5 | Telescope 5 | 3 Bistro Verde, 10 Serrano Mash | 17–19 |
| Land Survey 6 | Telescope 6 | 3 Serrano Fire, 25 Sofrito Base | 20–22 |
| Land Survey 7 | Telescope 7 | 3 Sunshine Sauce, 20 Cayenne Mash | 23–25 |
| Land Survey 8 | Telescope 8 | 3 Pineapple Picante, 10 Pequin Mash | 26–28 |
| Land Survey 9 | Telescope 9 | 3 Mole Poblano, 10 Thai Chili Mash | 29–31 |
| Land Survey 10 | Telescope 10 | 3 Classic Louisiana, 10 Bonnet Mash | 32–34 |
| Land Survey 11 | Telescope 11 | 3 Phantom Smokehouse, 10 Fatalii Mash | 35–37 |
| Land Survey 12 | Telescope 12 | 3 Cajun Red, 10 Caribbean Red Mash | 38–40 |
| Land Survey 13 | Telescope 13 | 3 Pitmaster BBQ, 10 Chocolate Habanero Mash | 41–43 |
| Land Survey 14 | Telescope 14 | 3 Island Heat, 10 Ghost Mash | 44–46 |
| Land Survey 15 | Telescope 15 | 5 Ranchero, 10 Seven Pot Mash | 47–49 |
| Land Survey 16 | Telescope 16 | 3 Fatalii Fire, 10 Naga Mash | 50–52 |
| Land Survey 17 | Telescope 17 | 3 Sweet Heat Reserve, 10 Moruga Mash | 53–55 |
| Land Survey 18 | Telescope 18 | 4 Jalapeño Ranch, 10 Grim Mash | 56–58 |
| Land Survey 19 | Telescope 19 | 4 Volcano Sauce, 12 Pepper Y Mash | 59–61 |
| Land Survey 20 | Telescope 20 | 5 Cocoa Loco, 15 Lava Lantern Mash | 62–64 |
| Land Survey 21 | Telescope 21 | 5 Black Hole Sauce, 20 Solar Flare Mash | 65–67 |
| Land Survey 22 | Telescope 22 | 6 Seven Pot Stew, 24 Crystal Extract | 68–70 |
| Land Survey 23 | Telescope 23 | 6 Naga Sunrise, 30 Brimstone Mash | 71–73 |
| Land Survey 24 | Telescope 24 (not on the wiki) | 7 Ghost Town, 36 Supernova Mash (assumed: the next sauce, +1 count, +6 mash) | 74–76 |
| Land Survey 25 | Telescope 25 (not on the wiki) | 7 Scorpion Sting, 42 Event Horizon Mash (assumed: the next sauce, +1 count, +6 mash) | 77–79 |

**Adopted projects.** IPM's prerequisites, renamed; a project whose only prerequisite is one we left out (Rover, Smelter, Crafter) hangs off the Kitchen Table. Where one does what a brief node does, the brief's name and place stay and IPM's cost and effect replace its own.

| Our node | IPM project | Cost | Needs (IPM's) | Effect | Note |
| --- | --- | --- | --- | --- | --- |
| Hydroponic Bell Peppers | Advanced Mining | 5 Garden Hot Sauce, 20 Verde Mash | Kitchen Table (IPM's Rover, left out) | every farm harvests ×1.25 | E11 (brief name kept) |
| Hydroponic Jalapeños | Superior Mining | 10 Pineapple Picante, 25 Cayenne Mash | Truck Tune-Up OR Bigger Crates | every farm harvests ×1.25 more (the wiki says it may only add to ×1.2: assumed ×1.25 multiplied) | E37 (name kept) |
| Truck Tune-Up | Advanced Thrusters | 2 Cascabel Salsa, 10 Serrano Mash | Hydroponic Bell Peppers | trucks ×1.25 faster |  |
| Highway Route | Superior Thrusters | 4 Mole Poblano | Hydroponic Jalapeños | trucks ×1.25 faster again |  |
| Bigger Crates | Advanced Cargo Handling | 5 Smoky Ancho, 25 Hungarian Wax Mash | Hydroponic Bell Peppers | truck cargo ×1.25 |  |
| Pallet Racking | Superior Cargo Handling | 50 Pequin Mash | Hydroponic Jalapeños | truck cargo ×1.25 again |  |
| Crop Priority | Cargo Logistics | 10 Verde Mash, 3 Bistro Verde | Land Survey 4 | choose which crop a farm's truck takes first |  |
| Targeted Fertiliser | Ore Targeting | 100 Smoky Ancho, 50 Garden Hot Sauce | Crop Priority | a farm's priority crop +15% |  |
| Precision Fertiliser | Advanced Ore Targeting | 100 Salsa Verde Reserve, 15 Classic Louisiana | Targeted Fertiliser | +30% instead (not added to the 15%) |  |
| Crossbreed I | Alchemy | 50 Serrano Mash, 6 Garlic Gold | Land Survey 4 | one farm's crop becomes the next rung up (you pick the farm) |  |
| Crossbreed II | Advanced Alchemy | 50K Hungarian Wax, 25K Pequin, 6 Salsa Verde Reserve | Crossbreed I | two rungs up, a farm not already crossbred |  |
| Crossbreed III | Superior Alchemy | 400 Bonnet Mash, 200 Fatalii Mash, 5 Phantom Smokehouse | Crossbreed II | three rungs up |  |
| Hotter Burners | Advanced Furnace | 3 Cascabel Salsa, 10 Verde Mash | Kitchen Table (IPM's Smelter: our first vat is the kitchen's) | vats ×1.2 faster |  |
| Steam Jackets | Superior Furnace | 5 Thai Chili Mash, 20 Pequin Mash, 50 Cayenne Mash | Zero-Waste Piping I OR Slow Roasting | vats ×1.2 faster again |  |
| Zero-Waste Piping I | Smelting Efficiency | 200 Sofrito Base | Hotter Burners | vat recipes take 20% fewer inputs | S5 (brief name kept) |
| Slow Roasting | Advanced Alloy Value | 3 Bistro Verde, 10 Hungarian Wax Mash | Hotter Burners | mashes worth ×1.2 |  |
| Wood-Fired Roasting | Superior Alloy Value | 250K Chile de Árbol, 30 Serrano Fire | Slow Roasting | mashes worth ×1.2 again |  |
| Double Batch | Smelting Specialist | 5 Salsa Verde Reserve, 2 Mole Poblano | Slow Roasting | 10% chance a vat makes two |  |
| Faster Cappers | Advanced Crafter | 5 Garlic Gold, 50 Serrano Mash | Kitchen Table (IPM's Crafter: our first line) | lines ×1.2 faster |  |
| Rotary Filler | Superior Crafting | 2 Classic Louisiana, 10 Mole Poblano, 20 Pineapple Picante | Zero-Waste Piping II OR Heavy Flint Glass | lines ×1.2 faster again |  |
| Zero-Waste Piping II | Crafting Efficiency | 30 Sunshine Sauce | Faster Cappers | line recipes take 20% fewer inputs | S6 (brief name kept) |
| Heavy Flint Glass | Advanced Item Value | 1 Garlic Gold, 5 Hungarian Wax Mash | Faster Cappers | sauces worth ×1.2 | S3 (brief name kept) |
| Foil Neck Wraps | Superior Item Value | 200 Bonnet Mash, 25 Pineapple Picante | Heavy Flint Glass | sauces worth ×1.2 again | S4 (brief name kept) |
| Double Fill | Crafting Specialist | 3 Mole Poblano, 2 Phantom Smokehouse | Heavy Flint Glass | 10% chance a line makes two |  |
| Bulk Buyer's Club | Preferred Vendor | 200 Pimento Spread, 75 Smoky Ancho, 40 Bistro Verde | Steam Jackets | new vats and lines cost half |  |
| Pressure Cooker | Furnace Overdrive | 20 Fatalii Mash, 1 Bangkok Burn | Steam Jackets | one vat ×2 speed, inputs +50% |  |
| Pressure Cooker II | Advanced Furnace Overdrive | 40 Caribbean Red Mash, 20 Chocolate Habanero Mash, 10 Classic Louisiana | Pressure Cooker | the Pressure Cooker ×4 instead |  |
| Pressure Valve | Furnace Overdrive Efficiency | 200 Thai Chili Mash, 1 Ranchero | Pressure Cooker | its extra inputs +20% instead of +50% |  |
| Second Pressure Cooker | Furnace Overdrive 2 | 200 Naga Mash, 20 Bangkok Burn, 2 Sweet Heat Reserve | Pressure Cooker | a second vat under pressure |  |
| Third Pressure Cooker | Furnace Overdrive 3 | 300 Grim Mash, 100 Bangkok Burn, 2 Naga Sunrise | Second Pressure Cooker | a third |  |

**Changed in the tree:**
- **Gone:** the Culinary Blueprints (recipes are bought with cash, as IPM's are), the Crop Blueprints (Land Surveys), Jalapeño and Poblano Cultivation, Hydroponic Cayenne, and Slot Expansion I–IV.
- **Kept, re-costed:** every node of ours listed above under "Ours that stays". Their costs aren't IPM's to copy, so PR 2 sets them before measuring by one rule (G23): each cost item keeps its dollar worth (count × its value before v0.7), paid in the item of the same kind (mash or sauce) whose new value is nearest on a log scale, the count rounded to the nearest whole one, at least 1. A rule on values rather than on when the copied run makes things, which isn't known until it's measured.
- **After the sale:** only Standard Operating Procedures still waits for the first sale (brief). Tier 6's gate (D034) goes: IPM gates nothing behind a sale.

## HQ (prestige)

The sale, the $10M floor and the credit table are unchanged (D035). **Operation Value becomes IPM's Galaxy Value:** cash, stock at its values, and everything spent on farms, upgrades, vats, lines, recipes and research (items spent at their values). Today research lowers Operation Value; after this it doesn't.

Rooms are offered two at a time in a fixed order, IPM's, not a random draft (this changes the brief's 2-card draft, §6). The n-th room bought costs the n-th opening price (the wiki's Min Cost column lists 3 for both Engineering and the Forge, either of which can be first; its Combined Min Cost column shows the second costs 6); levels cost each room's own IPM table (in the snapshot). Two of ours fill the places of rooms we left out.

| Offered | Our room | IPM room | Effect | Level 1 | Per level | Max level | Opening cost (credits, as the n-th room bought) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Seed Vault | Engineering | farm harvest speed | x1.25 | +.15 | 60 | 3 |
| 2 | Fermentation Cellar | Forge | vat speed | x1.20 | +.10 | 60 | 6 |
| 3 | Motor Pool | Aeronautical | truck speed (new) | x1.50 | +.25 | 60 | 12 |
| 4 | Land Office | Astronomy | farm upgrade prices (new) | x90% | - 4% | 11 | 21 |
| 5 | Crate Yard | Packaging | truck cargo (new) | x1.50 | +.25 | 60 | 35 |
| 6 | High-Speed Cannery | Workshop | line speed | x1.20 | +.10 | 60 | 56 |
| 7 | Test Kitchen | Laboratory | Tech Tree costs | x90% | - 4% | 11 | 87 |
| 8 | Ergonomics Lab | (none) | button yield (ours, brief; in Robotics's place) | as now (rooms.json) | as now | as now | 133 |
| 9 | Boardroom | Lounge | credits (was the Executive Lounge) | x1.15 | +.05 | 60 | 200 |
| 10 | Night Watchman's Desk | Backup Generator | offline time | +0:30 | +0:30 | 44 | 298 |
| 11 | Seed Capital Office | (none) | starting cash (ours, brief; in Terrarium's place) | as now (rooms.json) | as now | as now | 439 |
| 12 | Cooperage | Underforge | vat inputs | x90% | - 4% | 11 | 642 |
| 13 | Glassworks | Dorm | line inputs | x90% | - 4% | 11 | 934 |
| 14 | Tasting Room | Sales | mash and sauce values | x1.15 | +.05 | 60 | 1351 |
| 15 | Ad Agency | Marketing | Market Ticker spikes (new) | x1.30 | +.10 | 60 | 1946 |

- **Hydroponics Bay goes:** it raised plot yield, and Yield per Cycle goes with IPM's upgrades.
- **Night Watchman's Desk** adds IPM's 30 minutes a level to 44 levels (+22 hours) on top of our 4-hour cap; offline speed is ours (OFFLINE.md). The wiki's "24 hours" at the top is its 2-hour default plus those 22. This replaces G16's Level 8.
- **Ergonomics Lab and Seed Capital Office** keep their effects and caps; their level costs follow Engineering's table (assumed).

## Numbers on screen

Money and counts keep LAYOUT.md's rule (three figures and a suffix) with our suffixes taken as far as the deep end needs: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc (to 10³⁶). Not IPM's q/Q/s/S letters, which differ only by case.

## Criteria (set before building)

Measured in PR 2 on the copy as it stands. A FAIL is reported and gets a backlog row; PR 3 tweaks.

| Id | Criterion |
| --- | --- |
| I1 | **Copied as given.** Every farm's price, shares and distance; every crop's value; every mash's and sauce's inputs, seconds, unlock price and value; every survey's and adopted node's cost and effect; vat and line prices; every room's effect, offer place, opening price and level costs; and the credit table equal the snapshot through this doc's mapping, apart from the rows marked assumed here (`tests/`, reading `docs/ipm_snapshot.json`). |
| I2 | **Farm formulas.** For levels 1–60, Harvest Rate, Truck Speed and Truck Cargo match IPM's formulas to 3 decimals, and each level's price is the farm's price ÷ 20 × 1.3^(L−1) (the Bell Plot: $100 ÷ 20, and its Harvest Rate and Cargo × 4). |
| I3 | **Trucks.** Over 10 minutes, a farm delivers min(what it grows, Truck Cargo × Truck Speed ÷ (2 × distance)) crops a second within 1%, the most valuable crop first (or the one Crop Priority picks); the rest waits at the farm. |
| I4 | **The kitchen is untouched.** O2–O7, O9–O10, E1–E5, F1–F6, K1–K9 and L10–L13 pass as they stand. |
| I5 | **Farms open in order.** Farms 1–4 are on sale from the start; every other farm only once its survey is researched; ingredient stations with theirs. |
| I6 | **The first sale on time.** The pacing player reaches $10M Operation Value between 2:00 and 2:30 (U1's last band, D035). |
| I7 | **No dead air.** From the first line to the sale, the pacing player never goes more than 6:30 without buying a farm, vat, line or recipe, or researching (A4's bar). |
| I8 | **The button still matters.** Tapping adds at least 25% at 15:00, 10% at 30:00 and 30% (with Heat) at 1:30 (F8, N8 and M5's bars). |
| I9 | **The second run is quicker, not trivial.** Run 2 reaches the sale in 60–75% of run 1's time. This tightens Y1's 85% ceiling to 75% and sets W24's floor at 60%, both before measuring, said here. |
| I10 | **The deep end is reachable.** In a long simulation (a tool, not CI), the pacing player, selling whenever the sale pays at least 10× its last credits, buys farm 79 and makes every sauce at least once within 50 runs. The 50 is a GUESS. |
| I11 | **No lost progress.** A v11 save loads as v12: cash, cash earned and best Operation Value are at least what they were; every owned plot and slot comes back as cash at what was spent on it (price and upgrades); items that still exist keep their counts and removed ones come back as cash at their old values; credits are kept and every room level is refunded in the credits it cost; an unreadable save is still kept as `save.json.bad`. |
| I12 | **Big numbers read.** Every money and count shown reads three figures and a suffix up to 10³⁶, never `inf` or an exponent, at each boundary. |
| I13 | **The farms fit.** At 540×960 the Farms tab lists every farm grouped by survey, each with its crops, truck and three upgrades, and nothing runs past the screen's edges (PX6); looked at with `tools/capture_ui.gd`. |
| I14 | **Everything else holds.** Every criterion not retired below still passes. |

### Retired or rewritten (before measuring)

These measure the curve or rules the skeleton replaces. Retiring them now, before any result, is said here so no bar moves unseen.

- **Replaced by I1–I3, I5:** A1, A2, A8 (the starting plots and their curve); C1–C3 (plot upgrades and cargo as a rate); R3 (blueprints), R9 (Slot Expansion), R10 and R11 (now IPM's values), R18 (Hydroponic Bell Peppers is IPM's Advanced Mining); S3 (the cap is ten); S5 (Operation Value is Galaxy Value); S7 and S8 (Tier 3's recipes, Crop Quality); V1–V3 (D004's markups and the old ladder); Q4 and Q5 (the draft and room levels are IPM's); Q10 and Q11 (Tier 6's gate and values).
- **Replaced by I6–I9:** A4, F7, J3, M1–M4, M6, M7, N1–N7, U1–U7, Y1, Y3, Y4, T4 and C7 (checkpoints and shares on the old curve). PR 3 sets new checkpoints from the measured copy.
- **Replaced by I14:** A6, A9, C8 and T5 (each "every earlier criterion still passes").
- **Rewritten:** Q10 keeps its Standard Operating Procedures clause (SOP opens only after a sale) and drops Tier 6's gate.
- **Kept as they stand:** everything else, including A3, A5, A7 (the casual player's second farm by 3:30: the early feel, W28, not the curve; farm 2 is $200), C4–C6, E1–E6 (E6 is still W30), F1–F6, F8, H1–H3, J1–J2, K1–K9, L1–L15, M5, N8, O1–O10 as D044 left them, P1–P2, PX1–PX8, Q1–Q3, Q6–Q9, Q12–Q14, Y2 (SOP's node count in run 2), R1–R2, R4–R8, R12–R17, S1–S2, S4, S6, S9–S10, T1–T3, U8–U9, V4–V7 and X1–X8. Where one names an item or price that's gone (P2's "1:40 state", U8's $10M), it is read with the new items, the bar unchanged.

## Results (PR 2)

Measured on the copy as it stands, played by the pacing player (D003, its v0.7 policy below). No game number was retuned to pass and no bar moved; the player itself was fixed three times while measuring (below), which changed the measurements.

| Id | Result |
| --- | --- |
| I1 | **PASS.** Every farm, pepper, mash, sauce, ingredient, survey, adopted node, room and slot price in `data/` equals `tools/ipm/mapping.json`; `run_tests.sh` checks that file is what `mapping.py` makes of the snapshot; and the snapshot's own planets (price, shares, distance), ore values, smelters, crafters and credit table are checked directly, apart from the rows marked assumed (`skeleton_tests.gd`). |
| I2 | **PASS.** Levels 1–60 of Harvest Rate, Truck Speed and Truck Cargo (half to even) and every level's price, on farm 2 and the Bell Plot. |
| I3 | **PASS.** Over 10 minutes a truck-bound farm delivers its carrying rate within 1%, Pimento (worth more) or the Crop Priority pick first, the rest waiting; a truck that keeps up brings everything. |
| I4 | **FAIL** on F6 (184 s against 90), E3 (184 s eager against 75, 110 s casual against 100) and E6 (2 against 10; W30). The waits are on IPM's farms 3–4 and their levels after the kitchen is bought; E6 falls because the Bell Plot's truck brings peppers 20 at a time. O2–O7, O9–O10, E1, E2 (1:46 and 2:32), E4, E5, F1–F5, K1–K9 and L10–L13 pass. W42, W30. |
| I5 | **PASS.** Farms 1–4 from the start, every other farm with its survey, the four ingredient stations with Surveys 1, 3, 4 and 6. |
| I6 | **FAIL.** $10M at **7:56** (2:00–2:30; timed by `second_run_tests.gd`, since `pacing_tests.gd` stops at 3:15 and reports it as never). $150K at 34:07, $1M at 1:59, $2.3M at 3:15. Land Survey 3 wants 10 Pimento Spread, 50,000 Pimento, on farms growing about 5 a second: from 1:35 to 2:46 the player only levels farms. W37. |
| I7 | **FAIL.** 1:11:06 without a farm, vat, line, recipe or research (1:35:27 to Land Survey 3 at 2:46:33), against 6:30. W38. |
| I8 | **FAIL.** Tapping adds 13% at 15:00 (25%), 10% at 30:00 (10%, passes) and 6% at 1:30 (30%). W39. |
| I9 | **FAIL.** Run 2's sale at 6:46, 85% of run 1's 7:56 (60–75%). The first sale pays 10 credits: Seed Vault and Fermentation Cellar. W40. |
| I10 | **FAIL.** `tools/deep_run.gd`: run 1 sells at 8:00 for 10 credits; run 2, needing 100 credits (about $10B), is at Land Survey 5 with 20 farms and 5 of 48 sauces made after 48 hours ($344M), where the tool stops. Farm 79 and every sauce: never. At about $500–900 a second mid-run, IPM's $10M fourth vat alone takes 4 hours to save. W44. |
| I11 | **PASS.** Saves v1–v3 and v6–v11 (v8–v10 built from the v11 fixture in their own shapes, D042's old names included; v4–v5 not covered) load as v12, a pin on a removed node dropped, a broken plot refused, with cash at least the run's earnings, stock and the best Operation Value kept, removed nodes' items back, rooms back as credits; an unreadable save is kept as `.bad` (`factory_tests.gd`, `skeleton_tests.gd`). |
| I12 | **PASS.** $1.00 and $999 of each suffix K to Dc, $500Dc, never an exponent or `inf` (`layout_tests.gd`). |
| I13 | **PASS.** Every farm owned and upgraded: all 83 cards show under their survey headings, nothing past the edges (PX6, `look_tests.gd`), and the captures looked at (`capture_ui.gd`'s `i13_*`). Two fixes found on the way: the pixel font gains é and Á (Purée, Árbol), and Crossbreeding I–III became **Crossbreed I–III** so the word fits a Tech Tree node. |
| I14 | **FAIL** on P2 (8 hours away from 1:40 raise $1.25M, two hours' tapping $1.28M; W43) and Y2 (Standard Operating Procedures, researched at 19:04 in run 2, grants no node: its bar, 1% of an hour's bottles, is under every node's cost with one line bottling; W41). Everything else kept passes. |

**What changed while building, said here:**

- **S4, S9, A5 and C5** can't hold as worded ("goes on producing as before", plot levels carried over): v12 refunds the factory as cash (I11). S4 and S9 now check that v2 and v3 saves load with their stats, sliders and surviving research; A5 and C5 are left to I11.
- **HQ rooms open at 3, 6, 12…** credits: the second room is 6, not 3 as PR 1's table read it (IPM's minimum costs).
- **Forager's Luck** drops what its station grows in 10 seconds (`FORAGE_SECONDS`), since a station's harvest is now a rate, not a yield per cycle.
- **Selling any item** (`sell_item`), IPM's way; Sell Batch and the plot card's Sell stay.
- **`run_tests.sh`** runs every suite and fails at the end, so a measured FAIL doesn't hide the suites after it.
- **The pacing player's policy** (GUESS, `engaged_player.gd`): its goal is the next Land Survey; it buys the recipes, slots and farms the goal needs and sells the rest; a Harvest Rate level is priced with the truck levels that carry it, and trucks are kept up first; with nothing to save for, it buys the best farm level however slow the payback; it keeps Table Mild for the cheapest kitchen node, holds back what it saves from Auto-Sell, and sells bottles with Sell Batch. Measuring found three stalls in it (a vat bought for the kitchen's mash, which only runs in the first vat; cash hoarded when every level paid back slower than an hour; Auto-Sell selling the survey's sauce), each fixed before the numbers above. A better player could find a quicker run; PR 3 should weigh the player with the curve.

## PR 3: tuning (criteria set before tuning)

The owner chose to pull the first sale back to I6's 2:00–2:30 (2026-10-23) rather than move the bar. PR 3 tweaks the copy against PR 2's FAILs; these are the bars, set before any tweak.

| Id | Criterion |
| --- | --- |
| Z1 | **Every I criterion passes as written**, I2–I14, with I1 replaced by Z2. That includes I6 (the sale at 2:00–2:30), I7, I8, I9, I10, I4's F6 and E3, and E6 (kept as it stands). |
| Z2 | **Tweaks are listed, not hidden.** `data/` equals `tools/ipm/mapping.json` with `tools/ipm/tweaks.json` applied, nothing else. Each tweak row names the FAIL it answers. Every number not in the table still equals the snapshot through the mapping (`skeleton_tests.gd`, replacing I1). |
| Z3 | **Checkpoints on the way.** The pacing player reaches $150K Operation Value at 0:25–0:50, $1M at 1:00–1:30 and $4M at 1:35–2:00: roughly even ratios between the kitchen and I6's band. |
| Z4 | **Still Idle Planet Miner's shape.** The order of surveys, farms, recipes and rooms is unchanged; tweaks change amounts, prices, rates and our own rules, not the graph. |

Z1 keeps E6 at 10 (W30 is still the owner's to settle). Z1 first said "I4's F6, E3 and E6"; I4 lists E1–E5, and E6 is kept on its own, so the wording was corrected after the review, the bar unchanged. If a bar can't be met without breaking another, that's reported, not quietly traded.

### Results (PR 3)

Measured with every tweak below in place, played by the pacing player (its PR 3 changes below).

| Id | Result |
| --- | --- |
| Z1 | **FAIL** on I7, I10 and E6 below; every other I criterion passes (Z2 for I1). |
| I6 | **PASS.** $10M at 2:07 (2:00–2:30). |
| Z3 | **PASS.** $150K at 0:27 (0:25–0:50), $1M at 1:04 (1:00–1:30), $4M at 1:41 (1:35–2:00). |
| I7 | **FAIL.** 15:15 without a farm, vat, line, recipe or research (0:49 to Night Shift I at 1:05), against 6:30; seven stretches over 6:30, all 7–15 minutes. Purchases come in bursts at each Land Survey, about 20 minutes apart. Nothing tried filled the gaps without breaking another bar (a faster kitchen broke E3, chasing side nodes stalled the run, cheaper slots changed nothing). W38. |
| I8 | **PASS.** Tapping adds 40% at 15:00, 59% at 30:00 and 50% at 1:30 (Heat Meter at 0:46). |
| I9 | **PASS.** Run 2's sale at 1:29, 70% of run 1's 2:07; the first sale pays 50 credits. |
| I10 | **FAIL.** `tools/deep_run.gd`: run 1 sells at 2:10 for 52 credits; run 2 at 4:20 for 550 ($27B, Land Survey 11, 41 farms); run 3, which must pay 5,500 credits (about $10^20), is at Survey 19 with 47 farms and $87T after 24 hours, where the tool stops. Farm 79 and every sauce: never (9 of 48 made; the player only makes what a survey asks for). W44. |
| I4 | **FAIL on E6 only** (2 Sweet Pepper Mash waiting, against 10; W30, the owner's call). F1–F6 and E1–E5 pass (E3 72 s, F6 84 s). |
| I14 | **PASS.** P1, P2 ($17.7M away against $13.4M tapping), U8, Y2 (SOP researched 21 nodes in run 2), A7 and every other suite pass. |
| Z2 | **PASS.** `data/` is the mapping with `tweaks.json` applied, nothing else (`skeleton_tests.gd`). |
| Z4 | **PASS.** No survey, farm, recipe or room changed place; T4 adds a slot ahead of IPM's, which keep their order. |

Also found and fixed on the way: the Standard Operating Procedures panel ran off the screen (its title didn't wrap; already so in PR 2), now in `look_tests.gd`.

### The tweaks

Each is in `tools/ipm/tweaks.json` (data, checked by Z2) or `src/core/tuning.gd` and `game.gd` (rules), and names what it answers. Everything else is still Idle Planet Miner's.

| Id | Tweak | Answers |
| --- | --- | --- |
| T1 | Farms and ingredient stations from Land Survey 1 on: prices climb from farm 4's $1,250 as (price ÷ $1,250)^0.3 up to Land Survey 10's farms, then keep IPM's own steps from there; their upgrades follow at price ÷ 20, so I2's formula holds. | I6, Z3: IPM's planet prices outran a run without its managers, colonies and Beacon. |
| T2 | Every Land Survey costs its telescope × 0.5. | I6, I7: Survey 3 alone asked 50,000 Pimento. |
| T3 | A farm or ingredient station from Land Survey n harvests and carries × 1.15^n (IPM's curves, scaled), in place of the managers and colonies left out. Farms 1–4 and the Bell Plot are untouched; I2 checks farm 2 and the Bell Plot. | I6, Z3: the middle of the run grew too slowly. |
| T4 | The kitchen's vat and line run only the kitchen's recipes; IPM's free first smelter and crafter follow as Vat 2 and Line 2 at the kitchen's $150 and $100. Eleven of each. | I8, Y2: the player gave the kitchen's line to the survey's sauces, so no Table Mild came for the Tech Tree. |
| T5 | Standard Operating Procedures researches any node costing under 5% of the run's Operation Value (was 1% of an hour's bottles). A rule, in `tuning.gd`. | Y2, I9: on the copy that bar was under every node's cost. |
| T6 | Calloused Thumbs: +8 Bell Peppers a press (was +2). | I8: at 15:00 the copy's factory dwarfs v0.6's. |
| T7 | Double-Tap, Ergonomic Grip and Heat Meter cost half their Table Mild. | I8: Heat came after 1:30. |
| T8 | Night Shift Protocols I costs 128 Table Mild (was 6 Sweet Pepper Relish). | P2: offline needs Night Shift by 1:40. |
| T9 | A sale pays 5 × IPM's credits (50 at $10M). A rule, in `tuning.gd`. | I9: IPM's 10 credits opened two rooms and run 2 took 80% of run 1. |

**The pacing player's PR 3 changes** (GUESS, `engaged_player.gd`): it keeps everything the survey takes; its survey recipes take turns in the slots it has rather than saving for one dearer than 30 minutes' income; a recipe mid-cycle keeps its slot (it swapped back and forth and never finished); it sets up the kitchen before saving for research; it takes the button's nodes N1–N4 first, then the cheapest kitchen node, and spare research leaves that node's Table Mild alone; after a sale, the Van and SOP first. Each was a stall or a choice no tapping player would make; none moved a bar.

**Z1's I2, said plainly:** I2 checks the formulas on farm 2 and the Bell Plot, which are untouched; farms from the surveys run the same curves × 1.15^n (T3).

## Assumed

Each is the smallest reasonable answer; the owner can change any of it.

- **The pepper list** (D053): which real pepper takes each heat band, and Heat Death as the 28th, fictional rung. Names checked against the marks D042 found, not the register itself (G25).
- **Farm names**: the main crop's name and a numeral (G24).
- **Farms 77–79** (Celestite's): ×3 a farm from farm 76, Celestite arriving as a minority, then a majority, then pure, as IPM's ores do; **distances from farm 71**: +2 a farm from 134 (G22).
- **Land Surveys 24–25**: the next two sauces on IPM's list and +1 count, +6 mash a survey, as 22 and 23 go (G22).
- **The four top sauces' values**: $500Dc each, the wiki's guess (G22). **Heat Death Mash's time**: 100:00.
- **Trucks**: the trip formula above (G21).
- **The kitchen** (D052): the Bell Plot at $50 with four times Balor's harvest and cargo; kitchen recipes only in the kitchen vat and line; the kitchen vat and line at $150 and $100 rather than IPM's free.
- **Crafters 7–10** are the wiki's prices doubled: the wiki quotes them after Preferred Vendor's 50%.
- **Ingredients**: stations opening with Surveys 1, 3, 4 and 6; priced like the survey's cheapest farm; mash values by IPM's bar markup; two sauces each, at about 10% of the inputs.
- **Superior Mining, Thrusters and Cargo Handling** multiply by ×1.25 (the wiki doubts this and says it may be ×1.2 added).
- **Our nodes' costs**: the value rule above (G23).
- **Operation Value as Galaxy Value**, rooms in IPM's fixed order, Hydroponics Bay gone, Night Watchman on IPM's levels, Ergonomics Lab and Seed Capital on Engineering's level costs.
- **Suffixes** ours to Dc, not IPM's letters.
