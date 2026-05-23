class_name PlayerAppearanceApplicator
extends RefCounted

const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const APPEARANCE_CUTOUT_NODE_NAME: StringName = &"AppearanceCutout"

class CutoutSource extends RefCounted:
	var frame_size: Vector2
	var used_rect: Rect2

	func _init(frame_size_value: Vector2, used_rect_value: Rect2) -> void:
		frame_size = frame_size_value
		used_rect = used_rect_value

func apply_appearance(player: Node, appearance: Resource) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player.")
	Validation.require_condition(player is PlayerCharacterScript, "PlayerAppearanceApplicator requires a PlayerCharacter implementation.")
	Validation.require_condition(appearance != null, "PlayerAppearanceApplicator requires a player appearance.")
	Validation.require_condition(appearance is PlayerAppearanceScript, "PlayerAppearanceApplicator requires a PlayerAppearance resource.")

	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	var typed_appearance: PlayerAppearanceScript = appearance as PlayerAppearanceScript
	typed_appearance.assert_valid()
	_clear_existing_appearance_visuals(typed_player)
	typed_player.get_player_visual().visible = false
	if not typed_appearance.rig_scene_path.is_empty():
		_apply_rigged_appearance(typed_player, typed_appearance)
		typed_player.assert_visual_roots_physics_neutral()
		return
	if not typed_appearance.atlas_texture_path.is_empty():
		_apply_cutout_appearance(typed_player, typed_appearance)
		typed_player.assert_visual_roots_physics_neutral()
		return

	_apply_part(typed_player.get_body_visual_sprite(), typed_appearance.body_texture_path, typed_appearance.body_offset, typed_appearance.body_scale)
	_apply_part(typed_player.get_face_overlay(), typed_appearance.face_texture_path, typed_appearance.face_offset, typed_appearance.face_scale)
	_apply_part(typed_player.get_left_upper_arm_visual(), typed_appearance.left_upper_arm_texture_path, typed_appearance.left_upper_arm_offset, typed_appearance.left_upper_arm_scale)
	_apply_part(typed_player.get_left_forearm_visual(), typed_appearance.left_forearm_texture_path, typed_appearance.left_forearm_offset, typed_appearance.left_forearm_scale)
	_apply_part(typed_player.get_left_hand_visual(), typed_appearance.left_hand_texture_path, typed_appearance.left_hand_offset, typed_appearance.left_hand_scale)
	_apply_part(typed_player.get_right_upper_arm_visual(), typed_appearance.right_upper_arm_texture_path, typed_appearance.right_upper_arm_offset, typed_appearance.right_upper_arm_scale)
	_apply_part(typed_player.get_right_forearm_visual(), typed_appearance.right_forearm_texture_path, typed_appearance.right_forearm_offset, typed_appearance.right_forearm_scale)
	_apply_part(typed_player.get_right_hand_visual(), typed_appearance.right_hand_texture_path, typed_appearance.right_hand_offset, typed_appearance.right_hand_scale)
	_apply_part(typed_player.get_lower_body_visual(), typed_appearance.lower_body_texture_path, typed_appearance.lower_body_offset, typed_appearance.lower_body_scale)
	_fit_body_collision_to_visible_body(typed_player)
	typed_player.assert_visual_roots_physics_neutral()

func _apply_rigged_appearance(player: PlayerCharacterScript, appearance: PlayerAppearanceScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player for rigged appearance application.")
	Validation.require_condition(appearance != null, "PlayerAppearanceApplicator requires an appearance for rigged appearance application.")
	var rig_scene_resource: Resource = load(appearance.rig_scene_path)
	Validation.require_condition(rig_scene_resource != null, "PlayerAppearanceApplicator failed to load rig scene at %s." % appearance.rig_scene_path)
	Validation.require_condition(rig_scene_resource is PackedScene, "PlayerAppearanceApplicator rig scene must be a PackedScene.")
	player.apply_runtime_appearance_rig(
		rig_scene_resource as PackedScene,
		appearance.rig_lower_body_bone_path,
		appearance.rig_left_upper_arm_bone_path,
		appearance.rig_left_forearm_bone_path,
		appearance.rig_left_hand_bone_path,
		appearance.rig_right_upper_arm_bone_path,
		appearance.rig_right_forearm_bone_path,
		appearance.rig_right_hand_bone_path
	)

	var body_source: CutoutSource = _load_cutout_source(appearance.body_texture_path)
	var face_source: CutoutSource = _load_cutout_source(appearance.face_texture_path)
	var lower_body_source: CutoutSource = _load_cutout_source(appearance.lower_body_texture_path)
	_fit_body_collision_to_cutout_bounds(player, body_source, face_source, lower_body_source, appearance)

func _clear_existing_appearance_visuals(player: PlayerCharacterScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player before clearing appearance visuals.")
	player.clear_runtime_appearance_rig()
	_clear_part_visual(player.get_body_visual_sprite())
	_clear_part_visual(player.get_face_overlay())
	_clear_part_visual(player.get_left_upper_arm_visual())
	_clear_part_visual(player.get_left_forearm_visual())
	_clear_part_visual(player.get_left_hand_visual())
	_clear_part_visual(player.get_right_upper_arm_visual())
	_clear_part_visual(player.get_right_forearm_visual())
	_clear_part_visual(player.get_right_hand_visual())
	_clear_part_visual(player.get_lower_body_visual())

func _apply_cutout_appearance(player: PlayerCharacterScript, appearance: PlayerAppearanceScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player for cutout application.")
	Validation.require_condition(appearance != null, "PlayerAppearanceApplicator requires an appearance for cutout application.")
	var atlas_texture_resource: Resource = load(appearance.atlas_texture_path)
	Validation.require_condition(atlas_texture_resource != null, "PlayerAppearanceApplicator failed to load atlas texture at %s." % appearance.atlas_texture_path)
	Validation.require_condition(atlas_texture_resource is Texture2D, "PlayerAppearanceApplicator atlas texture must be a Texture2D.")
	var atlas_texture: Texture2D = atlas_texture_resource as Texture2D

	var body_source: CutoutSource = _load_cutout_source(appearance.body_texture_path)
	var face_source: CutoutSource = _load_cutout_source(appearance.face_texture_path)
	var left_upper_arm_source: CutoutSource = _load_cutout_source(appearance.left_upper_arm_texture_path)
	var left_forearm_source: CutoutSource = _load_cutout_source(appearance.left_forearm_texture_path)
	var left_hand_source: CutoutSource = _load_cutout_source(appearance.left_hand_texture_path)
	var right_upper_arm_source: CutoutSource = _load_cutout_source(appearance.right_upper_arm_texture_path)
	var right_forearm_source: CutoutSource = _load_cutout_source(appearance.right_forearm_texture_path)
	var right_hand_source: CutoutSource = _load_cutout_source(appearance.right_hand_texture_path)
	var lower_body_source: CutoutSource = _load_cutout_source(appearance.lower_body_texture_path)

	_apply_cutout_part(player.get_body_visual_sprite(), atlas_texture, body_source, appearance.body_offset, appearance.body_scale)
	_apply_cutout_part(player.get_face_overlay(), atlas_texture, face_source, appearance.face_offset, appearance.face_scale)
	_apply_cutout_part(player.get_left_upper_arm_visual(), atlas_texture, left_upper_arm_source, appearance.left_upper_arm_offset, appearance.left_upper_arm_scale)
	_apply_cutout_part(player.get_left_forearm_visual(), atlas_texture, left_forearm_source, appearance.left_forearm_offset, appearance.left_forearm_scale)
	_apply_cutout_part(player.get_left_hand_visual(), atlas_texture, left_hand_source, appearance.left_hand_offset, appearance.left_hand_scale)
	_apply_cutout_part(player.get_right_upper_arm_visual(), atlas_texture, right_upper_arm_source, appearance.right_upper_arm_offset, appearance.right_upper_arm_scale)
	_apply_cutout_part(player.get_right_forearm_visual(), atlas_texture, right_forearm_source, appearance.right_forearm_offset, appearance.right_forearm_scale)
	_apply_cutout_part(player.get_right_hand_visual(), atlas_texture, right_hand_source, appearance.right_hand_offset, appearance.right_hand_scale)
	_apply_cutout_part(player.get_lower_body_visual(), atlas_texture, lower_body_source, appearance.lower_body_offset, appearance.lower_body_scale)
	_fit_body_collision_to_cutout_bounds(player, body_source, face_source, lower_body_source, appearance)

func _apply_cutout_part(anchor: Sprite2D, atlas_texture: Texture2D, source: CutoutSource, offset: Vector2, scale_value: Vector2) -> void:
	Validation.require_condition(anchor != null, "PlayerAppearanceApplicator requires a cutout anchor.")
	Validation.require_condition(atlas_texture != null, "PlayerAppearanceApplicator requires an atlas texture for cutout application.")
	Validation.require_condition(source != null, "PlayerAppearanceApplicator requires a cutout source.")
	Validation.require_condition(source.used_rect.size.x > 0.0 and source.used_rect.size.y > 0.0, "PlayerAppearanceApplicator requires a non-empty cutout source rectangle.")
	Validation.require_condition(source.frame_size.x > 0.0 and source.frame_size.y > 0.0, "PlayerAppearanceApplicator requires a positive cutout frame size.")
	Validation.require_condition(scale_value.x > 0.0 and scale_value.y > 0.0, "PlayerAppearanceApplicator cutout scale must be positive.")

	anchor.texture = null
	anchor.offset = Vector2.ZERO
	anchor.scale = Vector2.ONE
	var cutout_node: Polygon2D = _get_or_create_cutout_node(anchor)
	cutout_node.texture = atlas_texture
	cutout_node.color = Color(1.0, 1.0, 1.0, 1.0)
	cutout_node.polygon = _build_cutout_polygon(anchor, source, offset, scale_value)
	cutout_node.uv = _build_cutout_uv(source.used_rect)
	cutout_node.visible = true

func _get_or_create_cutout_node(anchor: Sprite2D) -> Polygon2D:
	var existing_node: Node = anchor.get_node_or_null(NodePath(String(APPEARANCE_CUTOUT_NODE_NAME)))
	if existing_node != null:
		Validation.require_condition(existing_node is Polygon2D, "PlayerAppearanceApplicator appearance cutout node must remain a Polygon2D.")
		return existing_node as Polygon2D

	var cutout_node := Polygon2D.new()
	cutout_node.name = APPEARANCE_CUTOUT_NODE_NAME
	anchor.add_child(cutout_node)
	return cutout_node

func _build_cutout_polygon(anchor: Sprite2D, source: CutoutSource, offset: Vector2, scale_value: Vector2) -> PackedVector2Array:
	var assembled_center: Vector2 = _get_cutout_center_in_visual_frame(source) + offset
	var anchor_center: Vector2 = _sum_local_positions(anchor, _require_visual_root(anchor))
	var local_center: Vector2 = assembled_center - anchor_center
	var half_size: Vector2 = (source.used_rect.size * scale_value) / 2.0
	return PackedVector2Array([
		local_center + Vector2(-half_size.x, -half_size.y),
		local_center + Vector2(half_size.x, -half_size.y),
		local_center + Vector2(half_size.x, half_size.y),
		local_center + Vector2(-half_size.x, half_size.y),
	])

func _build_cutout_uv(source_rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		source_rect.position,
		source_rect.position + Vector2(source_rect.size.x, 0.0),
		source_rect.position + source_rect.size,
		source_rect.position + Vector2(0.0, source_rect.size.y),
	])

func _load_cutout_source(asset_path: String) -> CutoutSource:
	Validation.require_condition(not asset_path.is_empty(), "PlayerAppearanceApplicator requires a cutout asset path.")
	Validation.require_condition(FileAccess.file_exists(asset_path), "PlayerAppearanceApplicator is missing cutout asset at %s." % asset_path)
	var image := Image.new()
	var load_result: Error = image.load(ProjectSettings.globalize_path(asset_path))
	Validation.require_condition(load_result == OK, "PlayerAppearanceApplicator failed to load cutout image at %s." % asset_path)
	var used_rect: Rect2i = image.get_used_rect()
	Validation.require_condition(used_rect.size.x > 0 and used_rect.size.y > 0, "PlayerAppearanceApplicator found no opaque pixels in %s." % asset_path)
	return CutoutSource.new(Vector2(image.get_width(), image.get_height()), Rect2(used_rect.position, used_rect.size))

func _fit_body_collision_to_cutout_bounds(
	player: PlayerCharacterScript,
	body_source: CutoutSource,
	face_source: CutoutSource,
	lower_body_source: CutoutSource,
	appearance: PlayerAppearanceScript
) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit cutout collision.")
	var merged_bounds: Rect2 = _build_cutout_rect(body_source, appearance.body_offset, appearance.body_scale)
	merged_bounds = merged_bounds.merge(_build_cutout_rect(face_source, appearance.face_offset, appearance.face_scale))
	merged_bounds = merged_bounds.merge(_build_cutout_rect(lower_body_source, appearance.lower_body_offset, appearance.lower_body_scale))
	Validation.require_condition(merged_bounds.size.x > 0.0 and merged_bounds.size.y > 0.0, "PlayerAppearanceApplicator requires visible cutout bounds to fit collision.")
	var capsule_radius: float = merged_bounds.size.x / 2.0
	var capsule_height: float = maxf(0.0, merged_bounds.size.y - (capsule_radius * 2.0))
	var collision_offset: Vector2 = merged_bounds.position + (merged_bounds.size / 2.0)
	player.configure_body_collision_capsule(capsule_radius, capsule_height, collision_offset)

func _build_cutout_rect(source: CutoutSource, offset: Vector2, scale_value: Vector2) -> Rect2:
	var center: Vector2 = _get_cutout_center_in_visual_frame(source) + offset
	var scaled_size: Vector2 = source.used_rect.size * scale_value
	return Rect2(center - (scaled_size / 2.0), scaled_size)

func _get_cutout_center_in_visual_frame(source: CutoutSource) -> Vector2:
	Validation.require_condition(source != null, "PlayerAppearanceApplicator requires a cutout source to resolve its center.")
	var frame_center: Vector2 = source.frame_size / 2.0
	return source.used_rect.position + (source.used_rect.size / 2.0) - frame_center

func _require_visual_root(anchor: Sprite2D) -> Node2D:
	var current: Node = anchor
	while current != null:
		if current is Node2D and current.name == &"VisualRoot":
			return current as Node2D
		current = current.get_parent()
	Validation.require_condition(false, "PlayerAppearanceApplicator could not resolve VisualRoot for a cutout anchor.")
	return anchor

func _apply_part(sprite: Sprite2D, asset_path: String, offset: Vector2, scale_value: Vector2) -> void:
	Validation.require_condition(sprite != null, "PlayerAppearanceApplicator requires a sprite target.")
	Validation.require_condition(not asset_path.is_empty(), "PlayerAppearanceApplicator requires a texture asset path.")
	Validation.require_condition(FileAccess.file_exists(asset_path), "PlayerAppearanceApplicator is missing asset at %s." % asset_path)
	_clear_part_visual(sprite)
	var image := Image.new()
	var load_result: Error = image.load(ProjectSettings.globalize_path(asset_path))
	Validation.require_condition(load_result == OK, "PlayerAppearanceApplicator failed to load image at %s." % asset_path)
	var used_rect: Rect2i = image.get_used_rect()
	Validation.require_condition(used_rect.size.x > 0 and used_rect.size.y > 0, "PlayerAppearanceApplicator found no opaque pixels in %s." % asset_path)
	if used_rect.position != Vector2i.ZERO or used_rect.size != Vector2i(image.get_width(), image.get_height()):
		image = image.get_region(used_rect)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	Validation.require_condition(texture != null, "PlayerAppearanceApplicator failed to create texture for %s." % asset_path)
	sprite.texture = texture
	sprite.offset = offset
	sprite.scale = scale_value

func _clear_part_visual(sprite: Sprite2D) -> void:
	Validation.require_condition(sprite != null, "PlayerAppearanceApplicator requires a sprite target before clearing visuals.")
	var existing_cutout_node: Node = sprite.get_node_or_null(NodePath(String(APPEARANCE_CUTOUT_NODE_NAME)))
	if existing_cutout_node != null:
		sprite.remove_child(existing_cutout_node)
		existing_cutout_node.free()
	sprite.texture = null
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE

func _fit_body_collision_to_visible_body(player: PlayerCharacterScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit collision.")
	var merged_bounds: Rect2 = _get_body_collision_fit_bounds(player)
	Validation.require_condition(merged_bounds.size.x > 0.0 and merged_bounds.size.y > 0.0, "PlayerAppearanceApplicator requires visible body bounds to fit collision.")
	var capsule_radius: float = merged_bounds.size.x / 2.0
	var capsule_height: float = maxf(0.0, merged_bounds.size.y - (capsule_radius * 2.0))
	var collision_offset: Vector2 = merged_bounds.position + (merged_bounds.size / 2.0)
	player.configure_body_collision_capsule(capsule_radius, capsule_height, collision_offset)

func _get_body_collision_fit_bounds(player: PlayerCharacterScript) -> Rect2:
	var body_bounds: Rect2 = _get_sprite_body_local_rect(player.get_body_visual_sprite(), player.get_player_body())
	var face_bounds: Rect2 = _get_sprite_body_local_rect(player.get_face_overlay(), player.get_player_body())
	var lower_body_bounds: Rect2 = _get_sprite_body_local_rect(player.get_lower_body_visual(), player.get_player_body())
	return body_bounds.merge(face_bounds).merge(lower_body_bounds)

func _get_sprite_body_local_rect(sprite: Sprite2D, stop_at: Node) -> Rect2:
	Validation.require_condition(sprite != null, "PlayerAppearanceApplicator requires a sprite to measure collision fit bounds.")
	Validation.require_condition(stop_at != null, "PlayerAppearanceApplicator requires a collision fit root node.")
	Validation.require_condition(sprite.texture != null, "PlayerAppearanceApplicator requires an applied texture before measuring collision fit bounds.")
	Validation.require_condition(sprite.centered, "PlayerAppearanceApplicator expects centered sprite targets when fitting collision.")
	var texture_size: Vector2 = sprite.texture.get_size()
	Validation.require_condition(texture_size.x > 0.0 and texture_size.y > 0.0, "PlayerAppearanceApplicator requires non-empty sprite textures when fitting collision.")
	var scaled_size: Vector2 = Vector2(texture_size.x * absf(sprite.scale.x), texture_size.y * absf(sprite.scale.y))
	Validation.require_condition(scaled_size.x > 0.0 and scaled_size.y > 0.0, "PlayerAppearanceApplicator requires positive sprite scale when fitting collision.")
	var sprite_center: Vector2 = _sum_local_positions(sprite, stop_at) + sprite.offset
	return Rect2(sprite_center - (scaled_size / 2.0), scaled_size)

func _sum_local_positions(node: Node2D, stop_at: Node) -> Vector2:
	Validation.require_condition(node != null, "PlayerAppearanceApplicator requires a node to resolve collision fit positions.")
	Validation.require_condition(stop_at != null, "PlayerAppearanceApplicator requires a collision fit stop node.")
	var accumulated: Vector2 = Vector2.ZERO
	var current: Node = node
	while current != null and current != stop_at:
		Validation.require_condition(current is Node2D, "PlayerAppearanceApplicator requires Node2D ancestors while resolving collision fit positions.")
		var typed_current: Node2D = current as Node2D
		accumulated += typed_current.position
		current = typed_current.get_parent()
	Validation.require_condition(current == stop_at, "PlayerAppearanceApplicator could not resolve collision fit positions to PlayerBody.")
	return accumulated
