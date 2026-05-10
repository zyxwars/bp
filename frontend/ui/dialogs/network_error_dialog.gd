extends Control

@onready var _error: Label = %Error


## Show on network error and wait for player manually retry
func _ready() -> void:
	Events.network_error.connect(_on_network_error)
	%RetryButton.pressed.connect(_on_retry_button_pressed)
	hide()


func _on_network_error(message: String):
	_error.text = message
	await get_tree().process_frame
	show()


func _on_retry_button_pressed():
	Events.network_retrying.emit()
	hide()
