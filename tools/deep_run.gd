extends SceneTree
## SKELETON.md I10, a tool rather than a test: the pacing player plays run after
## run, selling whenever the sale pays at least 10× its last credits (the
## first sale as soon as it can), and spends its credits on rooms. Reports when
## it first owns farm 79 and has made every sauce, within RUNS runs.
##   bash run_godot.sh --headless --path . -s res://tools/deep_run.gd
## Settings come from the environment: RUNS (50), RUN_HOURS (the most one run
## may take, 48), BUDGET_MINUTES (wall-clock minutes before it stops, 60).
## It looks at the game once a second and steps the game a second at a time
## (Game._step(10), as the catch-up does), tapping at the pacing player's rate
## between steps.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")


func _init() -> void:
	var runs := _env_int("RUNS", 50)
	var run_hours := _env_int("RUN_HOURS", 48)
	var budget := _env_int("BUDGET_MINUTES", 60) * 60000
	var started := Time.get_ticks_msec()
	var g := Game.new({}, 1)
	var sauces := []
	for id in g.data.items:
		if g.data.items[id].kind == "bottle" and not g.data.recipes.get(id, {}).get("kitchen", false):
			sauces.append(id)
	var made := {}
	var last_credits := 0
	var farm_79 := ""
	var every_sauce := ""
	var total_seconds := 0.0
	for run in range(1, runs + 1):
		var p := Player.new()
		var taps := roundi(p.taps_per_second)
		var steps := 0
		var sold := false
		while steps < run_hours * 3600:
			for t in taps:
				g.press()
			p.decide(g)
			g._step(roundi(1.0 / T.TICK_SECONDS))
			steps += 1
			if steps % 600 == 0:
				for s in sauces:
					if g.stats.made[s] > 0:
						made[s] = true
				if farm_79 == "" and g.plots.farm_79.owned:
					farm_79 = "run %d, %s in" % [run, _clock(steps)]
				if every_sauce == "" and made.size() == sauces.size():
					every_sauce = "run %d, %s in" % [run, _clock(steps)]
				if g.can_prestige() and g.prestige_credits() >= maxi(1, 10 * last_credits):
					sold = true
					break
				if Time.get_ticks_msec() - started > budget:
					break
		total_seconds += steps
		var owned := 0
		var top := ""
		for id in g.data.plots:
			if g.plots[id].owned:
				owned += 1
				top = id
		var credits: int = g.prestige_credits()
		print("run %d: %s, Operation Value $%s, %d farms (top %s), survey %d, %d of %d sauces made so far%s" % [
			run, _clock(steps), String.num_scientific(g.operation_value()), owned, top, g.fx.survey, made.size(), sauces.size(),
			", sold for %d credits" % credits if sold else ", not sold"])
		if not sold:
			print("stopped: run %d didn't reach a sale paying %d credits within %d hours or the time budget" % [run, maxi(1, 10 * last_credits), run_hours])
			break
		last_credits = credits
		print("  rooms: %s" % ", ".join(p.sell_and_spend(g)))
		if farm_79 != "" and every_sauce != "":
			break
	print("I10: farm 79 %s; every sauce %s; %d runs, %s of play, %d s of computing" % [
		farm_79 if farm_79 != "" else "never", every_sauce if every_sauce != "" else "never", g.account.prestiges + 1,
		_clock(int(total_seconds)), (Time.get_ticks_msec() - started) / 1000])
	quit()


static func _env_int(key: String, default: int) -> int:
	var v := OS.get_environment(key)
	return int(v) if v.is_valid_int() else default


static func _clock(seconds: int) -> String:
	return "%d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]
