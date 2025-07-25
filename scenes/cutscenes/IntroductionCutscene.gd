extends Node

# Reference to cutscene manager
var cutscene_manager: Control

# Signals
signal intro_finished()

func _ready():
	# Create cutscene manager
	cutscene_manager = preload("res://scenes/cutscenes/CutsceneManager.gd").new()
	add_child(cutscene_manager)
	
	# Connect signals
	cutscene_manager.cutscene_finished.connect(_on_cutscene_finished)
	
	# Start the intro automatically
	call_deferred("start_intro")

func start_intro():
	"""Start the introduction cutscene"""
	print("IntroductionCutscene: Starting epic intro...")
	
	var intro_scenes = create_intro_scenes()
	cutscene_manager.play_cutscene(intro_scenes)

func create_intro_scenes() -> Array:
	"""Create the 6 scenes of the introduction"""
	var CutsceneScene = cutscene_manager.CutsceneScene
	var scenes = []
	
	# Scene 1: The World in Chaos (Single full image for comparison)
	var scene1 = CutsceneScene.new(
		Color(0.8, 0.2, 0.2, 1.0), # Dark red - chaos and danger
		"[b]The world as we knew it... is no more.[/b]\n\nPortals have been torn into the fabric of reality itself, merging our peaceful realm with a dimension of unimaginable darkness and peril.\n\nWhispers of shadow seep through the cracks between worlds...",
		Color(1.0, 0.9, 0.8, 1.0), # Warm white text
		1.5, # Longer fade for dramatic effect
		Vector3(0.2, 0.4, 0.8) # Slow background, medium mid, fast foreground
	)
	# Load single full image as background only
	scene1.set_textures(
		preload("res://scenes/cutscenes/images/scene_1_full.png"), # Background
		null, # No midground
		null # No foreground
	)
	scenes.append(scene1)
	
	# Scene 2: Society's Collapse (FULL 3-LAYER PARALLAX - Your masterpiece!)
	var scene2 = CutsceneScene.new(
		Color(0.15, 0.15, 0.25, 1.0), # Dark blue-gray - despair
		"[b]Hope has abandoned us.[/b]\n\nGreat cities lie in ruins. Kingdoms have crumbled to dust. The people cower in fear as creatures from the void roam freely through once-sacred lands.\n\nChaos reigns supreme, and order seems but a distant memory...",
		Color(0.9, 0.9, 1.0, 1.0), # Cool white text
		1.3,
		Vector3(0.3, 0.5, 0.9) # Ruined cityscape, fallen statues, ash particles
	)
	# Load your beautiful 3-layer parallax artwork!
	scene2.set_textures(
		preload("res://scenes/cutscenes/images/scene_2_background.png"), # Background layer
		preload("res://scenes/cutscenes/images/scene_2_midground.png"), # Midground layer
		preload("res://scenes/cutscenes/images/scene_2_foreground.png") # Foreground layer
	)
	scenes.append(scene2)
	
	# Scene 3: The Ancient Prophecy (Single full image for comparison)
	var scene3 = CutsceneScene.new(
		Color(0.4, 0.3, 0.6, 1.0), # Deep purple - mystical/ancient
		"[b]But in the darkest hour, ancient words surfaced...[/b]\n\n\"When the worlds collide and hope seems lost, in the heart of the smallest sanctuary shall emerge the key to restoration.\"\n\nThe tiny town of [b]Bubakra[/b] - overlooked, forgotten, yet somehow... significant.",
		Color(1.0, 1.0, 0.8, 1.0), # Golden text - prophecy
		1.4,
		Vector3(0.4, 0.7, 1.2) # Ancient temple, floating runes, magical light rays
	)
	# Load single full image as background only
	scene3.set_textures(
		preload("res://scenes/cutscenes/images/scene_3_full.png"), # Background
		null, # No midground
		null # No foreground
	)
	scenes.append(scene3)
	
	# Scene 4: Your Mysterious Arrival (Single full image for comparison)
	var scene4 = CutsceneScene.new(
		Color(0.2, 0.4, 0.3, 1.0), # Dark green - mystery/forest
		"[b]You awaken in the town square...[/b]\n\nNo memory of how you arrived. No recollection of who you were. The cobblestones beneath you are cold, the air thick with an otherworldly energy.\n\nThe townspeople whisper among themselves, their eyes filled with a mixture of fear and... hope?",
		Color(0.9, 1.0, 0.9, 1.0), # Pale green text
		1.2,
		Vector3(0.3, 0.6, 1.0) # Town square, watching silhouettes, swirling mist
	)
	# Load single full image as background only
	scene4.set_textures(
		preload("res://scenes/cutscenes/images/scene_4_full.png"), # Background
		null, # No midground
		null # No foreground
	)
	scenes.append(scene4)
	
	# Scene 5: The Hidden Truth (Single full image for comparison)
	var scene5 = CutsceneScene.new(
		Color(0.6, 0.4, 0.1, 1.0), # Golden brown - revelation
		"[b]Unbeknownst to you...[/b]\n\nEvery detail of your being matches the ancient prophecy perfectly. The mark upon your hand, the way the shadows recoil from your presence, the strange calm that settles over the chaos when you near...\n\nYou are the foretold one.",
		Color(1.0, 0.95, 0.7, 1.0), # Warm golden text
		1.3,
		Vector3(0.5, 0.8, 1.3) # Prophecy scroll close-up, glowing symbols, divine light
	)
	# Load single full image as background only
	scene5.set_textures(
		preload("res://scenes/cutscenes/images/scene_5_full.png"), # Background
		null, # No midground
		null # No foreground
	)
	scenes.append(scene5)
	
	# Scene 6: The Ultimate Destiny (Single full image for comparison)
	var scene6 = CutsceneScene.new(
		Color(0.1, 0.1, 0.4, 1.0), # Deep midnight blue - destiny
		"[b]Unbeknownst to you...[/b]\n\nThe fate of both worlds rests upon your shoulders alone. Every choice you make, every step you take, every battle you fight will determine whether reality itself survives or falls to eternal darkness.\n\n[b]You are the only one.[/b]",
		Color(0.8, 0.9, 1.0, 1.0), # Ethereal blue-white text
		2.0, # Longest fade for epic conclusion
		Vector3(0.6, 1.0, 1.5) # Cosmic void, heroic silhouette, flowing stellar energy
	)
	# Load single full image as background only
	scene6.set_textures(
		preload("res://scenes/cutscenes/images/scene_6_full.png"), # Background
		null, # No midground
		null # No foreground
	)
	scenes.append(scene6)
	
	print("IntroductionCutscene: Created ", scenes.size(), " epic scenes")
	return scenes

func _on_cutscene_finished():
	"""Handle cutscene completion"""
	print("IntroductionCutscene: Epic intro completed!")
	intro_finished.emit()

func skip_intro():
	"""Skip the intro cutscene"""
	if cutscene_manager:
		cutscene_manager.skip_cutscene()
