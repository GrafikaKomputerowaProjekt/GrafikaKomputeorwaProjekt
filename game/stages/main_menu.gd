extends Control


func _on_start_button_pressed() -> void:
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://stages/level1_v2.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
	
func _on_levels_button_pressed() -> void:
	$VBoxContainer.visible = false
	$LevelsContainer.visible = true

func _on_back_button_pressed() -> void:
	$LevelsContainer.visible = false
	$VBoxContainer.visible = true

func _on_level_1_button_pressed() -> void:
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://stages/level1_v2.tscn")

func _on_boss_button_pressed() -> void:
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://stages/boss1_arena.tscn")
