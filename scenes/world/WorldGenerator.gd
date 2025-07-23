extends Node2D

# World generation settings
const TILE_SIZE = 32
const WORLD_WIDTH = 400
const WORLD_HEIGHT = 300
const MIN_ROOM_SIZE = 6
const MAX_ROOM_SIZE = 20
const MAX_ROOMS = 60

# Tile types
enum TileType {
	EMPTY,
	FLOOR, # Green - off-beaten path/grass
	PATH, # Grey - connecting paths
	WALL, # Black - immovable walls with collision
	ITEM # Yellow - items of interest
}

# Grass textures for variety
var grass_textures = []

# Color mapping for non-grass tiles
var tile_colors = {
	TileType.EMPTY: Color(0.1, 0.1, 0.1, 1), # Dark grey
	TileType.PATH: Color(0.5, 0.5, 0.5, 1), # Grey
	TileType.WALL: Color(0, 0, 0, 1), # Black
	TileType.ITEM: Color(1, 1, 0, 1) # Yellow
}

# World data
var world_grid = []
var rooms = []
var rng = RandomNumberGenerator.new()

# Room structure
class Room:
	var x: int
	var y: int
	var width: int
	var height: int
	var center_x: int
	var center_y: int
	
	func _init(pos_x: int, pos_y: int, w: int, h: int):
		x = pos_x
		y = pos_y
		width = w
		height = h
		center_x = x + width / 2
		center_y = y + height / 2

func _ready():
	rng.randomize()
	load_grass_textures()
	generate_world()

func load_grass_textures():
	# Load the 4 grass texture variants
	var grass_paths = [
		"res://tiles/grass_0.png",
		"res://tiles/grass_1.png",
		"res://tiles/grass_2.png",
		"res://tiles/grass_3.png"
	]
	
	for path in grass_paths:
		var texture = load(path)
		if texture:
			grass_textures.append(texture)
			print("Loaded grass texture: ", path)
		else:
			print("Failed to load grass texture: ", path)
	
	if grass_textures.size() == 0:
		print("Warning: No grass textures loaded, falling back to solid color")

func generate_world():
	print("Generating world...")
	
	# Initialize grid with empty tiles
	initialize_grid()
	
	# Generate rooms
	generate_rooms()
	
	# Connect rooms with paths
	connect_rooms()
	
	# Add walls around rooms and paths
	add_walls()
	
	# Place items of interest
	place_items()
	
	# Render the world
	render_world()
	
	print("World generation complete!")
	print("Generated ", rooms.size(), " rooms in a ", WORLD_WIDTH, "x", WORLD_HEIGHT, " world")

func initialize_grid():
	world_grid = []
	for y in range(WORLD_HEIGHT):
		var row = []
		for x in range(WORLD_WIDTH):
			row.append(TileType.EMPTY)
		world_grid.append(row)

func generate_rooms():
	rooms = []
	var attempts = 0
	var max_attempts = 200
	
	while rooms.size() < MAX_ROOMS and attempts < max_attempts:
		attempts += 1
		
		var width = rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var height = rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var x = rng.randi_range(1, WORLD_WIDTH - width - 1)
		var y = rng.randi_range(1, WORLD_HEIGHT - height - 1)
		
		var new_room = Room.new(x, y, width, height)
		
		# Check if room overlaps with existing rooms
		var can_place = true
		for existing_room in rooms:
			if rooms_overlap(new_room, existing_room):
				can_place = false
				break
		
		if can_place:
			rooms.append(new_room)
			# Fill room with floor tiles
			for room_y in range(y, y + height):
				for room_x in range(x, x + width):
					world_grid[room_y][room_x] = TileType.FLOOR

func rooms_overlap(room1: Room, room2: Room) -> bool:
	return not (room1.x + room1.width < room2.x or
				room2.x + room2.width < room1.x or
				room1.y + room1.height < room2.y or
				room2.y + room2.height < room1.y)

func connect_rooms():
	# Connect each room to the next one (main path)
	for i in range(rooms.size() - 1):
		var room_a = rooms[i]
		var room_b = rooms[i + 1]
		
		# Create L-shaped corridor
		create_corridor(room_a.center_x, room_a.center_y, room_b.center_x, room_b.center_y)
	
	# Add some random connections for more interesting exploration
	var extra_connections = min(rooms.size() / 4, 15) # Up to 15 extra connections
	for i in range(extra_connections):
		var room_a = rooms[rng.randi() % rooms.size()]
		var room_b = rooms[rng.randi() % rooms.size()]
		if room_a != room_b:
			create_corridor(room_a.center_x, room_a.center_y, room_b.center_x, room_b.center_y)

func create_corridor(x1: int, y1: int, x2: int, y2: int):
	# Create horizontal corridor first
	var start_x = min(x1, x2)
	var end_x = max(x1, x2)
	for x in range(start_x, end_x + 1):
		if is_valid_position(x, y1):
			world_grid[y1][x] = TileType.PATH
	
	# Then vertical corridor
	var start_y = min(y1, y2)
	var end_y = max(y1, y2)
	for y in range(start_y, end_y + 1):
		if is_valid_position(x2, y):
			world_grid[y][x2] = TileType.PATH

func add_walls():
	# Add walls around floors and paths
	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			if world_grid[y][x] == TileType.EMPTY:
				# Check if adjacent to floor or path
				if is_adjacent_to_floor_or_path(x, y):
					world_grid[y][x] = TileType.WALL

func is_adjacent_to_floor_or_path(x: int, y: int) -> bool:
	var directions = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)
	]
	
	for dir in directions:
		var check_x = x + dir.x
		var check_y = y + dir.y
		if is_valid_position(check_x, check_y):
			var tile = world_grid[check_y][check_x]
			if tile == TileType.FLOOR or tile == TileType.PATH:
				return true
	return false

func place_items():
	# Place more items per room since rooms are larger now
	for room in rooms:
		var item_count = rng.randi_range(2, 6)
		for i in range(item_count):
			var attempts = 0
			while attempts < 10:
				attempts += 1
				var item_x = rng.randi_range(room.x + 1, room.x + room.width - 2)
				var item_y = rng.randi_range(room.y + 1, room.y + room.height - 2)
				
				if world_grid[item_y][item_x] == TileType.FLOOR:
					# Create actual collectible item instead of tile
					create_collectible_item(item_x, item_y)
					break

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < WORLD_WIDTH and y >= 0 and y < WORLD_HEIGHT

func render_world():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Create visual tiles
	for y in range(WORLD_HEIGHT):
		for x in range(WORLD_WIDTH):
			var tile_type = world_grid[y][x]
			if tile_type != TileType.EMPTY:
				create_tile(x, y, tile_type)

func create_tile(x: int, y: int, tile_type: TileType):
	# Handle grass tiles with texture sprites
	if tile_type == TileType.FLOOR:
		create_grass_tile(x, y)
		return
	
	# Handle other tiles with ColorRect (walls, paths, etc.)
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = tile_colors[tile_type]
	
	# Add collision for walls
	if tile_type == TileType.WALL:
		var static_body = StaticBody2D.new()
		var collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		collision_shape.shape = shape
		
		# RectangleShape2D is centered, so offset by half tile size to align with visual
		collision_shape.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		
		# Visual tile starts at top-left of the static body
		tile.position = Vector2(0, 0)
		
		static_body.add_child(collision_shape)
		static_body.add_child(tile)
		static_body.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(static_body)
	else:
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)

func create_grass_tile(x: int, y: int):
	# Use the base grass texture with subtle hue variations
	var sprite = Sprite2D.new()
	
	# Always use the base grass texture (grass_0) for consistency
	if grass_textures.size() > 0:
		sprite.texture = grass_textures[0] # Always use grass_0
	else:
		# Fallback to colored rect if textures failed to load
		var fallback_tile = ColorRect.new()
		fallback_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		fallback_tile.color = Color(0.2, 0.6, 0.2, 1)
		fallback_tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(fallback_tile)
		return
	
	# Position the sprite
	sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
	
	# Scale sprite to fit tile size
	if sprite.texture:
		var texture_size = sprite.texture.get_size()
		var scale_x = float(TILE_SIZE) / texture_size.x
		var scale_y = float(TILE_SIZE) / texture_size.y
		sprite.scale = Vector2(scale_x, scale_y)
	
	# Create smooth, blended hue variations across the world
	var hue_variation = create_smooth_hue_variation(x, y)
	var saturation_variation = create_smooth_saturation_variation(x, y)
	var brightness_variation = create_smooth_brightness_variation(x, y)
	
	# Apply the subtle color modulation
	var base_color = Color.from_hsv(hue_variation, saturation_variation, brightness_variation)
	sprite.modulate = base_color
	
	# Very occasional rotation for minimal texture variation (only 2% of tiles)
	var position_hash = (x * 7 + y * 11) % 100
	if position_hash < 2:
		var rotations = [90, 180, 270]
		sprite.rotation_degrees = rotations[position_hash % rotations.size()]
	
	add_child(sprite)

func create_smooth_hue_variation(x: int, y: int) -> float:
	# Create smooth hue variation using sine waves for natural blending
	var base_hue = 0.33 # Green hue (120 degrees / 360 = 0.33)
	
	# Multiple frequency sine waves for organic variation
	var wave1 = sin(x * 0.05) * sin(y * 0.03) * 0.02 # Large slow waves
	var wave2 = sin(x * 0.1) * sin(y * 0.08) * 0.01 # Medium waves
	var wave3 = sin(x * 0.2) * sin(y * 0.15) * 0.005 # Small detail waves
	
	var hue = base_hue + wave1 + wave2 + wave3
	
	# Keep hue in valid range and within green spectrum
	return clamp(hue, 0.25, 0.4) # Stay in green-yellow to blue-green range

func create_smooth_saturation_variation(x: int, y: int) -> float:
	# Subtle saturation variation for depth
	var base_saturation = 0.6
	
	var sat_wave1 = sin(x * 0.03) * cos(y * 0.04) * 0.1
	var sat_wave2 = sin(x * 0.08) * sin(y * 0.06) * 0.05
	
	var saturation = base_saturation + sat_wave1 + sat_wave2
	
	return clamp(saturation, 0.4, 0.8)

func create_smooth_brightness_variation(x: int, y: int) -> float:
	# Subtle brightness variation for organic feel
	var base_brightness = 0.85
	
	var bright_wave1 = sin(x * 0.04) * sin(y * 0.05) * 0.08
	var bright_wave2 = cos(x * 0.09) * cos(y * 0.07) * 0.04
	var bright_wave3 = sin(x * 0.15) * cos(y * 0.12) * 0.02
	
	var brightness = base_brightness + bright_wave1 + bright_wave2 + bright_wave3
	
	return clamp(brightness, 0.7, 1.0)

func create_collectible_item(grid_x: int, grid_y: int):
	# Use the proper CollectibleItem scene
	var collectible_scene = preload("res://scenes/items/CollectibleItem.tscn")
	var item = collectible_scene.instantiate()
	
	# Random item type based on rarity
	var weights = [60, 15, 15, 7, 3] # Weighted chances: Coin, Key, Potion, Speed, Dash
	var total_weight = 100
	var random_value = rng.randi_range(1, total_weight)
	var current_weight = 0
	var item_type_index = 0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			item_type_index = i
			break
	
	# Set the item type
	item.item_type_index = item_type_index
	item.item_type = item_type_index # Make sure both are set
	
	# Position the item in world coordinates
	item.position = Vector2(grid_x * TILE_SIZE + TILE_SIZE / 2, grid_y * TILE_SIZE + TILE_SIZE / 2)
	
	# Add to world
	add_child(item)

# Public method to regenerate world
func regenerate():
	generate_world()
