extends Control

@onready var _hint_label: Label = %"HintLabel"
@onready var _submit_button: Button = %"SubmitButton"

# Form screen is shown before game can start if forms are enabled
var _is_form_screen := true

## Show when game starts
func _open() -> void:
	show()

func _ready() -> void:
	_submit_button.pressed.connect(_on_submit_pressed)

	if not Bootstrap.forms_enabled:
		_show_start_after_form()


func _on_submit_pressed():
	if not _is_form_screen:
		_close()
		return


	# Open form in new browser tab
	JavaScriptBridge.eval('window.open("%s%s", "_blank");' % [Bootstrap.pregame_form, State.user_id])
	_show_start_after_form()


func _show_start_after_form():
	_is_form_screen = false
	_hint_label.text = "Press 'Start Game' to start new game."
	_submit_button.text = "Start Game"

func _close() -> void:
	Events.game_started.emit()
	hide()