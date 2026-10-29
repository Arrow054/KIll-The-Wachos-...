extends Node2D

const STRIKE_SCENE: PackedScene = preload("res://scenes/trident_strike.tscn")

var level := 1
var fire_timer := 1.8


func set_level(value: int) -> void:
	level = clampi(value, 1, 5)


func _process(delta: float) -> void:
	fire_timer -= delta
	if fire_timer > 0.0:
		return
	var target := _find_target()
	if target == null:
		fire_timer = 0.5
		return
	fire_timer = maxf(1.5, 3.6 - float(level - 1) * 0.35)
	var strike := STRIKE_SCENE.instantiate() as Node2D
	get_tree().current_scene.add_child(strike)
	strike.call("activate", target.global_position, 3 + level - 1, 52.0 + float(level - 1) * 10.0)


func _find_target() -> Node2D:
	var closest: Node2D
	var closest_distance := 600.0 * 600.0
	for candidate in get_tree().get_nodes_in_group("Enemies"):
		var enemy := candidate as Node2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared < closest_distance:
			closest = enemy
			closest_distance = distance_squared
	return closest
