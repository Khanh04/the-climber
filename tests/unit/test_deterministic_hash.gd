extends GutTest

## Pins the FNV-1a algorithm. If this value changes, every generated route
## reshuffles -- which must be a deliberate generator_version bump, never an
## accident.
func test_of_string_matches_pinned_fnv1a_value() -> void:
    assert_eq(DeterministicHash.of_string("generator_v5:2026-05-14"), 890364228)

func test_of_string_is_stable_across_calls() -> void:
    assert_eq(DeterministicHash.of_string("route_plan:7:2:branch_side"), DeterministicHash.of_string("route_plan:7:2:branch_side"))

func test_of_string_is_non_negative_for_non_empty_input() -> void:
    for seed_text: String in ["a", "generator_v5:run:1-2", "y:3:4", "movement:11"]:
        assert_gte(DeterministicHash.of_string(seed_text), 0)

func test_unit_float_stays_in_zero_to_one_half_open_range() -> void:
    for seed_text: String in ["0", "1", "abc", "generator_v5:2026-05-14", "generator_v5:2026-05-15"]:
        var value: float = DeterministicHash.unit_float(seed_text)
        assert_between(value, 0.0, 1.0)
        assert_lt(value, 1.0)
