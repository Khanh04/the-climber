class_name PlayerAppearanceApplicator
extends RefCounted

const PlayerAppearanceScript = preload("res://resources/config/player_appearance.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")
const HandSideScript = preload("res://src/gameplay/player/hand_side.gd")

func apply_appearance(player: Node, appearance: Resource) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player.")
	Validation.require_condition(player is PlayerCharacterScript, "PlayerAppearanceApplicator requires a PlayerCharacter implementation.")
	Validation.require_condition(appearance != null, "PlayerAppearanceApplicator requires a player appearance.")
	Validation.require_condition(appearance is PlayerAppearanceScript, "PlayerAppearanceApplicator requires a PlayerAppearance resource.")

	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	var typed_appearance: PlayerAppearanceScript = appearance as PlayerAppearanceScript
	typed_appearance.assert_valid()
	_clear_existing_appearance_visuals(typed_player)
	# The head is the whole visible body now. Its box is fitted to the head art's opaque bounds
	# but stays a RectangleShape2D rather than a traced face silhouette: a lopsided silhouette
	# gives a resting head a preferred tilt angle (it tips and drags the arm sockets, its
	# children, askew), and unlike the arms the head cannot be rotation-locked without also
	# killing the grip-point swing.
	var _face_image: Image = _apply_part(typed_player.get_face_overlay(), typed_appearance.face_texture_path, typed_appearance.face_offset, typed_appearance.face_scale, 0.0)
	typed_player.configure_head_collision(_drawn_rect_in(typed_player.get_face_overlay(), typed_player.get_head_body()))
	var left_arm_image: Image = _apply_part(typed_player.get_left_arm_visual(), typed_appearance.left_upper_arm_texture_path, typed_appearance.left_upper_arm_offset, typed_appearance.left_upper_arm_scale, typed_appearance.left_upper_arm_rotation_degrees)
	var right_arm_image: Image = _apply_part(typed_player.get_right_arm_visual(), typed_appearance.right_upper_arm_texture_path, typed_appearance.right_upper_arm_offset, typed_appearance.right_upper_arm_scale, typed_appearance.right_upper_arm_rotation_degrees)
	_fit_arm_collision_to_pixel_silhouette(typed_player, HandSideScript.Value.LEFT, left_arm_image)
	_fit_arm_collision_to_pixel_silhouette(typed_player, HandSideScript.Value.RIGHT, right_arm_image)
	typed_player.assert_visual_roots_physics_neutral()

func _clear_existing_appearance_visuals(player: PlayerCharacterScript) -> void:
	Validation.require_condition(player != null, "PlayerAppearanceApplicator requires a player before clearing appearance visuals.")
	_clear_part_visual(player.get_face_overlay())
	_clear_part_visual(player.get_left_arm_visual())
	_clear_part_visual(player.get_right_arm_visual())

# Cropping an image to its opaque bounding box (used_rect) throws away where that
# box sat within the original canvas. Assets are frequently drawn off-center within
# their canvas (e.g. an arm sprite whose opaque pixels sit left-of-center), so the
# cropped, re-centered sprite must be nudged back by this delta or it renders shifted
# from its intended attachment point.
func _resolve_crop_center_offset(frame_size: Vector2, used_rect_position: Vector2, used_rect_size: Vector2) -> Vector2:
	return used_rect_position + (used_rect_size / 2.0) - (frame_size / 2.0)

func _apply_part(sprite: Sprite2D, asset_path: String, offset: Vector2, scale_value: Vector2, rotation_degrees_value: float) -> Image:
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
	sprite.rotation_degrees = rotation_degrees_value
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
	sprite.texture = null
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0

# Godot's dynamic RigidBody2D physics doesn't handle a single concave shape correctly (no
# well-defined "inside" for a ConcavePolygonShape2D on a live body -- it's meant for static
# geometry only), so a traced pixel silhouette has to be split into convex pieces before it's
# usable collision. BitMap.opaque_to_polygons traces the sprite's already-cropped opaque region
# (built from the exact same image _apply_part rendered, so the collision literally outlines
# the visible pixels); Geometry2D.decompose_polygon_in_convex splits each traced outline into
# physics-legal convex pieces. The transform into body-local space: image-space points are
# centered, shifted by the sprite's resolved .offset (texture pixels), then carried through
# the sprite's own transform (scale, rotation, position) and every ancestor up to the body.
const SILHOUETTE_TRACE_EPSILON: float = 2.0

# The sprite's texture is already cropped to its opaque pixels, so its drawn quad is the visible
# art. Returns that quad's bounding rect in stop_at's local space.
func _drawn_rect_in(sprite: Sprite2D, stop_at: Node) -> Rect2:
	Validation.require_condition(sprite.texture != null, "PlayerAppearanceApplicator requires a textured sprite to measure its drawn rect.")
	var sprite_to_body: Transform2D = _transform_to(sprite, stop_at)
	var texture_size: Vector2 = sprite.texture.get_size()
	var local_rect := Rect2(sprite.offset - texture_size / 2.0, texture_size)
	var drawn_rect := Rect2(sprite_to_body * local_rect.position, Vector2.ZERO)
	for corner: Vector2 in [local_rect.position + Vector2(texture_size.x, 0.0), local_rect.position + Vector2(0.0, texture_size.y), local_rect.end]:
		drawn_rect = drawn_rect.expand(sprite_to_body * corner)
	return drawn_rect

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

	var anchor_to_body: Transform2D = _transform_to(anchor, stop_at)
	var image_center: Vector2 = Vector2(image.get_size()) / 2.0
	var convex_polygons: Array[PackedVector2Array] = []
	for outline in traced_outlines:
		var body_local_points: Array[Vector2] = []
		for point in outline:
			body_local_points.append(anchor_to_body * (anchor.offset + point - image_center))
		var body_local_outline := PackedVector2Array(body_local_points)
		for convex_piece in Geometry2D.decompose_polygon_in_convex(body_local_outline):
			Validation.require_condition(convex_piece.size() >= 3, "PlayerAppearanceApplicator produced a degenerate convex collision piece.")
			convex_polygons.append(convex_piece)

	Validation.require_condition(not convex_polygons.is_empty(), "PlayerAppearanceApplicator failed to build any convex collision pieces.")
	return convex_polygons

func _transform_to(node: Node2D, stop_at: Node) -> Transform2D:
	Validation.require_condition(node != null, "PlayerAppearanceApplicator requires a node to resolve collision fit positions.")
	Validation.require_condition(stop_at != null, "PlayerAppearanceApplicator requires a collision fit stop node.")
	var accumulated: Transform2D = Transform2D.IDENTITY
	var current: Node = node
	while current != null and current != stop_at:
		Validation.require_condition(current is Node2D, "PlayerAppearanceApplicator requires Node2D ancestors while resolving collision fit positions.")
		var typed_current: Node2D = current as Node2D
		accumulated = typed_current.transform * accumulated
		current = typed_current.get_parent()
	Validation.require_condition(current == stop_at, "PlayerAppearanceApplicator could not resolve collision fit positions to Torso.")
	return accumulated
