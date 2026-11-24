extends Control

const LOG_TAG := "[LevelSelect] "

const LEVELS_DIR := "res://data/levels/"
const LEVEL_CARD_SCENE := preload("res://prefabs/interfaces/LevelCard.tscn")
const GAME_SCENE := "res://scenes/interfaces/Game.tscn"

@onready var grid: GridContainer = %GridContainer


func _ready() -> void:
	_build_grid()

func _on_back_button_pressed() -> void:
	queue_free()

func _build_grid() -> void:
	# récupérer et parser les fichiers
	var levels: Array[Dictionary] = []
	for file_name in _get_level_files():
		var info := _parse_level_file_name(file_name)
		if info.is_empty():
			Log.warn("Nom de niveau invalide (ignoré) : " + file_name)
			continue
		Log.info("Nouvelle card (niveau) : " + str(info["order"]) + " - " + info["tr_name"])
		info["path"] = LEVELS_DIR + file_name
		levels.append(info)

	# création card
	var previous_completed := true   # le 1er niveau est toujours débloqué
	for level in levels:
		var best_score: int = SaveLevelManager.get_best_score(level["tr_name"])

		var card := LEVEL_CARD_SCENE.instantiate()
		grid.add_child(card)   # d'abord add_child, pour que les @onready existent
		card.setup(level["order"], level["tr_name"], best_score, previous_completed)
		print(card.scene_file_path, " |) ", card.get_script().resource_path)
		
		previous_completed = (best_score != -1)


func _get_level_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file_name in ResourceLoader.list_directory(LEVELS_DIR):
		if file_name.get_extension() == "tres":
			files.append(file_name)
	return files


## "1__Niv_TRADUCTION.tres" -> { "order": 1, "tr_name": "Niv_TRADUCTION" }
func _parse_level_file_name(file_name: String) -> Dictionary :
	var parts := file_name.get_basename().split("__", false, 1)
	if parts.size() != 2 or not parts[0].is_valid_int():
		return {}
	return {	"order": parts[0],
				"tr_name": parts[1] }
