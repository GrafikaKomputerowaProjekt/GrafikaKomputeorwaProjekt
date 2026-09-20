extends Control

@onready var ammo_bar_texture_rect : TextureRect = $AmmoBarTexture

const TILE_SIZE := Vector2(10, 17)

const REGION_AMMO_BAR_FOUR := Rect2(Vector2(0, 0), TILE_SIZE)
const REGION_AMMO_BAR_THREE := Rect2(Vector2(10, 0), TILE_SIZE)
const REGION_AMMO_BAR_TWO := Rect2(Vector2(20, 0), TILE_SIZE)
const REGION_AMMO_BAR_ONE := Rect2(Vector2(30, 0), TILE_SIZE)
const REGION_AMMO_BAR_ZERO := Rect2(Vector2(40, 0), TILE_SIZE)

func _ready() -> void:
	ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_FOUR


func set_shield_state(bars: int) -> void:
	match bars:
		4: 
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_FOUR
		3: 
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_THREE
		2:
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_TWO
		1:
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_ONE
		0:
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_ZERO
		_:
			ammo_bar_texture_rect.texture.region = REGION_AMMO_BAR_ZERO
