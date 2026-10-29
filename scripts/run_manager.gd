extends Node2D

const RUN_DURATION := 180.0
const BOSS_SCENE: PackedScene = preload("res://scenes/boss_slime.tscn")
const MINECRAFT_HUD_SCRIPT = preload("res://scripts/minecraft_hud.gd")
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const RUN_RECORDS_PATH := "user://run_records.cfg"
const POWERUP_SCENES := {
	"axe": preload("res://scenes/rotating_axe_powerup.tscn"),
	"sword": preload("res://scenes/sword_powerup.tscn"),
	"trident": preload("res://scenes/trident_powerup.tscn")
}
const POWERUP_DEFINITIONS := [
	{"id": "axe", "name": "Hacha giratoria", "icon": "res://images/rotating_axe.svg", "unlock_description": "Un hacha de 40 px gira alrededor de ti y golpea a los slimes."},
	{"id": "sword", "name": "Espada voladora", "icon": "res://images/assets/dungeon_items/iron-sword.png", "unlock_description": "Giran espadas de 40 px a tu alrededor y salen disparadas hacia fuera."},
	{"id": "trident", "name": "Lluvia de tridentes", "icon": "res://images/slime_trident.svg", "unlock_description": "Un tridente de 40 px cae sobre enemigos cercanos con daño de área."}
]
const GEAR_TIERS := [
	{"name": "Madera", "level": 1, "armor": 0},
	{"name": "Piedra", "level": 3, "armor": 3},
	{"name": "Hierro", "level": 5, "armor": 4},
	{"name": "Esmeralda", "level": 7, "armor": 4},
	{"name": "Diamante", "level": 10, "armor": 4},
	{"name": "Netherita", "level": 14, "armor": 5}
]
const UPGRADES := [
	{"id": "damage", "name": "Punta de hierro", "description": "+1 de daño por disparo"},
	{"id": "fire_rate", "name": "Cadencia rápida", "description": "Dispara un 20% más rápido"},
	{"id": "speed", "name": "Botas de slime", "description": "+15% de velocidad al moverte"},
	{"id": "magnet", "name": "Imán verde", "description": "Atrae bolas de slime desde más lejos"},
	{"id": "harvest", "name": "Cosecha abundante", "description": "+25% de experiencia al recoger slime"},
	{"id": "armor", "name": "Cota de hierro", "description": "+4 puntos de armadura y reduce el daño recibido"},
	{"id": "vitality", "name": "Corazón extra", "description": "+2 de vida máxima y recupera 2 puntos"}
]

var player
var spawner
var boss
var elapsed := 0.0
var level := 1
var experience := 0.0
var experience_to_next := 5
var experience_multiplier := 1.0
var magnet_bonus := 0.0
var kills := 0
var victories := 0
var weapon_tier_index := 0
var armor_tier_index := 0
var powerup_levels: Dictionary = {}
var powerup_instances: Dictionary = {}
var next_boss_at := RUN_DURATION
var boss_active := false
var endless_mode := false
var game_ended := false
var is_paused := false
var is_level_up_open := false
var completion_overlay_open := false

var hud_root: Control
var time_label: Label
var kills_label: Label
var equipment_label: Label
var minecraft_hud: Control
var powerup_inventory: HBoxContainer
var boss_bar: ProgressBar
var overlay: ColorRect
var overlay_content: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run_manager")
	player = get_tree().get_first_node_in_group("player") as Node2D
	spawner = get_parent().find_child("spawner", true, false)
	_build_interface()
	_update_hud()


func _process(delta: float) -> void:
	if game_ended or is_paused or is_level_up_open or completion_overlay_open:
		return
	elapsed += delta
	if boss_active:
		_update_boss_bar()
		_update_hud()
		return
	if spawner:
		if endless_mode and spawner.has_method("set_endless_time"):
			spawner.call("set_endless_time", maxf(0.0, elapsed - RUN_DURATION))
		elif spawner.has_method("set_run_progress"):
			spawner.call("set_run_progress", elapsed / RUN_DURATION)
	_update_hud()
	if elapsed >= next_boss_at:
		_begin_boss_fight()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var pause_key_pressed: bool = event.keycode == KEY_ESCAPE or event.keycode == KEY_P or event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_P
	if not pause_key_pressed:
		return
	if game_ended or is_level_up_open or completion_overlay_open:
		return
	if is_paused:
		_resume_game()
	else:
		_pause_game()
	get_viewport().set_input_as_handled()


func gain_experience(amount: int) -> void:
	if game_ended or boss_active:
		return
	experience += maxf(0.0, amount * experience_multiplier)
	_update_hud()
	if experience >= experience_to_next and not is_level_up_open:
		experience -= experience_to_next
		level += 1
		experience_to_next = ceili(experience_to_next * 1.35 + 1.0)
		_show_level_up()


func register_kill() -> void:
	kills += 1
	_update_hud()


func end_run() -> void:
	if game_ended:
		return
	game_ended = true
	if spawner and spawner.has_method("set_active"):
		spawner.call("set_active", false)
	get_tree().paused = true
	_show_overlay("FIN DE PARTIDA", "Has eliminado %d slimes y alcanzado el nivel %d." % [kills, level])
	_add_overlay_button("Volver a intentarlo", _restart_run)
	_add_overlay_button("Salir al menú", _leave_run_to_menu)


func on_boss_defeated() -> void:
	if game_ended:
		return
	boss_active = false
	boss_bar.visible = false
	if not endless_mode:
		endless_mode = true
		victories = _record_run_victory()
		completion_overlay_open = true
		get_tree().paused = true
		_show_overlay("¡RUN COMPLETADA!", "El dragón ha caído. Victoria registrada #%d.\nNivel %d · %d slimes eliminados." % [victories, level, kills])
		_add_overlay_button("Seguir jugando en infinito", _continue_endless_run)
		_add_overlay_button("Salir al menú", _leave_run_to_menu)
		return

	next_boss_at = elapsed + RUN_DURATION
	if spawner and spawner.has_method("set_active"):
		spawner.call("set_active", true)
	_update_hud()


func _begin_boss_fight() -> void:
	if boss_active or game_ended:
		return
	boss_active = true
	if spawner and spawner.has_method("set_active"):
		spawner.call("set_active", false)
	if player == null:
		end_run()
		return
	boss = BOSS_SCENE.instantiate()
	get_tree().current_scene.add_child(boss)
	var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var distance := maxf(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.72
	boss.global_position = player.global_position + direction * distance
	boss_bar.visible = true
	_update_hud()


func _update_boss_bar() -> void:
	if boss == null or not is_instance_valid(boss):
		return
	boss_bar.max_value = float(boss.get("max_health"))
	boss_bar.value = float(boss.get("health"))


func _show_level_up() -> void:
	is_level_up_open = true
	get_tree().paused = true
	_show_overlay("¡NIVEL %d!" % level, "Elige una mejora para esta partida")
	var choices: Array = _get_tier_upgrades()
	choices.append_array(_get_powerup_upgrades())
	var general_upgrades: Array = UPGRADES.duplicate(true)
	general_upgrades.shuffle()
	for upgrade in general_upgrades:
		if choices.size() >= 3:
			break
		choices.append(upgrade)
	choices.shuffle()
	for index in mini(3, choices.size()):
		var upgrade: Dictionary = choices[index]
		var button := _make_upgrade_button(upgrade)
		button.pressed.connect(_choose_upgrade.bind(upgrade))
		overlay_content.add_child(button)


func _choose_upgrade(upgrade: Dictionary) -> void:
	match upgrade["id"]:
		"damage":
			player.set("weapon_damage", player.get("weapon_damage") + 1)
		"fire_rate":
			player.set("weapon_fire_interval", maxf(0.12, player.get("weapon_fire_interval") * 0.8))
		"speed":
			player.set("SPEED", player.get("SPEED") * 1.15)
		"magnet":
			magnet_bonus += 85.0
		"harvest":
			experience_multiplier += 0.25
		"armor":
			player.set("armor_points", mini(20, int(player.get("armor_points")) + 4))
		"vitality":
			player.set("max_health", mini(40, int(player.get("max_health")) + 2))
			player.set("health", mini(int(player.get("max_health")), int(player.get("health")) + 2))
		"weapon_tier":
			weapon_tier_index = int(upgrade["tier_index"])
			player.set("weapon_damage", int(player.get("weapon_damage")) + 1)
		"armor_tier":
			armor_tier_index = int(upgrade["tier_index"])
			var tier_armor := int(GEAR_TIERS[armor_tier_index]["armor"])
			player.set("armor_points", mini(20, int(player.get("armor_points")) + tier_armor))
		"powerup":
			_add_or_upgrade_powerup(String(upgrade["powerup_id"]))

	is_level_up_open = false
	overlay.visible = false
	get_tree().paused = false
	_update_hud()
	_refresh_powerup_inventory()
	if experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		experience_to_next = ceili(experience_to_next * 1.35 + 1.0)
		_show_level_up()


func _get_tier_upgrades() -> Array:
	var upgrades: Array = []
	var next_weapon_tier := weapon_tier_index + 1
	if next_weapon_tier < GEAR_TIERS.size() and level >= int(GEAR_TIERS[next_weapon_tier]["level"]):
		var weapon_tier: Dictionary = GEAR_TIERS[next_weapon_tier]
		upgrades.append({
			"id": "weapon_tier",
			"tier_index": next_weapon_tier,
			"name": "Arco de %s" % weapon_tier["name"].to_lower(),
			"description": "Mejora el arco · +1 de daño"
		})
	var next_armor_tier := armor_tier_index + 1
	if next_armor_tier < GEAR_TIERS.size() and level >= int(GEAR_TIERS[next_armor_tier]["level"]):
		var armor_tier: Dictionary = GEAR_TIERS[next_armor_tier]
		upgrades.append({
			"id": "armor_tier",
			"tier_index": next_armor_tier,
			"name": "Armadura de %s" % armor_tier["name"].to_lower(),
			"description": "+%d puntos de armadura" % int(armor_tier["armor"])
		})
	return upgrades


func _get_powerup_upgrades() -> Array:
	var upgrades: Array = []
	for definition in POWERUP_DEFINITIONS:
		var powerup_id: String = definition["id"]
		var current_level := int(powerup_levels.get(powerup_id, 0))
		if current_level >= 5:
			continue
		var next_level := current_level + 1
		var description: String = definition["unlock_description"] if current_level == 0 else _powerup_upgrade_description(powerup_id, next_level)
		upgrades.append({
			"id": "powerup",
			"powerup_id": powerup_id,
			"level": next_level,
			"name": definition["name"] if current_level == 0 else "%s %s" % [definition["name"], _to_roman(next_level)],
			"description": description,
			"icon": definition["icon"]
		})
	return upgrades


func _powerup_upgrade_description(powerup_id: String, _next_level: int) -> String:
	match powerup_id:
		"axe":
			return "+1 de daño; añade hachas al nivel III y V."
		"sword":
			return "Más daño y cadencia; añade espadas extra en niveles III y V."
		"trident":
			return "+1 de daño y más radio; cae con mayor frecuencia."
	return "Mejora el poder y la frecuencia de ataque."


func _to_roman(value: int) -> String:
	var roman_numerals := ["I", "II", "III", "IV", "V"]
	return roman_numerals[clampi(value - 1, 0, roman_numerals.size() - 1)]


func _add_or_upgrade_powerup(powerup_id: String) -> void:
	var next_level := mini(5, int(powerup_levels.get(powerup_id, 0)) + 1)
	powerup_levels[powerup_id] = next_level
	var powerup: Node2D = powerup_instances.get(powerup_id) as Node2D
	if powerup == null or not is_instance_valid(powerup):
		var powerup_scene: PackedScene = POWERUP_SCENES.get(powerup_id) as PackedScene
		if powerup_scene == null:
			push_warning("No se encontró la escena del powerup: %s" % powerup_id)
			return
		powerup = powerup_scene.instantiate() as Node2D
		player.add_child(powerup)
		powerup_instances[powerup_id] = powerup
	powerup.call("set_level", next_level)


func _make_upgrade_button(upgrade: Dictionary) -> Button:
	if not upgrade.has("icon"):
		return _make_button("%s\n%s" % [upgrade["name"], upgrade["description"]])
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 78.0)
	button.focus_mode = Control.FOCUS_ALL
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40.0, 40.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = load(String(upgrade["icon"])) as Texture2D
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_column)
	var name_label := Label.new()
	name_label.text = String(upgrade["name"])
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(name_label)
	var description_label := Label.new()
	description_label.text = String(upgrade["description"])
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.add_child(description_label)
	return button


func _pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	_show_overlay("PAUSA", "WASD para moverte · Pulsa o mantén clic izquierdo/Z para disparar")
	_add_overlay_button("Continuar", _resume_game)
	_add_overlay_button("Reiniciar partida", _restart_run)
	_add_overlay_button("Salir al menú", _leave_run_to_menu)


func _resume_game() -> void:
	is_paused = false
	overlay.visible = false
	get_tree().paused = false


func _continue_endless_run() -> void:
	completion_overlay_open = false
	is_paused = false
	if spawner and spawner.has_method("set_active"):
		spawner.call("set_active", true)
	if spawner and spawner.has_method("set_endless_time"):
		spawner.call("set_endless_time", maxf(0.0, elapsed - RUN_DURATION))
	_next_boss_after_interval()
	overlay.visible = false
	get_tree().paused = false


func _next_boss_after_interval() -> void:
	next_boss_at = elapsed + RUN_DURATION


func _record_run_victory() -> int:
	var records := ConfigFile.new()
	if FileAccess.file_exists(RUN_RECORDS_PATH):
		records.load(RUN_RECORDS_PATH)
	victories = int(records.get_value("runs", "victories", 0)) + 1
	records.set_value("runs", "victories", victories)
	records.set_value("runs", "last_run_won", true)
	records.set_value("runs", "best_level_on_victory", maxi(level, int(records.get_value("runs", "best_level_on_victory", 1))))
	var save_error := records.save(RUN_RECORDS_PATH)
	if save_error != OK:
		push_warning("No se pudo guardar el registro de victorias: %s" % error_string(save_error))
	return victories


func _leave_run_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud_root)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(18.0, 18.0)
	status_panel.custom_minimum_size = Vector2(205.0, 0.0)
	status_panel.add_theme_stylebox_override("panel", _make_panel_style())
	hud_root.add_child(status_panel)
	var status := VBoxContainer.new()
	status.add_theme_constant_override("separation", 3)
	status_panel.add_child(status)
	time_label = _make_stat_label()
	kills_label = _make_stat_label()
	equipment_label = _make_stat_label()
	status.add_child(time_label)
	status.add_child(kills_label)
	status.add_child(equipment_label)

	powerup_inventory = HBoxContainer.new()
	powerup_inventory.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	powerup_inventory.offset_left = -230.0
	powerup_inventory.offset_top = 18.0
	powerup_inventory.offset_right = -18.0
	powerup_inventory.offset_bottom = 78.0
	powerup_inventory.alignment = BoxContainer.ALIGNMENT_END
	powerup_inventory.add_theme_constant_override("separation", 8)
	powerup_inventory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(powerup_inventory)

	minecraft_hud = MINECRAFT_HUD_SCRIPT.new() as Control
	hud_root.add_child(minecraft_hud)

	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(360.0, 20.0)
	boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_bar.offset_left = -180.0
	boss_bar.offset_top = 20.0
	boss_bar.offset_right = 180.0
	boss_bar.offset_bottom = 40.0
	boss_bar.show_percentage = false
	boss_bar.visible = false
	boss_bar.add_theme_color_override("font_color", Color.WHITE)
	hud_root.add_child(boss_bar)

	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	hud_root.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var overlay_panel := PanelContainer.new()
	overlay_panel.custom_minimum_size = Vector2(500.0, 0.0)
	overlay_panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(overlay_panel)

	overlay_content = VBoxContainer.new()
	overlay_content.add_theme_constant_override("separation", 12)
	overlay_panel.add_child(overlay_content)


func _make_stat_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	return label


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.045, 0.94)
	style.border_color = Color(0.34, 0.75, 0.24, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_top = 14.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	return style


func _make_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 62.0)
	button.add_theme_font_size_override("font_size", 16)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _show_overlay(title_text: String, description_text: String) -> void:
	for child in overlay_content.get_children():
		overlay_content.remove_child(child)
		child.queue_free()
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.65, 1.0, 0.35))
	overlay_content.add_child(title)
	var description := Label.new()
	description.text = description_text
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_content.add_child(description)
	overlay.visible = true


func _add_overlay_button(text_value: String, callback: Callable) -> void:
	var button := _make_button(text_value)
	button.pressed.connect(callback)
	overlay_content.add_child(button)


func _update_hud() -> void:
	if time_label == null:
		return
	var total_seconds := maxi(0, floori(elapsed))
	time_label.text = "TIEMPO  %02d:%02d" % [int(total_seconds / 60), total_seconds % 60]
	kills_label.text = "SLIMES  %d%s" % [kills, "  ·  INFINITO" if endless_mode else ""]
	equipment_label.text = "Arco %s · Arm. %s" % [GEAR_TIERS[weapon_tier_index]["name"], GEAR_TIERS[armor_tier_index]["name"]]
	if minecraft_hud and player:
		minecraft_hud.call("set_stats", int(player.get("health")), int(player.get("max_health")), int(player.get("armor_points")), experience, experience_to_next, level)


func _refresh_powerup_inventory() -> void:
	if powerup_inventory == null:
		return
	for child in powerup_inventory.get_children():
		powerup_inventory.remove_child(child)
		child.queue_free()
	for definition in POWERUP_DEFINITIONS:
		var powerup_id: String = definition["id"]
		var powerup_level := int(powerup_levels.get(powerup_id, 0))
		if powerup_level <= 0:
			continue
		var item := VBoxContainer.new()
		item.custom_minimum_size = Vector2(44.0, 58.0)
		item.add_theme_constant_override("separation", 0)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		powerup_inventory.add_child(item)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40.0, 40.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.texture = load(String(definition["icon"])) as Texture2D
		icon.tooltip_text = "%s · Nivel %s" % [definition["name"], _to_roman(powerup_level)]
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)
		var level_label := Label.new()
		level_label.text = "NIV. %s" % _to_roman(powerup_level)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 9)
		level_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.62))
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(level_label)
