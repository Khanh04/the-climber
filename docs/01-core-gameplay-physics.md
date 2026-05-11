# Module 1: Core Gameplay and Physics System

## Owner

Gameplay Programmer / Physics Engineer

## Goal

Build the player interaction loop around two-hand gripping, pendulum-style movement, and a readable failure state driven by physics instead of canned animation.

## MVP Scope

- Two grip inputs, virtual momentum control, ragdoll gripping, one-hand stamina drain, fall camera, and recoverable run-end state.
- Desktop controls exist only as a development/testing fallback.
- Accelerometer tilt assist is optional until the virtual control baseline feels reliable.

## Core Requirements

### Movement and Controls

- Inputs are limited to `Left Grip` and `Right Grip`.
- Each grip input maps to either a screen half or a dedicated virtual button.
- While a grip input is held, the game casts a check for a valid handhold.
- If the check intersects a valid handhold, the corresponding hand locks to that point using a physics joint.
- Releasing one hand shifts the character into pendulum-style swinging.
- Mobile-first swing momentum uses virtual controls as the baseline, with accelerometer tilt assist as an optional enhancement.
- Hanging by a single hand drains stamina.
- If stamina reaches zero while only one hand is attached, that grip breaks automatically.

### Player Character

- Use `Skeleton2D`, `Bone2D`, and `PinJoint2D` for the ragdoll setup.
- All gameplay collision shapes must remain attached to the base skeleton only.
- Cosmetics must be visual-only sprite swaps.
- Cosmetics must not affect collision boundaries, friction, mass, or any other gameplay-relevant value.

### Game Loop and Camera

- The run is an endless vertical climb.
- There are no checkpoints.
- Hitting the bottom of the screen ends the run.
- Contact with a lethal hazard ends the run.
- `Camera2D` should use heavy smoothing.
- On falls, the camera must follow the full descent instead of snapping immediately to a death result state.
- Death resolution should pass through a recoverable run-ending state so the shared rescue mechanic can offer either a Rewarded Continue or an inventory Mulligan Drone when eligible.

### Death and Rescue Eligibility

| Run-ending event | MVP rescue eligibility | Notes |
| --- | --- | --- |
| Bottom-screen fall | Eligible | Let the camera follow the descent before showing the rescue prompt. |
| Stamina-caused grip break leading to fall | Eligible | Counts as a fall recovery, not a stamina refill. |
| General missed grip / physics fall | Eligible | Eligible only once per run through the shared rescue mechanic. |
| Chaser contact | Not eligible | Chaser remains the final anti-camping fail state. |
| Lethal hazard contact | Not eligible by default | Individual hazards can opt in later if they are tuned as slapstick hazards rather than hard kills. |
| Already rescued this run | Not eligible | Rewarded Continue and Mulligan Drone share this limit. |

## Implementation Notes

### Grip Detection

- Define a handhold validation layer or group early so grip checks remain deterministic.
- Keep left-hand and right-hand attachment state independent.
- Store the currently attached hold and joint reference per hand to simplify release and forced-break logic.
- Normalize mobile touch and desktop debug controls into the same typed gameplay intent layer before player systems consume them.

### Stamina Rules

- Drain only when exactly one hand is attached.
- Pause drain when both hands are secured.
- Phase 2 runtime does not passively regenerate stamina; restore stamina only through explicit run start, retry, or rescue flows unless later balancing changes require otherwise.
- Ensure forced break events use the same release path as manual input release to avoid divergent states.

### Physics Fairness

- Treat the skeleton-driven collision bodies as gameplay authority.
- Treat skin visuals as presentation authority only.
- Validate that every cosmetic can be swapped without changing the physics profile.

### Camera Behavior

- Favor comedic readability over strict competitive framing when the player falls.
- Delay any death UI until the fall has been fully observed or until the run-ending impact has clearly resolved.
- Present continue or rescue prompts after the fall beat lands, not during active physics comedy.

## Post-MVP

- Accelerometer tilt assist if virtual controls validate the core loop first.
- Accessibility presets for grip buttons, control size, and input sensitivity.
- Additional rescue categories for non-lethal slapstick hazards if playtests show they improve retention.

## Open Questions

- What is the target average stamina duration for a one-hand hang in the first 100 meters?
- If passive stamina regeneration is added later, should it happen only while both hands are attached or also while fully detached during a fall beat?
- What minimum fall distance qualifies for the comedic camera follow before the result UI can appear?

## Risks

- Two-hand physics can become unstable if joint creation and cleanup are not tightly managed.
- Accelerometer-driven momentum may need fallback tuning for desktop testing and accessibility.
- Heavy camera smoothing can fight with responsiveness if not damped differently during climb versus fall states.

## Suggested First Tasks

1. Define the ragdoll scene structure and skeleton collision ownership.
2. Implement per-hand grip acquisition and release.
3. Add one-hand stamina drain and forced release.
4. Tune pendulum movement and momentum input.
5. Implement camera follow behavior for climb and fall states.