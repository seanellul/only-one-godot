extends Control

# Minimal test scene to isolate crash issues
# This scene avoids all complex systems and tweens

var test_label: Label

func _ready():
	print("CrashTestScene: Starting minimal test...")
	
	# Create simple UI without tweens
	test_label = Label.new()
	test_label.text = "🧪 CRASH TEST - If you see this, basic systems work!\nPress F1 to test DebugManager\nPress F2 to test basic tween\nPress F3 to test all systems\nPress F4 to restore main menu\nPress F5 to test room scene\nPress ESCAPE to quit"
	test_label.position = Vector2(50, 50)
	test_label.add_theme_font_size_override("font_size", 16)
	add_child(test_label)
	
	print("CrashTestScene: Basic UI created successfully")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				test_debug_manager()
			KEY_F2:
				test_basic_tween()
			KEY_F3:
				test_all_systems()
			KEY_F4:
				restore_main_menu()
			KEY_F5:
				test_room_scene()
			KEY_ESCAPE:
				print("CrashTestScene: Quitting...")
				get_tree().quit()

func test_debug_manager():
	"""Test DebugManager functionality"""
	print("CrashTestScene: Testing DebugManager...")
	
	if DebugManager:
		DebugManager.log_info(DebugManager.DebugCategory.SYSTEM, "DebugManager test successful!")
		test_label.text += "\n✅ DebugManager works!"
	else:
		test_label.text += "\n❌ DebugManager not available!"

func test_basic_tween():
	"""Test basic tween functionality with safety"""
	print("CrashTestScene: Testing basic tween...")
	
	if not is_instance_valid(test_label):
		print("CrashTestScene: Label invalid!")
		return
	
	# Test safe tween creation
	if DebugManager:
		var tween = DebugManager.safe_create_tween(self, "CrashTestScene basic test")
		if tween:
			# Test with position instead of modulate (position definitely exists on Control nodes)
			var original_pos = test_label.position
			var success = DebugManager.safe_tween_property(tween, test_label, "position:x", original_pos.x + 20, 0.5, "test move")
			if success:
				test_label.text += "\n✅ Safe tween works!"
				# Move back
				DebugManager.safe_tween_property(tween, test_label, "position:x", original_pos.x, 0.5, "test move back")
			else:
				test_label.text += "\n❌ Safe tween property failed!"
		else:
			test_label.text += "\n❌ Safe tween creation failed!"
	else:
		test_label.text += "\n❌ DebugManager not available for tween test!"

func test_all_systems():
	"""Test all available systems"""
	print("CrashTestScene: Testing all systems...")
	test_label.text += "\n\n🔍 SYSTEM HEALTH CHECK:"
	
	if DebugManager:
		var health_report = DebugManager.check_system_health()
		test_label.text += "\n📊 Overall Status: " + health_report.overall_status
		
		# Check each autoload
		for autoload_name in health_report.autoloads:
			var is_valid = health_report.autoloads[autoload_name]
			var icon = "✅" if is_valid else "❌"
			test_label.text += "\n" + icon + " " + autoload_name
		
		# Audio system check
		var audio_debug = DebugManager.debug_audio_system()
		test_label.text += "\n🔊 Audio: " + audio_debug.get("status", "Unknown")
		
		# Save system check
		var save_debug = DebugManager.debug_save_system()
		var save_status = "Working" if save_debug.save_system_valid else "Failed"
		test_label.text += "\n💾 Save: " + save_status
		
		if health_report.overall_status == "HEALTHY":
			test_label.text += "\n\n✅ ALL SYSTEMS STABLE - Game should be safe to run!"
		else:
			test_label.text += "\n\n⚠️ Some systems need attention before full restore"
	else:
		test_label.text += "\n❌ DebugManager not available!"

func restore_main_menu():
	"""Restore the main menu as the main scene"""
	print("CrashTestScene: Restoring main menu...")
	test_label.text += "\n\n🔄 Switching to MainMenu..."
	
	# Use deferred to avoid immediate scene change issues
	call_deferred("_change_to_main_menu")

func _change_to_main_menu():
	"""Actually change to the main menu scene"""
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func test_room_scene():
	"""Test loading the room scene directly"""
	print("CrashTestScene: Testing room scene...")
	test_label.text += "\n\n🏠 Testing Room scene..."
	
	# Use deferred to avoid immediate scene change issues
	call_deferred("_change_to_room_scene")

func _change_to_room_scene():
	"""Actually change to the room scene"""
	get_tree().change_scene_to_file("res://scenes/rooms/Room.tscn")