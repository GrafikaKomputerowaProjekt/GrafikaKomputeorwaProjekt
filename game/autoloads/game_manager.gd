extends Node

var is_alarm_active: bool = false
var is_power_on: bool = false

var alarm_time_left: float = 10.0
var canvas_layer: CanvasLayer
var countdown_label: Label

func _ready():
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	countdown_label = Label.new()
	countdown_label.set_anchors_preset(Control.PRESET_CENTER_TOP) # Top middle
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_color_override("font_color", Color.RED)
	countdown_label.add_theme_font_size_override("font_size", 40)
	countdown_label.visible = false
	canvas_layer.add_child(countdown_label)

func start_alarm():
	if is_alarm_active: 
		return 
		
	is_alarm_active = true
	alarm_time_left = 10.0
	countdown_label.visible = true

func _process(delta: float):
	if is_alarm_active:
		alarm_time_left -= delta
		
		if alarm_time_left <= 0.0:
			is_alarm_active = false
			countdown_label.visible = false
			get_tree().reload_current_scene() 
		else:
			countdown_label.text = "ALARM: " + str(snapped(alarm_time_left, 0.1))
