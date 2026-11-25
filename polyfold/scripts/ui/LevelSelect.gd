extends Control

const LOG_TAG := "[LevelSelect] "

const LEVELS_DIR := "res://data/levels/"
const LEVEL_CARD_SCENE := preload("res://prefabs/interfaces/LevelCard.tscn")
const GAME_SCENE := "res://scenes/interfaces/Game.tscn"
const GAME_LEVEL_SCENE := preload("res://scenes/interfaces/GameLevel.tscn")

@onready var grid: GridContainer = %GridContainer
@onready var info_label: Label = %InfoLabel
@onready var progress_label: Label = %ProgressLabel

## Tous les niveaux chargés, rangés par id.
var _levels_by_id := {}
## Niveau actuellement sélectionné (-1 = aucun).
var _selected_id := -1

func _ready() -> void:
	_init_page()

func _on_back_button_pressed() -> void:
	queue_free()

## Initialise les cartes + progress & preselect
func _init_page() -> void:
	# récupérer et parser les fichiers
	var levels: Array[LevelData] = []
	for file_name in ResourceLoader.list_directory(LEVELS_DIR):
		if file_name.get_extension() != "tres":
			continue
		var level := load(LEVELS_DIR + file_name) as LevelData
		if level == null:
			Log.warn(LOG_TAG + "Fichier ignoré : " + file_name)
			continue
		levels.append(level)

	# création card
	var locked := false  
	var total_stars := 0
		
	for level in levels:
		var stats : Dictionary = SaveLevelManager.get_all_stats(level)
		total_stars += stats["stars"]

		var card := LEVEL_CARD_SCENE.instantiate()
		grid.add_child(card)  # avant setup(), pour que les @onready existent
		card.setup(level.id, "LEVEL_%d" % level.id,
			stats["best_moves"], stats["best_time"], stats["stars"], locked)

		_levels_by_id[level.id] = level
		card.level_chosen.connect(_on_level_chosen)
		
		if not locked : 
			locked = not stats["is_completed"]

	progress_label.text = tr("LEVEL_SELECT_PROGRESS") % [total_stars, levels.size() * 3]
	_select_default_level(levels)

## signal d'une carte ou présélection 
func _on_level_chosen(level_id: int) -> void:
	_selected_id = level_id
	var level: LevelData = _levels_by_id[level_id]

	info_label.text = tr("LEVEL_INFO") % [
		level.id,                        # numéro
		tr("LEVEL_%d" % level.id),       # nom
		level.move_goal,                 # objectif de coups
		_format_time(level.time_goal),   # objectif de temps
	]

## Sélectionne le premier niveau pas encore réussi, sinon le dernier.
func _select_default_level(levels: Array[LevelData]) -> void:
	if levels.is_empty():
		info_label.text = ""
		return
	for level in levels:
		if not SaveLevelManager.is_completed(level.id):
			_on_level_chosen(level.id)
			return
	_on_level_chosen(levels[-1].id)

# 75 -> 01:15
func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _on_play_button_pressed() -> void:
	if _selected_id == -1:
		return
	var level: LevelData = _levels_by_id[_selected_id]

	Log.info(LOG_TAG + "Lancement niveau %d (coups : %d, temps : %d)"
		% [level.id, level.move_goal, level.time_goal])


	var polycube = MenuManager._display_polycube(self, level.polycube_file.resource_path, 0, 0)
	get_tree().change_scene_to_node(polycube)

	# Crée la partie
	var game = MenuManager._display_game_level(
		polycube,
		GameLevel.gameMode.LEVEL,
		str(level.id),               
		tr("LEVEL_%d" % level.id),  
		level.move_goal,
		level.time_goal,
	)
	game.startChrono()
	queue_free()
