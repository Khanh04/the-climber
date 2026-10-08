extends SceneTree

## Dumps generated chunks to JSON for tools/generation/analyze.py.
## Usage: godot --headless --path . -s res://tools/generation/dump_chunks.gd -- <out.json> <seed_count> <chunk_count>
## Seeds are fixed run keys, so output is reproducible.

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("usage: -- <out.json> <seed_count> <chunk_count>")
		quit(1)
		return
	var tuning: GenerationTuning = GenerationTuning.new()
	var runs: Array = []
	for seed_index: int in range(int(args[1])):
		var seed_key: String = "%s:run:%d-%d" % [DailySeedKey.GENERATOR_VERSION, 1000 + seed_index * 7919, seed_index]
		var generator: DailyChunkGenerator = DailyChunkGenerator.new(tuning)
		var chunks: Array = []
		for chunk_index: int in range(int(args[2])):
			var started_usec: int = Time.get_ticks_usec()
			var layout: GeneratedChunkLayout = generator.build_chunk(seed_key, chunk_index)
			var dumped: Dictionary = _dump_layout(layout)
			dumped["ms"] = float(Time.get_ticks_usec() - started_usec) / 1000.0
			chunks.append(dumped)
		runs.append({"seed": seed_key, "chunks": chunks})
	var file: FileAccess = FileAccess.open(args[0], FileAccess.WRITE)
	var _stored: bool = file.store_string(JSON.stringify({"chunk_width": tuning.chunk_width_meters, "segment_height": tuning.segment_height_meters, "runs": runs}))
	file.close()
	quit()

func _dump_layout(layout: GeneratedChunkLayout) -> Dictionary:
	var holds: Array = []
	for handhold: GeneratedHandholdSocket in layout.handholds:
		holds.append({
			"id": String(handhold.hold_id), "x": handhold.local_position.x, "y": handhold.local_position.y,
			"w": handhold.physical_size_meters.x, "h": handhold.physical_size_meters.y,
			"type": HandholdType.to_label(handhold.handhold_type), "role": RouteRole.to_label(handhold.route_role),
			"safe": layout.safe_path_hold_ids.has(String(handhold.hold_id)),
		})
	var hazards: Array = []
	for hazard: GeneratedHazardSocket in layout.hazard_sockets:
		hazards.append({"kind": GeneratedHazardKind.to_label(hazard.hazard_kind), "x": hazard.local_position.x, "y": hazard.local_position.y})
	var pickups: Array = []
	for pickup: GeneratedPickupSocket in layout.pickup_sockets:
		pickups.append({"x": pickup.local_position.x, "y": pickup.local_position.y})
	return {
		"index": layout.chunk_index, "band": ChunkDifficultyBand.to_label(layout.difficulty_band),
		"chunk_type": ChunkType.to_label(layout.chunk_type), "start_h": layout.start_height_meters,
		"safe_order": Array(layout.safe_path_hold_ids),
		"holds": holds, "hazards": hazards, "pickups": pickups,
	}
