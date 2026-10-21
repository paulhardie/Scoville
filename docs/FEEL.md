# Feel: sound and haptics (W2)

The Blank Button should feel like a physical button on a phone: a click you hear and a tap you feel. This is screen-only: nothing in the simulation changes, and nothing is saved in the game save.

Status: **built.** All criteria PASS (`tests/ui_tests.gd`, K1–K5); looked at with `capture_ui.gd` (`w2_settings.png`). Not yet heard or felt on a real phone: that's the next phone test.

## Rules

- **A finger press clicks.** The click is a short, decaying tone made in code (no audio files), played once per press of the Blank Button by the player. Presses from Ergonomic Grip, the Automated Piston and Double-Tap don't click, so holding the button or leaving the Piston running doesn't drone.
- **The pitch moves.** Each click's pitch varies at random by up to ±8%, so fast tapping doesn't sound like one note, and rises with Heat by up to +20% at full Heat, so building Heat sounds like it.
- **A finger press buzzes.** On phones that support it (Android, including the Web build in Chrome; not iPhone Safari), each finger press asks for a 15 ms vibration.
- **Both can be switched off.** A Settings card at the foot of the Farms page has Sound and Vibration switches. The choice is kept in its own small file (`user://settings.json`), not in the game save, so selling the franchise or an unreadable save never touches it.

## Criteria

| Id | Criterion |
| --- | --- |
| K1 | Each finger press of the Blank Button plays exactly one click; Grip and Piston presses play none. |
| K2 | Over 200 presses at no Heat, the pitch stays within 0.92–1.08 and isn't one value; at full Heat it's 1.2× higher on average. |
| K3 | Each finger press asks for one 15 ms vibration; Grip and Piston presses ask for none. |
| K4 | With Sound off there's no click, and with Vibration off no vibration; the switches survive closing and reopening the app. |
| K5 | Stage 0 still shows no text (O1), and the Settings card only appears with the deck. |

## Also fixed: the stock line

With v0.6a's 30 items, the stock line under the status bar wrapped to six lines and ran over the Blank Button (seen in the capture). It now shows at most three lines: Bell Peppers, then bottles, mash and crops that are in stock, so the least important fall off the end. Three short names that clashed were made distinct (Ancho Mash, Smoky Ancho, Serrano Fire). The line is still crowded; the visual pass (W8) should replace it.

## Assumed

- The click's sound, 15 ms and the pitch ranges are defaults (UI polish); say if you want different.
- Only the Blank Button makes a sound for now. Purchases and research stay silent until the visual pass (W8) sets the overall feel.

## Bottling: a sound, a buzz and a bottle (D045)

The owner asked what bottling a sauce looks and feels like. The honest answer was a text pop and nothing else, so it gets a sound and a picture: options 1 and 2 of the three offered. The first-bottle ceremony waits for layout step 3. Screen-only, like the click: nothing in the simulation changes.

### Rules

- **A clink with every bottle pop.** The bottling sound is made in code: a glass clink, two bright partials that ring briefly. It plays with each bottle pop (LAYOUT.md), so it inherits the pop's limit of POPS_PER_SECOND and never drones. Sound off silences it.
- **Richer sauces sound fuller.** The clink's pitch drops a step for each tier of the sauce in the pop (its most valuable bottle): Tier 1 at 1.0, each tier BOTTLE_TIER_PITCH lower.
- **The first bottle of a sauce buzzes.** The first bottle of each sauce in a run asks for one short vibration, FIRST_BOTTLE_MS; later bottles don't. Vibration off silences it.
- **A bottle in the factory view.** Each pop drops a small bottle shape onto the Bottling floor, tinted by the sauce's tier (`style.gd`, TIER_TINTS), which slides right towards Sell Batch and fades. Placeholder shapes, for W8 to restyle.

### Criteria

| Id | Criterion |
| --- | --- |
| K6 | Each bottle pop plays exactly one bottling sound with Sound on, and none with Sound off. However fast lines run, there are at most POPS_PER_SECOND a second. |
| K7 | The bottling sound's pitch is 1.0 for Tier 1 and falls with each tier. |
| K8 | The first bottle of a sauce in a run asks for one FIRST_BOTTLE_MS vibration with Vibration on; the next bottles of it ask for none, and Vibration off asks for none. |
| K9 | Each bottle pop adds one bottle to the factory view's Bottling floor, tinted by the sauce's tier, which moves right and is gone within BOTTLE_SECONDS. |

### Results (bottling)

**K6–K9 PASS** (`tests/ui_tests.gd`):
- **K6:** each pop clinks once. With Sound off it doesn't clink but the bottle still drops. Bottling flat out stays within POPS_PER_SECOND.
- **K7:** Table Mild clinks at 1.0 and Bistro Verde (Tier 2) at 0.93.
- **K8:** the first Table Mild buzzes, the second doesn't, and with Vibration off a first Bistro Verde doesn't.
- **K9:** one bottle per pop, tinted by tier, gone within 0.9 s.

Seen in the captures: a red Table Mild bottle on the Bottling floor, sliding right.

**Not checked:** how the clink sounds and the buzz feels on a real phone (W16).

### Assumed (bottling)

- The clink's partials (2.35 and 3.42 kHz), its length (0.22 s) and volume (−14 dB, quieter than the button's click), and each tier's pitch step (7%).
- The 30 ms first-bottle buzz.
- The tier tints (`style.gd`, TIER_TINTS) and the bottle's placeholder shape. All are defaults; say if you want different.
