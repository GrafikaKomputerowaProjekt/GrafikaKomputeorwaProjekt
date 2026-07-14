# Hurtbox.gd
extends Area2D

func hit_by_projectile(damage: int) -> void:
	get_parent().hit_by_projectile(damage) # Przekazuje obrażenia do Slime.gd
