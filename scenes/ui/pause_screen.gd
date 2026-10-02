extends Control

signal resume_pressed
signal restart_pressed
signal title_pressed


var resume_button: Button
var restart_button: Button
var title_button: Button


func _ready() -> void:
	resume_button = find_child("ResumeButton", true, false) as Button
	restart_button = find_child("RestartButton", true, false) as Button
	title_button = find_child("TitleButton", true, false) as Button

	if is_instance_valid(resume_button):
		resume_button.pressed.connect(_on_resume_pressed)
	else:
		push_error("Pause screen is missing a Button named ResumeButton.")

	if is_instance_valid(restart_button):
		restart_button.pressed.connect(_on_restart_pressed)
	else:
		push_error("Pause screen is missing a Button named RestartButton.")

	if is_instance_valid(title_button):
		title_button.pressed.connect(_on_title_pressed)
	else:
		push_error("Pause screen is missing a Button named TitleButton.")


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()


func _on_title_pressed() -> void:
	title_pressed.emit()
