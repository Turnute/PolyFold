extends Node

const LOG_TAG := "[SaveLevelManager] "

const SAVE_PATH := "user://progress.cfg"

var _save := ConfigFile.new()


func _ready() -> void:
	var err := _save.load(SAVE_PATH)
	if err != OK:
		Log.debug(LOG_TAG + "Pas de sauvegarde trouvée")
	
	if OS.is_debug_build(): # !! ajout données de test en debug
		_add_test_data()

## return meilleur score du niveau, ou -1 (niveau pas réussi)
func get_best_score(level_id: String) -> int:
	return _save.get_value("scores", level_id, -1)


func is_completed(level_id: String) -> bool:
	return get_best_score(level_id) != -1


# données de test
func _add_test_data() -> void:
	_save.set_value("scores", "LEVEL_NAME_CUBE", 12)
	_save.set_value("scores", "LEVEL_NAME_DICUBE", 18)
