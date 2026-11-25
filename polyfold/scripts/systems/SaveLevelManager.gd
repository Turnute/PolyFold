extends Node

const LOG_TAG := "[SaveLevelManager] "

const SAVE_PATH := "user://progress.cfg"

## Sections du fichier de sauvegarde
const SECTION_MOVES := "best_moves"
const SECTION_TIME := "best_time"

var _save := ConfigFile.new()


func _ready() -> void:
	var err := _save.load(SAVE_PATH)
	if err != OK:
		Log.debug(LOG_TAG + "Pas de sauvegarde trouvée")

	#if OS.is_debug_build(): # !! données de test en debug
		#_add_test_data()


## Return le meilleur nombre de coups du niveau, ou -1 (niveau pas réussi)
func get_best_moves(level_id: int) -> int:
	return _save.get_value(SECTION_MOVES, str(level_id), -1)


## Return le meilleur temps du niveau en secondes, ou -1 (niveau pas réussi)
func get_best_time(level_id: int) -> int:
	return _save.get_value(SECTION_TIME, str(level_id), -1)


## Return le nombre d'étoile obtenue sur ce level
func get_number_stars(level: LevelData) -> int:
	if not is_completed(level.id):
		return 0
	var stars := 1                                      # polycube déplié
	if get_best_moves(level.id) <= level.move_goal:
		stars += 1                                      # objectif de coups
	if get_best_time(level.id) <= level.time_goal:
		stars += 1                                      # objectif de temps
	return stars

func _compute_stars(level: LevelData, best_moves: int, best_time: int) -> int:
	if best_moves == -1:
		return 0
	var stars := 1                          # polycube déplié
	if best_moves <= level.move_goal:
		stars += 1                          # objectif de coups
	if best_time <= level.time_goal:
		stars += 1                          # objectif de temps
	return stars

func get_all_stats(level: LevelData) -> Dictionary:
	var best_moves := get_best_moves(level.id)
	var best_time := get_best_time(level.id)

	return {
		"is_completed": best_moves != -1,
		"best_moves": best_moves,
		"best_time": best_time,
		"stars": _compute_stars(level, best_moves, best_time),
	}

func is_completed(level_id: int) -> bool:
	return get_best_moves(level_id) != -1


## À appeler quand le joueur réussit un niveau.
## record gardé indépendamment (le minimum)
func save_result(level_id: int, moves: int, time_s: int) -> void:
	var key := str(level_id)

	var best_moves := get_best_moves(level_id)
	if best_moves == -1 or moves < best_moves:
		_save.set_value(SECTION_MOVES, key, moves)

	var best_time := get_best_time(level_id)
	if best_time == -1 or time_s < best_time:
		_save.set_value(SECTION_TIME, key, time_s)

	var err := _save.save(SAVE_PATH)
	if err != OK:
		Log.warn(LOG_TAG + "Échec de la sauvegarde (erreur %d)" % err)


# données de test
func _add_test_data() -> void:
	_save.set_value(SECTION_MOVES, "1", 5)
	_save.set_value(SECTION_TIME, "1", 60)
	_save.set_value(SECTION_MOVES, "2", 7)
	_save.set_value(SECTION_TIME, "2", 130)
