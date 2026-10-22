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
