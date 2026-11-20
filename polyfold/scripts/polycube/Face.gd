class_name Face
extends Node3D

## Identifier of the cube we belong to.
var _id_cube : int

## Enumerator of the face's position inside a cube.
enum FaceEnum { 
	NONE, 	# NONE
	TOP, 	# TOP
	BOTTOM,	# BOTTOM
	LEFT, 	# LEFT (-Z)
	RIGHT, 	# RIGHT (+Z)
	FRONT, 	# FRONT (+X)
	BACK 	# BACK (-X)
}
## Face normals in the cube local space.
const DIRECTIONS = [ 
	Vector3i.ZERO, 		# NONE
	Vector3i.UP, 		# TOP
	Vector3i.DOWN,		# BOTTOM
	Vector3i.FORWARD, 	# LEFT (-Z)
	Vector3i.BACK, 		# RIGHT (+Z)
	Vector3i.RIGHT, 	# FRONT (+X)
	Vector3i.LEFT 		# BACK (-X)
]
## The face's original side inside its cube.
var _side : FaceEnum

## Unique face identifier: id_cube * 10 + side.
var _id_face: int:
	get:
		return _id_cube * 10 + _side

## Returns the cube identifier and side encoded in a face identifier.
static func faceIdToCubeIDWithSide(faceId : int) -> Array[int] :
	var side : int = faceId%10
	var cube : int = (faceId - side)/10
	return [cube, side]

## A reference to the edge scene (prefab).
@export var _edge_scene: PackedScene = preload("res://prefabs/edge.tscn")

## The face's edges, indexed by EdgeEnum.
var _edges : Array[Edge]

## This face's adjacency list. Contains the unique identifiers of
## neighbouring faces, indexed by EdgeEnum (-1 if disconnected).
var _adj_faces : Array[int]

## Recess of each disconnected visual border, in face-local units.
const CUT_INSET: float = 0.015

## Reference to the face's MeshInstance3D.
@onready var _mesh: MeshInstance3D = $StaticBody3D/MeshInstance3D
## The face's own copy of its mesh material.
@onready var _material: StandardMaterial3D = _mesh.get_active_material(0).duplicate()
## The original color of the face.
@onready var _ogColor: Color
## The color used to highlight the selected face.
var _selectionColor: Color = Color(1, 1, 0)

## Dedicated detector used to validate folding collisions.
@onready var _fold_area: Area3D = $FoldDetector
## Collision shape.
@onready var _fold_shape: CollisionShape3D = $FoldDetector/CollisionShape3D
## Label (used for debug)
@onready var _label: Label3D = $Label3D

## Sets the face's material and creates its edges.
func _ready() -> void:
	_mesh.mesh = _mesh.mesh.duplicate()
	_mesh.set_surface_override_material(0, _material)
	_material.albedo_color = _ogColor
	
	createEdges()
	updateConnectionVisuals()

## Creates the face's edges
func createEdges() -> void :
	for i in range(4):
		createEdge(i, Vector3(Edge.DIRECTIONS[i]) * 0.5)
	updateConnectionVisuals()

## Called when a face is selected. Highlights it and reveals its edges.
func select() -> void:
	Log.debug("Face " + str(_id_face) + " sélectionnée !")
	_material.albedo_color = _selectionColor
	showEdges(true)

## Called when a face is unselected. Removes highlighting and hides its edges.
func unselect() -> void:
	_material.albedo_color = _ogColor
	showEdges(false)

## Toggles the face's edge visibility and collision.
func switchEdges() -> void:
	for e in _edges:
		e.switch()

## Sets the visibility and collision state of all edges.
func showEdges(vis: bool) -> void:
	for e in _edges:
		e.showEdge(vis)

## Creates and stores an edge.
func createEdge(edge_side: Edge.EdgeEnum, pos: Vector3) -> void:
	var edge : Edge = _edge_scene.instantiate() as Edge
	edge._side = edge_side
	edge.position = pos
	add_child(edge)
	_edges.append(edge)

## Returns the face side followed by the cube identifier.
func getInfo() -> Array[int] :
	return [_side, _id_cube]

## Returns the edge opposite to the given edge.
func getOppositeEdge(e : Edge) -> Edge :
	match e._side :
		Edge.EdgeEnum.TOP :
			return _edges[1]
		Edge.EdgeEnum.BOTTOM :
			return _edges[0]
		Edge.EdgeEnum.LEFT :
			return _edges[3]
		Edge.EdgeEnum.RIGHT :
			return _edges[2]
		_ :
			Log.error("ERROR! Unidentified Edge!")
			return null

## Rotates the face around an edge by an angle in degrees.
func rotateAroundEdge(edge : Edge, angle : float) -> void:
	var pivot : Vector3 = edge.global_position
	var local_axis: Vector3

	match edge._side:
		Edge.EdgeEnum.TOP, Edge.EdgeEnum.BOTTOM:
			local_axis = Vector3.FORWARD
		Edge.EdgeEnum.LEFT, Edge.EdgeEnum.RIGHT:
			local_axis = Vector3.RIGHT
		_:
			return

	var axis: Vector3 = (global_transform.basis * local_axis).normalized()
	var rotation := Basis(axis, deg_to_rad(angle))
	var t: Transform3D = global_transform
	t.origin = pivot + rotation * (t.origin - pivot)
	t.basis = rotation * t.basis
	global_transform = t

## Returns the neighbouring face identifier, or -1 if disconnected.
func getNeighbouringFace(edge : Edge.EdgeEnum) -> int:
	return _adj_faces[edge]

## Disconnects all neighbouring faces except the one across the given edge.
## Returns the identifiers of the disconnected faces.
func disconnectFromEdge(edge : Edge) -> Array[int]:
	var disconnected_faces : Array[int]
	for i in range(4):
		if i == edge._side:
			continue
		if _adj_faces[i] != -1:
			disconnected_faces.append(getNeighbouringFace(i))
		
		_adj_faces[i] = -1
	
	updateConnectionVisuals()
	return disconnected_faces

## Removes the neighbour from this face's adjacency list.
## Returns the corresponding EdgeEnum index, or -1 if not found.
func disconnectFace(faceId: int) -> int:
	for i in range(_adj_faces.size()):
		if _adj_faces[i] == faceId:
			_adj_faces[i] = -1
			updateConnectionVisuals()
			return i
	return -1

func connectFace(faceId: int, dir : Edge.EdgeEnum) -> void:
	_adj_faces[dir] = faceId
	updateConnectionVisuals()
	pass

## Insets disconnected mesh borders.
func updateConnectionVisuals() -> void :
	if _adj_faces.size() != 4 or not is_instance_valid(_mesh):
		return

	var top: float = CUT_INSET if _adj_faces[Edge.EdgeEnum.TOP] == -1 else 0.0
	var bottom: float = CUT_INSET if _adj_faces[Edge.EdgeEnum.BOTTOM] == -1 else 0.0
	var left: float = CUT_INSET if _adj_faces[Edge.EdgeEnum.LEFT] == -1 else 0.0
	var right: float = CUT_INSET if _adj_faces[Edge.EdgeEnum.RIGHT] == -1 else 0.0
	
	var box: BoxMesh = _mesh.mesh as BoxMesh

	box.size = Vector3(
		1.0 - top - bottom,
		box.size.y,
		1.0 - left - right
	)

	_mesh.position = Vector3(
		(bottom - top) * 0.5,
		_mesh.position.y,
		(left - right) * 0.5
	)

## Resizes and offsets this face's detector.
## Keeps borders shared with stationary neighbours at full size.
## Insets borders facing moving faces or no faces by 0.1 units.
func updateFoldDetector(moving_faces: Array[int]) -> void:
	var inset: Array[float] = []

	for neighbour_id in _adj_faces:
		var internal: bool = (
			neighbour_id != -1
			and not moving_faces.has(neighbour_id)
		)
		inset.append(0.0 if internal else 0.1)

	var box: BoxShape3D = _fold_shape.shape.duplicate()
	box.margin = 0.0
	box.size = Vector3(
		1.0 - inset[0] - inset[1],
		box.size.y,
		1.0 - inset[2] - inset[3]
	)
	_fold_shape.shape = box

	_fold_shape.position = Vector3(
		(inset[1] - inset[0]) * 0.5,
		0.0,
		(inset[2] - inset[3]) * 0.5
	)

func log() -> void :
	Log.trace(
		"Face " + str(_id_face) 
		+ " of side " + str(_side)
		+ " with Edges: "
		)
	for e in _edges:
		e.log()
