extends Node

const LOG_TAG := "[SettingsManager] "
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
var locale := "fr" # Application language
var resolution := Vector2i(1280, 720) # Window resolution
var fullscreen := false # Fullscreen mode
var keys := {} # Keybinds


func _ready() -> void:
	_load() # load settings file (if exist)
	
	# update keybinds
	for action in keys:
		replace_key(action, keys[action])
	
	TranslationServer.set_locale(locale)
	Log.info(LOG_TAG + "Language on : " + TranslationServer.get_locale())
	apply_window()

## Change the application language
## [br][br]
## [b]Parameters:[/b]
## [br]- [param value]: The new locale
func set_locale(value: String) -> void:
	locale = value
	TranslationServer.set_locale(locale)
	Log.info(LOG_TAG + "Language changed : " + locale)
	save()

## Change the window resolution
## [br][br]
## [b]Parameters:[/b]
## [br]- [param value]: Vector corresponding to the new resolution
func set_resolution(value: Vector2i) -> void:
	resolution = value
	Log.info(LOG_TAG + "Resolution changed : %s" % resolution)
	apply_window()
	save()


## Allows you to switch the window to full-screen mode or exit it
## [br][br]
## [b]Parameters:[/b]
## [br]- [param value]: true to enter in fullscreen, else false
func set_fullscreen(value: bool) -> void:
	fullscreen = value
	Log.info(LOG_TAG + "Fullscreen : %s" % fullscreen)
	apply_window()
	save()

## Resize the window
func apply_window() -> void:
	var w := get_window()
	if fullscreen:
		w.mode = Window.MODE_FULLSCREEN
	else:
		w.mode = Window.MODE_WINDOWED
		w.size = resolution
		w.move_to_center()
		
	Log.debug(LOG_TAG + "Window apply (mode : %s, size : %s)" % [w.mode, w.size])

## Save all changes in a config file
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("general", "locale", locale)
	cfg.set_value("video", "resolution", resolution)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("controls", "keys", keys)
	var err := cfg.save(PATH)
	if err != OK:
		Log.error(LOG_TAG + "Failed on parameters saved (%s)" % error_string(err))
	else:
		Log.debug(LOG_TAG + "Parameters saved")

## Load user settings from a config file and apply it
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return  # pas de fichier
	locale = cfg.get_value("general", "locale", locale)
	resolution = cfg.get_value("video", "resolution", resolution)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	keys = cfg.get_value("controls", "keys", keys)

## Adds a key remapped by the user
## [br][br]
## [b]Parameters:[/b]
## [br]- [param action]: The name of the action (ex: ui_cancel, ui_undo,...)
## [br]- [param event]: The new key
func set_key(action: StringName, event: InputEventKey) -> void:
	keys[action] = event
	replace_key(action, event)
	Log.info(LOG_TAG + "Key changed : %s -> %s" % [action, event.as_text()])
	save()

## Replace the new key in Godot keybinds
## [br][br]
## [b]Parameters:[/b]
## [br]- [param action]: The name of the action (ex: ui_cancel, ui_undo,...)
## [br]- [param event]: The new key		
func replace_key(action: StringName, event: InputEvent) -> void:
	var events := InputMap.action_get_events(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	for e in events.slice(1):
		InputMap.action_add_event(action, e)
			
