extends Node2D

const playerScene = preload("res://scenes/player/player.tscn")
const enemyScene = preload("res://scenes/main/enemy.tscn")
const shotScene = preload("res://scenes/player/cannonball.tscn")

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
var pending_upgrades: int = 0


@onready var xp_bar: ProgressBar = $HUD/XPDisplay/XPBar
@onready var xp_frame: TextureRect = $HUD/XPDisplay/Frame
@onready var xp_text: Label = $HUD/XPDisplay/XPText

# Special enemies introduced during the voyage.
const CRAB_BOSS_SCENE = preload(
	"res://scenes/main/crab_miniboss.tscn"
)
const SEAGULL_BOSS_SCENE = preload(
	"res://scenes/main/seagull_miniboss.tscn"
)

# Regular ships spawn independently of player level.
var enemy_spawn_clock: float = 3.0
@export var max_regular_enemies: int = 60

# First arrival times.
var next_crab_time: float = 60.0
var next_seagull_time: float = 120.0

# Repeat intervals shrink after each arrival.
var crab_spawn_interval: float = 90.0
var seagull_spawn_interval: float = 120.0

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
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.player_died.connect(_on_player_died)

	# Add the two enemies that already exist in the scene.
	if is_instance_valid(enemy):
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		listOfEnemies.append(enemy)
		enemy.died.connect(_on_enemy_died)

	if is_instance_valid(enemy2):
		enemy2.process_mode = Node.PROCESS_MODE_PAUSABLE
		listOfEnemies.append(enemy2)
		enemy2.died.connect(_on_enemy_died)

	# Timer used for printing enemy information.
	var print_timer = Timer.new()
	print_timer.wait_time = 1.0
	print_timer.autostart = true
	add_child(print_timer)

	# Timer used for automatically firing shots.
	shot_timer = Timer.new()
	shot_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	shot_timer.wait_time = 1.5
	shot_timer.autostart = true
	add_child(shot_timer)

	shot_timer.timeout.connect(_on_shot_timer_timeout)
	print_timer.timeout.connect(_on_print_timer_timeout)

	update_xp_display()


func _unhandled_input(event: InputEvent) -> void:
	# Required upgrade choices and Game Over cannot be dismissed with Escape.
	if game_over or pending_upgrades > 0 or is_instance_valid(upgrade_screen):
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

func spawn_enemy() -> void:
	var instantiateEnemy = enemyScene.instantiate() as Node2D

	if instantiateEnemy == null:
		print("ERROR: Enemy scene could not be instantiated.")
		return

	if not is_instance_valid(player):
		print("ERROR: Player is not valid, cannot spawn enemy.")
		instantiateEnemy.free()
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
	instantiateEnemy.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	shot.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(shot)

	shot.global_position = player.global_position
	shot.look_at(target.global_position)


func add_xp(amount: int) -> void:
	if game_over:
		return
	xp += amount

	# Keep any extra XP when leveling up.
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1

		print("Reached level ", level)

		# Each new level takes two more enemy defeats.
		xp_needed += 2

		# Boss rewards can earn several levels. Queue every choice.
		pending_upgrades += 1

	update_xp_display()
	if pending_upgrades > 0:
		# Enemy deaths can originate in a physics callback.
		# Add the upgrade controls after that callback has finished.
		call_deferred("_show_upgrade_screen")


func _show_upgrade_screen() -> void:
	if game_over or pending_upgrades <= 0:
		return
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
	pending_upgrades = maxi(0, pending_upgrades - 1)
	if pending_upgrades > 0:
		_show_upgrade_screen()
	else:
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
	if game_over:
		return

	if not listOfEnemies.has(dead_enemy):
		return

	listOfEnemies.erase(dead_enemy)

	# Bosses award more XP than ordinary ships.
	if dead_enemy.is_in_group("minibosses"):
		add_xp(5)
	else:
		add_xp(1)

	# No replacement here.
	# The timed spawner controls all future arrivals.

func spawn_miniboss(scene: PackedScene, boss_name: String) -> void:
	if game_over or not is_instance_valid(player):
		return

	var boss = scene.instantiate()
	boss.name = boss_name
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Allows the spawner to distinguish bosses from regular ships.
	boss.add_to_group("minibosses")

	# Pick a position just outside the current camera view.
	var screen_size := get_viewport_rect().size
	var margin := 160.0
	var screen_position := Vector2.ZERO

	match randi_range(0, 3):
		0:
			screen_position = Vector2(
				-margin, randf_range(0.0, screen_size.y)
			)
		1:
			screen_position = Vector2(
				screen_size.x + margin,
				randf_range(0.0, screen_size.y)
			)
		2:
			screen_position = Vector2(
				randf_range(0.0, screen_size.x), -margin
			)
		3:
			screen_position = Vector2(
				randf_range(0.0, screen_size.x),
				screen_size.y + margin
			)

	# Convert the screen position into the gameplay world's coordinates.
	var world_position := (
		get_viewport().get_canvas_transform().affine_inverse()
		* screen_position
	)

	boss.position = to_local(world_position)

	# Include the boss in cannon targeting, pausing, and death handling.
	listOfEnemies.append(boss)
	boss.died.connect(_on_enemy_died)
	add_child(boss)

	print("MINIBOSS ARRIVED: ", boss_name)

func _process(delta: float) -> void:
	# This manager runs while paused, so explicitly stop the clock.
	if game_over or get_tree().paused:
		return

	survival_time += delta
	# Spawn regular ships more frequently as the voyage continues.
	enemy_spawn_clock -= delta

	if enemy_spawn_clock <= 0.0:
		# Shorten the interval by 0.4 seconds per minute.
		# Never spawn faster than one ship every 0.75 seconds.
		var spawn_interval := maxf(
			0.75,
			3.0 - (survival_time / 60.0) * 0.4
		)

		enemy_spawn_clock = spawn_interval

		# Count regular ships separately from minibosses.
		var regular_count := 0

		for enemy_node in listOfEnemies:
			if is_instance_valid(enemy_node):
				if not enemy_node.is_in_group("minibosses"):
					regular_count += 1

		if regular_count < max_regular_enemies:
			spawn_enemy()

	# Repeated crab arrivals, with progressively shorter gaps.
	if survival_time >= next_crab_time:
		spawn_miniboss(CRAB_BOSS_SCENE, "CrabMiniboss")

		next_crab_time = survival_time + crab_spawn_interval
		crab_spawn_interval = maxf(
			45.0, crab_spawn_interval - 15.0
		)

	# Seagulls start later and repeat less frequently.
	if survival_time >= next_seagull_time:
		spawn_miniboss(SEAGULL_BOSS_SCENE, "SeagullMiniboss")

		next_seagull_time = survival_time + seagull_spawn_interval
		seagull_spawn_interval = maxf(
			60.0, seagull_spawn_interval - 15.0
		)
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
	get_tree().change_scene_to_file("res://scenes/player/gameplay.tscn")


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
		
