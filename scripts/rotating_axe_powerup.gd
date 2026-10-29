extends Node2D

const AXE_TEXTURE: Texture2D = preload("res://images/rotating_axe.svg")
const WORLD_SPRITE_SCALE := Vector2(0.625, 0.625) # SVG 64 px -> 40 px, igual que el arco.

var level := 1
var damage := 2
var orbit_radius := 62.0
var spin_speed := 2.8
var hit_cooldowns: Dictionary = {}
var axe_sprites: Array[Sprite2D] = []
var axe_areas: Array[Area2D] = []


func _ready() -> void:
	_build_axes(1)
	set_level(level)


func set_level(value: int) -> void:
	level = clampi(value, 1, 5)
	damage = level + 1
	spin_speed = 2.8 + float(level - 1) * 0.3
	var desired_count := mini(3, 1 + floori(float(level - 1) / 2.0))
	if desired_count != axe_sprites.size():
		_build_axes(desired_count)


func _process(delta: float) -> void:
	rotation += spin_speed * delta
	for enemy_id in hit_cooldowns.keys():
		var cooldown := maxf(0.0, float(hit_cooldowns[enemy_id]) - delta)
		if cooldown <= 0.0:
			hit_cooldowns.erase(enemy_id)
		else:
			hit_cooldowns[enemy_id] = cooldown
	_position_axes()


func _build_axes(count: int) -> void:
	for sprite in axe_sprites:
		sprite.queue_free()
	for area in axe_areas:
		area.queue_free()
	axe_sprites.clear()
	axe_areas.clear()
	for _index in count:
		var sprite := Sprite2D.new()
		sprite.texture = AXE_TEXTURE
		sprite.scale = WORLD_SPRITE_SCALE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 2
		add_child(sprite)
		axe_sprites.append(sprite)

		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 2
		area.monitoring = true
		area.monitorable = false
		var shape_node := CollisionShape2D.new()
		var hit_shape := CircleShape2D.new()
		hit_shape.radius = 10.0
		shape_node.shape = hit_shape
		area.add_child(shape_node)
		area.body_entered.connect(_on_axe_body_entered)
		add_child(area)
		axe_areas.append(area)
	_position_axes()


func _position_axes() -> void:
	var count := axe_sprites.size()
	if count == 0:
		return
	for index in count:
		var angle := TAU * float(index) / float(count)
		var offset := Vector2.RIGHT.rotated(angle) * orbit_radius
		axe_sprites[index].position = offset
		axe_sprites[index].rotation = 0.0
		axe_areas[index].position = offset


func _on_axe_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Enemies") or not body.has_method("take_damage"):
		return
	var enemy_id := body.get_instance_id()
	if hit_cooldowns.has(enemy_id):
		return
	hit_cooldowns[enemy_id] = 0.55
	body.call("take_damage", damage)
