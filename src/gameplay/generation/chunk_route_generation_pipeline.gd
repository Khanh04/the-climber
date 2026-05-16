class_name ChunkRouteGenerationPipeline
extends RefCounted

const ChunkDifficultyBandScript = preload("res://src/gameplay/generation/chunk_difficulty_band.gd")
const ChunkRouteLayoutEmitterScript: GDScript = preload("res://src/gameplay/generation/chunk_route_layout_emitter.gd")
const ChunkRoutePathSolutionScript = preload("res://src/gameplay/generation/chunk_route_path_solution.gd")
const ChunkRoutePathSolverScript = preload("res://src/gameplay/generation/chunk_route_path_solver.gd")
const ChunkRoutePlanBuilderScript = preload("res://src/gameplay/generation/chunk_route_plan_builder.gd")
const ChunkRoutePlanScript = preload("res://src/gameplay/generation/chunk_route_plan.gd")
const ChunkRoutePopulationBuilderScript: GDScript = preload("res://src/gameplay/generation/chunk_route_population_builder.gd")
const ChunkRouteSlotScript = preload("res://src/gameplay/generation/chunk_route_slot.gd")
const GeneratedChunkLayoutScript = preload("res://src/gameplay/generation/generated_chunk_layout.gd")
const GenerationTuningScript = preload("res://resources/config/generation_tuning.gd")
const RouteAnchorGraphBuilderScript = preload("res://src/gameplay/generation/route_anchor_graph_builder.gd")
const RouteAnchorGraphScript = preload("res://src/gameplay/generation/route_anchor_graph.gd")
const RouteValidationTuningScript = preload("res://resources/config/route_validation_tuning.gd")

var _tuning: GenerationTuningScript
var _plan_builder: ChunkRoutePlanBuilderScript
var _path_solver: ChunkRoutePathSolverScript
var _population_builder: RefCounted
var _layout_emitter: RefCounted

func _init(tuning_value: GenerationTuningScript) -> void:
	Validation.require_condition(tuning_value != null, "ChunkRouteGenerationPipeline requires generation tuning.")
	_tuning = tuning_value
	_tuning.assert_valid()
	_plan_builder = ChunkRoutePlanBuilderScript.new()
	_path_solver = ChunkRoutePathSolverScript.new()
	var population_builder_variant: Variant = ChunkRoutePopulationBuilderScript.new()
	Validation.require_condition(population_builder_variant is RefCounted, "ChunkRouteGenerationPipeline must create a route population builder.")
	_population_builder = population_builder_variant
	var layout_emitter_variant: Variant = ChunkRouteLayoutEmitterScript.new(_tuning)
	Validation.require_condition(layout_emitter_variant is RefCounted, "ChunkRouteGenerationPipeline must create a route layout emitter.")
	_layout_emitter = layout_emitter_variant

func build_layout(
	seed_key: String,
	chunk_index: int,
	route_slot: int,
	difficulty_band: int,
	route_validation_result: RefCounted = null,
	selected_candidate_attempt_index: int = 0,
	candidate_score: float = 0.0
) -> GeneratedChunkLayoutScript:
	Validation.require_condition(seed_key != "", "ChunkRouteGenerationPipeline requires a seed key.")
	Validation.require_condition(chunk_index >= 0, "ChunkRouteGenerationPipeline chunk index cannot be negative.")
	ChunkRouteSlotScript.assert_valid(route_slot)
	ChunkDifficultyBandScript.assert_valid(difficulty_band)
	Validation.require_condition(selected_candidate_attempt_index >= 0, "ChunkRouteGenerationPipeline candidate attempt index cannot be negative.")
	Validation.require_condition(not is_nan(candidate_score), "ChunkRouteGenerationPipeline candidate score cannot be NaN.")

	var plan: ChunkRoutePlanScript = _plan_builder.build_plan(seed_key, chunk_index, route_slot, difficulty_band)
	var first_row_height_meters: float = _calculate_route_first_row_height_meters(plan)
	var anchor_graph_builder: RouteAnchorGraphBuilderScript = RouteAnchorGraphBuilderScript.new(
		_tuning.chunk_width_meters,
		_calculate_route_row_step_height_meters(plan, first_row_height_meters),
		first_row_height_meters
	)
	var anchor_graph: RouteAnchorGraphScript = anchor_graph_builder.build_graph(plan)
	var path_solution: ChunkRoutePathSolutionScript = _path_solver.solve(plan, anchor_graph)
	Validation.require_condition(path_solution.is_valid, path_solution.failure_reason)

	var population_variant: Variant = _population_builder.call("populate", plan, anchor_graph, path_solution)
	Validation.require_condition(population_variant is RefCounted, "ChunkRouteGenerationPipeline population builder must return a RefCounted population.")
	var population: RefCounted = population_variant
	var layout_variant: Variant = _layout_emitter.call(
		"emit_layout",
		seed_key,
		plan,
		population,
		route_validation_result,
		selected_candidate_attempt_index,
		candidate_score
	)
	Validation.require_condition(layout_variant is GeneratedChunkLayoutScript, "ChunkRouteGenerationPipeline emitter must return a generated chunk layout.")
	var layout_ref: RefCounted = layout_variant
	var layout: GeneratedChunkLayoutScript = layout_ref as GeneratedChunkLayoutScript
	return layout

func _calculate_route_first_row_height_meters(plan: ChunkRoutePlanScript) -> float:
	Validation.require_condition(plan != null, "ChunkRouteGenerationPipeline row step requires a route plan.")
	plan.assert_valid()
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	Validation.require_condition(
		_tuning.opener_first_row_height_meters < route_validation_tuning.max_move_distance_meters,
		"ChunkRouteGenerationPipeline first route row must be inside the move envelope."
	)
	return _tuning.opener_first_row_height_meters

func _calculate_route_row_step_height_meters(plan: ChunkRoutePlanScript, first_row_height_meters: float) -> float:
	Validation.require_condition(plan != null, "ChunkRouteGenerationPipeline row step requires a route plan.")
	plan.assert_valid()
	Validation.require_condition(first_row_height_meters > 0.0, "ChunkRouteGenerationPipeline first row height must be positive.")
	Validation.require_condition(plan.get_row_count() >= 2, "ChunkRouteGenerationPipeline route plans require at least two rows.")
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	var top_row_height_meters: float = _tuning.segment_height_meters - _calculate_route_top_padding_meters(first_row_height_meters)
	var row_step_height_meters: float = (top_row_height_meters - first_row_height_meters) / float(plan.get_row_count() - 1)
	Validation.require_condition(row_step_height_meters > 0.0, "ChunkRouteGenerationPipeline route row step must be positive.")
	Validation.require_condition(
		row_step_height_meters < route_validation_tuning.max_move_distance_meters,
		"ChunkRouteGenerationPipeline route row step must stay inside the move envelope."
	)
	return row_step_height_meters

func _calculate_route_top_padding_meters(first_row_height_meters: float) -> float:
	Validation.require_condition(first_row_height_meters > 0.0, "ChunkRouteGenerationPipeline top padding requires a positive first row height.")
	var route_validation_tuning: RouteValidationTuningScript = _get_route_validation_tuning()
	var reachable_top_padding_meters: float = route_validation_tuning.max_move_distance_meters - first_row_height_meters - 0.05
	Validation.require_condition(
		reachable_top_padding_meters > 0.0,
		"ChunkRouteGenerationPipeline route seam padding must leave a reachable next entry row."
	)
	return minf(_tuning.opener_top_padding_meters, reachable_top_padding_meters)

func _get_route_validation_tuning() -> RouteValidationTuningScript:
	Validation.require_condition(_tuning.route_validation_tuning != null, "ChunkRouteGenerationPipeline requires route validation tuning.")
	Validation.require_condition(
		_tuning.route_validation_tuning is RouteValidationTuningScript,
		"ChunkRouteGenerationPipeline route validation tuning must use RouteValidationTuning resources."
	)
	var typed_tuning: RouteValidationTuningScript = _tuning.route_validation_tuning as RouteValidationTuningScript
	return typed_tuning