class_name HelpDialog extends Control

@onready var _dialog: Dialog = %Dialog
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton

var _pages: Array[Node]
var _current_page := 0
var _opened_from_game_start := false

func _ready() -> void:
	# Pages are sorted by their order in the scene tree
	_pages = get_tree().get_nodes_in_group("page")
	Events.game_started.connect(_open_from_game_start)
	Events.help_opened.connect(_open)
	_dialog.closed.connect(_close)
	_back_button.pressed.connect(_on_back_pressed)
	_next_button.pressed.connect(_on_next_pressed)
	_show_page(0)
	hide()

func _open_from_game_start():
	_opened_from_game_start = true
	_open()

## Show help at the start of the game or when player opens it explictly
func _open():
	_show_page(0)
	show()

func _show_page(page: int) -> void:
	_current_page = page
	for i in _pages.size():
		_pages[i].visible = i == page
	_back_button.visible = page > 0
	_next_button.text = "Done" if page == _pages.size() - 1 else "Next"

func _on_back_pressed() -> void:
	_show_page(_current_page - 1)

func _on_next_pressed() -> void:
	if _current_page == _pages.size() - 1:
		_close()
	else:
		_show_page(_current_page + 1)

func _close() -> void:
	if _opened_from_game_start:
		_opened_from_game_start = false
		Events.help_closed.emit()
	hide()
