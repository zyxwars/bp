## Track current player information and latest discussion entry
class_name PlayerPanel extends PanelContainer

const POSITIVE_CHANGE_COLOR := Color("40a249")
const NEGATIVE_CHANGE_COLOR := Color("eb4034")

@onready var _avatar: TextureRect = %Avatar
@onready var _name: Label = %Name
@onready var _gold: Label = %Gold
@onready var _attack_gold_change: Label = %AttackGoldChange
@onready var _exploration_gold_change: Label = %ExplorationGoldChange
@onready var _last_message: Label = %LastMessage

var _player: PlayerState

func init(player_id: int):
	_player = State.players[player_id]
	_avatar.texture = AvatarLoader.get_player_avatar(_player.id)

	var player_name = AvatarLoader.get_player_name(_player.id)
	if _player == State.get_this_player():
		player_name += " (You)"
	_name.text = player_name

func _ready() -> void:
	Events.game_started.connect(_on_game_started)
	Events.round_started.connect(_on_round_started)
	Events.attack_resolved.connect(_on_attack_resolved)
	Events.exploration_resolution_ship_arrived.connect(_on_exploration_resolution_ship_arrived)
	Events.deciding_exploration.connect(_on_deciding_exploration)
	Events.deciding_attack.connect(_on_deciding_attack)
	Events.deciding_defense.connect(_on_deciding_defense)
	Events.deciding_attack_sides.connect(_on_deciding_attack_sides)
	Events.player_exploration_decided.connect(_on_player_exploration_decided)
	Events.attack_decided.connect(_on_attack_decided)
	Events.defense_decided.connect(_on_defense_decided)
	Events.player_attack_side_decided.connect(_on_player_attack_side_decided)

	Events.starting_attack_phase.connect(_clear_message)
	Events.starting_attack_resolution.connect(_clear_message)
	Events.exploration_resolved.connect(_clear_message)

	_set_last_message("")
	hide()


func _on_game_started():
	show()
	_gold.text = "%d" % _player.gold


func _on_round_started():
	_attack_gold_change.text = ""
	_exploration_gold_change.text = ""
	_gold.text = "%d" % _player.gold


func _on_attack_resolved(_attacker_id: int, _defender_id: int, _attackers_won: bool, _gold_captured: int, _attacker_ships: int, _defender_ships: int, _attacker_ally_id: Array[int], _defender_ally_ids: Array[int], _neutral_player_ids: Array[int], _attacker_invited_player_ids: Array[int], _defender_invited_player_ids: Array[int]) -> void:
	var gold_change = _player.attack_gold_change

	_attack_gold_change.text = "(%+d)" % gold_change

	if gold_change > 0:
		_attack_gold_change.add_theme_color_override("font_color", POSITIVE_CHANGE_COLOR)
	elif gold_change < 0:
		_attack_gold_change.add_theme_color_override("font_color", NEGATIVE_CHANGE_COLOR)
	else:
		_attack_gold_change.text = ""
		_attack_gold_change.remove_theme_color_override("font_color")


func _on_exploration_resolution_ship_arrived(player_id: int) -> void:
	if _player.id != player_id:
		return

	if _player.exploration_ship_count <= 0:
		_exploration_gold_change.text = ""
		_exploration_gold_change.remove_theme_color_override("font_color")
		return

	_exploration_gold_change.text = "(+%d)" % _player.exploration_ship_count
	_exploration_gold_change.add_theme_color_override("font_color", POSITIVE_CHANGE_COLOR)


func _on_deciding_exploration() -> void:
	_set_last_message("Choosing exploration")


func _on_deciding_attack(attacker_id: int) -> void:
	if _player.id != attacker_id:
		return

	_set_last_message("Choosing attack")


func _on_deciding_defense(_attacker_id: int, defender_id: int) -> void:
	if _player.id != defender_id:
		return

	_set_last_message("Choosing defense")


func _on_deciding_attack_sides(_attacker_id: int, _defender_id: int, _attacker_invited_player_ids: Array[int], _defender_invited_player_ids: Array[int]) -> void:
	if not _attacker_invited_player_ids.has(_player.id) and not _defender_invited_player_ids.has(_player.id):
		return

	_set_last_message("Choosing attack side")


func _clear_message() -> void:
	_set_last_message("")

func _on_player_exploration_decided(player_id: int, _ship_count: int, discussion: String) -> void:
	if _player.id != player_id:
		return
	_set_last_message(discussion)

func _on_attack_decided(attacker_id: int, _defender_id: int, _invited: Array[int], discussion: String) -> void:
	if _player.id != attacker_id:
		return
	_set_last_message(discussion)

func _on_defense_decided(_attacker_id: int, defender_id: int, _invited: Array[int], discussion: String) -> void:
	if _player.id != defender_id:
		return
	_set_last_message(discussion)

func _on_player_attack_side_decided(player_id: int, _side: State.AttackSide, discussion: String) -> void:
	if _player.id != player_id:
		return
	_set_last_message(discussion)


func _set_last_message(message: String) -> void:
	_last_message.text = message
	# Panels don't go back to their original size without setting this
	reset_size()
