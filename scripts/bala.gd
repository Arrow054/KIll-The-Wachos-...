extends Area2D

@export var speed := 500.0
@export var damage := 1
@export var lifetime := 2.0

func _on_body_entered(body) -> void:
	if body.is_in_group("Enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta
