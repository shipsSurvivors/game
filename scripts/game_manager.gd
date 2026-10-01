extends Node2D

const playerScene = preload("res://scenes/player/player.tscn")
const enemyScene = preload("res://scenes/main/enemy.tscn")
const shotScene = preload("res://scenes/player/cannonball.tscn")

@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var enemy2: CharacterBody2D

# Crab with 20 health dies in 4 hits
var damage: int = 5


var listOfEnemies: Array[Node2D] = []

# Small starting requirement so we can test with two crabs.
var level: int = 1
var xp: int = 0
var xp_needed: int = 2

# References to the fixed-screen HUD.
@onready var xp_bar: ProgressBar = $HUD/XPDisplay/XPBar
@onready var xp_frame: TextureRect = $HUD/XPDisplay/Frame
@onready var xp_text: Label = $HUD/XPDisplay/XPText

# Your artwork for the first three levels.
const LEVEL_FRAMES = [
	preload("res://sprites/lvl_1_bar.png"),
	preload("res://sprites/lvl_2_bar.png"),
	preload("res://sprites/lvl_3_bar.png")
]

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
	var instantiateEnemy = enemyScene.instantiate()
	instantiateEnemy.global_position.y = global_position.y+300
	listOfEnemies.append(instantiateEnemy)
	instantiateEnemy.died.connect(_on_enemy_died)
	
	
func _ready() -> void:
	listOfEnemies.append(enemy)
	enemy.died.connect(_on_enemy_died)
	listOfEnemies.append(enemy2)
	enemy2.died.connect(_on_enemy_died)
	
	var print_timer = Timer.new()
	print_timer.wait_time = 1.0 
	print_timer.autostart = true
	add_child(print_timer)
	
	var shot_timer = Timer.new()
	# Fire often enough to keep combat active.
	shot_timer.wait_time = 1.5
	shot_timer.autostart = true
	add_child(shot_timer)
	
	
	shot_timer.timeout.connect(_on_shot_timer_timeout)
	print_timer.timeout.connect(_on_print_timer_timeout)
	
		# Show the starting level and empty XP bar.
	update_xp_display()
	
func _on_shot_timer_timeout() -> void:
	if not is_instance_valid(player):
		return

	# Find a target once, then check it before firing.
	var target := find_closest_enemy()

	if not is_instance_valid(target):
		return

	var shot = shotScene.instantiate()
	shot.damage = damage
	add_child(shot)

	shot.global_position = player.global_position
	shot.look_at(target.global_position)

func add_xp(amount: int) -> void:
	xp += amount

	# Keep any extra XP when leveling up.
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1

		# Each new level takes two more enemy defeats.
		xp_needed += 2

		print("Reached level ", level)

	update_xp_display()


func update_xp_display() -> void:
	xp_bar.max_value = xp_needed
	xp_bar.value = xp

	xp_text.text = "Level %d • XP %d / %d" % [
		level, xp, xp_needed
	]

	# Use the matching numbered artwork while available.
	if level <= LEVEL_FRAMES.size():
		xp_frame.texture = LEVEL_FRAMES[level - 1]
		xp_frame.show()
	else:
		# Beyond level 3, keep the working bar and text.
		# Hide the artwork so it doesn't show the wrong level.
		xp_frame.hide()

func _on_enemy_died(dead_enemy: Node2D) -> void:
	# Only reward an enemy that is still registered.
	if not listOfEnemies.has(dead_enemy):
		return

	listOfEnemies.erase(dead_enemy)

	# Award XP directly for now; pickups can come later.
	add_xp(1)

func _on_print_timer_timeout() -> void:
	# 3. Call your closest enemy function
	var closest = find_closest_enemy()
	
	if closest:
		# .global_position returns a Vector2 (X, Y) coordinate
		print("Closest Enemy coordinates: ", closest.global_position)
	else:
		print("No active enemies found on screen.")
	
