# Module 5: Meta and Viral Features

## Owner

Integrations Programmer / Marketing Tech

## Goal

Build replayable, shareable, and community-visible systems that amplify memorable failures and friend-level comparison.

## MVP Scope

- Detect major falls and expose a lightweight share prompt after the fall resolves.
- Android v1.0 share baseline is a screenshot or engine-composed share card, not native rolling video capture.
- Save enough local fall context to support future replay and ghost work without backend, account, or always-on recording requirements.
- Defer facecam, full rolling video export, friend ghosts, persistent fall sprays, and other backend-heavy comparison features until after launch.

## Core Requirements

### Social Capture

- Monitor `linear_velocity` and altitude loss.
- If a major fall is detected, preserve lightweight local context for a screenshot or share-card payload.
- After the fall and any rescue or result beats resolve, prompt the player with a native share action.
- The launch share should target a screenshot or engine-composed card sized for short-form social posting.

### Facecam Overlay

- Provide a toggleable UI element.
- The overlay activates the device front-facing camera.
- The camera feed appears in a screen corner while the player records.
- Facecam is post-launch unless platform integration cost, privacy posture, and device performance all remain low-risk.

### Asynchronous Multiplayer

#### Ghosts

- Download friend death coordinates for the current daily seed.
- Display them as chalk outlines or tombstones.
- Friend ghosts are post-launch unless the backend and account system already exist.

#### Fall Sprays

- If equipped, the player leaves a spray-paint decal at the exact death coordinates.
- Sprays accumulate over time to build a visible history of failures near the tower base.
- Persistent fall sprays are post-launch and require moderation and retention rules.

#### Deferred Global Features

- Global leaderboards and number-one-player lead ghosts are not part of the MVP scope.
- If added later, lead ghosts must remain faint, non-colliding, and non-authoritative.

## Implementation Notes

### Highlight Capture

- Capture a still image or share-card payload by default rather than writing full-session video.
- Define a fall threshold using a combination of downward velocity, lost altitude, and outcome severity.
- Keep the share prompt post-event so it does not interrupt the fall itself.
- Log the fall trigger event even if the first release only shares a screenshot.
- Do not make the launch share flow depend on account login, backend storage, or camera permissions.

### Camera and Privacy

- Facecam requires explicit user consent and platform-specific permission handling.
- The system should degrade gracefully when camera permissions are denied.

### Async Data Model

- Associate ghosts and sprays with the active UTC daily seed and generator version.
- Store only lightweight state for non-interactive social objects.
- Keep all ghost data non-authoritative and non-colliding to avoid gameplay side effects.

## Post-MVP

- Native rolling replay capture and TikTok / Reels export.
- Facecam overlay with explicit permission handling.
- Friend death ghosts tied to the UTC daily seed and generator version.
- Fall sprays with storage limits, content moderation, and expiry policies.

## Open Questions

- Should the first share feature use a raw screenshot, a branded share card, or a hybrid overlay?
- What account/friends system will provide friend death coordinates?
- How long should fall sprays persist, and are custom player-created spray images allowed?

## Risks

- Native video capture and social-share flows are heavily platform-dependent.
- Facecam support may be limited by device permissions, performance, and store-policy constraints.
- Persistent sprays can create content moderation and storage concerns if users can customize them freely.
- Global competition features can expand infrastructure and moderation scope quickly, so they should remain deferred until the core loop proves retention.

## Suggested First Tasks

1. Define the event trigger for a highlight-worthy fall.
2. Prototype a screenshot and share-card composition flow for the Android launch slice.
3. Define the lightweight local fall context needed for future replay and ghost expansion.
4. Scope native OS share requirements for Android before exploring facecam or video capture.
5. Define moderation and retention rules for post-launch user-generated social features.
