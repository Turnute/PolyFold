class_name Edge
extends StaticBody3D

## Reference to the edge's MeshInstance
@onready var _mesh : MeshInstance3D = $MeshInstance3D
## Reference to the edge's CollisionShape
@onready var _col : CollisionShape3D = $CollisionShape3D

## Enumerator of the edge's position inside a face
enum EdgeEnum {
	TOP,	# TOP (+X)
	BOTTOM,	# BOTTOM (-X)
	LEFT,	# LEFT (-Z)
	RIGHT	# RIGHT (+Z)
}
## The edge direction (local to face)
const DIRECTIONS = [
	Vector3i.RIGHT,		# TOP (+X)
	Vector3i.LEFT,		# BOTTOM (-X)
	Vector3i.FORWARD,	# LEFT (-Z)
	Vector3i.BACK 		# RIGHT (+Z)
]
## Enumerator of the edge's position inside a face
var _side : EdgeEnum

## on _ready(), an edge is invisible and non interactible
func _ready() -> void:
	_mesh.visible = false
	_col.disabled = true

# Sélection d'un edge
func select(dir : UnfoldAction.DirEnum) -> UnfoldAction:
	var info = [0,0]
	if get_parent().has_method("getInfo"):
		info = get_parent().getInfo()

	return UnfoldAction.createAction(info[1], info[0], _side, dir)

## Unselecting an edge
func unselect() -> void:
	print("Unelected " + get_parent().name)

## Switch the edge's visibility
func switch() -> void:
	_mesh.visible = !_mesh.visible
	_col.disabled = !_col.disabled
