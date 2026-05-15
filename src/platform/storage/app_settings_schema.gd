class_name AppSettingsSchema
extends RefCounted

const VERSION: int = 1
const KEY_SCHEMA_VERSION: String = "schema_version"
const KEY_AUDIO_MUTED: String = "audio_muted"
const KEY_MASTER_VOLUME_RATIO: String = "master_volume_ratio"
const KEY_HAPTICS_ENABLED: String = "haptics_enabled"
const KEY_TOUCH_SPLIT_RATIO: String = "touch_split_ratio"
const KEY_TOUCH_CENTER_DEAD_ZONE_RATIO: String = "touch_center_dead_zone_ratio"
const SNAPSHOT_KEY: String = "app_settings_snapshot"