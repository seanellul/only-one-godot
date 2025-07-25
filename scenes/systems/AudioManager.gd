extends Node

# Comprehensive Audio Management System for dynamic music and sound effects

# Audio players
var ambient_player: AudioStreamPlayer
var action_player: AudioStreamPlayer
var fx_player: AudioStreamPlayer
var crossfade_timer: Timer

# Current audio state
var current_track_type: String = ""
var current_track_index: int = 0
var is_in_combat: bool = false
var is_crossfading: bool = false

# Audio settings
var master_volume: float = 0.8
var music_volume: float = 0.7
var fx_volume: float = 0.9
var fade_duration: float = 2.0
var combat_fade_duration: float = 1.0

# Track collections
var ambient_tracks: Array[AudioStream] = []
var light_ambient_tracks: Array[AudioStream] = []
var dark_ambient_tracks: Array[AudioStream] = []
var action_tracks: Array[AudioStream] = []
var fx_tracks: Dictionary = {}

# Music rotation system
var track_history: Array[int] = []
var max_history_size: int = 3 # Prevent recent repeats

# Signals
signal music_changed(track_type: String, track_name: String)
signal volume_changed(volume_type: String, new_volume: float)

func _ready():
	setup_audio_players()
	load_audio_tracks()
	setup_game_connections()
	
	# Start with ambient music
	call_deferred("start_initial_music")
	
	DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "AudioManager system initialized with all audio tracks loaded")

func setup_audio_players():
	"""Create and configure audio players"""
	# Ambient/background music player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.volume_db = linear_to_db(master_volume * music_volume)
	ambient_player.finished.connect(_on_ambient_track_finished)
	add_child(ambient_player)
	
	# Action/combat music player
	action_player = AudioStreamPlayer.new()
	action_player.name = "ActionPlayer"
	action_player.volume_db = linear_to_db(master_volume * music_volume)
	action_player.finished.connect(_on_action_track_finished)
	add_child(action_player)
	
	# Sound effects player
	fx_player = AudioStreamPlayer.new()
	fx_player.name = "FXPlayer"
	fx_player.volume_db = linear_to_db(master_volume * fx_volume)
	add_child(fx_player)
	
	# Crossfade timer
	crossfade_timer = Timer.new()
	crossfade_timer.name = "CrossfadeTimer"
	crossfade_timer.one_shot = true
	crossfade_timer.timeout.connect(_on_crossfade_complete)
	add_child(crossfade_timer)

func load_audio_tracks():
	"""Load all audio tracks from the music folder"""
	# Load ambient tracks (1-10)
	for i in range(1, 11):
		var track_path = "res://music/Ambient " + str(i) + ".mp3"
		var audio_stream = load(track_path)
		if audio_stream:
			ambient_tracks.append(audio_stream)
			DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Loaded Ambient track " + str(i))
		else:
			DebugManager.log_error(DebugManager.DebugCategory.AUDIO, "Failed to load Ambient track " + str(i) + " from " + track_path)
	
	# Load light ambient tracks (1-5)
	for i in range(1, 6):
		var track_path = "res://music/Light Ambience " + str(i) + ".mp3"
		var audio_stream = load(track_path)
		if audio_stream:
			light_ambient_tracks.append(audio_stream)
			print("AudioManager: Loaded Light Ambience ", i)
	
	# Load dark ambient tracks (1-5)
	for i in range(1, 6):
		var track_path = "res://music/Dark Ambient " + str(i) + ".mp3"
		var audio_stream = load(track_path)
		if audio_stream:
			dark_ambient_tracks.append(audio_stream)
			print("AudioManager: Loaded Dark Ambient ", i)
	
	# Load action tracks (1-5)
	for i in range(1, 6):
		var track_path = "res://music/Action " + str(i) + ".mp3"
		var audio_stream = load(track_path)
		if audio_stream:
			action_tracks.append(audio_stream)
			print("AudioManager: Loaded Action ", i)
	
	# Load FX tracks
	fx_tracks["death"] = load("res://music/Fx 3.mp3")
	fx_tracks["level_up"] = load("res://music/Fx 2.mp3")
	fx_tracks["victory"] = load("res://music/Fx 1.mp3")
	
	var total_loaded = ambient_tracks.size() + light_ambient_tracks.size() + dark_ambient_tracks.size() + action_tracks.size() + fx_tracks.size()
	DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Audio loading complete - Total tracks loaded: " + str(total_loaded))
	DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Breakdown: " + str(ambient_tracks.size()) + " ambient, " + str(light_ambient_tracks.size()) + " light ambient, " + str(dark_ambient_tracks.size()) + " dark ambient, " + str(action_tracks.size()) + " action, " + str(fx_tracks.size()) + " FX")

func setup_game_connections():
	"""Connect to game systems for audio triggers"""
	# Connect to zone changes
	call_deferred("connect_zone_system")
	
	# Connect to combat system
	call_deferred("connect_combat_system")
	
	# Connect to shop system for level up detection
	call_deferred("connect_upgrade_system")

func connect_zone_system():
	"""Connect to world manager for zone-based music"""
	var world_manager = DebugManager.safe_get_node("/root/WorldSystemManager", "AudioManager zone system")
	if world_manager:
		if DebugManager.safe_connect_signal(world_manager, "zone_changed", _on_zone_changed, "AudioManager zone music"):
			DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Connected to WorldSystemManager for zone-based music")
		else:
			DebugManager.log_warning(DebugManager.DebugCategory.AUDIO, "Failed to connect to zone_changed signal")

func connect_combat_system():
	"""Connect to combat events for action music"""
	# We'll use a timer to check for nearby enemies instead of direct connection
	var combat_check_timer = Timer.new()
	combat_check_timer.wait_time = 0.5 # Check every half second
	combat_check_timer.autostart = true
	combat_check_timer.timeout.connect(_check_combat_state)
	add_child(combat_check_timer)

func connect_upgrade_system():
	"""Connect to upgrade events for level up sound"""
	# We'll monitor for upgrade purchases through shop events (safely)
	var auto_save_manager = get_node_or_null("/root/AutoSaveManager")
	if auto_save_manager and is_instance_valid(auto_save_manager):
		if DebugManager.safe_connect_signal(auto_save_manager, "auto_save_triggered", _on_auto_save_triggered, "AudioManager level up sounds"):
			DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "Connected to AutoSaveManager for level up sound effects")
		else:
			DebugManager.log_warning(DebugManager.DebugCategory.AUDIO, "Failed to connect to auto_save_triggered signal")
	else:
		DebugManager.log_info(DebugManager.DebugCategory.AUDIO, "AutoSaveManager not available for level up sounds (disabled for crash testing)")

func start_initial_music():
	"""Start playing initial ambient music"""
	play_ambient_music("light") # Start with light ambient for town

# Music Management Functions

func play_ambient_music(ambient_type: String = "ambient"):
	"""Play ambient music based on type"""
	if is_in_combat:
		return # Don't change music during combat
	
	var track_collection: Array[AudioStream]
	var track_type_name: String
	
	match ambient_type:
		"light":
			track_collection = light_ambient_tracks
			track_type_name = "Light Ambient"
		"dark":
			track_collection = dark_ambient_tracks
			track_type_name = "Dark Ambient"
		"ambient":
			track_collection = ambient_tracks
			track_type_name = "Ambient"
		_:
			track_collection = ambient_tracks
			track_type_name = "Ambient"
	
	if track_collection.size() == 0:
		print("AudioManager: No tracks available for type: ", ambient_type)
		return
	
	# Select a track that wasn't recently played
	var track_index = select_random_track(track_collection.size())
	var selected_track = track_collection[track_index]
	
	if current_track_type != track_type_name or not ambient_player.playing:
		crossfade_to_ambient(selected_track)
		current_track_type = track_type_name
		current_track_index = track_index
		
		music_changed.emit(track_type_name, track_type_name + " " + str(track_index + 1))
		print("AudioManager: Playing ", track_type_name, " ", track_index + 1)

func play_action_music():
	"""Start action music for combat"""
	if action_tracks.size() == 0:
		return
	
	var track_index = select_random_track(action_tracks.size())
	var selected_track = action_tracks[track_index]
	
	crossfade_to_action(selected_track)
	current_track_type = "Action"
	current_track_index = track_index
	
	music_changed.emit("Action", "Action " + str(track_index + 1))
	print("AudioManager: Starting action music - Action ", track_index + 1)

func select_random_track(collection_size: int) -> int:
	"""Select a random track avoiding recent repeats"""
	var available_indices = []
	
	for i in range(collection_size):
		if i not in track_history:
			available_indices.append(i)
	
	# If all tracks were recent, clear history and use any track
	if available_indices.size() == 0:
		track_history.clear()
		return randi() % collection_size
	
	var selected_index = available_indices[randi() % available_indices.size()]
	
	# Add to history
	track_history.append(selected_index)
	if track_history.size() > max_history_size:
		track_history.pop_front()
	
	return selected_index

# Crossfade Functions

func crossfade_to_ambient(new_track: AudioStream):
	"""Crossfade from current music to new ambient track"""
	if is_crossfading:
		return
	
	is_crossfading = true
	
	# If action music is playing, fade it out first
	if action_player.playing:
		fade_out_action()
	
	# Start new ambient track
	ambient_player.stream = new_track
	ambient_player.volume_db = linear_to_db(0.01) # Start very quiet
	ambient_player.play()
	
	# Fade in new track
	fade_in_ambient()

func crossfade_to_action(new_track: AudioStream):
	"""Crossfade from ambient to action music"""
	if is_crossfading:
		return
	
	is_crossfading = true
	
	# Fade out ambient music
	if ambient_player.playing:
		fade_out_ambient()
	
	# Start action track
	action_player.stream = new_track
	action_player.volume_db = linear_to_db(0.01) # Start very quiet
	action_player.play()
	
	# Fade in action music
	fade_in_action()

func fade_in_ambient():
	"""Fade in ambient music"""
	var target_volume = master_volume * music_volume
	var tween = create_tween()
	tween.tween_method(
		func(volume): ambient_player.volume_db = linear_to_db(volume),
		0.01,
		target_volume,
		fade_duration
	)
	tween.tween_callback(func(): is_crossfading = false)

func fade_in_action():
	"""Fade in action music"""
	var target_volume = master_volume * music_volume * 1.1 # Slightly louder for action
	var tween = create_tween()
	tween.tween_method(
		func(volume): action_player.volume_db = linear_to_db(volume),
		0.01,
		target_volume,
		combat_fade_duration
	)
	tween.tween_callback(func(): is_crossfading = false)

func fade_out_ambient():
	"""Fade out ambient music"""
	var tween = create_tween()
	tween.tween_method(
		func(volume): ambient_player.volume_db = linear_to_db(volume),
		db_to_linear(ambient_player.volume_db),
		0.01,
		fade_duration
	)
	tween.tween_callback(func(): ambient_player.stop())

func fade_out_action():
	"""Fade out action music"""
	var tween = create_tween()
	tween.tween_method(
		func(volume): action_player.volume_db = linear_to_db(volume),
		db_to_linear(action_player.volume_db),
		0.01,
		combat_fade_duration
	)
	tween.tween_callback(func(): action_player.stop())

# Sound Effects

func play_fx(fx_type: String):
	"""Play a sound effect"""
	if fx_type in fx_tracks:
		var fx_stream = fx_tracks[fx_type]
		if fx_stream:
			fx_player.stream = fx_stream
			fx_player.play()
			print("AudioManager: Playing FX - ", fx_type)
	else:
		print("AudioManager: FX type not found: ", fx_type)

func play_death_sound():
	"""Play death sound effect"""
	play_fx("death")

func play_level_up_sound():
	"""Play level up sound effect"""
	play_fx("level_up")

func play_victory_sound():
	"""Play victory sound effect"""
	play_fx("victory")

# Event Handlers

func _on_zone_changed(old_zone: String, new_zone: String):
	"""Handle zone changes for appropriate music"""
	print("AudioManager: Zone changed from ", old_zone, " to ", new_zone)
	
	match new_zone:
		"TOWN":
			play_ambient_music("light")
		"DANGER_ZONE":
			play_ambient_music("dark")
		_:
			play_ambient_music("ambient")

func _check_combat_state():
	"""Check if player is in combat to trigger action music"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var enemies_nearby = false
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance < 200: # Combat range
				enemies_nearby = true
				break
	
	# Transition to/from combat music
	if enemies_nearby and not is_in_combat:
		is_in_combat = true
		play_action_music()
	elif not enemies_nearby and is_in_combat:
		is_in_combat = false
		# Return to appropriate ambient music based on current zone
		var world_manager = get_node_or_null("/root/WorldSystemManager")
		if world_manager:
			var current_zone = world_manager.get("current_zone_type")
			match current_zone:
				0: # TOWN
					play_ambient_music("light")
				1: # DANGER_ZONE
					play_ambient_music("dark")
				_:
					play_ambient_music("ambient")

func _on_auto_save_triggered(checkpoint_type: String):
	"""Detect upgrade purchases for level up sound"""
	if checkpoint_type == "shop_purchase":
		# Small delay to let the purchase complete
		await get_tree().create_timer(0.5).timeout
		play_level_up_sound()

func _on_ambient_track_finished():
	"""Handle when ambient track finishes - play next track"""
	if not is_in_combat:
		# Determine current ambient type and continue
		var world_manager = get_node_or_null("/root/WorldSystemManager")
		if world_manager:
			var current_zone = world_manager.get("current_zone_type")
			match current_zone:
				0: # TOWN
					play_ambient_music("light")
				1: # DANGER_ZONE
					play_ambient_music("dark")
				_:
					play_ambient_music("ambient")
		else:
			play_ambient_music("ambient")

func _on_action_track_finished():
	"""Handle when action track finishes - loop or switch if combat ended"""
	if is_in_combat:
		# Continue with another action track
		play_action_music()
	else:
		# Combat ended during track, switch back to ambient
		_check_combat_state()

func _on_crossfade_complete():
	"""Handle crossfade completion"""
	is_crossfading = false

# Public Interface

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	volume_changed.emit("master", master_volume)

func set_music_volume(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	volume_changed.emit("music", music_volume)

func set_fx_volume(volume: float):
	"""Set FX volume (0.0 to 1.0)"""
	fx_volume = clamp(volume, 0.0, 1.0)
	fx_player.volume_db = linear_to_db(master_volume * fx_volume)
	volume_changed.emit("fx", fx_volume)

func update_volumes():
	"""Update all player volumes"""
	var music_db = linear_to_db(master_volume * music_volume)
	var fx_db = linear_to_db(master_volume * fx_volume)
	
	if not is_crossfading:
		ambient_player.volume_db = music_db
		action_player.volume_db = music_db
	fx_player.volume_db = fx_db

func stop_all_music():
	"""Stop all music"""
	ambient_player.stop()
	action_player.stop()

func pause_music():
	"""Pause current music"""
	if ambient_player.playing:
		ambient_player.stream_paused = true
	if action_player.playing:
		action_player.stream_paused = true

func resume_music():
	"""Resume paused music"""
	if ambient_player.playing:
		ambient_player.stream_paused = false
	if action_player.playing:
		action_player.stream_paused = false

func force_music_type(music_type: String):
	"""Force a specific music type (for testing/special events)"""
	match music_type:
		"light":
			play_ambient_music("light")
		"dark":
			play_ambient_music("dark")
		"action":
			is_in_combat = true
			play_action_music()
		"ambient":
			play_ambient_music("ambient")

func get_current_music_info() -> Dictionary:
	"""Get information about currently playing music"""
	return {
		"type": current_track_type,
		"index": current_track_index,
		"is_combat": is_in_combat,
		"ambient_playing": ambient_player.playing,
		"action_playing": action_player.playing,
		"is_crossfading": is_crossfading
	}
