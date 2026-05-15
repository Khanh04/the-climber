extends GutTest

const RewardedAdPlacementScript = preload("res://src/platform/ads/rewarded_ad_placement.gd")
const RewardedAdOutcomeScript = preload("res://src/platform/ads/rewarded_ad_outcome.gd")
const RewardedAdResultScript = preload("res://src/platform/ads/rewarded_ad_result.gd")
const DesktopPreviewRewardedAdsAdapterScript = preload("res://src/platform/ads/desktop_preview_rewarded_ads_adapter.gd")
const RewardedAdsAdapterFactoryScript = preload("res://src/platform/ads/rewarded_ads_adapter_factory.gd")
const UnavailableRewardedAdsAdapterScript = preload("res://src/platform/ads/unavailable_rewarded_ads_adapter.gd")
const HapticFeedbackTypeScript = preload("res://src/platform/haptics/haptic_feedback_type.gd")
const AppLifecycleEventScript = preload("res://src/platform/lifecycle/app_lifecycle_event.gd")
const AppLifecycleStateScript = preload("res://src/platform/lifecycle/app_lifecycle_state.gd")
const StoreProductKindScript = preload("res://src/platform/commerce/store_product_kind.gd")
const StoreProductScript = preload("res://src/platform/commerce/store_product.gd")
const PurchaseOutcomeScript = preload("res://src/platform/commerce/purchase_outcome.gd")
const PurchaseResultScript = preload("res://src/platform/commerce/purchase_result.gd")
const SubscriptionStatusScript = preload("res://src/platform/commerce/subscription_status.gd")
const ShareContentScript = preload("res://src/platform/sharing/share_content.gd")
const ShareResultScript = preload("res://src/platform/sharing/share_result.gd")

func test_rewarded_ad_placements_and_outcomes_are_validated() -> void:
    assert_true(RewardedAdPlacementScript.is_valid(RewardedAdPlacementScript.Value.CONTINUE))
    assert_true(RewardedAdPlacementScript.is_valid(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER))
    assert_true(RewardedAdPlacementScript.is_valid(RewardedAdPlacementScript.Value.PRE_RUN_VENDING_MACHINE))
    assert_false(RewardedAdPlacementScript.is_valid(-1))

    assert_true(RewardedAdOutcomeScript.is_valid(RewardedAdOutcomeScript.Value.COMPLETED))
    assert_true(RewardedAdOutcomeScript.is_valid(RewardedAdOutcomeScript.Value.CANCELLED))
    assert_true(RewardedAdOutcomeScript.is_valid(RewardedAdOutcomeScript.Value.UNAVAILABLE))
    assert_true(RewardedAdOutcomeScript.is_valid(RewardedAdOutcomeScript.Value.FAILED))
    assert_false(RewardedAdOutcomeScript.is_valid(99))

func test_rewarded_ad_result_requires_completed_ads_to_grant_rewards() -> void:
    var rewarded_result = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.CONTINUE,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )
    var cancelled_result = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER,
        RewardedAdOutcomeScript.Value.CANCELLED,
        false
    )
    var invalid_result = RewardedAdResultScript.new(
        RewardedAdPlacementScript.Value.PRE_RUN_VENDING_MACHINE,
        RewardedAdOutcomeScript.Value.COMPLETED,
        true
    )
    invalid_result.reward_granted = false

    assert_true(rewarded_result.is_valid())
    assert_true(cancelled_result.is_valid())
    assert_false(invalid_result.is_valid())

func test_unavailable_rewarded_ads_adapter_returns_unavailable_result() -> void:
    var adapter: UnavailableRewardedAdsAdapterScript = UnavailableRewardedAdsAdapterScript.new()
    var raw_result: RefCounted = adapter.show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)

    assert_false(adapter.can_show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER))
    assert_true(raw_result is RewardedAdResultScript)
    var result: RewardedAdResultScript = raw_result as RewardedAdResultScript
    assert_eq(result.placement, RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)
    assert_eq(result.outcome, RewardedAdOutcomeScript.Value.UNAVAILABLE)
    assert_false(result.reward_granted)

func test_desktop_preview_rewarded_ads_adapter_returns_completed_rewards() -> void:
    var adapter: DesktopPreviewRewardedAdsAdapterScript = DesktopPreviewRewardedAdsAdapterScript.new()
    var raw_result: RefCounted = adapter.show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)

    assert_true(adapter.can_show(RewardedAdPlacementScript.Value.CONTINUE))
    assert_true(adapter.can_show(RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER))
    assert_true(adapter.can_show(RewardedAdPlacementScript.Value.PRE_RUN_VENDING_MACHINE))
    assert_true(raw_result is RewardedAdResultScript)
    var result: RewardedAdResultScript = raw_result as RewardedAdResultScript
    assert_eq(result.placement, RewardedAdPlacementScript.Value.POST_RUN_COIN_DOUBLER)
    assert_eq(result.outcome, RewardedAdOutcomeScript.Value.COMPLETED)
    assert_true(result.reward_granted)

func test_rewarded_ads_adapter_factory_uses_desktop_preview_only_for_desktop_runtime() -> void:
    var desktop_adapter: RefCounted = RewardedAdsAdapterFactoryScript.create_for_runtime("x11", "Linux")
    var headless_adapter: RefCounted = RewardedAdsAdapterFactoryScript.create_for_runtime("headless", "Linux")
    var android_adapter: RefCounted = RewardedAdsAdapterFactoryScript.create_for_runtime("vulkan", "Android")

    assert_true(desktop_adapter is DesktopPreviewRewardedAdsAdapterScript)
    assert_true(headless_adapter is UnavailableRewardedAdsAdapterScript)
    assert_true(android_adapter is UnavailableRewardedAdsAdapterScript)

func test_haptics_and_lifecycle_contract_enums_cover_supported_values() -> void:
    assert_true(HapticFeedbackTypeScript.is_valid(HapticFeedbackTypeScript.Value.LIGHT_IMPACT))
    assert_true(HapticFeedbackTypeScript.is_valid(HapticFeedbackTypeScript.Value.SUCCESS))
    assert_false(HapticFeedbackTypeScript.is_valid(-1))

    assert_true(AppLifecycleStateScript.is_valid(AppLifecycleStateScript.Value.ACTIVE))
    assert_true(AppLifecycleStateScript.is_valid(AppLifecycleStateScript.Value.PAUSED))
    assert_true(AppLifecycleStateScript.is_valid(AppLifecycleStateScript.Value.BACKGROUND))
    assert_false(AppLifecycleStateScript.is_valid(12))

    assert_true(AppLifecycleEventScript.is_valid(AppLifecycleEventScript.Value.PAUSED))
    assert_true(AppLifecycleEventScript.is_valid(AppLifecycleEventScript.Value.RESUMED))
    assert_true(AppLifecycleEventScript.is_valid(AppLifecycleEventScript.Value.ENTERED_BACKGROUND))
    assert_true(AppLifecycleEventScript.is_valid(AppLifecycleEventScript.Value.ENTERED_FOREGROUND))
    assert_true(AppLifecycleEventScript.is_valid(AppLifecycleEventScript.Value.QUIT_REQUESTED))
    assert_false(AppLifecycleEventScript.is_valid(34))

func test_store_products_and_purchase_results_require_valid_ids_and_kinds() -> void:
    var product = StoreProductScript.new(
        "supporter_pack",
        StoreProductKindScript.Value.SUPPORTER_SUBSCRIPTION,
        "Supporter Pack"
    )
    var invalid_product = StoreProductScript.new("coin_bundle_small", StoreProductKindScript.Value.COIN_BUNDLE, "Coin Bundle")
    invalid_product.product_id = ""
    var purchase_result = PurchaseResultScript.new("supporter_pack", PurchaseOutcomeScript.Value.PURCHASED)
    var invalid_purchase_result = PurchaseResultScript.new("failed_purchase", PurchaseOutcomeScript.Value.FAILED)
    invalid_purchase_result.product_id = ""

    assert_true(product.is_valid())
    assert_false(invalid_product.is_valid())
    assert_true(StoreProductKindScript.is_valid(StoreProductKindScript.Value.COSMETIC_UNLOCK))
    assert_false(StoreProductKindScript.is_valid(45))

    assert_true(purchase_result.is_valid())
    assert_false(invalid_purchase_result.is_valid())
    assert_true(PurchaseOutcomeScript.is_valid(PurchaseOutcomeScript.Value.RESTORED))
    assert_false(PurchaseOutcomeScript.is_valid(22))
    assert_true(SubscriptionStatusScript.is_valid(SubscriptionStatusScript.Value.GRACE_PERIOD))
    assert_false(SubscriptionStatusScript.is_valid(10))

func test_share_content_requires_a_payload_field() -> void:
    var text_share = ShareContentScript.new("Beat my climb.", "", "")
    var link_share = ShareContentScript.new("", "https://example.com/run", "")
    var image_share = ShareContentScript.new("", "", "user://share.png")
    var invalid_share = ShareContentScript.new("Ready to share", "", "")
    invalid_share.message_text = ""
    invalid_share.deep_link_url = ""
    invalid_share.image_path = ""

    assert_true(text_share.is_valid())
    assert_true(link_share.is_valid())
    assert_true(image_share.is_valid())
    assert_false(invalid_share.is_valid())
    assert_true(ShareResultScript.is_valid(ShareResultScript.Value.SHARED))
    assert_false(ShareResultScript.is_valid(77))