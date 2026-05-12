extends GutTest

const ClimbPrototypeFrameResultScript = preload("res://src/gameplay/player/climb_prototype_frame_result.gd")
const PlayerPhysicsModeScript = preload("res://src/gameplay/player/player_physics_mode.gd")
const PlayerPhysicsModeTransitionsScript = preload("res://src/gameplay/player/player_physics_mode_transitions.gd")

func test_player_physics_modes_validate_supported_values() -> void:
    assert_true(PlayerPhysicsModeScript.is_valid(PlayerPhysicsModeScript.controlled_climb()))
    assert_true(PlayerPhysicsModeScript.is_valid(PlayerPhysicsModeScript.falling_ragdoll()))
    assert_false(PlayerPhysicsModeScript.is_valid(99))

func test_player_physics_transitions_allow_controlled_to_falling_reasons() -> void:
    assert_true(PlayerPhysicsModeTransitionsScript.is_transition_allowed(
        PlayerPhysicsModeScript.controlled_climb(),
        PlayerPhysicsModeScript.falling_ragdoll(),
        PlayerPhysicsModeTransitionsScript.Reason.ALL_HANDS_RELEASED
    ))
    assert_true(PlayerPhysicsModeTransitionsScript.is_transition_allowed(
        PlayerPhysicsModeScript.controlled_climb(),
        PlayerPhysicsModeScript.falling_ragdoll(),
        PlayerPhysicsModeTransitionsScript.Reason.STAMINA_DEPLETED
    ))
    assert_true(PlayerPhysicsModeTransitionsScript.is_transition_allowed(
        PlayerPhysicsModeScript.controlled_climb(),
        PlayerPhysicsModeScript.falling_ragdoll(),
        PlayerPhysicsModeTransitionsScript.Reason.FALL_DETECTED
    ))

func test_player_physics_transitions_require_explicit_reset_from_falling() -> void:
    assert_false(PlayerPhysicsModeTransitionsScript.is_transition_allowed(
        PlayerPhysicsModeScript.falling_ragdoll(),
        PlayerPhysicsModeScript.controlled_climb(),
        PlayerPhysicsModeTransitionsScript.Reason.FRAME_ADVANCE
    ))
    assert_true(PlayerPhysicsModeTransitionsScript.is_transition_allowed(
        PlayerPhysicsModeScript.falling_ragdoll(),
        PlayerPhysicsModeScript.controlled_climb(),
        PlayerPhysicsModeTransitionsScript.Reason.RESET_OR_RESCUE
    ))

func test_player_physics_mode_enters_falling_when_stamina_depletes() -> void:
    var frame_result := ClimbPrototypeFrameResultScript.new(Vector2.ZERO, true, 0)

    var next_mode: int = PlayerPhysicsModeTransitionsScript.mode_after_frame(PlayerPhysicsModeScript.controlled_climb(), frame_result)

    assert_eq(next_mode, PlayerPhysicsModeScript.falling_ragdoll())

func test_player_physics_mode_stays_controlled_for_normal_frames() -> void:
    var frame_result := ClimbPrototypeFrameResultScript.new(Vector2.ZERO, false, 0)

    var next_mode: int = PlayerPhysicsModeTransitionsScript.mode_after_frame(PlayerPhysicsModeScript.controlled_climb(), frame_result)

    assert_eq(next_mode, PlayerPhysicsModeScript.controlled_climb())