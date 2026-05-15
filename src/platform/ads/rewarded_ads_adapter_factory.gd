class_name RewardedAdsAdapterFactory
extends RefCounted

const DesktopPreviewRewardedAdsAdapterScript = preload("res://src/platform/ads/desktop_preview_rewarded_ads_adapter.gd")
const RewardedAdsAdapterScript = preload("res://src/platform/ads/rewarded_ads_adapter.gd")
const UnavailableRewardedAdsAdapterScript = preload("res://src/platform/ads/unavailable_rewarded_ads_adapter.gd")

static func create_default() -> RewardedAdsAdapterScript:
    return create_for_runtime(DisplayServer.get_name(), OS.get_name())

static func create_for_runtime(display_server_name: String, os_name: String) -> RewardedAdsAdapterScript:
    Validation.require_condition(not display_server_name.is_empty(), "RewardedAdsAdapterFactory display server name cannot be empty.")
    Validation.require_condition(not os_name.is_empty(), "RewardedAdsAdapterFactory OS name cannot be empty.")

    if _should_use_desktop_preview(display_server_name, os_name):
        return DesktopPreviewRewardedAdsAdapterScript.new()

    return UnavailableRewardedAdsAdapterScript.new()

static func _should_use_desktop_preview(display_server_name: String, os_name: String) -> bool:
    if display_server_name == "headless":
        return false

    match os_name:
        "Linux", "Windows", "macOS":
            return true
        _:
            return false