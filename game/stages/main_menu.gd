extends Control


func _on_start_button_pressed() -> void:
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://stages/level1_v2.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
