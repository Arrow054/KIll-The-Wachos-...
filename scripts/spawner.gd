extends Node2D

# ---------------- ENEMY SETTINGS ----------------

@export var enemy1_scene: PackedScene
@export var medium_enemy_scene: PackedScene
@export var enemy2_scene: PackedScene

@export var spawn_timer_sec := 2.8
@export var medium_spawn_chance := 0.28
@export var large_spawn_chance := 0.12
@export var safe_radius := 300.0
@export var maximum_enemies := 90

# ---------------- INTERNAL ----------------

@onready var camera: Camera2D = get_viewport().get_camera_2d()
@onready var timer: Timer = $Timer


func _ready():
	add_to_group("enemy_spawner")
	if camera == null:
		push_error("No Camera2D found! Spawner will not work.")
		return
	timer.stop()
	timer.wait_time = spawn_timer_sec
	timer.one_shot = false
	timer.start()


func set_run_progress(progress: float) -> void:
	var normalized_progress := clampf(progress, 0.0, 1.0)
	timer.wait_time = lerpf(spawn_timer_sec, 0.65, normalized_progress)
	medium_spawn_chance = lerpf(0.28, 0.4, normalized_progress)
	large_spawn_chance = lerpf(0.12, 0.33, normalized_progress)


func set_endless_time(seconds_since_victory: float) -> void:
	var minutes := maxf(0.0, seconds_since_victory / 60.0)
	timer.wait_time = maxf(0.22, 0.65 - minutes * 0.025)
	medium_spawn_chance = minf(0.6, 0.4 + minutes * 0.025)
	large_spawn_chance = minf(0.58, 0.33 + minutes * 0.02)
	maximum_enemies = mini(180, 90 + int(minutes * 4.0))


func set_active(active: bool) -> void:
	if active:
		timer.start()
	else:
		timer.stop()


# ---------------- SPAWN FUNCTION ----------------

func _on_timer_timeout() -> void:
	if camera == null or get_tree().get_nodes_in_group("Enemies").size() >= maximum_enemies:
		return

	# Los slimes grandes y medianos aparecen cada vez más a menudo.
	var roll := randf()
	var enemy_scene_to_spawn: PackedScene

	if roll < large_spawn_chance:
		enemy_scene_to_spawn = enemy2_scene
	elif roll < large_spawn_chance + medium_spawn_chance:
		enemy_scene_to_spawn = medium_enemy_scene
	else:
		enemy_scene_to_spawn = enemy1_scene
	if enemy_scene_to_spawn == null:
		return

	var enemy = enemy_scene_to_spawn.instantiate()

	# Aparecen justo fuera de la cámara y nunca dentro del radio seguro.
	var half_size := get_viewport_rect().size * 0.5 / camera.zoom
	var direction := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var horizontal_edge := half_size.x / maxf(absf(direction.x), 0.001)
	var vertical_edge := half_size.y / maxf(absf(direction.y), 0.001)
	var distance_to_edge := minf(horizontal_edge, vertical_edge)
	var distance := maxf(safe_radius, distance_to_edge) + 64.0
	var spawn_pos := camera.get_screen_center_position() + direction * distance

	# Add enemy to current scene
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
