extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var particles = $CPUParticles2D
@onready var spark_particles = $SparkParticles
@onready var spark_particles2 = $SparkParticles2

var is_broken = false

func break_pillar() -> bool:
	if not is_broken:
		is_broken = true
		sprite.texture = load("res://assets/pillar/pillar_destroyed.png")
		collision_shape.set_deferred("disabled", true)
		
		particles.emitting = true
		spark_particles.emitting = false
		spark_particles2.emitting = true
		
		var camera = get_tree().get_first_node_in_group("camera")
		if camera:
			camera.apply_shake(15.0)
			
		return true
	return false
