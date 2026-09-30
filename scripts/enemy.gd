extends CharacterBody2D

signal died(enemy)

@export var speed = 120

var max_hp = 20;
var hp = 20;
var player: Node2D

func _physics_process(_delta: float) -> void:
	# Find the ship tagged with "player" group
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		
		
	# Wait if the player isn't available yet.
	if not is_instance_valid(player):
		return
	
	# Move toward the player's current position
	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
func take_damage(amount: int):
	hp -= amount
	
	if hp <= 0:
		die()
		
func die() -> void: 
	# Prevent multiple death signals before Godot removes this enemy
	if is_queued_for_deletion():
		return
		
	died.emit(self) 
	print("AWESOME")
	queue_free()
