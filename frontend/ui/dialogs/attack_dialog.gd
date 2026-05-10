class_name AttackDialog extends Control

@onready var _dialog: Dialog = %Dialog
@onready var _defender_picker: PlayerPicker = %"DefenderPicker"
@onready var _invite_picker: PlayerPicker = %"InvitePicker"
@onready var _text_edit: TextEdit = %"TextEdit"
@onready var _submit_button: Button = %"SubmitButton"

var _attacker_id := 0

## Show when this player has to choose attack target and invite allies
func _open(attacker_id: int):
	if attacker_id != State.get_this_player().id:
		return

	_attacker_id = attacker_id
	_text_edit.clear()

	var other_ids: Array[int] = []
	other_ids.assign(State.players.filter(func(p): return p.id != attacker_id).map(func(p): return p.id))
	_defender_picker.reset(other_ids)
	_invite_picker.reset(other_ids)
	_submit_button.disabled = true

	await get_tree().process_frame
	show()

func _close():
	hide()

func _ready() -> void:
	Events.deciding_attack.connect(_open)

	_defender_picker.selection_changed.connect(_on_defender_changed)
	_defender_picker.can_select_multiple = false

	_submit_button.pressed.connect(_on_submit)
	_submit_button.disabled = true
	_dialog.closed.connect(_close)

	_close()

func _on_defender_changed():
	_submit_button.disabled = _defender_picker.selected_player_ids.is_empty()

	if _defender_picker.selected_player_ids.is_empty():
		return

	# Hide defender from invite picker
	var defender_id = _defender_picker.selected_player_ids[0]
	var other_ids: Array[int] = []
	other_ids.assign(State.players.filter(func(p): return p.id != _attacker_id and p.id != defender_id).map(func(p): return p.id))
	_invite_picker.reset(other_ids)


func _on_submit():
	if _defender_picker.selected_player_ids.is_empty():
		return

	var invited: Array[int] = []
	invited.assign(_invite_picker.selected_player_ids)
	Events.decide_attack_submitted.emit(
		_attacker_id,
		_defender_picker.selected_player_ids[0],
		invited,
		"",
		_text_edit.text,
	)
	_close()
