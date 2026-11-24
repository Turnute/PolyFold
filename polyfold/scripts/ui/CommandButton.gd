class_name CmdButton
extends Button

@export var action: StringName # Touche à modifier (ex: ui_cancel, window_fullscreen...)

static var listening := false
var is_me := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_refresh_text()

func _on_cmd_btn_pressed() -> void:
	if listening:
		return
	listening = true
	is_me = true
	text = "En attente..."

func _input(event: InputEvent) -> void:
	if not is_me or not event is InputEventKey or not listening:
		return
	get_viewport().set_input_as_handled()

	const MODIFIERS = [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]
	if event.keycode in MODIFIERS:
		return

	Log.info(str("[Settings] Remap keybind ", action, " = ", event.as_text()))

	Settings.set_key(action, event)
	_refresh_text()
	
	is_me = false
	await get_tree().process_frame
	listening = false

func _refresh_text() -> void:
	var events := InputMap.action_get_events(action)
	if not events.is_empty():
		text = events[0].as_text()
