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

## Selects the reference face and refreshes its entire folding group.
func selectFace(face_id: int) -> void:
	_selected_face_id = face_id
	refreshSelectedFaceEdges()

## Removes selection from the face matching a valid face identifier.
func unselectFace(face_id : int) -> void :
	unselectAllFaces()

## Checks whether a face can be unfolded along a certain edge
func canFoldFace(face_id : int, edge_side : Edge.EdgeEnum) -> bool:
	return not getFoldGroup(face_id, edge_side).is_empty()

## Highlights the selected group and binds one farthest handle per valid hinge.
func refreshSelectedFaceEdges() -> void:
	if _selected_face_id == -1:
		return

	for cube in _cubes:
		for face in cube._faces:
			face.unselect()
			for edge in face._edges:
				edge._fold_face = null

	var group: Array[int] = getSelectionGroup(_selected_face_id)

	for face_id in group:
		var face: Face = getFaceFromFaceId(face_id)
		face.select()
		face.showEdges(false)

	for face_id in group:
		var anchor: Face = getFaceFromFaceId(face_id)

		for hinge in anchor._edges:
			var neighbour_id: int = anchor.getNeighbouringFace(hinge._side)

			if neighbour_id == -1 or group.has(neighbour_id):
				continue

			var grabbed: Edge = anchor.getOppositeEdge(hinge)

			if not canFoldFace(face_id, grabbed._side):
				continue

			var handle: Edge = findFarthestHandle(group, anchor, hinge)

			if handle != null:
				handle._fold_face = anchor
				handle._fold_grabbed_side = grabbed._side
				handle.showEdge(true)

## Checks whether or not two faces are coplanar
func areCoplanar(a : Face, b : Face) -> bool :
	var normal_a : Vector3 = a.global_transform.basis.y.normalized()
	var normal_b : Vector3 = b.global_transform.basis.y.normalized()
	
	var parallel: bool = absf(normal_a.dot(normal_b)) >= 0.9999
	
	var distance_to_plane: float = absf(
		normal_a.dot(b.global_position - a.global_position)
	)

	return parallel and distance_to_plane <= 0.0001

## Returns faces reachable through existing connections.
## Excluded faces are not crossed.[br]
## [param plane] optionally restricts the traversal.
func collectFaces(start_id : int, excluded : Array[int], plane : Face = null) -> Array[int]:
	var result: Array[int] = []
	var pending : Array[int] = [start_id]
	var visited : Dictionary = {}
	var next_index : int = 0
	
	while next_index < pending.size():
		var face_id : int = pending[next_index]
		next_index += 1
		
		if face_id == -1 or excluded.has(face_id) or visited.has(face_id):
			continue
		
		visited[face_id] = true
		var face : Face = getFaceFromFaceId(face_id)
		
		if plane != null and not areCoplanar(plane, face):
			continue
		
		result.append(face_id)
		pending.append_array(face._adj_faces)
	
	return result

## Returns the selected face and the branches outside the main body.
func getSelectionGroup(face_id: int) -> Array[int]:
	var reference: Face = getFaceFromFaceId(face_id)
	var components: Array[Array] = []
	var processed: Dictionary = {face_id: true}
	var body_index: int = -1
	var body_cycles: int = -1

	var neighbours: Array[int] = reference._adj_faces.duplicate()
	neighbours.sort()

	for neighbour_id in neighbours:
		if neighbour_id == -1 or processed.has(neighbour_id):
			continue

		var component: Array[int] = collectFaces(neighbour_id, [face_id])

		var links: int = 0
		for member_id in component:
			processed[member_id] = true

			for adjacent_id in getFaceFromFaceId(member_id)._adj_faces:
				if adjacent_id != -1 and adjacent_id != face_id:
					links += 1

		var cycles: int = links / 2 - component.size() + 1
		components.append(component)

		if body_index == -1 or cycles > body_cycles or (
			cycles == body_cycles
			and component.size() > components[body_index].size()
		):
			body_index = components.size() - 1
			body_cycles = cycles

	var group: Array[int] = [face_id]
	for i in range(components.size()):
		if i != body_index:
			group.append_array(components[i])

	return group

## Returns the moving faces for the chosen hinge, including dependent branches.
## [param edge_side] identifies the grabbed side on the attachment face.
func getFoldGroup(face_id: int, edge_side: Edge.EdgeEnum) -> Array[int]:
	var selection: Array[int] = getSelectionGroup(face_id)
	var face: Face = getFaceFromFaceId(face_id)
	var hinge: Edge = face.getOppositeEdge(face._edges[edge_side])
	var neighbour_id: int = face.getNeighbouringFace(hinge._side)

	if neighbour_id == -1 or selection.has(neighbour_id):
		return []

	return selection

## Returns an edge's longitudinal axis in world space.
func getEdgeAxis(face: Face, edge: Edge) -> Vector3:
	var local_axis: Vector3 = Vector3.FORWARD

	if edge._side == Edge.EdgeEnum.LEFT or edge._side == Edge.EdgeEnum.RIGHT:
		local_axis = Vector3.RIGHT

	return (face.global_transform.basis * local_axis).normalized()

## Returns one boundary edge at maximum distance opposite the chosen hinge.
func findFarthestHandle(group: Array[int], anchor: Face, hinge: Edge) -> Edge:
	var pivot: Vector3 = hinge.global_position
	var axis: Vector3 = getEdgeAxis(anchor, hinge)
	var direction: Vector3 = (anchor.global_position - pivot).normalized()

	var best: Edge = null
	var best_distance: float = -INF

	for face_id in group:
		var face: Face = getFaceFromFaceId(face_id)

		for edge in face._edges:
			if group.has(face.getNeighbouringFace(edge._side)):
				continue

			if absf(getEdgeAxis(face, edge).dot(axis)) < 0.9999:
				continue

			var distance: float = (edge.global_position - pivot).dot(direction)

			if distance > best_distance:
				best_distance = distance
				best = edge

	return best

func log() -> void :
	Log.trace("Polycube")
	for c in _cubes:
		for f in c._faces:
			f.log()

## Used in unit testing: manually creates all faces' edges
func createEdges() -> void :
	for c in _cubes:
		for f in c._faces:
			f.createEdges()
