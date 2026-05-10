class_name AttackSideDialog extends Control

@onready var _info: Label = %"Info"
@onready var _text_edit: TextEdit = %"TextEdit"
@onready var _neutral: Button = %"Neutral"
@onready var _defense: Button = %"Defense"
@onready var _attack: Button = %"Attack"


## Show when this player has to choose attack side
func _open(attacker_id: int, defender_id: int, attacker_invited_player_ids: Array[int], defender_invited_player_ids: Array[int]):
	var player = State.get_this_player()

	var has_attacker_side_invite = attacker_invited_player_ids.has(player.id)
	var has_defender_side_invite = defender_invited_player_ids.has(player.id)

	if not has_attacker_side_invite and not has_defender_side_invite:
		return

	_text_edit.clear()
	_attack.show()
	_defense.show()
	_attack.disabled = not has_attacker_side_invite
	_defense.disabled = not has_defender_side_invite

	var attacker = State.players[attacker_id]
	var defender = State.players[defender_id]

	var attacker_name = AvatarLoader.get_player_name(attacker.id)
	var defender_name = AvatarLoader.get_player_name(defender.id)

	var invite_text: String
	if has_attacker_side_invite and has_defender_side_invite:
		invite_text = "Both %s and %s invited you." % [attacker_name, defender_name]
	elif has_attacker_side_invite:
		invite_text = "%s invited you to the attacking side." % attacker_name
	else:
		invite_text = "%s invited you to the defending side." % defender_name

	_info.text = "%s is attacking %s.\n%s Choose which side you want to join." % [attacker_name, defender_name, invite_text]

	_attack.text = "%s (Attack)" % attacker_name
	_defense.text = "%s (Defense)" % defender_name
	_apply_button_color(_attack, attacker.id)
	_apply_button_color(_defense, defender.id)
	await get_tree().process_frame
	show()

func _apply_button_color(button: Button, player_id: int) -> void:
	var style = button.get_theme_stylebox("normal") as StyleBoxFlat
	style.bg_color = AvatarLoader.get_player_color(player_id)
	style.border_color = AvatarLoader.get_player_color_dark(player_id)


func _close():
	hide()


func _ready() -> void:
	Events.deciding_attack_sides.connect(_open)
	_neutral.pressed.connect(_on_neutral_pressed)
	_defense.pressed.connect(_on_defense_pressed)
	_attack.pressed.connect(_on_attack_pressed)
	_close()


func _on_neutral_pressed():
	Events.decide_attack_side_submitted.emit(State.get_this_player().id, State.AttackSide.Neutral, "", _text_edit.text)
	_close()


func _on_defense_pressed():
	Events.decide_attack_side_submitted.emit(State.get_this_player().id, State.AttackSide.Defense, "", _text_edit.text)
	_close()


func _on_attack_pressed():
	Events.decide_attack_side_submitted.emit(State.get_this_player().id, State.AttackSide.Attack, "", _text_edit.text)
	_close()
