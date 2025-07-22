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

# Color mapping
var tile_colors = {
	TileType.EMPTY: Color(0.1, 0.1, 0.1, 1), # Dark grey
	TileType.FLOOR: Color(0.2, 0.6, 0.2, 1), # Green
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
	generate_world()

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
					world_grid[item_y][item_x] = TileType.ITEM
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

# Public method to regenerate world
func regenerate():
	generate_world()