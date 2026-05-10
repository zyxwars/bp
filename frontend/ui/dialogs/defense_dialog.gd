class_name DefenseDialog extends Control

@onready var _dialog: Dialog = %Dialog
@onready var _invite_picker: PlayerPicker = %"InvitePicker"
@onready var _info: Label = %"Info"
@onready var _text_edit: TextEdit = %"TextEdit"
@onready var _submit_button: Button = %"SubmitButton"

var _attacker_id := 0
var _defender_id := 0

## Open when this player is attacked and has to invite allies
func _open(attacker_id: int, defender_id: int):
	if defender_id != State.get_this_player().id:
		return

	_attacker_id = attacker_id
	_defender_id = defender_id

	_text_edit.clear()
	_info.text = "%s decided to attack you!" % AvatarLoader.get_player_name(attacker_id)
	var other_ids: Array[int] = []
	other_ids.assign(State.players.filter(func(p): return p.id != attacker_id and p.id != defender_id).map(func(p): return p.id))
	_invite_picker.reset(other_ids)

	await get_tree().process_frame
	show()

func _close():
	hide()

func _ready() -> void:
	Events.deciding_defense.connect(_open)
	_submit_button.pressed.connect(_on_submit)
	_dialog.closed.connect(_close)

	_close()

func _on_submit():
	var invited: Array[int] = []
	invited.assign(_invite_picker.selected_player_ids)
	Events.decide_defense_submitted.emit(
		_attacker_id,
		_defender_id,
		invited,
		"",
		_text_edit.text,
	)
	_close()
