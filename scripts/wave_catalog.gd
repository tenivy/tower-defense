class_name WaveCatalog
extends RefCounted
## Every campaign row is authored. No random rolls affect enemy stats or order.

const LAST_CAMPAIGN_WAVE = 50
const VARIANTS = ["Обычные", "Усиленные", "Злые", "Гиганты", "Злые гиганты"]
# Visual size, health, speed, bounty, castle damage. Baseline scene stats are preserved.
const TIERS = [
	{"size": 1.0, "health": 1.0, "speed": 1.0, "reward": 1.0, "damage": 1.0, "angry": false},
	{"size": 1.20, "health": 4.0, "speed": 1.03, "reward": 1.2, "damage": 1.2, "angry": false},
	{"size": 1.40, "health": 12.0, "speed": 1.08, "reward": 1.5, "damage": 1.4, "angry": true},
	{"size": 1.75, "health": 40.0, "speed": 0.92, "reward": 2.0, "damage": 1.8, "angry": false},
	{"size": 2.05, "health": 100.0, "speed": 1.0, "reward": 2.5, "damage": 2.2, "angry": true},
]
# Pairs: ordinary goblin/werewolf, strong G/W, angry G/W, giant G/W, angry giant G/W.
# The eleventh value is the fixed interval in game seconds. Waves 1-10 only add bodies.
const CAMPAIGN = [
	[ 5, 0,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 01: learn placement
	[ 7, 0,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 02: extend coverage
	[ 8, 1,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 03: first werewolf
	[ 9, 2,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 04
	[11, 2,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 05
	[12, 3,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 06
	[13, 4,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 07
	[14, 5,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 08
	[16, 5,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 09
	[18, 6,  0, 0,  0, 0,  0, 0, 0, 0, 1.50], # 10: ordinary regiment
	[16, 6,  2, 0,  0, 0,  0, 0, 0, 0, 1.50], # 11: strong goblins
	[16, 6,  3, 1,  0, 0,  0, 0, 0, 0, 1.48], # 12: strong werewolf
	[16, 6,  5, 1,  0, 0,  0, 0, 0, 0, 1.46], # 13
	[14, 6,  7, 2,  0, 0,  0, 0, 0, 0, 1.44], # 14
	[12, 6, 10, 3,  0, 0,  0, 0, 0, 0, 1.42], # 15
	[12, 6, 12, 4,  0, 0,  0, 0, 0, 0, 1.40], # 16
	[10, 6, 15, 5,  0, 0,  0, 0, 0, 0, 1.38], # 17
	[10, 6, 17, 6,  0, 0,  0, 0, 0, 0, 1.36], # 18
	[ 8, 6, 20, 7,  0, 0,  0, 0, 0, 0, 1.34], # 19
	[ 8, 5, 20, 7,  1, 0,  0, 0, 0, 0, 1.32], # 20: first angry goblin
	[ 6, 4, 20, 7,  2, 0,  0, 0, 0, 0, 1.30], # 21
	[ 4, 3, 20, 7,  3, 1,  0, 0, 0, 0, 1.28], # 22: angry werewolf
	[ 2, 2, 20, 7,  5, 2,  0, 0, 0, 0, 1.26], # 23
	[ 0, 0, 20, 7,  7, 3,  0, 0, 0, 0, 1.24], # 24
	[ 0, 0, 20, 7, 10, 4,  0, 0, 0, 0, 1.22], # 25
	[ 0, 0, 18, 7, 13, 5,  0, 0, 0, 0, 1.20], # 26
	[ 0, 0, 18, 7, 15, 6,  0, 0, 0, 0, 1.18], # 27
	[ 0, 0, 18, 7, 17, 7,  0, 0, 0, 0, 1.16], # 28
	[ 0, 0, 16, 7, 20, 8,  0, 0, 0, 0, 1.14], # 29
	[ 0, 0, 16, 6, 20, 8,  1, 0, 0, 0, 1.12], # 30: first giant
	[ 0, 0, 14, 6, 20, 8,  2, 0, 0, 0, 1.10], # 31
	[ 0, 0, 12, 5, 20, 8,  3, 1, 0, 0, 1.10], # 32: giant werewolf
	[ 0, 0, 10, 4, 20, 8,  4, 1, 0, 0, 1.10], # 33
	[ 0, 0,  8, 3, 20, 8,  5, 2, 0, 0, 1.08], # 34
	[ 0, 0,  6, 2, 20, 8,  6, 2, 0, 0, 1.08], # 35
	[ 0, 0,  4, 1, 20, 8,  7, 3, 0, 0, 1.06], # 36
	[ 0, 0,  2, 0, 20, 8,  8, 4, 0, 0, 1.06], # 37
	[ 0, 0,  0, 0, 20, 8, 10, 4, 0, 0, 1.04], # 38
	[ 0, 0,  0, 0, 20,10, 12, 5, 0, 0, 1.04], # 39
	[ 0, 0,  0, 0, 20,10, 10, 5, 1, 0, 1.02], # 40: first angry giant
	[ 0, 0,  0, 0, 20,10, 10, 5, 2, 0, 1.02], # 41
	[ 0, 0,  0, 0, 20,10,  9, 5, 2, 1, 1.00], # 42: angry giant werewolf
	[ 0, 0,  0, 0, 20,10,  9, 5, 3, 1, 1.00], # 43
	[ 0, 0,  0, 0, 20,10,  8, 5, 4, 2, 0.98], # 44
	[ 0, 0,  0, 0, 20,10,  8, 5, 5, 2, 0.98], # 45
	[ 0, 0,  0, 0, 20,10,  8, 4, 5, 3, 0.96], # 46
	[ 0, 0,  0, 0, 20,10,  7, 4, 6, 3, 0.96], # 47
	[ 0, 0,  0, 0, 20,10,  7, 4, 6, 4, 0.94], # 48
	[ 0, 0,  0, 0, 20,10,  6, 3, 6, 4, 0.94], # 49
	[ 0, 0,  0, 0,  0, 0,  4, 2, 8, 6, 2.10], # 50: march of giants only
]


static func get_wave(number: int) -> Dictionary:
	assert(number > 0, "Wave numbers start at one")
	var row: Array
	if number <= LAST_CAMPAIGN_WAVE:
		row = CAMPAIGN[number - 1].duplicate()
	else:
		# Free play only increases quantity. Stats, intervals and composition weights stay fixed.
		var extra := number - LAST_CAMPAIGN_WAVE
		# Exactly one additional giant per wave; the heaviest werewolves grow more slowly.
		var giant_wolves := extra / 5
		var angry_goblins := extra / 2
		var angry_wolves := extra / 10
		row = [0, 0, 0, 0, 0, 0, 4 + extra - giant_wolves - angry_goblins - angry_wolves,
			2 + giant_wolves, 8 + angry_goblins, 6 + angry_wolves, 2.1]
	var counts: Array[int] = []
	for index in 10:
		counts.append(int(row[index]))
	var order: Array[Dictionary] = []
	# Smooth weighted interleaving, with stable tie order and no random seed.
	var remaining := counts.duplicate()
	var total := 0
	for count: int in counts: total += count
	var weights: Array[int] = []
	weights.resize(10)
	weights.fill(0)
	for slot in total:
		var selected := -1
		for kind in 10:
			weights[kind] += counts[kind]
			if remaining[kind] > 0 and (selected < 0 or weights[kind] > weights[selected]):
				selected = kind
		weights[selected] -= total
		remaining[selected] -= 1
		order.append({"species": selected % 2, "tier": selected / 2})
	return {"number": number, "counts": counts, "enemies": order,
		"interval": float(row[10]), "reward": 50, "campaign": number <= LAST_CAMPAIGN_WAVE}


static func describe(number: int) -> String:
	var wave := get_wave(number)
	var lines: Array[String] = ["Следующая волна: %d" % number]
	for tier in 5:
		var goblins: int = wave.counts[tier * 2]
		var wolves: int = wave.counts[tier * 2 + 1]
		if goblins + wolves > 0:
			lines.append("%s: гоблины %d : оборотни %d" % [VARIANTS[tier], goblins, wolves])
	return "\n".join(lines)
