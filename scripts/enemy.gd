extends CharacterBody2D

signal died(enemy)

@export var speed = 120

var max_hp = 20
var hp = 20
var player: Node2D

# ---------------------------------------------------------
# PLAYER DAMAGE SETTINGS
# ---------------------------------------------------------

# How much damage this enemy does to the player.
@export var damage: int = 10

# How often the enemy can damage the player.
@export var damage_cooldown: float = 1.0

# Keeps track of the damage cooldown.
var damage_timer: float = 0.0


# Find this enemy's own health bar.
@onready var health_bar: ProgressBar = $HealthBar

# The base enemy uses a static ship sprite.
@onready var sprite: Sprite2D = $Visual

# Remember its red tint so hit flashes restore the correct color.
@onready var normal_tint: Color = sprite.self_modulate

# Stores the current flash so repeated hits can restart it.
var hit_tween: Tween


func _ready() -> void:
	# Start this ship at full health.
	hp = max_hp

	# Configure its health bar.
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp

	# Show the bar only after taking damage.
	health_bar.hide()

func _physics_process(delta: float) -> void:
	# Reduce the damage cooldown.
	if damage_timer > 0:
		damage_timer -= delta

	# Find the ship tagged with "player" group.
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	# Wait if the player isn't available yet.
	if not is_instance_valid(player):
		return

	# Move toward the player's current position.
	var direction := global_position.direction_to(player.global_position)

	# Turn only the ship visual toward the player.
	# The health bar stays upright because the root does not rotate.
	sprite.rotation = lerp_angle(
		sprite.rotation,
		direction.angle(),
		minf(delta * 8.0, 1.0)
	)

	velocity = direction * speed
	move_and_slide()

	# Check whether the enemy is close enough to attack.
	attack_player()


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
	# Tint the crab red, then let the existing tween restore its color.
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
	# Only surviving hits play the damage sound.
	SFX.play_sound("ShipHit")


func die() -> void:
	# Prevent multiple death signals before Godot removes this enemy.
	if is_queued_for_deletion():
		return
		
	SFX.play_sound("ShipDeath")
	died.emit(self)
	print("AWESOME")
	queue_free()
