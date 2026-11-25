extends Node

const LOG_TAG := "[SaveLevelManager] "

const SAVE_PATH := "user://progress.cfg"

## Save file sections
const SECTION_MOVES := "best_moves"
const SECTION_TIME := "best_time"

var _save := ConfigFile.new()


func _ready() -> void:
	var err := _save.load(SAVE_PATH)  # Load the save into memory
	if err != OK:
		Log.debug(LOG_TAG + "No save file found (normal on first launch)")

	#if OS.is_debug_build(): # !! data test for debug
		#_add_test_data()


## Get the best number of moves for a level.
## [br][br]
## [br][b]Returns:[/b] [code]int[/code] - The best moves, or -1 if the level is not completed
func get_best_moves(level_id: int) -> int:
	return _save.get_value(SECTION_MOVES, str(level_id), -1)


## Get the best time for a level.
## [br][b]Returns:[/b] [code]int[/code] - The best time in seconds, or -1 if the level is not completed
func get_best_time(level_id: int) -> int:
	return _save.get_value(SECTION_TIME, str(level_id), -1)

## Get the number of stars won on a level.
## [br][br]
## Tip: if you also need the records, use [method get_all_stats]
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level]: The level data
## [br][b]Returns:[/b] [code]int[/code] - Number of stars (0 to 3)
func get_number_stars(level: LevelData) -> int:
	if not is_completed(level.id):
		return 0
	var stars := 1                                      # polycube unfolded
	if get_best_moves(level.id) <= level.move_goal:
		stars += 1                                      # moves goal reached
	if get_best_time(level.id) <= level.time_goal:
		stars += 1                                      # time goal reached
	return stars

## Count the stars from records that are already read.
## [br][br]
## 1 star: the polycube is unfolded.
## [br]+1 star: best moves <= move goal.
## [br]+1 star: best time <= time goal.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level]: The level data (for the goals)
## [br]- [param best_moves]: Best moves
## [br]- [param best_time]: Best time in seconds
## [br][b]Returns:[/b] [code]int[/code] - Number of stars (0 to 3)
func _compute_stars(level: LevelData, best_moves: int, best_time: int) -> int:
	if best_moves == -1:
		return 0
	var stars := 1                          # polycube unfolded
	if best_moves <= level.move_goal:
		stars += 1                          # moves goal reached
	if best_time <= level.time_goal:
		stars += 1                          # time goal reached
	return stars

## Get all the player stats for a level (each value is read only once).
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level]: The level data
## [br][b]Returns:[/b] [code]Dictionary[/code] - Keys: 'is_completed', 'best_moves', 'best_time', 'stars'
func get_all_stats(level: LevelData) -> Dictionary:
	var best_moves := get_best_moves(level.id)
	var best_time := get_best_time(level.id)
	return {
		"is_completed": best_moves != -1,
		"best_moves": best_moves,
		"best_time": best_time,
		"stars": _compute_stars(level, best_moves, best_time),
	}


## Check if a level is completed.
## [br][br]
## [br][b]Returns:[/b] [code]bool[/code] - true if the player has completed the level
func is_completed(level_id: int) -> bool:
	return get_best_moves(level_id) != -1


## Save the result of a completed level.
## [br][br]
## Each record is kept on its own: the best moves and the best time
## can come from different games.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param level_id]: The level id
## [br]- [param moves]: Number of moves in this game
## [br]- [param time_s]: Time of this game in seconds
func save_result(level_id: int, moves: int, time_s: int) -> void:
	var key := str(level_id)

	var best_moves := get_best_moves(level_id)
	if best_moves == -1 or moves < best_moves:
		Log.info(LOG_TAG + "New moves record : %d" % moves)
		_save.set_value(SECTION_MOVES, key, moves)

	var best_time := get_best_time(level_id)
	if best_time == -1 or time_s < best_time:
		Log.info(LOG_TAG + "New time record : %d" % time_s)
		_save.set_value(SECTION_TIME, key, time_s)

	var err := _save.save(SAVE_PATH)
	if err != OK:
		Log.warn(LOG_TAG + "Échec de la sauvegarde (erreur %d)" % err)


# Test data -- DEBUG
func _add_test_data() -> void:
	_save.set_value(SECTION_MOVES, "1", 5)
	_save.set_value(SECTION_TIME, "1", 60)
	_save.set_value(SECTION_MOVES, "2", 7)
	_save.set_value(SECTION_TIME, "2", 130)
