extends Control

@export var player: Node2D
@export var floor_layer: TileMapLayer
@export var map_background: TextureRect
@export var player_marker: ColorRect

var map_offset: Vector2i

func generate_minimap(target_layer: TileMapLayer) -> ImageTexture:
	var cells: Array[Vector2i] = target_layer.get_used_cells()
	if cells.is_empty():
		return null

	# 1. Calculate map boundaries (Bounding Box)
	var min_x = cells[0].x
	var max_x = cells[0].x
	var min_y = cells[0].y
	var max_y = cells[0].y

	for cell in cells:
		if cell.x < min_x: min_x = cell.x
		if cell.x > max_x: max_x = cell.x
		if cell.y < min_y: min_y = cell.y
		if cell.y > max_y: max_y = cell.y

	var width: int = max_x - min_x + 1
	var height: int = max_y - min_y + 1
	
	# Store offset to map UI coordinates later
	map_offset = Vector2i(min_x, min_y - 2)

	# 2. Initialize buffer (FORMAT_RGBA8 supports alpha channel)
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0)) # Fill with transparency

	# 3. Map tiles to pixels
	var floor_color := Color(1.0, 1.0, 1.0, 0.325) # Floor outline color
	for cell in cells:
		# Normalize coordinates to [0, 0] of the image
		var img_x: int = cell.x - min_x
		var img_y: int = cell.y - min_y
		image.set_pixel(img_x, img_y, floor_color)

	return ImageTexture.create_from_image(image)
	
func _ready() -> void:
	map_background.texture = generate_minimap(floor_layer)

func _process(_delta: float) -> void:
	if not player or not floor_layer:
		return
		
	update_player_marker()

func update_player_marker() -> void:
	var player_cell: Vector2i = floor_layer.local_to_map(player.global_position)
	
	var local_map_pos: Vector2 = player_cell - map_offset
	
	player_marker.position = local_map_pos
