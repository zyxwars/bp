## Loop players in a slot machine like popup until the attacker is chosen
extends Control

const STEP_LENGTH_SECONDS := 0.5
const STEPS := 4
const FINAL_HOLD_SECONDS := 3.0

@onready var _avatar: TextureRect = %Avatar
@onready var _label: Label = %Label


func _ready() -> void:
	Events.attacker_chosen.connect(_on_attacker_chosen)
	hide()

func _on_attacker_chosen(attacker_id: int) -> void:
	_label.text = "Choosing attacker"
	show()

	var start_player_id = randi_range(0, State.players.size() - 1)

	# Land on the predetermined attacker after looping at least `STEPS` times
	var step = 0
	while true:
		var current_player_id = (start_player_id + step) % State.players.size()
		_set_player(current_player_id)

		if step > STEPS and current_player_id == attacker_id:
			break

		await get_tree().create_timer(STEP_LENGTH_SECONDS).timeout
		step += 1

	_label.text = "%s is the attacker" % AvatarLoader.get_player_name(attacker_id)
	await get_tree().create_timer(FINAL_HOLD_SECONDS).timeout
	Events.attacker_chosen_acknowledged.emit()
	hide()


func _set_player(player_id: int) -> void:
	_avatar.texture = AvatarLoader.get_player_avatar(player_id)
