# ADR 0012: Player Appearances Fit The Collision To Their Art

## Status

Accepted. Relaxes the "cosmetics must never modify collision shapes" rule in
`CLAUDE.md` and `docs/engineering/ARCHITECTURE.md`.

## Context

The player is a Head `RigidBody2D` plus two arm bodies. The arms already got
collision traced from their pixels when an appearance was applied, but the
head kept one scene-authored 70x70 box and fixed shoulder sockets for every
character. Head art differs per character (Spartan's helmet is 54 px wide,
Webhead's mask 72 px), so the hitbox stuck out past the drawn head or fell
short of it, and arms floated beside narrow heads.

## Decision

`PlayerAppearanceApplicator` measures the drawn head (the face sprite's
texture is already cropped to its opaque pixels) and calls
`PlayerCharacter.configure_head_collision`, which:

- resizes and re-centres the head `RectangleShape2D` to the drawn rect, on a
  per-instance copy of the shape (the scene sub-resource is shared);
- moves both shoulder sockets onto the box's side edges, inset by
  `SHOULDER_INSET_PIXELS`. Hand anchors and the body-arm joints are socket
  children and follow.

The head stays a rectangle rather than a traced silhouette: a lopsided
silhouette gives a resting head a preferred tilt.

Cosmetics still never change mass, friction, collision layers or gameplay
tuning.

## Consequences

- Characters differ in feel: hitbox size and where reach starts follow the
  art. Spartan's sockets sit at about +/-24 px instead of +/-32 px, so its
  reach starts about 8 px further in.
- `RouteValidationTuning.player_body_width_meters` must cover the widest
  appearance; `test_tuning_validation` derives it from the catalog.
- Adding a character needs no hand-tuned collision numbers; the scene tests
  check the head fit and the arm fit for every catalog appearance.
