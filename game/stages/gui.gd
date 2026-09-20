# gui.gd
extends CanvasLayer

@onready var player_shield: Control = $ShieldControl
@onready var player_ammo_bar: Control = $AmmoBarControl


const FRAME_ENABLED: int = 0
const FRAME_DISABLED: int = 1

func _on_player_shield_state_changed(is_active: bool) -> void:
	if is_active:
		player_shield.set_shield_state(true)
	else:
		player_shield.set_shield_state(false)


func _on_player_ammo_bar_state_changed(ammo_count: int) -> void:
	player_ammo_bar.set_shield_state(ammo_count)
