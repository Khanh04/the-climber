class_name GenerationTuning
extends Resource

@export var generator_version: String = DailySeedKey.GENERATOR_VERSION
@export var segment_height_meters: float = 16.0
@export var chunk_width_meters: float = 3.0
@export var inner_lane_position_ratio: float = 0.2
@export var outer_lane_position_ratio: float = 0.66
@export var pickup_socket_ratio: float = 0.6
@export var pickup_lateral_offset_meters: float = 0.28
@export var pickup_branch_side_alignment_meters: float = 0.25
@export var hazard_branch_side_alignment_meters: float = 0.25
@export var easy_band_max_height_meters: float = 50.0
@export var baseline_band_max_height_meters: float = 100.0
@export var chunk_spawn_ahead_count: int = 3
@export var chunk_keep_behind_count: int = 1
@export var socket_count_per_chunk: int = 12
@export var ladder_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([1, 2]),
    PackedInt32Array([1]),
    PackedInt32Array([2]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([1]),
    PackedInt32Array([2]),
    PackedInt32Array([1, 2]),
]
@export var zigzag_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([0, 1]),
    PackedInt32Array([2, 3]),
    PackedInt32Array([0, 1]),
    PackedInt32Array([2, 3]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 3]),
]
@export var wide_traverse_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([0, 1]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([2, 3]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 1]),
    PackedInt32Array([2, 3]),
    PackedInt32Array([1, 2]),
]
@export var sparse_reach_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([0]),
    PackedInt32Array([3]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([0]),
    PackedInt32Array([3]),
    PackedInt32Array([1, 2]),
]
@export var dense_recovery_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 1]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([2, 3]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 1]),
    PackedInt32Array([1, 2]),
]
@export var fork_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 3]),
    PackedInt32Array([0, 3]),
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 3]),
    PackedInt32Array([0, 3]),
    PackedInt32Array([1, 2]),
]
@export var risk_lane_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([1, 2]),
    PackedInt32Array([0, 2]),
    PackedInt32Array([1, 3]),
    PackedInt32Array([0, 2]),
    PackedInt32Array([1, 3]),
    PackedInt32Array([0, 2]),
    PackedInt32Array([1, 2]),
]
@export var swing_gap_hold_rows: Array[PackedInt32Array] = [
    PackedInt32Array([0]),
    PackedInt32Array([0, 2]),
    PackedInt32Array([3]),
    PackedInt32Array([1, 3]),
    PackedInt32Array([0]),
    PackedInt32Array([2]),
]

func is_valid() -> bool:
    return generator_version != "" \
        and segment_height_meters > 0.0 \
        and chunk_width_meters > 0.0 \
        and inner_lane_position_ratio > 0.0 \
        and outer_lane_position_ratio > inner_lane_position_ratio \
        and outer_lane_position_ratio < 1.0 \
        and pickup_socket_ratio > 0.0 \
        and pickup_socket_ratio < 1.0 \
        and pickup_lateral_offset_meters >= 0.0 \
        and pickup_branch_side_alignment_meters >= 0.0 \
        and pickup_branch_side_alignment_meters < _max_lane_alignment_meters() \
        and hazard_branch_side_alignment_meters >= 0.0 \
        and hazard_branch_side_alignment_meters < _max_lane_alignment_meters() \
        and easy_band_max_height_meters > 0.0 \
        and baseline_band_max_height_meters > easy_band_max_height_meters \
        and chunk_spawn_ahead_count >= 1 \
        and chunk_keep_behind_count >= 0 \
        and socket_count_per_chunk > 0 \
        and _hold_rows_are_valid(ladder_hold_rows) \
        and _hold_rows_are_valid(zigzag_hold_rows) \
        and _hold_rows_are_valid(wide_traverse_hold_rows) \
        and _hold_rows_are_valid(sparse_reach_hold_rows) \
        and _hold_rows_are_valid(dense_recovery_hold_rows) \
        and _hold_rows_are_valid(fork_hold_rows) \
        and _hold_rows_are_valid(risk_lane_hold_rows) \
        and _hold_rows_are_valid(swing_gap_hold_rows)

func validate() -> void:
    assert_valid()

func assert_valid() -> void:
    Validation.require_condition(generator_version != "", "Generation config requires a generator version.")
    Validation.require_condition(segment_height_meters > 0.0, "Generation segment height must be positive.")
    Validation.require_condition(chunk_width_meters > 0.0, "Generation chunk width must be positive.")
    Validation.require_condition(inner_lane_position_ratio > 0.0, "Generation inner lane position ratio must be positive.")
    Validation.require_condition(
        outer_lane_position_ratio > inner_lane_position_ratio,
        "Generation outer lane position ratio must be greater than the inner lane position ratio."
    )
    Validation.require_condition(outer_lane_position_ratio < 1.0, "Generation outer lane position ratio must stay inside the chunk width.")
    Validation.require_condition(pickup_socket_ratio > 0.0, "Generation pickup socket ratio must be positive.")
    Validation.require_condition(pickup_socket_ratio < 1.0, "Generation pickup socket ratio must leave room for hazards.")
    Validation.require_condition(pickup_lateral_offset_meters >= 0.0, "Generation pickup lateral offset cannot be negative.")
    Validation.require_condition(
        pickup_branch_side_alignment_meters >= 0.0,
        "Generation pickup branch-side alignment cannot be negative."
    )
    Validation.require_condition(
        pickup_branch_side_alignment_meters < _max_lane_alignment_meters(),
        "Generation pickup branch-side alignment must stay inside the outer lane width."
    )
    Validation.require_condition(
        hazard_branch_side_alignment_meters >= 0.0,
        "Generation hazard branch-side alignment cannot be negative."
    )
    Validation.require_condition(
        hazard_branch_side_alignment_meters < _max_lane_alignment_meters(),
        "Generation hazard branch-side alignment must stay inside the outer lane width."
    )
    Validation.require_condition(easy_band_max_height_meters > 0.0, "Generation easy-band max height must be positive.")
    Validation.require_condition(
        baseline_band_max_height_meters > easy_band_max_height_meters,
        "Generation baseline-band max height must be greater than the easy-band max height."
    )
    Validation.require_condition(chunk_spawn_ahead_count >= 1, "Generation config must keep at least one chunk ahead of the camera.")
    Validation.require_condition(chunk_keep_behind_count >= 0, "Generation config cannot keep a negative number of chunks behind the camera.")
    Validation.require_condition(socket_count_per_chunk > 0, "Generation config must provide at least one socket per chunk.")
    _assert_valid_hold_rows("LADDER", ladder_hold_rows)
    _assert_valid_hold_rows("ZIGZAG", zigzag_hold_rows)
    _assert_valid_hold_rows("WIDE_TRAVERSE", wide_traverse_hold_rows)
    _assert_valid_hold_rows("SPARSE_REACH", sparse_reach_hold_rows)
    _assert_valid_hold_rows("DENSE_RECOVERY", dense_recovery_hold_rows)
    _assert_valid_hold_rows("FORK", fork_hold_rows)
    _assert_valid_hold_rows("RISK_LANE", risk_lane_hold_rows)
    _assert_valid_hold_rows("SWING_GAP", swing_gap_hold_rows)

func get_pickup_socket_count() -> int:
    return ceili(float(socket_count_per_chunk) * pickup_socket_ratio)

func get_hazard_socket_count() -> int:
    return maxi(0, socket_count_per_chunk - get_pickup_socket_count())

func get_hold_rows(chunk_type: int) -> Array[PackedInt32Array]:
    ChunkType.assert_valid(chunk_type)

    match chunk_type:
        ChunkType.Value.LADDER:
            return ladder_hold_rows
        ChunkType.Value.ZIGZAG:
            return zigzag_hold_rows
        ChunkType.Value.WIDE_TRAVERSE:
            return wide_traverse_hold_rows
        ChunkType.Value.SPARSE_REACH:
            return sparse_reach_hold_rows
        ChunkType.Value.DENSE_RECOVERY:
            return dense_recovery_hold_rows
        ChunkType.Value.FORK:
            return fork_hold_rows
        ChunkType.Value.RISK_LANE:
            return risk_lane_hold_rows
        ChunkType.Value.SWING_GAP:
            return swing_gap_hold_rows
        _:
            Validation.require_condition(false, "Generation config requires a supported chunk type when fetching hold rows.")
            return []

func _hold_rows_are_valid(hold_rows: Array[PackedInt32Array]) -> bool:
    if hold_rows.size() == 0:
        return false

    for row_index in range(hold_rows.size()):
        var hold_row: PackedInt32Array = hold_rows[row_index]
        if hold_row.size() == 0:
            return false

        for lane_entry_index in range(hold_row.size()):
            var lane_index: int = hold_row[lane_entry_index]
            if lane_index < 0 or lane_index > 3:
                return false

    return true

func _assert_valid_hold_rows(label: String, hold_rows: Array[PackedInt32Array]) -> void:
    Validation.require_condition(hold_rows.size() > 0, "Generation %s hold rows must not be empty." % label)

    for row_index in range(hold_rows.size()):
        var hold_row: PackedInt32Array = hold_rows[row_index]
        Validation.require_condition(hold_row.size() > 0, "Generation %s hold row %d must not be empty." % [label, row_index])

        for lane_entry_index in range(hold_row.size()):
            var lane_index: int = hold_row[lane_entry_index]
            Validation.require_condition(
                lane_index >= 0 and lane_index <= 3,
                "Generation %s hold row %d contains an out-of-range lane index." % [label, row_index]
            )

func _max_lane_alignment_meters() -> float:
    return (chunk_width_meters * 0.5) * outer_lane_position_ratio