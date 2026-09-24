extends CharacterBody2D

# Movement speed of the player in pixels per second.
@export var speed: float = 300.0

# Gets the Sprite2D child so we can flip the artwork left/right.
@onready var sprite: Sprite2D = $Sprite2D

# Reference to the health bar under player sprite
@onready var health_bar: ProgressBar = $HealthBar

# Player's maximum health
@export var max_health: int = 100

# Current health during gameplay.
var current_health: int

# When ready
func _ready():
	# Start player at full health
	current_health = max_health
	
	# Configure health bar
	health_bar.max_value = max_health
	health_bar.value = current_health

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

	# If the player is moving left, flip the sprite horizontally.
	if direction.x < 0:
		sprite.flip_h = true

	# If the player is moving right, return the sprite to its normal direction.
	elif direction.x > 0:
		sprite.flip_h = false

	# Moves the CharacterBody2D using the velocity we calculated above.
	move_and_slide()
