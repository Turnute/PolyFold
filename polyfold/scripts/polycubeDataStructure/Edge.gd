class_name Edge
extends StaticBody3D

## Reference to the edge's MeshInstance
@onready var _mesh : MeshInstance3D = $MeshInstance3D
## Reference to the edge's CollisionShape
@onready var _col : CollisionShape3D = $CollisionShape3D

## Enumerator of the edge's position inside a face
enum EdgeEnum { TOP, BOTTOM, LEFT, RIGHT }
## Enumerator of the edge's position inside a face
var _side : EdgeEnum

## on _ready(), an edge is invisible and non interactible
func _ready() -> void:
	_mesh.visible = false
	_col.disabled = true

## Selecting an edge
func select() -> void:
	print("Selected " + get_parent().name)

## Unselecting an edge
func unselect() -> void:
	print("Unelected " + get_parent().name)

## Switch the edge's visibility
func switch() -> void:
	_mesh.visible = !_mesh.visible
	_col.disabled = !_col.disabled
