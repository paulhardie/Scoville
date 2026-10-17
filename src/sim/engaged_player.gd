extends RefCounted
## The pacing player of docs/FACTORY.md: a GUESS at an engaged first-time
## player. It only uses the game's real actions. Call step() once per tick,
## before the game's tick().

const T = preload("res://src/core/tuning.gd")

## Taps a second (GUESS: quick but not frantic). Zero for an idle player.
var taps_per_second := 3.0
## Raw peppers it lets pile up before selling them all, once the vat runs.
const RAW_SELL_ABOVE := 50

## Whether it buys anything (off when measuring a minute as things stand).
var buys := true

## What it did, as [seconds, what] pairs, for the report.
var events: Array = []

var _tap_acc := 0.0


func step(g) -> void:
	_tap_acc += taps_per_second * T.TICK_SECONDS
	while _tap_acc >= 1.0:
		_tap_acc -= 1.0
		g.press()
	if g.stats.ticks % roundi(1.0 / T.TICK_SECONDS) == 0:
		decide(g)


## Once a second: sell, then buy.
func decide(g) -> void:
	var now: float = g.stats.ticks * T.TICK_SECONDS
	if g.sell_batch():
		_note(now, "sell_batch")
	if not g.stations.vat.owned or g.stock.bell > RAW_SELL_ABOVE:
		g.sell_raw()
	if not buys:
		return
	# Save for the next station; upgrades only once all three are owned.
	for station in ["plot", "vat", "line"]:
		if not g.stations[station].owned:
			if g.buy(station):
				_note(now, "buy " + station)
			return
	while true:
		var best := ""
		var best_cost := INF
		for station in g.UPGRADES:
			for upgrade in g.UPGRADES[station]:
				var c: float = g.upgrade_cost(station, upgrade)
				if c < best_cost:
					best_cost = c
					best = station + "." + upgrade
		var parts := best.split(".")
		if not g.buy_upgrade(parts[0], parts[1]):
			return
		_note(now, "upgrade " + best)


func first(what: String) -> float:
	for entry in events:
		if entry[1] == what:
			return entry[0]
	return INF


func _note(now: float, what: String) -> void:
	events.append([now, what])
