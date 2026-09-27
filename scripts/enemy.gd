extends CharacterBody2D

@export var speed = 400

signal died(enemy)

var target = position
var max_hp = 20;
var hp = 20;

# ENEMY WILL MOVE WHERE YOU CLICK; ONLY FOR DEBUGGING, NOT INTENDED FOR FINAL GAME

func _input(event):
	# Use is_action_pressed to only accept single taps as input instead of mouse drags.
	# print(event)
	if event.is_action_pressed("click"):
		target = get_global_mouse_position()
	if event.is_action_pressed("die"):
		die()


func _physics_process(delta: float):
	velocity = position.direction_to(target) * speed
	# look_at(target)
	if position.distance_to(target) > 10:
		move_and_slide()
func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()
		
func die(): 
	died.emit(self) 
	print("AWESOME")
	queue_free()
