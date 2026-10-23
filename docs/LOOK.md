# The look: pixel art (W8, D047)

After the first phone test the owner said the game "looks like a 2010 web game rather than a mobile app in 2026" (W8). The owner has now chosen **pixel art** as the game's style (D047). This doc is the first step: a **trial** of a ready-made pixel UI skin over today's screen, to see whether it carries the game before any art is drawn for it.

Status: **built.** PX1–PX7 PASS (PX6 was tightened after the first captures, below); PX8 is the owner's.

## The kit

[Pixel UI Free](https://heyheythere.itch.io/pixel-ui-free) by heyheythere, CC BY 4.0, copied unchanged into `addons/pixel_ui/` (without its demo). It has:

- one theme, **wood**: 9-slice art for buttons, panels, a sunken "inset" panel, a window with a title bar, progress bars (red, green, blue, gold), sliders, check boxes, scroll bars and tabs;
- 20 icons at 16×16 (coin, gem, star, chest and so on);
- a bitmap font, 8 px glyphs on a 10 px line, printable ASCII only.

The licence asks for a credit line in the game: "Pixel UI Free by heyheythere - https://heyheythere.itch.io/pixel-ui-free - CC BY 4.0".

The paid pack (same files and names) adds five colour themes, ember among them, and 50 icons. It installs over this one.

## Rules

- **Whole pixels.** The kit's art is drawn at 1×. We draw it at exactly `Style.PIXEL_SCALE` (2×) on the 540×960 screen, never stretched to an in-between size. Texture filtering is Nearest everywhere, so pixels stay hard-edged.
- **One font.** All text uses the kit's bitmap font, at a whole multiple of its 8 px: 16 (2×) for most text, 24 (3×) for headlines (Cash, card titles). The five characters the game shows that the font lacks (ñ, ×, ·, →, −) come from a small companion font drawn to match (`assets/fonts/pixel_extra.fnt`), as a fallback.
- **The kit's boxes, not flat ones.** Panels, cards, buttons and bars use the kit's art. The screen draws no flat rounded boxes any more.
- **The Blank Button stays the hero.** It's still a large chilli-red disc with no label (brief §2), now drawn as a pixel disc at whole scales: 4× at the start and 2× once compact.
- **Colours** that are ours (cash, Heat, highlights, text) live in `style.gd` as before, chosen to sit with the wood palette. The kit's own colours stay in its theme.

## Criteria

| Id | Criterion |
| --- | --- |
| PX1 | **Square pixels.** The project's default texture filter is Nearest. Every kit texture on screen is the kit's art scaled by exactly PIXEL_SCALE, and every 9-slice margin is the kit's margin × PIXEL_SCALE. *Measured as (worded after the Haiku review, same bar):* every box and icon in the 2× theme the screen draws from is the kit's art with each pixel PIXEL_SCALE×PIXEL_SCALE, its texture and content margins × PIXEL_SCALE (PX4 rules out anything else on screen), and the Blank Button on screen is a whole multiple of its disc, at the start and compact. |
| PX2 | **One font, whole sizes.** At each stage the capture tool visits, every visible Label and Button uses the kit's font at a size that is a whole multiple of 8. |
| PX3 | **Every character drawn.** Every character in every visible text at those stages is in the kit's font or the companion font, so nothing falls back to a system font. |
| PX4 | **No flat boxes.** No visible control at those stages draws a StyleBoxFlat (for panel, normal, hover, pressed, disabled, background or fill). |
| PX5 | **Readable.** Text colours reach WCAG AA contrast against the surface they sit on, taking the surface's colour from the centre pixel of its art: 4.5:1 for TEXT, DIM, cash and Heat; 3:1 for MUTED (disabled text and hints). Surfaces: the inset card, the panel (status bar, nav, sheets) and the screen background. Dark text on the kit's buttons is the kit's choice and is measured too (4.5:1). |
| PX6 | **It fits.** At those stages no visible control runs past the screen's left or right edge, apart from the Tech Tree's web, which scrolls sideways. Every button is at least 44 px tall (today's height for an ordinary button), so tap targets don't shrink. *Tightened after the first captures (the agent's, before any result was reported):* no clipped label hides part of its text; wrapped text never breaks inside a word, Tech Tree nodes included; every tab's name fits the nav at once; the status bar keeps its height. |
| PX7 | **Nothing else breaks.** Every suite passes, the headless boot is clean, stage 0 still shows the Blank Button alone with no text (O1), and the credit line is shown in the Settings card. |
| PX8 | **The owner's eye.** Owner's call, on screenshots and then on the phone: does it look like a 2026 mobile game rather than a 2010 web game? The agent reports its own view but this one isn't the agent's to PASS. |

## Assumed

- 2× for the kit's art, so a button's 4 px border is 8 px on screen: the size that fits our content. At 3× a card's text would run off the screen.
- Headlines at 3× text next to 2× borders. Mixing scales is a pixel-art sin ("mixels"), but 16 px for Cash and titles is too small. Say if you'd rather everything at 2×.
- Wood, the only free theme. Ember or royal from the paid pack may suit hot sauce better.
- Cards as the sunken inset, the status bar, nav and sheets as the raised panel.
- The phone's screen isn't a whole multiple of 540 wide, so the final stretch to the phone can still make pixels slightly uneven (W32).
- Measured into place (each found by the checks or the captures): the panel art darkened to 0.6 (PANEL_SHADE) so text on it reads; Tech Tree nodes 164×100 on a 180×116 grid, so "Concentrate" fits (they were 90×70, so less of the web shows at once); the nav says "Roster" for Shift Roster; Sell Raw Peppers on two lines, same words; card titles, the goal line, and valve and Auto-Sell labels wrap rather than widen the screen; valve and Auto-Sell rows put their label above their controls; the stock strip 16 px lower to make room for a two-line goal; the bottle pop rises 24 px, not 36; the compact Blank Button 140 px, not 150 (2× its disc).
- The kit's demo isn't copied in; its art and theme are unchanged. Five glyphs (ñ × · → −) are ours, drawn by `tools/make_pixel_glyphs.gd`.
- The selected Tech Tree node gets a cream frame and the pinned one a red frame, since the kit has no outlined button.

## Results

`tests/look_tests.gd` checks PX1–PX6 on the real screen, laid out at 540×960, at 17 stages from the bare button to HQ after a sale (7,537 checks). Every suite passes and the headless boot is clean.

**The Web build** (`tools/export_web.sh`), opened in a browser: the kit, the font and the disc load with no console errors, so scaling the kit's art at start-up works in the export. At a phone's size (375×812 at 2× density) the layout is right, but W32 shows. The screen is drawn at 1.39×, so some art pixels are one device pixel wide and some two: uneven steps on the disc's edge and in the letters.

| Id | Result |
| --- | --- |
| PX1 | PASS: Nearest filtering; every kit box and icon is its art at exactly 2×, every pixel of every block checked, with texture and content margins doubled; the Blank Button 280 px then 140 px on screen |
| PX2 | PASS: every visible text uses the kit font at 16 or 24 px |
| PX3 | PASS: every character drawn by the kit font or the companion glyphs |
| PX4 | PASS: no flat boxes left on screen |
| PX5 | PASS: on the inset card, the darkened panel and the background, TEXT 6.7–11.2:1, DIM 5.3–8.8, cash 6.8–11.3, Heat 4.6–7.7, MUTED 3.4–5.7; button text 6.2:1 (pressed 4.75, disabled 4.2) |
| PX6 | PASS, after the fixes in "Measured into place" |
| PX7 | PASS: all suites, the boot, O1 (stage 0 shows no text) and the credit line in Settings |
| PX8 | The owner's: [before and after](look/trial_before_after.png) |

Found on the way:
- **The Haiku review** found no runtime bugs but several soft spots in the checks, all fixed: the Tech Tree word check now uses a card's tighter padding; PX1 checks every pixel of every block, the content margins, and the Blank Button's real size on screen (it compared constants before); PX6 now catches labels that hide lines and a goal over two lines; two stale comments; the font's 8 px moved into `style.gd`.
- **A bug that would have shown on screen:** `get_image()` on an imported texture can hand back the texture's own image, so scaling it in place quietly changed the kit's art for the next reader. The kit loader now scales a copy. PX1's pixel-for-pixel check caught it.
- **Headless isn't the phone's shape.** The first PX6 run saw a 960-wide window and passed what the captures showed overflowing. The suite now lays out at the design size.
- **Wrapping every button was worse.** A wrapped button in a row shrank to one letter a line and stretched the status bar to half the screen. Now only full-width buttons wrap, and PX6 checks that no word breaks.

The agent's view for PX8: it reads as a game now rather than a web page, and the chunky disc suits the Blank Button. But wood is a fantasy-RPG material, not a hot sauce one; the grey "can't afford" buttons are cold against the wood; and 3× headlines beside 2× borders show. The full pack's ember theme, or our own palette over the same parts, would fix the first two.

## After merging #20 (D043–D045 on `main`)

`main` gained Cargo, the dashboard from the first launch and bottling feel while this trial waited, so the trial was merged with it. To keep the merge clear, this branch's D043 is now **D047** and its W28 and W29 are now **W32** and **W33** (`main` uses D043 and W28–W30 for its own).

The kit now dresses the dashboard. What had to change:
- **The factory view** (drawn in code) uses the wood palette and the kit font at 16 px. Floor names sit at the right, because the pixel font is too tall to sit above the tiles. Its dots are gold and its tile outlines whole pixels.
- **The tab selectors** are 64 px tall, not `main`'s 56, so a locked tab's two lines ("Roster", "$150K") stay a 44 px tap target (PX6). The nav keeps "Roster".
- **Sell Batch** is 48 px tall: on the dashboard it's one line.
- **The next action's ring** is an outline with square corners, 4 px wide. **PX4 was narrowed after measuring:** it now fails only flat boxes that are filled or rounded, since an outline is drawn pixel-crisp. The ring is the only box this lets through.
- **Heat** uses the kit's red bar under the button, 12 px tall.
- L10 checks that the selectors sit at the upper viewport's foot (`UPPER_FRACTION` of the screen) instead of a fixed gap under the button. L11 expects "Roster" in the nav.

**Results after the merge:** PX1–PX7 PASS (`look_tests.gd`, 8,078 checks), and the captures were looked at. A4 and E6 fail by one unit, as they do on `main` (W29, W30).
