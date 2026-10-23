extends SceneTree
## The second run (SKELETON.md I9, PRESTIGE.md Y2): the pacing player plays run
## 1 to the sale, sells and spends its credits, then plays run 2 to the sale.
## A few minutes: since v0.7 run 1 is long.

const Game = preload("res://src/core/game.gd")
const Player = preload("res://src/sim/engaged_player.gd")
const T = preload("res://src/core/tuning.gd")

## How long run 1 may take before the suite gives up on the sale.
const RUN_1_MAX := 600

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
	# Run 1, as the pacing suite plays it, to the sale.
	var g := Game.new()
	var p := Player.new()
	while g.stats.ticks < ticks(RUN_1_MAX) and not g.can_prestige():
		p.step(g)
		g.tick()
	var sale_1: float = g.now_seconds() if g.can_prestige() else INF
	if sale_1 == INF:
		criterion("I9", false, "run 1 doesn't reach the sale by %s, so there's no second run to time" % clock(RUN_1_MAX * 60.0))
		finish()
		return
	var ov_1: float = g.operation_value()
	var credits: int = g.prestige_credits()
	var bought := p.sell_and_spend(g)

	# Run 2, to the sale or as long as run 1 took.
	var q := Player.new()
	var sop_at := INF
	var first_grant := INF
	var grants := 0
	while g.stats.ticks < ticks(sale_1 / 60.0) and not g.can_prestige():
		q.step(g)
		var researched: int = g.stats.researched
		g.tick()
		# The player researches in step(); anything researched in the tick is SOP's.
		var granted: int = g.stats.researched - researched
		if granted > 0:
			grants += granted
			if first_grant == INF:
				first_grant = g.now_seconds()
		if sop_at == INF and g.is_researched("standard_operating_procedures"):
			sop_at = g.now_seconds()
	var sale_2: float = g.now_seconds() if g.can_prestige() else INF

	print("Second run (SKELETON.md I9)")
	print("  run 1: the sale at %s for %d credits (Operation Value $%.0f)" % [clock(sale_1), credits, ov_1])
	print("  bought: %s" % ", ".join(bought))
	print("  run 2: the sale at %s, Operation Value $%.0f" % [clock(sale_2), g.operation_value()])

	var share := sale_2 / sale_1
	criterion("I9", share >= 0.60 and share <= 0.75, "run 2 reaches the sale at %s, %.0f%% of run 1's %s (60–75%%)" % [clock(sale_2), share * 100.0, clock(sale_1)])
	criterion("Y2", grants >= 15, "Standard Operating Procedures at %s researched %d nodes, the first at %s (at least 15)" % [clock(sop_at), grants, clock(first_grant)])
	finish()


func finish() -> void:
	for line in results:
		print(line)
	print("%s: second run tests (%d criteria)" % ["FAIL" if failed else "PASS", results.size()])
	quit(1 if failed else 0)
