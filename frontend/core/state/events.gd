## Global event bus
## Events are used to connect the game simulation with agents and ui clients
extends Node

@warning_ignore_start("unused_signal")

# Simulaion lifecycle

signal game_started()

signal help_opened()
signal help_closed()


signal starting_round()
signal round_started()


# Exploration phase

signal deciding_exploration()
signal decide_exploration_submitted(player_id: int, ship_count: int, private_thought: String, discussion: String, strategy: String, player_analysis: Dictionary)
signal player_exploration_decided(player_id: int, exploration_ship_count: int, discussion: String)
signal exploration_decided()


# Attack phase

signal starting_attack_phase()

signal attacker_chosen(attacker_id: int)
signal attacker_chosen_acknowledged()

signal deciding_attack(attacker_id: int)
signal decide_attack_submitted(attacker_id: int, defender_id: int, invited_player_ids: Array[int], private_thought: String, discussion: String)
signal attack_decided(attacker_id: int, defender_id: int, invited_player_ids: Array[int], discussion: String)

signal deciding_defense(attacker_id: int, defender_id: int)
signal decide_defense_submitted(attacker_id: int, defender_id: int, invited_player_ids: Array[int], private_thought: String, discussion: String)
signal defense_decided(attacker_id: int, defender_id: int, invited_player_ids: Array[int], discussion: String)

signal deciding_attack_sides(attacker_id: int, defender_id: int, attacker_invited_player_ids: Array[int], defender_invited_player_ids: Array[int])
signal decide_attack_side_submitted(player_id: int, side: State.AttackSide, private_thought: String, discussion: String)
signal player_attack_side_decided(player_id: int, side: State.AttackSide, discussion: String)
signal attack_sides_decided()


# Resolution phase

signal starting_attack_resolution()
signal attack_resolved(attacker_id: int, defender_id: int, attackers_won: bool, gold_captured: int, attacker_ships: int, defender_ships: int, attacker_ally_id: Array[int], defender_ally_ids: Array[int], neutral_player_ids: Array[int], attacker_invited_player_ids: Array[int], defender_invited_player_ids: Array[int])
signal attack_resolved_acknowledged()


signal starting_exploration_resolution()
signal exploration_resolved()
signal exploration_resolution_ship_arrived(player_id: int)

signal round_ended()

signal player_won(player_id: int)


# Misc

signal network_error(message: String)

signal network_retrying()


@warning_ignore_restore("unused_signal")

var _signal_logger = SignalLogger.new()

func _ready() -> void:
	_signal_logger.watch(Events)
