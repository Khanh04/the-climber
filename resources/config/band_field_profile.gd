class_name BandFieldProfile
extends Resource

## Hold-field generation knobs for one difficulty band (see docs/adr/0011-hold-field-generation.md).

## Minimum centre distance between holds inside a route corridor.
@export var corridor_hold_spacing_meters: float = 0.85
## Half-width of a route corridor at full strength.
@export var corridor_half_width_meters: float = 0.9
## Minimum centre distance between the sparse scatter holds that connect corridors.
@export var scatter_hold_spacing_meters: float = 1.8
## Number of wandering route corridors across the wall.
@export var corridor_count: int = 4
## Longest move (hold centre to hold centre) allowed on a counted route.
@export var max_route_move_meters: float = 1.3
## The easiest route must still contain a move at least this long, so a band cannot
## collapse into an easier one. 0 disables the floor.
@export var min_easiest_route_move_meters: float = 0.0
## Distinct routes (separated by route_separation_meters) every chunk must offer.
@export var required_route_count: int = 3
## Upper bound on holds per chunk; each hold is a physics node at runtime.
@export var max_hold_count: int = 90
## Hazards placed per chunk.
@export var hazard_count: int = 1
## Share of hazards drawn from the lethal pool (spike, rock, log).
@export var lethal_hazard_share: float = 0.25
## Coins placed per chunk.
@export var coin_count: int = 2
## Share of holds off every counted route kept after pruning (route holds always stay).
## Holds that link two routes are kept first, then holds next to one route.
@export var extra_hold_keep_ratio: float = 0.0
## Chance an off-route hold gets a special type from the band's optional pool.
@export var special_hold_chance: float = 0.15

func is_valid() -> bool:
	return corridor_hold_spacing_meters > 0.0 \
		and corridor_half_width_meters > 0.0 \
		and scatter_hold_spacing_meters >= corridor_hold_spacing_meters \
		and corridor_count >= 2 \
		and max_route_move_meters > corridor_hold_spacing_meters \
		and min_easiest_route_move_meters >= 0.0 \
		and min_easiest_route_move_meters < max_route_move_meters \
		and required_route_count >= 1 \
		and required_route_count <= corridor_count \
		and max_hold_count >= 20 \
		and hazard_count >= 0 \
		and lethal_hazard_share >= 0.0 and lethal_hazard_share <= 1.0 \
		and coin_count >= 0 \
		and special_hold_chance >= 0.0 and special_hold_chance <= 1.0 \
		and extra_hold_keep_ratio >= 0.0 and extra_hold_keep_ratio <= 1.0

func validate() -> void:
	assert_valid()

func assert_valid() -> void:
	Validation.require_condition(corridor_hold_spacing_meters > 0.0, "BandFieldProfile corridor hold spacing must be positive.")
	Validation.require_condition(corridor_half_width_meters > 0.0, "BandFieldProfile corridor half-width must be positive.")
	Validation.require_condition(scatter_hold_spacing_meters >= corridor_hold_spacing_meters, "BandFieldProfile scatter spacing cannot be tighter than corridor spacing.")
	Validation.require_condition(corridor_count >= 2, "BandFieldProfile needs at least two corridors.")
	Validation.require_condition(max_route_move_meters > corridor_hold_spacing_meters, "BandFieldProfile max route move must exceed corridor hold spacing.")
	Validation.require_condition(min_easiest_route_move_meters >= 0.0, "BandFieldProfile min easiest-route move cannot be negative.")
	Validation.require_condition(min_easiest_route_move_meters < max_route_move_meters, "BandFieldProfile min easiest-route move must be below the max route move.")
	Validation.require_condition(required_route_count >= 1, "BandFieldProfile requires at least one route.")
	Validation.require_condition(required_route_count <= corridor_count, "BandFieldProfile cannot require more routes than corridors.")
	Validation.require_condition(max_hold_count >= 20, "BandFieldProfile max hold count must be at least 20.")
	Validation.require_condition(hazard_count >= 0, "BandFieldProfile hazard count cannot be negative.")
	Validation.require_condition(lethal_hazard_share >= 0.0 and lethal_hazard_share <= 1.0, "BandFieldProfile lethal hazard share must be in [0, 1].")
	Validation.require_condition(coin_count >= 0, "BandFieldProfile coin count cannot be negative.")
	Validation.require_condition(special_hold_chance >= 0.0 and special_hold_chance <= 1.0, "BandFieldProfile special hold chance must be in [0, 1].")
	Validation.require_condition(extra_hold_keep_ratio >= 0.0 and extra_hold_keep_ratio <= 1.0, "BandFieldProfile extra hold keep ratio must be in [0, 1].")
