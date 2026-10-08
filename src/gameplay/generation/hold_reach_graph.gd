class_name HoldReachGraph
extends RefCounted

## Reachability graph over every hold in a chunk (plus the previous chunk's seam band).
## Positions are chunk-local metres, y negative up. An edge a -> b exists when the
## edge-to-edge gap fits the player's move envelope and b is not lower than a by more
## than the downward budget. Edge lengths are hold centre distances; route difficulty
## is the longest edge on the route (its bottleneck).

var positions: PackedVector2Array
var sizes: PackedVector2Array
var _edge_offsets: PackedInt32Array
var _edge_targets: PackedInt32Array
var _edge_lengths: PackedFloat32Array

func _init(positions_value: PackedVector2Array, sizes_value: PackedVector2Array, max_gap_meters: float, max_downward_meters: float) -> void:
	Validation.require_condition(positions_value.size() == sizes_value.size(), "HoldReachGraph positions and sizes must align.")
	Validation.require_condition(max_gap_meters > 0.0, "HoldReachGraph max gap must be positive.")
	Validation.require_condition(max_downward_meters >= 0.0, "HoldReachGraph downward budget cannot be negative.")
	positions = positions_value
	sizes = sizes_value
	_build_edges(max_gap_meters, max_downward_meters)

func node_count() -> int:
	return positions.size()

## Holds reachable from sources over every edge, ignoring difficulty.
func reachable_from(sources: PackedInt32Array) -> PackedByteArray:
	var reached: PackedByteArray = PackedByteArray()
	var _resize: int = reached.resize(node_count())
	var queue: PackedInt32Array = PackedInt32Array()
	for source in sources:
		if reached[source] == 0:
			reached[source] = 1
			var _q: bool = queue.append(source)
	var head: int = 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		for edge in range(_edge_offsets[node], _edge_offsets[node + 1]):
			var target: int = _edge_targets[edge]
			if reached[target] == 0:
				reached[target] = 1
				var _a: bool = queue.append(target)
	return reached

## Parent tree from the sources over every edge that adds as few unfree nodes as possible:
## entering a node with free[n] == 1 costs nothing, any other node costs 1. parents[n] is
## the node n is reached from, -1 for a source, -2 for unreachable.
func cheapest_parent_tree(sources: PackedInt32Array, free: PackedByteArray) -> PackedInt32Array:
	var parents: PackedInt32Array = PackedInt32Array()
	var costs: PackedInt32Array = PackedInt32Array()
	var done: PackedByteArray = _empty_mask()
	var _rp: int = parents.resize(node_count())
	var _rc: int = costs.resize(node_count())
	parents.fill(-2)
	costs.fill(1 << 30)
	for source in sources:
		parents[source] = -1
		costs[source] = 0
	# ponytail: O(V^2) Dijkstra; chunks hold < 120 nodes. Use a heap if that grows.
	for _round in range(node_count()):
		var node: int = -1
		for candidate in range(node_count()):
			if done[candidate] == 0 and costs[candidate] < (1 << 30) and (node == -1 or costs[candidate] < costs[node]):
				node = candidate
		if node == -1:
			break
		done[node] = 1
		for edge in range(_edge_offsets[node], _edge_offsets[node + 1]):
			var target: int = _edge_targets[edge]
			var cost: int = costs[node] + (0 if free[target] == 1 else 1)
			if cost < costs[target]:
				costs[target] = cost
				parents[target] = node
	return parents

## Whether there is a move from a to b no longer than max_move.
func has_move(from_node: int, to_node: int, max_move: float) -> bool:
	for edge in range(_edge_offsets[from_node], _edge_offsets[from_node + 1]):
		if _edge_targets[edge] == to_node:
			return _edge_lengths[edge] <= max_move
	return false

## The route with intermediate holds dropped wherever a later hold of the same route is
## still one move away (greedy farthest jump). Keeps the first and last hold.
func shortcut_route(route: PackedInt32Array, max_move: float) -> PackedInt32Array:
	var kept: PackedInt32Array = PackedInt32Array([route[0]])
	var index: int = 0
	while index < route.size() - 1:
		var next_index: int = index + 1
		for candidate in range(route.size() - 1, index, -1):
			if has_move(route[index], route[candidate], max_move):
				next_index = candidate
				break
		var _a: bool = kept.append(route[next_index])
		index = next_index
	return kept

## Fewest-move path from any source to any target using only edges no longer than
## max_move and nodes not banned. Empty when none exists.
func path_within(sources: PackedInt32Array, is_target: PackedByteArray, banned: PackedByteArray, max_move: float) -> PackedInt32Array:
	var previous: PackedInt32Array = PackedInt32Array()
	var _resize: int = previous.resize(node_count())
	previous.fill(-2)
	var queue: PackedInt32Array = PackedInt32Array()
	for source in sources:
		if banned[source] == 0 and previous[source] == -2:
			previous[source] = -1
			var _q: bool = queue.append(source)
	var head: int = 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if is_target[node] == 1:
			return _unwind(previous, node)
		for edge in range(_edge_offsets[node], _edge_offsets[node + 1]):
			var target: int = _edge_targets[edge]
			if previous[target] == -2 and banned[target] == 0 and _edge_lengths[edge] <= max_move:
				previous[target] = node
				var _a: bool = queue.append(target)
	return PackedInt32Array()

## Path whose longest move is as short as possible (binary search over edge lengths,
## capped at max_move). Empty when no path fits max_move.
func easiest_path(sources: PackedInt32Array, is_target: PackedByteArray, banned: PackedByteArray, max_move: float) -> PackedInt32Array:
	var best: PackedInt32Array = path_within(sources, is_target, banned, max_move)
	if best.is_empty():
		return best
	var lengths: PackedFloat32Array = _sorted_unique_lengths_up_to(bottleneck_of(best))
	var low: int = 0
	var high: int = lengths.size() - 1
	while low < high:
		var middle: int = (low + high) / 2
		var candidate: PackedInt32Array = path_within(sources, is_target, banned, lengths[middle])
		if candidate.is_empty():
			low = middle + 1
		else:
			high = middle
			best = candidate
	if lengths.size() > 0:
		var final_path: PackedInt32Array = path_within(sources, is_target, banned, lengths[low])
		if not final_path.is_empty():
			best = final_path
	return best

func bottleneck_of(path: PackedInt32Array) -> float:
	var longest: float = 0.0
	for index in range(1, path.size()):
		longest = maxf(longest, positions[path[index - 1]].distance_to(positions[path[index]]))
	return longest

## Distinct routes. Each guide (a mask that bans everything outside one corridor) is tried
## first, since corridors are kept apart; then the easiest route overall; then an open
## search that bans the neighbourhood of every route found so far. A route only
## counts when it stays on average at least separation metres from every counted route,
## so two routes may touch at a junction but not run side by side.
func distinct_routes(
	sources: PackedInt32Array,
	is_target: PackedByteArray,
	exempt: PackedByteArray,
	max_move: float,
	separation: float,
	max_routes: int,
	initial_banned: PackedByteArray = PackedByteArray(),
	guide_bans: Array[PackedByteArray] = []
) -> Array[PackedInt32Array]:
	var base_banned: PackedByteArray = initial_banned if initial_banned.size() == node_count() else _empty_mask()
	var routes: Array[PackedInt32Array] = []
	for guide in guide_bans:
		if routes.size() >= max_routes:
			return routes
		var guided_banned: PackedByteArray = base_banned.duplicate()
		for node in range(node_count()):
			if guide[node] == 1:
				guided_banned[node] = 1
		var guided: PackedInt32Array = easiest_path(sources, is_target, guided_banned, max_move)
		if not guided.is_empty() and _is_apart_from_all(guided, routes, separation, exempt):
			routes.append(guided)
	# The easiest route overall can run between two corridors, so it is tried after them and
	# only counts when it is a separate line.
	if routes.size() < max_routes:
		var easiest: PackedInt32Array = easiest_path(sources, is_target, base_banned, max_move)
		if not easiest.is_empty() and _is_apart_from_all(easiest, routes, separation, exempt):
			routes.append(easiest)

	var banned: PackedByteArray = base_banned.duplicate()
	for route in routes:
		_ban_route(route, separation * 0.5, exempt, banned)
	for _search in range(max_routes * 4):
		if routes.size() >= max_routes:
			break
		var route: PackedInt32Array = easiest_path(sources, is_target, banned, max_move)
		if route.is_empty():
			break
		if _is_apart_from_all(route, routes, separation, exempt):
			routes.append(route)
			_ban_route(route, separation * 0.5, exempt, banned)
		else:
			# A near-duplicate: clear its whole neighbourhood so the next search looks elsewhere.
			_ban_route(route, separation, exempt, banned)
	return routes

func _ban_route(route: PackedInt32Array, half_width: float, exempt: PackedByteArray, banned: PackedByteArray) -> void:
	ban_corridor(route, half_width, exempt, banned)
	for node in route:
		if exempt[node] == 0:
			banned[node] = 1

## Mean horizontal distance from the route's holds to another route at the same heights,
## skipping exempt holds (a shared start every route has to use).
func mean_separation(route: PackedInt32Array, other: PackedInt32Array, exempt: PackedByteArray) -> float:
	var total: float = 0.0
	var counted: int = 0
	for node in route:
		if exempt[node] == 1:
			continue
		total += absf(positions[node].x - route_x_at(other, positions[node].y))
		counted += 1
	return total / float(counted) if counted > 0 else 0.0

func _is_apart_from_all(route: PackedInt32Array, routes: Array[PackedInt32Array], separation: float, exempt: PackedByteArray) -> bool:
	for other in routes:
		if mean_separation(route, other, exempt) < separation:
			return false
	return true

## Marks nodes within separation metres (horizontally) of the route at matching heights.
func ban_corridor(route: PackedInt32Array, separation: float, exempt: PackedByteArray, banned: PackedByteArray) -> void:
	for node in range(node_count()):
		if exempt[node] == 1 or banned[node] == 1:
			continue
		if absf(positions[node].x - route_x_at(route, positions[node].y)) < separation:
			banned[node] = 1

## The route's x at height y, interpolated between its holds (clamped at the ends).
func route_x_at(route: PackedInt32Array, y: float) -> float:
	var lowest: Vector2 = positions[route[0]]
	var highest: Vector2 = positions[route[0]]
	for index in range(route.size()):
		var point: Vector2 = positions[route[index]]
		if point.y > lowest.y:
			lowest = point
		if point.y < highest.y:
			highest = point
		if index == 0:
			continue
		var a: Vector2 = positions[route[index - 1]]
		var b: Vector2 = point
		if (y - a.y) * (y - b.y) <= 0.0 and not is_equal_approx(a.y, b.y):
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return lowest.x if y > lowest.y else highest.x

func empty_mask() -> PackedByteArray:
	return _empty_mask()

func _empty_mask() -> PackedByteArray:
	var mask: PackedByteArray = PackedByteArray()
	var _resize: int = mask.resize(node_count())
	return mask

func _unwind(previous: PackedInt32Array, end_node: int) -> PackedInt32Array:
	var reversed: PackedInt32Array = PackedInt32Array()
	var node: int = end_node
	while node != -1:
		var _a: bool = reversed.append(node)
		node = previous[node]
	reversed.reverse()
	return reversed

func _sorted_unique_lengths_up_to(limit: float) -> PackedFloat32Array:
	var lengths: PackedFloat32Array = PackedFloat32Array()
	for length in _edge_lengths:
		if length <= limit + 0.0001:
			var _a: bool = lengths.append(length)
	lengths.sort()
	var unique: PackedFloat32Array = PackedFloat32Array()
	for length in lengths:
		if unique.is_empty() or length - unique[unique.size() - 1] > 0.0001:
			var _a: bool = unique.append(length)
	return unique

func _build_edges(max_gap_meters: float, max_downward_meters: float) -> void:
	var cell_size: float = max_gap_meters + 0.5
	var grid: Dictionary[Vector2i, PackedInt32Array] = {}
	for node in range(node_count()):
		var cell: Vector2i = Vector2i(floori(positions[node].x / cell_size), floori(positions[node].y / cell_size))
		# Packed arrays are copied out of a Dictionary, so append to a local and store it back.
		var bucket: PackedInt32Array = grid.get(cell, PackedInt32Array())
		var _a: bool = bucket.append(node)
		grid[cell] = bucket

	_edge_offsets = PackedInt32Array()
	_edge_targets = PackedInt32Array()
	_edge_lengths = PackedFloat32Array()
	var _o: bool = _edge_offsets.append(0)
	for node in range(node_count()):
		var origin: Vector2 = positions[node]
		var cell: Vector2i = Vector2i(floori(origin.x / cell_size), floori(origin.y / cell_size))
		var neighbours: PackedInt32Array = PackedInt32Array()
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var key: Vector2i = cell + Vector2i(dx, dy)
				if grid.has(key):
					neighbours.append_array(grid[key])
		neighbours.sort()
		for target in neighbours:
			if target == node:
				continue
			var half: Vector2 = (sizes[node] + sizes[target]) * 0.5
			var delta: Vector2 = positions[target] - origin
			var gap: float = Vector2(maxf(0.0, absf(delta.x) - half.x), maxf(0.0, absf(delta.y) - half.y)).length()
			var downward: float = maxf(0.0, delta.y - half.y)
			if gap <= max_gap_meters and downward <= max_downward_meters:
				var _t: bool = _edge_targets.append(target)
				var _l: bool = _edge_lengths.append(delta.length())
		var _n: bool = _edge_offsets.append(_edge_targets.size())
