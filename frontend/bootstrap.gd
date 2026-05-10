## Global config loader
## Config variables are explained in config.cfg
extends Node

# https://docs.godotengine.org/en/stable/classes/class_configfile.html
var config = ConfigFile.new()

var backend_url: String

var forms_enabled: bool
var pregame_form: String
var postgame_form: String

func _ready():
	var err = config.load("res://config.cfg")

	if err != OK:
		var err_str = error_string(err)
		push_error("Config load failed: %s" % err_str)
		return

	backend_url = config.get_value("network", "backend_url", "http://localhost:3000")
	prints("backend_url", backend_url)

	forms_enabled = config.get_value("forms", "forms_enabled", false)
	prints("forms_enabled", forms_enabled)

	pregame_form = config.get_value("forms", "pregame_form", "")
	prints("pregame_form", pregame_form)

	postgame_form = config.get_value("forms", "postgame_form", "")
	prints("postgame_form", postgame_form)
