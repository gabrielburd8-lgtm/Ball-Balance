extends RigidBody2D

var box_size: Vector2 = Vector2(90, 90)
var box_color: Color = Color(0.6, 0.8, 0.9)
var box_weight: float = 1.0

func _ready() -> void:
    set_meta("box", true)
    _apply_visual()

func configure(new_size: Vector2, new_color: Color, weight_value: float) -> void:
    box_size = new_size
    box_color = new_color
    box_weight = weight_value
    mass = weight_value
    if has_node("CollisionShape2D"):
        var collision = $CollisionShape2D
        if collision.shape is RectangleShape2D:
            collision.shape.size = new_size
    _apply_visual()

func _apply_visual() -> void:
    if has_node("Visual"):
        var visual = $Visual as Polygon2D
        visual.color = box_color
        visual.polygon = _make_square_points(box_size)

    if has_node("CollisionShape2D"):
        var collision = $CollisionShape2D as CollisionShape2D
        if collision.shape is RectangleShape2D:
            collision.shape.size = box_size

func _make_square_points(size_value: Vector2) -> PackedVector2Array:
    var half_x = size_value.x * 0.5
    var half_y = size_value.y * 0.5
    return PackedVector2Array([
        Vector2(-half_x, -half_y),
        Vector2(half_x, -half_y),
        Vector2(half_x, half_y),
        Vector2(-half_x, half_y)
    ])
