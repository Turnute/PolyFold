class_name LevelSystem
extends Node

static var _instance: LevelSystem
static var _levels :Array[Level]
var _levelData : LevelData = load("res://data/levels/test_level.tres")

static func _static_init() -> void:
	_instance = LevelSystem.new()

func _init() -> void:
	_levels.append(LevelFactory.loadLevel(_levelData))

static func loadLevel(id : int) -> Level :
	Log.info(str(_levels))
	return _levels[id]
