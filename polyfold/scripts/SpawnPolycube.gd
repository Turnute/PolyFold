extends Node3D

## String for the polycube data file
var data_str = "res://data/polycubes/test_poly.tres"
@onready var camera : Camera3D = $Camera3D

# TODO: Update this function to do random generation based on a mode parameter
## Spawns polycube based on a PolycubeData object
func init_polycube() -> void:
	var data : PolycubeData = load(data_str)
	var polycube : Polycube = PolycubeFactory.loadPolycube(data)
	
	polycube.name = "Polycube"
	add_child(polycube)
	camera.target(polycube)
	

func _ready() -> void:
	# TEMP: Init polycube
	init_polycube()
