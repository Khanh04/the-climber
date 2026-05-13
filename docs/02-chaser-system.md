# Module 2: The Chaser

## Owner

Systems Programmer / Content Designer

## Goal

Introduce a rising environmental kill-zone that prevents stalling while preserving tension through dynamic pacing.

## MVP Scope

- A single full-width rising `Area2D` kill-zone with one default visual theme and one audio profile.
- Chaser contact is final and not eligible for Rewarded Continue or Mulligan Drone rescue.
- Rubber-banding uses simple, inspectable thresholds before adding more advanced pacing curves.

## Core Requirements

### Chaser Behavior

- The Chaser constantly rises from the bottom of the screen.
- It is implemented as an `Area2D` spanning the full level width.
- Any player contact with the Chaser immediately ends the run.

### Rubber-Banding

- If the player remains at roughly the same Y position for more than 5 seconds, the Chaser speeds up.
- If the player is climbing rapidly, the Chaser slows down.
- The goal is tension maintenance, not forcing a pure speedrun.
- Initial tuning target: treat less than 2 meters of vertical progress over 5 seconds as camping.
- Initial tuning target: treat more than 8 meters of vertical progress over 5 seconds as rapid climbing.
- Clamp Chaser speed between a readable minimum pressure speed and a maximum speed that still gives the player time to react.
- Current Phase 6 tuning uses a 5 second sample window, 2 meter camping threshold, 8 meter rapid-climb threshold, and a clamped 1.5 to 5.0 meters-per-second rise-speed envelope.

### Cosmetics and Audio

- The `Area2D` visual can be swapped through player loadout.
- Supported examples include Rising Void, Hot Coffee, Glitch / Code, and Plastic Ball Pit.
- Each cosmetic has a distinct spatial audio signature.
- Audio intensity should increase as the Chaser approaches the player.
- The current Phase 6 slice uses a checked-in default Chaser loop asset through an `AudioStreamPlayer2D`, with pitch and volume driven by feedback intensity.

## Implementation Notes

### Pacing Model

- Track recent player vertical progress over time rather than relying on instantaneous velocity only.
- Use a bounded speed range for the Chaser so rubber-banding remains predictable.
- Separate base speed from temporary pressure modifiers so balancing remains data-driven.
- The initial implementation uses typed Chaser tuning data for base rise speed, camping bonus speed, rapid-climb slowdown, and spawn offset.
- The current implementation also exposes a typed feedback snapshot containing pace state, recent vertical progress, rise speed, and normalized speed intensity for presentation and playtest tooling.

### Kill Logic

- Keep the Chaser collision behavior simple and authoritative.
- Death on contact should bypass partial damage logic and immediately resolve the run state.
- Chaser death should still allow the fall/death camera beat if visually useful, but it should not offer rescue.
- The current run-scene integration resolves Chaser contact as `CHASER_CONTACT`, releases active grips, forces falling physics, and ends the run without rescue eligibility.

### Presentation Layer

- Decouple the visual theme from the kill-zone logic.
- Treat cosmetic selection as a theme bundle containing visuals, particles, and an audio profile.
- Current feedback intensity blends pace-driven pressure and player proximity to drive Chaser alpha and optional audio modulation without moving game rules into the scene.

## Post-MVP

- Multiple Chaser themes such as Hot Coffee, Glitch / Code, and Plastic Ball Pit.
- Per-theme spatial audio, particles, and screen-edge warning treatments.
- More nuanced pacing curves based on run altitude, player skill, and recent near-death events.

## Open Questions

- What should the initial Chaser spawn distance be below the player?

## Risks

- Over-aggressive speed-up can make the system feel unfair instead of anti-camping.
- Under-tuned slowdown can remove urgency for skilled players.
- Spatial audio needs careful mixing so it communicates threat without becoming fatiguing.

## Suggested First Tasks

1. Playtest the current camping and rapid-climb thresholds against slow, average, and expert climb cases.
2. Choose and tune the initial spawn distance now that it is exposed through validated config.
3. Refine or replace the current default Chaser loop asset once audio direction is locked.
4. Use the run-scene pacing snapshot and feedback intensity hooks to capture playtest notes for camping and near-contact pressure.
5. Evaluate whether first-run onboarding needs a delayed Chaser start in a later phase.