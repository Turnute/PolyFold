extends PanelContainer

# cf /scripts/SettingsManager.gd 
# => const value LOCALES & RESOLUTIONS

signal back 

@onready var lang_select: OptionButton = %LangSelect
@onready var res_select: OptionButton = %ResSelect
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var back_button: Button = %BackButton


func _ready() -> void:
	_fill_lists()
	_refresh()
	lang_select.item_selected.connect(_on_lang_selected)
	res_select.item_selected.connect(_on_res_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(back.emit)


## Fil list with Settings.gd const
func _fill_lists() -> void:
	for lang in Settings.LOCALES:
		lang_select.add_item(Settings.LANGUAGE_NAMES[lang])             # "Français", "English"… jamais traduit
		lang_select.set_item_metadata(lang_select.item_count - 1, lang) # (index, code), ex : (0, "fr")
		
	var screen := DisplayServer.screen_get_size()
	for res in Settings.RESOLUTIONS:
		if res.x <= screen.x and res.y <= screen.y:  # seulement celles qui tiennent à l'écran
			res_select.add_item("%d × %d" % [res.x, res.y])
			res_select.set_item_metadata(res_select.item_count - 1, res)


## Actual choice
func _refresh() -> void:
	_select_by_metadata(lang_select, Settings.locale)
	_select_by_metadata(res_select, Settings.resolution)
	fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	res_select.disabled = Settings.fullscreen


func _select_by_metadata(select: OptionButton, value: Variant) -> void:
	for i in select.item_count:
		if select.get_item_metadata(i) == value:
			select.select(i)
			return


func _on_lang_selected(index: int) -> void:
	Settings.set_locale(lang_select.get_item_metadata(index))


func _on_res_selected(index: int) -> void:
	Settings.set_resolution(res_select.get_item_metadata(index))


func _on_fullscreen_toggled(on: bool) -> void:
	Settings.set_fullscreen(on)
	res_select.disabled = on # lock res choice if fullscreen on
