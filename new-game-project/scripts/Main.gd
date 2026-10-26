extends Node

const BOX_SCENE = preload("res://scenes/Box.tscn")
const PLATFORM_SCENE = preload("res://scenes/Platform.tscn")
const MOVING_PLATFORM_SCENE = preload("res://scenes/MovingPlatform.tscn")

const LEVELS = [
    {
        "name": "Level 1: Warm Up",
        "target_height": 140.0,
        "box_sizes": [Vector2(90, 90), Vector2(70, 70), Vector2(90, 90), Vector2(80, 80)],
        "platforms": [
            {"position": Vector2(640, 680), "size": Vector2(1280, 70), "color": Color(0.26, 0.42, 0.56), "moving": false},
            {"position": Vector2(640, 610), "size": Vector2(300, 22), "color": Color(0.31, 0.68, 0.62), "moving": false}
        ],
        "moving_platforms": [],
        "wind_strength": 0.0,
        "spawn_x": 640.0,
        "spawn_y": 120.0
    },
    {
        "name": "Level 2: Mixed Loads",
        "target_height": 220.0,
        "box_sizes": [Vector2(96, 96), Vector2(120, 70), Vector2(80, 110), Vector2(70, 70), Vector2(90, 90)],
        "platforms": [
            {"position": Vector2(640, 680), "size": Vector2(1280, 70), "color": Color(0.29, 0.46, 0.62), "moving": false},
            {"position": Vector2(640, 610), "size": Vector2(360, 22), "color": Color(0.72, 0.54, 0.35), "moving": false}
        ],
        "moving_platforms": [],
        "wind_strength": 0.0,
        "spawn_x": 640.0,
        "spawn_y": 110.0
    },
    {
        "name": "Level 3: Narrow Deck",
        "target_height": 260.0,
        "box_sizes": [Vector2(90, 90), Vector2(68, 68), Vector2(92, 92), Vector2(80, 80), Vector2(90, 90), Vector2(70, 70)],
        "platforms": [
            {"position": Vector2(640, 680), "size": Vector2(1280, 70), "color": Color(0.29, 0.40, 0.58), "moving": false},
            {"position": Vector2(640, 620), "size": Vector2(210, 22), "color": Color(0.28, 0.72, 0.73), "moving": false}
        ],
        "moving_platforms": [],
        "wind_strength": 0.0,
        "spawn_x": 640.0,
        "spawn_y": 100.0
    },
    {
        "name": "Level 4: Moving Platform",
        "target_height": 300.0,
        "box_sizes": [Vector2(100, 100), Vector2(82, 82), Vector2(68, 68), Vector2(110, 80), Vector2(90, 90), Vector2(70, 70)],
        "platforms": [
            {"position": Vector2(640, 680), "size": Vector2(1280, 70), "color": Color(0.27, 0.39, 0.61), "moving": false},
            {"position": Vector2(500, 600), "size": Vector2(260, 22), "color": Color(0.69, 0.62, 0.90), "moving": false}
        ],
        "moving_platforms": [
            {"position": Vector2(760, 520), "size": Vector2(260, 18), "axis": Vector2(1, 0), "amplitude": 185.0, "speed": 1.25, "color": Color(0.67, 0.83, 0.97)}
        ],
        "wind_strength": 0.0,
        "spawn_x": 640.0,
        "spawn_y": 90.0
    },
    {
        "name": "Level 5: Wind Storm",
        "target_height": 360.0,
        "box_sizes": [Vector2(110, 110), Vector2(92, 92), Vector2(74, 74), Vector2(88, 88), Vector2(110, 80), Vector2(78, 78), Vector2(76, 98)],
        "platforms": [
            {"position": Vector2(640, 680), "size": Vector2(1280, 70), "color": Color(0.25, 0.37, 0.58), "moving": false},
            {"position": Vector2(640, 598), "size": Vector2(300, 22), "color": Color(0.86, 0.57, 0.41), "moving": false}
        ],
        "moving_platforms": [],
        "wind_strength": 120.0,
        "spawn_x": 640.0,
        "spawn_y": 85.0
    }
]

var world: Node2D
var ui_layer: CanvasLayer
var hud_panel: PanelContainer
var status_label: Label
var stability_label: Label
var height_label: Label
var score_label: Label
var level_label: Label

var main_menu_panel: PanelContainer
var how_to_play_panel: PanelContainer
var pause_panel: PanelContainer
var level_complete_panel: PanelContainer
var game_over_panel: PanelContainer
var final_victory_panel: PanelContainer

var score: int = 0
var current_level_index: int = 0
var current_level_data: Dictionary = {}
var current_target_height: float = 0.0
var tower_height: float = 0.0
var active_box: RigidBody2D = null
var box_counter: int = 0
var held_box_size_index: int = 0
var level_active: bool = false
var paused: bool = false
var world_ready: bool = false

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color(0.08, 0.14, 0.24))
    _register_input_actions()
    _setup_ui()
    _show_main_menu()

func _register_input_actions() -> void:
    var actions = ["move_left", "move_right", "drop_box", "restart_level", "pause_game"]
    for action_name in actions:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)

    var left_events = [KEY_A, KEY_LEFT]
    for key in left_events:
        var event = InputEventKey.new()
        event.physical_keycode = key
        InputMap.action_add_event("move_left", event)

    var right_events = [KEY_D, KEY_RIGHT]
    for key in right_events:
        var event = InputEventKey.new()
        event.physical_keycode = key
        InputMap.action_add_event("move_right", event)

    var drop_event = InputEventKey.new()
    drop_event.physical_keycode = KEY_SPACE
    InputMap.action_add_event("drop_box", drop_event)

    var restart_event = InputEventKey.new()
    restart_event.physical_keycode = KEY_R
    InputMap.action_add_event("restart_level", restart_event)

    var pause_event = InputEventKey.new()
    pause_event.physical_keycode = KEY_ESCAPE
    InputMap.action_add_event("pause_game", pause_event)

func _setup_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)

    var root = MarginContainer.new()
    root.name = "RootMargin"
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.anchor_right = 1.0
    root.anchor_bottom = 1.0
    root.offset_right = 0
    root.offset_bottom = 0
    ui_layer.add_child(root)

    hud_panel = PanelContainer.new()
    hud_panel.name = "HUD"
    hud_panel.visible = false
    root.add_child(hud_panel)

    var hud_vbox = VBoxContainer.new()
    hud_panel.add_child(hud_vbox)

    level_label = Label.new()
    level_label.add_theme_font_size_override("font_size", 22)
    level_label.text = "Level 1/5"
    hud_vbox.add_child(level_label)

    height_label = Label.new()
    height_label.add_theme_font_size_override("font_size", 20)
    height_label.text = "Tower Height: 0.0 / 0.0"
    hud_vbox.add_child(height_label)

    stability_label = Label.new()
    stability_label.add_theme_font_size_override("font_size", 18)
    stability_label.text = "Stable: --"
    hud_vbox.add_child(stability_label)

    score_label = Label.new()
    score_label.add_theme_font_size_override("font_size", 18)
    score_label.text = "Score: 0"
    hud_vbox.add_child(score_label)

    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.text = ""
    hud_vbox.add_child(status_label)

    main_menu_panel = _build_menu_panel("Box Balance", [
        {"text": "Play", "callback": _play_game},
        {"text": "How to Play", "callback": _show_how_to_play},
        {"text": "Quit", "callback": _quit_game}
    ])
    root.add_child(main_menu_panel)

    how_to_play_panel = _build_menu_panel("How to Play", [
        {"text": "Back", "callback": _show_main_menu}
    ])
    how_to_play_panel.visible = false
    root.add_child(how_to_play_panel)

    pause_panel = _build_menu_panel("Paused", [
        {"text": "Resume", "callback": _resume_game},
        {"text": "Restart", "callback": _restart_level},
        {"text": "Main Menu", "callback": _return_to_main_menu}
    ])
    pause_panel.visible = false
    root.add_child(pause_panel)

    level_complete_panel = _build_menu_panel("Level Complete!", [
        {"text": "Next Level", "callback": _next_level}
    ])
    level_complete_panel.visible = false
    root.add_child(level_complete_panel)

    game_over_panel = _build_menu_panel("Tower Fell!", [
        {"text": "Retry", "callback": _restart_level},
        {"text": "Main Menu", "callback": _return_to_main_menu}
    ])
    game_over_panel.visible = false
    root.add_child(game_over_panel)

    final_victory_panel = _build_menu_panel("You Won!", [
        {"text": "Play Again", "callback": _play_game},
        {"text": "Main Menu", "callback": _return_to_main_menu}
    ])
    final_victory_panel.visible = false
    root.add_child(final_victory_panel)

func _build_menu_panel(title: String, buttons_data: Array) -> PanelContainer:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -250
    panel.offset_top = -150
    panel.offset_right = 250
    panel.offset_bottom = 150

    var vbox = VBoxContainer.new()
    panel.add_child(vbox)

    var title_label = Label.new()
    title_label.text = title
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 32)
    vbox.add_child(title_label)

    var description = RichTextLabel.new()
    description.fit_content = true
    description.scroll_active = false
    description.bbcode_enabled = true
    description.text = ""
    if title == "How to Play":
        description.text = "[center]A/D or Left/Right to move the box.[/center]\n[center]Space to drop.[/center]\n[center]R to restart.[/center]\n[center]Esc to pause.[/center]\n[center]Stack the tower high enough to reach the target height and stay stable.[/center]"
    elif title == "Box Balance":
        description.text = "[center]Build a tower of boxes without letting it fall.[/center]"
    elif title == "Level Complete!":
        description.text = "[center]The tower is stable and the target was reached.[/center]"
    elif title == "Tower Fell!":
        description.text = "[center]Your tower collapsed. Try a different stack.[/center]"
    elif title == "You Won!":
        description.text = "[center]All five levels complete.[/center]"
    vbox.add_child(description)

    for button_data in buttons_data:
        var button = Button.new()
        button.text = button_data["text"]
        button.custom_minimum_size = Vector2(220, 48)
        button.pressed.connect(button_data["callback"])
        vbox.add_child(button)

    return panel

func _play_game() -> void:
    score = 0
    current_level_index = 0
    _load_level(current_level_index)
    _hide_all_menus()
    hud_panel.visible = true
    level_active = true
    paused = false
    get_tree().paused = false

func _show_main_menu() -> void:
    _hide_all_menus()
    main_menu_panel.visible = true
    hud_panel.visible = false
    level_active = false
    paused = false
    get_tree().paused = false
    if is_instance_valid(world):
        world.visible = false

func _show_how_to_play() -> void:
    _hide_all_menus()
    how_to_play_panel.visible = true

func _hide_all_menus() -> void:
    main_menu_panel.visible = false
    how_to_play_panel.visible = false
    pause_panel.visible = false
    level_complete_panel.visible = false
    game_over_panel.visible = false
    final_victory_panel.visible = false

func _quit_game() -> void:
    get_tree().quit()

func _load_level(level_number: int) -> void:
    current_level_index = level_number
    current_level_data = LEVELS[level_number]
    current_target_height = float(current_level_data["target_height"])
    tower_height = 0.0
    active_box = null
    box_counter = 0
    held_box_size_index = 0
    paused = false
    get_tree().paused = false

    if is_instance_valid(world):
        world.queue_free()

    world = Node2D.new()
    world.name = "GameWorld"
    add_child(world)
    world_ready = true

    for platform_data in current_level_data["platforms"]:
        _create_platform(platform_data["position"], platform_data["size"], platform_data["color"], false)

    for moving_data in current_level_data["moving_platforms"]:
        var moving_platform = MOVING_PLATFORM_SCENE.instantiate()
        moving_platform.position = moving_data["position"]
        moving_platform.configure(moving_data["size"], moving_data["color"], moving_data["axis"], moving_data["amplitude"], moving_data["speed"])
        world.add_child(moving_platform)

    _spawn_hold_box()
    _update_hud()

func _create_platform(position: Vector2, size: Vector2, color: Color, is_moving: bool) -> void:
    var platform = PLATFORM_SCENE.instantiate()
    platform.position = position
    platform.get_node("CollisionShape2D").shape.size = size
    platform.get_node("Visual").color = color
    platform.get_node("Visual").polygon = PackedVector2Array([
        Vector2(-size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, -size.y * 0.5),
        Vector2(size.x * 0.5, size.y * 0.5),
        Vector2(-size.x * 0.5, size.y * 0.5)
    ])
    world.add_child(platform)

func _spawn_hold_box() -> void:
    if current_level_data.is_empty():
        return

    var box = BOX_SCENE.instantiate()
    var size = current_level_data["box_sizes"][min(held_box_size_index, current_level_data["box_sizes"].size() - 1)]
    var mass_value = 1.0 + (size.x * 0.012)
    var color = Color.from_hsv((float(box_counter) * 0.13) + 0.52, 0.75, 0.9)
    box.configure(size, color, mass_value)
    box.position = Vector2(current_level_data["spawn_x"], current_level_data["spawn_y"])
    box.mode = RigidBody2D.MODE_KINEMATIC
    box.freeze = true
    box.set_meta("is_hold_box", true)
    box.set_meta("size_value", size)
    box.name = "HeldBox%s" % box_counter
    world.add_child(box)
    active_box = box
    box_counter += 1
    held_box_size_index = (held_box_size_index + 1) % max(1, current_level_data["box_sizes"].size())

func _process(delta: float) -> void:
    if not level_active or paused:
        return

    if is_instance_valid(active_box):
        var input_dir = Input.get_axis("move_left", "move_right")
        active_box.position.x += input_dir * 420.0 * delta
        active_box.position.x = clamp(active_box.position.x, 140.0, 1140.0)
        active_box.position.y = current_level_data["spawn_y"]
        active_box.rotation = 0.0
        active_box.linear_velocity = Vector2.ZERO
        active_box.angular_velocity = 0.0
        active_box.mode = RigidBody2D.MODE_KINEMATIC
        active_box.freeze = true

    var boxes = get_tree().get_nodes_in_group("boxes")
    if boxes.is_empty():
        tower_height = 0.0
    else:
        var highest_top = 10000.0
        var total_speed = 0.0
        var count = 0
        for box in boxes:
            if not box is RigidBody2D:
                continue
            var body: RigidBody2D = box
            if body.has_meta("size_value"):
                var half = max(float(body.get_meta("size_value").x), float(body.get_meta("size_value").y)) * 0.5
                var top = body.global_position.y - half
                if top < highest_top:
                    highest_top = top
            total_speed += body.linear_velocity.length()
            count += 1
        if count > 0:
            tower_height = max(0.0, 645.0 - highest_top)
            var average_speed = total_speed / float(count)
            var stable = average_speed < 25.0
            stability_label.text = "Stable: %s" % ["Yes" if stable else "No"]
        else:
            tower_height = 0.0

    _update_hud()
    _check_level_success()
    _check_level_failure()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("drop_box") and level_active and not paused:
        _drop_active_box()
    elif event.is_action_pressed("restart_level") and level_active:
        _restart_level()
    elif event.is_action_pressed("pause_game") and level_active:
        _toggle_pause()

func _drop_active_box() -> void:
    if active_box == null:
        return

    active_box.mode = RigidBody2D.MODE_RIGID
    active_box.freeze = false
    active_box.linear_velocity = Vector2.ZERO
    active_box.angular_velocity = 0.0
    active_box.position.y += 2.0
    active_box.add_to_group("boxes")
    active_box.remove_meta("is_hold_box")
    active_box = null
    _play_sound("drop")
    _spawn_hold_box()

func _check_level_success() -> void:
    if not level_active:
        return

    var boxes = get_tree().get_nodes_in_group("boxes")
    if boxes.is_empty():
        return

    var stability_ok = false
    var total_speed = 0.0
    var count = 0
    for box in boxes:
        if not box is RigidBody2D:
            continue
        var body: RigidBody2D = box
        total_speed += body.linear_velocity.length()
        count += 1
    if count > 0:
        stability_ok = (total_speed / float(count)) < 15.0

    if tower_height >= current_target_height and stability_ok:
        _complete_level()

func _check_level_failure() -> void:
    if not level_active:
        return

    var boxes = get_tree().get_nodes_in_group("boxes")
    for box in boxes:
        if not box is RigidBody2D:
            continue
        var body: RigidBody2D = box
        if body.global_position.y > 760.0 and body.linear_velocity.length() > 120.0:
            _trigger_game_over()
            return

func _complete_level() -> void:
    level_active = false
    paused = false
    get_tree().paused = false
    var reward = int(current_target_height + tower_height * 1.5)
    score += reward
    _play_sound("success")
    _update_hud()

    if current_level_index >= LEVELS.size() - 1:
        final_victory_panel.visible = true
        hud_panel.visible = false
        return

    level_complete_panel.visible = true
    hud_panel.visible = false

func _next_level() -> void:
    level_complete_panel.visible = false
    if current_level_index < LEVELS.size() - 1:
        _load_level(current_level_index + 1)
        level_active = true
        hud_panel.visible = true
    else:
        _return_to_main_menu()

func _trigger_game_over() -> void:
    level_active = false
    paused = false
    get_tree().paused = false
    _play_sound("fail")
    game_over_panel.visible = true
    hud_panel.visible = false

func _restart_level() -> void:
    game_over_panel.visible = false
    level_complete_panel.visible = false
    pause_panel.visible = false
    get_tree().paused = false
    _load_level(current_level_index)
    level_active = true
    hud_panel.visible = true
    paused = false

func _toggle_pause() -> void:
    if not level_active:
        return
    paused = not paused
    get_tree().paused = paused
    pause_panel.visible = paused
    if paused:
        hud_panel.visible = false
    else:
        hud_panel.visible = true

func _resume_game() -> void:
    paused = false
    get_tree().paused = false
    pause_panel.visible = false
    hud_panel.visible = true

func _return_to_main_menu() -> void:
    game_over_panel.visible = false
    final_victory_panel.visible = false
    level_complete_panel.visible = false
    pause_panel.visible = false
    get_tree().paused = false
    _show_main_menu()

func _update_hud() -> void:
    level_label.text = "Level %d / %d: %s" % [current_level_index + 1, LEVELS.size(), current_level_data.get("name", "")]
    height_label.text = "Tower Height: %.1f / %.1f" % [tower_height, current_target_height]
    score_label.text = "Score: %d" % score
    if level_active:
        stability_label.text = "Stable: %s" % ["Yes" if tower_height >= current_target_height else "No"]
    else:
        stability_label.text = "Stable: --"
    if current_level_data:
        status_label.text = "Target: %s" % [str(current_target_height)]

func _play_sound(effect_name: String) -> void:
    var sound = AudioStreamPlayer.new()
    add_child(sound)
    sound.stream = _build_tone_stream(effect_name)
    sound.finished.connect(sound.queue_free)
    sound.play()

func _build_tone_stream(effect_name: String) -> AudioStreamWAV:
    var stream = AudioStreamWAV.new()
    var sample_rate = 44100
    var duration = 0.09
    var frequency = 440.0
    var amplitude = 0.25

    if effect_name == "drop":
        frequency = 180.0
        duration = 0.05
    elif effect_name == "success":
        frequency = 660.0
        duration = 0.12
    elif effect_name == "fail":
        frequency = 130.0
        duration = 0.16
        amplitude = 0.35

    var frame_count = int(sample_rate * duration)
    var data = PackedByteArray()
    data.resize(frame_count * 2)

    for i in range(frame_count):
        var t = float(i) / float(sample_rate)
        var value = sin(TAU * frequency * t) * amplitude
        var sample = int(clamp(value, -1.0, 1.0) * 32767.0)
        data[i * 2] = sample & 0xFF
        data[i * 2 + 1] = (sample >> 8) & 0xFF

    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = data
    return stream

func _run_final_victory() -> void:
    final_victory_panel.visible = true
    hud_panel.visible = false

func _run_game_over() -> void:
    game_over_panel.visible = true
    hud_panel.visible = false

func _show_world() -> void:
    if is_instance_valid(world):
        world.visible = true

func _hide_world() -> void:
    if is_instance_valid(world):
        world.visible = false

func _restart_game() -> void:
    _return_to_main_menu()

func _on_next_level_pressed() -> void:
    _next_level()
