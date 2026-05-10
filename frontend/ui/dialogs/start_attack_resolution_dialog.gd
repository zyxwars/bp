extends Control

@onready var _submit_button: Button = %"SubmitButton"

## Show when player needs to confirm attack resolution
func _open() -> void:
	show()


func _close() -> void:
	Events.starting_attack_resolution.emit()
	hide()


func _ready() -> void:
	Events.attack_sides_decided.connect(_open)
	_submit_button.pressed.connect(_close)
	hide()
