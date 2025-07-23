extends Node2D

# Town generator creates safe areas with shops, NPCs, and portals
class_name TownGenerator

const TILE_SIZE = 32
const TOWN_WIDTH = 40
const TOWN_HEIGHT = 30

# Town elements
var spawn_position: Vector2
var portal_locations = []
var shop_locations = []
var npc_locations = []

# Structures
var buildings = []
var roads = []
var decoration_items = []

func generate_town():
	"""Generate the town layout"""
	print("TownGenerator: Generating town...")
	
	clear_town()
	
	# Create town layout
	create_town_layout()
	create_central_plaza()
	create_shops()
	create_decorations()
	create_portal_areas()
	
	# Set spawn position in central plaza (ensure it's safe)
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	spawn_position = Vector2((center_x + 1) * TILE_SIZE, (center_y + 1) * TILE_SIZE) # Offset to avoid fountain
	print("TownGenerator: Player spawn set to ", spawn_position, " (center plaza)")
	
	print("TownGenerator: Town generation complete")

func create_town_layout():
	"""Create the basic town structure with roads and buildings"""
	# Create ground tiles
	for x in range(TOWN_WIDTH):
		for y in range(TOWN_HEIGHT):
			create_ground_tile(x, y)
	
	# Create main roads (cross pattern)
	var main_road_h = TOWN_HEIGHT / 2
	var main_road_v = TOWN_WIDTH / 2
	
	# Horizontal road
	for x in range(TOWN_WIDTH):
		create_road_tile(x, main_road_h)
		create_road_tile(x, main_road_h - 1)
		create_road_tile(x, main_road_h + 1)
	
	# Vertical road
	for y in range(TOWN_HEIGHT):
		create_road_tile(main_road_v, y)
		create_road_tile(main_road_v - 1, y)
		create_road_tile(main_road_v + 1, y)

func create_central_plaza():
	"""Create a central plaza area"""
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	var plaza_size = 6
	
	for x in range(center_x - plaza_size / 2, center_x + plaza_size / 2):
		for y in range(center_y - plaza_size / 2, center_y + plaza_size / 2):
			create_plaza_tile(x, y)
	
	# Add fountain in center
	create_fountain(center_x, center_y)

func create_shops():
	"""Create shops around the town"""
	var shop_positions = [
		Vector2(5, 5), # Weapon shop (top-left)
		Vector2(27, 5), # Item shop (top-right)
		Vector2(5, 20), # Armor shop (bottom-left)
		Vector2(27, 20) # Magic shop (bottom-right)
	]
	
	var shop_types = ["weapon", "item", "armor", "magic"]
	
	for i in range(shop_positions.size()):
		var pos = shop_positions[i]
		create_shop(pos.x, pos.y, shop_types[i])
		# Store the center position of the building for reference
		var center_pos = Vector2((pos.x + 4) * TILE_SIZE, (pos.y + 3) * TILE_SIZE)
		shop_locations.append(center_pos)

func create_shop(x: int, y: int, shop_type: String):
	"""Create a shop building"""
	var shop_width = 8 # Larger buildings
	var shop_height = 6
	
	# Create shop building with proper floor area
	for sx in range(shop_width):
		for sy in range(shop_height):
			var tile_x = x + sx
			var tile_y = y + sy
			
			# Create walls on the perimeter
			if sx == 0 or sx == shop_width - 1 or sy == 0 or sy == shop_height - 1:
				# Don't create wall at entrance positions
				if not (sx == shop_width / 2 and sy == shop_height - 1): # Front entrance
					create_wall_tile(tile_x, tile_y)
				else:
					create_floor_tile(tile_x, tile_y) # Entrance floor
			else:
				create_floor_tile(tile_x, tile_y) # Interior floor
	
	# Create shop NPC inside the building
	var npc_pos = Vector2((x + shop_width / 2) * TILE_SIZE, (y + shop_height / 2) * TILE_SIZE)
	create_shop_npc(npc_pos, shop_type)
	
	# Create shop sign
	create_shop_sign(x + shop_width / 2, y - 1, shop_type)

func create_shop_sign(x: int, y: int, shop_type: String):
	"""Create a sign showing what shop this is"""
	var sign = ColorRect.new()
	sign.size = Vector2(TILE_SIZE, TILE_SIZE / 2)
	sign.color = Color(0.9, 0.8, 0.6, 1) # Light wood color
	sign.position = Vector2(x * TILE_SIZE, y * TILE_SIZE + TILE_SIZE / 4)
	add_child(sign)
	
	# Add text label
	var sign_text = Label.new()
	sign_text.text = shop_type.capitalize()
	sign_text.position = Vector2(x * TILE_SIZE - 15, y * TILE_SIZE + TILE_SIZE / 4 - 5)
	sign_text.add_theme_color_override("font_color", Color.BLACK)
	sign_text.add_theme_font_size_override("font_size", 12)
	add_child(sign_text)
	
	decoration_items.append(sign)
	decoration_items.append(sign_text)

func create_portal_areas():
	"""Create areas where portals will be placed"""
	portal_locations = [
		Vector2(5, 15) * TILE_SIZE, # West portal (Level 1)
		Vector2(35, 15) * TILE_SIZE, # East portal (Level 2)
		Vector2(20, 5) * TILE_SIZE, # North portal (Level 3)
		Vector2(20, 25) * TILE_SIZE # South portal (Level 4)
	]
	
	# Create portal platforms
	for portal_pos in portal_locations:
		var grid_pos = portal_pos / TILE_SIZE
		create_portal_platform(int(grid_pos.x), int(grid_pos.y))

func create_portal_platform(x: int, y: int):
	"""Create a platform for a portal"""
	var platform_size = 3
	
	for px in range(platform_size):
		for py in range(platform_size):
			var tile_x = x + px - platform_size / 2
			var tile_y = y + py - platform_size / 2
			create_platform_tile(tile_x, tile_y)

func create_decorations():
	"""Add decorative elements to the town"""
	# Create trees and benches around roads
	for i in range(10):
		var x = randi() % TOWN_WIDTH
		var y = randi() % TOWN_HEIGHT
		
		# Don't place on roads or buildings
		if is_valid_decoration_spot(x, y):
			if randf() < 0.7:
				create_tree(x, y)
			else:
				create_bench(x, y)

func create_ground_tile(x: int, y: int):
	"""Create a ground tile"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.4, 0.6, 0.3, 1) # Green grass
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)

func create_road_tile(x: int, y: int):
	"""Create a road tile"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.6, 0.6, 0.6, 1) # Gray road
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)
	roads.append(tile)

func create_plaza_tile(x: int, y: int):
	"""Create a plaza tile"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.8, 0.8, 0.7, 1) # Light stone
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)

func create_platform_tile(x: int, y: int):
	"""Create a platform tile for portals"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.3, 0.3, 0.8, 1) # Blue magic platform
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)

func create_wall_tile(x: int, y: int):
	"""Create a wall tile with collision"""
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	collision_shape.shape = shape
	collision_shape.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.6, 0.4, 0.2, 1) # Brown wall
	tile.position = Vector2(0, 0)
	
	static_body.add_child(collision_shape)
	static_body.add_child(tile)
	static_body.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(static_body)
	buildings.append(static_body)

func create_floor_tile(x: int, y: int):
	"""Create a floor tile inside buildings"""
	var tile = ColorRect.new()
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.color = Color(0.8, 0.7, 0.5, 1) # Wooden floor
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tile)

func create_fountain(x: int, y: int):
	"""Create a fountain in the plaza"""
	var fountain = ColorRect.new()
	fountain.size = Vector2(TILE_SIZE * 2, TILE_SIZE * 2)
	fountain.color = Color(0.2, 0.4, 0.8, 1) # Blue fountain
	fountain.position = Vector2(x * TILE_SIZE - TILE_SIZE, y * TILE_SIZE - TILE_SIZE)
	add_child(fountain)
	decoration_items.append(fountain)

func create_tree(x: int, y: int):
	"""Create a decorative tree"""
	var tree = ColorRect.new()
	tree.size = Vector2(TILE_SIZE, TILE_SIZE)
	tree.color = Color(0.2, 0.8, 0.2, 1) # Green tree
	tree.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(tree)
	decoration_items.append(tree)

func create_bench(x: int, y: int):
	"""Create a decorative bench"""
	var bench = ColorRect.new()
	bench.size = Vector2(TILE_SIZE, TILE_SIZE / 2)
	bench.color = Color(0.6, 0.4, 0.2, 1) # Brown bench
	bench.position = Vector2(x * TILE_SIZE, y * TILE_SIZE + TILE_SIZE / 4)
	add_child(bench)
	decoration_items.append(bench)

func create_shop_npc(position: Vector2, shop_type: String):
	"""Create an NPC for a shop"""
	print("TownGenerator: Creating ", shop_type, " NPC at ", position)
	
	var npc_scene = preload("res://scenes/npcs/ShopNPC.tscn")
	var npc = npc_scene.instantiate()
	npc.global_position = position
	npc.setup_shop(shop_type)
	add_child(npc)
	npc_locations.append(position)
	
	print("TownGenerator: NPC created successfully - total NPCs: ", npc_locations.size())

func is_valid_decoration_spot(x: int, y: int) -> bool:
	"""Check if a position is valid for decoration placement"""
	# Don't place on roads
	var main_road_h = TOWN_HEIGHT / 2
	var main_road_v = TOWN_WIDTH / 2
	
	if abs(y - main_road_h) <= 1 or abs(x - main_road_v) <= 1:
		return false
	
	# Don't place too close to buildings or portals
	for shop_pos in shop_locations:
		var grid_pos = shop_pos / TILE_SIZE
		if Vector2(x, y).distance_to(grid_pos) < 8:
			return false
	
	return true

func get_spawn_position() -> Vector2:
	"""Get the player spawn position"""
	return spawn_position

func get_portal_locations() -> Array:
	"""Get the locations where portals should be placed"""
	return portal_locations

func get_shop_locations() -> Array:
	"""Get the locations of shops"""
	return shop_locations

func clear_town():
	"""Clear all town elements"""
	for child in get_children():
		child.queue_free()
	
	buildings.clear()
	roads.clear()
	decoration_items.clear()
	portal_locations.clear()
	shop_locations.clear()
	npc_locations.clear()
