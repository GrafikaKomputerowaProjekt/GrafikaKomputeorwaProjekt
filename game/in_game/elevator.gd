extends Node2D

var player_in_range = false

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		trigger_ending()

func trigger_ending():
	print("Elevator activated. Ending game.")
	
	
	get_tree().change_scene_to_file("res://stages/main_menu.tscn")
	
	

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
