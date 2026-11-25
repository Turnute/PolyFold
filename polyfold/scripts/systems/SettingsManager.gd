extends Node

const LOG_TAG := "[Settings] "
const PATH := "user://settings.cfg"
const LOCALES: Array[String] = ["fr", "en", "es"]
const LANGUAGE_NAMES := {
	"fr": "Français",
	"en": "English",
	"es": "Español",
}
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
	Log.info(LOG_TAG + "Langue active : " + TranslationServer.get_locale())
	
	if OS.has_feature("web"):
		get_window().mode = Window.MODE_MAXIMIZED
	else:
		_apply_window()

func set_locale(value: String) -> void:
	locale = value
	TranslationServer.set_locale(locale)
	Log.info(LOG_TAG + "Langue changée : " + locale)
	save()


func set_resolution(value: Vector2i) -> void:
	resolution = value
	Log.info(LOG_TAG + "Résolution changée : %s" % resolution)
	_apply_window()
	save()


func set_fullscreen(value: bool) -> void:
	if (OS.has_feature("web")):
		pass
	fullscreen = value
	Log.info(LOG_TAG + "Plein écran : %s" % fullscreen)
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
		
	Log.debug(LOG_TAG + "Fenêtre appliquée (mode : %s, taille : %s)" % [w.mode, w.size])

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	cfg.set_value("video", "resolution", resolution)
	cfg.set_value("video", "fullscreen", fullscreen)
	var err := cfg.save(PATH)
	if err != OK:
		Log.error(LOG_TAG + "Échec de la sauvegarde des paramètres (%s)" % error_string(err))
	else:
		Log.debug(LOG_TAG + "Paramètres sauvegardés")


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return  # pas de fichier
	locale = cfg.get_value("general", "locale", locale)
	resolution = cfg.get_value("video", "resolution", resolution)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
