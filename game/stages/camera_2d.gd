extends Camera2D

var shake_strength = 0.0
var shake_fade = 5.0
@onready var player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player:
		global_position = player.global_position
		
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		offset = random_offset()

func apply_shake(strength):
	shake_strength = strength

func random_offset() -> Vector2:
	return Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
