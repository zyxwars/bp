extends CollisionObject3D

# Disabled object selector as there is nothing to select in the current game version
# Could still be useful in the future
@warning_ignore("unused_signal")
signal pressed()

# var _select_material := preload("selection_material.tres")
# var _selected = false


# func _ready() -> void:
# 	mouse_entered.connect(_on_mouse_entered)
# 	mouse_exited.connect(_on_mouse_exited)


# func _on_mouse_entered():
# 	_selected = true
# 	_update_selected(self )


# func _on_mouse_exited():
# 	_selected = false
# 	_update_selected(self )


# func _input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
# 	if event.is_action_pressed("click"):
# 		pressed.emit()


# func _update_selected(node: Node):
# 	if node is MeshInstance3D:
# 		node.material_overlay = _select_material if _selected else null

# 	for child in node.get_children():
# 		_update_selected(child)
