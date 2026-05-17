extends GutTest

const GeneratedHandholdAdapterScript: GDScript = preload("res://src/gameplay/generation/generated_handhold_adapter.gd")
const HandholdTypeScript: GDScript = preload("res://src/gameplay/generation/handhold_type.gd")

func test_ghost_handhold_breaks_on_first_release() -> void:
	var handhold: GeneratedHandholdAdapter = GeneratedHandholdAdapterScript.new()
	handhold.configure_handhold(
		&"ghost_hold",
		&"GHOST",
		HandholdTypeScript.Value.GHOST,
		Vector2.ZERO,
		Vector2(18.0, 28.0),
		1.0,
		Color(0.73, 0.84, 0.95, 0.82),
		0.0,
		true,
		Vector2.ZERO
	)
	add_child_autofree(handhold)
	await get_tree().process_frame

	handhold.notify_hand_attached()
	var release_impulse: Vector2 = handhold.notify_hand_released()
	var collision_shape: CollisionShape2D = handhold.get_node("CollisionShape2D") as CollisionShape2D
	var visual: Polygon2D = handhold.get_node("Visual") as Polygon2D

	assert_true(release_impulse.is_equal_approx(Vector2.ZERO))
	assert_true(handhold.is_broken())
	assert_not_null(collision_shape)
	assert_not_null(visual)
	assert_true(collision_shape.disabled)
	assert_false(visual.visible)

func test_rocket_handhold_returns_stronger_release_impulse_without_breaking() -> void:
	var handhold: GeneratedHandholdAdapter = GeneratedHandholdAdapterScript.new()
	var expected_impulse: Vector2 = Vector2(0.0, -360.0)
	handhold.configure_handhold(
		&"rocket_hold",
		&"ROCKET",
		HandholdTypeScript.Value.ROCKET,
		Vector2.ZERO,
		Vector2(14.0, 28.0),
		1.1,
		Color(0.99, 0.48, 0.14, 1.0),
		0.0,
		false,
		expected_impulse
	)
	add_child_autofree(handhold)
	await get_tree().process_frame

	handhold.notify_hand_attached()
	var release_impulse: Vector2 = handhold.notify_hand_released()
	var collision_shape: CollisionShape2D = handhold.get_node("CollisionShape2D") as CollisionShape2D
	var visual: Polygon2D = handhold.get_node("Visual") as Polygon2D

	assert_true(release_impulse.is_equal_approx(expected_impulse))
	assert_false(handhold.is_broken())
	assert_not_null(collision_shape)
	assert_not_null(visual)
	assert_false(collision_shape.disabled)
	assert_true(visual.visible)
	assert_false(handhold.advance_attached_lifecycle(0.25))