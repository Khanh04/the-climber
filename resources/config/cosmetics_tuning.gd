class_name CosmeticsTuning
extends Resource

@export var loadout_slot_count: int = 3
@export var max_preview_variants_per_item: int = 4
@export var catalog_page_size: int = 12
@export var max_active_visual_layers: int = 3

func is_valid() -> bool:
    return loadout_slot_count > 0 \
        and max_preview_variants_per_item > 0 \
        and catalog_page_size > 0 \
        and max_active_visual_layers > 0

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(loadout_slot_count > 0, "Cosmetics config must expose at least one loadout slot.")
    Validation.require_condition(max_preview_variants_per_item > 0, "Cosmetics config must allow at least one preview variant per item.")
    Validation.require_condition(catalog_page_size > 0, "Cosmetics catalog page size must be positive.")
    Validation.require_condition(max_active_visual_layers > 0, "Cosmetics config must allow at least one active visual layer.")