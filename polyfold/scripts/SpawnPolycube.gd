extends Node3D

## String for the polycube data file
var data_str = "res://data/polycubes/test_poly.tres"

# TODO: Update this function to do random generation based on a mode parameter
## Spawns polycube based on a PolycubeData object
func init_polycube() -> void:
	var data : PolycubeData = load(data_str)
	var polycube : Polycube = PolycubeFactory.generatePolycube(10, 3)
	
	polycube.name = "Polycube"
	add_child(polycube)

func _ready() -> void:
	# TEMP: Init polycube
	init_polycube()
