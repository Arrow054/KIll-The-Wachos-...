extends Area2D

const SWORD_TEXTURE: Texture2D = preload("res://images/assets/dungeon_items/iron-sword.png")

@export var speed := 360.0
@export var lifetime := 2.5
var damage := 1
var direction := Vector2.RIGHT


func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = SWORD_TEXTURE
	sprite.scale = Vector2(2.5, 2.5) # 16 px -> 40 px, igual que el arco.
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


func launch_in_direction(launch_direction: Vector2, hit_damage: int) -> void:
	damage = hit_damage
	direction = launch_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_rotation = direction.angle() + PI * 0.25


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()
