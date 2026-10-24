class_name Face
extends Node3D

## Identifier of the cube we belong to
var _id_cube : int

## Enumerator of the face's position inside a cube
enum FaceEnum { 
	NONE, 	# NONE
	TOP, 	# TOP
	BOTTOM,	# BOTTOM
	LEFT, 	# LEFT (-Z)
	RIGHT, 	# RIGHT (+Z)
	FRONT, 	# FRONT (+X)
	BACK 	# BACK (-X)
}
const DIRECTIONS = [ 
	Vector3i.ZERO, 		# NONE
	Vector3i.UP, 		# TOP
	Vector3i.DOWN,		# BOTTOM
	Vector3i.FORWARD, 	# LEFT (-Z)
	Vector3i.BACK, 		# RIGHT (+Z)
	Vector3i.RIGHT, 	# FRONT (+X)
	Vector3i.LEFT 		# BACK (-X)
]
## Enumerator of the face's position inside a cube
var _side : FaceEnum

## A face's unique identifier. Equals to id_cube*10 + side
var _id_face: int:
	get:
		return _id_cube * 10 + _side

static func faceIdToCubeIDWithSide(faceId : int) -> Array[int] :
	var side : int = faceId%10
	var cube : int = (faceId - side)/10
	return [cube, side]

## A reference to the Edge scene (prefab)
@export var _edge_scene: PackedScene = preload("res://prefabs/edge.tscn")

## The face's edges
var _edges : Array[Edge]

## This face's adjancy list. Containts the unique identifiers of all
## neighbouring faces (or -1 if disconnected).
var _adj_faces : Array[int]

## Reference to the face's MeshInstance3D
@onready var _mesh: MeshInstance3D = $StaticBody3D/MeshInstance3D
## The face's mesh material
@onready var _material: StandardMaterial3D = _mesh.get_active_material(0).duplicate()
## The original color of a face
@onready var _ogColor: Color = _material.albedo_color
## The color a face is supposed to be when selected (highlighting feature)
var _selectionColor: Color = Color(1, 1, 0)

## _ready() method: set the face's material and creates its edges
func _ready() -> void:
	_mesh.set_surface_override_material(0, _material)
	for i in range(4):
		createEdge(i, Vector3(Edge.DIRECTIONS[i]) * 0.5)

## Called when a face is selected. Highlights it and reveals its edges.
func select() -> void:
	print("Face sélectionnée !")
	_material.albedo_color = _selectionColor
	showEdges(true)

## Called when a face is unselected. Removes highlighting and hides its edges.
func unselect() -> void:
	_material.albedo_color = _ogColor
	showEdges(false)

## Switches the face's edges visibility
func switchEdges() -> void:
	for e in _edges:
		e.switch()

func showEdges(vis: bool) -> void:
	for e in _edges:
		e.showEdge(vis)

## Creates and stores an edge
func createEdge(edge_side: Edge.EdgeEnum, pos: Vector3) -> void:
	var edge : Edge = _edge_scene.instantiate() as Edge
	edge._side = edge_side
	edge.position = pos
	add_child(edge)
	_edges.append(edge)

func getInfo() -> Array[int] :
	return [_side, _id_cube]

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
			print("ERROR! Unidentified Edge!")
			return null

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

func getNeighbouringFace(edge : Edge.EdgeEnum) -> int:
	return _adj_faces[edge]

## Disconnects all faces in this face's adjency list except the one specified
## by an edge.
## Returns an array containing the id of all disconnected faces.
func disconnectFromEdge(edge : Edge) -> Array[int]:
	var disconnected_faces : Array[int]
	for i in range(4):
		if i == edge._side:
			pass
		if _adj_faces[i] != -1:
			disconnected_faces.append(getNeighbouringFace(i))
		
		_adj_faces[i] = -1
		
	return disconnected_faces

func disconnectFace(faceId: int) -> bool:
	for i in range(_adj_faces.size()):
		if _adj_faces[i] == faceId:
			_adj_faces[i] = -1
			return true
	return false
