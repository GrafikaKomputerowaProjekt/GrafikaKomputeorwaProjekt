extends Node2D

@export var target_id: String = ""

@onready var sprite_off = $Sprite_off
@onready var sprite_on = $Sprite_on

var player_in_range = false
var is_on = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		trigger_doors()

func trigger_doors():
	var all_doors = get_tree().get_nodes_in_group("Doors")
	
	is_on = !is_on
	
	if is_on:
		sprite_off.visible = false
		sprite_on.visible = true
	else:
		sprite_off.visible = true
		sprite_on.visible = false
		
	
	for door in all_doors:
		if door.door_id == target_id:
			door.toggle_door()
	
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
	
func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
