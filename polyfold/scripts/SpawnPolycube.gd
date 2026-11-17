class_name SpawnPolycube
extends Node3D

# TEMP : String value for test polycube
const data_str = "res://data/polycubes/test_poly.tres"

var polycube : Polycube
static var data : PolycubeData = null
static var nb_cubes : int = 30
static var max_adj : int = 6

@onready var camera : Camera3D = $Camera3D

## Spawns polycube based on a PolycubeData object [br]
## If [member SpawnPolycube.data][code] == null[/code] on ready, a random polycube will be generated 
func init_polycube() -> void:
	if (data != null):
		polycube = PolycubeFactory.loadPolycube(data)
	else: 
		polycube = PolycubeFactory.generatePolycube(nb_cubes, max_adj)
	
	polycube.name = "Polycube"
	add_child(polycube)
	camera.target(polycube)
	

func _ready() -> void:
	# TEMP: Init polycube
	init_polycube()
	print(polycube._adj)
