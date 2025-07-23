extends Control

@onready var debug_panel = get_node_or_null("DebugPanel")
@onready var debug_log = get_node_or_null("DebugPanel/VBox/ScrollContainer/DebugLog")
@onready var command_input = get_node_or_null("DebugPanel/VBox/CommandInput")

var is_debug_open = false
var command_history: Array[String] = []
var history_index = -1

func _ready():
	visible = false
	
	# Allow processing when paused so debug console can work
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure we're in the UI layer for proper rendering
	call_deferred("move_to_ui_layer")
	
	if command_input:
		command_input.text_submitted.connect(_on_command_submitted)


func move_to_ui_layer():
	# Try to find the UI CanvasLayer and move there if we're not already
	var ui_layer = get_node_or_null("../UI")
	if ui_layer and ui_layer is CanvasLayer:
		var current_parent = get_parent()
		if current_parent != ui_layer:
			current_parent.remove_child(self)
			ui_layer.add_child(self)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1: # Toggle debug console
				toggle_debug_console()
			KEY_BACKSLASH:
				toggle_debug_console()
			KEY_F2: # Quick spawn coins
				if is_debug_open:
					execute_command("give coin 10")
			KEY_F3: # Quick spawn all items
				if is_debug_open:
					execute_command("give all 5")
			KEY_F4: # Clear inventory
				if is_debug_open:
					execute_command("clear")
			KEY_ESCAPE: # Close debug console
				if is_debug_open:
					toggle_debug_console()

func toggle_debug_console():
	is_debug_open = !is_debug_open
	visible = is_debug_open
	
	if is_debug_open:
		# Ensure we're on top
		if get_parent():
			get_parent().move_child(self, -1) # Move to end (top layer)
		
		get_tree().paused = true
		if command_input:
			command_input.grab_focus()
		log_message("Debug Console Opened - Type 'help' for commands", Color.CYAN)
	else:
		# Only unpause if inventory is not open
		var inventory_ui = get_node_or_null("/root/Room/InventoryUI")
		if not inventory_ui or not inventory_ui.is_open:
			get_tree().paused = false
		if command_input:
			command_input.release_focus()

func _on_command_submitted(command: String):
	if command.strip_edges() != "":
		command_history.append(command)
		history_index = command_history.size()
		execute_command(command)
		command_input.text = ""

func execute_command(command: String):
	var parts = command.strip_edges().split(" ")
	var cmd = parts[0].to_lower()
	
	log_message("> " + command, Color.WHITE)
	
	match cmd:
		"help":
			show_help()
		"give":
			handle_give_command(parts)
		"clear":
			handle_clear_command()
		"status":
			handle_status_command()
		"spawn":
			handle_spawn_command(parts)
		"teleport", "tp":
			handle_teleport_command(parts)
		"speed":
			handle_speed_command(parts)
		"debug":
			handle_debug_command(parts)
		"test":
			handle_test_command(parts)
		"save":
			handle_save_command()
		"load":
			handle_load_command()
		"damage":
			handle_damage_command(parts)
		"heal":
			handle_heal_command(parts)
		"spawn_enemy":
			handle_spawn_enemy_command()
		"toggle_hitboxes":
			handle_toggle_hitboxes_command()
		"kill_enemies":
			handle_kill_enemies_command()
		"enemy_status":
			handle_enemy_status_command()
		"force_spawn":
			handle_force_spawn_command()
		"debug_spawn":
			handle_debug_spawn_command()
		"travel_town":
			handle_travel_town_command()
		"travel_danger":
			handle_travel_danger_command(parts)
		"give_keys":
			handle_give_keys_command(parts)
		"test_death":
			handle_test_death_command()
		"test_spawn":
			handle_test_spawn_command()
		"test_enemies":
			handle_test_enemies_command()
		"spawn_test_enemy":
			handle_spawn_test_enemy_command()
		"test_loot":
			handle_test_loot_command()
		"test_npcs":
			handle_test_npcs_command()
		_:
			log_message("Unknown command: " + cmd + ". Type 'help' for available commands.", Color.RED)

func show_help():
	var help_text = """
=== DEBUG CONSOLE COMMANDS ===

INVENTORY:
  give <item> <amount>    - Add items (coin, key, potion, speed, dash)
  give all <amount>       - Give amount of all items
  clear                   - Clear entire inventory
  status                  - Show inventory status

WORLD:
  spawn <item> <x> <y>    - Spawn item at coordinates
  teleport <x> <y>        - Teleport player to coordinates

PLAYER:
  speed <value>           - Set player speed
  upgrade <type>          - Apply upgrade (speed/dash)

COMBAT:
  damage <amount>         - Damage player (test combat)
  heal <amount>           - Heal player
  spawn_enemy             - Spawn enemy near player
  toggle_hitboxes         - Toggle hitbox debug visualization
  kill_enemies            - Kill all enemies
  enemy_status            - Show enemy spawner status
  force_spawn             - Force spawn enemies immediately
  debug_spawn             - Spawn enemy without distance restrictions

WORLD:
  travel_town             - Travel to town (safe area)
  travel_danger <level>   - Travel to danger zone
  give_keys <amount>      - Give keys for portal access
  test_death              - Test player death system
  test_spawn              - Test dungeon spawn positioning
  test_enemies            - Check enemy visibility and spawning
  spawn_test_enemy        - Spawn enemy right next to player for testing
  test_loot               - Check loot visibility and spawn test loot
  test_npcs               - Check NPC setup and interactions

DEBUG:
  debug collision         - Toggle collision debug
  debug pickup           - Toggle pickup radius debug
  test performance       - Run performance test
  test collection        - Test collection mechanics

SAVE/LOAD:
  save                   - Save current game state
  load                   - Load saved game state

HOTKEYS:
  F1 - Toggle Console    F2 - Give 10 coins
  F3 - Give 5 of all     F4 - Clear inventory
"""
	log_message(help_text, Color.YELLOW)

func handle_give_command(parts: Array):
	if parts.size() < 3:
		log_message("Usage: give <item> <amount> or give all <amount>", Color.RED)
		return
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	var item_name = parts[1].to_lower()
	var amount = parts[2].to_int()
	
	if amount <= 0:
		log_message("Amount must be positive!", Color.RED)
		return
	
	if item_name == "all":
		for i in range(5):
			inventory_system.add_item(i, amount)
		log_message("Added " + str(amount) + " of all items!", Color.GREEN)
	else:
		var item_types = {
			"coin": 0, "coins": 0,
			"key": 1, "keys": 1,
			"potion": 2, "potions": 2, "health": 2,
			"speed": 3, "speedboost": 3,
			"dash": 4, "dashboost": 4
		}
		
		if item_name in item_types:
			var item_type = item_types[item_name]
			inventory_system.add_item(item_type, amount)
			log_message("Added " + str(amount) + " " + item_name + "(s)!", Color.GREEN)
		else:
			log_message("Unknown item: " + item_name, Color.RED)

func handle_clear_command():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	# Clear all items
	for i in range(5):
		var count = inventory_system.get_item_count(i)
		if count > 0:
			inventory_system.remove_item(i, count)
	
	log_message("Inventory cleared!", Color.GREEN)

func handle_status_command():
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	var status_text = """
=== INVENTORY STATUS ===
Gold Coins: %d
Ancient Keys: %d
Health Potions: %d
Speed Boosts: %d
Dash Boosts: %d
Total Value: %d gold
""" % [
		inventory_system.get_item_count(0),
		inventory_system.get_item_count(1),
		inventory_system.get_item_count(2),
		inventory_system.get_item_count(3),
		inventory_system.get_item_count(4),
		inventory_system.get_total_value()
	]
	
	log_message(status_text, Color.CYAN)

func handle_spawn_command(parts: Array):
	if parts.size() < 4:
		log_message("Usage: spawn <item> <x> <y>", Color.RED)
		return
	
	var world_generator = get_node_or_null("../../WorldGenerator")
	if not world_generator:
		log_message("World generator not found!", Color.RED)
		return
	
	var item_name = parts[1].to_lower()
	var x = parts[2].to_int()
	var y = parts[3].to_int()
	
	# Spawn item at coordinates
	world_generator.create_collectible_item(x, y)
	log_message("Spawned " + item_name + " at (" + str(x) + ", " + str(y) + ")", Color.GREEN)

func handle_teleport_command(parts: Array):
	if parts.size() < 3:
		log_message("Usage: teleport <x> <y>", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	var x = parts[1].to_float()
	var y = parts[2].to_float()
	
	player.global_position = Vector2(x, y)
	log_message("Teleported to (" + str(x) + ", " + str(y) + ")", Color.GREEN)

func handle_speed_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: speed <value>", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	var new_speed = parts[1].to_float()
	if "SPEED" in player:
		player.SPEED = new_speed
		log_message("Player speed set to: " + str(new_speed), Color.GREEN)
	else:
		log_message("Cannot modify player speed!", Color.RED)

func handle_debug_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: debug <collision|pickup>", Color.RED)
		return
	
	var debug_type = parts[1].to_lower()
	
	match debug_type:
		"collision":
			get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint
			log_message("Collision debug: " + ("ON" if get_tree().debug_collisions_hint else "OFF"), Color.GREEN)
		"pickup":
			# Toggle pickup radius visualization
			log_message("Pickup radius debug toggled", Color.GREEN)
		_:
			log_message("Unknown debug type: " + debug_type, Color.RED)

func handle_test_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: test <performance|collection>", Color.RED)
		return
	
	var test_type = parts[1].to_lower()
	
	match test_type:
		"performance":
			run_performance_test()
		"collection":
			run_collection_test()
		_:
			log_message("Unknown test type: " + test_type, Color.RED)

func run_performance_test():
	log_message("Running performance test...", Color.YELLOW)
	
	# Simulate rapid item collection
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		for i in range(100):
			inventory_system.add_item(0, 1) # Add 100 coins
	
	log_message("Performance test completed - Added 100 items", Color.GREEN)

func run_collection_test():
	log_message("Running collection test...", Color.YELLOW)
	
	# Test all item types
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		for i in range(5):
			inventory_system.add_item(i, 1)
		log_message("Collection test completed - Added 1 of each item type", Color.GREEN)

func handle_save_command():
	# Simple save functionality
	log_message("Save functionality not implemented yet", Color.YELLOW)

func handle_load_command():
	# Simple load functionality
	log_message("Load functionality not implemented yet", Color.YELLOW)

# Combat debug commands
func handle_damage_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: damage <amount>", Color.RED)
		return
	
	var amount = parts[1].to_int()
	if amount <= 0:
		log_message("Damage amount must be positive!", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(amount)
		log_message("Dealt " + str(amount) + " damage to player", Color.ORANGE)
	else:
		log_message("Player not found or cannot take damage", Color.RED)

func handle_heal_command(parts: Array):
	if parts.size() < 2:
		log_message("Usage: heal <amount>", Color.RED)
		return
	
	var amount = parts[1].to_int()
	if amount <= 0:
		log_message("Heal amount must be positive!", Color.RED)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_combat_system"):
		var combat_system = player.get_combat_system()
		if combat_system and combat_system.has_method("heal"):
			combat_system.heal(amount)
			log_message("Healed player for " + str(amount) + " health", Color.GREEN)
		else:
			log_message("Player combat system not found", Color.RED)
	else:
		log_message("Player not found", Color.RED)

func handle_spawn_enemy_command():
	var spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	if spawner and spawner.has_method("debug_spawn_near_player"):
		spawner.debug_spawn_near_player()
		log_message("Spawned enemy near player", Color.GREEN)
	else:
		log_message("Enemy spawner not found", Color.RED)

func handle_toggle_hitboxes_command():
	# Toggle hitbox visibility globally
	var hitboxes = get_tree().get_nodes_in_group("attack_hitboxes")
	if hitboxes.size() == 0:
		log_message("No active hitboxes to toggle", Color.YELLOW)
		return
	
	var toggle_state = not hitboxes[0].debug_visible
	for hitbox in hitboxes:
		if hitbox.has_method("set_debug_visible"):
			hitbox.set_debug_visible(toggle_state)
	
	log_message("Hitbox debug visibility: " + ("ON" if toggle_state else "OFF"), Color.CYAN)

func handle_kill_enemies_command():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var killed_count = 0
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(9999) # Overkill damage
			killed_count += 1
	
	log_message("Killed " + str(killed_count) + " enemies", Color.RED)

func log_message(message: String, color: Color = Color.WHITE):
	if not debug_log:
		return
	
	var label = RichTextLabel.new()
	label.fit_content = true
	label.bbcode_enabled = true
	label.append_text("[color=" + color.to_html() + "]" + message + "[/color]")
	debug_log.add_child(label)
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll_container = debug_log.get_parent()
	if scroll_container is ScrollContainer:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func handle_enemy_status_command():
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if not enemy_spawner:
		# Try alternative path
		enemy_spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	
	if not enemy_spawner:
		log_message("Enemy spawner not found!", Color.RED)
		return
	
	if enemy_spawner.has_method("get_status"):
		enemy_spawner.get_status()
		log_message("Enemy spawner status printed to output (check terminal)", Color.CYAN)
	else:
		log_message("Current enemies: " + str(enemy_spawner.get_enemy_count()), Color.GREEN)

func handle_force_spawn_command():
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if not enemy_spawner:
		# Try alternative path
		enemy_spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	
	if not enemy_spawner:
		log_message("Enemy spawner not found!", Color.RED)
		return
	
	if enemy_spawner.has_method("force_spawn_enemies"):
		enemy_spawner.force_spawn_enemies()
		log_message("Forced enemy spawn attempt", Color.GREEN)
	else:
		log_message("Force spawn method not available", Color.RED)

func handle_debug_spawn_command():
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if not enemy_spawner:
		# Try alternative path
		enemy_spawner = get_tree().current_scene.get_node_or_null("EnemySpawner")
	
	if not enemy_spawner:
		log_message("Enemy spawner not found!", Color.RED)
		return
	
	if enemy_spawner.has_method("debug_spawn_unrestricted"):
		enemy_spawner.debug_spawn_unrestricted()
		log_message("Debug spawn attempt (no distance restrictions)", Color.GREEN)
	else:
		log_message("Debug spawn method not available", Color.RED)

func handle_travel_town_command():
	var world_manager = get_tree().current_scene.get_node_or_null("WorldSystemManager")
	if not world_manager:
		log_message("World system manager not found!", Color.RED)
		return
	
	if world_manager.has_method("debug_return_to_town"):
		world_manager.debug_return_to_town()
		log_message("Traveling to town...", Color.GREEN)
	else:
		log_message("Travel method not available", Color.RED)

func handle_travel_danger_command(parts: Array):
	var level = 1
	if parts.size() > 1:
		level = parts[1].to_int()
	
	var world_manager = get_tree().current_scene.get_node_or_null("WorldSystemManager")
	if not world_manager:
		log_message("World system manager not found!", Color.RED)
		return
	
	if world_manager.has_method("debug_travel_to_danger_zone"):
		world_manager.debug_travel_to_danger_zone(level)
		log_message("Traveling to danger zone level " + str(level) + "...", Color.GREEN)
	else:
		log_message("Travel method not available", Color.RED)

func handle_give_keys_command(parts: Array):
	var amount = 5
	if parts.size() > 1:
		amount = parts[1].to_int()
	
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if not inventory_system:
		log_message("Inventory system not found!", Color.RED)
		return
	
	inventory_system.add_item(1, amount) # Keys are item type 1
	log_message("Added " + str(amount) + " keys to inventory", Color.GREEN)

func handle_test_death_command():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	var combat_system = player.get_combat_system()
	if not combat_system:
		log_message("Combat system not found!", Color.RED)
		return
	
	# Kill the player for testing
	combat_system.current_health = 0
	combat_system.die()
	log_message("Triggered player death for testing", Color.YELLOW)

func handle_test_spawn_command():
	# Test dungeon spawning multiple times
	var world_manager = get_tree().current_scene.get_node_or_null("WorldSystemManager")
	if not world_manager:
		log_message("World manager not found!", Color.RED)
		return
	
	# Go to a danger zone and check spawn
	world_manager.load_zone(world_manager.ZoneType.DANGER_ZONE, 1, randi())
	log_message("Regenerated danger zone for spawn testing", Color.CYAN)
	
	# Wait a moment then report player position
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		log_message("Player position: " + str(player.global_position), Color.GREEN)
	else:
		log_message("Player not found!", Color.RED)

func handle_test_enemies_command():
	# Check for enemies in the current scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	log_message("Found " + str(enemies.size()) + " enemies in scene", Color.CYAN)
	
	if enemies.size() == 0:
		log_message("No enemies found - checking danger zone generator...", Color.YELLOW)
		var world_manager = get_tree().current_scene.get_node_or_null("WorldSystemManager")
		if world_manager and world_manager.danger_zone_generator:
			var spawned_count = world_manager.danger_zone_generator.enemies_spawned.size()
			log_message("Danger zone generator has " + str(spawned_count) + " enemies spawned", Color.CYAN)
		else:
			log_message("No danger zone generator found", Color.RED)
	else:
		for i in range(min(3, enemies.size())):
			var enemy = enemies[i]
			log_message("Enemy " + str(i) + " at " + str(enemy.global_position), Color.GREEN)
			if enemy.has_method("get_debug_info"):
				var info = enemy.get_debug_info()
				log_message("  Health: " + info.health + " State: " + info.state, Color.WHITE)

func handle_spawn_test_enemy_command():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	# Spawn an enemy right next to the player for visibility testing
	var enemy_scene = preload("res://scenes/enemies/BasicEnemy.tscn")
	var enemy = enemy_scene.instantiate()
	
	# Position it 50 pixels to the right of the player
	enemy.global_position = player.global_position + Vector2(50, 0)
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	
	log_message("Spawned test enemy at " + str(enemy.global_position), Color.GREEN)

func handle_test_loot_command():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	# Check existing loot
	var loot_items = get_tree().get_nodes_in_group("collectible_items")
	log_message("Found " + str(loot_items.size()) + " loot items in scene", Color.CYAN)
	
	for i in range(min(3, loot_items.size())):
		var item = loot_items[i]
		log_message("Loot " + str(i) + ": type " + str(item.item_type_index) + " at " + str(item.global_position), Color.GREEN)
	
	# Spawn test loot near player
	var collectible_scene = preload("res://scenes/items/CollectibleItem.tscn")
	var test_item = collectible_scene.instantiate()
	test_item.item_type_index = 0 # Coin
	test_item.global_position = player.global_position + Vector2(60, 0)
	test_item.z_index = 50
	
	get_tree().current_scene.add_child(test_item)
	log_message("Spawned test coin at " + str(test_item.global_position), Color.YELLOW)

func handle_test_npcs_command():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		log_message("Player not found!", Color.RED)
		return
	
	# Find NPCs in the scene
	var npcs = []
	var all_nodes = get_tree().get_nodes_in_group("shopnpc")
	if all_nodes.size() == 0:
		# Try finding by class name
		all_nodes = get_all_nodes_of_type(get_tree().current_scene, "ShopNPC")
	
	log_message("Found " + str(all_nodes.size()) + " NPCs in scene", Color.CYAN)
	
	for npc in all_nodes:
		if npc.has_method("get_global_position"):
			var distance = player.global_position.distance_to(npc.global_position)
			log_message("NPC " + npc.shop_type + " at " + str(npc.global_position) + " (distance: " + str(int(distance)) + ")", Color.GREEN)
			
			# Check if player is in range
			if distance < 100:
				log_message("  Player is close to this NPC!", Color.YELLOW)

func get_all_nodes_of_type(node: Node, type_name: String) -> Array:
	var result = []
	if node.get_script() and node.get_script().get_global_name() == type_name:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(get_all_nodes_of_type(child, type_name))
	
	return result
