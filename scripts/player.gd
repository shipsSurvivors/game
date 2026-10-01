extends CharacterBody2D

signal player_died

# Movement speed of the player in pixels per second.
@export var speed: float = 300.0

# Control the animated ship.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Reference to the health bar under player sprite.
@onready var health_bar: ProgressBar = $HealthBar

# Player's maximum health.
@export var max_health: int = 100

# Current health during gameplay.
var current_health: int

# Prevent the death function from running multiple times.
var is_dead: bool = false


# When ready.
func _ready():
	add_to_group("player")
	
	# Start player at full health.
	current_health = max_health
	
	# Configure health bar.
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Start the looping sailing animation.
	sprite.play("sail")


func take_damage(amount: int):
	# Don't take damage after dying.
	if is_dead:
		return
	
	# Reduce current health by enemy damage amount.
	current_health -= amount
	
	# Prevent health from becoming negative.
	current_health = max(current_health, 0)
	
	# Update HealthBar to match current health.
	health_bar.value = current_health
	
	# Check if the player has died.
	if current_health <= 0:
		die()


func die():
	# Prevent death from triggering more than once.
	if is_dead:
		return
	
	is_dead = true
	
	# Stop the player's movement.
	velocity = Vector2.ZERO
	
	# Tell the GameManager that the player died.
	player_died.emit()
	
	print("PLAYER DIED")


func _physics_process(_delta):
	# Don't allow movement after death.
	if is_dead:
		return
	
	# Gets movement input from WASD / arrow keys.
	var direction = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# Converts the input direction into the player's movement velocity.
	velocity = direction * speed

	# Our ship artwork naturally faces left.
	if direction.x < 0:
		sprite.flip_h = false
	elif direction.x > 0:
		sprite.flip_h = true

	# Moves the CharacterBody2D using the velocity we calculated above.
	move_and_slide()
