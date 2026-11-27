class_name LevelFactory
extends Node

static func loadLevel(data: LevelData) -> Level:
	var level = Level.creat(data.id,data.name, data.difficulty, data.polycube_file, data.high_score)
	return level
