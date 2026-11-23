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
## Stores Shift+Click selected faces
var _multiselection: Array[int] = []

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

## Computes and returns the combined global AABB of all cubes in the polycube.
func getPolycubeAABB() -> AABB :
	var aabb : AABB = AABB()
	var first = true
	for cube in _cubes:
		var aabb_cube = cube.getCubeAABB()
		if first :
			first = false
			aabb = aabb_cube
		else:
			aabb = aabb.merge(aabb_cube)
	return aabb

## Checks whether the polycube can be unfolded.
func canUnfold() -> bool:
	var end = true
	var face_init =  _cubes[0]._faces[0]
	for cube in _cubes:
		for face in cube._faces:
			end = areCoplanar(face_init, face) && end
	Log.info("Fin de jeu : " + str(end))
	return end;

# Rotate all faces of the polycube in the direction the camera is looking
func finalRotation(duration: float = 2.5) -> void:
	var target_angle_x: float = 0.0
	var target_angle_z: float = 0.0
	
	var ref_face : Face = _cubes[0]._faces[0]
	var normal = ref_face.global_transform.basis
	if normal.y[1] > 0.9:
		return
	elif roundi(normal.y[2]) != 0:
		target_angle_x = 90 if int(normal.y[2]) == -1 else -90
	elif roundi(normal.y[0]) != 0:
		target_angle_z = 90 if int(normal.y[0]) == -1 else -90
		
	var avg_local: Vector3 = getAveragePos()
	# only if the target is not on the origin center
	var target_world: Vector3 = to_global(avg_local)
	var end_rot_deg: Vector3 = rotation_degrees + Vector3(target_angle_x, 0.0, target_angle_z)
	var end_basis: Basis = Basis.from_euler(Vector3(
		deg_to_rad(end_rot_deg.x),
		deg_to_rad(end_rot_deg.y),
		deg_to_rad(end_rot_deg.z)
	))
	
	var end_global_pos: Vector3 = target_world - (end_basis * avg_local)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC) 
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", end_rot_deg, duration)
	tween.tween_property(self, "global_position", end_global_pos, duration)

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
	_multiselection = []
	for cube in _cubes:
		for face in cube._faces:
			face.unselect()

## Selects the reference face and refreshes its entire folding group.
func selectFace(face_id: int) -> void:
	_selected_face_id = face_id
	refreshSelectedFaceEdges()

## Handles multiselection
func multiselectFace(face_id: int) -> void:
	if _selected_face_id == -1:
		selectFace(face_id)
	elif face_id != _selected_face_id:
		if _multiselection.has(face_id):
			_multiselection.erase(face_id)	# TODO: blem si on supprime au milieu
		elif (
			hasInAdjList(_selected_face_id, face_id) or
			isAdjToGroup(_multiselection, face_id)
			):
			_multiselection.append(face_id)
	refreshSelectedFaceEdges()

## Checks whether face a has face b in its adjacency list
func hasInAdjList(a: int, b: int) -> bool :
	return getFaceFromFaceId(a)._adj_faces.has(b)

## Checks whether a face is adjacent to a group of faces
func isAdjToGroup(group: Array[int], face_id: int):
	var result: bool = false
	for f in group:
		result = result or hasInAdjList(f, face_id)
	return result

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

	var group: Array[int] = getSelectedFaces()

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
func getSelectionGroup(face_id: int, extra_faces: Array[int] = []) -> Array[int]:
	var faces_depart : Array[int] = [face_id]
	for extra_id in extra_faces:
		if not faces_depart.has(extra_id):
			faces_depart.append(extra_id)
	var components: Array[Array] = []
	var processed: Dictionary = {}
	var body_index: int = -1
	var body_cycles: int = -1
	var neighbours: Array[int] = []
	for depart_id in faces_depart:
		processed[depart_id] = true
		var depart = getFaceFromFaceId(depart_id)
		for neighbour_id in depart._adj_faces:
			if neighbour_id != -1 and not neighbours.has(neighbour_id):
				neighbours.append(neighbour_id)
	neighbours.sort()

	for neighbour_id in neighbours:
		if processed.has(neighbour_id):
			continue

		var component: Array[int] = collectFaces(neighbour_id, faces_depart)

		var links: int = 0
		for member_id in component:
			processed[member_id] = true

			for adjacent_id in getFaceFromFaceId(member_id)._adj_faces:
				if adjacent_id != -1 and not faces_depart.has(adjacent_id):
					links += 1

		var cycles: int = links / 2 - component.size() + 1
		components.append(component)

		if body_index == -1 or cycles > body_cycles or (
			cycles == body_cycles
			and component.size() > components[body_index].size()
		):
			body_index = components.size() - 1
			body_cycles = cycles

	var group: Array[int] = faces_depart.duplicate()
	for i in range(components.size()):
		if i != body_index:
			group.append_array(components[i])

	return group

## Shortcut: returns getSelectionGroup on current selected face and multiselection
func getSelectedFaces() -> Array[int] :
	if _selected_face_id == -1:
		return []
	return getSelectionGroup(_selected_face_id, _multiselection) 

## Returns the moving faces for the chosen hinge, including dependent branches.
## [param edge_side] identifies the grabbed side on the attachment face.
func getFoldGroup(face_id: int, edge_side: Edge.EdgeEnum, saved_group: Array[int] = []) -> Array[int]:
	var selection: Array[int] = saved_group.duplicate()
	
	if selection.is_empty():
		selection = getSelectedFaces()
	if selection.is_empty():
		selection = getSelectionGroup(face_id)
	
	if not selection.has(face_id):
		return []
	
	var face: Face = getFaceFromFaceId(face_id)
	var hinge: Edge = face.getOppositeEdge(face._edges[edge_side])
	var neighbour_id: int = face.getNeighbouringFace(hinge._side)
	
	if neighbour_id == -1 or selection.has(neighbour_id):
		return []
	
	var fixed: Array[int] = collectFaces(neighbour_id, selection)
	var moving: Array[int] = collectFaces(face_id, fixed)
	
	var expected: Array[int] = selection.duplicate()
	expected.sort()
	moving.sort()
	
	if moving != expected:
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
