extends GutTest

const HoldReachGraphScript = preload("res://src/gameplay/generation/hold_reach_graph.gd")

const HOLD_SIZE: Vector2 = Vector2(0.1, 0.1)

func test_easiest_path_prefers_the_route_with_the_shortest_longest_move() -> void:
    # Left route: three 1.0 m moves. Right route: two 1.5 m moves (fewer, but longer).
    var graph: HoldReachGraphScript = _graph([
        Vector2(0, 0), Vector2(-1, -1), Vector2(-1, -2), Vector2(0, -3),
        Vector2(1.2, -1.5),
    ], 2.2)
    var path: PackedInt32Array = graph.easiest_path(PackedInt32Array([0]), _mask(graph, [3]), graph.empty_mask(), 2.0)

    assert_eq(path, PackedInt32Array([0, 1, 2, 3]))
    assert_almost_eq(graph.bottleneck_of(path), sqrt(2.0), 0.001)

func test_path_within_rejects_moves_longer_than_the_limit() -> void:
    var graph: HoldReachGraphScript = _graph([Vector2(0, 0), Vector2(0, -1.5)], 2.2)

    assert_true(graph.path_within(PackedInt32Array([0]), _mask(graph, [1]), graph.empty_mask(), 1.4).is_empty())
    assert_false(graph.path_within(PackedInt32Array([0]), _mask(graph, [1]), graph.empty_mask(), 1.6).is_empty())

func test_moves_beyond_the_gap_envelope_are_not_edges() -> void:
    var graph: HoldReachGraphScript = _graph([Vector2(0, 0), Vector2(0, -3.0)], 2.2)

    assert_eq(graph.reachable_from(PackedInt32Array([0]))[1], 0)

func test_downward_moves_beyond_the_budget_are_not_edges() -> void:
    var graph: HoldReachGraphScript = _graph([Vector2(0, -1.0), Vector2(1.0, 0.0)], 2.2, 0.12)

    assert_eq(graph.reachable_from(PackedInt32Array([0]))[1], 0, "Dropping 0.9 m between hold edges is not a climbing move.")
    assert_eq(graph.reachable_from(PackedInt32Array([1]))[0], 1)

func test_distinct_routes_counts_separated_lines_but_not_side_by_side_twins() -> void:
    var positions: Array[Vector2] = []
    for x: float in [-3.0, -2.6, 3.0]:
        for step in range(5):
            positions.append(Vector2(x, -float(step)))
    var graph: HoldReachGraphScript = _graph(positions, 1.2)
    var sources: PackedInt32Array = PackedInt32Array([0, 5, 10])
    var targets: PackedByteArray = _mask(graph, [4, 9, 14])

    var routes: Array[PackedInt32Array] = graph.distinct_routes(sources, targets, graph.empty_mask(), 1.1, 1.75, 3)

    assert_eq(routes.size(), 2, "The two lines 0.4 m apart are one choice; the line 6 m away is another.")

func test_corridor_guides_find_a_route_the_open_search_misses() -> void:
    var positions: Array[Vector2] = []
    for x: float in [-3.0, 0.0, 3.0]:
        for step in range(5):
            positions.append(Vector2(x, -float(step)))
    var graph: HoldReachGraphScript = _graph(positions, 1.2)
    var sources: PackedInt32Array = PackedInt32Array([0, 5, 10])
    var targets: PackedByteArray = _mask(graph, [4, 9, 14])
    var guide: PackedByteArray = graph.empty_mask()
    for node in range(graph.node_count()):
        guide[node] = 0 if absf(graph.positions[node].x - 3.0) < 0.5 else 1

    var routes: Array[PackedInt32Array] = graph.distinct_routes(sources, targets, graph.empty_mask(), 1.1, 1.75, 3, PackedByteArray(), [guide])

    assert_eq(routes.size(), 3)

func _graph(points: Array[Vector2], max_gap: float, max_downward: float = 0.12) -> HoldReachGraphScript:
    var positions: PackedVector2Array = PackedVector2Array(points)
    var sizes: PackedVector2Array = PackedVector2Array()
    var _resize: int = sizes.resize(positions.size())
    sizes.fill(HOLD_SIZE)
    return HoldReachGraphScript.new(positions, sizes, max_gap, max_downward)

func _mask(graph: HoldReachGraphScript, nodes: Array[int]) -> PackedByteArray:
    var mask: PackedByteArray = graph.empty_mask()
    for node in nodes:
        mask[node] = 1
    return mask
