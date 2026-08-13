extends Node2D

@onready var sprite_off = $Sprite2D_off
@onready var sprite_on = $Sprite2D_on

var player_in_range = false
var _was_power_on = false

func _ready() -> void:
	_update_visibility(GameManager.is_power_on)
	_was_power_on = GameManager.is_power_on

func _process(delta: float) -> void:
	if GameManager.is_power_on != _was_power_on:
		_was_power_on = GameManager.is_power_on
		_update_visibility(_was_power_on)

	if player_in_range and Input.is_action_just_pressed("interact") and GameManager.is_power_on:
		trigger_ending()

func _update_visibility(is_on: bool) -> void:
	if is_on:
		sprite_on.visible = true
		sprite_off.visible = false
	else:
		sprite_on.visible = false
		sprite_off.visible = true

func trigger_ending():
	print("Elevator activated. Ending game.")
	get_tree().change_scene_to_file("res://stages/main_menu.tscn")

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
