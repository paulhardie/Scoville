# The look: pixel art (W8, D043)

After the first phone test the owner said the game "looks like a 2010 web game rather than a mobile app in 2026" (W8). The owner has now chosen **pixel art** as the game's style (D043). This doc is the first step: a **trial** of a ready-made pixel UI skin over today's screen, to see whether it carries the game before any art is drawn for it.

Status: **criteria set, building.**

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
| PX1 | **Square pixels.** The project's default texture filter is Nearest. Every kit texture on screen is the kit's art scaled by exactly PIXEL_SCALE, and every 9-slice margin is the kit's margin × PIXEL_SCALE. |
| PX2 | **One font, whole sizes.** At each stage the capture tool visits, every visible Label and Button uses the kit's font at a size that is a whole multiple of 8. |
| PX3 | **Every character drawn.** Every character in every visible text at those stages is in the kit's font or the companion font, so nothing falls back to a system font. |
| PX4 | **No flat boxes.** No visible control at those stages draws a StyleBoxFlat (for panel, normal, hover, pressed, disabled, background or fill). |
| PX5 | **Readable.** Text colours reach WCAG AA contrast against the surface they sit on, taking the surface's colour from the centre pixel of its art: 4.5:1 for TEXT, DIM, cash and Heat; 3:1 for MUTED (disabled text and hints). Surfaces: the inset card, the panel (status bar, nav, sheets) and the screen background. Dark text on the kit's buttons is the kit's choice and is measured too (4.5:1). |
| PX6 | **It fits.** At those stages no visible control runs past the screen's left or right edge, apart from the Tech Tree's web, which scrolls sideways. Every button is at least 44 px tall (today's height for an ordinary button), so tap targets don't shrink. |
| PX7 | **Nothing else breaks.** Every suite passes, the headless boot is clean, stage 0 still shows the Blank Button alone with no text (O1), and the credit line is shown in the Settings card. |
| PX8 | **The owner's eye.** Owner's call, on screenshots and then on the phone: does it look like a 2026 mobile game rather than a 2010 web game? The agent reports its own view but this one isn't the agent's to PASS. |

## Assumed

- 2× for the kit's art, so a button's 4 px border is 8 px on screen: the size that fits our content. At 3× a card's text would run off the screen.
- Headlines at 3× text next to 2× borders. Mixing scales is a pixel-art sin ("mixels"), but 16 px for Cash and titles is too small. Say if you'd rather everything at 2×.
- Wood, the only free theme. Ember or royal from the paid pack may suit hot sauce better.
- Cards as the sunken inset, the status bar, nav and sheets as the raised panel.
- The phone's screen isn't a whole multiple of 540 wide, so the final stretch to the phone can still make pixels slightly uneven (W28).
