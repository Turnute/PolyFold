class_name Polycube
extends Node3D

## Stores all cubes in the polycube.
var _cubes : Array[Cube]

## Adjacency matrix for connections between cubes.
var _adj : Array[Array] = []
# Example:
# 			0	1	2	...
# 	0	[	0	0	BOT	0	]
# 	1 	[	0	0	0	0	]
# 	2 	[	TOP	0	0	0	]
# ...	[	0	0	0	0	]
# Cube 0 is connected to cube 2 through its BOTTOM face.
# Cube 2 is connected to cube 0 through its TOP face.
# A cube identifier matches its index in the matrix.

## Initializes the polycube from an array of cubes.
func _init(cubes: Array[Cube]):
	_cubes = cubes
	for cube in cubes : add_child(cube)
	initAdj()

## Initializes all entries of the cube adjacency matrix to zero.
func initAdj() -> void:
	_adj.clear()

	for i in _cubes.size():
		var line : Array[Face.FaceEnum] = []
		line.resize(_cubes.size())
		line.fill(0) # 0 = no connection.
		_adj.append(line)

## Sets the connection between two cubes and their touching sides.
func addAdj(id1 : int, id2 : int, face1 : Face.FaceEnum, face2 : Face.FaceEnum) -> void:
	_adj[id1][id2] = face1
	_adj[id2][id1] = face2

## Creates the cube faces that are not shared with another cube.
func initCube(id : int) -> void:
	var cube = _cubes[id]
	var occupied_faces = []
	
	for other_id in range(_cubes.size()):
		if _adj[id][other_id] != Face.FaceEnum.NONE:
			occupied_faces.append(_adj[id][other_id])

	for face_side in range(Face.FaceEnum.TOP, Face.FaceEnum.BACK+1):
		if face_side not in occupied_faces:
			cube.createFace(face_side)

## Initializes exposed face connections from the original cube grid.
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
				# Edge direction in the face local space.
				var local_dir: Vector3 = Edge.DIRECTIONS[i]
				# Rotate the direction into the cube grid space.
				var rotated_dir: Vector3 = face.transform.basis * local_dir
				# Round to an integer grid direction.
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


## Checks whether the polycube can be unfolded.
func canUnfold() -> bool:
	return true;

## Returns a face from its cube identifier and original side.
func getFace(id_cube : int, side : Face.FaceEnum) -> Face :
	return _cubes[id_cube].getFace(side)

## Returns the face matching a valid face identifier.
func getFaceFromFaceId(face_id : int) -> Face :
	var info : Array[int] = Face.faceIdToCubeIDWithSide(face_id)
	return getFace(info[0], info[1])

## Returns the average initial cube grid position in polycube local space.
func getAveragePos() -> Vector3 : 
	if _cubes.is_empty(): return Vector3i.ZERO
	var result = Vector3.ZERO
	for cube in _cubes :
		var c_pos : Vector3 = cube._pos
		result += c_pos
		
	return result / _cubes.size()

## Removes selection from all faces.
func unselectAllFaces() -> void :
	for cube in _cubes:
		for face in cube._faces:
			face.unselect()

## Selects the face matching a valid face identifier.
func selectFace(face_id : int) -> void :
	var f : Face = getFaceFromFaceId(face_id)
	f.select()

## Removes selection from the face matching a valid face identifier.
func unselectFace(face_id : int) -> void :
	var f : Face = getFaceFromFaceId(face_id)
	f.unselect()
