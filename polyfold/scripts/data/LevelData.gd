class_name LevelData
extends Resource

## Represents a game level.

## Level identifier.
@export var id : int
## Level name.
@export var name : String
## Level difficulty.
@export var difficulty : int
## Best score recorded for the level.
@export var high_score : int
## Polycube data used by the level.
@export var polycube_file : PolycubeData
