## Global game state
extends Node

enum AttackSide {
	Attack,
	Defense,
	Neutral,
}

# NOTE: KEEP IN SYNC WITH BACKEND PROMPTS
const SHIP_COUNT = 5;
const STARTING_GOLD = 3;
const WIN_GOLD = 20;
const MAX_MEMORY_SIZE = 30


var players: Array[PlayerState]
var game_round: int
var winner_id: int

var session_id: String
var user_id: String

func _ready() -> void:
	load_state()

func load_state() -> void:
	# Generate random player id for survey and log matching
	# user_id persists across sessions while session_id is freshly generated each time
	session_id = Time.get_datetime_string_from_system(true)
	user_id = _load_or_create_user_id()

	players.clear()
	for i in range(4):
		var player = PlayerState.new(i, "agent%d" % i)
		players.push_back(player)

	get_this_player().agent_state = null

	game_round = 1
	winner_id = -1

	prints(user_id, session_id)

# https://docs.godotengine.org/en/stable/classes/class_configfile.html
func _load_or_create_user_id() -> String:
	var store = ConfigFile.new()
	var path = "user://user_store.cfg"
	if store.load(path) == OK:
		var saved_id = store.get_value("user", "id", "")
		if saved_id != "":
			return saved_id
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var new_id = str(rng.randi())
	store.set_value("user", "id", new_id)
	store.save(path)
	return new_id


func get_this_player() -> PlayerState:
	return players[0]
