## Utily for loading player visual data
class_name AvatarLoader extends Node


static var _names = ["Red", "Green", "Blue", "Yellow"]


static var _colors = ["#eb4034", "#34eb68", "#3496eb", "#ebd034"]


static var _avatars = [
	preload("res://assets/avatars/red.svg"),
	preload("res://assets/avatars/green.svg"),
	preload("res://assets/avatars/blue.svg"),
	preload("res://assets/avatars/yellow.svg")
	]


static func get_player_name(player_id: int):
	return _names[player_id]


static func get_player_color(player_id: int) -> Color:
	return Color(_colors[player_id])


static func get_player_color_dark(player_id: int) -> Color:
	return Color(_colors[player_id]).darkened(0.4)


static func get_player_avatar(player_id: int):
	return _avatars[player_id]