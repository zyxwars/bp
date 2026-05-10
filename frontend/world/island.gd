# Islands show visuals for each player
class_name Island extends Node3D

@onready var _panel_position: Vector3 = $PanelMarker.global_position
@onready var _panel: PlayerPanel = $PlayerPanel
@onready var _port_marker: Node3D = $PortMarker
@onready var _exploration_destination_marker: Node3D = $/root/Main/World/ExplorationDestinationMarker
@onready var _exploration_source_marker: Node3D = $/root/Main/World/ExplorationSourceMarker
@onready var _fire_particles: Node3D = $"FireParticles"

const exploration_ships_scene := preload("res://world/exploration_ship.tscn")


var _camera: Camera3D

var _player: PlayerState

func init(player_id: int):
	if not is_node_ready():
		await ready

	_player = State.players[player_id]
	_panel.init(_player.id)


func _ready():
	Events.exploration_decided.connect(_on_exploration_decided)
	Events.attack_resolved.connect(_on_attack_resolved)
	Events.exploration_resolved.connect(_on_exploration_resolved)

	_camera = get_viewport().get_camera_3d()
	$ObjectSelector.pressed.connect(_on_island_pressed)

	_fire_particles.hide()


func _process(_delta: float) -> void:
	_panel.global_position = _camera.unproject_position(_panel_position)


func _on_exploration_decided():
	# Send exploration ships
	var ship: ExplorationShip = exploration_ships_scene.instantiate()
	add_child(ship)
	ship.init(_player, _port_marker, _exploration_destination_marker, _player.exploration_ship_count, false)


func _on_attack_resolved(attacker_id: int, defender_id: int, attackers_won: bool, _gold_captured: int, _attacker_ships: int, _defender_ships: int, _attacker_ally_id: Array[int], _defender_ally_ids: Array[int], _neutral_player_ids: Array[int], _attacker_invited_player_ids: Array[int], _defender_invited_player_ids: Array[int]):
	var loser_id = attacker_id
	if attackers_won:
		loser_id = defender_id

	if _player.id != loser_id:
		return

	# Spawn fire effect on attack loss
	_fire_particles.show()

func _on_exploration_resolved():
	var ship: ExplorationShip = exploration_ships_scene.instantiate()
	add_child(ship)
	ship.init(_player, _exploration_source_marker, _port_marker, _player.exploration_ship_count, true)

	# Destroy fire effect
	if _fire_particles.visible:
		await get_tree().create_timer(5.0).timeout
		_fire_particles.hide()

	
func _on_island_pressed():
	pass
