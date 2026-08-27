# ADR 0007: Generated Presentation Catalogs

## Status

Accepted

## Context

Generated handholds and hazards previously built placeholder polygons,
animation frames, and collision in the same runtime adapter. Replacing a
placeholder with production art therefore required gameplay code changes and
made it possible for an art scene to accidentally change collision behavior.

Generated positions, physical handhold sizes, hazard collision profiles,
movement, impulses, groups, and signals are gameplay-authoritative. Production
art must be replaceable without changing those values or the deterministic
route-generation sequence.

## Decision

- Keep `GeneratedHandholdAdapter` and `GeneratedHazardSpawnAdapter` as the
  gameplay roots that own collision, targeting, movement, groups, metadata,
  and signals.
- Add a `PresentationRoot/Asset` subtree to each generated adapter.
- Resolve the asset scene through complete typed catalogs keyed by
  `HandholdType` and `GeneratedHazardKind`.
- Require every presentation scene to have a `Node2D` root and reject
  physics collision or joint descendants. Validate both the packed scene and
  its live subtree after presentation scripts enter the scene tree.
- Keep visual offset, scale, rotation, and optional impulse orientation in the
  presentation definition rather than generated gameplay snapshots.
- Keep `physical_size_meters` and hazard collision dimensions independent of
  sprite bounds.
- Keep presentation selection outside generator random-number consumption and
  candidate scoring.

## Consequences

- Each handhold type and hazard kind has one replaceable placeholder scene.
- Static sprites, animated sprites, particles, lights, shaders, and
  `AnimationPlayer` nodes can be added without editing gameplay adapters.
- Composite handhold visuals disappear together when a hold breaks because
  the adapter hides `PresentationRoot`.
- Changing artwork does not require a generator-version bump unless gameplay
  geometry or deterministic output also changes.
- An asset whose silhouette differs substantially from its gameplay collision
  still requires deliberate gameplay tuning rather than automatic collision
  resizing.
