class_name StoreShell
extends Control

signal item_selected(item_id: StringName)
signal purchase_requested(item_id: StringName)
signal equip_requested(item_id: StringName)
signal closed

const CosmeticSlotScript = preload("res://src/cosmetics/cosmetic_slot.gd")
const StoreItemStateScript = preload("res://src/ui/store_item_state.gd")
const StoreStateScript = preload("res://src/ui/store_state.gd")

const ALL_SLOTS_FILTER_ID: int = -100

@onready var _wallet_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/Header/WalletLabel") as Label
@onready var _close_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/Header/CloseButton") as Button
@onready var _slot_filter_option: OptionButton = get_node("CenterContainer/Panel/ContentMargin/Content/SlotFilterOption") as OptionButton
@onready var _item_list: ItemList = get_node("CenterContainer/Panel/ContentMargin/Content/ItemList") as ItemList
@onready var _selected_name_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/SelectedNameLabel") as Label
@onready var _selected_detail_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/SelectedDetailLabel") as Label
@onready var _feedback_label: Label = get_node("CenterContainer/Panel/ContentMargin/Content/FeedbackLabel") as Label
@onready var _purchase_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/Actions/PurchaseButton") as Button
@onready var _equip_button: Button = get_node("CenterContainer/Panel/ContentMargin/Content/Actions/EquipButton") as Button

var _state: StoreStateScript = null
var _visible_item_ids: Array[StringName] = []

func _ready() -> void:
	_validate_required_nodes()
	_populate_slot_filter_options()
	var _filter_connect_result: int = _slot_filter_option.connect(&"item_selected", Callable(self, "_on_slot_filter_item_selected"))
	var _item_connect_result: int = _item_list.connect(&"item_selected", Callable(self, "_on_item_list_item_selected"))
	var _purchase_connect_result: int = _purchase_button.connect(&"pressed", Callable(self, "_on_purchase_button_pressed"))
	var _equip_connect_result: int = _equip_button.connect(&"pressed", Callable(self, "_on_equip_button_pressed"))
	var _close_connect_result: int = _close_button.connect(&"pressed", Callable(self, "_on_close_button_pressed"))

func apply_state(state: RefCounted) -> void:
	Validation.require_condition(state != null, "StoreShell requires a state snapshot.")
	Validation.require_condition(state is StoreStateScript, "StoreShell requires a StoreState snapshot.")
	var typed_state: StoreStateScript = state as StoreStateScript
	typed_state.assert_valid()

	_state = typed_state
	visible = true
	_wallet_label.text = "Wallet: %d" % _state.wallet_coins
	_feedback_label.visible = not _state.feedback_message.is_empty()
	_feedback_label.text = _state.feedback_message
	_sync_item_list()
	_sync_selected_detail()

func _populate_slot_filter_options() -> void:
	_slot_filter_option.clear()
	_slot_filter_option.add_item("All", ALL_SLOTS_FILTER_ID)
	_slot_filter_option.add_item(CosmeticSlotScript.to_label(CosmeticSlotScript.Value.BODY), CosmeticSlotScript.Value.BODY)
	_slot_filter_option.add_item(CosmeticSlotScript.to_label(CosmeticSlotScript.Value.LEFT_HAND), CosmeticSlotScript.Value.LEFT_HAND)
	_slot_filter_option.add_item(CosmeticSlotScript.to_label(CosmeticSlotScript.Value.RIGHT_HAND), CosmeticSlotScript.Value.RIGHT_HAND)
	_slot_filter_option.add_item(CosmeticSlotScript.to_label(CosmeticSlotScript.Value.CHASER_THEME), CosmeticSlotScript.Value.CHASER_THEME)
	_slot_filter_option.select(0)

func _sync_item_list() -> void:
	_item_list.clear()
	_visible_item_ids = []
	if _state == null:
		return

	for item: StoreItemStateScript in _state.items:
		if not _item_matches_filter(item):
			continue

		var item_index: int = _item_list.add_item(_format_item_row(item))
		_visible_item_ids.append(item.item_id)
		if item.item_id == _state.selected_item_id:
			_item_list.select(item_index)

func _sync_selected_detail() -> void:
	var item: StoreItemStateScript = _get_selected_item_state()
	if item == null:
		_selected_name_label.text = "No item selected"
		_selected_detail_label.text = ""
		_purchase_button.visible = false
		_equip_button.visible = false
		return

	_selected_name_label.text = item.display_name
	_selected_detail_label.text = "%s\n%s" % [CosmeticSlotScript.to_label(item.slot), _format_item_status(item)]
	_purchase_button.visible = not item.owned
	_purchase_button.disabled = not item.can_purchase
	_purchase_button.text = "Buy %d" % item.price_coins
	_equip_button.visible = item.owned
	_equip_button.disabled = not item.can_equip
	_equip_button.text = "Equipped" if item.equipped else "Equip"

func _format_item_row(item: StoreItemStateScript) -> String:
	var row_text: String = "%s · %s" % [CosmeticSlotScript.to_label(item.slot), item.display_name]
	if item.equipped:
		return "%s · Equipped" % row_text

	if item.owned:
		return "%s · Owned" % row_text

	return "%s · %d coins" % [row_text, item.price_coins]

func _format_item_status(item: StoreItemStateScript) -> String:
	if item.equipped:
		return "Equipped"

	if item.owned:
		return "Owned"

	if item.can_purchase:
		return "%d coins" % item.price_coins

	return "%d coins · Need more coins" % item.price_coins

func _item_matches_filter(item: StoreItemStateScript) -> bool:
	var selected_filter_id: int = _slot_filter_option.get_selected_id()
	return selected_filter_id == ALL_SLOTS_FILTER_ID or item.slot == selected_filter_id

func _get_selected_item_state() -> StoreItemStateScript:
	if _state == null:
		return null

	for item: StoreItemStateScript in _state.items:
		if item.item_id == _state.selected_item_id:
			return item

	return null

func _on_slot_filter_item_selected(_index: int) -> void:
	_sync_item_list()
	_sync_selected_detail()

func _on_item_list_item_selected(index: int) -> void:
	Validation.require_condition(index >= 0 and index < _visible_item_ids.size(), "StoreShell selected item index is out of bounds.")
	item_selected.emit(_visible_item_ids[index])

func _on_purchase_button_pressed() -> void:
	Validation.require_condition(_state != null, "StoreShell requires state before purchase requests.")
	purchase_requested.emit(_state.selected_item_id)

func _on_equip_button_pressed() -> void:
	Validation.require_condition(_state != null, "StoreShell requires state before equip requests.")
	equip_requested.emit(_state.selected_item_id)

func _on_close_button_pressed() -> void:
	visible = false
	closed.emit()

func _validate_required_nodes() -> void:
	Validation.require_condition(_wallet_label != null, "StoreShell requires WalletLabel.")
	Validation.require_condition(_close_button != null, "StoreShell requires CloseButton.")
	Validation.require_condition(_slot_filter_option != null, "StoreShell requires SlotFilterOption.")
	Validation.require_condition(_item_list != null, "StoreShell requires ItemList.")
	Validation.require_condition(_selected_name_label != null, "StoreShell requires SelectedNameLabel.")
	Validation.require_condition(_selected_detail_label != null, "StoreShell requires SelectedDetailLabel.")
	Validation.require_condition(_feedback_label != null, "StoreShell requires FeedbackLabel.")
	Validation.require_condition(_purchase_button != null, "StoreShell requires PurchaseButton.")
	Validation.require_condition(_equip_button != null, "StoreShell requires EquipButton.")