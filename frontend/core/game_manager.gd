## Main game logic manager
class_name GameManager extends Node


func _ready():
	Events.starting_round.connect(_game_loop)

	Events.decide_exploration_submitted.connect(_on_decide_exploration_submitted)
	Events.decide_attack_submitted.connect(_on_decide_attack_submitted)
	Events.decide_defense_submitted.connect(_on_decide_defense_submitted)
	Events.decide_attack_side_submitted.connect(_on_decide_attack_side_submitted)


# All play-testing data from this demo is logged on the backend

func _log(data: Dictionary) -> void:
	var body = {"userId": State.user_id, "sessionId": State.session_id, "data": data}
	await ApiService._async_post("/log", body)


func _attack_side_string(side: State.AttackSide) -> String:
	match side:
		State.AttackSide.Attack:
			return "attack"
		State.AttackSide.Defense:
			return "defense"
		_:
			return "neutral"


func _on_decide_exploration_submitted(player_id: int, ship_count: int, private_thought: String, discussion: String, strategy: String, player_analysis: Dictionary) -> void:
	_log({
		"type": "decideExploration",
		"playerId": player_id,
		"privateThought": private_thought,
		"explorationShipCount": ship_count,
		"discussion": discussion,
		"strategy": strategy,
		"playerAnalysis": player_analysis,
	})
	Events.player_exploration_decided.emit(player_id, ship_count, discussion)


func _on_decide_attack_submitted(attacker_id: int, defender_id: int, invited_player_ids: Array[int], private_thought: String, discussion: String) -> void:
	_log({
		"type": "decideAttack",
		"playerId": attacker_id,
		"privateThought": private_thought,
		"defenderId": defender_id,
		"invitedPlayerIds": invited_player_ids,
		"discussion": discussion,
	})
	Events.attack_decided.emit(attacker_id, defender_id, invited_player_ids, discussion)


func _on_decide_defense_submitted(attacker_id: int, defender_id: int, invited_player_ids: Array[int], private_thought: String, discussion: String) -> void:
	_log({
		"type": "decideDefense",
		"playerId": defender_id,
		"privateThought": private_thought,
		"invitedPlayerIds": invited_player_ids,
		"discussion": discussion,
	})
	Events.defense_decided.emit(attacker_id, defender_id, invited_player_ids, discussion)


func _on_decide_attack_side_submitted(player_id: int, side: State.AttackSide, private_thought: String, discussion: String) -> void:
	_log({
		"type": "decideAttackSide",
		"playerId": player_id,
		"privateThought": private_thought,
		"side": _attack_side_string(side),
		"discussion": discussion,
	})
	Events.player_attack_side_decided.emit(player_id, side, discussion)


## Main game loop
func _game_loop():
	# Check win condition
	var max_gold_player_count = 0
	var max_gold_player = State.players[0]
	for player in State.players:
		if player.gold > max_gold_player.gold:
			max_gold_player_count = 1
			max_gold_player = player
		elif player.gold == max_gold_player.gold:
			max_gold_player_count += 1

	# Only one player can win, continue game if there is a tie
	if (max_gold_player_count == 1 and max_gold_player.gold >= State.WIN_GOLD):
		State.winner_id = max_gold_player.id

		_log({
			"type": "gameEnded",
			"round": State.game_round,
			"winnerId": max_gold_player.id,
			"players": State.players.map(func(p): return {
				"id": p.id,
				"name": AvatarLoader.get_player_name(p.id),
				"gold": p.gold,
			}),
		})

		Events.player_won.emit(max_gold_player.id)
		return

	_log({
		"type": "roundStarted",
		"round": State.game_round,
		"players": State.players.map(func(p): return {
			"id": p.id,
			"name": AvatarLoader.get_player_name(p.id),
			"gold": p.gold,
			"explorationShipCount": p.exploration_ship_count,
		}),
	})

	Events.round_started.emit()

	# Exploration
	# Use deferred call to avoid missing events in the await loop
	Events.deciding_exploration.emit.call_deferred()

	for _i in State.players:
		var decide_exploration_res = await Events.player_exploration_decided
		var player_id = decide_exploration_res[0]
		var exploration_ship_count = decide_exploration_res[1]
		State.players[player_id].exploration_ship_count = exploration_ship_count

	Events.exploration_decided.emit.call_deferred()
	await Events.starting_attack_phase

	# Attack
	var attacker = State.players.pick_random()

	# Wait for animation
	Events.attacker_chosen.emit.call_deferred(attacker.id)
	await Events.attacker_chosen_acknowledged

	Events.deciding_attack.emit.call_deferred(attacker.id)

	var decide_attack_res = await Events.attack_decided
	var decided_attacker_id = decide_attack_res[0]
	var defender_id = decide_attack_res[1]
	var attacker_invited_player_ids: Array[int] = []
	attacker_invited_player_ids.assign(decide_attack_res[2])

	# Defense
	var defender = State.players[defender_id]
	Events.deciding_defense.emit.call_deferred(decided_attacker_id, defender.id)

	var decide_defense_res = await Events.defense_decided
	var defender_invited_player_ids: Array[int] = []
	defender_invited_player_ids.assign(decide_defense_res[2])

	var invited_player_ids = attacker_invited_player_ids.duplicate()
	for v in defender_invited_player_ids:
		if v not in invited_player_ids:
			invited_player_ids.append(v)

	# Allies
	Events.deciding_attack_sides.emit.call_deferred(attacker.id, defender.id, attacker_invited_player_ids, defender_invited_player_ids)

	var attacker_ally_ids: Array[int] = []
	var defender_ally_ids: Array[int] = []
	var neutral_player_ids: Array[int] = []

	for _i in invited_player_ids:
		var decide_attack_side_res = await Events.player_attack_side_decided
		var player_id = decide_attack_side_res[0]
		var side = decide_attack_side_res[1]
		if State.AttackSide.Attack == side:
			attacker_ally_ids.push_back(player_id)
		elif State.AttackSide.Defense == side:
			defender_ally_ids.push_back(player_id)
		else:
			neutral_player_ids.push_back(player_id)

	Events.attack_sides_decided.emit.call_deferred()
	await Events.starting_attack_resolution

	# Attack resolution
	var attackers = [attacker]
	attackers.append_array(attacker_ally_ids.map(func(id): return State.players[id]))
	var defenders = [defender]
	defenders.append_array(defender_ally_ids.map(func(id): return State.players[id]))

	# Count ships per attack side
	var attack_ships = attackers.reduce(func(acc, curr): return acc + curr.get_ships_at_home(), 0)
	var defense_ships = defenders.reduce(func(acc, curr): return acc + curr.get_ships_at_home(), 0)

	# Determine attack winners
	# Defenders win on stalemate
	var attackers_won = attack_ships > defense_ships

	var winners = []
	var losers = []
	if attackers_won:
		winners = attackers
		losers = defenders
	else:
		winners = defenders
		losers = attackers

	# Attackers capture gold from the losers
	var total_captured_gold = 0
	for loser in losers:
		# Each losers loses half of their gold (rounded down)
		var lost_gold = floor(loser.gold / 2)
		loser.attack_gold_change = - lost_gold
		total_captured_gold += lost_gold

	# Winner split the spoils evenly
	var captured_split = floor(total_captured_gold / winners.size())
	for winner in winners:
		winner.attack_gold_change = captured_split

	# Remainded of the gold goes to the lead attacker/defender
	var remainder = total_captured_gold % winners.size()
	if remainder > 0:
		winners[0].attack_gold_change += remainder

	var attack_resolved_players = []
	for p in State.players:
		var is_attack_side = p.id == attacker.id or attacker_ally_ids.has(p.id)
		var is_defense_side = p.id == defender.id or defender_ally_ids.has(p.id)
		var p_side = "attack" if is_attack_side else ("defense" if is_defense_side else "neutral")
		attack_resolved_players.append({
			"playerId": p.id,
			"side": p_side,
			"invitedByAttacker": attacker_invited_player_ids.has(p.id),
			"invitedByDefender": defender_invited_player_ids.has(p.id),
			"homeShips": p.get_ships_at_home(),
			"goldChange": p.attack_gold_change,
		})

	_log({
		"type": "attackResolved",
		"round": State.game_round,
		"attackerId": attacker.id,
		"defenderId": defender.id,
		"attackWon": attackers_won,
		"players": attack_resolved_players,
	})

	Events.attack_resolved.emit.call_deferred(
		attacker.id,
		defender.id,
		attackers_won,
		total_captured_gold,
		attack_ships,
		defense_ships,
		attacker_ally_ids,
		defender_ally_ids,
		neutral_player_ids,
		attacker_invited_player_ids,
		defender_invited_player_ids
	)

	await Events.attack_resolved_acknowledged
	# Skip exploration resolution confirmation
	# await Events.starting_exploration_resolution

	# Exploration resolution
	Events.exploration_resolved.emit.call_deferred()
	for _i in State.players:
		await Events.exploration_resolution_ship_arrived

	# Apply gold changes
	for player in State.players:
		player.gold += player.exploration_ship_count
		player.gold += player.attack_gold_change

	_log({
		"type": "explorationResolved",
		"round": State.game_round,
		"players": State.players.map(func(p): return {
			"playerId": p.id,
			"explorationShipCount": p.exploration_ship_count,
			"goldChange": p.exploration_ship_count,
		}),
	})

	for player in State.players:
		player.exploration_ship_count = 0
		player.attack_gold_change = 0

	_log({
		"type": "roundEnded",
		"round": State.game_round,
		"players": State.players.map(func(p): return {
			"id": p.id,
			"name": AvatarLoader.get_player_name(p.id),
			"gold": p.gold,
		}),
	})

	Events.round_ended.emit()
	State.game_round += 1
