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
	countdown_label.set_anchors_preset(Control.PRESET_TOP_WIDE) 
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.add_theme_color_override("font_color", Color.RED)
	countdown_label.add_theme_font_size_override("font_size", 12)
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
			# TODO back to main menu
			get_tree().change_scene_to_file("res://stages/main_menu.tscn")
		else:
			countdown_label.text = "! " + str(snapped(alarm_time_left, 0.1)) + "s !"
			
func reset_state():
	is_alarm_active = false
	is_power_on = false
	alarm_time_left = 10.0
	
	if countdown_label:
		countdown_label.visible = false
