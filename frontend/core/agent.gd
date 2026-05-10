## Agent client
## Listens for simulation events and responds with choices
## Manages agent memory and other state
class_name Agent extends Node


var _player: PlayerState

func init(player: PlayerState) -> void:
	_player = player


func _record_private_thought(event: String, private_thought: String):
	_record_memory("[Private] Round %s %s: %s" % [State.game_round, event, private_thought])


func _record_memory(value: String):
	_player.agent_state["history"].push_back(value)

	if (_player.agent_state["history"].size() > State.MAX_MEMORY_SIZE):
		_player.agent_state["history"].pop_front()

func _get_player_name(player_id: int):
	return AvatarLoader.get_player_name(player_id)

func _get_player_names(player_ids: Array[int]) -> Array[String]:
	var names: Array[String] = []
	for player_id in player_ids:
		names.push_back(_get_player_name(player_id))
	return names

func _format_player_names(player_ids: Array[int]) -> String:
	if player_ids.is_empty():
		return "none"

	return ", ".join(_get_player_names(player_ids))

func _get_attack_side_string(side: State.AttackSide):
	match side:
		State.AttackSide.Attack:
			return "attack"
		State.AttackSide.Defense:
			return "defense"
		State.AttackSide.Neutral:
			return "neutral"

func _to_state_dto(player: PlayerState) -> Dictionary:
	return {
		"sessionId": State.session_id,
		"userId": State.user_id,
		"players": State.players.map(func(p): return {
			"id": p.id,
			"name": AvatarLoader.get_player_name(p.id),
			"gold": p.gold,
			}),
		"round": State.game_round,
		"thisPlayerId": player.id,
		"agentState": player.agent_state
		}


func _ready() -> void:
	Events.deciding_exploration.connect(_on_decide_exploration)
	Events.deciding_attack.connect(_on_decide_attack)
	Events.deciding_defense.connect(_on_decide_defense)
	Events.deciding_attack_sides.connect(_on_decide_attack_side)

	Events.attacker_chosen.connect(_on_record_attacker_chosen)
	Events.player_exploration_decided.connect(_on_record_exploration_decided)
	Events.attack_decided.connect(_on_record_attack_decided)
	Events.defense_decided.connect(_on_record_defense_decided)
	Events.player_attack_side_decided.connect(_on_record_attack_side_decided)
	Events.attack_resolved.connect(_on_record_attack_resolved)
	Events.exploration_resolved.connect(_on_record_exploration_resolved)

# Handlers

func _on_decide_exploration():
	prints("[Agent]: deciding exploration", _player.id)

	var body = {
		"state": _to_state_dto(_player),
	}
	var res = await ApiService._async_post("/llm/exploration", body)

	_player.agent_state["strategy"] = res["strategy"]
	_player.agent_state["playerAnalysis"] = res["playerAnalysis"]

	_record_private_thought("Exploration", res["privateThought"])

	Events.decide_exploration_submitted.emit.call_deferred(
		_player.id,
		res["explorationShipCount"],
		res["privateThought"],
		res["discussion"],
		res["strategy"],
		res["playerAnalysis"],
	)


func _on_decide_attack(attacker_id: int):
	if attacker_id != _player.id:
		return


	prints("[Agent]: deciding attack", _player.id)


	var body = {
		"state": _to_state_dto(_player),
	}
	var res = await ApiService._async_post("/llm/attack", body)

	_record_private_thought("Attack", res["privateThought"])
	var attack_invited: Array[int] = []
	attack_invited.assign(res["invitedPlayerIds"])

	Events.decide_attack_submitted.emit.call_deferred(attacker_id, res["defenderId"], attack_invited, res["privateThought"], res["discussion"])


func _on_decide_defense(attacker_id: int, defender_id: int):
	if defender_id != _player.id:
		return

	prints("[Agent]: deciding defense", _player.id)


	var body = {
		"state": _to_state_dto(_player),
		"attackerId": attacker_id,
	}
	var res = await ApiService._async_post("/llm/defense", body)

	_record_private_thought("Defense", res["privateThought"])
	var defense_invited: Array[int] = []
	defense_invited.assign(res["invitedPlayerIds"])

	Events.decide_defense_submitted.emit.call_deferred(attacker_id, defender_id, defense_invited, res["privateThought"], res["discussion"])


func _on_decide_attack_side(attacker_id: int, defender_id: int, attacker_invited_player_ids: Array[int], defender_invited_player_ids: Array[int]):
	var has_attacker_side_invite = attacker_invited_player_ids.has(_player.id)
	var has_defender_side_invite = defender_invited_player_ids.has(_player.id)

	if not has_attacker_side_invite and not has_defender_side_invite:
		return

	prints("[Agent]: deciding attack side", _player.id)


	var body = {
		"state": _to_state_dto(_player),
		"attackerId": attacker_id,
		"defenderId": defender_id,
		"hasAttackerSideInvite": has_attacker_side_invite,
		"hasDefenderSideInvite": has_defender_side_invite
	}
	var res = await ApiService._async_post("/llm/attackSide", body)

	_record_private_thought("AttackSide", res["privateThought"])

	var side = State.AttackSide.Neutral
	match res["side"]:
		"attack":
			side = State.AttackSide.Attack
		"defense":
			side = State.AttackSide.Defense
		"neutral":
			side = State.AttackSide.Neutral
		_:
			assert(false, "Invalid attack side %s" % res["side"])

	Events.decide_attack_side_submitted.emit.call_deferred(_player.id, side, res["privateThought"], res["discussion"])

# Memory

func _on_record_attacker_chosen(attacker_id: int) -> void:
	_record_memory("Round %s | %s was chosen as the attacker." % [State.game_round, _get_player_name(attacker_id)])

func _on_record_exploration_decided(player_id: int, _ship_count: int, discussion: String) -> void:
	_record_memory("Round %s | %s says: %s" % [State.game_round, _get_player_name(player_id), discussion])

func _on_record_attack_decided(attacker_id: int, defender_id: int, invited_player_ids: Array[int], discussion: String) -> void:
	_record_memory("Round %s | %s attacks %s; invited allies: %s. %s" % [
		State.game_round,
		_get_player_name(attacker_id),
		_get_player_name(defender_id),
		_format_player_names(invited_player_ids),
		discussion,
	])

func _on_record_defense_decided(attacker_id: int, defender_id: int, invited_player_ids: Array[int], discussion: String) -> void:
	_record_memory("Round %s | %s defends against %s; invited allies: %s. %s" % [
		State.game_round,
		_get_player_name(defender_id),
		_get_player_name(attacker_id),
		_format_player_names(invited_player_ids),
		discussion,
	])

func _on_record_attack_side_decided(player_id: int, side: State.AttackSide, discussion: String) -> void:
	_record_memory("Round %s | %s joins %s. %s" % [
		State.game_round,
		_get_player_name(player_id),
		_get_attack_side_string(side),
		discussion,
	])

func _on_record_attack_resolved(
	attacker_id: int,
	defender_id: int,
	attackers_won: bool,
	gold_captured: int,
	attacker_ships: int,
	defender_ships: int,
	attacker_ally_ids: Array[int],
	defender_ally_ids: Array[int],
	_neutral_player_ids: Array[int],
	_attacker_invited_player_ids: Array[int],
	_defender_invited_player_ids: Array[int]
) -> void:
	var winner = _get_player_name(attacker_id) if attackers_won else _get_player_name(defender_id)
	_record_memory("Round %s | Combat resolved: attacker side %d ships vs defender side %d ships. Winner: %s's side." % [
		State.game_round,
		attacker_ships,
		defender_ships,
		winner,
	])

	var winner_count = (1 + attacker_ally_ids.size()) if attackers_won else (1 + defender_ally_ids.size())
	_record_memory("Round %s | Spoils distributed: %d total gold across %d winner(s)." % [
		State.game_round,
		gold_captured,
		winner_count,
	])

func _on_record_exploration_resolved() -> void:
	var parts: Array[String] = []
	for player in State.players:
		var gold_change = player.attack_gold_change + player.exploration_ship_count
		var final_gold = player.gold + gold_change
		parts.append("%s: %d gold (%+d), home %d/%d ships, exploring %d" % [
			_get_player_name(player.id),
			final_gold,
			gold_change,
			player.get_ships_at_home(),
			State.SHIP_COUNT,
			player.exploration_ship_count,
		])
	_record_memory("Round %s end | %s" % [State.game_round, " | ".join(parts)])
