extends Node2D

# Town generator creates safe areas with shops, NPCs, and portals
class_name TownGenerator

const TILE_SIZE = 32
const TOWN_WIDTH = 120 # 3x larger (was 40)
const TOWN_HEIGHT = 90 # 3x larger (was 30)

# Town elements
var spawn_position: Vector2
var portal_locations = []
var shop_locations = []
var npc_locations = []

# Structures
var buildings = []
var roads = []
var decoration_items = []
var light_sources = []
var interactive_signs = []

# Village tile textures
var village_textures = {}
var grass_variations = []
var rng = RandomNumberGenerator.new()

# Shop variance data
var shop_decorations = {
	"weapon": ["anvil", "forge", "hammer", "sword_rack", "bellows"],
	"item": ["herb_shelf", "potion_rack", "ingredient_box", "mortar", "scales"],
	"armor": ["armor_stand", "shield_wall", "helmet_display", "chain_rack"],
	"magic": ["crystal_ball", "spell_book", "rune_circle", "star_chart", "cauldron"]
}

var shop_color_schemes = {
	"weapon": {"primary": Color(0.6, 0.4, 0.2), "accent": Color(0.8, 0.3, 0.1)},
	"item": {"primary": Color(0.4, 0.6, 0.3), "accent": Color(0.3, 0.8, 0.2)},
	"armor": {"primary": Color(0.5, 0.5, 0.6), "accent": Color(0.7, 0.7, 0.8)},
	"magic": {"primary": Color(0.4, 0.3, 0.7), "accent": Color(0.6, 0.4, 0.9)}
}

func _ready():
	rng.randomize()
	load_village_textures()

func load_village_textures():
	"""Load all village tile textures"""
	print("TownGenerator: Loading village textures...")
	
	# Load individual grass variations
	for letter in ["a", "b", "c", "d"]:
		var path = "res://tiles/village/grass_" + letter + ".png"
		var texture = load(path)
		if texture:
			grass_variations.append(texture)
			print("TownGenerator: Loaded ", path)
	
	# Load other village tiles
	var tile_paths = {
		"cobblestone_road": "res://tiles/village/cobblestone_road.png",
		"central_plaza_stone": "res://tiles/village/central_plaza_stone.png",
		"building_wall": "res://tiles/village/building_wall.png",
		"building_wall_timber": "res://tiles/village/building_wall_timber_frame.png",
		"wooden_floor": "res://tiles/village/wooden_building_floor.png",
		"fountain_base": "res://tiles/village/fountain_base.png",
		"magic_platform": "res://tiles/village/magic_platform.png",
		"garden_park": "res://tiles/village/garden_park.png",
		"workshop": "res://tiles/village/workshop.png"
	}
	
	for key in tile_paths:
		var texture = load(tile_paths[key])
		if texture:
			village_textures[key] = texture
			print("TownGenerator: Loaded ", key, " texture")
		else:
			print("TownGenerator: Failed to load ", key, " texture")
	
	print("TownGenerator: Loaded ", grass_variations.size(), " grass variations and ", village_textures.size(), " village textures")

func generate_town():
	"""Generate the town layout with organic, varied design"""
	print("TownGenerator: Generating massive enhanced town with lighting and interactions...")
	
	clear_town()
	
	# Create enhanced town layout
	create_organic_town_layout()
	create_enhanced_central_plaza()
	create_varied_shops()
	create_rich_decorations()
	create_atmospheric_elements()
	create_portal_areas()
	
	# Add lighting system
	setup_dynamic_lighting()
	
	# Set spawn position in central plaza (ensure it's safe)
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	spawn_position = Vector2((center_x + 2) * TILE_SIZE, (center_y + 2) * TILE_SIZE)
	print("TownGenerator: Player spawn set to ", spawn_position, " (center plaza)")
	
	print("TownGenerator: Massive enhanced town with lighting system complete")

func setup_dynamic_lighting():
	"""Set up the dynamic lighting system"""
	print("TownGenerator: Setting up dynamic lighting system...")
	
	# Create ambient lighting
	create_ambient_lighting()
	
	# Add lights for all torch and lamp positions
	for light_data in light_sources:
		create_dynamic_light(light_data)
	
	print("TownGenerator: Dynamic lighting system active with ", light_sources.size(), " light sources")

func create_ambient_lighting():
	"""Create ambient lighting for the scene"""
	# Create a CanvasModulate for overall scene lighting
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.7, 0.75, 0.8, 1.0) # Balanced lighting - not too dark, not too bright
	add_child(canvas_modulate)
	decoration_items.append(canvas_modulate)

func create_dynamic_light(light_data: Dictionary):
	"""Create a Light2D node for dynamic lighting"""
	var light = PointLight2D.new()
	var pos = light_data.pos
	var light_type = light_data.type
	var radius = light_data.radius
	var color = light_data.color
	
	# Position the light
	light.position = Vector2(pos.x * TILE_SIZE + TILE_SIZE / 2.0, pos.y * TILE_SIZE + TILE_SIZE / 2.0)
	
	# Configure light properties based on type
	if light_type == "torch":
		light.energy = 1.3  # Stronger for visible shadows
		light.color = Color(1.0, 0.7, 0.3, 1.0) # Warm orange
		light.texture_scale = 1.2
		
		# Add flickering effect
		create_flickering_light(light)
		
	elif light_type == "lamp":
		light.energy = 1.6  # Stronger for visible shadows
		light.color = Color(1.0, 0.9, 0.6, 1.0) # Warm white
		light.texture_scale = 1.5
	
	# Set light range
	light.range_item_cull_mask = 1
	
	# Create shadow casting
	light.shadow_enabled = true
	light.shadow_color = Color(0.2, 0.2, 0.3, 0.6)
	light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5  # Smoother shadows
	
	add_child(light)
	decoration_items.append(light)

func create_flickering_light(light: PointLight2D):
	"""Add subtle flickering effect to torch lights"""
	var tween = create_tween()
	tween.set_loops()
	
	# Randomly vary energy between 1.0 and 1.6 for visible effect
	var flicker_sequence = [1.3, 1.4, 1.2, 1.6, 1.0, 1.3, 1.5, 1.1]
	
	for energy_value in flicker_sequence:
		tween.tween_property(light, "energy", energy_value, 0.1 + randf() * 0.1)

func create_organic_town_layout():
	"""Create a more natural, varied town layout"""
	# Fill entire area with varied grass
	for x in range(TOWN_WIDTH):
		for y in range(TOWN_HEIGHT):
			create_ground_tile(x, y)
	
	# Create main plaza area first
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	
	# Create organic road network instead of rigid cross
	create_organic_roads(center_x, center_y)
	
	# Add random garden patches throughout
	create_scattered_gardens()

func create_organic_roads(center_x: int, center_y: int):
	"""Create more natural, winding road patterns"""
	
	# Main plaza approach roads (slightly curved) - scaled up for larger town
	# North approach
	for i in range(20): # Increased from 8
		var x = center_x + (sin(i * 0.3) * 4) as int # Increased curve amplitude
		var y = center_y - 20 + i # Increased length
		if is_valid_position(x, y):
			create_road_tile(x, y)
			create_road_tile(x - 1, y) # Make roads wider
			create_road_tile(x + 1, y)
			create_road_tile(x - 2, y) # Even wider for scale
			create_road_tile(x + 2, y)
	
	# South approach  
	for i in range(20):
		var x = center_x + (sin(i * 0.4) * 3) as int
		var y = center_y + 8 + i # Increased offset
		if is_valid_position(x, y):
			create_road_tile(x, y)
			create_road_tile(x - 1, y)
			create_road_tile(x + 1, y)
			create_road_tile(x - 2, y)
			create_road_tile(x + 2, y)
	
	# East approach
	for i in range(20):
		var x = center_x + 8 + i # Increased offset
		var y = center_y + (cos(i * 0.5) * 2) as int
		if is_valid_position(x, y):
			create_road_tile(x, y)
			create_road_tile(x, y - 1)
			create_road_tile(x, y + 1)
			create_road_tile(x, y - 2)
			create_road_tile(x, y + 2)
	
	# West approach
	for i in range(20):
		var x = center_x - 20 + i # Increased length
		var y = center_y + (cos(i * 0.4) * 3) as int
		if is_valid_position(x, y):
			create_road_tile(x, y)
			create_road_tile(x, y - 1)
			create_road_tile(x, y + 1)
			create_road_tile(x, y - 2)
			create_road_tile(x, y + 2)
	
	# Connecting side paths - scaled up positions
	create_curved_path(Vector2(20, 20), Vector2(35, 30))
	create_curved_path(Vector2(85, 20), Vector2(70, 30))
	create_curved_path(Vector2(20, 60), Vector2(35, 50))
	create_curved_path(Vector2(85, 60), Vector2(70, 50))

func create_curved_path(start: Vector2, end: Vector2):
	"""Create a curved path between two points"""
	var steps = int(start.distance_to(end))
	for i in range(steps):
		var t = float(i) / float(steps)
		# Add curve using quadratic bezier
		var control = Vector2((start.x + end.x) / 2, (start.y + end.y) / 2 - 6) # Increased curve depth
		var pos = start.lerp(control, t).lerp(control.lerp(end, t), t)
		
		var x = int(pos.x)
		var y = int(pos.y)
		if is_valid_position(x, y):
			create_road_tile(x, y)
			# Make curved paths wider too
			create_road_tile(x - 1, y)
			create_road_tile(x + 1, y)

func create_enhanced_central_plaza():
	"""Create a more elaborate central plaza"""
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	var plaza_size = 16 # Much larger plaza (was 8)
	
	# Create irregular plaza shape
	for x in range(center_x - plaza_size / 2, center_x + plaza_size / 2):
		for y in range(center_y - plaza_size / 2, center_y + plaza_size / 2):
			var dist = Vector2(x - center_x, y - center_y).length()
			if dist < plaza_size / 2:
				create_plaza_tile(x, y)
	
	# Enhanced fountain with proper Z-index
	create_massive_fountain(center_x, center_y)
	
	# Add decorative elements around plaza
	create_plaza_decorations(center_x, center_y)

func create_varied_shops():
	"""Create shops with more varied sizes and styles"""
	var shop_configs = [
		{
			"pos": Vector2(15, 12), # Scaled positions
			"size": Vector2(15, 12), # Larger buildings
			"type": "weapon",
			"style": "stone",
			"features": ["forge", "anvil"]
		},
		{
			"pos": Vector2(75, 10),
			"size": Vector2(12, 10),
			"type": "item",
			"style": "timber",
			"features": ["herbs", "shelves"]
		},
		{
			"pos": Vector2(10, 55),
			"size": Vector2(14, 11),
			"type": "armor",
			"style": "stone",
			"features": ["displays", "racks"]
		},
		{
			"pos": Vector2(80, 60),
			"size": Vector2(11, 14),
			"type": "magic",
			"style": "tower",
			"features": ["crystals", "library"]
		}
	]
	
	for config in shop_configs:
		create_enhanced_shop(config)

func create_enhanced_shop(config: Dictionary):
	"""Create a shop with enhanced design and features"""
	var pos = config.pos
	var size = config.size
	var shop_type = config.type
	var style = config.style
	
	var width = int(size.x)
	var height = int(size.y)
	var start_x = int(pos.x)
	var start_y = int(pos.y)
	
	# Create varied building structure
	for sx in range(width):
		for sy in range(height):
			var tile_x = start_x + sx
			var tile_y = start_y + sy
			
			# Create walls on perimeter
			if sx == 0 or sx == width - 1 or sy == 0 or sy == height - 1:
				# Entrance variations
				var has_entrance = false
				if sy == height - 1: # Front wall
					if sx >= width / 2 - 1 and sx <= width / 2 + 1: # Triple door entrance
						has_entrance = true
				
				if not has_entrance:
					if style == "timber" or shop_type == "magic":
						create_timber_wall_tile(tile_x, tile_y)
					else:
						create_wall_tile(tile_x, tile_y)
				else:
					create_floor_tile(tile_x, tile_y)
			else:
				create_floor_tile(tile_x, tile_y)
	
	# Add procedural shop decorations
	add_procedural_shop_decorations(start_x, start_y, width, height, config)
	
	# Create enhanced shop NPC
	var npc_pos = Vector2((start_x + width / 2) * TILE_SIZE, (start_y + height / 2) * TILE_SIZE)
	create_shop_npc(npc_pos, shop_type)
	shop_locations.append(npc_pos)
	
	# Enhanced shop signage with interaction
	create_interactive_shop_sign(start_x + width / 2, start_y - 1, shop_type, config)

func add_procedural_shop_decorations(x: int, y: int, width: int, height: int, config: Dictionary):
	"""Add procedural decorative elements specific to shop type"""
	var shop_type = config.type
	var color_scheme = shop_color_schemes.get(shop_type, {"primary": Color.GRAY, "accent": Color.WHITE})
	
	# Add workshop areas outside buildings (scaled positions)
	if shop_type == "weapon":
		# Forge complex outside
		for i in range(3):
			create_workshop_tile(x - 3 + i, y + height / 2)
		
		# Add procedural weapon displays
		create_procedural_decoration(x + 2, y + 2, "weapon_rack", color_scheme.accent)
		create_procedural_decoration(x + width - 3, y + 3, "anvil", color_scheme.primary)
	
	elif shop_type == "item":
		# Herb garden outside
		for dx in range(2):
			for dy in range(2):
				create_garden_tile(x + width + 1 + dx, y + 2 + dy)
		
		# Add procedural item displays
		create_procedural_decoration(x + 2, y + 2, "herb_shelf", color_scheme.accent)
		create_procedural_decoration(x + width - 3, y + height - 3, "potion_rack", color_scheme.primary)
	
	elif shop_type == "armor":
		# Training dummy outside
		create_procedural_decoration(x - 2, y + height / 2, "training_dummy", color_scheme.accent)
		
		# Add procedural armor displays
		create_procedural_decoration(x + 3, y + 2, "armor_stand", color_scheme.primary)
		create_procedural_decoration(x + width - 4, y + 3, "shield_wall", color_scheme.accent)
	
	elif shop_type == "magic":
		# Magical herb garden
		for dx in range(3):
			for dy in range(3):
				create_garden_tile(x + width + 1 + dx, y + 3 + dy)
		
		# Add procedural magic displays
		create_procedural_decoration(x + width / 2, y + 2, "crystal_ball", Color(0.5, 0.7, 1.0))
		create_procedural_decoration(x + 2, y + height - 3, "rune_circle", Color(0.8, 0.4, 1.0))

func create_procedural_decoration(x: int, y: int, decoration_type: String, color: Color):
	"""Create a procedural decoration element"""
	var decoration = ColorRect.new()
	
	# Different sizes and shapes based on type
	match decoration_type:
		"weapon_rack":
			decoration.size = Vector2(TILE_SIZE, TILE_SIZE * 1.5)
			decoration.position = Vector2(x * TILE_SIZE, y * TILE_SIZE - TILE_SIZE / 2.0)
		"anvil":
			decoration.size = Vector2(TILE_SIZE * 0.8, TILE_SIZE * 0.6)
			decoration.position = Vector2(x * TILE_SIZE + 3, y * TILE_SIZE + 6)
		"herb_shelf":
			decoration.size = Vector2(TILE_SIZE * 1.2, TILE_SIZE * 0.8)
			decoration.position = Vector2(x * TILE_SIZE - 3, y * TILE_SIZE + 3)
		"potion_rack":
			decoration.size = Vector2(TILE_SIZE * 0.6, TILE_SIZE)
			decoration.position = Vector2(x * TILE_SIZE + 6, y * TILE_SIZE)
		"armor_stand":
			decoration.size = Vector2(TILE_SIZE * 0.7, TILE_SIZE * 1.3)
			decoration.position = Vector2(x * TILE_SIZE + 5, y * TILE_SIZE - 5)
		"shield_wall":
			decoration.size = Vector2(TILE_SIZE * 1.1, TILE_SIZE * 0.9)
			decoration.position = Vector2(x * TILE_SIZE - 2, y * TILE_SIZE + 2)
		"training_dummy":
			decoration.size = Vector2(TILE_SIZE * 0.8, TILE_SIZE * 1.4)
			decoration.position = Vector2(x * TILE_SIZE + 3, y * TILE_SIZE - 6)
		"crystal_ball":
			decoration.size = Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
			decoration.position = Vector2(x * TILE_SIZE + 8, y * TILE_SIZE + 8)
		"rune_circle":
			decoration.size = Vector2(TILE_SIZE, TILE_SIZE)
			decoration.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		_:
			decoration.size = Vector2(TILE_SIZE * 0.6, TILE_SIZE * 0.6)
			decoration.position = Vector2(x * TILE_SIZE + 6, y * TILE_SIZE + 6)
	
	decoration.color = color
	decoration.z_index = -1 # Behind player
	add_child(decoration)
	decoration_items.append(decoration)

func create_interactive_shop_sign(x: int, y: int, shop_type: String, config: Dictionary):
	"""Create an enhanced interactive shop sign"""
	var color_scheme = shop_color_schemes.get(shop_type, {"primary": Color.GRAY, "accent": Color.WHITE})
	
	# Create sign background with shop colors
	var sign = Panel.new()
	sign.size = Vector2(TILE_SIZE * 3, TILE_SIZE)
	sign.position = Vector2(x * TILE_SIZE - TILE_SIZE * 1.5, y * TILE_SIZE)
	
	# Style the sign with shop theme
	var sign_style = StyleBoxFlat.new()
	sign_style.bg_color = color_scheme.primary
	sign_style.border_color = color_scheme.accent
	sign_style.border_width_left = 2
	sign_style.border_width_right = 2
	sign_style.border_width_top = 2
	sign_style.border_width_bottom = 2
	sign_style.corner_radius_top_left = 6
	sign_style.corner_radius_top_right = 6
	sign_style.corner_radius_bottom_left = 6
	sign_style.corner_radius_bottom_right = 6
	sign.add_theme_stylebox_override("panel", sign_style)
	sign.z_index = -2
	add_child(sign)
	
	# Add shop icon
	var icon = Label.new()
	icon.position = Vector2(8, 8)
	icon.add_theme_font_size_override("font_size", 16)
	match shop_type:
		"weapon": icon.text = "⚔️"
		"item": icon.text = "🧪"
		"armor": icon.text = "🛡️"
		"magic": icon.text = "🔮"
	icon.add_theme_color_override("font_color", Color.WHITE)
	sign.add_child(icon)
	
	# Add shop name
	var name_label = Label.new()
	name_label.text = get_shop_name(shop_type)
	name_label.position = Vector2(32, 4)
	name_label.size = Vector2(64, 24)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign.add_child(name_label)
	
	# Make sign interactive
	var interaction_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE * 3, TILE_SIZE)
	collision_shape.shape = shape
	collision_shape.position = Vector2(TILE_SIZE * 1.5, TILE_SIZE / 2.0)
	interaction_area.add_child(collision_shape)
	sign.add_child(interaction_area)
	
	# Store interaction data
	var interaction_data = {
		"type": "shop_sign",
		"shop_type": shop_type,
		"title": name_label.text,
		"description": get_shop_description(shop_type),
		"area": interaction_area
	}
	
	interactive_signs.append(interaction_data)
	decoration_items.append(sign)

func get_shop_name(shop_type: String) -> String:
	"""Generate procedural shop names"""
	var names = {
		"weapon": ["Iron & Steel", "The Forge", "Blade Works", "Hammer & Anvil"],
		"item": ["Herb & Remedy", "The Apothecary", "Mystic Brews", "Nature's Bounty"],
		"armor": ["Shield & Mail", "The Armory", "Steel Guard", "Defender's Den"],
		"magic": ["Arcane Arts", "The Grimoire", "Spell & Scroll", "Mystic Tower"]
	}
	
	var shop_names = names.get(shop_type, ["Generic Shop"])
	return shop_names[rng.randi() % shop_names.size()]

func get_shop_description(shop_type: String) -> String:
	"""Get shop description for dialogue"""
	match shop_type:
		"weapon":
			return "Fine weapons forged with skill and honor. Every blade tells a story of courage."
		"item":
			return "Potions, herbs, and remedies for the weary traveler. Health and magic await within."
		"armor":
			return "Protection for the bold adventurer. Our armor has saved countless lives."
		"magic":
			return "Ancient knowledge and mystical artifacts. Seek wisdom beyond the mundane world."
		_:
			return "A place of mystery and wonder."

func create_rich_decorations():
	"""Add varied decorative elements throughout town"""
	
	# Market stalls near plaza (scaled positions)
	var stall_positions = [
		Vector2(35, 30), Vector2(65, 30), Vector2(50, 25),
		Vector2(35, 50), Vector2(65, 50), Vector2(50, 55)
	]
	
	for pos in stall_positions:
		create_market_stall(int(pos.x), int(pos.y))
	
	# Garden areas in corners and around town
	var garden_areas = [
		Vector2(5, 5), Vector2(110, 5), Vector2(5, 80), Vector2(110, 80),
		Vector2(30, 15), Vector2(70, 15), Vector2(30, 70), Vector2(70, 70)
	]
	
	for area in garden_areas:
		create_garden_cluster(int(area.x), int(area.y))
	
	# Workshop areas (more spread out)
	var workshop_spots = [
		Vector2(40, 20), Vector2(50, 20), Vector2(60, 20),
		Vector2(40, 65), Vector2(50, 65), Vector2(60, 65)
	]
	
	for spot in workshop_spots:
		if rng.randf() > 0.3: # More workshops
			create_workshop_tile(int(spot.x), int(spot.y))

func create_scattered_gardens():
	"""Create natural garden patches throughout"""
	for i in range(50): # More gardens for larger space
		var x = rng.randi_range(8, TOWN_WIDTH - 8)
		var y = rng.randi_range(8, TOWN_HEIGHT - 8)
		
		if is_valid_decoration_spot(x, y):
			create_garden_tile(x, y)

func create_atmospheric_elements():
	"""Add lighting and atmospheric elements"""
	
	# Street lamps along main roads
	create_street_lighting()
	
	# Torch lighting around important buildings
	create_building_lighting()
	
	# Ambient particle systems
	create_ambient_particles()

func create_street_lighting():
	"""Add lamp posts along main pathways"""
	var lamp_positions = [
		Vector2(25, 45), Vector2(75, 45), Vector2(50, 20), Vector2(50, 70),
		Vector2(35, 25), Vector2(65, 25), Vector2(35, 55), Vector2(65, 55),
		Vector2(20, 35), Vector2(80, 35), Vector2(40, 15), Vector2(60, 15)
	]
	
	for pos in lamp_positions:
		create_lamp_post(int(pos.x), int(pos.y))

func create_building_lighting():
	"""Add torches near building entrances"""
	# Add torches near shop entrances
	for shop_pos in shop_locations:
		var grid_pos = shop_pos / TILE_SIZE
		create_torch(int(grid_pos.x) - 2, int(grid_pos.y) + 3)
		create_torch(int(grid_pos.x) + 2, int(grid_pos.y) + 3)

func create_ambient_particles():
	"""Add subtle particle effects for atmosphere"""
	# Floating dust motes in sunbeams
	create_ambient_dust_system()
	
	# Gentle wind effect on grass
	create_wind_particles()

# ===== ENHANCED DECORATION FUNCTIONS =====

func create_market_stall(x: int, y: int):
	"""Create a small market stall"""
	var stall = ColorRect.new()
	stall.size = Vector2(TILE_SIZE * 2, TILE_SIZE * 1.5) # Larger stalls
	stall.color = Color(0.8, 0.6, 0.4, 1.0) # Wooden stall
	stall.position = Vector2(x * TILE_SIZE - TILE_SIZE / 2.0, y * TILE_SIZE)
	stall.z_index = -2 # FIXED: Behind player
	add_child(stall)
	decoration_items.append(stall)
	
	# Add stall goods
	var goods = ColorRect.new()
	goods.size = Vector2(TILE_SIZE * 1.5, TILE_SIZE)
	goods.color = Color(1.0, 0.8, 0.2, 1.0) # Golden goods
	goods.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	goods.z_index = -1 # FIXED: Behind player
	add_child(goods)
	decoration_items.append(goods)

func create_garden_cluster(x: int, y: int):
	"""Create a cluster of garden tiles"""
	for dx in range(-2, 3): # Larger clusters
		for dy in range(-2, 3):
			var pos_x = x + dx
			var pos_y = y + dy
			if is_valid_position(pos_x, pos_y) and rng.randf() > 0.2: # More dense
				create_garden_tile(pos_x, pos_y)

func create_lamp_post(x: int, y: int):
	"""Create a decorative lamp post with light"""
	# Lamp post base
	var post = ColorRect.new()
	post.size = Vector2(8, TILE_SIZE + 8) # Taller posts
	post.color = Color(0.3, 0.3, 0.3, 1.0) # Dark metal
	post.position = Vector2(x * TILE_SIZE + 12, y * TILE_SIZE - 4)
	post.z_index = -3 # FIXED: Behind player
	add_child(post)
	decoration_items.append(post)
	
	# Lamp top
	var lamp = ColorRect.new()
	lamp.size = Vector2(20, 16) # Larger lamp
	lamp.color = Color(1.0, 0.9, 0.6, 0.8) # Warm light
	lamp.position = Vector2(x * TILE_SIZE + 6, y * TILE_SIZE - 10)
	lamp.z_index = -2 # FIXED: Behind player
	add_child(lamp)
	decoration_items.append(lamp)
	
	# Add to light sources for dynamic lighting system
	light_sources.append({"pos": Vector2(x, y), "type": "lamp", "radius": 96, "color": Color(1.0, 0.9, 0.6, 0.3)})

func create_torch(x: int, y: int):
	"""Create a wall torch"""
	var torch = ColorRect.new()
	torch.size = Vector2(10, 24) # Larger torches
	torch.color = Color(0.6, 0.3, 0.1, 1.0) # Torch handle
	torch.position = Vector2(x * TILE_SIZE + 11, y * TILE_SIZE + 4)
	torch.z_index = -3 # FIXED: Behind player
	add_child(torch)
	decoration_items.append(torch)
	
	# Flame
	var flame = ColorRect.new()
	flame.size = Vector2(14, 14) # Larger flames
	flame.color = Color(1.0, 0.6, 0.2, 0.9) # Orange flame
	flame.position = Vector2(x * TILE_SIZE + 9, y * TILE_SIZE - 2)
	flame.z_index = -2 # FIXED: Behind player
	add_child(flame)
	decoration_items.append(flame)
	
	# Add flame particles
	create_torch_particles(Vector2(x * TILE_SIZE + 16, y * TILE_SIZE + 6))
	
	# Add to light sources for dynamic lighting system
	light_sources.append({"pos": Vector2(x, y), "type": "torch", "radius": 72, "color": Color(1.0, 0.7, 0.3, 0.4)})

func create_ambient_dust_system():
	"""Create floating dust particle system"""
	var dust_system = CPUParticles2D.new()
	dust_system.position = Vector2(TOWN_WIDTH * TILE_SIZE / 2.0, TOWN_HEIGHT * TILE_SIZE / 2.0)
	dust_system.emitting = true
	
	# Dust particle settings
	dust_system.amount = 150 # More particles for larger space
	dust_system.lifetime = 20.0 # Longer lifetime
	dust_system.speed_scale = 0.3
	
	# Dust appearance
	dust_system.scale_amount_min = 0.5
	dust_system.scale_amount_max = 1.5
	dust_system.color = Color(1.0, 1.0, 1.0, 0.1)
	
	# Dust movement
	dust_system.direction = Vector2(0, -1)
	dust_system.initial_velocity_min = 5.0
	dust_system.initial_velocity_max = 15.0
	dust_system.gravity = Vector2(2, -1)
	
	# Dust area (much larger)
	dust_system.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust_system.emission_rect_extents = Vector2(TOWN_WIDTH * TILE_SIZE / 2.0, TOWN_HEIGHT * TILE_SIZE / 2.0)
	
	dust_system.z_index = -5
	add_child(dust_system)
	decoration_items.append(dust_system)

func create_wind_particles():
	"""Create subtle wind effect particles"""
	var wind_system = CPUParticles2D.new()
	wind_system.position = Vector2(0, TOWN_HEIGHT * TILE_SIZE / 2.0)
	wind_system.emitting = true
	
	# Wind settings
	wind_system.amount = 80 # More wind particles
	wind_system.lifetime = 12.0 # Longer lifetime
	
	# Wind appearance (small leaves/particles)
	wind_system.scale_amount_min = 0.3
	wind_system.scale_amount_max = 0.8
	wind_system.color = Color(0.6, 0.8, 0.4, 0.3)
	
	# Wind movement
	wind_system.direction = Vector2(1, 0)
	wind_system.initial_velocity_min = 20.0
	wind_system.initial_velocity_max = 40.0
	wind_system.gravity = Vector2(0, 5)
	
	# Wind spawn area (much larger)
	wind_system.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wind_system.emission_rect_extents = Vector2(15, TOWN_HEIGHT * TILE_SIZE / 2.0)
	
	wind_system.z_index = -3
	add_child(wind_system)
	decoration_items.append(wind_system)

func create_torch_particles(pos: Vector2):
	"""Create flame particles for torches"""
	var flame_particles = CPUParticles2D.new()
	flame_particles.position = pos
	flame_particles.emitting = true
	
	# Flame settings
	flame_particles.amount = 35 # More flame particles
	flame_particles.lifetime = 2.0 # Longer lifetime
	
	# Flame appearance
	flame_particles.scale_amount_min = 0.3
	flame_particles.scale_amount_max = 0.8
	flame_particles.color = Color(1.0, 0.6, 0.2, 0.8)
	flame_particles.color_ramp = create_flame_gradient()
	
	# Flame movement
	flame_particles.direction = Vector2(0, -1)
	flame_particles.initial_velocity_min = 15.0
	flame_particles.initial_velocity_max = 35.0
	flame_particles.gravity = Vector2(0, -20)
	
	# Flame area
	flame_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	flame_particles.emission_sphere_radius = 4.0
	
	flame_particles.z_index = 1 # Flames can be in front of player
	add_child(flame_particles)
	decoration_items.append(flame_particles)

func create_flame_gradient() -> Gradient:
	"""Create a gradient for flame particles"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.2, 0.9)) # Bright yellow base
	gradient.add_point(0.5, Color(1.0, 0.4, 0.1, 0.7)) # Orange middle
	gradient.add_point(1.0, Color(0.8, 0.2, 0.1, 0.1)) # Dark red fade
	return gradient

# ===== EXISTING TILE CREATION FUNCTIONS (Updated) =====

func create_sprite_tile(x: int, y: int, texture: Texture2D, z_layer: int = 0):
	"""Create a sprite tile at the given grid position"""
	if not texture:
		print("TownGenerator: Warning - No texture provided for sprite tile")
		return null
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(x * TILE_SIZE + TILE_SIZE / 2.0, y * TILE_SIZE + TILE_SIZE / 2.0)
	
	# Scale down from 256x256 to 32x32
	var scale_factor = float(TILE_SIZE) / 256.0
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.z_index = z_layer
	
	add_child(sprite)
	return sprite

func create_ground_tile(x: int, y: int):
	"""Create a ground tile using random grass variation"""
	if grass_variations.size() == 0:
		# Fallback to colored rect if textures aren't loaded
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.4, 0.6, 0.3, 1)
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)
		return
	
	# Select grass variation with some bias toward certain types
	var grass_weights = [30, 25, 25, 20] # Slightly favor grass_a
	var total_weight = 100
	var random_value = rng.randi_range(1, total_weight)
	var current_weight = 0
	var grass_index = 0
	
	for i in range(grass_weights.size()):
		current_weight += grass_weights[i]
		if random_value <= current_weight:
			grass_index = i
			break
	
	if grass_index < grass_variations.size():
		var grass_texture = grass_variations[grass_index]
		create_sprite_tile(x, y, grass_texture, -10)

func create_road_tile(x: int, y: int):
	"""Create a road tile using cobblestone texture"""
	var texture = village_textures.get("cobblestone_road")
	if texture:
		var sprite = create_sprite_tile(x, y, texture, -5)
		if sprite:
			roads.append(sprite)
	else:
		# Fallback
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.6, 0.6, 0.6, 1)
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)
		roads.append(tile)

func create_plaza_tile(x: int, y: int):
	"""Create a plaza tile using stone texture"""
	var texture = village_textures.get("central_plaza_stone")
	if texture:
		create_sprite_tile(x, y, texture, -5)
	else:
		# Fallback
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.8, 0.8, 0.7, 1)
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)

func create_platform_tile(x: int, y: int):
	"""Create a platform tile for portals using magic platform texture"""
	var texture = village_textures.get("magic_platform")
	if texture:
		create_sprite_tile(x, y, texture, -3)
	else:
		# Fallback
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.3, 0.3, 0.8, 1)
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)

func create_wall_tile(x: int, y: int):
	"""Create a wall tile with collision using stone wall texture"""
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	collision_shape.shape = shape
	collision_shape.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	# Create sprite instead of ColorRect
	var texture = village_textures.get("building_wall")
	if texture:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		
		# Scale down from 256x256 to 32x32
		var scale_factor = float(TILE_SIZE) / 256.0
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.z_index = 0
		
		static_body.add_child(collision_shape)
		static_body.add_child(sprite)
	else:
		# Fallback to ColorRect
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.6, 0.4, 0.2, 1)
		tile.position = Vector2(0, 0)
		
		static_body.add_child(collision_shape)
		static_body.add_child(tile)
	
	static_body.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(static_body)
	buildings.append(static_body)

func create_timber_wall_tile(x: int, y: int):
	"""Create a timber frame wall tile with collision"""
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	collision_shape.shape = shape
	collision_shape.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	
	# Create sprite for timber frame wall
	var texture = village_textures.get("building_wall_timber")
	if texture:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		
		# Scale down from 256x256 to 32x32
		var scale_factor = float(TILE_SIZE) / 256.0
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.z_index = 0
		
		static_body.add_child(collision_shape)
		static_body.add_child(sprite)
	else:
		# Fallback to ColorRect
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.8, 0.7, 0.6, 1) # Lighter color for timber
		tile.position = Vector2(0, 0)
		
		static_body.add_child(collision_shape)
		static_body.add_child(tile)
	
	static_body.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	add_child(static_body)
	buildings.append(static_body)

func create_floor_tile(x: int, y: int):
	"""Create a floor tile inside buildings using wooden floor texture"""
	var texture = village_textures.get("wooden_floor")
	if texture:
		create_sprite_tile(x, y, texture, -8)
	else:
		# Fallback
		var tile = ColorRect.new()
		tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.color = Color(0.8, 0.7, 0.5, 1)
		tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		add_child(tile)

func create_massive_fountain(x: int, y: int):
	"""Create a massive fountain with enhanced particles"""
	var texture = village_textures.get("fountain_base")
	if texture:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
		
		# Scale for massive 4x4 fountain (128x128 pixels)
		var scale_factor = float(TILE_SIZE * 4) / 256.0
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.z_index = -1 # Behind player
		
		add_child(sprite)
		decoration_items.append(sprite)
		
		# Add enhanced fountain particles
		create_massive_fountain_particles(Vector2(x * TILE_SIZE, y * TILE_SIZE - 20))
	else:
		# Fallback
		var fountain = ColorRect.new()
		fountain.size = Vector2(TILE_SIZE * 4, TILE_SIZE * 4)
		fountain.color = Color(0.2, 0.4, 0.8, 1)
		fountain.position = Vector2(x * TILE_SIZE - TILE_SIZE * 2, y * TILE_SIZE - TILE_SIZE * 2)
		fountain.z_index = -1 # Behind player
		add_child(fountain)
		decoration_items.append(fountain)

func create_massive_fountain_particles(pos: Vector2):
	"""Create enhanced water particles for the massive fountain"""
	var water_particles = CPUParticles2D.new()
	water_particles.position = pos
	water_particles.emitting = true
	
	# Enhanced water fountain settings
	water_particles.amount = 120 # Much more particles
	water_particles.lifetime = 3.5 # Longer lifetime
	
	# Water appearance
	water_particles.scale_amount_min = 0.4
	water_particles.scale_amount_max = 1.2
	water_particles.color = Color(0.4, 0.7, 1.0, 0.8)
	
	# Water movement
	water_particles.direction = Vector2(0, -1)
	water_particles.initial_velocity_min = 50.0 # Higher velocity
	water_particles.initial_velocity_max = 80.0
	water_particles.gravity = Vector2(0, 98)
	
	# Massive fountain spray pattern
	water_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	water_particles.emission_sphere_radius = 16.0 # Much larger radius
	water_particles.spread = 35.0 # Wider spread
	
	water_particles.z_index = 2
	add_child(water_particles)
	decoration_items.append(water_particles)

func create_plaza_decorations(center_x: int, center_y: int):
	"""Add decorative elements around the plaza"""
	# Decorative benches around plaza (more spaced for larger plaza)
	var bench_positions = [
		Vector2(center_x - 8, center_y - 8),
		Vector2(center_x + 8, center_y - 8),
		Vector2(center_x - 8, center_y + 8),
		Vector2(center_x + 8, center_y + 8),
		Vector2(center_x, center_y - 10),
		Vector2(center_x, center_y + 10),
		Vector2(center_x - 10, center_y),
		Vector2(center_x + 10, center_y)
	]
	
	for bench_pos in bench_positions:
		create_decorative_bench(int(bench_pos.x), int(bench_pos.y))

func create_decorative_bench(x: int, y: int):
	"""Create an ornate bench"""
	var bench = ColorRect.new()
	bench.size = Vector2(TILE_SIZE * 1.5, TILE_SIZE * 0.75) # Larger benches
	bench.color = Color(0.6, 0.4, 0.2, 1) # Brown bench
	bench.position = Vector2(x * TILE_SIZE - TILE_SIZE / 4, y * TILE_SIZE + TILE_SIZE / 8)
	bench.z_index = -2 # FIXED: Behind player
	add_child(bench)
	decoration_items.append(bench)

func create_garden_tile(x: int, y: int):
	"""Create a decorative garden tile"""
	var texture = village_textures.get("garden_park")
	if texture:
		create_sprite_tile(x, y, texture, -7)

func create_workshop_tile(x: int, y: int):
	"""Create a workshop area tile"""
	var texture = village_textures.get("workshop")
	if texture:
		create_sprite_tile(x, y, texture, -7)

func create_portal_areas():
	"""Create areas where portals will be placed"""
	portal_locations = [
		Vector2(15, 45) * TILE_SIZE, # West portal (Level 1) - scaled positions
		Vector2(105, 45) * TILE_SIZE, # East portal (Level 2)
		Vector2(60, 15) * TILE_SIZE, # North portal (Level 3)
		Vector2(60, 75) * TILE_SIZE # South portal (Level 4)
	]
	
	# Create portal platforms
	for portal_pos in portal_locations:
		var grid_pos = portal_pos / TILE_SIZE
		create_portal_platform(int(grid_pos.x), int(grid_pos.y))

func create_portal_platform(x: int, y: int):
	"""Create a platform for a portal"""
	var platform_size = 5 # Larger platforms
	
	for px in range(platform_size):
		for py in range(platform_size):
			var tile_x = x + px - platform_size / 2
			var tile_y = y + py - platform_size / 2
			create_platform_tile(tile_x, tile_y)

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
	# Don't place on roads or too close to buildings
	var center_x = TOWN_WIDTH / 2
	var center_y = TOWN_HEIGHT / 2
	
	# Stay away from plaza center
	if Vector2(x, y).distance_to(Vector2(center_x, center_y)) < 12:
		return false
	
	# Don't place too close to buildings or portals
	for shop_pos in shop_locations:
		var grid_pos = shop_pos / TILE_SIZE
		if Vector2(x, y).distance_to(grid_pos) < 10:
			return false
	
	return true

func is_valid_position(x: int, y: int) -> bool:
	"""Check if position is within bounds"""
	return x >= 0 and x < TOWN_WIDTH and y >= 0 and y < TOWN_HEIGHT

func get_spawn_position() -> Vector2:
	"""Get the player spawn position"""
	return spawn_position

func get_portal_locations() -> Array:
	"""Get the locations where portals should be placed"""
	return portal_locations

func get_shop_locations() -> Array:
	"""Get the locations of shops"""
	return shop_locations

func get_interactive_signs() -> Array:
	"""Get all interactive signs for dialogue system"""
	return interactive_signs

func clear_town():
	"""Clear all town elements"""
	for child in get_children():
		child.queue_free()
	
	buildings.clear()
	roads.clear()
	decoration_items.clear()
	light_sources.clear()
	interactive_signs.clear()
	portal_locations.clear()
	shop_locations.clear()
	npc_locations.clear()
