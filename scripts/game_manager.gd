extends Node2D

const playerScene = preload("res://scenes/player/player.tscn")
const enemyScene = preload("res://scenes/main/enemy.tscn")
const shotScene = preload("res://scenes/player/cannonball.tscn")

# Scenes used for Game Over and returning to the title screen.
const GAME_SCENE := preload("res://scenes/player/gameplay.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over_screen.tscn")


@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var enemy2: CharacterBody2D

# Crab with 20 health dies in 4 hits.
var damage: int = 5

var listOfEnemies: Array[Node2D] = []

# Level and XP.
var level: int = 1
var xp: int = 0
var xp_needed: int = 2

# Time before a killed enemy respawns.
@export var enemy_respawn_time: float = 3.0

# Enemy spawn settings.
# Enemies will spawn somewhere within this radius around the player.
@export var enemy_spawn_radius: float = 500.0

# Enemies will not spawn closer than this distance to the player.
@export var enemy_min_spawn_distance: float = 150.0

# Keeps track of whether the player has died.
var game_over: bool = false

# Reference to the Game Over UI.
var game_over_screen: Control


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
	# Remove invalid enemies from the list first.
	listOfEnemies = listOfEnemies.filter(
		func(enemy_node):
			return is_instance_valid(enemy_node)
	)

	if listOfEnemies.is_empty() or not is_instance_valid(player):
		return null

	var shortest_distance: float = INF
	var closest_enemy: Node2D

	for enemy_node in listOfEnemies:
		if is_instance_valid(enemy_node):
			var distance_sq = player.global_position.distance_squared_to(
				enemy_node.global_position
			)

			if distance_sq < shortest_distance:
				shortest_distance = distance_sq
				closest_enemy = enemy_node

	return closest_enemy


# Determines how many enemies should exist at each level.
#
# Level 1 = 2 enemies
# Level 2 = 3 enemies
# Level 3 = 4 enemies
# Level 4 = 5 enemies
# etc.
func get_enemy_count_for_level() -> int:
	return level + 1


# Makes sure the correct number of enemies exist.
func scale_enemies_to_level() -> void:
	var target_enemy_count := get_enemy_count_for_level()

	# Clean out invalid references first.
	listOfEnemies = listOfEnemies.filter(
		func(enemy_node):
			return is_instance_valid(enemy_node)
	)

	var current_enemy_count := listOfEnemies.size()

	print(
		"Enemy scaling - Level: ",
		level,
		" | Current enemies: ",
		current_enemy_count,
		" | Target enemies: ",
		target_enemy_count
	)

	# Spawn only the enemies we are missing.
	while listOfEnemies.size() < target_enemy_count:
		spawn_enemy()


func spawn_enemy() -> void:
	var instantiateEnemy = enemyScene.instantiate() as Node2D

	if instantiateEnemy == null:
		print("ERROR: Enemy scene could not be instantiated.")
		return

	# Make sure the player exists before using their position.
	if not is_instance_valid(player):
		print("ERROR: Player is not valid, cannot spawn enemy.")
		return

	# ---------------------------------------------------------
	# RANDOM SPAWN AROUND PLAYER
	# ---------------------------------------------------------

	# Pick a random angle around the player.
	var angle := randf_range(0.0, TAU)

	# Pick a random distance between the minimum
	# and maximum spawn radius.
	var distance := randf_range(
		enemy_min_spawn_distance,
		enemy_spawn_radius
	)

	# Convert the angle and distance into a Vector2.
	var spawn_offset := Vector2.from_angle(angle) * distance

	# Spawn relative to the player's current position.
	instantiateEnemy.global_position = player.global_position + spawn_offset

	# Add the enemy to the actual game scene.
	get_tree().current_scene.add_child(instantiateEnemy)

	# Add the enemy to our enemy list.
	listOfEnemies.append(instantiateEnemy)

	# Listen for the enemy's death.
	instantiateEnemy.died.connect(_on_enemy_died)

	print(
		"Spawned enemy at distance ",
		distance,
		" from player. Total enemies: ",
		listOfEnemies.size()
	)


func _ready() -> void:
	# Randomize positions used by randf_range().
	randomize()

	# Connect player death.
	if is_instance_valid(player):
		player.player_died.connect(_on_player_died)

	# Add the two enemies that already exist in the scene.
	if is_instance_valid(enemy):
		listOfEnemies.append(enemy)
		enemy.died.connect(_on_enemy_died)

	if is_instance_valid(enemy2):
		listOfEnemies.append(enemy2)
		enemy2.died.connect(_on_enemy_died)

	# Make sure Level 1 has the correct number of enemies.
	scale_enemies_to_level()

	# Timer used for printing enemy information.
	var print_timer = Timer.new()
	print_timer.wait_time = 1.0
	print_timer.autostart = true
	add_child(print_timer)

	# Timer used for automatically firing shots.
	var shot_timer = Timer.new()
	shot_timer.wait_time = 1.5
	shot_timer.autostart = true
	add_child(shot_timer)

	shot_timer.timeout.connect(_on_shot_timer_timeout)
	print_timer.timeout.connect(_on_print_timer_timeout)

	# Show the starting level and empty XP bar.
	update_xp_display()


func _on_shot_timer_timeout() -> void:
	# Don't fire after Game Over.
	if game_over:
		return

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

		print("Reached level ", level)

		# Increase the number of enemies for the new level.
		scale_enemies_to_level()

		# Each new level takes two more enemy defeats.
		xp_needed += 2

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
		xp_frame.hide()


func _on_enemy_died(dead_enemy: Node2D) -> void:
	# Don't process enemy deaths after Game Over.
	if game_over:
		return

	# Only reward an enemy that is still registered.
	if not listOfEnemies.has(dead_enemy):
		return

	listOfEnemies.erase(dead_enemy)

	# Award XP.
	add_xp(1)

	# Wait before spawning the replacement enemy.
	await get_tree().create_timer(enemy_respawn_time).timeout

	# Don't respawn enemies after Game Over.
	if game_over:
		return

	# Spawn the replacement.
	spawn_enemy()


func _on_player_died() -> void:
	# Prevent Game Over from triggering multiple times.
	if game_over:
		return

	game_over = true

	print("GAME OVER")

	# Stop all gameplay.
	get_tree().paused = true

	# Create the Game Over UI.
	game_over_screen = GAME_OVER_SCENE.instantiate()

	# Allow the Game Over UI to work while the game is paused.
	game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	get_tree().current_scene.add_child(game_over_screen)

	# Connect the Game Over buttons.
	game_over_screen.retry_pressed.connect(_on_retry_pressed)
	game_over_screen.title_pressed.connect(_on_title_pressed)


func _on_retry_pressed() -> void:
	# Unpause before changing scenes.
	get_tree().paused = false

	# Reload the gameplay scene.
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_title_pressed() -> void:
	# Unpause before changing scenes.
	get_tree().paused = false

	# Return to the title screen.
	get_tree().change_scene_to_packed(TITLE_SCENE)


func _on_print_timer_timeout() -> void:
	if game_over:
		return

	var closest = find_closest_enemy()

	if closest:
		print("Closest Enemy coordinates: ", closest.global_position)
	else:
		print("No active enemies found on screen.")
