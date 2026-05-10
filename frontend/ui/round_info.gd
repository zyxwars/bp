## Show round number and current phase
extends PanelContainer

@onready var _round: Label = %Round
@onready var _phase: Label = %Phase

func _ready() -> void:
	Events.round_started.connect(_on_round_started)
	Events.deciding_exploration.connect(func(): _on_phase_changed("Exploration"))
	Events.deciding_attack.connect(func(_a): _on_phase_changed("Attack"))
	Events.deciding_defense.connect(func(_a, _b): _on_phase_changed("Defense"))
	Events.deciding_attack_sides.connect(func(_a, _b, _c, _d): _on_phase_changed("Attack Sides"))
	Events.starting_attack_resolution.connect(func(): _on_phase_changed("Attack Sides"))
	Events.starting_exploration_resolution.connect(func(): _on_phase_changed("Exploration Resolution"))

func _on_round_started():
	_round.text = "Round: %d" % State.game_round

func _on_phase_changed(phase_name: String):
	_phase.text = "Phase: %s" % phase_name