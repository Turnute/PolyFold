class_name Cube
extends Node3D

## Cube identifier
var _id : int

## Reference to the face scene (prefab)
@export var _face_scene : PackedScene = preload("res://prefabs/face.tscn")

## Array of faces
var _faces : Array[Face]

## The cube's position inside the polycube
var _pos : Vector3i

## Creates and stores a cube's face from its FaceEnum identifier
func createFace(face_side: Face.FaceEnum) -> void:
	var face_pos : Vector3 = _pos
	var face_rot : Vector3 = Vector3(0,0,0)
	
	match face_side :
		Face.FaceEnum.TOP :
			face_pos += Vector3(0,1,0)
		Face.FaceEnum.BOTTOM :
			face_rot = Vector3(180,0,0)
		Face.FaceEnum.LEFT :
			face_pos += Vector3(0,0.5,-0.5)
			face_rot = Vector3(-90,0,0)
		Face.FaceEnum.RIGHT :
			face_pos += Vector3(0,0.5,0.5)
			face_rot = Vector3(90,0,0)
		Face.FaceEnum.FRONT :
			face_pos += Vector3(0.5,0.5,0)
			face_rot = Vector3(0,0,-90)
		Face.FaceEnum.BACK :
			face_pos += Vector3(-0.5,0.5,0)
			face_rot = Vector3(0,0,90)
	
	var face : Face = _face_scene.instantiate() as Face
	face._id_cube = _id
	face._side = face_side
	face.position = face_pos
	face.rotation_degrees = face_rot
	add_child(face)
	_faces.append(face)

## Returns the face corresponding to the searched side
func getFace(face_side: Face.FaceEnum) -> Face:
	for face in _faces:
		if face._side == face_side:
			return face
	return null
