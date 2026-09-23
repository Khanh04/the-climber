class_name GeneratedCoinPickupSpawnAdapter
extends Area2D

signal collected(socket_id: StringName, coin_amount: int, body: Node)

const GROUP_NAME: StringName = &"generated_coin_pickup"

var socket_id: StringName = StringName()
var coin_amount: int = 1

var _collision_radius_pixels: float = 18.0
var _is_collected: bool = false

func configure(
	socket_id_value: StringName,
	local_position_pixels_value: Vector2,
	coin_amount_value: int = 1,
	collision_radius_pixels_value: float = 18.0,
	collision_layer_value: int = 8,
	collision_mask_value: int = 1
) -> void:
	Validation.require_condition(not String(socket_id_value).is_empty(), "GeneratedCoinPickupSpawnAdapter requires a socket id.")
	Validation.require_condition(coin_amount_value > 0, "GeneratedCoinPickupSpawnAdapter coin amount must be positive.")
	Validation.require_condition(collision_radius_pixels_value > 0.0, "GeneratedCoinPickupSpawnAdapter collision radius must be positive.")
	Validation.require_condition(collision_layer_value > 0, "GeneratedCoinPickupSpawnAdapter collision layer must be positive.")
	Validation.require_condition(collision_mask_value > 0, "GeneratedCoinPickupSpawnAdapter collision mask must be positive.")

	socket_id = socket_id_value
	coin_amount = coin_amount_value
	position = local_position_pixels_value
	_collision_radius_pixels = collision_radius_pixels_value
	collision_layer = collision_layer_value
	collision_mask = collision_mask_value
	monitoring = true
	monitorable = true
	add_to_group(GROUP_NAME)
	set_meta(&"socket_kind", &"pickup")
	set_meta(&"coin_amount", coin_amount)
	_ensure_presentation()

func _ready() -> void:
	_validate_required_state()
	if not body_entered.is_connected(_on_body_entered):
		var _connect_result: int = body_entered.connect(_on_body_entered)

func _validate_required_state() -> void:
	Validation.require_condition(not String(socket_id).is_empty(), "GeneratedCoinPickupSpawnAdapter must be configured before entering the scene tree.")
	Validation.require_condition(coin_amount > 0, "GeneratedCoinPickupSpawnAdapter coin amount must remain positive.")
	Validation.require_condition(_collision_radius_pixels > 0.0, "GeneratedCoinPickupSpawnAdapter collision radius must remain positive.")
	Validation.require_condition(get_node_or_null("CollisionShape2D") is CollisionShape2D, "GeneratedCoinPickupSpawnAdapter requires CollisionShape2D.")
	Validation.require_condition(get_node_or_null("Visual") is Polygon2D, "GeneratedCoinPickupSpawnAdapter requires Visual.")

func _ensure_presentation() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		collision_shape.name = &"CollisionShape2D"
		add_child(collision_shape)

	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = _collision_radius_pixels
	collision_shape.shape = circle_shape

	var visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
	if visual == null:
		visual = Polygon2D.new()
		visual.name = &"Visual"
		add_child(visual)

	visual.color = Color(0.96, 0.85, 0.24, 0.95)
	visual.polygon = PackedVector2Array([
		Vector2(0.0, -16.0),
		Vector2(14.0, 0.0),
		Vector2(0.0, 16.0),
		Vector2(-14.0, 0.0),
	])

func _on_body_entered(body: Node) -> void:
	Validation.require_condition(body != null, "GeneratedCoinPickupSpawnAdapter body_entered requires a body.")
	if _is_collected:
		return

	_is_collected = true
	set_deferred(&"monitoring", false)
	collected.emit(socket_id, coin_amount, body)
	queue_free()
