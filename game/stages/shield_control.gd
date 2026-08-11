extends Control

@onready var shield_texture_rect: TextureRect = $ShieldTexture

const TILE_SIZE := Vector2(8, 9)

const REGION_SHIELD_ACTIVE := Rect2(Vector2(0, 0), TILE_SIZE)
const REGION_SHIELD_INACTIVE := Rect2(Vector2(8, 0), TILE_SIZE)


func set_shield_state(is_active: bool) -> void:
	if is_active:
		shield_texture_rect.texture.region = REGION_SHIELD_ACTIVE
	else:
		shield_texture_rect.texture.region = REGION_SHIELD_INACTIVE
