extends Control

@onready var _dialog: Dialog = %Dialog
@onready var _title: Label = %Title
@onready var _label: Label = %Label
@onready var _attackers: Control = %Attackers
@onready var _defenders: Control = %Defenders
@onready var _submit_button: Button = %SubmitButton

var _player_attack_info_scene := preload("res://ui/dialogs/attack_resolved/player_attack_info.tscn")
var _player_attack_info_flipped_scene: PackedScene = load("res://ui/dialogs/attack_resolved/player_attack_info_flipped.tscn")

func _open(attacker_id: int, defender_id: int, attackers_won: bool, gold_captured: int, attacker_ships: int, defender_ships: int, attacker_ally_ids: Array[int], defender_ally_ids: Array[int], _neutral_player_ids: Array[int], attacker_invited_player_ids: Array[int], defender_invited_player_ids: Array[int]) -> void:
	for child in _attackers.get_children():
		child.queue_free()
	for child in _defenders.get_children():
		child.queue_free()

	var attackers = [attacker_id]
	attackers.append_array(attacker_ally_ids)

	var defenders = [defender_id]
	defenders.append_array(defender_ally_ids)

	for player_id in attackers:
		var info: PlayerAttackInfo = _player_attack_info_scene.instantiate()
		_attackers.add_child(info)
		info.init(player_id)

	for player_id in attacker_invited_player_ids:
		if not attackers.has(player_id):
			var info: PlayerAttackInfo = _player_attack_info_scene.instantiate()
			_attackers.add_child(info)
			var status := "Other side" if defenders.has(player_id) else "Neutral"
			info.init(player_id, status)

	for player_id in defenders:
		var info: PlayerAttackInfo = _player_attack_info_flipped_scene.instantiate()
		_defenders.add_child(info)
		info.init(player_id)

	for player_id in defender_invited_player_ids:
		if not defenders.has(player_id):
			var info: PlayerAttackInfo = _player_attack_info_flipped_scene.instantiate()
			_defenders.add_child(info)
			var status := "Other side" if attackers.has(player_id) else "Neutral"
			info.init(player_id, status)

	if attackers_won:
		_title.text = "Attackers won"
	else:
		_title.text = "Defenders won"

	var winner_ships := attacker_ships if attackers_won else defender_ships
	var loser_ships := defender_ships if attackers_won else attacker_ships

	_label.text = "%d vs %d ships. %d gold captured — half of each loser's pile, split equally among winner (remainder goes to leader)." % [winner_ships, loser_ships, gold_captured]

	await get_tree().process_frame
	show()

func _close():
	Events.attack_resolved_acknowledged.emit()
	hide()

func _ready() -> void:
	Events.attack_resolved.connect(_open)
	_dialog.closed.connect(_close)
	_submit_button.pressed.connect(_close)
	hide()
