extends StaticBody2D

@export var reactor_id: String = ""
@export var texture_off: Texture2D
@export var texture_on: Texture2D

@onready var sprite = $Sprite2D
@onready var light = $PointLight2D
@onready var anim_player = $AnimationPlayer

@onready var spark_particles = $SparkParticles
@onready var spark_particles2 = $SparkParticles2

var is_on = false

func _ready():
	sprite.texture = texture_off
	light.enabled = false
	anim_player.stop()

func toggle_reactor():
	is_on = !is_on
	GameManager.is_power_on = is_on  
	
	if is_on:
		sprite.texture = texture_on
		light.enabled = true
		spark_particles.emitting = true
		spark_particles2.emitting = true
		anim_player.play("pulse")
	else:
		sprite.texture = texture_off
		light.enabled = false
		spark_particles.emitting = false
		spark_particles2.emitting = false
		anim_player.stop()
