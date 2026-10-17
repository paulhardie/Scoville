# Handover

## Where it's at

Built: v0.1–v0.5 (PRs #1–#8, waiting to merge), and now **v0.5.1, the early-game pass** ([FACTORY.md](FACTORY.md#v051-the-early-game-pass)).

**The phone test (W1, done).** The Web build plays fine on the owner's phone, and the "While you were away" card works. Two findings:
- **The start felt "incredibly slow".** That's fixed here.
- **It "looks like a 2010 web game rather than a mobile app in 2026".** That's W8, the visual pass.

**What v0.5.1 changes:**
- **A casual phone player for the first 20 minutes (D022),** beside the tireless pacing player.
- **New early-game criteria, E1–E6,** with "never longer than … without something new" gaps as well as deadlines.
- **Cheaper, stronger first stations:** a £5 plot giving a pepper a second, a £15 vat and a £10 line. Upgrade prices are unchanged.
- **Results for the casual player:** the line at 3:16 (was 10:40), the longest wait 96 s (was 450 s), and the Tech Tree at 13:10.

All criteria pass: E1–E6, F, N, M, X, P (31 pacing and offline criteria, 553 rule and screen checks).

Knock-ons, each fixed or noted in [FACTORY.md](FACTORY.md#what-moved):
- two catch-up faults that a bigger factory exposed, fixed;
- P2's measurement, fixed;
- the run now gets ahead of the 3-hour curve a little sooner (W7).

**Also in design: the pepper ladder ([INGREDIENTS.md](INGREDIENTS.md), D023, proposed).** 13 real peppers by Scoville, Bell to Pepper X, then 6 fictional up to 16 billion SHU, each with a value. The brief's six peppers keep their values, so nothing built changes. Not in `data/` yet (W10).

## Open decisions

- **W8, the visual pass:** needs your direction: a few reference games, a mood, and whether art comes later.
- **W7, the whole curve:** for v0.6, as agreed.
- **E6 was narrowed** to the casual player after measuring, because the pacing player leaves only 3 mash for the Starter Crate. Say if you'd rather the eager player saw a bigger crate moment too, which would mean a pricier line.
- **The pepper ladder (D023):** accept the list and values, or rename and swap peppers.
- **G17, how the new peppers are used:** recommend one mash and one sauce per new pepper (Idle Planet Miner's ore→bar), built with v0.6. The cheaper option, any pepper of a tier filling that tier's mash, adds no recipes but makes them interchangeable.

## Next

1. W8, once you've sent references; otherwise G8, G16 and G17 for v0.6 Prestige, with the pepper ladder (W10).

Touches: data (first stations), tuning (reference prices), the pacing player (casual mode), pacing tests (E1–E6), the catch-up (shared inputs, Piston batching), and docs. Stubbed or open: W3–W10, G16, G17. Next: W8 or G8/G16/G17, your call.
