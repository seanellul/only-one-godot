extends Control

@onready var inventory_panel = $InventoryPanel
@onready var item_grid = $InventoryPanel/VBoxContainer/MainHSplit/LeftPanel/ScrollContainer/ItemGrid
@onready var stats_label = $InventoryPanel/VBoxContainer/MainHSplit/RightPanel/StatsLabel
@onready var close_button = $InventoryPanel/VBoxContainer/CloseButton

var is_open = false

# Smart sorting system
enum SortType {
	BY_TYPE, # Default: coins, keys, potions, upgrades
	BY_VALUE, # Highest value items first
	BY_QUANTITY, # Most owned items first
	BY_RECENT, # Recently collected items first
	BY_USAGE # Most used items first
}

var current_sort_type: SortType = SortType.BY_TYPE
var sort_buttons: Array[Button] = []
var last_collected_items: Array = [] # Track recent collections
var item_usage_count: Dictionary = {} # Track how often items are used

func _ready():
	# Start hidden
	visible = false
	
	# Debug: Check if @onready nodes are found
	print("InventoryUI: inventory_panel = ", inventory_panel)
	print("InventoryUI: item_grid = ", item_grid)
	print("InventoryUI: stats_label = ", stats_label)
	print("InventoryUI: close_button = ", close_button)
	
	# Style the main inventory panel
	call_deferred("setup_main_panel_styling")
	
	# Setup smart sorting UI
	call_deferred("setup_sorting_ui")
	
	# Ensure we're in the UI layer for proper rendering
	call_deferred("move_to_ui_layer")
	
	# Add to inventory_ui group for easy finding
	add_to_group("inventory_ui")
	
	# Connect inventory updates - use get_node to avoid typing issues
	var inventory_system = get_node_or_null("/root/InventorySystem")
	if inventory_system:
		inventory_system.inventory_updated.connect(_on_inventory_updated)
		if inventory_system.has_signal("item_collected"):
			inventory_system.item_collected.connect(_on_item_collected_for_sorting)
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(close_inventory)
	
	# Initial update - wait a frame to ensure nodes are ready
	call_deferred("_on_inventory_updated")

func setup_main_panel_styling():
	if not inventory_panel:
		return
		
	# Create a stunning main panel style with premium look
	var main_style = StyleBoxFlat.new()
	
	# Rich gradient-like dark background
	main_style.bg_color = Color(0.02, 0.02, 0.05, 0.98)
	
	# Elegant gold border with enhanced thickness
	main_style.border_color = Color(0.85, 0.65, 0.25, 1.0)
	main_style.border_width_left = 4
	main_style.border_width_right = 4
	main_style.border_width_top = 4
	main_style.border_width_bottom = 4
	
	# Smooth, premium rounded corners
	main_style.corner_radius_top_left = 16
	main_style.corner_radius_top_right = 16
	main_style.corner_radius_bottom_left = 16
	main_style.corner_radius_bottom_right = 16
	
	# Sophisticated shadow with golden glow
	main_style.shadow_color = Color(0.85, 0.65, 0.25, 0.4)
	main_style.shadow_size = 12
	main_style.shadow_offset = Vector2(0, 6)
	
	inventory_panel.add_theme_stylebox_override("panel", main_style)
	
	# Style the headers
	var inventory_header = get_node_or_null("InventoryPanel/VBoxContainer/MainHSplit/LeftPanel/InventoryHeader")
	if inventory_header:
		inventory_header.add_theme_font_size_override("font_size", 16)
		inventory_header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4, 1.0))
		inventory_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		inventory_header.add_theme_constant_override("shadow_offset_x", 1)
		inventory_header.add_theme_constant_override("shadow_offset_y", 1)
	
	# Style the close button with premium appearance
	if close_button:
		var button_style = StyleBoxFlat.new()
		button_style.bg_color = Color(0.25, 0.18, 0.08, 0.95)
		button_style.border_color = Color(0.7, 0.55, 0.25, 1.0)
		button_style.border_width_left = 3
		button_style.border_width_right = 3
		button_style.border_width_top = 3
		button_style.border_width_bottom = 3
		button_style.corner_radius_top_left = 8
		button_style.corner_radius_top_right = 8
		button_style.corner_radius_bottom_left = 8
		button_style.corner_radius_bottom_right = 8
		close_button.add_theme_stylebox_override("normal", button_style)
		
		var button_hover = button_style.duplicate()
		button_hover.bg_color = Color(0.35, 0.26, 0.12, 0.95)
		button_hover.border_color = Color(0.8, 0.65, 0.3, 1.0)
		close_button.add_theme_stylebox_override("hover", button_hover)
		
		var button_pressed = button_style.duplicate()
		button_pressed.bg_color = Color(0.15, 0.12, 0.05, 0.95)
		close_button.add_theme_stylebox_override("pressed", button_pressed)
		
		close_button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 1.0))
		close_button.add_theme_font_size_override("font_size", 14)
		close_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		close_button.add_theme_constant_override("shadow_offset_x", 1)
		close_button.add_theme_constant_override("shadow_offset_y", 1)
	
	# Style the stats label
	if stats_label:
		stats_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
		stats_label.add_theme_font_size_override("font_size", 12)

func move_to_ui_layer():
	# Try to find the UI CanvasLayer and move there if we're not already
	var ui_layer = get_node_or_null("../UI")
	if ui_layer and ui_layer is CanvasLayer:
		print("InventoryUI: Moving to UI layer")
		var current_parent = get_parent()
		if current_parent != ui_layer:
			current_parent.remove_child(self)
			ui_layer.add_child(self)
			print("InventoryUI: Successfully moved to UI layer")
	else:
		print("InventoryUI: UI layer not found, staying in current parent")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_TAB:
				toggle_inventory()
			KEY_ESCAPE:
				if is_open:
					close_inventory()

func toggle_inventory():
	if is_open:
		close_inventory()
	else:
		open_inventory()

func open_inventory():
	is_open = true
	visible = true
	
	# Track inventory opening for contextual hints (safely)
	var contextual_hints = get_node_or_null("/root/ContextualHints")
	if contextual_hints and is_instance_valid(contextual_hints) and contextual_hints.has_method("_on_inventory_opened"):
		contextual_hints._on_inventory_opened()
	
	# Ensure we're on top
	if get_parent():
		get_parent().move_child(self, -1) # Move to end (top layer)
	
	# Add opening animation
	if inventory_panel:
		inventory_panel.modulate = Color(1, 1, 1, 0)
		inventory_panel.scale = Vector2(0.8, 0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(inventory_panel, "modulate", Color(1, 1, 1, 1), 0.3)
		tween.tween_property(inventory_panel, "scale", Vector2(1.0, 1.0), 0.3)
	
	# get_tree().paused = true
	_on_inventory_updated()

func close_inventory():
	# Add closing animation
	if inventory_panel:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(inventory_panel, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_property(inventory_panel, "scale", Vector2(0.8, 0.8), 0.2)
		
		# Wait for animation to complete before hiding
		await tween.finished
	
	is_open = false
	visible = false
	# Only unpause if debug console is not open
	var debug_console = get_node_or_null("/root/Room/DebugConsole")
	if not debug_console or not debug_console.is_debug_open:
		get_tree().paused = false

func setup_sorting_ui():
	"""Add smart sorting buttons to the inventory UI"""
	# Find the left panel header area to add sorting buttons
	var left_panel = inventory_panel.get_node_or_null("VBoxContainer/MainHSplit/LeftPanel")
	if not left_panel:
		return
		
	# Create sorting button container
	var sort_container = HBoxContainer.new()
	sort_container.name = "SortingContainer"
	sort_container.add_theme_constant_override("separation", 5)
	
	# Add sorting label
	var sort_label = Label.new()
	sort_label.text = "Sort:"
	sort_label.add_theme_font_size_override("font_size", 10)
	sort_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	sort_container.add_child(sort_label)
	
	# Create sort buttons
	var sort_options = [
		{"name": "Type", "type": SortType.BY_TYPE},
		{"name": "Value", "type": SortType.BY_VALUE},
		{"name": "Qty", "type": SortType.BY_QUANTITY},
		{"name": "Recent", "type": SortType.BY_RECENT}
	]
	
	for option in sort_options:
		var button = Button.new()
		button.text = option.name
		button.custom_minimum_size = Vector2(50, 25)
		button.add_theme_font_size_override("font_size", 9)
		
		# Style the button
		var button_style = StyleBoxFlat.new()
		if option.type == current_sort_type:
			button_style.bg_color = Color(0.4, 0.3, 0.2, 0.9) # Active
		else:
			button_style.bg_color = Color(0.2, 0.2, 0.25, 0.8) # Inactive
		button_style.border_color = Color(0.6, 0.5, 0.3, 0.8)
		button_style.border_width_left = 1
		button_style.border_width_right = 1
		button_style.border_width_top = 1
		button_style.border_width_bottom = 1
		button_style.corner_radius_top_left = 3
		button_style.corner_radius_top_right = 3
		button_style.corner_radius_bottom_left = 3
		button_style.corner_radius_bottom_right = 3
		button.add_theme_stylebox_override("normal", button_style)
		
		# Connect button press
		var sort_type = option.type
		button.pressed.connect(func(): change_sort_type(sort_type))
		
		sort_buttons.append(button)
		sort_container.add_child(button)
	
	# Insert sorting container after the header
	var header = left_panel.get_node_or_null("InventoryHeader")
	if header:
		var header_index = header.get_index()
		left_panel.add_child(sort_container)
		left_panel.move_child(sort_container, header_index + 1)

func change_sort_type(new_sort_type: SortType):
	"""Change the current sort type and refresh inventory"""
	current_sort_type = new_sort_type
	
	# Update button appearances
	for i in range(sort_buttons.size()):
		var button = sort_buttons[i]
		var button_style = StyleBoxFlat.new()
		if i == current_sort_type:
			button_style.bg_color = Color(0.4, 0.3, 0.2, 0.9) # Active
		else:
			button_style.bg_color = Color(0.2, 0.2, 0.25, 0.8) # Inactive
		button_style.border_color = Color(0.6, 0.5, 0.3, 0.8)
		button_style.border_width_left = 1
		button_style.border_width_right = 1
		button_style.border_width_top = 1
		button_style.border_width_bottom = 1
		button_style.corner_radius_top_left = 3
		button_style.corner_radius_top_right = 3
		button_style.corner_radius_bottom_left = 3
		button_style.corner_radius_bottom_right = 3
		button.add_theme_stylebox_override("normal", button_style)
	
	# Refresh inventory with new sort
	_on_inventory_updated()
	print("InventoryUI: Sort changed to ", SortType.keys()[current_sort_type])

func get_sorted_item_types() -> Array:
	"""Get item types sorted according to current sort type"""
	var base_item_types = [
		InventorySystem.ItemType.COIN,
		InventorySystem.ItemType.KEY,
		InventorySystem.ItemType.HEALTH_POTION,
		InventorySystem.ItemType.SPEED_BOOST,
		InventorySystem.ItemType.DASH_BOOST
	]
	
	# Filter to only include items we have (except coins)
	var available_items = []
	for item_type in base_item_types:
		var count = InventorySystem.get_item_count(item_type)
		if count > 0 or item_type == InventorySystem.ItemType.COIN:
			available_items.append(item_type)
	
	# Sort based on current sort type
	match current_sort_type:
		SortType.BY_TYPE:
			# Default order: coins, keys, potions, upgrades
			return available_items
			
		SortType.BY_VALUE:
			# Sort by item value (coins worth most, then keys, etc.)
			var value_map = {
				InventorySystem.ItemType.COIN: 1000,
				InventorySystem.ItemType.KEY: 500,
				InventorySystem.ItemType.HEALTH_POTION: 100,
				InventorySystem.ItemType.SPEED_BOOST: 300,
				InventorySystem.ItemType.DASH_BOOST: 350
			}
			available_items.sort_custom(func(a, b):
				return value_map.get(a, 0) > value_map.get(b, 0)
			)
			return available_items
			
		SortType.BY_QUANTITY:
			# Sort by quantity owned (most first)
			available_items.sort_custom(func(a, b):
				var count_a = InventorySystem.get_item_count(a)
				var count_b = InventorySystem.get_item_count(b)
				return count_a > count_b
			)
			return available_items
			
		SortType.BY_RECENT:
			# Sort by recently collected (most recent first)
			var recent_sorted = []
			var remaining = available_items.duplicate()
			
			# Add recently collected items first
			for item_type in last_collected_items:
				if item_type in remaining:
					recent_sorted.append(item_type)
					remaining.erase(item_type)
			
			# Add remaining items
			recent_sorted.append_array(remaining)
			return recent_sorted
			
		SortType.BY_USAGE:
			# Sort by usage frequency (most used first)
			available_items.sort_custom(func(a, b):
				var usage_a = item_usage_count.get(a, 0)
				var usage_b = item_usage_count.get(b, 0)
				return usage_a > usage_b
			)
			return available_items
	
	return available_items

func track_item_collection(item_type: int):
	"""Track when an item is collected for recent sorting"""
	# Add to front of recent list
	if item_type in last_collected_items:
		last_collected_items.erase(item_type)
	last_collected_items.push_front(item_type)
	
	# Keep only last 10 items
	if last_collected_items.size() > 10:
		last_collected_items.resize(10)

func track_item_usage(item_type: int):
	"""Track when an item is used for usage-based sorting"""
	if item_type not in item_usage_count:
		item_usage_count[item_type] = 0
	item_usage_count[item_type] += 1

func _on_item_collected_for_sorting(item_type: int, amount: int):
	"""Handle item collection for smart sorting tracking"""
	track_item_collection(item_type)
	print("InventoryUI: Tracked collection of ", InventorySystem.ItemType.keys()[item_type] if item_type < InventorySystem.ItemType.size() else "Unknown")

func _on_inventory_updated():
	if not InventorySystem:
		return
		
	if not item_grid:
		return
		
	# Clear existing items
	for child in item_grid.get_children():
		child.queue_free()
	
	# Create a grid container for better layout
	var grid_container = GridContainer.new()
	grid_container.columns = 1 # Single column for clean vertical layout
	grid_container.add_theme_constant_override("v_separation", 8)
	item_grid.add_child(grid_container)
	
	# Get sorted item types
	var sorted_item_types = get_sorted_item_types()
	
	# Add item slots in sorted order
	for item_type in sorted_item_types:
		var count = InventorySystem.get_item_count(item_type)
		var item_info = get_item_info(item_type)
		var slot_data = create_inventory_slot()
		var slot = slot_data.slot
		setup_item_slot(slot_data, item_type, count, item_info.name, item_info.color, item_info.description)
		grid_container.add_child(slot)
	
	# Update stats
	update_stats_display()

func get_item_info(item_type):
	var item_names = ["Gold Coin", "Ancient Key", "Health Potion", "Speed Boost", "Dash Boost"]
	var item_colors = [Color.GOLD, Color.SILVER, Color.RED, Color.CYAN, Color.LIGHT_BLUE]
	var item_descriptions = [
		"Valuable currency for trading",
		"Opens mysterious doors",
		"Restores health when consumed",
		"Increases movement speed",
		"Enhances dash abilities"
	]
	
	return {
		"name": item_names[item_type] if item_type < item_names.size() else "Unknown Item",
		"color": item_colors[item_type] if item_type < item_colors.size() else Color.WHITE,
		"description": item_descriptions[item_type] if item_type < item_descriptions.size() else "No description"
	}

func create_item_slot(_item_type_index, count, item_name, color, description):
	var slot_data = create_inventory_slot()
	var slot = slot_data.slot
	var color_rect = slot_data.color_rect
	var name_label = slot_data.name_label
	var count_label = slot_data.count_label
	var desc_label = slot_data.desc_label
	
	# Set up item visual
	color_rect.color = color
	
	# Set up item info
	name_label.text = item_name
	count_label.text = str(count)
	desc_label.text = description
	
	# Add hover effects
	add_hover_effects(slot, color_rect, name_label)
	
	item_grid.add_child(slot)

func setup_item_slot(slot_data: Dictionary, _item_type_index: int, count: int, item_name: String, color: Color, description: String):
	var color_rect = slot_data.color_rect
	var name_label = slot_data.name_label
	var count_label = slot_data.count_label
	var desc_label = slot_data.desc_label
	
	# Set up item visual
	color_rect.color = color
	
	# Set up item info
	name_label.text = item_name
	count_label.text = str(count)
	desc_label.text = description
	
	# Add hover effects
	add_hover_effects(slot_data.slot, color_rect, name_label)

func add_hover_effects(slot: Control, icon: ColorRect, label: Label):
	# Add mouse detection
	slot.mouse_entered.connect(func(): on_slot_hover_enter(slot, icon, label))
	slot.mouse_exited.connect(func(): on_slot_hover_exit(slot, icon, label))

func on_slot_hover_enter(slot: Control, icon: ColorRect, label: Label):
	# Create premium hover animation with multiple effects
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Subtle scale up with smooth easing
	tween.tween_property(slot, "scale", Vector2(1.03, 1.03), 0.25).set_ease(Tween.EASE_OUT)
	
	# Golden glow effect
	tween.tween_property(slot, "modulate", Color(1.1, 1.08, 1.05, 1.0), 0.25)
	
	# Enhanced icon brightness with warm tone
	tween.tween_property(icon, "modulate", Color(1.15, 1.12, 1.08, 1.0), 0.25)
	
	# Subtle label enhancement
	tween.tween_property(label, "modulate", Color(1.08, 1.06, 1.04, 1.0), 0.25)
	
	# Gentle upward float
	var original_pos = slot.position
	slot.set_meta("original_position", original_pos)
	tween.tween_property(slot, "position", original_pos + Vector2(0, -3), 0.25).set_ease(Tween.EASE_OUT)

func on_slot_hover_exit(slot: Control, icon: ColorRect, label: Label):
	# Create smooth exit animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale back to normal with smooth easing
	tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_IN_OUT)
	
	# Return modulation to normal
	tween.tween_property(slot, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	# Return icon to normal brightness
	tween.tween_property(icon, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	# Return label to normal brightness
	tween.tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	# Return to original position
	var original_pos = slot.get_meta("original_position", slot.position)
	tween.tween_property(slot, "position", original_pos, 0.3).set_ease(Tween.EASE_IN_OUT)

func create_inventory_slot() -> Dictionary:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(260, 68) # Properly sized to fit container
	
	# Background panel with premium styling
	var panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create a sophisticated stylebox for the panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.06, 0.06, 0.1, 0.96) # Rich dark background
	style_box.border_color = Color(0.6, 0.45, 0.2, 0.85) # Subtle golden border
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	
	# Add subtle depth with inner shadow
	style_box.shadow_color = Color(0, 0, 0, 0.4)
	style_box.shadow_size = 4
	style_box.shadow_offset = Vector2(0, 2)
	
	panel.add_theme_stylebox_override("panel", style_box)
	slot.add_child(panel)
	
	# Item icon background (decorative circle)
	# Enhanced icon background with elegant styling
	var icon_bg = Panel.new()
	icon_bg.size = Vector2(50, 50)
	icon_bg.position = Vector2(12, 11)
	
	# Style the icon background
	var icon_bg_style = StyleBoxFlat.new()
	icon_bg_style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	icon_bg_style.border_color = Color(0.45, 0.35, 0.15, 0.7)
	icon_bg_style.border_width_left = 1
	icon_bg_style.border_width_right = 1
	icon_bg_style.border_width_top = 1
	icon_bg_style.border_width_bottom = 1
	icon_bg_style.corner_radius_top_left = 6
	icon_bg_style.corner_radius_top_right = 6
	icon_bg_style.corner_radius_bottom_left = 6
	icon_bg_style.corner_radius_bottom_right = 6
	icon_bg.add_theme_stylebox_override("panel", icon_bg_style)
	slot.add_child(icon_bg)
	
	# Item icon with refined positioning
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(38, 38)
	color_rect.position = Vector2(6, 6)
	color_rect.color = Color.WHITE
	icon_bg.add_child(color_rect)
	
	# Enhanced shine effect
	var shine = ColorRect.new()
	shine.size = Vector2(15, 15)
	shine.position = Vector2(8, 8)
	shine.color = Color(1.0, 1.0, 1.0, 0.35)
	icon_bg.add_child(shine)
	
	# Info container with proper sizing
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(70, 8) # Adjusted for smaller slot
	vbox.size = Vector2(180, 52) # Properly sized to fit within slot
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)
	
	# Item name with better styling
	# Item name with premium typography
	var name_label = Label.new()
	name_label.text = "Item Name"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75, 1.0)) # Enhanced warm tone
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(name_label)
	
	# Count container with refined spacing
	var count_container = HBoxContainer.new()
	count_container.add_theme_constant_override("separation", 4)
	vbox.add_child(count_container)
	
	# Count label with enhanced styling
	var count_icon = Label.new()
	count_icon.text = "×"
	count_icon.add_theme_font_size_override("font_size", 13)
	count_icon.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	count_container.add_child(count_icon)
	
	var count_label = Label.new()
	count_label.text = "0"
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
	count_container.add_child(count_label)
	
	# Item description with enhanced readability
	var desc_label = Label.new()
	desc_label.text = "Description"
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0)) # Improved contrast
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.clip_contents = true
	vbox.add_child(desc_label)
	
	return {
		"slot": slot,
		"color_rect": color_rect,
		"name_label": name_label,
		"count_label": count_label,
		"desc_label": desc_label
	}

func update_stats_display():
	if not stats_label:
		return
		
	# Clear the existing label and create a custom stats panel
	if not stats_label.get_parent():
		return
		
	# Hide the default stats label and create our custom panel
	stats_label.visible = false
	
	# Check if we already created the custom stats panel
	var stats_container = stats_label.get_parent().get_node_or_null("CustomStatsPanel")
	if not stats_container:
		create_custom_stats_panel()
	else:
		# Update existing panel
		update_custom_stats_panel(stats_container)

func create_custom_stats_panel():
	var parent = stats_label.get_parent()
	if not parent:
		return
		
	# Create main stats container
	var stats_container = VBoxContainer.new()
	stats_container.name = "CustomStatsPanel"
	stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_container.add_theme_constant_override("separation", 8)
	parent.add_child(stats_container)
	
	# Create character display section
	create_character_display(stats_container)
	
	# Create player stats section
	create_player_stats(stats_container)
	
	# Create character progression section
	create_progression_stats(stats_container)

func update_custom_stats_panel(stats_container: VBoxContainer):
	# Clear and rebuild the stats (simpler than updating individual elements)
	for child in stats_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Recreate sections
	create_character_display(stats_container)
	create_player_stats(stats_container)
	create_progression_stats(stats_container)

func create_character_display(container: VBoxContainer):
	# Character section header
	var char_header = Label.new()
	char_header.text = "🏛️ CHARACTER"
	char_header.add_theme_font_size_override("font_size", 16)
	char_header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
	char_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(char_header)
	
	# Character display panel
	var char_panel = Panel.new()
	char_panel.custom_minimum_size = Vector2(160, 180)
	
	# Style the character panel
	var char_style = StyleBoxFlat.new()
	char_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	char_style.border_color = Color(0.6, 0.5, 0.2, 1.0)
	char_style.border_width_left = 2
	char_style.border_width_right = 2
	char_style.border_width_top = 2
	char_style.border_width_bottom = 2
	char_style.corner_radius_top_left = 8
	char_style.corner_radius_top_right = 8
	char_style.corner_radius_bottom_left = 8
	char_style.corner_radius_bottom_right = 8
	char_panel.add_theme_stylebox_override("panel", char_style)
	container.add_child(char_panel)
	
	# Character name at top
	var name_label = Label.new()
	name_label.text = "⚔️ SIR KNIGHT"
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 12)
	name_label.size = Vector2(160, 22)
	char_panel.add_child(name_label)
	
	# Character class/level info
	var class_label = Label.new()
	class_label.text = "Noble Adventurer • Level 1"
	class_label.add_theme_font_size_override("font_size", 10)
	class_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_label.position = Vector2(0, 34)
	class_label.size = Vector2(160, 16)
	char_panel.add_child(class_label)
	
	# Create animated knight sprite
	create_character_sprite(char_panel)

func create_character_sprite(char_panel: Panel):
	# Create a background for the sprite
	var sprite_container = Panel.new()
	sprite_container.position = Vector2(40, 55)
	sprite_container.size = Vector2(80, 100)
	
	# Style the sprite container
	var sprite_bg_style = StyleBoxFlat.new()
	sprite_bg_style.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	sprite_bg_style.border_color = Color(0.3, 0.3, 0.3, 0.6)
	sprite_bg_style.border_width_left = 1
	sprite_bg_style.border_width_right = 1
	sprite_bg_style.border_width_top = 1
	sprite_bg_style.border_width_bottom = 1
	sprite_bg_style.corner_radius_top_left = 4
	sprite_bg_style.corner_radius_top_right = 4
	sprite_bg_style.corner_radius_bottom_left = 4
	sprite_bg_style.corner_radius_bottom_right = 4
	sprite_container.add_theme_stylebox_override("panel", sprite_bg_style)
	char_panel.add_child(sprite_container)
	
	# Create the animated sprite
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.position = Vector2(40, 50)
	animated_sprite.scale = Vector2(2.0, 2.0)
	
	# Load the knight idle animation
	var sprite_frames = SpriteFrames.new()
	var idle_texture = load("res://scenes/sprites/knight/noBKG_KnightIdle_strip.png")
	
	if idle_texture:
		# Create idle animation
		sprite_frames.add_animation("idle")
		
		# Calculate frame dimensions (assuming 8 frames in the strip)
		var frame_width = idle_texture.get_width() / 15
		var frame_height = idle_texture.get_height()
		
		# Add frames to the animation
		for i in range(8):
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = idle_texture
			atlas_texture.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			sprite_frames.add_frame("idle", atlas_texture)
		
		# Set animation properties
		sprite_frames.set_animation_speed("idle", 8.0)
		sprite_frames.set_animation_loop("idle", true)
		
		# Apply to sprite
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "idle"
		animated_sprite.play()
	
	sprite_container.add_child(animated_sprite)

func create_player_stats(container: VBoxContainer):
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 0)
	container.add_child(spacer1)
	
	# # Player stats header
	# var stats_header = Label.new()
	# stats_header.text = "⚡ ATTRIBUTES"
	# stats_header.add_theme_font_size_override("font_size", 12)
	# stats_header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
	# stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# container.add_child(stats_header)
	
	# Create stats panel
	var stats_panel = Panel.new()
	stats_panel.custom_minimum_size = Vector2(160, 80)
	
	# Style the stats panel
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	stats_style.border_color = Color(0.6, 0.5, 0.2, 1.0)
	stats_style.border_width_left = 2
	stats_style.border_width_right = 2
	stats_style.border_width_top = 2
	stats_style.border_width_bottom = 2
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_top_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	container.add_child(stats_panel)
	
	# Get player reference for stats
	var player = get_tree().get_first_node_in_group("player")
	var _upgrades = null
	if player and player.has_node("PlayerUpgrades"):
		_upgrades = player.get_node("PlayerUpgrades")
	
	# Stats grid inside panel
	var stats_grid = VBoxContainer.new()
	stats_grid.position = Vector2(8, 6)
	stats_grid.size = Vector2(144, 108)
	stats_grid.add_theme_constant_override("separation", 6)
	stats_panel.add_child(stats_grid)
	
	# Movement Speed
	var speed_value = "200"
	if player and "SPEED" in player:
		speed_value = str(int(player.SPEED))
	create_stat_row(stats_grid, "🏃 Movement Speed", speed_value)
	create_stat_row(stats_grid, "💊 Health", str(player.get_combat_system().get_combat_stats().health))
	create_stat_row(stats_grid, "💥 Damage", str(player.get_combat_system().get_combat_stats().damage))
	
	# Dash Stats
	var dash_cooldown = "1.0s"
	var dash_speed = "600"
	if player:
		if "DASH_COOLDOWN" in player:
			dash_cooldown = "%.1fs" % player.DASH_COOLDOWN
		if "DASH_SPEED" in player:
			dash_speed = str(int(player.DASH_SPEED))
	
	# create_stat_row(stats_grid, "⚡ Dash Cooldown", dash_cooldown)
	# create_stat_row(stats_grid, "💨 Dash Speed", dash_speed)
	
	# # Upgrades Applied
	# if upgrades:
	# 	create_stat_row(stats_grid, "🔥 Speed Boosts", str(upgrades.speed_boosts_applied))
	# 	create_stat_row(stats_grid, "💫 Dash Boosts", str(upgrades.dash_boosts_applied))

func create_progression_stats(container: VBoxContainer):
	# Add some spacing
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 0)
	container.add_child(spacer2)
	
	# Progression headeree
	# var prog_header = Label.new()
	# prog_header.text = "📊 PROGRESSION"
	# prog_header.add_theme_font_size_override("font_size", 16)
	# prog_header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
	# prog_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# container.add_child(prog_header)
	
	# Create progression panel
	var prog_panel = Panel.new()
	prog_panel.custom_minimum_size = Vector2(160, 140)
	
	# Style the progression panel
	var prog_style = StyleBoxFlat.new()
	prog_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	prog_style.border_color = Color(0.6, 0.5, 0.2, 1.0)
	prog_style.border_width_left = 2
	prog_style.border_width_right = 2
	prog_style.border_width_top = 2
	prog_style.border_width_bottom = 2
	prog_style.corner_radius_top_left = 8
	prog_style.corner_radius_top_right = 8
	prog_style.corner_radius_bottom_left = 8
	prog_style.corner_radius_bottom_right = 8
	prog_panel.add_theme_stylebox_override("panel", prog_style)
	container.add_child(prog_panel)
	
	# Get collection stats
	var collection_tracker = get_node_or_null("/root/CollectionTracker")
	var inventory_system = get_node_or_null("/root/InventorySystem")
	
	var prog_grid = VBoxContainer.new()
	prog_grid.position = Vector2(8, 6)
	prog_grid.size = Vector2(144, 128)
	prog_grid.add_theme_constant_override("separation", 6)
	prog_panel.add_child(prog_grid)
	
	# Wealth & Items
	if inventory_system:
		create_stat_row(prog_grid, "💰 Gold", str(inventory_system.get_item_count(0)))
		create_stat_row(prog_grid, "🗝️ Keys Found", str(inventory_system.get_item_count(1)))
		create_stat_row(prog_grid, "💎 Total Value", str(inventory_system.get_total_value()) + "g")
	
	# Collection Progress
	if collection_tracker:
		var stats = collection_tracker.get_collection_stats()
		create_stat_row(prog_grid, "📦 Items Collected", str(stats.total_collected))
		create_stat_row(prog_grid, "�� Achievements", str(stats.achievements_unlocked.size()) + "/6")
		create_stat_row(prog_grid, "✨ Completion", "%.1f%%" % stats.completion_percentage)

func create_stat_row(parent: VBoxContainer, label: String, value: String):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	
	var stat_label = Label.new()
	stat_label.text = label
	stat_label.add_theme_font_size_override("font_size", 11)
	stat_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stat_label)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(value_label)
