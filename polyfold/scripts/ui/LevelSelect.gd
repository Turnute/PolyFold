extends Control

const LOG_TAG := "[LevelSelect] "

const LEVELS_DIR := "res://data/levels/"
const LEVEL_CARD_SCENE := preload("res://prefabs/interfaces/LevelCard.tscn")
const GAME_SCENE := "res://scenes/interfaces/Game.tscn"
const GAME_LEVEL_SCENE := preload("res://scenes/interfaces/GameLevel.tscn")

@onready var grid: GridContainer = %GridContainer
@onready var info_label: Label = %InfoLabel
@onready var progress_label: Label = %ProgressLabel

## All levels loaded, arranged by id.
var _levels_by_id := {}
## Level actuelly selected (-1 = none).
var _selected_id := -1

func _ready() -> void:
	_init_page()

func _on_back_button_pressed() -> void:
	queue_free()

## Initialise cards + progress & preselect
func _init_page() -> void:
	# load et parse files
	var levels: Array[LevelData] = []
	for file_name in ResourceLoader.list_directory(LEVELS_DIR):
		if file_name.get_extension() != "tres":
			continue
		var level := load(LEVELS_DIR + file_name) as LevelData
		if level == null:
			Log.warn(LOG_TAG + "Ignored file : " + file_name)
			continue
		levels.append(level)

	# create card
	var locked := false  
	var total_stars := 0
		
	for level in levels:
		var stats := SaveLevelManager.get_all_stats(level)
		total_stars += stats["stars"]

		var card := LEVEL_CARD_SCENE.instantiate()
		grid.add_child(card)  # before setup(), then @onready exist
		card.setup(level.id, "LEVEL_%d" % level.id,
			stats["best_moves"], stats["best_time"], stats["stars"], locked)

		_levels_by_id[level.id] = level
		card.level_chosen.connect(_on_level_chosen)
		
		if not locked : 
			locked = not stats["is_completed"]

	progress_label.text = tr("LEVEL_SELECT_PROGRESS") % [total_stars, levels.size() * 3]
	_select_default_level(levels)

## Show the info of the chosen level in the bottom panel.
## [br][br]
## Called by the [code]level_chosen[/code] signal of a card, or by the default selection.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level_id]: The chosen level id
func _on_level_chosen(level_id: int) -> void:
	_selected_id = level_id
	var level: LevelData = _levels_by_id[level_id]

	info_label.text = tr("LEVEL_INFO") % [
		level.id,                        # number
		tr("LEVEL_%d" % level.id),       # name
		level.move_goal,                 # moves goal
		_format_time(level.time_goal),   # time goal
	]

## Select the first level not completed yet, else the last one.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param levels]: The levels, sorted by id
func _select_default_level(levels: Array[LevelData]) -> void:
	if levels.is_empty():
		info_label.text = ""
		return
	for level in levels:
		if not SaveLevelManager.is_completed(level.id):
			_on_level_chosen(level.id)
			return
	_on_level_chosen(levels[-1].id) # all levels completed: select the last one

# 75 -> 01:15
func _format_time(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _on_play_button_pressed() -> void:
	if _selected_id == -1:
		return
	var level: LevelData = _levels_by_id[_selected_id]

	Log.info(LOG_TAG + "Level launched %d (moves : %d, time : %d)"
		% [level.id, level.move_goal, level.time_goal])

	var polycube = MenuManager._display_polycube(self, level.polycube_file.resource_path, 0, 0)
	get_tree().change_scene_to_node(polycube)

	# Initialise game
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
