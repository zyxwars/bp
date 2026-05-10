## Loads all llm agents
class_name LlmManager extends Node

var agent_scene := preload("./agent.tscn")
var agents: Array[Agent] = []

func _ready() -> void:
	for player in State.players:
		# Skip human player
		if player.agent_state == null:
			continue

		var agent: Agent = agent_scene.instantiate()
		agent.init(player)
		add_child(agent)
		agents.push_back(agent)