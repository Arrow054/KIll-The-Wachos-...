extends CanvasLayer

# Guardamos todos los AnimatedSprite2D en una lista
@onready var corazones = [
	$"HBoxContainer/TextureRect/AnimatedSprite2D-1",
	$"HBoxContainer/TextureRect2/AnimatedSprite2D-2",
	$"HBoxContainer/TextureRect3/AnimatedSprite2D-3",
	$"HBoxContainer/TextureRect4/AnimatedSprite2D-4"
]

func actualizar_vida(vida_actual: int):
	for i in range(corazones.size()):
		if i < vida_actual:
			corazones[i].play("con_vida") # Si el índice es menor a la vida, slime verde
		else:
			corazones[i].play("sin_vida") # Si no, sprite de vida quitada