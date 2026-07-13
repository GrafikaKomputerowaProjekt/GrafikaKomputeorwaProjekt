extends StaticBody2D

@export var reactor_id: String = ""
@export var texture_off: Texture2D
@export var texture_on: Texture2D

@onready var sprite = $Sprite2D
@onready var light = $PointLight2D
@onready var anim_player = $AnimationPlayer

var is_on = false

func _ready():
	# Ensure it starts in the off state
	sprite.texture = texture_off
	light.enabled = false
	anim_player.stop()

func toggle_reactor():
	is_on = !is_on
	GameManager.is_power_on = is_on  # Syncs the global power to the reactor's state
	
	if is_on:
		sprite.texture = texture_on
		light.enabled = true
		anim_player.play("pulse")
	else:
		sprite.texture = texture_off
		light.enabled = false
		anim_player.stop()
