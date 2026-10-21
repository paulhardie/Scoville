extends SceneTree
## The second run (docs/PRESTIGE.md Y1–Y4): the pacing player plays run 1 to
## 3:00, sells and spends its credits, then plays run 2. About a minute.

const Game = preload("res://src/core/game.gd")
const Player = preload("res://src/sim/engaged_player.gd")
const T = preload("res://src/core/tuning.gd")

const SELL_AT := 180
const RUN_2 := 195

var results := []
var failed := false


func _init() -> void:
	run.call_deferred()


func criterion(id: String, ok: bool, text: String) -> void:
	results.append("  %s %s  %s" % [id, "PASS" if ok else "FAIL", text])
	if not ok:
		failed = true
		printerr("FAIL: %s: %s" % [id, text])


static func clock(seconds: float) -> String:
	if seconds == INF:
		return "never"
	if seconds >= 3600.0:
		return "%d:%02d:%02d" % [int(seconds) / 3600, (int(seconds) / 60) % 60, int(seconds) % 60]
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


static func ticks(minutes: float) -> int:
	return roundi(minutes * 60.0 / T.TICK_SECONDS)


func run() -> void:
	# Run 1, as the pacing suite plays it, to 3:00.
	var g := Game.new()
	var p := Player.new()
	var sale_1 := INF
	while g.stats.ticks < ticks(SELL_AT):
		p.step(g)
		g.tick()
		if sale_1 == INF and g.operation_value() >= T.PRESTIGE_OV:
			sale_1 = g.now_seconds()
	var ov_1: float = g.operation_value()
	var credits: int = g.prestige_credits()
	var bought := p.sell_and_spend(g)

	# Run 2.
	var q := Player.new()
	var sale_2 := INF
	var sop_at := INF
	var first_grant := INF
	var grants := 0
	var scorpion := INF
	var happened := []   # seconds of every purchase or research, the player's or SOP's
	var ov_180 := 0.0
	while g.stats.ticks < ticks(RUN_2):
		var mine := q.events.size()
		q.step(g)
		for i in range(mine, q.events.size()):
			if not String(q.events[i][1]).begins_with("sell"):
				happened.append(q.events[i][0])
		var researched: int = g.stats.researched
		g.tick()
		# The player researches in step(); anything researched in the tick is SOP's.
		var granted: int = g.stats.researched - researched
		if granted > 0:
			grants += granted
			happened.append(g.now_seconds())
			if first_grant == INF:
				first_grant = g.now_seconds()
		if sop_at == INF and g.is_researched("standard_operating_procedures"):
			sop_at = g.now_seconds()
		if sale_2 == INF and g.operation_value() >= T.PRESTIGE_OV:
			sale_2 = g.now_seconds()
		if scorpion == INF and g.stats.made.scorpion_sting > 0:
			scorpion = g.now_seconds()
		if g.stats.ticks == ticks(180):
			ov_180 = g.operation_value()

	print("Second run (PRESTIGE.md)")
	print("  run 1: the sale at %s; sold at %s for %d credits (Operation Value $%.0f)" % [clock(sale_1), clock(SELL_AT * 60.0), credits, ov_1])
	print("  bought: %s" % ", ".join(bought))
	print("  run 2: Operation Value $%.0f at 3:00, $%.0f at 3:15" % [ov_180, g.operation_value()])

	criterion("Y1", sale_2 <= 0.85 * sale_1, "run 2 reaches the sale at %s, %.0f%% of run 1's %s (at most 85%%)" % [clock(sale_2), sale_2 / sale_1 * 100.0, clock(sale_1)])
	criterion("Y2", grants >= 15 and first_grant - sop_at <= 600.0, "Standard Operating Procedures at %s researched %d nodes, the first at %s (at least 15, the first within 10 minutes)" % [clock(sop_at), grants, clock(first_grant)])
	criterion("Y3", scorpion <= RUN_2 * 60.0, "the first Scorpion Sting at %s (by 3:15)" % clock(scorpion))
	happened.sort()
	var last := 110 * 60.0
	var longest := 0.0
	for t in happened:
		if t >= 110 * 60.0 and t <= 180 * 60.0:
			longest = maxf(longest, t - last)
			last = t
	longest = maxf(longest, 180 * 60.0 - last)
	criterion("Y4", longest <= 300.0, "longest wait between purchases or research, 1:50–3:00 of run 2: %.0f s (at most 300)" % longest)

	for line in results:
		print(line)
	print("%s: second run tests (%d criteria)" % ["FAIL" if failed else "PASS", results.size()])
	quit(1 if failed else 0)
