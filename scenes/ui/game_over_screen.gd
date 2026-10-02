extends Control

signal retry_pressed
signal title_pressed


@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton
@onready var title_button: Button = $CenterContainer/VBoxContainer/TitleButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	title_button.pressed.connect(_on_title_pressed)

	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	retry_pressed.emit()


func _on_title_pressed() -> void:
	title_pressed.emit()
