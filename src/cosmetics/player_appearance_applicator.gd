class_name PlayerAppearanceApplicator
extends RefCounted

const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")
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
	if not typed_appearance.atlas_texture_path.is_empty():
		_apply_cutout_appearance(typed_player, typed_appearance)
		typed_player.assert_visual_roots_physics_neutral()
		return

	var body_image: Image = _apply_part(typed_player.get_body_visual_sprite(), typed_appearance.body_texture_path, typed_appearance.body_offset, typed_appearance.body_scale)
	var face_image: Image = _apply_part(typed_player.get_face_overlay(), typed_appearance.face_texture_path, typed_appearance.face_offset, typed_appearance.face_scale)
	var left_arm_image: Image = _apply_part(typed_player.get_left_arm_visual(), typed_appearance.left_upper_arm_texture_path, typed_appearance.left_upper_arm_offset, typed_appearance.left_upper_arm_scale)
	var right_arm_image: Image = _apply_part(typed_player.get_right_arm_visual(), typed_appearance.right_upper_arm_texture_path, typed_appearance.right_upper_arm_offset, typed_appearance.right_upper_arm_scale)
	_fit_torso_collision_to_pixel_silhouette(typed_player, body_image)
	_fit_head_collision_to_pixel_silhouette(typed_player, face_image)
	_fit_arm_collision_to_pixel_silhouette(typed_player, HandSideScript.Value.LEFT, left_arm_image)
	_fit_arm_collision_to_pixel_silhouette(typed_player, HandSideScript.Value.RIGHT, right_arm_image)
	typed_player.assert_visual_roots_physics_neutral()

func _clear_existing_appearance_visuals(player: PlayerCharacterScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player before clearing appearance visuals.")
	_clear_part_visual(player.get_body_visual_sprite())
	_clear_part_visual(player.get_face_overlay())
	_clear_part_visual(player.get_left_arm_visual())
	_clear_part_visual(player.get_right_arm_visual())

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
	var right_upper_arm_source: CutoutSource = _load_cutout_source(appearance.right_upper_arm_texture_path)

	_apply_cutout_part(player.get_body_visual_sprite(), atlas_texture, body_source, appearance.body_offset, appearance.body_scale)
	_apply_cutout_part(player.get_face_overlay(), atlas_texture, face_source, appearance.face_offset, appearance.face_scale)
	_apply_cutout_part(player.get_left_arm_visual(), atlas_texture, left_upper_arm_source, appearance.left_upper_arm_offset, appearance.left_upper_arm_scale)
	_apply_cutout_part(player.get_right_arm_visual(), atlas_texture, right_upper_arm_source, appearance.right_upper_arm_offset, appearance.right_upper_arm_scale)
	_fit_torso_collision_to_cutout_bounds(player, body_source, appearance)
	_fit_head_collision_to_cutout_bounds(player, face_source, appearance)
	_fit_arm_collision_to_cutout_bounds(player, HandSideScript.Value.LEFT, left_upper_arm_source, appearance.left_upper_arm_offset, appearance.left_upper_arm_scale)
	_fit_arm_collision_to_cutout_bounds(player, HandSideScript.Value.RIGHT, right_upper_arm_source, appearance.right_upper_arm_offset, appearance.right_upper_arm_scale)

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
	var image: Image = _load_image_resource(asset_path)
	var used_rect: Rect2i = image.get_used_rect()
	Validation.require_condition(used_rect.size.x > 0 and used_rect.size.y > 0, "PlayerAppearanceApplicator found no opaque pixels in %s." % asset_path)
	return CutoutSource.new(Vector2(image.get_width(), image.get_height()), Rect2(used_rect.position, used_rect.size))

func _fit_torso_collision_to_cutout_bounds(
	player: PlayerCharacterScript,
	body_source: CutoutSource,
	appearance: PlayerAppearanceScript
) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit cutout collision.")
	var merged_bounds: Rect2 = _get_cutout_body_local_rect(player.get_body_visual_sprite(), player.get_player_body(), body_source, appearance.body_offset, appearance.body_scale)
	Validation.require_condition(merged_bounds.size.x > 0.0 and merged_bounds.size.y > 0.0, "PlayerAppearanceApplicator requires visible cutout bounds to fit collision.")
	var capsule_dimensions: Vector2 = _capsule_dimensions_from_rect_size(merged_bounds.size)
	var collision_offset: Vector2 = merged_bounds.position + (merged_bounds.size / 2.0)
	player.configure_torso_collision_capsule(capsule_dimensions.x, capsule_dimensions.y, collision_offset)

func _fit_head_collision_to_cutout_bounds(
	player: PlayerCharacterScript,
	face_source: CutoutSource,
	appearance: PlayerAppearanceScript
) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit cutout head collision.")
	var merged_bounds: Rect2 = _get_cutout_body_local_rect(player.get_face_overlay(), player.get_head_body(), face_source, appearance.face_offset, appearance.face_scale)
	Validation.require_condition(merged_bounds.size.x > 0.0 and merged_bounds.size.y > 0.0, "PlayerAppearanceApplicator requires visible cutout face bounds to fit collision.")
	var circle_radius: float = maxf(merged_bounds.size.x, merged_bounds.size.y) / 2.0
	var collision_offset: Vector2 = merged_bounds.position + (merged_bounds.size / 2.0)
	player.configure_head_collision_circle(circle_radius, collision_offset)

func _fit_arm_collision_to_cutout_bounds(
	player: PlayerCharacterScript,
	hand_side: int,
	arm_source: CutoutSource,
	offset: Vector2,
	scale_value: Vector2
) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit cutout arm collision.")
	var arm_sprite: Sprite2D = player.get_left_arm_visual() if hand_side == HandSideScript.Value.LEFT else player.get_right_arm_visual()
	var arm_body: RigidBody2D = player.get_left_arm_body() if hand_side == HandSideScript.Value.LEFT else player.get_right_arm_body()
	var merged_bounds: Rect2 = _get_cutout_body_local_rect(arm_sprite, arm_body, arm_source, offset, scale_value)
	Validation.require_condition(merged_bounds.size.x > 0.0 and merged_bounds.size.y > 0.0, "PlayerAppearanceApplicator requires visible cutout arm bounds to fit collision.")
	var capsule_dimensions: Vector2 = _capsule_dimensions_from_rect_size(merged_bounds.size)
	var collision_offset: Vector2 = merged_bounds.position + (merged_bounds.size / 2.0)
	player.configure_arm_collision_capsule(hand_side, capsule_dimensions.x, capsule_dimensions.y, collision_offset)

# Content center (per _get_cutout_center_in_visual_frame) is expressed in the anchor sprite's
# own local space -- same convention as Sprite2D.offset in the non-cutout path. Adding the
# anchor's accumulated local position up to stop_at (mirroring _get_sprite_body_local_rect)
# is what makes this correct for anchors that sit off-origin relative to their owning body
# (FaceOverlay at Head-local (0,-14), arm visuals at (0,28)) and not just Torso's zero-offset case.
func _get_cutout_body_local_rect(anchor: Sprite2D, stop_at: Node, source: CutoutSource, offset: Vector2, scale_value: Vector2) -> Rect2:
	var anchor_local_offset: Vector2 = _sum_local_positions(anchor, stop_at)
	var content_center: Vector2 = anchor_local_offset + _get_cutout_center_in_visual_frame(source) + offset
	var scaled_size: Vector2 = source.used_rect.size * scale_value
	return Rect2(content_center - (scaled_size / 2.0), scaled_size)

func _get_cutout_center_in_visual_frame(source: CutoutSource) -> Vector2:
	Validation.require_condition(source != null, "PlayerAppearanceApplicator requires a cutout source to resolve its center.")
	return _resolve_crop_center_offset(source.frame_size, source.used_rect.position, source.used_rect.size)

# Cropping an image to its opaque bounding box (used_rect) throws away where that
# box sat within the original canvas. Assets are frequently drawn off-center within
# their canvas (e.g. an arm sprite whose opaque pixels sit left-of-center), so the
# cropped, re-centered sprite must be nudged back by this delta or it renders shifted
# from its intended attachment point. Shared by both the plain and cutout part paths.
func _resolve_crop_center_offset(frame_size: Vector2, used_rect_position: Vector2, used_rect_size: Vector2) -> Vector2:
	return used_rect_position + (used_rect_size / 2.0) - (frame_size / 2.0)

func _require_visual_root(anchor: Sprite2D) -> Node2D:
	var current: Node = anchor
	while current != null:
		if current is Node2D and current.name == &"VisualRoot":
			return current as Node2D
		current = current.get_parent()
	Validation.require_condition(false, "PlayerAppearanceApplicator could not resolve VisualRoot for a cutout anchor.")
	return anchor

func _apply_part(sprite: Sprite2D, asset_path: String, offset: Vector2, scale_value: Vector2) -> Image:
	Validation.require_condition(sprite != null, "PlayerAppearanceApplicator requires a sprite target.")
	Validation.require_condition(not asset_path.is_empty(), "PlayerAppearanceApplicator requires a texture asset path.")
	_clear_part_visual(sprite)
	var image: Image = _load_image_resource(asset_path)
	var used_rect: Rect2i = image.get_used_rect()
	Validation.require_condition(used_rect.size.x > 0 and used_rect.size.y > 0, "PlayerAppearanceApplicator found no opaque pixels in %s." % asset_path)
	var frame_size: Vector2 = Vector2(image.get_width(), image.get_height())
	var crop_center_offset: Vector2 = _resolve_crop_center_offset(frame_size, Vector2(used_rect.position), Vector2(used_rect.size))
	if used_rect.position != Vector2i.ZERO or used_rect.size != Vector2i(image.get_width(), image.get_height()):
		image = image.get_region(used_rect)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	Validation.require_condition(texture != null, "PlayerAppearanceApplicator failed to create texture for %s." % asset_path)
	sprite.texture = texture
	sprite.offset = offset + crop_center_offset
	sprite.scale = scale_value
	return image

# Reading these bytes via Image.load(ProjectSettings.globalize_path(...)) only works when
# res:// maps to real files on disk (editor, or a debug run from source). An exported build
# (export_filter=all_resources) ships the *imported* .ctex resource, not the raw source PNG,
# so that raw-file read fails silently in release (Validation.require_condition's assert() is
# a no-op there) -- this is why Android in particular loses appearance textures and, via the
# pixel-silhouette collision that depends on them, all body collision. Going through the normal
# resource loader instead resolves the same res:// path to the imported texture on every
# platform, editor and export alike.
func _load_image_resource(asset_path: String) -> Image:
	var texture_resource: Resource = load(asset_path)
	Validation.require_condition(texture_resource != null, "PlayerAppearanceApplicator failed to load texture at %s." % asset_path)
	Validation.require_condition(texture_resource is Texture2D, "PlayerAppearanceApplicator texture asset must be a Texture2D at %s." % asset_path)
	var texture: Texture2D = texture_resource as Texture2D
	var image: Image = texture.get_image()
	Validation.require_condition(image != null, "PlayerAppearanceApplicator failed to read pixel data from %s." % asset_path)
	return image

func _clear_part_visual(sprite: Sprite2D) -> void:
	Validation.require_condition(sprite != null, "PlayerAppearanceApplicator requires a sprite target before clearing visuals.")
	var existing_cutout_node: Node = sprite.get_node_or_null(NodePath(String(APPEARANCE_CUTOUT_NODE_NAME)))
	if existing_cutout_node != null:
		sprite.remove_child(existing_cutout_node)
		existing_cutout_node.free()
	sprite.texture = null
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE

# Godot's CapsuleShape2D silently clamps radius down whenever height < 2*radius, so radius
# must always come from the bounds' shorter axis and height from the longer one. Deriving
# radius from size.x unconditionally (as this used to) collapses to a zero-radius sliver for
# any bounds wider than tall -- which the arm art hits, since it's drawn on a diagonal bone
# and crops wider than it is tall. This is a no-op for the (portrait) torso/head bounds.
func _capsule_dimensions_from_rect_size(rect_size: Vector2) -> Vector2:
	var short_dimension: float = minf(rect_size.x, rect_size.y)
	var long_dimension: float = maxf(rect_size.x, rect_size.y)
	return Vector2(short_dimension / 2.0, long_dimension)

# Godot's dynamic RigidBody2D physics doesn't handle a single concave shape correctly (no
# well-defined "inside" for a ConcavePolygonShape2D on a live body -- it's meant for static
# geometry only), so a traced pixel silhouette has to be split into convex pieces before it's
# usable collision. BitMap.opaque_to_polygons traces the sprite's already-cropped opaque region
# (built from the exact same image _apply_part rendered, so the collision literally outlines
# the visible pixels); Geometry2D.decompose_polygon_in_convex splits each traced outline into
# physics-legal convex pieces. The transform into body-local space mirrors _get_cutout_body_local_rect's
# convention: image-space points are centered, scaled by the sprite's own scale, and offset by
# the sprite's resolved .offset plus its accumulated local position up to the owning body.
const SILHOUETTE_TRACE_EPSILON: float = 2.0

func _fit_torso_collision_to_pixel_silhouette(player: PlayerCharacterScript, image: Image) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit collision.")
	var local_polygons: Array[PackedVector2Array] = _pixel_silhouette_polygons(image, player.get_body_visual_sprite(), player.get_player_body())
	player.configure_torso_collision_polygons(local_polygons)

func _fit_head_collision_to_pixel_silhouette(player: PlayerCharacterScript, image: Image) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit head collision.")
	var local_polygons: Array[PackedVector2Array] = _pixel_silhouette_polygons(image, player.get_face_overlay(), player.get_head_body())
	player.configure_head_collision_polygons(local_polygons)

func _fit_arm_collision_to_pixel_silhouette(player: PlayerCharacterScript, hand_side: int, image: Image) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player to fit arm collision.")
	var arm_sprite: Sprite2D = player.get_left_arm_visual() if hand_side == HandSideScript.Value.LEFT else player.get_right_arm_visual()
	var arm_body: RigidBody2D = player.get_left_arm_body() if hand_side == HandSideScript.Value.LEFT else player.get_right_arm_body()
	var local_polygons: Array[PackedVector2Array] = _pixel_silhouette_polygons(image, arm_sprite, arm_body)
	player.configure_arm_collision_polygons(hand_side, local_polygons)

func _pixel_silhouette_polygons(image: Image, anchor: Sprite2D, stop_at: Node) -> Array[PackedVector2Array]:
	Validation.require_condition(image != null, "PlayerAppearanceApplicator requires an image to trace a collision silhouette.")
	Validation.require_condition(anchor != null, "PlayerAppearanceApplicator requires a sprite anchor to trace a collision silhouette.")

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)
	var traced_outlines: Array[PackedVector2Array] = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, Vector2(image.get_size())), SILHOUETTE_TRACE_EPSILON)
	Validation.require_condition(not traced_outlines.is_empty(), "PlayerAppearanceApplicator found no opaque silhouette to trace.")

	var anchor_local_offset: Vector2 = _sum_local_positions(anchor, stop_at) + anchor.offset
	var image_center: Vector2 = Vector2(image.get_size()) / 2.0
	var convex_polygons: Array[PackedVector2Array] = []
	for outline in traced_outlines:
		var body_local_points: Array[Vector2] = []
		for point in outline:
			body_local_points.append(anchor_local_offset + (point - image_center) * anchor.scale)
		var body_local_outline := PackedVector2Array(body_local_points)
		for convex_piece in Geometry2D.decompose_polygon_in_convex(body_local_outline):
			Validation.require_condition(convex_piece.size() >= 3, "PlayerAppearanceApplicator produced a degenerate convex collision piece.")
			convex_polygons.append(convex_piece)

	Validation.require_condition(not convex_polygons.is_empty(), "PlayerAppearanceApplicator failed to build any convex collision pieces.")
	return convex_polygons

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
	Validation.require_condition(current == stop_at, "PlayerAppearanceApplicator could not resolve collision fit positions to Torso.")
	return accumulated
