extends Node

@onready var _form_dialog: Control = %FormDialog

func _ready() -> void:
	# Hide form if disabled in config
	if not Bootstrap.forms_enabled:
		_form_dialog.hide()

	if State.winner_id != -1:
		var player = State.players[State.winner_id]
		%Avatar.texture = AvatarLoader.get_player_avatar(player.id)
		%Winner.text = "%s won with %d gold!" % [AvatarLoader.get_player_name(player.id), player.gold]

	%SubmitButton.pressed.connect(_on_form_pressed)

func _on_form_pressed():
	# Open end game form in a new tab
	JavaScriptBridge.eval('window.open("%s%s", "_blank");' % [Bootstrap.postgame_form, State.user_id])
	_form_dialog.hide()
