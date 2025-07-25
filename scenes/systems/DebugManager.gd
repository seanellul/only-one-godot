extends Node

# Comprehensive debugging and error handling system
# Prevents common issues across all game systems

# Debug settings
var debug_enabled: bool = true
var log_to_file: bool = true
var log_file_path: String = "user://debug_log.txt"
var max_log_entries: int = 1000

# Debug categories
enum DebugCategory {
	SYSTEM,
	AUDIO,
	UI,
	SAVE,
	COMBAT,
	INVENTORY,
	HINTS,
	MINIMAP
}

# Error tracking
var error_count: Dictionary = {}
var logged_errors: Array[String] = []

# Node validation cache
var validated_nodes: Dictionary = {}
var validation_cache_timeout: float = 5.0

signal error_detected(category: DebugCategory, message: String)
signal warning_issued(category: DebugCategory, message: String)

func _ready():
	print("DebugManager: Initializing comprehensive debugging system...")
	setup_debug_system()
	
	# Clear old logs
	clear_old_logs()
	
	# Start periodic validation
	var validation_timer = Timer.new()
	validation_timer.wait_time = 1.0
	validation_timer.autostart = true
	validation_timer.timeout.connect(_periodic_validation)
	add_child(validation_timer)
	
	log_info(DebugCategory.SYSTEM, "DebugManager initialized successfully")

func setup_debug_system():
	"""Initialize the debugging system"""
	# Initialize error counters
	for category in DebugCategory.values():
		error_count[category] = 0
	
	# Connect to tree signals for node tracking
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)

# Logging Functions

func log_info(category: DebugCategory, message: String):
	"""Log an informational message"""
	if debug_enabled:
		var formatted_message = format_log_message("INFO", category, message)
		print(formatted_message)
		write_to_log_file(formatted_message)

func log_warning(category: DebugCategory, message: String):
	"""Log a warning message"""
	var formatted_message = format_log_message("WARN", category, message)
	print(formatted_message)
	write_to_log_file(formatted_message)
	warning_issued.emit(category, message)

func log_error(category: DebugCategory, message: String):
	"""Log an error message"""
	error_count[category] += 1
	var formatted_message = format_log_message("ERROR", category, message)
	print(formatted_message)
	write_to_log_file(formatted_message)
	
	# Track unique errors
	if message not in logged_errors:
		logged_errors.append(message)
	
	error_detected.emit(category, message)

func format_log_message(level: String, category: DebugCategory, message: String) -> String:
	"""Format a log message with timestamp and category"""
	var timestamp = Time.get_datetime_string_from_system()
	var category_name = DebugCategory.keys()[category]
	return "[%s] %s [%s]: %s" % [timestamp, level, category_name, message]

func write_to_log_file(message: String):
	"""Write message to debug log file"""
	if not log_to_file:
		return
		
	var file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file:
		file.store_line(message)
		file.close()

# Node Validation Functions

func safe_get_node(path: String, context: String = "") -> Node:
	"""Safely get a node with validation and logging"""
	var node = get_node_or_null(path)
	if not node:
		log_warning(DebugCategory.SYSTEM, "Node not found at path '%s' (context: %s)" % [path, context])
		return null
	
	if not is_instance_valid(node):
		log_warning(DebugCategory.SYSTEM, "Node at path '%s' is not valid (context: %s)" % [path, context])
		return null
	
	return node

func safe_add_child(parent: Node, child: Node, context: String = "") -> bool:
	"""Safely add a child node with validation"""
	if not parent or not is_instance_valid(parent):
		log_error(DebugCategory.UI, "Cannot add child - parent is invalid (context: %s)" % context)
		return false
	
	if not child or not is_instance_valid(child):
		log_error(DebugCategory.UI, "Cannot add child - child is invalid (context: %s)" % context)
		return false
	
	if child.get_parent():
		log_warning(DebugCategory.UI, "Child already has a parent, removing first (context: %s)" % context)
		child.get_parent().remove_child(child)
	
	parent.add_child(child)
	log_info(DebugCategory.UI, "Successfully added child '%s' to '%s' (context: %s)" % [child.name, parent.name, context])
	return true

func safe_connect_signal(source: Node, signal_name: String, target: Callable, context: String = "") -> bool:
	"""Safely connect a signal with validation"""
	if not source or not is_instance_valid(source):
		log_error(DebugCategory.SYSTEM, "Cannot connect signal - source is invalid (context: %s)" % context)
		return false
	
	if not source.has_signal(signal_name):
		log_error(DebugCategory.SYSTEM, "Signal '%s' not found on node '%s' (context: %s)" % [signal_name, source.name, context])
		return false
	
	if source.is_connected(signal_name, target):
		log_warning(DebugCategory.SYSTEM, "Signal '%s' already connected (context: %s)" % [signal_name, context])
		return true
	
	source.connect(signal_name, target)
	log_info(DebugCategory.SYSTEM, "Successfully connected signal '%s' (context: %s)" % [signal_name, context])
	return true

func validate_autoload(autoload_name: String) -> bool:
	"""Validate that an autoload exists and is accessible"""
	var autoload = get_node_or_null("/root/" + autoload_name)
	if not autoload:
		log_error(DebugCategory.SYSTEM, "Autoload '%s' not found" % autoload_name)
		return false
	
	if not is_instance_valid(autoload):
		log_error(DebugCategory.SYSTEM, "Autoload '%s' is not valid" % autoload_name)
		return false
	
	return true

func validate_scene_integrity() -> Dictionary:
	"""Validate the current scene's integrity"""
	var result = {
		"valid": true,
		"errors": [],
		"warnings": []
	}
	
	var scene = get_tree().current_scene
	if not scene:
		result.valid = false
		result.errors.append("No current scene found")
		return result
	
	if not is_instance_valid(scene):
		result.valid = false
		result.errors.append("Current scene is not valid")
		return result
	
	# Check for essential nodes
	var essential_groups = ["player", "ui_layer"]
	for group in essential_groups:
		var nodes = get_tree().get_nodes_in_group(group)
		if nodes.is_empty():
			result.warnings.append("No nodes found in essential group: " + group)
	
	return result

# System Health Monitoring

func check_system_health() -> Dictionary:
	"""Comprehensive system health check"""
	var health_report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"autoloads": {},
		"scene_integrity": {},
		"error_counts": error_count.duplicate(),
		"memory_usage": _get_safe_memory_info(),
		"overall_status": "HEALTHY"
	}
	
	# Check autoloads (only enabled ones)
	var autoloads = ["SaveSystem", "GameManager", "InventorySystem", "CollectionTracker"]
	for autoload in autoloads:
		health_report.autoloads[autoload] = validate_autoload(autoload)
		if not health_report.autoloads[autoload]:
			health_report.overall_status = "CRITICAL"
	
	# Check scene integrity
	health_report.scene_integrity = validate_scene_integrity()
	if not health_report.scene_integrity.valid:
		health_report.overall_status = "CRITICAL"
	
	# Check error counts
	var total_errors = 0
	for category in error_count:
		total_errors += error_count[category]
	
	if total_errors > 50:
		health_report.overall_status = "DEGRADED"
	elif total_errors > 10:
		health_report.overall_status = "WARNING"
	
	log_info(DebugCategory.SYSTEM, "System health check completed - Status: " + health_report.overall_status)
	return health_report

# Audio System Debugging

func debug_audio_system() -> Dictionary:
	"""Debug the audio system specifically"""
	var audio_debug = {
		"audio_manager_valid": false,
		"players_created": 0,
		"current_track": "disabled",
		"volume_levels": {},
		"tracks_loaded": 0,
		"status": "AudioManager disabled for crash testing"
	}
	
	# Check if AudioManager is available (might be disabled for testing)
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and is_instance_valid(audio_manager):
		audio_debug.audio_manager_valid = true
		audio_debug.status = "AudioManager active"
		
		# Check players
		for child in audio_manager.get_children():
			if child is AudioStreamPlayer:
				audio_debug.players_created += 1
		
		# Get current music info
		if audio_manager.has_method("get_current_music_info"):
			var music_info = audio_manager.get_current_music_info()
			audio_debug.current_track = music_info.get("type") if "type" in music_info else "unknown"
		
		# Check volume levels
		audio_debug.volume_levels = {
			"master": audio_manager.master_volume if "master_volume" in audio_manager else 0.0,
			"music": audio_manager.music_volume if "music_volume" in audio_manager else 0.0,
			"fx": audio_manager.fx_volume if "fx_volume" in audio_manager else 0.0
		}
		
		# Count loaded tracks
		var track_collections = ["ambient_tracks", "light_ambient_tracks", "dark_ambient_tracks", "action_tracks"]
		for collection in track_collections:
			if audio_manager.has_method("get"):
				var tracks = audio_manager.get(collection)
				if tracks and tracks is Array:
					audio_debug.tracks_loaded += tracks.size()
	else:
		audio_debug.current_track = "AudioManager not available"
		audio_debug.volume_levels = {"master": "N/A", "music": "N/A", "fx": "N/A"}
	
	log_info(DebugCategory.AUDIO, "Audio system debug completed - Status: " + audio_debug.status)
	return audio_debug

# Save System Debugging

func debug_save_system() -> Dictionary:
	"""Debug the save system specifically"""
	var save_debug = {
		"save_system_valid": false,
		"save_file_exists": false,
		"save_file_readable": false,
		"last_save_data": {},
		"auto_save_working": false
	}
	
	if validate_autoload("SaveSystem"):
		var save_system = get_node("/root/SaveSystem")
		save_debug.save_system_valid = true
		
		# Check save file
		if save_system.has_method("has_save_file"):
			save_debug.save_file_exists = save_system.has_save_file()
		
		# Try to read save data
		if save_debug.save_file_exists and save_system.has_method("load_game"):
			var save_data = save_system.load_game()
			save_debug.save_file_readable = not save_data.is_empty()
			save_debug.last_save_data = save_data
	
	var auto_save_manager = get_node_or_null("/root/AutoSaveManager")
	if auto_save_manager and is_instance_valid(auto_save_manager):
		save_debug.auto_save_working = true
	
	log_info(DebugCategory.SAVE, "Save system debug completed")
	return save_debug

# Utility Functions

func _get_safe_memory_info() -> Dictionary:
	"""Safely get memory information with fallbacks for different Godot versions"""
	var memory_info = {}
	
	# Use only basic system info that's available in all Godot versions
	memory_info["engine_version"] = Engine.get_version_info()
	memory_info["platform"] = OS.get_name()
	memory_info["processor_count"] = OS.get_processor_count()
	
	# Try static memory if available
	if OS.has_method("get_static_memory_usage"):
		memory_info["static_memory"] = OS.get_static_memory_usage()
	else:
		memory_info["static_memory"] = "Not available"
	
	# Skip dynamic memory and process list as they're not available in this Godot version
	memory_info["heap_memory"] = "Not supported in this Godot version"
	memory_info["active_processes"] = "Not supported in this Godot version"
	
	# Add frame timing info instead
	memory_info["fps"] = Engine.get_frames_per_second()
	memory_info["frame_delay"] = Engine.get_process_frames()
	
	return memory_info

func _periodic_validation():
	"""Periodic validation of critical systems"""
	# Clear validation cache
	validated_nodes.clear()
	
	# Quick health check
	var health = check_system_health()
	if health.overall_status == "CRITICAL":
		log_error(DebugCategory.SYSTEM, "System health is CRITICAL!")

func _on_node_added(node: Node):
	"""Track when nodes are added"""
	if debug_enabled:
		log_info(DebugCategory.SYSTEM, "Node added: " + node.name + " (" + node.get_class() + ")")

func _on_node_removed(node: Node):
	"""Track when nodes are removed"""
	if debug_enabled:
		log_info(DebugCategory.SYSTEM, "Node removed: " + node.name + " (" + node.get_class() + ")")

func clear_old_logs():
	"""Clear old log entries to prevent file bloat"""
	if FileAccess.file_exists(log_file_path):
		var file = FileAccess.open(log_file_path, FileAccess.READ)
		if file:
			var lines = []
			while not file.eof_reached():
				var line = file.get_line()
				if line.length() > 0:
					lines.append(line)
			file.close()
			
			# Keep only recent entries
			if lines.size() > max_log_entries:
				lines = lines.slice(lines.size() - max_log_entries)
				
				# Rewrite file with recent entries
				file = FileAccess.open(log_file_path, FileAccess.WRITE)
				if file:
					for line in lines:
						file.store_line(line)
					file.close()

# Tween Safety Functions

func safe_tween_property(tween: Tween, object: Object, property: String, final_val: Variant, duration: float, context: String = "") -> bool:
	"""Safely create a tween property with validation"""
	if not tween or not is_instance_valid(tween):
		log_error(DebugCategory.UI, "Invalid tween provided for property animation (context: %s)" % context)
		return false
	
	if not object or not is_instance_valid(object):
		log_error(DebugCategory.UI, "Invalid object provided for tween property '%s' (context: %s)" % [property, context])
		return false
	
	# For sub-properties like "position:x" or "modulate:a", validate the base property
	var base_property = property.split(":")[0]
	if not base_property in object:
		log_error(DebugCategory.UI, "Base property '%s' not found on object '%s' (context: %s)" % [base_property, object.get_class(), context])
		return false
	
	# Attempt to create the tween (let Godot handle the sub-property validation)
	var property_tween = tween.tween_property(object, property, final_val, duration)
	if not property_tween:
		log_error(DebugCategory.UI, "Failed to create tween for property '%s' (context: %s)" % [property, context])
		return false
	
	log_info(DebugCategory.UI, "Successfully created tween for property '%s' (context: %s)" % [property, context])
	return true

func safe_create_tween(node: Node, context: String = "") -> Tween:
	"""Safely create a tween with validation"""
	if not node or not is_instance_valid(node):
		log_error(DebugCategory.UI, "Invalid node provided for tween creation (context: %s)" % context)
		return null
	
	var tween = node.create_tween()
	if not tween or not is_instance_valid(tween):
		log_error(DebugCategory.UI, "Failed to create tween (context: %s)" % context)
		return null
	
	log_info(DebugCategory.UI, "Successfully created tween (context: %s)" % context)
	return tween

func safe_tween_callback(tween: Tween, callback: Callable, delay: float = 0.0, context: String = "") -> bool:
	"""Safely create a tween callback with validation"""
	if not tween or not is_instance_valid(tween):
		log_error(DebugCategory.UI, "Invalid tween provided for callback (context: %s)" % context)
		return false
	
	if not callback.is_valid():
		log_error(DebugCategory.UI, "Invalid callback provided for tween (context: %s)" % context)
		return false
	
	var callback_tween = tween.tween_callback(callback)
	if callback_tween and delay > 0.0:
		callback_tween.set_delay(delay)
	
	if not callback_tween:
		log_error(DebugCategory.UI, "Failed to create tween callback (context: %s)" % context)
		return false
	
	log_info(DebugCategory.UI, "Successfully created tween callback (context: %s)" % context)
	return true

# Public Interface

func get_debug_report() -> Dictionary:
	"""Get comprehensive debug report"""
	return {
		"system_health": check_system_health(),
		"audio_debug": debug_audio_system(),
		"save_debug": debug_save_system(),
		"error_summary": {
			"total_errors": logged_errors.size(),
			"error_counts": error_count.duplicate(),
			"recent_errors": logged_errors.slice(max(0, logged_errors.size() - 10))
		}
	}

func force_system_validation():
	"""Force validation of all systems"""
	log_info(DebugCategory.SYSTEM, "=== FORCED SYSTEM VALIDATION ===")
	var report = get_debug_report()
	log_info(DebugCategory.SYSTEM, "Validation complete - Status: " + report.system_health.overall_status)
	return report

func set_debug_level(enabled: bool, file_logging: bool = true):
	"""Configure debug settings"""
	debug_enabled = enabled
	log_to_file = file_logging
	log_info(DebugCategory.SYSTEM, "Debug settings updated - Enabled: %s, File logging: %s" % [enabled, file_logging])
