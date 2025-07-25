extends Node

const SAVE_FILE_PATH = "user://savegame.dat"

# Signals
signal game_saved()
signal game_loaded()

# Game state data structure
var game_data = {
	"player_name": "SIR KNIGHT",
	"player_health": 100,
	"player_max_health": 100,
	"player_damage": 25,
	"player_position": {"x": 0, "y": 0},
	"current_zone": "town",
	"inventory": {},
	"upgrades": {},
	"collection_data": {},
	"play_time": 0.0,
	"save_timestamp": ""
}

func save_game():
	"""Save current game state to file"""
	print("SaveSystem: Saving game...")
	
	# Update save timestamp
	game_data.save_timestamp = Time.get_datetime_string_from_system()
	
	# Collect current game state
	collect_game_state()
	
	# Write to file
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(game_data))
		save_file.close()
		print("SaveSystem: Game saved successfully")
		game_saved.emit()
		return true
	else:
		print("SaveSystem: Failed to save game!")
		return false

func load_game() -> Dictionary:
	"""Load game state from file"""
	print("SaveSystem: Loading game...")
	
	if not has_save_file():
		print("SaveSystem: No save file found")
		return {}
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var loaded_data = json.data
			# Merge loaded data with defaults (in case of missing keys)
			for key in game_data:
				if key in loaded_data:
					game_data[key] = loaded_data[key]
			
			print("SaveSystem: Game loaded successfully")
			game_loaded.emit()
			return game_data
		else:
			print("SaveSystem: Failed to parse save file")
			return {}
	else:
		print("SaveSystem: Failed to open save file")
		return {}

func has_save_file() -> bool:
	"""Check if save file exists"""
	return FileAccess.file_exists(SAVE_FILE_PATH)

func delete_save():
	"""Delete the save file"""
	if has_save_file():
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("SaveSystem: Save file deleted")

func collect_game_state():
	"""Collect current game state from various systems"""
	DebugManager.log_info(DebugManager.DebugCategory.SAVE, "=== COLLECTING GAME STATE ===")
	
	# Get player data
	var player = get_player()
	if player:
		# Store position as dictionary for JSON compatibility
		var pos = player.global_position
		game_data.player_position = {"x": pos.x, "y": pos.y}
		print("SaveSystem: Player position: ", pos)
		
		# Get health AND damage from combat system (includes merchant upgrades!)
		var combat_system = get_player_combat_system()
		if combat_system:
			var combat_stats = combat_system.get_combat_stats()
			game_data.player_health = combat_stats.health
			game_data.player_max_health = combat_stats.max_health
			# Add damage to save data - this includes weapon upgrades from merchants!
			game_data.player_damage = combat_stats.get("damage", 25)
			print("SaveSystem: Combat stats - Health: ", combat_stats.health, "/", combat_stats.max_health, " Damage: ", combat_stats.get("damage", 25))
		else:
			# Fallback values
			game_data.player_health = 100
			game_data.player_max_health = 100
			game_data.player_damage = 25
			print("SaveSystem: Using fallback combat values")
	
	# Get current zone/area
	var world_manager = get_node_or_null("/root/WorldSystemManager")
	if world_manager:
		var zone_type = world_manager.get("current_zone_type")
		game_data.current_zone = zone_type if zone_type != null else "town"
		print("SaveSystem: Current zone: ", game_data.current_zone)
	
	# Get inventory data
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system and inventory_system.has_method("get_save_data"):
		game_data.inventory = inventory_system.get_save_data()
		print("SaveSystem: Inventory saved: ", game_data.inventory)
	else:
		print("SaveSystem: InventorySystem not found or missing save method")
		game_data.inventory = {}
	
	# Get upgrade data (speed/dash boosts)
	var player_upgrades = get_player_upgrades()
	if player_upgrades and player_upgrades.has_method("get_save_data"):
		game_data.upgrades = player_upgrades.get_save_data()
		print("SaveSystem: Upgrades saved: ", game_data.upgrades)
	else:
		print("SaveSystem: PlayerUpgrades system not found or missing save method")
		game_data.upgrades = {}
	
	# Get collection tracker data (achievements, milestones)
	var collection_tracker = get_node_or_null("/root/CollectionTracker")
	if collection_tracker and collection_tracker.has_method("get_save_data"):
		game_data.collection_data = collection_tracker.get_save_data()
		print("SaveSystem: Collection data saved")
	else:
		print("SaveSystem: CollectionTracker not found or no save method")
		game_data.collection_data = {}
	
	print("SaveSystem: === COLLECTION COMPLETE ===")
	print("SaveSystem: Final save data: ", game_data)

func apply_game_state(data: Dictionary):
	"""Apply loaded game state to various systems"""
	if data.is_empty():
		return
	
	# Apply player data
	var player = get_player()
	if player:
		# Set player position - handle different formats from save data
		var position_data = data.get("player_position", {"x": 0, "y": 0})
		if position_data is Dictionary and "x" in position_data and "y" in position_data:
			# New format: dictionary with x and y keys
			player.global_position = Vector2(position_data.x, position_data.y)
		elif position_data is String:
			# Legacy format: parse string representation of Vector2 like "(x, y)"
			var pos_string = position_data.strip_edges("()")
			var coords = pos_string.split(",")
			if coords.size() >= 2:
				var x = coords[0].strip_edges().to_float()
				var y = coords[1].strip_edges().to_float()
				player.global_position = Vector2(x, y)
			else:
				player.global_position = Vector2.ZERO
		elif position_data is Vector2:
			# Direct Vector2 (shouldn't happen in JSON but just in case)
			player.global_position = position_data
		else:
			player.global_position = Vector2.ZERO
		
		# Apply health AND damage through combat system
		var combat_system = get_player_combat_system()
		if combat_system:
			combat_system.set_health(data.get("player_health", 100))
			combat_system.set_max_health(data.get("player_max_health", 100))
			# Apply damage upgrades from merchants!
			combat_system.set_damage(data.get("player_damage", 25))
			print("SaveSystem: Restored combat stats - Health: ", data.get("player_health", 100), "/", data.get("player_max_health", 100), " Damage: ", data.get("player_damage", 25))
	
	# Apply inventory data
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system and inventory_system.has_method("load_save_data"):
		print("SaveSystem: Loading inventory data...")
		inventory_system.load_save_data(data.get("inventory", {}))
	else:
		print("SaveSystem: InventorySystem not available for loading")
	
	# Apply upgrade data
	var player_upgrades = get_player_upgrades()
	if player_upgrades and player_upgrades.has_method("load_save_data"):
		print("SaveSystem: Loading upgrade data...")
		player_upgrades.load_save_data(data.get("upgrades", {}))
	else:
		print("SaveSystem: PlayerUpgrades not available for loading")
	
	# Apply collection tracker data (achievements, milestones)
	var collection_tracker = get_node_or_null("/root/CollectionTracker")
	if collection_tracker and collection_tracker.has_method("load_save_data"):
		print("SaveSystem: Loading collection data...")
		collection_tracker.load_save_data(data.get("collection_data", {}))
	else:
		print("SaveSystem: CollectionTracker not available for loading")

func get_player():
	"""Get reference to player node"""
	# Try multiple common paths for player
	var player_paths = [
		"/root/Room/Player",
		"/root/WorldSystemManager/Player",
		"/root/Main/Player"
	]
	
	for path in player_paths:
		var player = get_node_or_null(path)
		if player:
			return player
	
	# Search for player by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	return null

func get_player_upgrades():
	"""Get reference to player upgrades system"""
	var player = get_player()
	if player and player.has_node("PlayerUpgrades"):
		return player.get_node("PlayerUpgrades")
	return null

func get_player_combat_system():
	"""Get reference to player combat system"""
	var player = get_player()
	if player and player.has_node("CombatSystem"):
		return player.get_node("CombatSystem")
	return null

func get_spawn_position() -> Vector2:
	"""Get the position where player should spawn"""
	var position_data = game_data.get("player_position", {"x": 0, "y": 0})
	if position_data is Dictionary and "x" in position_data and "y" in position_data:
		return Vector2(position_data.x, position_data.y)
	else:
		return Vector2.ZERO

func get_current_zone() -> String:
	"""Get the zone player should be in"""
	return game_data.get("current_zone", "town")
