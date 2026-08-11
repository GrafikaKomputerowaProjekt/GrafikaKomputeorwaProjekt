extends Area2D

@export var custom_message: String = "Press E to interact"
# This lets it match the switch's target ID
@export var zone_id: String = "" 

@onready var prompt_text = $PromptText

# This flag decides if the zone is allowed to work
var is_permanently_disabled = false

func _ready():
	prompt_text.text = custom_message
	prompt_text.hide()

func disable_zone():
	# The switch runs this to shut the zone down
	is_permanently_disabled = true
	prompt_text.visible = false

func _on_body_entered(body):
	# Now it only shows text if it hasn't been disabled
	if not is_permanently_disabled and body.is_in_group("Player"):
		prompt_text.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		prompt_text.visible = false
