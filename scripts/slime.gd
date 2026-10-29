extends CharacterBody2D

@export var move_speed := 120.0
@export var max_health := 2
@export var contact_damage := 1
@export var experience_reward := 1
@export var split_on_death := false
@export var split_scene: PackedScene
@export var is_boss := false

var health := 2
var target: Node2D
var can_attack := true
var is_dead := false


func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player") as Node2D
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		_start_idle_animation(sprite)


func _start_idle_animation(sprite: Sprite2D) -> void:
	var original_scale := sprite.scale
	var stretch := original_scale * Vector2(1.06, 0.93)
	var squash := original_scale * Vector2(0.94, 1.07)
	var idle_tween := create_tween().set_loops()
	idle_tween.tween_property(sprite, "scale", stretch, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(sprite, "scale", squash, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(sprite, "scale", original_scale, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _physics_process(_delta: float) -> void:
	if is_dead or target == null or not target.is_in_group("player"):
		return
	if target.get("alive") == false:
		return

	velocity = global_position.direction_to(target.global_position) * move_speed
	move_and_slide()

	if can_attack:
		for index in get_slide_collision_count():
			var collision := get_slide_collision(index)
			var body := collision.get_collider() as Node
			if body and body.is_in_group("player") and body.has_method("take_damage"):
				can_attack = false
				body.call("take_damage", contact_damage)
				if body.has_method("apply_knockback"):
					body.call("apply_knockback", global_position)
				get_tree().create_timer(0.7).timeout.connect(_on_attack_cooldown_finished)
				break


func take_damage(amount: int) -> void:
	if is_dead:
		return
	health = maxi(health - amount, 0)
	if health == 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO

	var manager := get_tree().get_first_node_in_group("run_manager")
	if manager:
		manager.call("register_kill")

	if split_on_death and split_scene and get_tree().current_scene:
		_spawn_fragments()

	if experience_reward > 0 and get_tree().current_scene:
		var orb_scene: PackedScene = preload("res://scenes/xp_pickup.tscn")
		var orb := orb_scene.instantiate() as Area2D
		orb.set("value", experience_reward)
		get_tree().current_scene.add_child(orb)
		orb.global_position = global_position

	if is_boss and manager:
		manager.call("on_boss_defeated")

	queue_free()


func _spawn_fragments() -> void:
	var scene_root := get_tree().current_scene
	for index in 2:
		var fragment := split_scene.instantiate() as Node2D
		scene_root.add_child(fragment)
		var angle := TAU * float(index) / 2.0 + randf_range(-0.3, 0.3)
		fragment.global_position = global_position + Vector2.RIGHT.rotated(angle) * 28.0


func _on_attack_cooldown_finished() -> void:
	if is_inside_tree() and not is_dead:
		can_attack = true
