## Player avatar with attack side information
class_name PlayerAttackInfo extends Control

const POSITIVE_CHANGE_COLOR := Color("40a249")
const NEGATIVE_CHANGE_COLOR := Color("eb4034")

@onready var _avatar: TextureRect = $HBoxContainer/TextureRect
@onready var _stats: Control = $HBoxContainer/VBoxContainer
@onready var _name: Label = %Name
@onready var _count: Label = %Count
@onready var _gold: Label = %Gold
@onready var _gold_change: Label = %GoldChange


func init(player_id: int, disabled_status: String = "") -> void:
	var player: PlayerState = State.players[player_id]
	_avatar.texture = AvatarLoader.get_player_avatar(player.id)

	# Disabled players didn't accept the invite to join
	if disabled_status != "":
		_stats.hide()
		_avatar.self_modulate = Color(0.55, 0.55, 0.55, 0.5)
		_name.show()
		_name.text = disabled_status
		return

	var player_name = AvatarLoader.get_player_name(player.id)
	if player == State.get_this_player():
		player_name += " (You)"
	_name.text = player_name

	_count.text = str(player.get_ships_at_home())
	_gold.text = "%d" % player.gold

	var attack_gold_change = player.attack_gold_change
	_gold_change.text = "(%+d)" % attack_gold_change

	if attack_gold_change > 0:
		_gold_change.add_theme_color_override("font_color", POSITIVE_CHANGE_COLOR)
	elif attack_gold_change < 0:
		_gold_change.add_theme_color_override("font_color", NEGATIVE_CHANGE_COLOR)
	else:
		_gold_change.text = ""
		_gold_change.remove_theme_color_override("font_color")
