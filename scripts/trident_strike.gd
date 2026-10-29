extends Node2D

const TRIDENT_TEXTURE: Texture2D = preload("res://images/slime_trident.svg")
const STRIKE_SPRITE_SCALE := Vector2(0.625, 0.625) # SVG 64 px -> 40 px, igual que el arco.

var strike_damage := 3
var splash_radius := 52.0
var has_impacted := false
var trident_sprite: Sprite2D
var lightning: Line2D


func _ready() -> void:
	z_index = 3
	trident_sprite = Sprite2D.new()
	trident_sprite.texture = TRIDENT_TEXTURE
	trident_sprite.scale = STRIKE_SPRITE_SCALE
	trident_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trident_sprite.position = Vector2(0.0, -128.0)
	add_child(trident_sprite)
	lightning = Line2D.new()
	lightning.points = PackedVector2Array([Vector2(-7.0, -12.0), Vector2(6.0, -2.0), Vector2(-5.0, 8.0), Vector2(2.0, 15.0)])
	lightning.width = 4.0
	lightning.default_color = Color(0.48, 1.0, 0.82, 1.0)
	lightning.visible = false
	add_child(lightning)


func activate(target_position: Vector2, damage: int, radius: float) -> void:
	global_position = target_position
	strike_damage = damage
	splash_radius = radius
	var tween := create_tween()
	tween.tween_property(trident_sprite, "position", Vector2.ZERO, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_impact)


func _impact() -> void:
	if has_impacted:
		return
	has_impacted = true
	for candidate in get_tree().get_nodes_in_group("Enemies"):
		var enemy := candidate as Node2D
		if enemy == null or enemy.is_queued_for_deletion() or not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to(enemy.global_position) <= splash_radius:
			enemy.call("take_damage", strike_damage)
	lightning.visible = true
	var fade := create_tween()
	fade.tween_property(lightning, "modulate:a", 0.0, 0.22)
	fade.tween_callback(queue_free)
