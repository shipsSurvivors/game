extends Node

func play_sound(sound_name: String) -> void:
	var sound := get_node_or_null(sound_name) as AudioStreamPlayer

	if sound == null:
		push_error("SFX is missing an AudioStreamPlayer named: " + sound_name)
		return

	sound.play()
