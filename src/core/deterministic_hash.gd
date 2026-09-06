class_name DeterministicHash
extends RefCounted

## Version-stable 32-bit FNV-1a over the string's code points, folded to a
## non-negative 31-bit int. Godot's built-in String.hash() carries no
## cross-version stability guarantee, so every seeded generation decision must
## route through this -- an engine upgrade must never reshuffle generated routes.
static func of_string(seed_text: String) -> int:
	var hash_value: int = 2166136261
	for character_index in range(seed_text.length()):
		hash_value = hash_value ^ seed_text.unicode_at(character_index)
		hash_value = (hash_value * 16777619) & 0x7fffffff

	return hash_value

## Deterministic float in [0.0, 1.0) derived from of_string().
static func unit_float(seed_text: String) -> float:
	return float(of_string(seed_text) % 1000000) / 1000000.0
