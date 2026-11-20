extends Control

const LOG_TAG := "[GameModeMenu] "
const GAME_PARAM_CUSTOM: PackedScene = preload("res://scenes/interfaces/GameParamCustom.tscn")

func _ready() -> void:
	Log.debug(LOG_TAG + "ready")


func _on_mode_custom_button_pressed() -> void:
	Log.info(LOG_TAG + "Mode personnalisé sélectionné")
	get_parent().add_child(GAME_PARAM_CUSTOM.instantiate())
	queue_free()

func _on_back_button_pressed() -> void:
	queue_free()
