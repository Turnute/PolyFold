class_name Unfolder
extends Node

## Handles unfolding moves.

## Checks connectivity and overlap constraints.
static func validMove(action : UnfoldAction, pol : Polycube) -> bool:
	# TODO: Validate connectivity and collisions.
	return true

## Executes an unfolding move and updates face connections.
# TODO : Handle unfolding groups
static func executeMove(action : UnfoldAction, pol : Polycube) -> void:
	if !validMove(action, pol):
		return
	
	action.print() # DEBUG
	
	var folding_face : Face = pol.getFace(action._id_cube, action._face)
	var folding_edge : Edge = folding_face._edges[action._edge]
	var opposite_edge : Edge = folding_face.getOppositeEdge(folding_edge)
	
	# Translate the direction to an angle in degrees.
	var rot : float
	if action._dir == UnfoldAction.DirEnum.FWD: rot = 90.0
	else: rot = -90.0
	
	# Rotate the face around the opposite edge.
	folding_face.rotateAroundEdge(opposite_edge, rot)
	
	# Update face connections, keeping only the hinge connection.
	var disconnected_faces : Array[int] = folding_face.disconnectFromEdge(opposite_edge)
	for f_id in disconnected_faces :
		var f : Face = pol.getFaceFromFaceId(f_id)
		if f == null: print("no face from ", f_id)
		else: f.disconnectFace(folding_face._id_face)
