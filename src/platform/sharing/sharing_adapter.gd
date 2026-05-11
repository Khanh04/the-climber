class_name SharingAdapter
extends RefCounted

const ShareContentScript = preload("res://src/platform/sharing/share_content.gd")
const ShareResultScript = preload("res://src/platform/sharing/share_result.gd")

func can_share(content: RefCounted) -> bool:
    Validation.require_condition(content != null, "SharingAdapter requires share content.")
    Validation.require_condition(content is ShareContentScript, "SharingAdapter requires a share content instance.")
    Validation.require_condition(false, "SharingAdapter.can_share must be implemented.")
    return false

func share(content: RefCounted) -> int:
    Validation.require_condition(content != null, "SharingAdapter requires share content.")
    Validation.require_condition(content is ShareContentScript, "SharingAdapter requires a share content instance.")
    Validation.require_condition(false, "SharingAdapter.share must be implemented.")
    return ShareResultScript.Value.UNAVAILABLE