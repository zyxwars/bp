## List of clickable player avatars
class_name PlayerPicker extends Node

signal selection_changed()

@onready var _player_picker_item_scene := preload("./player_picker_item.tscn")

var can_select_multiple := true
var selected_player_ids: Array[int] = []

var _items: Array[PlayerPickerItem] = []

func reset(player_ids: Array[int]):
	# Clear current items
	selected_player_ids = []
	for item in _items:
		item.hide()
		item.queue_free()
	_items.clear()

	# Spawn new items
	for player_id in player_ids:
		var item: PlayerPickerItem = _player_picker_item_scene.instantiate()
		add_child(item)
		item.init(_items.size(), player_id)
		_items.push_back(item)
		item.pressed.connect(_on_item_pressed)

func _on_item_pressed(index: int):
	var player_id := _items[index].player_id

	if not can_select_multiple:
		for item in _items:
			item.deselect()
		selected_player_ids = [player_id]
		_items[index].select()
	else:
		if selected_player_ids.has(player_id):
			selected_player_ids.erase(player_id)
			_items[index].deselect()
		else:
			selected_player_ids.push_back(player_id)
			_items[index].select()

	selection_changed.emit()
