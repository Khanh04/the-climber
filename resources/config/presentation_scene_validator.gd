class_name PresentationSceneValidator
extends RefCounted

static var _validated_scene_ids: Dictionary[int, bool] = {}

static func is_valid(presentation_scene: PackedScene) -> bool:
	if presentation_scene == null:
		return false
	if _validated_scene_ids.has(presentation_scene.get_instance_id()):
		return true

	var instance: Node = presentation_scene.instantiate()
	var valid: bool = is_node_tree_valid(instance)
	instance.free()
	if valid:
		_validated_scene_ids[presentation_scene.get_instance_id()] = true
	return valid

static func assert_valid(presentation_scene: PackedScene, owner_label: String) -> void:
	Validation.require_condition(presentation_scene != null, "%s requires a presentation scene." % owner_label)
	if _validated_scene_ids.has(presentation_scene.get_instance_id()):
		return

	var instance: Node = presentation_scene.instantiate()
	Validation.require_condition(instance is Node2D, "%s presentation scene root must be Node2D." % owner_label)
	Validation.require_condition(
		is_node_tree_valid(instance),
		"%s presentation scene cannot contain collision objects, collision shapes, or joints." % owner_label
	)
	instance.free()
	_validated_scene_ids[presentation_scene.get_instance_id()] = true

static func assert_live_tree_valid(instance: Node, owner_label: String) -> void:
	Validation.require_condition(instance is Node2D, "%s live presentation root must remain Node2D." % owner_label)
	Validation.require_condition(
		is_node_tree_valid(instance),
		"%s live presentation cannot contain collision objects, collision shapes, or joints." % owner_label
	)

static func is_node_tree_valid(node: Node) -> bool:
	return node is Node2D and not _contains_physics_node(node)

static func _contains_physics_node(node: Node) -> bool:
	if node is CollisionObject2D \
		or node is CollisionShape2D \
		or node is CollisionPolygon2D \
		or node is Joint2D \
		or node is CollisionObject3D \
		or node is CollisionShape3D \
		or node is Joint3D:
		return true

	for child in node.get_children():
		if _contains_physics_node(child):
			return true

	return false
