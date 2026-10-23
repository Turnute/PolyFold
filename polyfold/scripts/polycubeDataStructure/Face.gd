extends Node3D

class_name Face

# Identifiant du cube auquel on appartient
var id_cube : int

# Énumérateur de sa position au sein d'un cube
enum FaceEnum { NONE, TOP, BOTTOM, LEFT, RIGHT, FRONT, BACK }
var side : FaceEnum

# Identifiant unique de la face
var id_face: int:
	get:
		return id_cube * 10 + side

# Arêtes de la face
var edges : Array[Edge]
@export var edge_scene: PackedScene

# Identifiants des faces adjacentes
var adj_faces : Array[int]

# Gestion de la couleur de la face
@onready var mesh: MeshInstance3D = $StaticBody3D/MeshInstance3D
@onready var material: StandardMaterial3D = mesh.get_active_material(0).duplicate()
@onready var ogColor: Color = material.albedo_color
var selectionColor: Color = Color(1, 1, 0)

func _ready() -> void:
	mesh.set_surface_override_material(0, material)
	
	createEdge(Edge.EdgeEnum.TOP, Vector3(0.5,0,0))
	createEdge(Edge.EdgeEnum.BOTTOM, Vector3(-0.5,0,0))
	createEdge(Edge.EdgeEnum.LEFT, Vector3(0,0,-0.5))
	createEdge(Edge.EdgeEnum.RIGHT, Vector3(0,0,0.5))

func select() -> void:
	print("Face sélectionnée !")
	material.albedo_color = selectionColor
	switchEdges()

func unselect() -> void:
	material.albedo_color = ogColor
	switchEdges()

func switchEdges() -> void:
	for e in edges:
		e.switch()

func createEdge(edge_side: Edge.EdgeEnum, pos: Vector3) -> void:
	var edge : Edge = edge_scene.instantiate() as Edge
	edge.side = edge_side
	edge.position = pos
	add_child(edge)
	edges.append(edge)

func getInfo() -> Array[int] :
	return [side, id_cube]

func getOppositeEdge(e : Edge) -> Edge :
	match e.side :
		Edge.EdgeEnum.TOP :
			return edges[1]
		Edge.EdgeEnum.BOTTOM :
			return edges[0]
		Edge.EdgeEnum.LEFT :
			return edges[3]
		Edge.EdgeEnum.RIGHT :
			return edges[2]
		_ :
			print("ERROR! Unidentified Edge!")
			return null

func rotateAroundEdge(edge : Edge, angle : float) -> void:
	var pivot : Vector3 = edge.global_position
	var local_axis: Vector3

	match edge.side:
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
