class_name Polycube
extends Node3D

## Stores all cubes in the polycube
var _cubes : Array[Cube]

## Adjacency matrix for connections in the cube
var _adj : Array[Array] = [] # Matrice d'adjacence du polycube
# EXEMPLE :
# 			0	1	2	...
# 	0	[	0	0	BOT	0	]
# 	1 	[	0	0	0	0	]
# 	2 	[	TOP	0	0	0	]
# ...	[	0	0	0	0	]
# Le cube n°0 est lié au cube n°2 par sa face "TOP". 
# Le cube n°2 est lié au cube n°0 par sa face "BOTTOM".
# L'ID d'un cube correspond donc à sa position dans la matrice.

## Constructor with an array of cubes as a parameter
func _init(cubes: Array[Cube]):
	_cubes = cubes
	for cube in cubes : add_child(cube)
	initAdj()

## Inits adjacency matrix at 0 for all cubes in the polycube
func initAdj() -> void:
	_adj.clear()

	for i in _cubes.size():
		var line : Array[Face.FaceEnum] = []
		line.resize(_cubes.size())
		line.fill(0) # 0 = aucune connexion
		_adj.append(line)

## Sets adjacency for cube of id1 with cube of id2 
func addAdj(id1 : int, id2 : int, face1 : Face.FaceEnum, face2 : Face.FaceEnum) -> void:
	_adj[id1][id2] = face1
	_adj[id2][id1] = face2

## Creates faces of a cube if the face is not overlapping with another face
func initCube(id : int) -> void:
	var cube = _cubes[id]
	var occupied_faces = []
	
	for other_id in range(_cubes.size()):
		if _adj[id][other_id] != Face.FaceEnum.NONE:
			occupied_faces.append(_adj[id][other_id])

	for face_side in range(Face.FaceEnum.TOP, Face.FaceEnum.BACK+1):
		if face_side not in occupied_faces:
			cube.createFace(face_side)
	
## Checks if the polycube can be unfolded
func canUnfold() -> bool:
	return true;

func getAveragePos() -> Vector3i : 
	if _cubes.is_empty(): return Vector3i.ZERO
	var result = Vector3i.ZERO
	for cube in _cubes : 
		result += cube
	return result / _cubes.size()
		
	
