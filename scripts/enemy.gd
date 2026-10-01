extends CharacterBody2D

signal died(enemy)

@export var speed = 120

var max_hp = 20;
var hp = 20;
var player: Node2D

# Find this enemy's own health bar.
@onready var health_bar: ProgressBar = $HealthBar

# Use the animated crab for movement visuals and hit flashes.
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var normal_tint: Color = $AnimatedSprite2D.self_modulate

# Stores the current flash so repeated hits can restart it.
var hit_tween: Tween

func _ready() -> void:
	# Start each enemy at full health.
	hp = max_hp

	# Match the bar's range to this enemy's health.
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp
	
	# Keep the bar hidden until this enemy takes damage.
	health_bar.hide()

	# Loop the crab's animation.
	sprite.play("scuttle")

	# Start each crab at a different point in the animation,
	# so the whole group doesn't move in perfect sync.
	sprite.set_frame_and_progress(
		randi_range(0, sprite.sprite_frames.get_frame_count("scuttle") - 1),
		randf()
	)
func _physics_process(_delta: float) -> void:
	# Find the ship tagged with "player" group
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		
		
	# Wait if the player isn't available yet.
	if not is_instance_valid(player):
		return
	
	# Move toward the player's current position
	var direction := global_position.direction_to(player.global_position)
	# The crab artwork naturally faces left.
	# The crab artwork naturally faces left.
	# Flip it when the player is to the right.
	if direction.x > 0.05:
		sprite.flip_h = true
	elif direction.x < -0.05:
		sprite.flip_h = false

	velocity = direction * speed
	move_and_slide()
	

	
func flash_on_hit() -> void:
	# Stop any previous flash before starting another.
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()

	# Values above 1 brighten the sprite's colors.
	# Tint the crab red, then let the existing tween restore its color.
	sprite.self_modulate = Color(1.0, 0.25, 0.25, normal_tint.a)
	
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

func die() -> void: 
	# Prevent multiple death signals before Godot removes this enemy
	if is_queued_for_deletion():
		return
		
	died.emit(self) 
	print("AWESOME")
	queue_free()
