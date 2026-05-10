class_name MoveShipsDialog extends Control

@onready var _dialog: Dialog = $Dialog
@onready var _count: HSlider = %"Count"
@onready var _explore_count: Label = %"ExploreCount"
@onready var _home_count: Label = %"HomeCount"
@onready var _text_edit: TextEdit = %"TextEdit"
@onready var _submit_button: Button = %"SubmitButton"

## Let this player choose how many ships to send exploring this round
func _open():
	_count.min_value = 0
	_count.max_value = State.SHIP_COUNT
	_count.value = _count.min_value
	_explore_count.text = str(0)
	_home_count.text = str(State.SHIP_COUNT)
	_text_edit.clear()

	await get_tree().process_frame
	show()


func _close():
	hide()


func _ready() -> void:
	Events.deciding_exploration.connect(_open)
	_submit_button.pressed.connect(_on_submit)
	_dialog.closed.connect(_close)
	_count.value_changed.connect(_on_count_changed)

	_close()


func _on_submit():
	Events.decide_exploration_submitted.emit(
		State.get_this_player().id,
		int(_count.value),
		"",
		_text_edit.text,
		"",
		{},
	)
	_close()


func _on_count_changed(value: float):
	_explore_count.text = str(int(value))
	_home_count.text = str(State.SHIP_COUNT - int(value))
