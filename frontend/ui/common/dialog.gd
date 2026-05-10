class_name Dialog extends Control

signal closed()

func _ready() -> void:
	%CloseButton.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	closed.emit()
