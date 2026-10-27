class_name UnfoldAction
extends Resource

## Unfolding direction.
enum DirEnum { 
	FWD,	## Adds 90 degrees
	BWD		## Substracts 90 degrees
	}

## Identifier of the cube where the action takes place.
var _id_cube : int
## The face to fold.
var _face : Face.FaceEnum
## The grabbed edge. Its opposite edge is the hinge.
var _edge : Edge.EdgeEnum
## The direction of the unfolding.
var _dir : DirEnum

## Creates an unfolding action for the specified cube, face, edge, and direction.
static func createAction(id_cube : int, face : Face.FaceEnum, edge : Edge.EdgeEnum, dir : DirEnum) -> UnfoldAction :
	var action : UnfoldAction = UnfoldAction.new()

	action._id_cube = id_cube
	action._face = face
	action._edge = edge
	action._dir = dir

	return action

## Prints the action parameters for debugging.
func print() -> void :
	print(
		"id_cube: ", _id_cube,
		" face: ", _face,
		" edge: ", _edge,
		" dir: ", _dir
	)
