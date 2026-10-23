class_name PolycubeFactory
extends Node


## Function which gets positions of adjacent cubes by position
static func getAdj(pos: Vector3i) -> Array[Vector3i]:
	var adj : Array[Vector3i] = []
	
	for i in range(1,7):
		adj.append(pos + Face.DIRECTIONS[i])
	
	return adj 

## Function which loads a polycube into the scene based on the coordinates in the data structure
static func loadPolycube(data: PolycubeData) -> Polycube:
	var curr_id = 0
	
	## Instantiating cubes
	var cubes : Array[Cube] = []
	for pos in data.cube_matrix:
		var cube = Cube.new()
		cube._id = curr_id
		cube._pos = pos
		cubes.append(cube)
		curr_id += 1
	
	## Creating a new polycube
	var polycube : Polycube = Polycube.new(cubes)

	## Updating adjacency matrix
	for cube in cubes:
		var adj = getAdj(cube._pos)
		for i in range(6):
			for other in cubes:
				if other._pos == adj[i]:
					polycube._adj[cube._id][other._id] = i+1
	
	for cube in cubes:
		polycube.initCube(cube._id)

	polycube.initFaceAdj()

	return polycube
