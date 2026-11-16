class_name Unfolder
extends Node

## Handles unfolding moves.

## Checks connectivity and overlap constraints.
static func validMove(action: UnfoldAction, pol: Polycube) -> bool:
	var face: Face = pol.getFace(action._id_cube, action._face)

	return pol.canFoldFace(face._id_face, action._edge)

## Executes an unfolding move and updates face connections.
static func executeMove(action : UnfoldAction, pol : Polycube) -> void:
	if !validMove(action, pol):
		return
		
	var folding_face : Face = pol.getFace(action._id_cube, action._face)
	var folding_edge : Edge = folding_face._edges[action._edge]
	var hinge : Edge = folding_face.getOppositeEdge(folding_edge)
	
	var group : Array[int] = pol.getFoldGroup(folding_face._id_face, action._edge)
	var hinge_neighbour : int = folding_face.getNeighbouringFace(hinge._side)
	
	var pivot : Vector3 = hinge.global_position
	var local_axis : Vector3 = Vector3.FORWARD
	
	if hinge._side == Edge.EdgeEnum.LEFT or hinge._side == Edge.EdgeEnum.RIGHT:
		local_axis = Vector3.RIGHT

	var axis: Vector3 = (
		folding_face.global_transform.basis * local_axis
	).normalized()

	var angle: float = 90.0
	if action._dir == UnfoldAction.DirEnum.BWD:
		angle = -90.0

	var rotation := Basis(axis, deg_to_rad(angle))

	for face_id in group:
		var face: Face = pol.getFaceFromFaceId(face_id)
		var t: Transform3D = face.global_transform

		t.origin = pivot + rotation * (t.origin - pivot)
		t.basis = rotation * t.basis

		face.global_transform = t

	for face_id in group:
		var face: Face = pol.getFaceFromFaceId(face_id)

		for i in range(face._adj_faces.size()):
			var neighbour_id: int = face._adj_faces[i]

			if neighbour_id == -1 or group.has(neighbour_id):
				continue

			if face_id == folding_face._id_face and neighbour_id == hinge_neighbour:
				continue

			face._adj_faces[i] = -1
			pol.getFaceFromFaceId(neighbour_id).disconnectFace(face_id)

	pol.refreshSelectedFaceEdges()
