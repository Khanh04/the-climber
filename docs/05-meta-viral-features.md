# Module 5: Meta and Viral Features

## Owner

Integrations Programmer / Marketing Tech

## Goal

Build replayable, shareable, and community-visible systems that amplify memorable failures and friend-level comparison.

## MVP Scope

- Detect major falls and expose a lightweight share prompt after the fall resolves.
- Save enough local event context to support future replay work, but do not require native video capture for MVP.
- Defer facecam, full rolling video export, friend ghosts, and persistent fall sprays until the core loop proves retention.

## Core Requirements

### Social Capture

- Monitor `linear_velocity` and altitude loss.
- If a major fall is detected, automatically preserve the last 10 seconds of gameplay.
- After the fall, prompt the player with a share action for TikTok or Reels.
- MVP can start with a shareable screenshot or lightweight clip stub if full native recording is not ready.

### Facecam Overlay

- Provide a toggleable UI element.
- The overlay activates the device front-facing camera.
- The camera feed appears in a screen corner while the player records.
- Facecam is post-MVP unless platform integration cost is proven low.

### Asynchronous Multiplayer

#### Ghosts

- Download friend death coordinates for the current daily seed.
- Display them as chalk outlines or tombstones.
- Friend ghosts are post-MVP unless the backend and account system already exist.

#### Fall Sprays

- If equipped, the player leaves a spray-paint decal at the exact death coordinates.
- Sprays accumulate over time to build a visible history of failures near the tower base.
- Persistent fall sprays are post-MVP and require moderation and retention rules.

#### Deferred Global Features

- Global leaderboards and number-one-player lead ghosts are not part of the MVP scope.
- If added later, lead ghosts must remain faint, non-colliding, and non-authoritative.

## Implementation Notes

### Replay Buffering

- Capture a rolling gameplay buffer rather than writing full-session video by default.
- Define a fall threshold using a combination of downward velocity, lost altitude, and outcome severity.
- Keep the share prompt post-event so it does not interrupt the fall itself.
- MVP should log the fall trigger event even if the first release only shares a screenshot.

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

- Is the first share feature a screenshot, an engine-rendered clip, or native OS recording?
- What account/friends system will provide friend death coordinates?
- How long should fall sprays persist, and are custom player-created spray images allowed?

## Risks

- Native video capture and social-share flows are heavily platform-dependent.
- Facecam support may be limited by device permissions, performance, and store-policy constraints.
- Persistent sprays can create content moderation and storage concerns if users can customize them freely.
- Global competition features can expand infrastructure and moderation scope quickly, so they should remain deferred until the core loop proves retention.

## Suggested First Tasks

1. Define the event trigger for a highlight-worthy fall.
2. Prototype a 10-second rolling replay buffer.
3. Design the per-seed data schema for ghosts and sprays.
4. Scope platform requirements for front-camera overlay support.
5. Define moderation and retention rules for persistent user-generated decals.