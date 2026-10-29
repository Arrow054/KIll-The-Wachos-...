extends CharacterBody2D

const PLAYER_IDLE_TEXTURE: Texture2D = preload("res://images/assets/adventurer/adventurer-idle-00.png")
const PLAYER_RUN_TEXTURE: Texture2D = preload("res://images/assets/adventurer/adventurer-run-00.png")
const PLAYER_HURT_TEXTURE: Texture2D = preload("res://images/assets/adventurer/adventurer-hurt-00.png")

@export var SPEED := 200.0
@export var knockback_force := 300.0
@export var knockback_duration := 0.2
@export var invulnerable_time := 0.5
@export var weapon_damage := 1
@export var weapon_fire_interval := 0.35
@export var max_health := 20

var alive := true
var health := 20
var armor_points := 0
var can_take_damage := true
var knockback_velocity := Vector2.ZERO
var knockback_time := 0.0


func _ready() -> void:
	add_to_group("player")
	max_health = maxi(2, max_health)
	health = mini(health, max_health)
	var old_health_hud := get_node_or_null("barra_vida") as CanvasLayer
	if old_health_hud:
		old_health_hud.visible = false


func _physics_process(delta: float) -> void:
	if not alive:
		return
	if knockback_time > 0.0:
		velocity = knockback_velocity
		knockback_time = maxf(0.0, knockback_time - delta)
	else:
		velocity = Input.get_vector("left", "right", "up", "down") * SPEED
	$PlayerSprite.texture = PLAYER_RUN_TEXTURE if velocity.length_squared() > 1.0 else PLAYER_IDLE_TEXTURE
	move_and_slide()


func take_damage(amount: int) -> void:
	if not alive or not can_take_damage or health <= 0:
		return
	can_take_damage = false
	$CollisionShape2D.set_deferred("disabled", true)
	var armor_reduction := clampf(float(armor_points) * 0.04, 0.0, 0.8)
	var damage_after_armor := maxi(1, ceili(float(amount) * (1.0 - armor_reduction)))
	health = maxi(health - damage_after_armor, 0)

	$PlayerSprite.texture = PLAYER_HURT_TEXTURE
	$PlayerSprite.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree():
		return
	$PlayerSprite.modulate = Color.WHITE
	$PlayerSprite.texture = PLAYER_IDLE_TEXTURE

	if health <= 0:
		die()
		return

	await get_tree().create_timer(invulnerable_time).timeout
	if not is_inside_tree() or not alive:
		return
	can_take_damage = true
	$CollisionShape2D.set_deferred("disabled", false)


func apply_knockback(from_position: Vector2) -> void:
	if not alive:
		return
	var direction := (global_position - from_position).normalized()
	direction.y -= 0.2
	knockback_velocity = direction.normalized() * knockback_force
	knockback_time = knockback_duration


func die() -> void:
	if not alive:
		return
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	var manager := get_tree().get_first_node_in_group("run_manager")
	if manager:
		manager.call("end_run")
	else:
		get_tree().reload_current_scene()
