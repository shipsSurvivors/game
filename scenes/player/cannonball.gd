extends Area2D

@export var velocity: int = 5
@export var damage: int = 5

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 3.0 
	timer.autostart = true
	add_child(timer)
	
	timer.timeout.connect(_on_timer_timeout)
	
func _on_body_entered(body: Node2D) -> void:
	# Check if the enemy has a take_damage method
	print(body)
	print("help")
	if body.has_method("take_damage"):
		body.take_damage(damage) 
		queue_free()
	
func _on_timer_timeout() -> void:
	queue_free()

func _process(delta: float) -> void:
	global_position += transform.x * velocity
