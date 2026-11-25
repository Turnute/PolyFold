class_name SettingsPage
extends Control

# cf /scripts/SettingsManager.gd 
# => const value LOCALES & RESOLUTIONS

const LOG_TAG := "[SettingsPage] "

signal back 

@onready var lang_select: OptionButton = %LangSelect
@onready var res_select: OptionButton = %ResSelect
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_fill_lists()
	_refresh()
	back.connect(queue_free)
	back_button.pressed.connect(back.emit)

## Fil list (Select) with Settings.gd const
func _fill_lists() -> void:
	for lang in Settings.LOCALES:
		lang_select.add_item(Settings.LANGUAGE_NAMES[lang])             # "Français", "English"… jamais traduit
		lang_select.set_item_metadata(lang_select.item_count - 1, lang) # (index, code), ex : (0, "fr")
		
	var screen := DisplayServer.screen_get_size()
	for res in Settings.RESOLUTIONS:
		if res.x <= screen.x and res.y <= screen.y:  # seulement celles qui tiennent à l'écran
			res_select.add_item("%d × %d" % [res.x, res.y])
			res_select.set_item_metadata(res_select.item_count - 1, res)


## Show the current settings in the menu.
func _refresh() -> void:
	Log.debug(LOG_TAG + "Refresh called")
	_select_by_metadata(lang_select, Settings.locale)
	_select_by_metadata(res_select, Settings.resolution)
	fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	res_select.disabled = Settings.fullscreen


func _select_by_metadata(select: OptionButton, value: Variant) -> void:
	for i in select.item_count:
		if select.get_item_metadata(i) == value:
			select.select(i)
			return


func _on_lang_select_item_selected(index: int) -> void:
	Settings.set_locale(lang_select.get_item_metadata(index))


func _on_res_select_item_selected(index: int) -> void:
	Settings.set_resolution(res_select.get_item_metadata(index))


func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	Log.debug(LOG_TAG + "Fullscreen toggled")
	Settings.set_fullscreen(toggled_on)
	res_select.disabled = toggled_on # lock res choice if fullscreen on
	fullscreen_check.set_pressed_no_signal(toggled_on)

## Close the menu with [code]Escape[/code]
## and switch full-screen mode with the full-screen key.
## [br][br]
## Does nothing while a command button is waiting for a key.
## [br][br]
## [b]Parameters:[/b]
## [br]- [param event]: The input event
func _input(event: InputEvent) -> void:
	if(CmdButton.listening):
		pass
	else:
		# Handling ui_cancel before parent method
		if event.is_action_pressed("ui_cancel"):
			queue_free()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("window_fullscreen"):
			_on_fullscreen_check_toggled(!Settings.fullscreen)
			get_viewport().set_input_as_handled()
