extends PointLight2D

@export var normal_color: Color = Color.WHITE
@export var alarm_color: Color = Color.RED

@export var normal_pulse_speed: float = 2.0
@export var alarm_pulse_speed: float = 12.0

@export var min_energy: float = 1
@export var max_energy: float = 1.1

var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	var current_speed = normal_pulse_speed
	

	if GameManager.is_alarm_active:
		color = alarm_color
		current_speed = alarm_pulse_speed
	else:
		color = normal_color
		current_speed = normal_pulse_speed
		
	var wave = (sin(time_passed * current_speed) + 1.0) / 2.0
	
	
	energy = lerpf(min_energy, max_energy, wave)
