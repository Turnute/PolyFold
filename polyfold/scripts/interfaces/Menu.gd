extends Node

#const GAME_LEVEL := "res://scenes/interfaces/Game_Level.tscn"
const SETTINGS_PAGE := preload("res://scenes/interfaces/Settings.tscn")
const GAME_MODE_CHOICE: PackedScene = preload("res://scenes/interfaces/GameModeChoice.tscn")


@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	add_child(GAME_MODE_CHOICE.instantiate())
	#get_tree().change_scene_to_file(GAME_LEVEL)

func _on_settings_button_pressed() -> void:
	add_child(SETTINGS_PAGE.instantiate())

func _on_quit_button_pressed() -> void:
	get_tree().quit()   # ferme le jeu

func _on_help_button_pressed() -> void:
	HelpMenu.create(self)
