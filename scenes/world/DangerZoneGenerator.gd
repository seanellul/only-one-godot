extends Node2D

# Danger zone generator creates challenging areas with enemies and loot
class_name DangerZoneGenerator

const TILE_SIZE = 32
const ZONE_WIDTH = 60
const ZONE_HEIGHT = 40

# Zone difficulty scaling
var zone_level: int = 1
var zone_seed: int = 0
var enemy_count: int = 0
var loot_count: int = 0

# Generated content
var spawn_position: Vector2
var rooms = []
var enemies_spawned = []
var loot_spawned = []

# World data
var world_grid = []
var rng = RandomNumberGenerator.new()

# Tile types (similar to WorldGenerator but more dangerous)
enum TileType {
	EMPTY,
	FLOOR,
	PATH,
	WALL,
	LAVA, # Damaging tiles
	SPIKES, # Trap tiles
	TREASURE # Loot tiles
}

# Color mapping
var tile_colors = {
	TileType.EMPTY: Color(0.1, 0.1, 0.1, 1),
	TileType.FLOOR: Color(0.3, 0.3, 0.3, 1), # Dark floor
	TileType.PATH: Color(0.4, 0.4, 0.4, 1), # Darker path
	TileType.WALL: Color(0.2, 0.2, 0.2, 1), # Dark walls
	TileType.LAVA: Color(1.0, 0.3, 0.0, 1), # Red lava
	TileType.SPIKES: Color(0.6, 0.6, 0.6, 1), # Gray spikes
	TileType.TREASURE: Color(1.0, 1.0, 0.0, 1) # Gold treasure
}

# Room structure
class DangerRoom:
	var x: int
	var y: int
	var width: int
	var height: int
	var center_x: int
	var center_y: int
	var room_type: String
	var difficulty: int
	
	func _init(pos_x: int, pos_y: int, w: int, h: int, type: String = "normal", diff: int = 1):
		x = pos_x
		y = pos_y
		width = w
		height = h
		center_x = x + width / 2
		center_y = y + height / 2
		room_type = type
		difficulty = diff

func generate_zone(level: int, seed: int):
	"""Generate a dangerous zone"""
	print("DangerZoneGenerator: Generating danger zone level ", level, " with seed ", seed)
	
	zone_level = level
	zone_seed = seed
	rng.seed = seed
	
	clear_zone()
	
	# Calculate difficulty scaling
	enemy_count = 5 + (level * 3) # More enemies per level
	loot_count = 2 + (level * 2) # More loot per level
	
	# Generate zone layout
	initialize_grid()
	generate_danger_rooms()
	connect_rooms()
	add_walls()
	add_environmental_hazards()
	place_enemies()
	place_loot()
	render_world()
	
	# Set spawn inside the first room (entrance room)
	set_safe_spawn_position()
	
	print("DangerZoneGenerator: Generated zone with ", enemy_count, " enemies and ", loot_count, " loot items")
	print("DangerZoneGenerator: Player spawn set to ", spawn_position)

func initialize_grid():
	"""Initialize the world grid"""
	world_grid = []
	for y in range(ZONE_HEIGHT):
		var row = []
		for x in range(ZONE_WIDTH):
			row.append(TileType.EMPTY)
		world_grid.append(row)

func generate_danger_rooms():
	"""Generate rooms for the danger zone"""
	rooms = []
	var min_rooms = 4 + zone_level
	var max_rooms = 8 + zone_level * 2
	var target_rooms = rng.randi_range(min_rooms, max_rooms)
	
	var attempts = 0
	var max_attempts = 200
	
	while rooms.size() < target_rooms and attempts < max_attempts:
		attempts += 1
		
		var width = rng.randi_range(6, 15)
		var height = rng.randi_range(6, 12)
		var x = rng.randi_range(2, ZONE_WIDTH - width - 2)
		var y = rng.randi_range(2, ZONE_HEIGHT - height - 2)
		
		# Determine room type based on zone level
		var room_type = get_room_type_for_level()
		var difficulty = zone_level + rng.randi_range(-1, 2)
		
		var new_room = DangerRoom.new(x, y, width, height, room_type, max(1, difficulty))
		
		# Check for overlaps
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

func get_room_type_for_level() -> String:
	"""Determine room type based on zone level"""
	var rand_val = rng.randf()
	
	match zone_level:
		1:
			return "normal" if rand_val < 0.8 else "trap"
		2:
			if rand_val < 0.6:
				return "normal"
			elif rand_val < 0.85:
				return "trap"
			else:
				return "elite"
		_:
			if rand_val < 0.4:
				return "normal"
			elif rand_val < 0.7:
				return "trap"
			elif rand_val < 0.9:
				return "elite"
			else:
				return "boss"

func rooms_overlap(room1: DangerRoom, room2: DangerRoom) -> bool:
	"""Check if two rooms overlap"""
	return not (room1.x + room1.width + 2 < room2.x or
				room2.x + room2.width + 2 < room1.x or
				room1.y + room1.height + 2 < room2.y or
				room2.y + room2.height + 2 < room1.y)

func connect_rooms():
	"""Connect rooms with corridors"""
	for i in range(rooms.size() - 1):
		var room_a = rooms[i]
		var room_b = rooms[i + 1]
		create_corridor(room_a.center_x, room_a.center_y, room_b.center_x, room_b.center_y)
	
	# Add some additional connections for higher levels
	if zone_level > 2:
		var extra_connections = zone_level - 2
		for i in range(extra_connections):
			var room_a = rooms[rng.randi() % rooms.size()]
			var room_b = rooms[rng.randi() % rooms.size()]
			if room_a != room_b:
				create_corridor(room_a.center_x, room_a.center_y, room_b.center_x, room_b.center_y)

func create_corridor(x1: int, y1: int, x2: int, y2: int):
	"""Create a corridor between two points"""
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
	"""Add walls around floors and paths"""
	for y in range(ZONE_HEIGHT):
		for x in range(ZONE_WIDTH):
			if world_grid[y][x] == TileType.EMPTY:
				if is_adjacent_to_floor_or_path(x, y):
					world_grid[y][x] = TileType.WALL

func is_adjacent_to_floor_or_path(x: int, y: int) -> bool:
	"""Check if position is adjacent to floor or path"""
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

func add_environmental_hazards():
	"""Add lava and spike traps based on zone level"""
	if zone_level < 2:
		return # No hazards in level 1
	
	var hazard_count = zone_level * 3
	
	for i in range(hazard_count):
		var attempts = 0
		while attempts < 20:
			attempts += 1
			var x = rng.randi_range(1, ZONE_WIDTH - 2)
			var y = rng.randi_range(1, ZONE_HEIGHT - 2)
			
			if world_grid[y][x] == TileType.FLOOR:
				# Choose hazard type
				if rng.randf() < 0.6:
					world_grid[y][x] = TileType.SPIKES
				else:
					world_grid[y][x] = TileType.LAVA
				break

func place_enemies():
	"""Place enemies in rooms based on difficulty"""
	for room in rooms:
		var enemies_in_room = calculate_enemies_for_room(room)
		
		for i in range(enemies_in_room):
			var attempts = 0
			while attempts < 10:
				attempts += 1
				var spawn_x = rng.randi_range(room.x + 1, room.x + room.width - 2)
				var spawn_y = rng.randi_range(room.y + 1, room.y + room.height - 2)
				
				if world_grid[spawn_y][spawn_x] == TileType.FLOOR:
					var spawn_pos = Vector2(spawn_x * TILE_SIZE + TILE_SIZE / 2, spawn_y * TILE_SIZE + TILE_SIZE / 2)
					spawn_enemy_at_position(spawn_pos, room.difficulty)
					break

func calculate_enemies_for_room(room: DangerRoom) -> int:
	"""Calculate number of enemies for a room"""
	var base_enemies = 1
	
	match room.room_type:
		"normal":
			base_enemies = 1 + (room.difficulty - 1)
		"trap":
			base_enemies = 2 + (room.difficulty - 1)
		"elite":
			base_enemies = 3 + room.difficulty
		"boss":
			base_enemies = 1 # Single boss enemy
	
	return base_enemies

func spawn_enemy_at_position(position: Vector2, difficulty: int):
	"""Spawn an enemy at the specified position"""
	print("DangerZoneGenerator: Spawning enemy at ", position, " with difficulty ", difficulty)
	
	var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	
	# Scale enemy stats based on difficulty
	enemy.max_health += difficulty * 20
	enemy.current_health = enemy.max_health
	enemy.damage += difficulty * 5
	
	add_child(enemy)
	enemies_spawned.append(enemy)
	
	print("DangerZoneGenerator: Enemy spawned successfully. Total enemies: ", enemies_spawned.size())

func place_loot():
	"""Place loot items throughout the zone"""
	print("DangerZoneGenerator: Placing ", loot_count, " loot items...")
	
	for i in range(loot_count):
		var attempts = 0
		while attempts < 20:
			attempts += 1
			var x = rng.randi_range(1, ZONE_WIDTH - 2)
			var y = rng.randi_range(1, ZONE_HEIGHT - 2)
			
			if world_grid[y][x] == TileType.FLOOR:
				# Don't change the tile type - just create the loot item
				create_loot_item(x, y)
				print("DangerZoneGenerator: Placed loot item ", i + 1, " at (", x, ",", y, ")")
				break
		
		if attempts >= 20:
			print("DangerZoneGenerator: Failed to place loot item ", i + 1, " after 20 attempts")
	
	print("DangerZoneGenerator: Finished placing loot. Total items: ", loot_spawned.size())

func create_loot_item(grid_x: int, grid_y: int):
	"""Create a loot item at grid position"""
	print("DangerZoneGenerator: Creating loot item at grid (", grid_x, ",", grid_y, ")")
	
	var collectible_scene = preload("res://scenes/items/CollectibleItem.tscn")
	var item = collectible_scene.instantiate()
	
	# Higher level zones have better loot
	var loot_quality = zone_level
	var item_type = get_loot_type_for_quality(loot_quality)
	
	item.item_type_index = item_type
	item.item_type = item_type
	
	# Position the item in world coordinates
	var world_pos = Vector2(grid_x * TILE_SIZE + TILE_SIZE / 2, grid_y * TILE_SIZE + TILE_SIZE / 2)
	item.global_position = world_pos
	
	# Ensure item is visible and on correct layer
	item.z_index = 50  # Above enemies and tiles
	item.add_to_group("collectible_items")
	
	add_child(item)
	loot_spawned.append(item)
	
	print("DangerZoneGenerator: Created ", get_item_type_name(item_type), " at world position ", world_pos)

func get_item_type_name(item_type: int) -> String:
	"""Get human-readable name for item type"""
	match item_type:
		0: return "Coin"
		1: return "Key"
		2: return "Health Potion"
		3: return "Speed Boost"
		4: return "Dash Boost"
		_: return "Unknown Item"

func get_loot_type_for_quality(quality: int) -> int:
	"""Get loot type based on quality level"""
	var rand_val = rng.randf()
	
	match quality:
		1:
			return 0 if rand_val < 0.7 else 1 # Mostly coins, some keys
		2:
			if rand_val < 0.4:
				return 0 # Coins
			elif rand_val < 0.7:
				return 1 # Keys
			else:
				return 2 # Potions
		_:
			if rand_val < 0.3:
				return 0 # Coins
			elif rand_val < 0.5:
				return 1 # Keys
			elif rand_val < 0.7:
				return 2 # Potions
			elif rand_val < 0.85:
				return 3 # Speed boosts
			else:
				return 4 # Dash boosts

func render_world():
	"""Render all tiles"""
	for y in range(ZONE_HEIGHT):
		for x in range(ZONE_WIDTH):
			var tile_type = world_grid[y][x]
			if tile_type != TileType.EMPTY:
				create_tile(x, y, tile_type)

func create_tile(x: int, y: int, tile_type: TileType):
	"""Create a visual tile"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = tile_colors[tile_type]
	tile.z_index = -10  # Put tiles behind everything else
	
	# Add collision for walls
	if tile_type == TileType.WALL:
		var static_body = StaticBody2D.new()
		var collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		collision_shape.shape = shape
		collision_shape.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		
		tile.position = Vector2(0, 0)
		static_body.add_child(collision_shape)
		static_body.add_child(tile)
		static_body.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		static_body.z_index = -10  # Put walls behind enemies too
		add_child(static_body)
	else:
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)

func is_valid_position(x: int, y: int) -> bool:
	"""Check if position is within bounds"""
	return x >= 0 and x < ZONE_WIDTH and y >= 0 and y < ZONE_HEIGHT

func set_safe_spawn_position():
	"""Set spawn position inside a valid room"""
	if rooms.size() > 0:
		# Use the first room as entrance room
		var entrance_room = rooms[0]
		
		# Find a safe spot inside the room (away from walls)
		var safe_x = entrance_room.center_x
		var safe_y = entrance_room.center_y
		
		# Ensure we're not too close to walls
		var padding = 2
		safe_x = clamp(safe_x, entrance_room.x + padding, entrance_room.x + entrance_room.width - padding)
		safe_y = clamp(safe_y, entrance_room.y + padding, entrance_room.y + entrance_room.height - padding)
		
		# Convert to world coordinates
		spawn_position = Vector2(safe_x * TILE_SIZE, safe_y * TILE_SIZE)
		
		print("DangerZoneGenerator: Spawn set in room at grid (", safe_x, ",", safe_y, ") world (", spawn_position, ")")
	else:
		# Fallback if no rooms exist
		spawn_position = Vector2(ZONE_WIDTH * TILE_SIZE / 2, ZONE_HEIGHT * TILE_SIZE / 2)
		print("DangerZoneGenerator: No rooms found, using center spawn")

func get_spawn_position() -> Vector2:
	"""Get the player spawn position"""
	return spawn_position

func clear_zone():
	"""Clear all zone elements"""
	for child in get_children():
		child.queue_free()
	
	rooms.clear()
	enemies_spawned.clear()
	loot_spawned.clear()

func get_zone_stats() -> Dictionary:
	"""Get statistics about the generated zone"""
	return {
		"level": zone_level,
		"enemy_count": enemies_spawned.size(),
		"loot_count": loot_spawned.size(),
		"room_count": rooms.size()
	}