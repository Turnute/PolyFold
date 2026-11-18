class_name PolycubeFactory
extends Node

## Function which gets positions of adjacent cubes by position
static func getAdj(pos: Vector3i) -> Array[Vector3i]:
	var adj : Array[Vector3i] = []
	
	for i in range(1,7):
		adj.append(pos + Face.DIRECTIONS[i])
	
	return adj 

## Function which counts how many cubes are adjacent to [param ref_cube] in the polycube
static func cntAdj(ref_cube: Vector3i, data: PolycubeData) -> int:
	var cnt = 0
	var adj = getAdj(ref_cube)
	
	for cube in data.cube_matrix:
		if cube != ref_cube && adj.has(cube): cnt += 1
	
	return cnt

## Function which loads a polycube into the scene based on the coordinates in the data structure
static func loadPolycube(data: PolycubeData) -> Polycube:
	Log.info("Loading current polycube")
	var curr_id = 0
	
	# Instantiating cubes
	var cubes : Array[Cube] = []
	for pos in data.cube_matrix:
		var cube = Cube.new()
		cube._id = curr_id
		cube._pos = pos
		cubes.append(cube)
		curr_id += 1
	
	# Creating a new polycube
	var polycube : Polycube = Polycube.new(cubes)

	# Updating adjacency matrix
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

## Function which randomly generates a polycube [br]
## [param cube_nb] : number of cubes in the polycube [br]
## [param max_adj] : maximum possible number of adjacent cubes
static func generatePolycube(cube_nb: int, max_adj: int) -> Polycube :
	# Edge cases
	if (cube_nb < 1): 
		print("Polycube must have at least one cube")
		return null
	if (max_adj < 2 || max_adj > 6):
		print("Polycube must have adjacency of at least 2 and at most 6")
		return null
	
	# Initialising new data struct for the polycube
	var data : PolycubeData = PolycubeData.new()
	
	# Queue to decide which cubes to add, visited for which have been seen
	var queue = []
	var visited = []
	queue.push_back(Vector3i(0,0,0))
	visited.push_back(queue.back())
	
	for i in range(cube_nb):
		# Adding first element of the queue to the polycube
		data.cube_matrix.push_back(queue.pop_front())
		var adj = getAdj(data.cube_matrix.back())
		
		var min = 1 # Ensure that at least one is added
		var max = max_adj if i == 0 else max_adj-1 # Current cube is forcedly connected to another cube if i>0
		var added = 0
		
		# Must add at least one cube to the queue if the queue is empty and cubes have not been added
		while added < min && queue.is_empty():
			for j in range(max):
				var idx = randi() % 6 # Allows for repeat numbers => not necessarily of length max_adj
				if (!visited.has(adj[idx])) :
					var add = true # Prevent adding a cube which brings a cube to max
					var all_max = true # Prevent adding a cube which leaves all cubes at max
					
					for cube in data.cube_matrix:
						var cnt_adj = cntAdj(cube, data)
						if getAdj(cube).has(adj[idx]):
							if cnt_adj == max_adj:
								add = false
							elif cnt_adj + 1 < max_adj: 
								all_max = false
						elif cnt_adj < max_adj:
							all_max = false
					
					if add and !all_max:
						visited.push_back(adj[idx])
						queue.push_back(adj[idx])
						added += 1
	
	return loadPolycube(data)
