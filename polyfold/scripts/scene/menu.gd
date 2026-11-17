extends Node

const SETTINGS_PAGE := preload("res://scenes/interfaces/Settings.tscn")

@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	settings_button.pressed.connect(settings_button_pressed)
	quit_button.pressed.connect(quit_button_pressed)

func settings_button_pressed() -> void:
	add_child(SETTINGS_PAGE.instantiate())

func quit_button_pressed() -> void:
	get_tree().quit()   # ferme le jeu
