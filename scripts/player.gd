extends CharacterBody2D

# Movement speed of the player in pixels per second.
@export var speed: float = 300.0

# Control the animated ship.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Reference to the health bar under player sprite
@onready var health_bar: ProgressBar = $HealthBar

# Player's maximum health
@export var max_health: int = 100

# Current health during gameplay.
var current_health: int

# When ready
func _ready():
	add_to_group("player") # Other scripts can help search for "player"
	# "player" = our ship
	
	
	# Start player at full health
	current_health = max_health
	
	# Configure health bar
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Start the looping sailing animation.
	sprite.play("sail")

func take_damage(amount: int):
	# Reduce current health by enemy damage amount
	current_health -= amount
	
	# Prevent health from becoming negative
	current_health = max(current_health, 0)
	
	# Update HealthBar to match current health.
	health_bar.value = current_health

func _physics_process(_delta):
	# Gets movement input from WASD / arrow keys.
	# Input.get_vector() also normalizes diagonal movement automatically.
	var direction = Input.get_vector(
		# Made from Project Settings > Input Map
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
