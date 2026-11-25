extends Control

const LOG_TAG := "[GameModeMenu] "
const GAME_PARAM_CUSTOM: PackedScene = preload("res://scenes/interfaces/GameParamCustom.tscn")
const GAME_LEVEL_SELECT: PackedScene = preload("res://scenes/interfaces/LevelSelect.tscn")


func _ready() -> void:
	Log.debug(LOG_TAG + "ready")

func _on_mode_level_button_pressed() -> void:
	Log.info(LOG_TAG + "Mode Level sélectionné")
	get_parent().add_child(GAME_LEVEL_SELECT.instantiate())
	queue_free()

func _on_mode_custom_button_pressed() -> void:
	Log.info(LOG_TAG + "Mode personnalisé sélectionné")
	get_parent().add_child(GAME_PARAM_CUSTOM.instantiate())
	queue_free()

func _on_back_button_pressed() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("window_fullscreen"):
		Settings.set_fullscreen(!Settings.fullscreen)
		get_viewport().set_input_as_handled()
