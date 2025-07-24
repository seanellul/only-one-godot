extends Node2D

# World system that manages different zone types and transitions
class_name WorldSystemManager

# Zone types
enum ZoneType {
	TOWN, # Safe area with shops and NPCs
	DANGER_ZONE, # Combat areas with enemies and loot
	BOSS_ARENA, # Special boss encounters
	SECRET_AREA # Hidden areas with rare loot
}

# Current zone information
var current_zone_type: ZoneType = ZoneType.TOWN
var current_zone_level: int = 1
var current_zone_seed: int = 0

# Zone management
var zones = {}
var player_spawn_position: Vector2
var active_portals = []

# References
var player: CharacterBody2D
var town_generator: Node2D
var danger_zone_generator: Node2D
var portal_system: Node2D

signal zone_changed(old_zone: ZoneType, new_zone: ZoneType)
signal zone_cleared(zone_type: ZoneType, level: int)
signal player_spawned(spawn_position: Vector2)
signal zone_loaded(zone_type: String, zone_level: int)

func _ready():
	print("WorldSystemManager: Ready - waiting for initialization...")
	
	# Connect signals
	zone_changed.connect(_on_zone_changed)
	zone_cleared.connect(_on_zone_cleared)

func initialize_world():
	"""Initialize the world system - called by RoomController"""
	print("WorldSystemManager: Initializing world system...")
	
	# Initialize town as starting zone
	load_zone(ZoneType.TOWN, 1)
	
	# Set initial spawn position and emit signal
	player_spawn_position = Vector2(400, 300) # Default town center
	player_spawned.emit(player_spawn_position)

func load_zone(zone_type: ZoneType, level: int = 1, seed: int = -1):
	"""Load a specific zone type"""
	print("WorldSystemManager: Loading zone type ", zone_type, " level ", level)
	
	# Clear current world
	clear_current_world()
	
	# Set zone info
	current_zone_type = zone_type
	current_zone_level = level
	current_zone_seed = seed if seed != -1 else randi()
	
	# Generate the appropriate zone
	match zone_type:
		ZoneType.TOWN:
			generate_town()
		ZoneType.DANGER_ZONE:
			generate_danger_zone(level, current_zone_seed)
		ZoneType.BOSS_ARENA:
			generate_boss_arena(level, current_zone_seed)
		ZoneType.SECRET_AREA:
			generate_secret_area(level, current_zone_seed)
	
	# Spawn player at appropriate location
	spawn_player()
	
	# Emit signals
	zone_changed.emit(current_zone_type, zone_type)
	zone_loaded.emit(zone_type_to_string(zone_type), level)

func zone_type_to_string(zone_type: ZoneType) -> String:
	"""Convert zone type enum to string"""
	match zone_type:
		ZoneType.TOWN:
			return "town"
		ZoneType.DANGER_ZONE:
			return "danger_zone"
		ZoneType.BOSS_ARENA:
			return "boss_arena"
		ZoneType.SECRET_AREA:
			return "secret_area"
		_:
			return "unknown"

func regenerate_current_zone():
	"""Regenerate the current zone with a new seed"""
	print("WorldSystemManager: Regenerating current zone...")
	load_zone(current_zone_type, current_zone_level, randi())

func generate_town():
	"""Generate the safe town area"""
	print("WorldSystemManager: Generating town...")
	
	# Create town generator if it doesn't exist
	if not town_generator:
		town_generator = preload("res://scenes/world/TownGenerator.gd").new()
		add_child(town_generator)
	
	# Generate town layout
	town_generator.generate_town()
	player_spawn_position = town_generator.get_spawn_position()
	
	# Set up interactive elements
	setup_town_interactions()
	
	# Create portals to danger zones
	create_town_portals()

func generate_danger_zone(level: int, seed: int):
	"""Generate a dangerous area with enemies and loot"""
	print("WorldSystemManager: Generating danger zone level ", level, " with seed ", seed)
	
	# Create danger zone generator
	if not danger_zone_generator:
		danger_zone_generator = preload("res://scenes/world/DangerZoneGenerator.gd").new()
		add_child(danger_zone_generator)
	
	# Generate dangerous area
	danger_zone_generator.generate_zone(level, seed)
	player_spawn_position = danger_zone_generator.get_spawn_position()
	
	# Create return portal to town
	create_return_portal()

func generate_boss_arena(level: int, seed: int):
	"""Generate a boss encounter area"""
	print("WorldSystemManager: Generating boss arena level ", level)
	# TODO: Implement boss arena generation
	pass

func generate_secret_area(level: int, seed: int):
	"""Generate a hidden area with rare loot"""
	print("WorldSystemManager: Generating secret area level ", level)
	# TODO: Implement secret area generation
	pass

func setup_town_interactions():
	"""Set up interactive elements in the town"""
	if not town_generator:
		return
	
	print("WorldSystemManager: Setting up town interactions...")
	
	# Get interactive signs from town generator
	var interactive_signs = town_generator.get_interactive_signs()
	
	# Find the player's interaction system
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player = player_nodes[0]
		if player.has_method("get") and player.get("interaction_system"):
			var interaction_system = player.interaction_system
			interaction_system.register_interactive_signs(interactive_signs)
			print("WorldSystemManager: Registered ", interactive_signs.size(), " interactive signs")
		else:
			print("WorldSystemManager: Warning - Player has no interaction system")
	else:
		print("WorldSystemManager: Warning - No player found for interaction setup")

func create_town_portals():
	"""Create portals in town that lead to danger zones"""
	if not town_generator:
		return
	
	var portal_locations = town_generator.get_portal_locations()
	
	for i in range(portal_locations.size()):
		var portal_pos = portal_locations[i]
		var required_keys = i # First portal needs 0 keys, second needs 1, etc.
		var danger_level = i + 1
		
		# Special handling for the first portal (beginner dungeon)
		if i == 0:
			print("WorldSystemManager: Creating starting portal (no keys required)")
		
		create_portal(portal_pos, ZoneType.DANGER_ZONE, danger_level, required_keys)

func create_return_portal():
	"""Create a return portal back to town"""
	# Place the return portal inside the spawn room, near the player spawn
	var return_pos = player_spawn_position + Vector2(64, 0) # Offset from spawn
	
	# Ensure portal is accessible by placing it in a safe spot
	if danger_zone_generator and danger_zone_generator.rooms.size() > 0:
		var spawn_room = danger_zone_generator.rooms[0] # First room where player spawns
		# Place portal near the center of the spawn room but not on the player
		var room_center = Vector2(spawn_room.center_x * 32, spawn_room.center_y * 32)
		return_pos = room_center + Vector2(32, 32) # Slight offset from center
		print("WorldSystemManager: Placing return portal in spawn room at ", return_pos)
	else:
		print("WorldSystemManager: Using fallback return portal position at ", return_pos)
	
	create_portal(return_pos, ZoneType.TOWN, 1, 0) # No keys required to return

func create_portal(position: Vector2, destination_zone: ZoneType, destination_level: int, keys_required: int):
	"""Create a portal at the specified position"""
	var portal_scene = preload("res://scenes/world/Portal.tscn")
	var portal = portal_scene.instantiate()
	
	portal.global_position = position
	portal.setup_portal(destination_zone, destination_level, keys_required)
	portal.portal_activated.connect(_on_portal_activated)
	
	add_child(portal)
	active_portals.append(portal)
	
	print("WorldSystemManager: Created portal to ", destination_zone, " level ", destination_level, " (keys: ", keys_required, ")")

func _on_portal_activated(destination_zone: ZoneType, destination_level: int):
	"""Handle portal activation"""
	print("WorldSystemManager: Portal activated - traveling to ", destination_zone, " level ", destination_level)
	load_zone(destination_zone, destination_level)

func spawn_player():
	"""Spawn player at the appropriate location for current zone"""
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if player and player_spawn_position != Vector2.ZERO:
		player.global_position = player_spawn_position
		print("WorldSystemManager: Player spawned at ", player_spawn_position)
		player_spawned.emit(player_spawn_position)
	elif player_spawn_position != Vector2.ZERO:
		# Player not found yet, but we have a spawn position
		player_spawned.emit(player_spawn_position)

func clear_current_world():
	"""Clear the current world before loading a new zone"""
	print("WorldSystemManager: Clearing current world...")
	
	# Remove all active portals
	for portal in active_portals:
		if is_instance_valid(portal):
			portal.queue_free()
	active_portals.clear()
	
	# Clear generators
	if town_generator:
		town_generator.clear_town()
	if danger_zone_generator:
		danger_zone_generator.clear_zone()
	
	# Clear enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	
	# Clear items (but preserve player inventory)
	var items = get_tree().get_nodes_in_group("collectible_items")
	for item in items:
		item.queue_free()

func get_zone_info() -> Dictionary:
	"""Get information about the current zone"""
	return {
		"type": current_zone_type,
		"level": current_zone_level,
		"seed": current_zone_seed,
		"is_safe": current_zone_type == ZoneType.TOWN
	}

func _on_zone_changed(old_zone: ZoneType, new_zone: ZoneType):
	"""Handle zone transition effects"""
	print("WorldSystemManager: Zone changed from ", old_zone, " to ", new_zone)
	
	# Apply zone-specific effects
	match new_zone:
		ZoneType.TOWN:
			# Heal player when entering town
			if player and player.has_method("get_combat_system"):
				var combat_system = player.get_combat_system()
				if combat_system:
					combat_system.heal(999) # Full heal in town
		ZoneType.DANGER_ZONE:
			# Show danger warning
			print("WorldSystemManager: Entering dangerous area!")

func _on_zone_cleared(zone_type: ZoneType, level: int):
	"""Handle zone completion rewards"""
	print("WorldSystemManager: Zone cleared - ", zone_type, " level ", level)
	
	# Give rewards based on zone type and level
	var gold_reward = level * 50
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.add_item(0, gold_reward) # Add gold
		print("WorldSystemManager: Awarded ", gold_reward, " gold for clearing zone")

# Debug functions
func debug_travel_to_danger_zone(level: int = 1):
	"""Debug function to instantly travel to danger zone"""
	load_zone(ZoneType.DANGER_ZONE, level)

func debug_return_to_town():
	"""Debug function to instantly return to town"""
	load_zone(ZoneType.TOWN, 1)
