extends Area2D

@export var value := 1
@export var attraction_radius := 170.0
@export var attraction_speed := 340.0

var player: Node2D
var run_manager


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	run_manager = get_tree().get_first_node_in_group("run_manager")
	body_entered.connect(_on_body_entered)
	_start_orb_animation()


func _start_orb_animation() -> void:
	var bob := create_tween().set_loops()
	bob.tween_property($Orb, "position:y", -3.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property($Orb, "position:y", 3.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var pulse := create_tween().set_loops()
	pulse.tween_property($Core, "scale", Vector2(1.25, 1.25), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property($Core, "scale", Vector2(0.8, 0.8), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var glow := get_node_or_null("Glow") as PointLight2D
	if glow:
		var light_pulse := create_tween().set_loops()
		light_pulse.tween_property(glow, "energy", 1.15, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		light_pulse.tween_property(glow, "energy", 0.55, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		return
	var magnet_range := attraction_radius
	if run_manager:
		magnet_range += run_manager.get("magnet_bonus")
	if global_position.distance_to(player.global_position) <= magnet_range:
		global_position = global_position.move_toward(player.global_position, attraction_speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var manager := get_tree().get_first_node_in_group("run_manager")
	if manager:
		manager.call("gain_experience", value)
	queue_free()
