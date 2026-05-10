## Clickable avatar of a player
class_name PlayerPickerItem extends Control

## Fired when player avatar is pressed
signal pressed(index: int)

var _SELECTED_MARGIN_SIZE = 4
var _DEFAULT_MARGIN_SIZE = 0

@onready var _texture_rect: TextureRect = %TextureRect
@onready var _margin_container: MarginContainer = %MarginContainer


var player_id: int
var _index: int

func select():
	_set_margin(_SELECTED_MARGIN_SIZE)

func deselect():
	_set_margin(_DEFAULT_MARGIN_SIZE)

func _set_margin(margin_size: int):
	_margin_container.add_theme_constant_override("margin_left", margin_size)
	_margin_container.add_theme_constant_override("margin_right", margin_size)
	_margin_container.add_theme_constant_override("margin_top", margin_size)
	_margin_container.add_theme_constant_override("margin_bottom", margin_size)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit(_index)

func init(index: int, p_player_id: int) -> void:
	_index = index
	player_id = p_player_id
	_texture_rect.texture = AvatarLoader.get_player_avatar(player_id)
