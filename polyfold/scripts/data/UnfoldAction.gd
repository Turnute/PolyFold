class_name UnfoldAction
extends Resource

## Enumerator describing the direction of the unfolding
enum DirEnum { FWD, BWD }

## Identifier of the cube where the action takes place
var _id_cube : int
## The folded face
var _face : Face.FaceEnum
## The edge at which the action is taking place
var _edge : Edge.EdgeEnum
## The direction of the unfolding
var _dir : DirEnum

## Creates an unfolding action for the specified cube, face, edge, and direction.
static func createAction(id_cube : int, face : Face.FaceEnum, edge : Edge.EdgeEnum, dir : DirEnum) -> UnfoldAction :
	var action : UnfoldAction = UnfoldAction.new()

	action._id_cube = id_cube
	action._face = face
	action._edge = edge
	action._dir = dir

	return action

func print() -> void :
	print(
		"id_cube: ", _id_cube,
		" face: ", _face,
		" edge: ", _edge,
		" dir: ", _dir
	)
