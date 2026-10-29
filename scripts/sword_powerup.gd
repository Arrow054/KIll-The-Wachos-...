extends Node2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/sword_projectile.tscn")
const SWORD_TEXTURE: Texture2D = preload("res://images/assets/dungeon_items/iron-sword.png")

var level := 1
var fire_timer := 0.7
var orbit_angle := 0.0
var orbit_radius := 60.0
var orbiting_swords: Array[Sprite2D] = []


func _ready() -> void:
	set_level(level)


func set_level(value: int) -> void:
	level = clampi(value, 1, 5)
	var desired_count := mini(3, 1 + floori(float(level - 1) / 2.0))
	if desired_count != orbiting_swords.size():
		_rebuild_orbiting_swords(desired_count)


func _process(delta: float) -> void:
	orbit_angle += delta * 2.2
	_position_orbiting_swords()
	fire_timer -= delta
	if fire_timer > 0.0:
		return
	var interval := maxf(0.75, 2.3 - float(level - 1) * 0.22)
	fire_timer = interval
	_launch_swords()

func _launch_swords() -> void:
	for index in orbiting_swords.size():
		var orbit_offset := Vector2.RIGHT.rotated(orbit_angle + TAU * float(index) / float(orbiting_swords.size())) * orbit_radius
		var projectile := PROJECTILE_SCENE.instantiate() as Area2D
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + orbit_offset
		var projectile_damage := 1 + floori(float(level - 1) / 2.0)
		projectile.call("launch_in_direction", orbit_offset.normalized(), projectile_damage)


func _rebuild_orbiting_swords(count: int) -> void:
	for sword in orbiting_swords:
		sword.queue_free()
	orbiting_swords.clear()
	for _index in count:
		var sword := Sprite2D.new()
		sword.texture = SWORD_TEXTURE
		sword.scale = Vector2(2.5, 2.5) # 16 px -> 40 px, igual que el arco.
		sword.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sword.z_index = 2
		add_child(sword)
		orbiting_swords.append(sword)
	_position_orbiting_swords()


func _position_orbiting_swords() -> void:
	for index in orbiting_swords.size():
		var angle := orbit_angle + TAU * float(index) / float(orbiting_swords.size())
		orbiting_swords[index].position = Vector2.RIGHT.rotated(angle) * orbit_radius
		orbiting_swords[index].rotation = angle + PI * 0.25
