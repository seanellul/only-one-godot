extends Node

# Contextual hints system for smart tutorial messages and gameplay tips

# Hint management
var active_hints: Array[Dictionary] = []
var shown_hints: Array[String] = []
var hint_ui: Control
var hint_timer: Timer

# Player behavior tracking
var player_stats: Dictionary = {
	"movement_time": 0.0,
	"combat_encounters": 0,
	"inventory_opens": 0,
	"deaths": 0,
	"zones_visited": 0,
	"shops_visited": 0,
	"items_collected": 0,
	"time_in_danger": 0.0,
	"time_in_menus": 0.0,
	"last_save_time": 0.0
}

var game_start_time: float = 0.0

# Hint conditions and triggers
var hint_definitions: Array[Dictionary] = []

# UI settings
var hint_display_duration: float = 8.0
var hint_fade_duration: float = 1.0
var max_concurrent_hints: int = 3

# Signals
signal hint_shown(hint_id: String)
signal hint_dismissed(hint_id: String)

func _ready():
	# Record game start time
	game_start_time = Time.get_unix_time_from_system()
	
	setup_hint_definitions()
	create_hint_ui()
	setup_behavior_tracking()
	
	# Setup hint timer
	hint_timer = Timer.new()
	hint_timer.wait_time = 1.0
	hint_timer.autostart = true
	hint_timer.timeout.connect(_on_hint_timer_timeout)
	if DebugManager.safe_add_child(self, hint_timer, "ContextualHints timer"):
		DebugManager.log_info(DebugManager.DebugCategory.HINTS, "System initialized with " + str(hint_definitions.size()) + " hint definitions")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to initialize hint timer")

func setup_hint_definitions():
	"""Define all contextual hints with their triggers and conditions"""
	hint_definitions = [
		{
			"id": "movement_tutorial",
			"title": "Movement Basics",
			"text": "Use WASD or Arrow Keys to move your character around the world.",
			"icon": "🚶",
			"condition": func(): return player_stats.movement_time < 5.0,
			"trigger": "on_game_start",
			"priority": 10,
			"category": "tutorial"
		},
		{
			"id": "inventory_hint",
			"title": "Inventory Management",
			"text": "Press TAB to open your inventory and manage items. Try the different sorting options!",
			"icon": "🎒",
			"condition": func(): return player_stats.items_collected >= 3 and player_stats.inventory_opens == 0,
			"trigger": "items_collected",
			"priority": 8,
			"category": "tutorial"
		},
		{
			"id": "combat_tutorial",
			"title": "Combat System",
			"text": "Left-click to attack enemies. Time your attacks carefully!",
			"icon": "⚔️",
			"condition": func(): return player_stats.combat_encounters == 0,
			"trigger": "enemy_nearby",
			"priority": 9,
			"category": "tutorial"
		},
		{
			"id": "low_health_warning",
			"title": "Low Health!",
			"text": "Your health is low! Visit shops to buy health upgrades or find healing items.",
			"icon": "❤️",
			"condition": func(): return get_player_health_percentage() < 0.3,
			"trigger": "health_check",
			"priority": 7,
			"category": "warning"
		},
		{
			"id": "save_reminder",
			"title": "Don't Forget to Save",
			"text": "Press ESC to save your progress and return to the main menu.",
			"icon": "💾",
			"condition": func(): return (get_elapsed_time() - player_stats.last_save_time) > 300.0, # 5 minutes
			"trigger": "time_based",
			"priority": 5,
			"category": "reminder"
		},
		{
			"id": "shop_tutorial",
			"title": "Shopping Tips",
			"text": "Shops offer powerful upgrades! Save up gold to improve your character's abilities.",
			"icon": "🏪",
			"condition": func(): return player_stats.shops_visited == 0 and get_player_gold() >= 50,
			"trigger": "near_shop",
			"priority": 6,
			"category": "tutorial"
		},
		{
			"id": "danger_zone_warning",
			"title": "Danger Ahead!",
			"text": "You're entering a dangerous area. Make sure you're prepared for combat!",
			"icon": "⚠️",
			"condition": func(): return true, # Always show when entering danger
			"trigger": "entering_danger_zone",
			"priority": 8,
			"category": "warning"
		},
		{
			"id": "item_magnetism_tip",
			"title": "Item Collection",
			"text": "Items automatically move toward you when you're close! No need to walk directly over them.",
			"icon": "🧲",
			"condition": func(): return player_stats.items_collected >= 10,
			"trigger": "items_collected",
			"priority": 4,
			"category": "tip"
		},
		{
			"id": "minimap_tip",
			"title": "Navigation Help",
			"text": "Check the minimap in the bottom-right corner to see shops, portals, and your location!",
			"icon": "🗺️",
			"condition": func(): return player_stats.zones_visited >= 2,
			"trigger": "zone_change",
			"priority": 5,
			"category": "tip"
		},
		{
			"id": "hotkey_tip",
			"title": "Quick Item Use",
			"text": "Press 1, 2, or 3 to quickly use health potions and boost items from your inventory!",
			"icon": "🔢",
			"condition": func(): return player_stats.inventory_opens >= 3,
			"trigger": "inventory_usage",
			"priority": 4,
			"category": "tip"
		}
	]

func create_hint_ui():
	"""Create the hint display UI"""
	hint_ui = Control.new()
	hint_ui.name = "ContextualHints"
	hint_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to current scene
	var current_scene = get_tree().current_scene
	if DebugManager.safe_add_child(current_scene, hint_ui, "ContextualHints UI"):
		DebugManager.log_info(DebugManager.DebugCategory.HINTS, "Hint UI created and added to scene")
	else:
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to add hint UI to scene")

func setup_behavior_tracking():
	"""Connect to various game systems to track player behavior"""
	# Track player movement
	call_deferred("connect_player_tracking")
	
	# Track inventory usage
	if DebugManager.validate_autoload("InventorySystem"):
		DebugManager.safe_connect_signal(InventorySystem, "item_collected", _on_item_collected, "ContextualHints item tracking")
	
	# Track save events
	if DebugManager.validate_autoload("SaveSystem"):
		DebugManager.safe_connect_signal(SaveSystem, "game_saved", _on_game_saved, "ContextualHints save tracking")
	
	# Track zone changes
	var world_manager = DebugManager.safe_get_node("/root/WorldSystemManager", "ContextualHints zone tracking")
	if world_manager:
		DebugManager.safe_connect_signal(world_manager, "zone_changed", _on_zone_changed, "ContextualHints zone changes")

func connect_player_tracking():
	"""Connect to player-specific tracking"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Track combat
		var combat_system = player.get_node_or_null("CombatSystem")
		if combat_system and combat_system.has_signal("player_died"):
			combat_system.player_died.connect(_on_player_died)
	
	# Start tracking movement
	set_process(true)

func _process(delta):
	"""Track continuous behaviors"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Track if player is moving
		if player.has_method("get_velocity"):
			var velocity = player.get_velocity()
			if velocity.length() > 10:
				player_stats.movement_time += delta
		
		# Check for nearby enemies (simple distance check)
		check_for_nearby_enemies()
	
	# Check time-based hints
	check_time_based_hints()

func check_for_nearby_enemies():
	"""Check if player is near enemies for combat tutorial"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_first_node_in_group("player")
	
	if player and enemies.size() > 0:
		for enemy in enemies:
			if player.global_position.distance_to(enemy.global_position) < 150:
				trigger_hint("enemy_nearby")
				break

func check_time_based_hints():
	"""Check for time-based hint conditions"""
	trigger_hint("time_based")
	trigger_hint("health_check")

func trigger_hint(trigger_type: String):
	"""Trigger hints based on specific events"""
	for hint_def in hint_definitions:
		if hint_def.trigger == trigger_type and hint_def.id not in shown_hints:
			if hint_def.condition.call():
				show_hint(hint_def)

func show_hint(hint_def: Dictionary):
	"""Display a contextual hint"""
	if hint_def.id in shown_hints:
		return
	
	if active_hints.size() >= max_concurrent_hints:
		# Remove oldest hint if at limit
		dismiss_hint(active_hints[0].id)
	
	# Mark as shown
	shown_hints.append(hint_def.id)
	
	# Create hint UI
	var hint_panel = create_hint_panel(hint_def)
	if not DebugManager.safe_add_child(hint_ui, hint_panel, "ContextualHints hint panel"):
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to add hint panel for: " + hint_def.title)
		return
	
	# Add to active hints
	active_hints.append({
		"id": hint_def.id,
		"panel": hint_panel,
		"show_time": get_elapsed_time()
	})
	
	# Animate hint in
	animate_hint_in(hint_panel)
	
	# Auto-dismiss after delay
	var dismiss_timer = Timer.new()
	dismiss_timer.wait_time = hint_display_duration
	dismiss_timer.one_shot = true
	dismiss_timer.timeout.connect(func(): dismiss_hint(hint_def.id))
	if not DebugManager.safe_add_child(self, dismiss_timer, "ContextualHints dismiss timer"):
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to add dismiss timer for hint: " + hint_def.title)
		return
	dismiss_timer.start()
	
	hint_shown.emit(hint_def.id)
	DebugManager.log_info(DebugManager.DebugCategory.HINTS, "Showing hint: " + hint_def.title)

func create_hint_panel(hint_def: Dictionary) -> Control:
	"""Create the visual panel for a hint"""
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(350, 80)
	
	# Position hints in top-left, stacked vertically
	var y_offset = active_hints.size() * 90 + 20
	panel.position = Vector2(20, y_offset)
	
	# Style the panel
	var panel_style = StyleBoxFlat.new()
	match hint_def.category:
		"tutorial":
			panel_style.bg_color = Color(0.2, 0.3, 0.4, 0.95) # Blue tint
		"warning":
			panel_style.bg_color = Color(0.4, 0.2, 0.2, 0.95) # Red tint
		"tip":
			panel_style.bg_color = Color(0.2, 0.4, 0.2, 0.95) # Green tint
		"reminder":
			panel_style.bg_color = Color(0.4, 0.3, 0.2, 0.95) # Orange tint
		_:
			panel_style.bg_color = Color(0.2, 0.2, 0.2, 0.95) # Default gray
	
	panel_style.border_color = Color(0.8, 0.8, 0.8, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0, 0, 0, 0.3)
	panel_style.shadow_size = 4
	panel_style.shadow_offset = Vector2(2, 2)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Content container
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(10, 10)
	hbox.size = Vector2(330, 60)
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = hint_def.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(30, 60)
	hbox.add_child(icon_label)
	
	# Text content
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = hint_def.title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	text_vbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = hint_def.text
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(desc_label)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(25, 25)
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.pressed.connect(func(): dismiss_hint(hint_def.id))
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.6, 0.2, 0.2, 0.8)
	close_style.corner_radius_top_left = 12
	close_style.corner_radius_top_right = 12
	close_style.corner_radius_bottom_left = 12
	close_style.corner_radius_bottom_right = 12
	close_button.add_theme_stylebox_override("normal", close_style)
	
	close_button.position = Vector2(320, 5)
	panel.add_child(close_button)
	
	return panel

func animate_hint_in(panel: Control):
	"""Animate hint panel sliding in"""
	if not panel or not is_instance_valid(panel):
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Invalid panel provided for hint animation")
		return
	
	panel.modulate.a = 0.0
	panel.position.x = - panel.size.x
	
	var tween = DebugManager.safe_create_tween(self, "ContextualHints animate_hint_in")
	if not tween:
		DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to create tween for hint animation")
		return
	
	tween.set_parallel(true)
	DebugManager.safe_tween_property(tween, panel, "modulate:a", 1.0, hint_fade_duration, "hint fade in")
	DebugManager.safe_tween_property(tween, panel, "position:x", 20.0, hint_fade_duration, "hint slide in")

func dismiss_hint(hint_id: String):
	"""Dismiss a specific hint"""
	for i in range(active_hints.size()):
		var hint_data = active_hints[i]
		if hint_data.id == hint_id:
			var panel = hint_data.panel
			
			if not panel or not is_instance_valid(panel):
				DebugManager.log_warning(DebugManager.DebugCategory.HINTS, "Panel already invalid for hint: " + hint_id)
				active_hints.remove_at(i)
				break
			
			# Animate out with safety
			var tween = DebugManager.safe_create_tween(self, "ContextualHints dismiss_hint")
			if not tween:
				DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to create dismiss tween, removing immediately")
				panel.queue_free()
				active_hints.remove_at(i)
				break
			
			tween.set_parallel(true)
			if DebugManager.safe_tween_property(tween, panel, "modulate:a", 0.0, hint_fade_duration, "hint fade out"):
				DebugManager.safe_tween_property(tween, panel, "position:x", -panel.size.x, hint_fade_duration, "hint slide out")
				
				# Remove after animation with safety
				DebugManager.safe_tween_callback(tween, func():
					if is_instance_valid(panel):
						panel.queue_free()
					else:
						DebugManager.log_info(DebugManager.DebugCategory.HINTS, "Panel already freed during animation")
				, hint_fade_duration, "hint cleanup callback")
			else:
				DebugManager.log_error(DebugManager.DebugCategory.HINTS, "Failed to create fade out tween, cleaning up immediately")
				panel.queue_free()
			
			# Remove from active hints
			active_hints.remove_at(i)
			
			# Reposition remaining hints
			reposition_hints()
			
			hint_dismissed.emit(hint_id)
			DebugManager.log_info(DebugManager.DebugCategory.HINTS, "Dismissed hint: " + hint_id)
			break

func reposition_hints():
	"""Reposition active hints after one is dismissed"""
	for i in range(active_hints.size()):
		var hint_data = active_hints[i]
		var panel = hint_data.panel
		
		if not panel or not is_instance_valid(panel):
			DebugManager.log_warning(DebugManager.DebugCategory.HINTS, "Invalid panel found during repositioning, skipping")
			continue
		
		var new_y = i * 90 + 20
		
		var tween = DebugManager.safe_create_tween(self, "ContextualHints reposition_hints")
		if tween:
			DebugManager.safe_tween_property(tween, panel, "position:y", new_y, 0.3, "hint reposition")
		else:
			# Fallback to immediate positioning
			panel.position.y = new_y
			DebugManager.log_warning(DebugManager.DebugCategory.HINTS, "Failed to create reposition tween, using immediate positioning")

func _on_hint_timer_timeout():
	"""Regular check for hint conditions"""
	trigger_hint("on_game_start")
	trigger_hint("items_collected")
	trigger_hint("inventory_usage")

# Event handlers for behavior tracking

func _on_item_collected(item_type: int, amount: int):
	"""Track item collection"""
	player_stats.items_collected += amount
	trigger_hint("items_collected")

func _on_game_saved():
	"""Track when game is saved"""
	player_stats.last_save_time = get_elapsed_time()

func _on_zone_changed(old_zone: String, new_zone: String):
	"""Track zone changes"""
	player_stats.zones_visited += 1
	trigger_hint("zone_change")
	
	if new_zone == "DANGER_ZONE":
		trigger_hint("entering_danger_zone")

func _on_player_died():
	"""Track player deaths"""
	player_stats.deaths += 1

func _on_inventory_opened():
	"""Track inventory usage"""
	player_stats.inventory_opens += 1
	trigger_hint("inventory_usage")

func _on_shop_visited():
	"""Track shop visits"""
	player_stats.shops_visited += 1

# Helper functions

func get_player_health_percentage() -> float:
	"""Get current player health as percentage"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var combat_system = player.get_node_or_null("CombatSystem")
		if combat_system:
			var stats = combat_system.get_combat_stats()
			return float(stats.health) / float(stats.max_health)
	return 1.0

func get_player_gold() -> int:
	"""Get current player gold amount"""
	if InventorySystem:
		return InventorySystem.get_item_count(0) # Coins
	return 0

# Public interface

func force_show_hint(hint_id: String):
	"""Force show a specific hint by ID"""
	for hint_def in hint_definitions:
		if hint_def.id == hint_id:
			show_hint(hint_def)
			break

func disable_hint_category(category: String):
	"""Disable all hints in a specific category"""
	for hint_def in hint_definitions:
		if hint_def.category == category:
			if hint_def.id not in shown_hints:
				shown_hints.append(hint_def.id)

func reset_shown_hints():
	"""Reset all shown hints (for testing)"""
	shown_hints.clear()
	
	# Dismiss all active hints
	for hint_data in active_hints:
		dismiss_hint(hint_data.id)

func get_player_stats() -> Dictionary:
	"""Get current player behavior stats"""
	return player_stats.duplicate()

func get_elapsed_time() -> float:
	"""Get time elapsed since game start"""
	return Time.get_unix_time_from_system() - game_start_time
