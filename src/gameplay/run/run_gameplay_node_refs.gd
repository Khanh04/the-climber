class_name RunGameplayNodeRefs
extends RefCounted

const ChaserKillZoneScript = preload("res://scenes/chaser/chaser_kill_zone.gd")
const GeneratedChunkCoordinatorScript = preload("res://src/gameplay/generation/generated_chunk_coordinator.gd")
const PlayerCharacterScript = preload("res://scenes/player/player_character.gd")

var player: PlayerCharacterScript = null
var chaser_kill_zone: ChaserKillZoneScript = null
var generated_chunk_coordinator: GeneratedChunkCoordinatorScript = null
var reset_anchor: Marker2D = null
var camera: Camera2D = null
var starter_handholds_root: Node2D = null

func _init(
	player_value: PlayerCharacterScript,
	chaser_kill_zone_value: ChaserKillZoneScript,
	generated_chunk_coordinator_value: GeneratedChunkCoordinatorScript,
	reset_anchor_value: Marker2D,
	camera_value: Camera2D,
	starter_handholds_root_value: Node2D
) -> void:
	player = player_value
	chaser_kill_zone = chaser_kill_zone_value
	generated_chunk_coordinator = generated_chunk_coordinator_value
	reset_anchor = reset_anchor_value
	camera = camera_value
	starter_handholds_root = starter_handholds_root_value

func assert_valid() -> void:
	Validation.require_condition(player != null, "Run gameplay nodes require PlayerCharacter.")
	Validation.require_condition(chaser_kill_zone != null, "Run gameplay nodes require ChaserKillZone.")
	Validation.require_condition(generated_chunk_coordinator != null, "Run gameplay nodes require GeneratedChunks coordinator.")
	Validation.require_condition(reset_anchor != null, "Run gameplay nodes require ResetAnchor.")
	Validation.require_condition(camera != null, "Run gameplay nodes require DevCamera.")
	Validation.require_condition(starter_handholds_root != null, "Run gameplay nodes require Handholds.")