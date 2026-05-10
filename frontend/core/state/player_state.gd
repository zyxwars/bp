class_name PlayerState

var id: int
var gold: int = State.STARTING_GOLD

# Round state
var exploration_ship_count: int = 0
var attack_gold_change: int = 0

# Agent state shall be null for human player
# NOTE: KEEP IN SYNC WITH BACKEND PROMPTS
var agent_state: Variant # Dictionary | null


func _init(
	p_id: int,
	model: String,
) -> void:
	id = p_id
	agent_state = {
		"model": model,
		"history": [],
		"strategy": "",
		"playerAnalysis": {},
	}

func get_ships_at_home():
	return State.SHIP_COUNT - exploration_ship_count