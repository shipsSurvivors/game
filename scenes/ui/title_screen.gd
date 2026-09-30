extends Control

# Load the gameplay scene so the Start button can open it.
const GAME_SCENE := preload("res://scenes/player/Player Attack.tscn")

# Find the button after this scene's nodes are ready.
# These names must match the nodes in your Scene tree.
@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton


# Godot calls this when the title screen is ready.
func _ready() -> void:
	# Run our start function whenever the button is pressed.
	start_button.pressed.connect(_on_start_pressed)

	# Select the button so Enter or Space can activate it.
	start_button.grab_focus()


# Replace the title screen with the gameplay scene.
func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCENE)
