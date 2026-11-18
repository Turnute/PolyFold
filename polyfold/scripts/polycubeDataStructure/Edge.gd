class_name Edge
extends StaticBody3D

## Reference to the edge's MeshInstance3D.
@onready var _mesh : MeshInstance3D = $MeshInstance3D
## Reference to the edge's CollisionShape3D.
@onready var _col : CollisionShape3D = $CollisionShape3D

## Enumerator of the edge's position inside a face.
enum EdgeEnum {
	TOP,	# TOP (+X)
	BOTTOM,	# BOTTOM (-X)
	LEFT,	# LEFT (-Z)
	RIGHT	# RIGHT (+Z)
}
## Edge directions in the face local space.
const DIRECTIONS = [
	Vector3i.RIGHT,		# TOP (+X)
	Vector3i.LEFT,		# BOTTOM (-X)
	Vector3i.FORWARD,	# LEFT (-Z)
	Vector3i.BACK 		# RIGHT (+Z)
]
## The edge's position inside its face.
var _side : EdgeEnum
## Actual attachment face controlled by this handle.
var _fold_face: Face = null
## Grabbed-side identifier on the attachment face, opposite its actual hinge.
var _fold_grabbed_side: EdgeEnum

## Hides the edge and disables its collision on startup.
func _ready() -> void:
	_mesh.visible = false
	_col.disabled = true

## Creates an action for the assigned attachment, or this edge's parent face.
func select(dir : UnfoldAction.DirEnum) -> UnfoldAction:
	if is_instance_valid(_fold_face):
		return UnfoldAction.createAction(
			_fold_face._id_cube,
			_fold_face._side,
			_fold_grabbed_side,
			dir
		)

	var info = [0,0]
	if get_parent().has_method("getInfo"):
		info = get_parent().getInfo()

	return UnfoldAction.createAction(info[1], info[0], _side, dir)

## Logs edge deselection for debugging.
func unselect() -> void:
	Log.debug("Unselected " + get_parent().name)

## Toggles the edge's visibility and collision.
func switch() -> void:
	_mesh.visible = !_mesh.visible
	_col.disabled = !_col.disabled

## Sets the edge visibility and collision state.
func showEdge(vis : bool) -> void:
	_mesh.visible = vis
	_col.disabled = !vis
