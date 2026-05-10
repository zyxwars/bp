## Ship with path finding
class_name ExplorationShip extends CharacterBody3D

var _max_movement_speed: float = 75
var _rotation_speed: float = 3

@onready var _navigation_agent: NavigationAgent3D = $NavigationAgent3D

@onready var _label_marker: Node3D = $"LabelMarker"
@onready var _panel: Control = %"UnitPanel"

# Destroy ship if it gets stuck
const MAX_ALIVE_TIME_SECONDS = 20
var _alive_time_seconds = 0
var _camera: Camera3D
var _player: PlayerState

var _is_resolution := false

func init(player: PlayerState, source: Node3D, destination: Node3D, count: int, is_resolution: bool):
	_is_resolution = is_resolution
	_player = player

	global_position = source.global_position
	global_rotation = source.global_rotation

	# Resolution ships should not start in the same spot
	if is_resolution:
		global_position += Vector3(randi_range(-100, 100), 0, randi_range(-100, 100))

	%"Avatar".self_modulate = AvatarLoader.get_player_color(_player.id)

	# Hide ship count before resolution
	if not is_resolution:
		%Count.text = str(count) if player == State.get_this_player() else "?"
	else:
		%Count.text = str(count)

	_navigation_agent.set_target_position(destination.global_position)


func _ready():
	_camera = get_viewport().get_camera_3d()
	_navigation_agent.max_speed = _max_movement_speed


func _process(_delta: float) -> void:
	_panel.global_position = _camera.unproject_position(_label_marker.global_position)


func _physics_process(delta):
	if (_alive_time_seconds > MAX_ALIVE_TIME_SECONDS):
		_close()
	_alive_time_seconds += delta


	# https://docs.godotengine.org/en/latest/tutorials/navigation/navigation_introduction_3d.html#setup-for-3d-scene
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(_navigation_agent.get_navigation_map()) == 0:
		print("map is empty")
		return
	if _navigation_agent.is_navigation_finished():
		_close()
		return

	# Movement
	var next_path_position: Vector3 = _navigation_agent.get_next_path_position()

	var dir = global_position.direction_to(next_path_position)
	var new_velocity = dir * _max_movement_speed


	if _navigation_agent.avoidance_enabled:
		_navigation_agent.set_velocity(new_velocity)
		velocity = await _navigation_agent.velocity_computed
	else:
		velocity = new_velocity

	if velocity.length() > 0.01:
		var target_angle = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * _rotation_speed)

	move_and_slide()

func _close():
	if _is_resolution:
		Events.exploration_resolution_ship_arrived.emit(_player.id)
	queue_free()