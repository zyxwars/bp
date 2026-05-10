## World manager
extends Node

var islands: Array[Island] = []


func _ready() -> void:
	var found_islands = get_tree().get_nodes_in_group("islands")
	prints("[World]: found islands", found_islands)

	# Delete islands with no players
	for i in found_islands.size():
		if i < State.players.size():
			islands.push_back(found_islands[i])
			islands[i].init(i)
		else:
			found_islands[i].queue_free()
