extends Node

const PATH := "user://settings.cfg"
const LOCALES: Array[String] = ["fr", "en", "es"]
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768),
	Vector2i(1280, 720), Vector2i(1024, 768),
]

# Default values
var locale := "fr"
var resolution := Vector2i(1280, 720)
var fullscreen := false


func _ready() -> void:
	_load() # load settings file (if exist)
	TranslationServer.set_locale(locale)
	_apply_window()
	#Log.info("Settings appliqués : langue=%s, résolution=%s, plein écran=%s"
		#% [locale, resolution, fullscreen])



func set_locale(value: String) -> void:
	locale = value
	TranslationServer.set_locale(locale)
	save()


func set_resolution(value: Vector2i) -> void:
	resolution = value
	_apply_window()
	save()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window()
	save()


func _apply_window() -> void:
	var w := get_window()
	if fullscreen:
		w.mode = Window.MODE_FULLSCREEN
	else:
		w.mode = Window.MODE_WINDOWED
		w.size = resolution
		w.move_to_center()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	cfg.set_value("video", "resolution", resolution)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return  # pas de fichier
	locale = cfg.get_value("general", "locale", locale)
	resolution = cfg.get_value("video", "resolution", resolution)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
