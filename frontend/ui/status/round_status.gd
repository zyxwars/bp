## Informs player about what is currently happening
extends Control

@onready var _label: Label = %Label

func _ready() -> void:
	Events.game_started.connect(hide)
	Events.round_ended.connect(hide)
	Events.exploration_decided.connect(hide)
	Events.attack_sides_decided.connect(hide)
	Events.attack_resolved.connect(func(_attacker_id, _defender_id, _attackers_won, _gold_captured, _attacker_ships, _defender_ships, _attacker_ally_id, _defender_ally_ids, _neutral_player_ids, _attacker_invited_player_ids, _defender_invited_player_ids): hide())

	Events.deciding_exploration.connect(_on_deciding_exploration)
	Events.deciding_attack.connect(_on_deciding_attack)
	Events.deciding_defense.connect(_on_deciding_defense)
	Events.deciding_attack_sides.connect(_on_deciding_attack_sides)
	Events.exploration_resolved.connect(_on_exploration_resolved)

	hide()


func _on_deciding_exploration() -> void:
	_label.text = "Waiting for all players to split ships"
	show()

func _on_attacker_chosen(_attacker_id: int) -> void:
	_label.text = "Choosing attacker"
	show()

func _on_attacker_chosen_animation_finished(attacker_id: int) -> void:
	_label.text = "%s is the attacker" % AvatarLoader.get_player_name(attacker_id)
	show()

func _on_deciding_attack(attacker_id: int) -> void:
	_label.text = "%s is choosing attack target" % AvatarLoader.get_player_name(attacker_id)
	show()


func _on_deciding_defense(_attacker_id: int, defender_id: int) -> void:
	var defender_name = AvatarLoader.get_player_name(defender_id)
	_label.text = "%s is choosing defense" % defender_name
	show()


func _on_deciding_attack_sides(_attacker_id: int, _defender_id: int, _attacker_invited_player_ids: Array[int], _defender_invited_player_ids: Array[int]) -> void:
	_label.text = "Waiting for invited allies to choose side"
	show()


func _on_exploration_resolved() -> void:
	_label.text = "Waiting for ships to return from exploration"
	show()
