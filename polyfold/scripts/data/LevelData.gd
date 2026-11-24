class_name LevelData
extends Resource

## Represents a game level.

## Level identifier.
@export var id : int
## Move goal
@export var move_goal : int
## Time goal (s)
@export var time_goal : int
## Polycube data used by the level.
@export var polycube_file : PolycubeData
