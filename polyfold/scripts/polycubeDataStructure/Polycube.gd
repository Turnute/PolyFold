extends Node

class_name Polycube

var cubes : Array[Cube]
var adj : Array[Array] = [] # Matrice d'adjacence du polycube
# EXEMPLE :
# 			0	1	2	...
# 	0	[	0	0	BOT	0	]
# 	1 	[	0	0	0	0	]
# 	2 	[	TOP	0	0	0	]
# ...	[	0	0	0	0	]
# Le cube n°0 est lié au cube n°2 par sa face "TOP". 
# Le cube n°2 est lié au cube n°0 par sa face "BOTTOM".
# L'ID d'un cube correspond donc à sa position dans la matrice.

func initAdj() -> void:
	adj.clear()

	for i in cubes.size():
		var line : Array[Face.FaceEnum] = []
		line.resize(cubes.size())
		line.fill(0) # 0 = aucune connexion
		adj.append(line)

func addAdj(id1 : int, id2 : int, face1 : Face.FaceEnum, face2 : Face.FaceEnum) -> void:
	adj[id1][id2] = face1
	adj[id2][id1] = face2

func initCube(id : int) -> void:
	var cube = cubes[id]
	var occupied_faces = []
	
	for other_id in range(cubes.size()):
		if adj[id][other_id] != Face.FaceEnum.NONE:
			occupied_faces.append(adj[id][other_id])

	for face_side in range(Face.FaceEnum.TOP, Face.FaceEnum.BACK+1):
		if face_side not in occupied_faces:
			cube.createFace(face_side)

func canUnfold() -> bool:
	return true;
