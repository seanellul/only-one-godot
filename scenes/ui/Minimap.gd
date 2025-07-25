extends Control

# Minimap system for better navigation and area awareness
class_name Minimap

# Minimap settings
var minimap_size: Vector2 = Vector2(200, 200)
var world_to_minimap_scale: float = 0.1
var update_interval: float = 0.1
var show_fog_of_war: bool = true

# Visual elements
var map_background: ColorRect
var player_dot: ColorRect
var shop_markers: Array[Control] = []
var portal_markers: Array[Control] = []
var discovered_areas: Array[Vector2] = []

# Tracking
var current_area_bounds: Rect2
var player_reference: Node2D
var world_manager: Node
var update_timer: Timer

# Colors
var bg_color: Color = Color(0.1, 0.1, 0.15, 0.9)
var player_color: Color = Color(0.2, 0.8, 0.2, 1.0)
var shop_color: Color = Color(0.8, 0.6, 0.2, 1.0)
var portal_color: Color = Color(0.6, 0.2, 0.8, 1.0)
var wall_color: Color = Color(0.4, 0.4, 0.4, 0.8)
var path_color: Color = Color(0.6, 0.6, 0.5, 0.6)
var fog_color: Color = Color(0.2, 0.2, 0.2, 0.7)

# Signals
signal minimap_clicked(world_position: Vector2)

func _ready():
	name = "Minimap"
	setup_minimap_ui()
	setup_update_timer()
	find_game_references()
	update_area_data()
	
	print("Minimap: System initialized")

func setup_minimap_ui():
	"""Create the minimap UI structure"""
	# Position in bottom-right corner
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	position = Vector2(-220, -220)
	size = minimap_size + Vector2(20, 20) # Extra space for border
	
	# Background frame
	var frame = ColorRect.new()
	frame.size = size
	frame.color = Color(0.0, 0.0, 0.0, 0.8)
	frame.name = "Frame"
	add_child(frame)
	
	# Map background
	map_background = ColorRect.new()
	map_background.position = Vector2(10, 10)
	map_background.size = minimap_size
	map_background.color = bg_color
	map_background.name = "MapBackground"
	add_child(map_background)
	
	# Player dot
	player_dot = ColorRect.new()
	player_dot.size = Vector2(8, 8)
	player_dot.color = player_color
	player_dot.name = "PlayerDot"
	player_dot.position = minimap_size / 2 - player_dot.size / 2
	map_background.add_child(player_dot)
	
	# Make clickable
	mouse_filter = Control.MOUSE_FILTER_PASS

func setup_update_timer():
	"""Setup timer for regular minimap updates"""
	update_timer = Timer.new()
	update_timer.wait_time = update_interval
	update_timer.autostart = true
	update_timer.timeout.connect(_on_update_timer_timeout)
	add_child(update_timer)

func find_game_references():
	"""Find references to game systems"""
	player_reference = get_tree().get_first_node_in_group("player")
	world_manager = get_node_or_null("/root/WorldSystemManager")
	
	if not player_reference:
		# Try to find player through scene tree
		var current_scene = get_tree().current_scene
		if current_scene:
			player_reference = current_scene.find_child("Player", true, false)

func update_area_data():
	"""Update minimap with current area information"""
	if not world_manager:
		return
		
	# Get current area bounds (estimate based on tile system)
	current_area_bounds = Rect2(-1000, -1000, 2000, 2000) # Default area
	
	# Clear existing markers
	clear_markers()
	
	# Update area-specific data based on current zone
	var current_zone = world_manager.get("current_zone_type")
	match current_zone:
		0: # TOWN
			update_town_markers()
		1: # DANGER_ZONE
			update_danger_zone_markers()
		_:
			update_generic_markers()

func clear_markers():
	"""Clear all existing markers from minimap"""
	for marker in shop_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	shop_markers.clear()
	
	for marker in portal_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	portal_markers.clear()

func update_town_markers():
	"""Update markers for town area"""
	# Find town-specific elements
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	# Look for shop NPCs
	var shops = current_scene.find_children("ShopNPC*", "Node", true, false)
	for shop in shops:
		if shop.has_method("get_global_position") or "global_position" in shop:
			var shop_pos = shop.global_position
			var shop_type = shop.get("shop_type") if shop.has_method("get") else "Unknown"
			create_shop_marker(shop_pos, shop_type)
	
	# Look for portals
	var portals = current_scene.find_children("Portal*", "Node", true, false)
	for portal in portals:
		if portal.has_method("get_global_position"):
			create_portal_marker(portal.global_position)

func update_danger_zone_markers():
	"""Update markers for danger zones"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	# Look for enemy spawners or important locations
	var spawners = current_scene.find_children("*Spawner*", "Node", true, false)
	for spawner in spawners:
		if spawner.has_method("get_global_position"):
			create_danger_marker(spawner.global_position)
	
	# Look for exit portals
	var portals = current_scene.find_children("Portal*", "Node", true, false)
	for portal in portals:
		if portal.has_method("get_global_position"):
			create_portal_marker(portal.global_position)

func update_generic_markers():
	"""Update markers for generic areas"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
	
	# Look for any interactive elements
	var interactables = current_scene.find_children("*NPC*", "Node", true, false)
	for npc in interactables:
		if npc.has_method("get_global_position"):
			create_generic_marker(npc.global_position, Color.CYAN)

func create_shop_marker(world_pos: Vector2, shop_type: String = ""):
	"""Create a marker for a shop"""
	var marker = create_marker(world_pos, shop_color, Vector2(6, 6))
	marker.name = "ShopMarker_" + shop_type
	shop_markers.append(marker)
	
	# Add shop type label if space allows
	if shop_type != "":
		var label = Label.new()
		label.text = shop_type[0] # First letter
		label.position = Vector2(-3, -12)
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", shop_color)
		marker.add_child(label)

func create_portal_marker(world_pos: Vector2):
	"""Create a marker for a portal"""
	var marker = create_marker(world_pos, portal_color, Vector2(8, 8))
	marker.name = "PortalMarker"
	portal_markers.append(marker)
	
	# Add pulsing effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(marker, "modulate:a", 0.5, 0.8)
	tween.tween_property(marker, "modulate:a", 1.0, 0.8)

func create_danger_marker(world_pos: Vector2):
	"""Create a marker for dangerous areas"""
	var marker = create_marker(world_pos, Color.RED, Vector2(4, 4))
	marker.name = "DangerMarker"
	
	# Add danger indicator (small triangle)
	var triangle = ColorRect.new()
	triangle.size = Vector2(4, 4)
	triangle.color = Color.RED
	triangle.position = Vector2(-2, -2)
	marker.add_child(triangle)

func create_generic_marker(world_pos: Vector2, color: Color):
	"""Create a generic marker"""
	var marker = create_marker(world_pos, color, Vector2(3, 3))
	marker.name = "GenericMarker"

func create_marker(world_pos: Vector2, color: Color, marker_size: Vector2) -> Control:
	"""Create a marker at the specified world position"""
	var minimap_pos = world_to_minimap_position(world_pos)
	
	var marker = ColorRect.new()
	marker.size = marker_size
	marker.color = color
	marker.position = minimap_pos - marker_size / 2
	marker.set_meta("world_position", world_pos) # Store world position for updates
	map_background.add_child(marker)
	
	return marker

func world_to_minimap_position(world_pos: Vector2) -> Vector2:
	"""Convert world position to minimap position"""
	if not player_reference:
		return minimap_size / 2
	
	var player_world_pos = player_reference.global_position
	var relative_pos = world_pos - player_world_pos
	
	# Scale and center on minimap
	var minimap_offset = relative_pos * world_to_minimap_scale
	var minimap_pos = minimap_size / 2 + minimap_offset
	
	# Clamp to minimap bounds
	minimap_pos.x = clamp(minimap_pos.x, 0, minimap_size.x)
	minimap_pos.y = clamp(minimap_pos.y, 0, minimap_size.y)
	
	return minimap_pos

func _on_update_timer_timeout():
	"""Update minimap on timer"""
	update_player_position()
	update_discovered_areas()

func update_player_position():
	"""Update player dot position on minimap"""
	if not player_reference or not player_dot:
		return
	
	# Player is always centered on minimap
	var center_pos = minimap_size / 2 - player_dot.size / 2
	player_dot.position = center_pos
	
	# Update all marker positions relative to player
	update_marker_positions()

func update_marker_positions():
	"""Update all marker positions relative to player"""
	if not player_reference:
		return
	
	# Update shop markers
	for marker in shop_markers:
		if is_instance_valid(marker) and marker.has_meta("world_position"):
			var world_pos = marker.get_meta("world_position")
			marker.position = world_to_minimap_position(world_pos) - marker.size / 2
	
	# Update portal markers
	for marker in portal_markers:
		if is_instance_valid(marker) and marker.has_meta("world_position"):
			var world_pos = marker.get_meta("world_position")
			marker.position = world_to_minimap_position(world_pos) - marker.size / 2

func update_discovered_areas():
	"""Update fog of war based on player exploration"""
	if not show_fog_of_war or not player_reference:
		return
	
	var player_pos = player_reference.global_position
	var discovery_radius = 150.0
	
	# Add current area to discovered areas
	var grid_pos = Vector2(
		int(player_pos.x / discovery_radius),
		int(player_pos.y / discovery_radius)
	)
	
	if grid_pos not in discovered_areas:
		discovered_areas.append(grid_pos)

func _gui_input(event):
	"""Handle minimap clicks for navigation hints"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_click = event.position - map_background.position
		var world_click = minimap_to_world_position(local_click)
		minimap_clicked.emit(world_click)
		print("Minimap: Clicked at world position ", world_click)

func minimap_to_world_position(minimap_pos: Vector2) -> Vector2:
	"""Convert minimap position to world position"""
	if not player_reference:
		return Vector2.ZERO
	
	var relative_pos = minimap_pos - minimap_size / 2
	var world_offset = relative_pos / world_to_minimap_scale
	return player_reference.global_position + world_offset

# Public interface

func set_minimap_visible(visible: bool):
	"""Show or hide the minimap"""
	self.visible = visible

func set_minimap_scale(scale: float):
	"""Adjust the world-to-minimap scale"""
	world_to_minimap_scale = clamp(scale, 0.05, 0.5)
	update_marker_positions()

func set_fog_of_war_enabled(enabled: bool):
	"""Enable or disable fog of war"""
	show_fog_of_war = enabled

func refresh_markers():
	"""Force refresh of all markers"""
	update_area_data()

func add_custom_marker(world_pos: Vector2, color: Color, label: String = ""):
	"""Add a custom marker to the minimap"""
	var marker = create_marker(world_pos, color, Vector2(5, 5))
	marker.set_meta("world_position", world_pos)
	marker.name = "CustomMarker_" + label
	
	if label != "":
		var label_node = Label.new()
		label_node.text = label
		label_node.position = Vector2(-10, -15)
		label_node.add_theme_font_size_override("font_size", 7)
		label_node.add_theme_color_override("font_color", color)
		marker.add_child(label_node)
	
	return marker
