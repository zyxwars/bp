extends Control

## Show game ui on game start
func _ready() -> void:
	Events.game_started.connect(show)
	hide()
