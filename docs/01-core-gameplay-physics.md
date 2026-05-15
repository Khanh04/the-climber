# Module 1: Core Gameplay and Physics System

## Owner

Gameplay Programmer / Physics Engineer

## Goal

Build the player interaction loop around two-hand gripping, pendulum-style movement, and a readable failure state driven by physics instead of canned animation.

## MVP Scope

- Two grip inputs mapped to the left and right screen halves, ragdoll gripping, one-hand stamina drain, fall camera, recoverable run-end state, and first-run onboarding.
- The launch touch baseline is simple two-thumb grip alternation. No visible joystick, tap-to-target mode, or multi-step gesture grammar is required.
- Desktop controls exist only as a development/testing fallback.
- Hidden smart reach assist is allowed if it preserves fairness. Hold-drag nudge and accelerometer tilt assist stay optional until the pure hold and release baseline is validated.

## Core Requirements

### Movement and Controls

- Inputs are limited to `Left Grip` and `Right Grip`.
- On mobile, each grip input maps to its screen half. Do not require a separate visible joystick or momentum pad.
- While a grip input is held, the game casts a check for a valid reachable handhold.
- If multiple holds are valid, hidden smart reach assist may bias toward the fairest reachable upward-progressing hold without changing the player's intent.
- If the check intersects a valid handhold, the corresponding hand locks to that point using a physics joint.
- Releasing one hand shifts the character into pendulum-style swinging.
- The launch baseline derives swing from grip timing, body motion, and route geometry rather than a separate momentum gesture layer.
- Hanging by a single hand drains stamina.
- If stamina reaches zero while only one hand is attached, that grip breaks automatically.

### First-Run Onboarding

- The first run should open in a low-pressure route slice with obvious reachable holds and no early demand for advanced timing.
- Teach only left grip, right grip, and release before surfacing optional settings or deeper economy systems.
- Delay or disable early Chaser pressure until the player clears the first grip prompts or reaches a safe height milestone.
- Tutorial prompts must remain readable with placeholder presentation and should not require text-heavy explanations during active physics.

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
- Treat smart reach assist as a hidden comfort rule only. It may prefer fair reachable holds, but it must never grab through hazards, across unreasonable gaps, or onto misleading off-route geometry.

### Onboarding Flow

- Gate tutorial prompts, Chaser start, and other first-run-only affordances through explicit typed run state rather than scattered scene flags.
- Drive onboarding prompts from actual successful grip and release events so the tutorial stays correct as control tuning changes.

### Stamina Rules

- Drain only when exactly one hand is attached.
- Pause drain when both hands are secured.
- Phase 2 runtime does not passively regenerate stamina; restore stamina only through explicit run start, retry, or rescue flows unless later balancing changes require otherwise.
- Ensure forced break events use the same release path as manual input release to avoid divergent states.

### Physics Fairness

- Treat the skeleton-driven collision bodies as gameplay authority.
- Treat skin visuals as presentation authority only.
- Validate that every cosmetic can be swapped without changing the physics profile.
- The current implementation applies player cosmetics only under `CosmeticVisualRoot`, `LeftHandCosmeticRoot`, and `RightHandCosmeticRoot`; the applicator owns only presentation nodes and revalidates visual roots after applying a loadout.

### Camera Behavior

- Favor comedic readability over strict competitive framing when the player falls.
- Delay any death UI until the fall has been fully observed or until the run-ending impact has clearly resolved.
- Present continue or rescue prompts after the fall beat lands, not during active physics comedy.

## Post-MVP

- Hold-drag nudge if mobile playtests prove the pure hold and release baseline needs a comfort layer.
- Accelerometer tilt assist if the simpler touch baseline validates first.
- Accessibility presets for grip zones, control size, haptic intensity, and input sensitivity.
- Additional rescue categories for non-lethal slapstick hazards if playtests show they improve retention.

## Open Questions

- What is the target average stamina duration for a one-hand hang in the first 100 meters?
- Should first-run Chaser pressure be fully disabled for the tutorial opener or simply delayed until a first height milestone?
- If passive stamina regeneration is added later, should it happen only while both hands are attached or also while fully detached during a fall beat?
- What minimum fall distance qualifies for the comedic camera follow before the result UI can appear?

## Risks

- Two-hand physics can become unstable if joint creation and cleanup are not tightly managed.
- Adding extra gestures too early can obscure whether the base two-thumb loop is actually fun.
- Heavy camera smoothing can fight with responsiveness if not damped differently during climb versus fall states.

## Suggested First Tasks

1. Define the ragdoll scene structure and skeleton collision ownership.
2. Implement per-hand grip acquisition and release.
3. Add one-hand stamina drain and forced release.
4. Prototype first-run onboarding prompts and Chaser grace behavior around the two-thumb baseline.
5. Implement camera follow behavior for climb and fall states, then tune pendulum movement around real touch playtests.
