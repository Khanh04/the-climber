extends AnimatedSprite2D
class_name CloudAnimation

@onready var _background: TextureRect = get_node("../../background_preview") as TextureRect
@onready var _cloud_container: Control = get_parent() as Control

func _ready() -> void:
	Validation.require_condition(_background != null, "CloudAnimation requires the menu background.")
	Validation.require_condition(_background.texture != null, "CloudAnimation requires a background texture.")
	Validation.require_condition(_cloud_container != null, "CloudAnimation requires a Control parent.")
	var _resize_connect_result: int = _background.resized.connect(_queue_alignment)
	_queue_alignment()
	play("cloud")

func _queue_alignment() -> void:
	# Wait until anchored parent controls have finished their layout update.
	_align_with_background.call_deferred()

func _align_with_background() -> void:
	var texture_size: Vector2 = _background.texture.get_size()
	var fit_scale: float = minf(_background.size.x / texture_size.x, _background.size.y / texture_size.y)
	var background_center: Vector2 = _background.get_global_transform() * (_background.size * 0.5)
	position = _cloud_container.get_global_transform().affine_inverse() * background_center
	scale = Vector2(fit_scale, fit_scale)
