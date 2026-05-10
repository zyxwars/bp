extends Control

@onready var _submit_button: Button = %"SubmitButton"

## Confirm player wants to start the next round
func _open() -> void:
	show()


func _close():
	Events.starting_round.emit()
	hide()


func _ready() -> void:
	Events.help_closed.connect(_open)
	Events.round_ended.connect(_open)
	_submit_button.pressed.connect(_close)
	hide()
