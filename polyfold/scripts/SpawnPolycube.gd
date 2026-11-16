class_name SpawnPolycube
extends Node3D

# TEMP : String value for test polycube
const data_str = "res://data/polycubes/test_poly.tres"

static var data : PolycubeData = null
static var nb_cubes : int = 10
static var max_adj : int = 3

@onready var camera : Camera3D = $Camera3D

## Spawns polycube based on a PolycubeData object [br]
## If [member SpawnPolycube.data][code] == null[/code] on ready, a random polycube will be generated 
func init_polycube() -> void:
	var polycube : Polycube
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
