extends Control

signal damage_pressed
signal movementspeed_pressed
signal attackspeed_pressed


var damage_button: Button
var movementspeed_button: Button
var attackspeed_button: Button


func _ready() -> void:
	damage_button = find_child("ButtonDamage", true, false) as Button
	movementspeed_button = find_child("ButtonSpeed", true, false) as Button
	attackspeed_button = find_child("ButtonAttackSpeed", true, false) as Button


	damage_button.pressed.connect(_on_damage_pressed)
	movementspeed_button.pressed.connect(_on_movementspeed_pressed)
	attackspeed_button.pressed.connect(_on_attackspeed_pressed)


func _on_damage_pressed() -> void:
	damage_pressed.emit()


func _on_movementspeed_pressed() -> void:
	movementspeed_pressed.emit()


func _on_attackspeed_pressed() -> void:
	attackspeed_pressed.emit()
