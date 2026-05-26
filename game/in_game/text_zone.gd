extends Area2D

@export var custom_message: String = "Press E to interact"

@onready var prompt_text = $PromptText

func _ready():
	prompt_text.text = custom_message

func _on_body_entered(body):
	if body.is_in_group("Player"):
		prompt_text.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		prompt_text.visible = false
