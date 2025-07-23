extends Node

# Spawning parameters
var enemies_per_room: int = 2
var max_enemies_total: int = 15
var spawn_delay: float = 2.0 # Increased initial delay
var min_distance_from_player: float = 60.0 # Reduced distance for better spawning
var respawn_delay: float = 5.0

var current_enemy_count: int = 0
var spawn_timer: float = 0.0

# References
var world_generator: Node2D
var player: CharacterBody2D

func _ready():
	print("EnemySpawner: Starting up...")
	# Find references
	world_generator = get_parent().get_node_or_null("WorldGenerator")
	if world_generator:
		print("EnemySpawner: Found WorldGenerator")
	else:
		print("EnemySpawner: WorldGenerator not found!")
	
	call_deferred("find_player")
	
	# Wait longer for world generation to complete
	call_deferred("initialize_spawning")

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("EnemySpawner: Found player at ", player.global_position)
	else:
		print("EnemySpawner: Player not found!")

func initialize_spawning():
	print("EnemySpawner: Initializing spawning system...")
	
	# Double-check references
	if not world_generator:
		print("EnemySpawner: Still no WorldGenerator - retrying...")
		world_generator = get_parent().get_node_or_null("WorldGenerator")
	
	if not player:
		print("EnemySpawner: Still no Player - retrying...")
		find_player()
	
	# Check if world generation is complete
	if world_generator and world_generator.rooms.size() > 0:
		print("EnemySpawner: World has ", world_generator.rooms.size(), " rooms - ready to spawn!")
		spawn_timer = spawn_delay  # Start the spawn timer
	else:
		print("EnemySpawner: World not ready yet - waiting...")
		# Try again after a short delay
		await get_tree().create_timer(1.0).timeout
		initialize_spawning()

func _process(delta):
	if spawn_timer > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			try_spawn_enemies()
			spawn_timer = spawn_delay * 5 # Much slower subsequent spawns

func try_spawn_enemies():
	if not world_generator:
		print("EnemySpawner: Missing world generator")
		return
	
	if not player:
		print("EnemySpawner: Missing player")
		find_player() # Try to find player again
		return
	
	if current_enemy_count >= max_enemies_total:
		print("EnemySpawner: Max enemies reached (", current_enemy_count, "/", max_enemies_total, ")")
		return
	
	# Access rooms array directly (no method needed)
	var rooms = world_generator.rooms
	if rooms.size() == 0:
		print("EnemySpawner: No rooms available")
		return
	
	print("EnemySpawner: Found ", rooms.size(), " rooms, trying to spawn enemies...")
	
	# Spawn fewer enemies initially to test
	var enemies_to_spawn = min(3, max_enemies_total - current_enemy_count)
	print("EnemySpawner: Attempting to spawn ", enemies_to_spawn, " enemies")
	
	var successful_spawns = 0
	for i in range(enemies_to_spawn):
		if spawn_enemy_in_random_room(rooms):
			successful_spawns += 1
	
	print("EnemySpawner: Successfully spawned ", successful_spawns, " enemies")

func spawn_enemy_in_random_room(rooms: Array) -> bool:
	var attempts = 0
	var max_attempts = 20 # Increased attempts
	
	print("EnemySpawner: Attempting to spawn in random room (", rooms.size(), " available)")
	
	while attempts < max_attempts:
		attempts += 1
		
		# Pick random room
		var room = rooms[randi() % rooms.size()]
		print("EnemySpawner: Attempt ", attempts, " - Trying room at (", room.x, ",", room.y, ") size ", room.width, "x", room.height)
		
		# Ensure room is large enough for spawn padding
		if room.width < 6 or room.height < 6:
			print("EnemySpawner: Room too small for spawning")
			continue
		
		# Pick random position in room (avoid edges)
		var spawn_x = room.x + randi() % (room.width - 4) + 2 # More padding
		var spawn_y = room.y + randi() % (room.height - 4) + 2
		var spawn_position = Vector2(spawn_x * world_generator.TILE_SIZE + world_generator.TILE_SIZE / 2,
									 spawn_y * world_generator.TILE_SIZE + world_generator.TILE_SIZE / 2)
		
		# Check distance from player
		var distance_to_player = spawn_position.distance_to(player.global_position) if player else 999
		if player and distance_to_player < min_distance_from_player:
			print("EnemySpawner: Spawn position too close to player (", distance_to_player, " < ", min_distance_from_player, ")")
			continue
		
		# Check if position is valid (on floor tile)
		if not is_valid_spawn_position(spawn_x, spawn_y):
			continue
		
		# Spawn enemy
		spawn_enemy_at_position(spawn_position)
		current_enemy_count += 1
		print("EnemySpawner: Spawned enemy ", current_enemy_count, " at ", spawn_position, " (room center: ", Vector2(room.center_x, room.center_y), ")")
		return true
	
	print("EnemySpawner: Failed to find valid spawn position after ", max_attempts, " attempts")
	return false

func is_valid_spawn_position(grid_x: int, grid_y: int) -> bool:
	if not world_generator:
		print("EnemySpawner: No world generator for position validation")
		return false
	
	# Check bounds
	if grid_x < 0 or grid_x >= world_generator.WORLD_WIDTH or grid_y < 0 or grid_y >= world_generator.WORLD_HEIGHT:
		return false
	
	# Access world_grid directly (no method needed)
	var tile_type = world_generator.world_grid[grid_y][grid_x]
	var is_floor = tile_type == world_generator.TileType.FLOOR
	
	if not is_floor:
		print("EnemySpawner: Position (", grid_x, ",", grid_y, ") is not a floor tile (type: ", tile_type, ")")
	
	return is_floor

func spawn_enemy_at_position(position: Vector2):
	# Create enemy instance
	var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	
	# Connect death signal to track enemy count
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
	else:
		print("EnemySpawner: Warning - enemy doesn't have enemy_died signal")
	
	# Add to world (use the scene root, not current_scene which might be different)
	get_tree().current_scene.add_child(enemy)
	print("EnemySpawner: Enemy added to scene at ", position)

func _on_enemy_died(_enemy):
	current_enemy_count -= 1
	print("EnemySpawner: Enemy died, remaining: ", current_enemy_count)
	
	# Respawn after some time if below half capacity
	if current_enemy_count < max_enemies_total / 2:
		spawn_timer = respawn_delay

func get_enemy_count() -> int:
	return current_enemy_count

# Debug function to manually spawn an enemy near player
func debug_spawn_near_player():
	if not player:
		find_player()
		if not player:
			print("EnemySpawner: Cannot debug spawn - no player found")
			return
	
	var spawn_offset = Vector2(100, 0) # Spawn to the right of player
	var spawn_position = player.global_position + spawn_offset
	spawn_enemy_at_position(spawn_position)
	current_enemy_count += 1
	print("EnemySpawner: Debug spawned enemy at ", spawn_position)

# Debug function to force spawn enemies
func force_spawn_enemies():
	print("EnemySpawner: Force spawning enemies...")
	try_spawn_enemies()

# Debug function to spawn enemy without restrictions
func debug_spawn_unrestricted():
	print("EnemySpawner: Debug spawning without distance restrictions...")
	if not world_generator or not player:
		print("EnemySpawner: Missing prerequisites for debug spawn")
		return
	
	var rooms = world_generator.rooms
	if rooms.size() == 0:
		print("EnemySpawner: No rooms available for debug spawn")
		return
	
	# Pick first room that's large enough
	for room in rooms:
		if room.width >= 6 and room.height >= 6:
			var spawn_x = room.x + 3
			var spawn_y = room.y + 3
			var spawn_position = Vector2(spawn_x * world_generator.TILE_SIZE + world_generator.TILE_SIZE/2, 
										 spawn_y * world_generator.TILE_SIZE + world_generator.TILE_SIZE/2)
			
			if is_valid_spawn_position(spawn_x, spawn_y):
				spawn_enemy_at_position(spawn_position)
				current_enemy_count += 1
				print("EnemySpawner: Debug spawned enemy at ", spawn_position)
				return
			else:
				print("EnemySpawner: Debug spawn position invalid")
	
	print("EnemySpawner: No suitable rooms found for debug spawn")

# Debug function to get status
func get_status():
	print("=== ENEMY SPAWNER STATUS ===")
	print("Current enemies: ", current_enemy_count, "/", max_enemies_total)
	print("World generator: ", "Found" if world_generator else "Missing")
	print("Player: ", "Found" if player else "Missing")
	if world_generator:
		print("Rooms available: ", world_generator.rooms.size())
	print("Spawn timer: ", spawn_timer)
	print("===========================")