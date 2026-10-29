extends Control

const LEVEL_SCENE := "res://scenes/test_level.tscn"
const RUN_RECORDS_PATH := "user://run_records.cfg"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu()


func _build_menu() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#18231b")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101710")
	panel_style.border_color = Color("#6cc94d")
	panel_style.set_border_width_all(3)
	panel_style.content_margin_left = 36.0
	panel_style.content_margin_top = 32.0
	panel_style.content_margin_right = 36.0
	panel_style.content_margin_bottom = 32.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	var title := Label.new()
	title.text = "KILL THE WACHOS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#9bea63"))
	content.add_child(title)

	var tagline := Label.new()
	tagline.text = "Sobrevive a la noche. Explora. Caza slimes."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 17)
	content.add_child(tagline)

	var records := ConfigFile.new()
	if FileAccess.file_exists(RUN_RECORDS_PATH):
		records.load(RUN_RECORDS_PATH)
	var victories := int(records.get_value("runs", "victories", 0))
	var record_label := Label.new()
	record_label.text = "Runs ganadas: %d" % victories
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(record_label)

	var play_button := Button.new()
	play_button.text = "Empezar run"
	play_button.custom_minimum_size = Vector2(0.0, 54.0)
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.pressed.connect(_start_run)
	content.add_child(play_button)

	var controls := Label.new()
	controls.text = "WASD mover · Clic izquierdo / Z disparar · Esc pausar"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 13)
	content.add_child(controls)
	play_button.grab_focus()


func _start_run() -> void:
	get_tree().change_scene_to_file(LEVEL_SCENE)
