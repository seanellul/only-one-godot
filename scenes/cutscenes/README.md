# Cutscene System

## Overview
A flexible cutscene system for displaying narrative sequences with background colors/images, text overlays, fade transitions, and parallax effects.

## Components

### CutsceneManager.gd
Core cutscene engine that handles:
- Scene sequencing and transitions
- Text display with rich text formatting
- Background management (colors + optional textures)
- Fade effects and parallax movement
- Input handling (click/space/enter to advance)
- Skip functionality

### CutsceneScene Class
Data structure for individual cutscene scenes with multi-layer parallax:
```gdscript
CutsceneScene.new(
    background_color: Color,    # Background color
    text: String,               # Rich text content
    text_color: Color,          # Text color (default: white)
    fade_duration: float,       # Fade transition time (default: 1.0)
    parallax_speeds: Vector3    # Layer movement speeds (default: Vector3(0.3, 0.6, 1.0))
).set_textures(
    background_texture,         # Far background layer (optional)
    midground_texture,          # Middle layer (optional)
    foreground_texture          # Close effects layer (optional)
)
```

### IntroductionCutscene.gd/.tscn
Epic 6-scene intro narrative about:
1. World chaos from interdimensional portals
2. Society's collapse and loss of hope
3. Ancient prophecy discovered in Bubakra
4. Player's mysterious awakening with amnesia
5. Player matches the prophecy (unknown to them)
6. Player is the only one who can save both worlds

## Game Flow Integration

**Main Menu → New Game → Intro Cutscene → Game**

1. Player clicks "New Game" in MainMenu
2. GameManager triggers IntroductionCutscene
3. Cutscene plays automatically on scene load
4. When finished, GameManager loads the actual game scene

## Features

### Visual Effects
- **Fade Transitions**: Smooth black fade between scenes
- **Multi-Layer Parallax**: 3 independent layers moving at different speeds
  - Background Layer (slowest) - Landscapes, architecture
  - Midground Layer (medium) - Objects, characters, structures  
  - Foreground Layer (fastest) - Particles, effects, atmosphere
- **Rich Text**: Bold, colors, formatting support
- **Responsive Timing**: Different fade durations per scene
- **Atmospheric Depth**: Layered opacity creates visual depth

### User Interaction
- **Click to Advance**: Left mouse button advances scenes
- **Keyboard Support**: Space/Enter also advance
- **Visual Prompts**: "Click to continue..." with pulsing effect
- **Skip Option**: Can skip entire cutscene (via skip_cutscene())

### Technical
- **Signal-based**: Clean communication between components
- **Modular Design**: Easy to create new cutscenes
- **Memory Safe**: Proper cleanup and node management
- **Debug Logging**: Comprehensive console output

## Creating New Cutscenes

1. Create new script extending Node
2. Instantiate CutsceneManager
3. Create array of CutsceneScene objects
4. Call `cutscene_manager.play_cutscene(scenes)`
5. Connect to `cutscene_finished` signal

## Usage Example
```gdscript
var scenes = []

# Create scene with multi-layer parallax
var epic_scene = CutsceneScene.new(
    Color.RED,                          # Background color
    "[b]Epic Story Text[/b]",           # Rich text content
    Color.WHITE,                        # Text color
    1.5,                                # Fade duration
    Vector3(0.3, 0.6, 1.0)             # Parallax speeds (bg, mid, fg)
).set_textures(
    preload("res://art/bg.png"),        # Background texture
    preload("res://art/mid.png"),       # Midground texture  
    preload("res://art/fg.png")         # Foreground texture
)

scenes.append(epic_scene)
cutscene_manager.play_cutscene(scenes)
``` 