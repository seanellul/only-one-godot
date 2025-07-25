extends Node

# Auto-save checkpoint system for seamless progress protection

# Auto-save settings
var auto_save_enabled: bool = true
var save_cooldown: float = 2.0 # Minimum time between auto-saves
var last_save_time: float = 0.0
var game_start_time: float = 0.0

# Visual feedback
var save_icon: Control
var save_animation_duration: float = 2.0

# Checkpoint tracking
var last_zone: String = ""
var last_shop_visit: String = ""
var last_health: int = 0
var last_gold: int = 0

# Signals
signal auto_save_triggered(checkpoint_type: String)
signal auto_save_completed(checkpoint_type: String)

func _ready():
	# Record game start time
	game_start_time = Time.get_unix_time_from_system()
	
	# Connect to relevant game events
	connect_to_game_events()
	
	# Create save icon UI
	create_save_icon()
	
	DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "AutoSaveManager initialized and ready")

func connect_to_game_events():
	"""Connect to various game systems for auto-save triggers"""
	
	# Connect to SaveSystem signals if available
	if DebugManager.validate_autoload("SaveSystem"):
		DebugManager.safe_connect_signal(SaveSystem, "game_saved", _on_save_completed, "AutoSaveManager save tracking")
	
	# Connect to zone changes
	var world_manager = DebugManager.safe_get_node("/root/WorldSystemManager", "AutoSaveManager zone tracking")
	if world_manager:
		DebugManager.safe_connect_signal(world_manager, "zone_changed", _on_zone_changed, "AutoSaveManager zone changes")
	
	# Connect to inventory changes for major pickups
	if DebugManager.validate_autoload("InventorySystem"):
		DebugManager.safe_connect_signal(InventorySystem, "item_collected", _on_item_collected, "AutoSaveManager item tracking")

func create_save_icon():
	"""Create the visual save icon indicator"""
	save_icon = Control.new()
	save_icon.name = "AutoSaveIcon"
	
	# Position in top-right corner
	save_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	save_icon.position = Vector2(-80, 20)
	save_icon.size = Vector2(60, 30)
	
	# Create background
	var bg = ColorRect.new()
	bg.size = Vector2(60, 30)
	bg.color = Color(0, 0, 0, 0.7)
	bg.name = "Background"
	save_icon.add_child(bg)
	
	# Create save text label
	var label = Label.new()
	label.text = "SAVED"
	label.size = Vector2(60, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.name = "SaveLabel"
	save_icon.add_child(label)
	
	# Start invisible
	save_icon.modulate.a = 0.0
	
	# Add to current scene
	var current_scene = get_tree().current_scene
	if DebugManager.safe_add_child(current_scene, save_icon, "AutoSaveManager save icon"):
		DebugManager.log_info(DebugManager.DebugCategory.UI, "Save icon created and added to scene")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to add save icon to scene")

func trigger_auto_save(checkpoint_type: String, force: bool = false):
	"""Trigger an auto-save if conditions are met"""
	if not auto_save_enabled:
		return
		
	var current_time = get_elapsed_time()
	
	# Check cooldown unless forced
	if not force and (current_time - last_save_time) < save_cooldown:
		DebugManager.log_info(DebugManager.DebugCategory.SAVE, "Auto-save skipped - cooldown active (%s seconds remaining)" % (save_cooldown - (current_time - last_save_time)))
		return
	
	# Update save time
	last_save_time = current_time
	
	DebugManager.log_info(DebugManager.DebugCategory.SAVE, "Triggering auto-save - Type: " + checkpoint_type)
	auto_save_triggered.emit(checkpoint_type)
	
	# Perform the save
	if DebugManager.validate_autoload("SaveSystem"):
		SaveSystem.save_game()
		show_save_feedback()
	else:
		DebugManager.log_error(DebugManager.DebugCategory.SAVE, "SaveSystem not available for auto-save")

func show_save_feedback():
	"""Show visual feedback that game was saved"""
	if not save_icon or not is_instance_valid(save_icon):
		DebugManager.log_warning(DebugManager.DebugCategory.UI, "Cannot show save feedback - save icon not valid")
		return
	
	# Double-check save_icon is still valid and has required properties
	if not save_icon.has_method("get") or not "modulate" in save_icon:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Save icon missing required properties for animation")
		return
		
	# Animate save icon with extreme safety
	var tween = create_tween()
	if not tween or not is_instance_valid(tween):
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create tween for save feedback")
		return
	
	# Kill any existing tweens to prevent conflicts
	tween.kill()
	tween = create_tween()
	
	if not tween:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to recreate tween after kill")
		return
		
	tween.set_parallel(true)
	
	# Validate save_icon is still valid before each tween operation
	if is_instance_valid(save_icon) and "modulate" in save_icon:
		# Fade in
		var fade_in_tween = tween.tween_property(save_icon, "modulate:a", 1.0, 0.3)
		if not fade_in_tween:
			DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create fade in tween")
			return
		
		# Hold visible
		var hold_tween = tween.tween_property(save_icon, "modulate:a", 1.0, save_animation_duration - 0.6).set_delay(0.3)
		if not hold_tween:
			DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create hold tween")
			return
		
		# Fade out
		var fade_out_tween = tween.tween_property(save_icon, "modulate:a", 0.0, 0.3).set_delay(save_animation_duration - 0.3)
		if not fade_out_tween:
			DebugManager.log_error(DebugManager.DebugCategory.UI, "Failed to create fade out tween")
			return
		
		DebugManager.log_info(DebugManager.DebugCategory.UI, "Save feedback animation started successfully")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.UI, "Save icon became invalid during tween setup")

# Event handlers for auto-save triggers

func _on_zone_changed(old_zone: String, new_zone: String):
	"""Auto-save when changing zones"""
	if old_zone != new_zone:
		trigger_auto_save("zone_transition")
		last_zone = new_zone

func _on_item_collected(item_type, amount: int):
	"""Auto-save for significant item pickups"""
	# Save for important items (keys, major upgrades)
	match item_type:
		1: # Keys are always important
			trigger_auto_save("key_collected")
		0: # Gold - save for large amounts
			var inventory = get_node_or_null("/root/InventorySystem")
			if inventory:
				var current_gold = inventory.get_item_count(0)
				if current_gold > last_gold + 50: # Significant gold gain
					trigger_auto_save("gold_milestone")
					last_gold = current_gold

func _on_save_completed():
	"""Handle when save operation completes"""
	auto_save_completed.emit("auto_save")

func _on_shop_purchase(shop_type: String, item_name: String):
	"""Auto-save after shop purchases"""
	trigger_auto_save("shop_purchase")
	last_shop_visit = shop_type

func _on_player_upgrade(upgrade_type: String):
	"""Auto-save after player upgrades"""
	trigger_auto_save("player_upgrade")

func _on_boss_defeated(boss_name: String):
	"""Auto-save after major encounters"""
	trigger_auto_save("boss_defeated", true) # Force save for boss kills

func _on_health_milestone():
	"""Auto-save when player reaches health milestones"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var combat_system = player.get_node_or_null("CombatSystem")
		if combat_system:
			var current_health = combat_system.max_health
			# Save when max health increases significantly
			if current_health > last_health + 25:
				trigger_auto_save("health_upgrade")
				last_health = current_health

# Public methods for manual triggering

func checkpoint_zone_enter(zone_name: String):
	"""Checkpoint when entering a new zone"""
	trigger_auto_save("zone_enter_" + zone_name)

func checkpoint_before_danger(danger_type: String):
	"""Checkpoint before entering dangerous areas"""
	trigger_auto_save("pre_danger_" + danger_type, true)

func checkpoint_quest_progress(quest_id: String):
	"""Checkpoint for quest progression"""
	trigger_auto_save("quest_" + quest_id)

func checkpoint_manual():
	"""Manual checkpoint (like from pause menu)"""
	trigger_auto_save("manual", true)

# Settings and configuration

func set_auto_save_enabled(enabled: bool):
	"""Enable or disable auto-save system"""
	auto_save_enabled = enabled
	print("AutoSaveManager: Auto-save ", "enabled" if enabled else "disabled")

func set_save_cooldown(cooldown: float):
	"""Set minimum time between auto-saves"""
	save_cooldown = max(0.5, cooldown)
	print("AutoSaveManager: Save cooldown set to ", save_cooldown, " seconds")

func get_last_checkpoint_info() -> Dictionary:
	"""Get information about the last checkpoint"""
	return {
		"last_save_time": last_save_time,
		"last_zone": last_zone,
		"last_shop_visit": last_shop_visit,
		"time_since_save": get_elapsed_time() - last_save_time
	}

func get_elapsed_time() -> float:
	"""Get time elapsed since game start"""
	return Time.get_unix_time_from_system() - game_start_time
