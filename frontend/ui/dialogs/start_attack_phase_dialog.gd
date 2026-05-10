extends Control

@onready var _submit_button: Button = %"SubmitButton"

## Show when player needs to confirm attack phase
func _open() -> void:
	show()

func _close():
	Events.starting_attack_phase.emit()
	hide()


func _ready() -> void:
	Events.exploration_decided.connect(_open)
	_submit_button.pressed.connect(_close)
	hide()
