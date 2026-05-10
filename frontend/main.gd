extends Node

var end_game_scene := preload("res://end_game.tscn")

func _ready() -> void:
	Events.player_won.connect(_on_player_won)

	
func _on_player_won(_player_id):
	# Change to end game scene
	get_tree().change_scene_to_packed(end_game_scene)