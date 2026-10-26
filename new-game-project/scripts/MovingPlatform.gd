extends AnimatableBody2D

var axis: Vector2 = Vector2.RIGHT
var amplitude: float = 180.0
var speed: float = 1.2
var base_position: Vector2 = Vector2.ZERO
var platform_size: Vector2 = Vector2(220, 18)

func _ready() -> void:
    if has_node("CollisionShape2D"):
        var collision = $CollisionShape2D as CollisionShape2D
        if collision.shape is RectangleShape2D:
            collision.shape.size = platform_size
    if has_node("Visual"):
        var visual = $Visual as Polygon2D
        visual.polygon = _make_rect_points(platform_size)

func configure(size_value: Vector2, color_value: Color, move_axis: Vector2, move_amplitude: float, move_speed: float) -> void:
    platform_size = size_value
    axis = move_axis.normalized()
    amplitude = move_amplitude
    speed = move_speed
    base_position = position
    if has_node("CollisionShape2D"):
        var collision = $CollisionShape2D as CollisionShape2D
        if collision.shape is RectangleShape2D:
            collision.shape.size = size_value
    if has_node("Visual"):
        var visual = $Visual as Polygon2D
        visual.color = color_value
        visual.polygon = _make_rect_points(size_value)

func _physics_process(delta: float) -> void:
    var t = Time.get_ticks_msec() * 0.001 * speed
    position = base_position + axis * sin(t) * amplitude

func _make_rect_points(size_value: Vector2) -> PackedVector2Array:
    var half_x = size_value.x * 0.5
    var half_y = size_value.y * 0.5
    return PackedVector2Array([
        Vector2(-half_x, -half_y),
        Vector2(half_x, -half_y),
        Vector2(half_x, half_y),
        Vector2(-half_x, half_y)
    ])
