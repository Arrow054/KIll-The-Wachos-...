extends Node2D

const BULLET_SCENE: PackedScene = preload("res://scenes/bala.tscn")

var player
var fire_cooldown := 0.0


func _ready() -> void:
	player = get_parent().get_parent()


func _process(delta: float) -> void:
	if player == null or not player.get("alive"):
		return
	look_at(get_global_mouse_position())
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if Input.is_action_pressed("attack") and fire_cooldown <= 0.0:
		fire_cooldown = player.get("weapon_fire_interval")
		var bullet = BULLET_SCENE.instantiate()
		bullet.set("damage", player.get("weapon_damage"))
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = global_position
		bullet.global_rotation = global_rotation
