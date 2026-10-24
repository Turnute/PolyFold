class_name Unfolder
extends Node

## Script gérant les dépliements

## Checks if a move is valid: not disconnecting and no overlap
static func validMove(action : UnfoldAction, pol : Polycube) -> bool:
	# TODO : validation
	return true

## Executes an Unfolding move
static func executeMove(action : UnfoldAction, pol : Polycube) -> void:
	if !validMove(action, pol):
		return
	
	action.print() # DEBUG
	
	var folding_face : Face = pol.getFace(action._id_cube, action._face)
	var folding_edge : Edge = folding_face._edges[action._edge]
	var opposite_edge : Edge = folding_face.getOppositeEdge(folding_edge)
	
	# Translating direction to rotation value
	var rot : float
	if action._dir == UnfoldAction.DirEnum.FWD: rot = 90.0
	else: rot = -90.0
	
	# Rotating the face using the opposite edge as the axis
	folding_face.rotateAroundEdge(opposite_edge, rot)
	
	# Updating the faces' adjacency list. Everything is disconnected from the folding face
	# except the one adjacent to the opposite edge.	
	var disconnected_faces : Array[int] = folding_face.disconnectFromEdge(opposite_edge)
	for f_id in disconnected_faces :
		var f : Face = pol.getFaceFromFaceId(f_id)
		if f == null: print("no face from ", f_id)
		else: f.disconnectFace(folding_face._id_face)
