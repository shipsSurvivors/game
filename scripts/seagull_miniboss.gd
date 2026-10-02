extends CharacterBody2D

signal died(enemy)


@export var speed = 180

var max_hp = 20
var hp = 20
var player: Node2D

# ---------------------------------------------------------
# PLAYER DAMAGE SETTINGS
# ---------------------------------------------------------

# How much damage this enemy does to the player.
@export var damage: int = 30

# How often the enemy can damage the player.
@export var damage_cooldown: float = 1.0

# Keeps track of the damage cooldown.
var damage_timer: float = 0.0


# Find this enemy's own health bar.
@onready var health_bar: ProgressBar = $HealthBar

# Use the animated seagull for movement visuals and hit flashes.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var normal_tint: Color = $AnimatedSprite2D.self_modulate

# Stores the current flash so repeated hits can restart it.
var hit_tween: Tween

# Which part of the swoop the bird is performing.
var flight_state: String = "follow"

# Time remaining before changing flight behavior.
var flight_timer: float = 2.0

# Remember the direction before swooping.
# The bird won't steer toward you during the swoop.
var swoop_direction: Vector2 = Vector2.RIGHT

# Position the bird returns toward after swooping.
var swoop_start: Vector2 = Vector2.ZERO

@export var swoop_speed: float = 500.0
@export var return_speed: float = 350.0

func _ready() -> void:
	# Start each enemy at full health.
	hp = max_hp

	# Match the bar's range to this enemy's health.
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp
	
	# Boss health is visible immediately.
	health_bar.show()

	# Loop the seagull's animation.
	sprite.play("flap")

	# Start each seagull at a different point in the animation,
	# so the whole group doesn't move in perfect sync.
	sprite.set_frame_and_progress(
		randi_range(
			0,
			sprite.sprite_frames.get_frame_count("flap") - 1
		),
		randf()
	)


func _physics_process(delta: float) -> void:
	# Each bird keeps its own contact-damage cooldown.
	damage_timer = maxf(0.0, damage_timer - delta)

	# Find the player if we haven't found them yet.
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if not is_instance_valid(player):
		return

	flight_timer -= delta

	var direction := global_position.direction_to(
		player.global_position
	)

	match flight_state:
		"follow":
			velocity = direction * speed

			# Only prepare a swoop when reasonably close.
			if flight_timer <= 0.0 and global_position.distance_to(
				player.global_position
			) < 500.0:
				swoop_start = global_position
				swoop_direction = direction

				flight_state = "prepare"
				flight_timer = 0.4
				velocity = Vector2.ZERO

		"prepare":
			# Brief pause gives the player a chance to dodge.
			velocity = Vector2.ZERO

			if flight_timer <= 0.0:
				flight_state = "swoop"
				flight_timer = 0.9

		"swoop":
			# Fly along the locked direction without steering.
			velocity = swoop_direction * swoop_speed

			if flight_timer <= 0.0:
				flight_state = "return"
				flight_timer = 1.4
				velocity = Vector2.ZERO

		"return":
			# Head back toward where the swoop started.
			velocity = global_position.direction_to(
				swoop_start
			) * return_speed

			if global_position.distance_to(swoop_start) < 20.0 \
					or flight_timer <= 0.0:
				flight_state = "follow"
				flight_timer = 2.0
				velocity = Vector2.ZERO

	# Move freely through other enemies.
	global_position += velocity * delta

	# Face the direction of flight.
	# During preparation, face the planned swoop direction.
	var facing := velocity
	if flight_state == "prepare":
		facing = swoop_direction

	sprite.rotation = 0.0

	if facing.x > 0.05:
		sprite.flip_h = true
	elif facing.x < -0.05:
		sprite.flip_h = false

	# Keep the existing contact-damage behavior.
	attack_player()

	# Refresh the swoop warning every frame.
	queue_redraw()


func attack_player() -> void:
	if not is_instance_valid(player):
		return

	# Distance between the enemy and player.
	var distance_to_player := global_position.distance_to(player.global_position)

	# How close the enemy needs to be before attacking.
	var attack_distance := 50.0

	# Don't attack until we're close enough.
	if distance_to_player > attack_distance:
		return

	# Don't attack while the cooldown is active.
	if damage_timer > 0:
		return

	# Make sure the player actually has take_damage().
	if player.has_method("take_damage"):
		player.take_damage(damage)

		print("Enemy attacked player for ", damage, " damage!")

		# Start the damage cooldown.
		damage_timer = damage_cooldown


func flash_on_hit() -> void:
	# Stop any previous flash before starting another.
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()

	# Values above 1 brighten the sprite's colors.
	# Tint the seagull red, then let the existing tween restore its color.
	sprite.self_modulate = Color(
		1.0,
		0.25,
		0.25,
		normal_tint.a
	)
	
	# Fade back to the original color over 0.15 seconds.
	hit_tween = create_tween()
	hit_tween.tween_property(
		sprite,
		"self_modulate",
		normal_tint,
		0.15
	)


func take_damage(amount: int) -> void:
	# Ignore hits after death and amounts that cause no damage.
	if is_queued_for_deletion() or amount <= 0:
		return

	hp = maxi(hp - amount, 0)

	health_bar.value = hp
	health_bar.visible = hp > 0 and hp < max_hp

	if hp <= 0:
		die()
		return

	# Give visual feedback for a hit the enemy survives.
	flash_on_hit()

func _draw() -> void:
	if flight_state == "prepare":
		# A gold line shows the direction of the upcoming swoop.
		draw_line(
			Vector2.ZERO,
			swoop_direction * 160.0,
			Color(1.0, 0.75, 0.2, 0.8),
			4.0
		)

func die() -> void:
	# Prevent multiple death signals before Godot removes this enemy.
	if is_queued_for_deletion():
		return
		
	died.emit(self)
	print("AWESOME")
	queue_free()
