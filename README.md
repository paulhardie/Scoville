# Scoville

A hot sauce incremental game: pick peppers, build heat into a Flash Boil, bottle sauce, and automate the kitchen. Built in Godot 4.7.2 for phones (Web export), from the HTML prototype kept in [`reference/web-prototype/`](reference/web-prototype/).

- How to work on it: [AGENTS.md](AGENTS.md)
- Where it's at: [docs/HANDOVER.md](docs/HANDOVER.md)
- Why things are the way they are: [docs/DECISIONS.md](docs/DECISIONS.md)
- What's waiting: [docs/BACKLOG.md](docs/BACKLOG.md)
- The core loop's design and criteria: [docs/CORE.md](docs/CORE.md)

Run the tests and check the game boots:

```bash
bash run_tests.sh
```

```bash
bash run_godot.sh --headless --path . --quit
```

Play it in a window:

```bash
bash run_godot.sh --path .
```
