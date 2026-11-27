extends GutTest

const data_str = "res://data/polycubes/test_poly.tres"

func test_getAdj():
	var input = Vector3i(1,1,1)
	var adj = PolycubeFactory.getAdj(input)
	
	gut.p("Testing 6-adjacent cube positions")
	assert_true(adj.has(Vector3i(0,1,1)))
	assert_true(adj.has(Vector3i(1,0,1)))
	assert_true(adj.has(Vector3i(1,1,0)))
	assert_true(adj.has(Vector3i(2,1,1)))
	assert_true(adj.has(Vector3i(1,2,1)))
	assert_true(adj.has(Vector3i(1,1,2)))
	
	gut.p("Testing 18-adjacent positions")
	assert_false(adj.has(Vector3i(1,0,0)))
	assert_false(adj.has(Vector3i(2,2,1)))

func test_loadPolycube():
	var data : PolycubeData = load(data_str)
	var polycube : Polycube = autofree(PolycubeFactory.loadPolycube(data))
	var adj_str : String = "Check polycube adjacency for cubes {0} and {1}"
	
	assert_true(polycube._cubes.size() == 5, "Check polycube size")
	assert_eq(polycube._adj[1][0], Face.FaceEnum.BACK, adj_str.format([1, 0]))
	assert_eq(polycube._adj[1][2], Face.FaceEnum.RIGHT, adj_str.format([1, 2]))
	assert_eq(polycube._adj[1][3], Face.FaceEnum.TOP, adj_str.format([1, 3]))

func test_generatePolycube():
	var polycube : Polycube = autofree(PolycubeFactory.generatePolycube(6,2))
	
	assert_true(polycube._cubes.size() == 6, "Check polycube size")
	assert_true(polycube._adj.size() == 6, "Check adj matrix col number")
	
	for i in range(6):
		assert_true(polycube._adj[i].size() == 6, "Check size for line {0}".format([i]))
		var cnt = 0
		for val in polycube._adj[i]:
			if val != 0:
				cnt += 1
		assert_true(cnt <= 2, "Testing maximal adjacency of the cube {0} -> cnt = {1}".format([i, cnt]))
