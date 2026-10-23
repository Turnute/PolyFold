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

func initFaceAdj() -> void :
	var cubes_by_pos: Dictionary = {}
	for cube in _cubes:
		cubes_by_pos[cube._pos] = cube

	for cube in _cubes:
		for face in cube._faces:
			face._adj_faces.resize(4)
			face._adj_faces.fill(-1)

			var n: Vector3i = Face.DIRECTIONS[face._side]

			for i in range(4):
				# edge direction (relative in its face)
				var local_dir: Vector3 = Edge.DIRECTIONS[i]
				# rotates it (relative to the face in the scene)
				var rotated_dir: Vector3 = face.transform.basis * local_dir
				# resulting direction
				var d: Vector3i = Vector3i(rotated_dir.round())
				
				var side_cube: Cube = cubes_by_pos.get(cube._pos + d)
				var diag_cube: Cube = cubes_by_pos.get(cube._pos + d + n)
				var neighbour: Face = null

				if side_cube == null:
					neighbour = cube.getFace(Face.DIRECTIONS.find(d))

				elif diag_cube == null:
					neighbour = side_cube.getFace(face._side)

				else:
					neighbour = diag_cube.getFace(Face.DIRECTIONS.find(-d))

				if neighbour != null:
					face._adj_faces[i] = neighbour._id_face


## Checks if the polycube can be unfolded
func canUnfold() -> bool:
	return true;

func getFace(id_cube : int, side : Face.FaceEnum) -> Face :
	return _cubes[id_cube].getFace(side)

func getFaceFromFaceId(face_id : int) -> Face :
	var info : Array[int] = Face.faceIdToCubeIDWithSide(face_id)
	return getFace(info[0], info[1])

func getAveragePos() -> Vector3 : 
	if _cubes.is_empty(): return Vector3i.ZERO
	var result = Vector3.ZERO
	for cube in _cubes :
		var c_pos : Vector3 = cube._pos
		result += c_pos
		
	return result / _cubes.size()
