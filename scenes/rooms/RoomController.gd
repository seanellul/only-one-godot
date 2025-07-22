extends Node2D

@onready var world_generator = $WorldGenerator
@onready var player = $Player

func _ready():
	# Wait a frame for world generation to complete
	await get_tree().process_frame
	spawn_player_in_first_room()

func _input(event):
	# Press R to regenerate world
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_R and event.pressed):
		regenerate_world()
	
	# Press C to toggle collision shape visibility
	if event is InputEventKey and event.keycode == KEY_C and event.pressed:
		toggle_collision_debug()

func regenerate_world():
	print("Regenerating world...")
	world_generator.regenerate()
	# Wait a frame for regeneration to complete
	await get_tree().process_frame
	spawn_player_in_first_room()

func spawn_player_in_first_room():
	# Find the first room and place player in its center
	if world_generator.rooms.size() > 0:
		var first_room = world_generator.rooms[0]
		var spawn_x = (first_room.center_x * world_generator.TILE_SIZE)
		var spawn_y = (first_room.center_y * world_generator.TILE_SIZE)
		player.position = Vector2(spawn_x, spawn_y)
		print("Player spawned at: ", player.position)

func toggle_collision_debug():
	# Toggle collision shape visibility for debugging
	get_tree().debug_collisions_hint = !get_tree().debug_collisions_hint
	print("Collision debug: ", "ON" if get_tree().debug_collisions_hint else "OFF")
