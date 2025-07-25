extends Node2D

@onready var world_manager = $WorldSystemManager
@onready var player = $Player

func _ready():
	# Wait a frame for world system to initialize
	await get_tree().process_frame
	
	# Connect to world manager signals (with safety checks)
	if world_manager and is_instance_valid(world_manager):
		if world_manager.has_signal("player_spawned"):
			world_manager.player_spawned.connect(_on_player_spawned)
		else:
			print("RoomController: WorldSystemManager missing player_spawned signal")
		
		if world_manager.has_signal("zone_loaded"):
			world_manager.zone_loaded.connect(_on_zone_loaded)
		else:
			print("RoomController: WorldSystemManager missing zone_loaded signal")
		
		# Initialize world system
		if world_manager.has_method("initialize_world"):
			world_manager.initialize_world()
		else:
			print("RoomController: WorldSystemManager missing initialize_world method")

func _input(event):
	# Press R to regenerate current zone
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_R and event.pressed):
		regenerate_current_zone()
	
	# Press C to toggle collision shape visibility
	if event is InputEventKey and event.keycode == KEY_C and event.pressed:
		toggle_collision_debug()

func regenerate_current_zone():
	print("Regenerating current zone...")
	if world_manager and is_instance_valid(world_manager):
		if world_manager.has_method("regenerate_current_zone"):
			world_manager.regenerate_current_zone()
		else:
			print("RoomController: WorldSystemManager missing regenerate_current_zone method")

func _on_player_spawned(spawn_position: Vector2):
	"""Called when world manager determines player spawn position"""
	if player:
		player.position = spawn_position
		print("RoomController: Player spawned at: ", player.position)

func _on_zone_loaded(zone_type: String, zone_level: int):
	"""Called when a new zone is loaded"""
	print("RoomController: Zone loaded - Type: ", zone_type, ", Level: ", zone_level)

func toggle_collision_debug():
	# Toggle collision shape visibility for debugging
	get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint
	print("Collision debug: ", "ON" if get_tree().debug_collisions_hint else "OFF")
