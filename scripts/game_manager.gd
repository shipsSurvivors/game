extends Node2D

const playerScene = preload("res://scenes/player/player.tscn")
const enemyScene = preload("res://scenes/main/enemy.tscn")
const shotScene = preload("res://scenes/player/cannonball.tscn")

const GAME_SCENE := preload("res://scenes/player/gameplay.tscn")
const TITLE_SCENE := preload("res://scenes/ui/title_screen.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over_screen.tscn")
const UPGRADE_SCENE := preload("res://scenes/ui/upgrade_screen.tscn")


@export var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var enemy2: CharacterBody2D

var damage: int = 5

# Attack speed is represented as a percentage multiplier.
# 100 means the default attack speed. Each upgrade adds 10%.
var attack_speed: int = 100

const BASE_SHOT_INTERVAL: float = 1.5

var listOfEnemies: Array[Node2D] = []
var level: int = 1
var xp: int = 0
var xp_needed: int = 2

# Seconds spent actively playing this voyage.
var survival_time: float = 0.0

# Finds the timer label inside the HUD.
@onready var survival_timer: Label = $HUD/SurvivalTimer

@export var enemy_respawn_time: float = 3.0
@export var enemy_spawn_radius: float = 500.0
@export var enemy_min_spawn_distance: float = 150.0

var game_over: bool = false

var game_over_screen: Control
var game_over_layer: CanvasLayer

var upgrade_screen: Control
var upgrade_layer: CanvasLayer
var shot_timer: Timer


@onready var xp_bar: ProgressBar = $HUD/XPDisplay/XPBar
@onready var xp_frame: TextureRect = $HUD/XPDisplay/Frame
@onready var xp_text: Label = $HUD/XPDisplay/XPText


const LEVEL_FRAMES = [
	preload("res://sprites/lvl_1_bar.png"),
	preload("res://sprites/lvl_2_bar.png"),
	preload("res://sprites/lvl_3_bar.png")
]


func _ready() -> void:
	# Keep this script active so it can detect Escape while paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	scale_enemies_to_level()

	# Timer used for printing enemy information.
	var print_timer = Timer.new()
	print_timer.wait_time = 1.0
	print_timer.autostart = true
	add_child(print_timer)

	# Timer used for automatically firing shots.
	shot_timer = Timer.new()
	shot_timer.wait_time = 1.5
	shot_timer.autostart = true
	add_child(shot_timer)

	shot_timer.timeout.connect(_on_shot_timer_timeout)
	print_timer.timeout.connect(_on_print_timer_timeout)

	update_xp_display()


func _unhandled_input(event: InputEvent) -> void:
	# Do not pause or resume during Game Over.
	if game_over:
		return

	# Press Escape to pause or resume.
	if event.is_action_pressed("ui_cancel"):
		_set_game_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_game_paused(should_pause: bool) -> void:
	# Pause or resume the SceneTree.
	get_tree().paused = should_pause

	# Stop or resume the player.
	if is_instance_valid(player):
		player.set_process(not should_pause)
		player.set_physics_process(not should_pause)

	# Stop or resume every enemy.
	for enemy_node in listOfEnemies:
		if is_instance_valid(enemy_node):
			enemy_node.set_process(not should_pause)
			enemy_node.set_physics_process(not should_pause)


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


func get_enemy_count_for_level() -> int:
	return level + 1


func scale_enemies_to_level() -> void:
	# Stop instead of repeatedly trying to spawn without a player.
	if not is_instance_valid(player):
		push_error("Assign Player on the Gameplay node in the Inspector.")
		return
		
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

	if not is_instance_valid(player):
		print("ERROR: Player is not valid, cannot spawn enemy.")
		return

	# Pick a random angle around the player.
	var angle := randf_range(0.0, TAU)

	# Pick a random distance around the player.
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


func _on_shot_timer_timeout() -> void:
	# Do not fire while paused or after Game Over.
	if game_over or get_tree().paused:
		return

	if not is_instance_valid(player):
		return

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

		# Pause the game and show the upgrade choices.
		_show_upgrade_screen()

		# One upgrade screen is shown for each level increase.
		# A normal enemy defeat can only increase the level once, but this
		# prevents multiple screens from being created in one loop.
		break

	update_xp_display()


func _show_upgrade_screen() -> void:
	# Do not create another upgrade screen if one is already open.
	if is_instance_valid(upgrade_screen):
		return

	_set_game_paused(true)

	upgrade_layer = CanvasLayer.new()
	upgrade_layer.name = "UpgradeLayer"
	upgrade_layer.layer = 90
	upgrade_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().current_scene.add_child(upgrade_layer)

	upgrade_screen = UPGRADE_SCENE.instantiate() as Control
	upgrade_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	upgrade_layer.add_child(upgrade_screen)
	upgrade_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Connect the signals emitted by upgrade_screen.gd.
	upgrade_screen.damage_pressed.connect(_on_damage_pressed)
	upgrade_screen.movementspeed_pressed.connect(_on_movementspeed_pressed)
	upgrade_screen.attackspeed_pressed.connect(_on_attackspeed_pressed)


func _close_upgrade_screen() -> void:
	if is_instance_valid(upgrade_layer):
		upgrade_layer.queue_free()

	upgrade_layer = null
	upgrade_screen = null


func _on_damage_pressed() -> void:
	damage += 5
	print("Damage upgraded to ", damage)
	_finish_upgrade()


func _on_movementspeed_pressed() -> void:
	if is_instance_valid(player):
		player.speed += 50.0
		print("Movement speed upgraded to ", player.speed)

	_finish_upgrade()


func _on_attackspeed_pressed() -> void:
	attack_speed += 100

	if is_instance_valid(shot_timer):
		shot_timer.wait_time = _get_shot_interval()

	print("Attack speed upgraded to ", attack_speed, "%")
	_finish_upgrade()


func _get_shot_interval() -> float:
	return BASE_SHOT_INTERVAL / (float(attack_speed) / 100.0)


func _finish_upgrade() -> void:
	_close_upgrade_screen()
	_set_game_paused(false)


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
		xp_frame.hide()


func _on_enemy_died(dead_enemy: Node2D) -> void:
	# Do not process enemy deaths while paused or after Game Over.
	if game_over or get_tree().paused:
		return

	if not listOfEnemies.has(dead_enemy):
		return

	listOfEnemies.erase(dead_enemy)

	# Award XP.
	add_xp(1)

	# Wait before spawning the replacement enemy.
	await get_tree().create_timer(enemy_respawn_time).timeout

	# Do not respawn enemies while paused or after Game Over.
	if game_over or get_tree().paused:
		return

	spawn_enemy()

func _process(delta: float) -> void:
	# This manager runs while paused, so explicitly stop the clock.
	if game_over or get_tree().paused:
		return

	survival_time += delta

	# Convert total seconds into minutes and remaining seconds.
	var total_seconds := int(survival_time)
	var minutes := int(total_seconds / 60.0)
	var seconds := total_seconds % 60

	# Pad both numbers with a zero: 00:09, 01:25, etc.
	survival_timer.text = "%02d:%02d" % [minutes, seconds]

func _on_player_died() -> void:
	# Prevent Game Over from triggering multiple times.
	if game_over:
		return

	game_over = true

	print("GAME OVER")

	# Stop the player, enemies, audio, and gameplay.
	_set_game_paused(true)

	# Create a UI layer above the gameplay.
	game_over_layer = CanvasLayer.new()
	game_over_layer.name = "GameOverLayer"
	game_over_layer.layer = 100
	game_over_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().current_scene.add_child(game_over_layer)

	# Create the Game Over screen.
	game_over_screen = GAME_OVER_SCENE.instantiate() as Control
	game_over_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	game_over_layer.add_child(game_over_screen)

	# Make the Game Over screen fill the viewport.
	game_over_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Make the CenterContainer fill the viewport.
	var center_container := game_over_screen.get_node("CenterContainer") as Control
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Connect the Game Over buttons.
	game_over_screen.retry_pressed.connect(_on_retry_pressed)
	game_over_screen.title_pressed.connect(_on_title_pressed)


func _close_game_over_screen() -> void:
	# Remove the Game Over UI layer.
	if is_instance_valid(game_over_layer):
		game_over_layer.queue_free()

	game_over_layer = null
	game_over_screen = null


func _on_retry_pressed() -> void:
	# Remove the Game Over screen.
	_close_game_over_screen()

	# Unpause before changing scenes.
	_set_game_paused(false)

	# Reload the gameplay scene.
	get_tree().change_scene_to_packed(GAME_SCENE)


func _on_title_pressed() -> void:
	# Remove the Game Over screen.
	_close_game_over_screen()

	# Unpause before changing scenes.
	_set_game_paused(false)

	# Return to the title screen.
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")


func _on_print_timer_timeout() -> void:
	if game_over or get_tree().paused:
		return

	var closest = find_closest_enemy()

	if closest:
		print("Closest Enemy coordinates: ", closest.global_position)
	else:
		print("No active enemies found on screen.")
		
