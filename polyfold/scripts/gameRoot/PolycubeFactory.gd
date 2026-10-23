class_name PolycubeFactory
extends Node


## Function which gets positions of adjacent cubes by position
static func getAdj(pos: Vector3i) -> Array[Vector3i]:
	var adj : Array[Vector3i] = []
	adj.append(pos + Vector3i(0,1,0))
	adj.append(pos + Vector3i(0,-1,0))
	adj.append(pos + Vector3i(0,0,1))
	adj.append(pos + Vector3i(0,0,-1))
	adj.append(pos + Vector3i(1,0,0))
	adj.append(pos + Vector3i(-1,0,0))
	
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

	# TODO: Initialize face adjacency

	return polycube


static func generatePolycube(cube_nb: int, max_adj: int) -> Polycube :
	if (cube_nb < 1): return null
	
	var data : PolycubeData = PolycubeData.new()
	
	var queue = []
	var visited = []
	queue.push_back(Vector3i(0,0,0))
	visited.push_back(queue.back())
	
	while (cube_nb > 0):
		data.cube_matrix.push_back(queue.pop_front())
		var adj = getAdj(data.cube_matrix.back())
		
		for i in range(max_adj):
			var idx = randi() % 6 # Allows for repeat numbers => not necessarily of length max_adj
			if (!visited.has(adj[idx])) :
				visited.push_back(adj[idx])
				queue.push_back(adj[idx])
		
		cube_nb -= 1
	
	return loadPolycube(data)
