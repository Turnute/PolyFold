extends LinkButton

@export var hover_scale := 1.15
@export var duration := 0.6
@export var flash_text_color := Color("#2F5BEA") 
@export var flash_bg_color := Color("#FFFFFF")    
 
const COLOR_KEYS := ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]

var _tween: Tween
var _bg: Panel
var _base_colors := {}


func _ready() -> void:
	for key in COLOR_KEYS:
		_base_colors[key] = get_theme_color(key)
	_create_background()
	mouse_entered.connect(_spin)
	resized.connect(_update_pivot)
	_update_pivot()


func _create_background() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = flash_bg_color
	style.set_corner_radius_all(8)

	_bg = Panel.new()
	_bg.add_theme_stylebox_override("panel", style)
	_bg.show_behind_parent = true
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.offset_left = -12
	_bg.offset_right = 12
	_bg.offset_top = -4
	_bg.offset_bottom = 4
	_bg.modulate.a = 0.0
	add_child(_bg)


func _update_pivot() -> void:
	pivot_offset = size / 2


func _set_text_color(color: Color) -> void:
	for key in COLOR_KEYS:
		add_theme_color_override(key, color)


func _restore() -> void:
	rotation_degrees = 0.0
	scale = Vector2.ONE
	_bg.modulate.a = 0.0
	for key in COLOR_KEYS:
		add_theme_color_override(key, _base_colors[key])


func _spin() -> void:
	Log.critical(" SCRUM MASTER SELECTED")
	if _tween and _tween.is_running():
		return
	var half := duration / 2
	var start_color: Color = _base_colors["font_hover_color"]

	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "rotation_degrees", 360.0, duration)
	_tween.tween_property(self, "scale", Vector2.ONE * hover_scale, half)
	_tween.tween_property(self, "scale", Vector2.ONE, half).set_delay(half)
	_tween.tween_method(_set_text_color, start_color, flash_text_color, half)
	_tween.tween_method(_set_text_color, flash_text_color, start_color, half).set_delay(half)
	_tween.tween_property(_bg, "modulate:a", 1.0, half)
	_tween.tween_property(_bg, "modulate:a", 0.0, half).set_delay(half)
	_tween.chain().tween_callback(_restore)
