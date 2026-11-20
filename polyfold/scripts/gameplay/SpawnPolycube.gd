class_name SpawnPolycube
extends Node3D

# TEMP : String value for test polycube
static var data_str = "" # .tres

var polycube : Polycube
static var data : PolycubeData = null
static var nb_cubes : int = 4
static var max_adj : int = 2

@onready var camera : Camera3D = $Camera3D

## Spawns polycube based on a PolycubeData object [br]
## If [member SpawnPolycube.data][code] == null[/code] on ready, a random polycube will be generated 
func init_polycube() -> void:
	if (data != null):
		polycube = PolycubeFactory.loadPolycube(data)
	else: 
		polycube = PolycubeFactory.generatePolycube(nb_cubes, max_adj)
	
	if polycube == null:
		Log.error("[SpawnPolycube] Génération impossible (cubes : %d, adjacences max : %d)" % [nb_cubes, max_adj])
		return
	polycube.name = "Polycube"
	add_child(polycube)
	camera.target(polycube)
	

func _ready() -> void:
	# TEMP: Init polycube
	if(data_str.is_empty()):
		data = null 
	else :
		data = load(data_str)
	
	init_polycube()
