extends Node

class_name Cube

var id : int # Identifiant du cube
@export var face_scene : PackedScene
var faces : Array[Face] # Tableau des faces
var pos : Vector3 # Position au sein du polycube

func createFace(face_side: Face.FaceEnum) -> void:
	var face_pos : Vector3 = pos
	var face_rot : Vector3 = Vector3(0,0,0)
	
	match face_side :
		Face.FaceEnum.TOP :
			face_pos += Vector3(0,1,0)
		Face.FaceEnum.BOTTOM :
			face_rot = Vector3(180,0,0)
		Face.FaceEnum.LEFT :
			face_pos =+ Vector3(0,0.5,-0.5)
			face_rot = Vector3(-90,0,0)
		Face.FaceEnum.RIGHT :
			face_pos =+ Vector3(0,0.5,0.5)
			face_rot = Vector3(90,0,0)
		Face.FaceEnum.FRONT :
			face_pos =+ Vector3(0.5,0.5,0)
			face_rot = Vector3(0,0,-90)
		Face.FaceEnum.BACK :
			face_pos =+ Vector3(-0.5,0.5,0)
			face_rot = Vector3(0,0,90)
	
	var face : Face = face_scene.instantiate() as Face
	face.side = face_side
	face.position = face_pos
	face.rotation = face_rot
	add_child(face)
	faces.append(face)
