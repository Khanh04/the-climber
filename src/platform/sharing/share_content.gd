class_name ShareContent
extends RefCounted

var message_text: String
var deep_link_url: String
var image_path: String

func _init(message_text_value: String = "", deep_link_url_value: String = "", image_path_value: String = "") -> void:
    message_text = message_text_value
    deep_link_url = deep_link_url_value
    image_path = image_path_value
    assert_valid()

func is_valid() -> bool:
    return message_text != "" or deep_link_url != "" or image_path != ""

func assert_valid() -> void:
    Validation.require_condition(is_valid(), "Share content requires at least one payload field.")