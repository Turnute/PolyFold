class_name Cube
extends Node3D

## Cube identifier
var _id : int

## Reference to the face scene (prefab)
@export var _face_scene : PackedScene

## Array of faces
var _faces : Array[Face]

## The cube's position inside the polycube
var _pos : Vector3

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
	face.id_cube = _id
	face.side = face_side
	face.position = face_pos
	face.rotation_degrees = face_rot
	add_child(face)
	_faces.append(face)
