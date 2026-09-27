extends Node2D

const playerScene = preload("res://scenes/player/player.tscn")
const enemyScene = preload("res://scenes/main/enemy.tscn")
const shotScene = preload("res://scenes/player/cannonball.tscn")

@export var player: CharacterBody2D
#@export var enemy: CharacterBody2D

var listOfEnemies: Array[Node2D] = []

func find_closest_enemy() -> Node2D:
	if listOfEnemies.is_empty() or not is_instance_valid(player):
		return null
	var shortest_distance: float = INF 
	var closest_enemy: Node2D
	
	for enemy in listOfEnemies:
		
		if is_instance_valid(enemy):
			var distance_sq = player.global_position.distance_squared_to(enemy.global_position)
			if distance_sq < shortest_distance:
				shortest_distance=distance_sq
				closest_enemy = enemy
	return closest_enemy

func spawn_enemy() -> void:
	print("Enemy spawned!")
	var new_enemy = enemyScene.instantiate()
	new_enemy.global_position.x = randi_range(0, 1150)
	new_enemy.global_position.y = player.global_position.y+randi_range(0, 647)
	print(new_enemy.global_position.x)
	print(new_enemy.global_position.y)
	add_child(new_enemy)
	listOfEnemies.append(new_enemy)
	
	
func _ready() -> void:
	var print_timer = Timer.new()
	print_timer.wait_time = 1.0 
	print_timer.autostart = true
	add_child(print_timer)
	
	var shot_timer = Timer.new()
	shot_timer.wait_time = 4.0 
	shot_timer.autostart = true
	add_child(shot_timer)
	
	var spawn_timer = Timer.new()
	spawn_timer.wait_time = 4.0 
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	#shot_timer.timeout.connect(_on_shot_timer_timeout)
	print_timer.timeout.connect(_on_print_timer_timeout)
	spawn_timer.timeout.connect(spawn_enemy)
	
func _on_shot_timer_timeout() -> void:
	var shot = shotScene.instantiate()
	print(shot)
	print(player)
	add_child(shot)
	shot.global_position = player.global_position
	shot.look_at(find_closest_enemy().global_position)

func _on_print_timer_timeout() -> void:
	# 3. Call your closest enemy function
	var closest = find_closest_enemy()
	
	if closest:
		# .global_position returns a Vector2 (X, Y) coordinate
		print("Closest Enemy coordinates: ", closest.global_position)
	else:
		print("No active enemies found on screen.")
	
