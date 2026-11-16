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

## Stores which face is currently being selected
var _selected_face_id: int = -1

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
	_selected_face_id = -1
	for cube in _cubes:
		for face in cube._faces:
			face.unselect()

## Selects the face matching a valid face identifier.
func selectFace(face_id: int) -> void:
	var face: Face = getFaceFromFaceId(face_id)

	_selected_face_id = face_id
	face.select()
	refreshSelectedFaceEdges()

## Removes selection from the face matching a valid face identifier.
func unselectFace(face_id : int) -> void :
	unselectAllFaces()

## Checks whether a face can be unfolded along a certain edge
func canFoldFace(face_id : int, edge_side : Edge.EdgeEnum) -> bool:
	return not getFoldGroup(face_id, edge_side).is_empty()

## TODO doc
func refreshSelectedFaceEdges() -> void:
	if _selected_face_id == -1:
		return

	for cube in _cubes:
		for face in cube._faces:
			face.unselect()

	var group: Array[int] = getPlanarGroup(_selected_face_id)

	for face_id in group:
		var face: Face = getFaceFromFaceId(face_id)
		face.select()

		for edge in face._edges:
			edge.showEdge(canFoldFace(face_id, edge._side))

## Checks whether or not two faces are coplanar
func areCoplanar(a : Face, b : Face) -> bool :
	var normal_a : Vector3 = a.global_transform.basis.y.normalized()
	var normal_b : Vector3 = b.global_transform.basis.y.normalized()
	
	var parallel: bool = absf(normal_a.dot(normal_b)) >= 0.9999
	
	var distance_to_plane: float = absf(
		normal_a.dot(b.global_position - a.global_position)
	)

	return parallel and distance_to_plane <= 0.0001

## Returns the coplanar group to a designated face
func getPlanarGroup(face_id : int) -> Array[int] :
	var ref : Face = getFaceFromFaceId(face_id)
	var group : Array[int] = [face_id]
	var visited : Dictionary = {}
	var next_index : int = 0
	
	visited[face_id] = true
	
	while next_index < group.size() :
		var current : Face = getFaceFromFaceId(group[next_index])
		next_index += 1
		
		for i in current._adj_faces:
			# i is the neighbour face's id we are examining
			if i == -1 or visited.has(i):
				continue
			
			visited[i] = true
			
			if areCoplanar(ref, getFaceFromFaceId(i)):
				group.append(i)
	
	return group

## Returns the whole folding group
func getFoldGroup(face_id : int, edge_side : Edge.EdgeEnum) -> Array[int] :
	var planar_group : Array[int] = getPlanarGroup(face_id)
	var face : Face = getFaceFromFaceId(face_id)
	var grabbed_edge : Edge = face._edges[edge_side]
	var hinge: Edge = face.getOppositeEdge(grabbed_edge)
	var hinge_neighbour: int = face.getNeighbouringFace(hinge._side)
	
	if hinge_neighbour == -1:
		return []
	
	if planar_group.has(hinge_neighbour):
		return[]
	
	var stationary: Dictionary = {}
	var pending: Array[int] = [hinge_neighbour]
	var next_index: int = 0
	
	stationary[hinge_neighbour] = true
	
	while next_index < pending.size():
		var current : Face = getFaceFromFaceId(pending[next_index])
		next_index += 1
		
		for i in current._adj_faces:
			if i == -1:
				continue
			if planar_group.has(i):
				continue
			if stationary.has(i):
				continue
			
			stationary[i] = true
			pending.append(i)
		
	var moving_group : Array[int] = []
	
	for cube in _cubes:
		for f in cube._faces:
			if not stationary.has(f._id_face):
				moving_group.append(f._id_face)
		
	return moving_group
