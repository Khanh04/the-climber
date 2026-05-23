class_name PlayerCosmeticApplicator
extends RefCounted

const CosmeticItemCatalogScript = preload("res://resources/config/cosmetic_item_catalog.gd")
const CosmeticItemScript = preload("res://resources/config/cosmetic_item.gd")
const CosmeticLoadoutScript = preload("res://resources/config/cosmetic_loadout.gd")
const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")

const APPLIED_BODY_NODE_NAME: StringName = &"AppliedBodyCosmetic"
const APPLIED_LEFT_HAND_NODE_NAME: StringName = &"AppliedLeftHandCosmetic"
const APPLIED_RIGHT_HAND_NODE_NAME: StringName = &"AppliedRightHandCosmetic"

func apply_loadout(player: Node, loadout: Resource, catalog: Resource) -> void:
	Validation.require_condition(player != null, "PlayerCosmeticApplicator requires a player.")
	Validation.require_condition(player is PlayerCharacterScript, "PlayerCosmeticApplicator requires a PlayerCharacter implementation.")
	Validation.require_condition(loadout != null, "PlayerCosmeticApplicator requires a cosmetic loadout.")
	Validation.require_condition(loadout is CosmeticLoadoutScript, "PlayerCosmeticApplicator requires a CosmeticLoadout resource.")
	Validation.require_condition(catalog != null, "PlayerCosmeticApplicator requires a cosmetic item catalog.")
	Validation.require_condition(catalog is CosmeticItemCatalogScript, "PlayerCosmeticApplicator requires a CosmeticItemCatalog resource.")

	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	var typed_loadout: CosmeticLoadoutScript = loadout as CosmeticLoadoutScript
	var typed_catalog: CosmeticItemCatalogScript = catalog as CosmeticItemCatalogScript
	typed_loadout.assert_valid()
	typed_catalog.assert_valid()

	_apply_body_cosmetic(typed_player.get_cosmetic_visual_root(), typed_catalog.get_required_item_by_id(typed_loadout.body_cosmetic_id))
	_apply_hand_cosmetic(typed_player.get_left_hand_cosmetic_root(), typed_catalog.get_required_item_by_id(typed_loadout.left_hand_cosmetic_id), APPLIED_LEFT_HAND_NODE_NAME, true)
	_apply_hand_cosmetic(typed_player.get_right_hand_cosmetic_root(), typed_catalog.get_required_item_by_id(typed_loadout.right_hand_cosmetic_id), APPLIED_RIGHT_HAND_NODE_NAME, false)
	typed_player.assert_visual_roots_physics_neutral()

func clear_loadout_visuals(player: Node) -> void:
	Validation.require_condition(player != null, "PlayerCosmeticApplicator requires a player before clearing visuals.")
	Validation.require_condition(player is PlayerCharacterScript, "PlayerCosmeticApplicator requires a PlayerCharacter implementation before clearing visuals.")
	var typed_player: PlayerCharacterScript = player as PlayerCharacterScript
	_clear_owned_node(typed_player.get_cosmetic_visual_root(), APPLIED_BODY_NODE_NAME)
	_clear_owned_node(typed_player.get_left_hand_cosmetic_root(), APPLIED_LEFT_HAND_NODE_NAME)
	_clear_owned_node(typed_player.get_right_hand_cosmetic_root(), APPLIED_RIGHT_HAND_NODE_NAME)
	typed_player.assert_visual_roots_physics_neutral()

func _apply_body_cosmetic(root: Node2D, item: CosmeticItemScript) -> void:
	Validation.require_condition(root != null, "PlayerCosmeticApplicator requires a body cosmetic root.")
	_assert_item_slot(item, CosmeticSlotScript.Value.BODY)
	_clear_owned_node(root, APPLIED_BODY_NODE_NAME)

	var cosmetic_root := Node2D.new()
	cosmetic_root.name = APPLIED_BODY_NODE_NAME
	var body_panel := Polygon2D.new()
	body_panel.name = &"BodyPanel"
	body_panel.color = item.visual_color
	body_panel.polygon = PackedVector2Array([
		Vector2(-22.0, -30.0),
		Vector2(22.0, -30.0),
		Vector2(18.0, 34.0),
		Vector2(-18.0, 34.0),
	])
	var accent_panel := Polygon2D.new()
	accent_panel.name = &"AccentPanel"
	accent_panel.color = item.accent_color
	accent_panel.polygon = PackedVector2Array([
		Vector2(-10.0, -24.0),
		Vector2(10.0, -24.0),
		Vector2(8.0, 24.0),
		Vector2(-8.0, 24.0),
	])
	cosmetic_root.add_child(body_panel)
	cosmetic_root.add_child(accent_panel)
	root.add_child(cosmetic_root)

func _apply_hand_cosmetic(root: Node2D, item: CosmeticItemScript, node_name: StringName, is_left_hand: bool) -> void:
	Validation.require_condition(root != null, "PlayerCosmeticApplicator requires a hand cosmetic root.")
	_assert_item_slot(item, CosmeticSlotScript.Value.LEFT_HAND if is_left_hand else CosmeticSlotScript.Value.RIGHT_HAND)
	_clear_owned_node(root, node_name)

	var cosmetic_root := Node2D.new()
	cosmetic_root.name = node_name
	var cuff := Polygon2D.new()
	cuff.name = &"Cuff"
	cuff.color = item.visual_color
	cuff.polygon = PackedVector2Array([
		Vector2(-10.0, -7.0),
		Vector2(10.0, -7.0),
		Vector2(10.0, 7.0),
		Vector2(-10.0, 7.0),
	])
	var palm := Polygon2D.new()
	palm.name = &"Palm"
	palm.color = item.accent_color
	palm.polygon = PackedVector2Array([
		Vector2(-7.0, -5.0),
		Vector2(7.0, -5.0),
		Vector2(5.0, 10.0),
		Vector2(-5.0, 10.0),
	])
	cosmetic_root.add_child(cuff)
	cosmetic_root.add_child(palm)
	root.add_child(cosmetic_root)

func _clear_owned_node(root: Node2D, node_name: StringName) -> void:
	var existing_node: Node = root.get_node_or_null(NodePath(String(node_name)))
	if existing_node != null:
		root.remove_child(existing_node)
		existing_node.free()

func _assert_item_slot(item: CosmeticItemScript, expected_slot: int) -> void:
	CosmeticSlotScript.assert_valid(expected_slot)
	Validation.require_condition(item != null, "PlayerCosmeticApplicator requires a cosmetic item.")
	item.assert_valid()
	Validation.require_condition(item.slot == expected_slot, "PlayerCosmeticApplicator item slot does not match the target root.")