extends Control

@onready var ammo_label: Label = $AmmoLabel

func set_ammo(ammo: int) -> void:
	ammo_label.text = str(ammo)
