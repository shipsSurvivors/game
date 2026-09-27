extends Area2D

@export var velocity: int = 5

func _process(float) -> void:
	position.x += velocity
