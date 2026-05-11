# Coding Standards

## Language

- Use Godot 4.4+ typed GDScript.
- Every function must declare parameter and return types.
- Every property must declare a type.
- Local variables must declare a type when the type is not obvious from construction.
- Avoid `Variant` except at Godot or serialization boundaries.

## Strict Domain Data

- Use typed classes or typed Resources for structured domain data.
- Do not use loose dictionaries for gameplay models, economy models, run state, or generated content.
- Dictionaries are allowed only at boundaries such as Godot date APIs, persistence, or platform SDK payloads.
- Boundary dictionaries must be parsed into typed values immediately and validated.

## No Fallback Policy

- Do not silently substitute default values for invalid configuration.
- Do not catch and ignore errors.
- Do not skip missing assets, missing Resources, missing nodes, or unsupported enum values.
- Fail fast with a clear message when required project state is invalid.

## SOLID-Oriented Rules

- Keep each script focused on one responsibility.
- Prefer composition over inheritance for gameplay rules.
- Keep platform SDK calls out of gameplay code.
- Inject or assign typed dependencies through scenes, Resources, or adapters.
- Make pure gameplay rules testable without loading full scenes whenever possible.

## Config Resources

- Use typed `Resource` classes for tuning and configuration.
- Shared tuning/config scripts belong under `resources/config/`.
- Config Resources with constraints must expose `validate()`, `is_valid()`, and `assert_valid()`.
- `validate()` must fail fast by delegating to explicit validation checks. Do not silently repair invalid values.

## Platform Boundaries

- Typed adapters under `src/platform/` define the only allowed entry points for rewarded ads, local storage, UTC clock/date, haptics, app lifecycle, purchases, subscriptions, and sharing.
- Boundary payloads may use dictionaries only at the adapter edge. Convert them to typed models immediately.
- Save schema/version checks are mandatory. Unsupported versions, missing required fields, and corrupt persisted values must fail fast.

## Forbidden Patterns

```gdscript
var run_state = {}
var config = value if value != null else default_config
func calculate_reward(data):
    pass
```

Use typed classes, explicit validation, and typed signatures instead.