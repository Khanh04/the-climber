# ADR 0013: Characters Carry Sidegrade Skills

## Status

Accepted. Relaxes the "cosmetics must never modify gameplay tuning" rule in
`CLAUDE.md`, `docs/engineering/ARCHITECTURE.md` and
`docs/04-economy-monetization.md` for player appearances (characters) only.

## Context

Human, Spartan and Webhead were coin-bought `PlayerAppearance` cosmetics that
only changed art (and, per ADR 0012, the collision fitted to it). Players asked
for characters that play differently. Bought characters must not simply win:
the store sells them for coins, and the game avoids pay-to-win perception.

## Decision

Each `PlayerAppearance` requires a `CharacterSkillProfile`
(`resources/config/character_skill_profile.gd`) with one always-on passive and
one HUD-triggered active skill.

- Passives scale the run's base tuning; they never replace it. The run scene
  pushes them into `StaminaRuntime.set_max_stamina_multiplier`,
  `ClimbPrototypeController.configure_character_passives` (drain cap,
  auto-catch, swing force) and the wind-gust hazard impulse.
- Actives live in `src/gameplay/player/skills/`: one `CharacterActiveSkill`
  subclass per kind, driven by `CharacterSkillRuntime`, which owns the
  cooldown. Skills act only while the run is CLIMBING, receive a
  `SkillContext` instead of reaching into the scene, and reset on a new run or
  rescue. A skill that has nothing to act on (Web Swing without a target,
  Chalk Up at full stamina) spends no cooldown.
- Every kit is a sidegrade: a strength is paired with a weakness.

| Character | Passive | Active |
|---|---|---|
| Human | Catch: with no hand attached, a hand that has a grab target grips on its own | Chalk Up: restore 50% stamina, 20 s |
| Spartan | Heavy: stamina x1.3, hazard knock-back x0.5, swing force x0.8 | Spartan Kick: push off the hold, launch up and away, 15 s |
| Webhead | Sticky Hands: hold drain capped at 1.0, stamina x0.8 | Web Swing: pull to a hold up to 2x grab reach in the aim cone, 18 s |

Body and hand overlay cosmetics and Chaser themes stay gameplay-neutral.
No skill interacts with the Chaser; Chaser contact stays final.

## Consequences

- Stamina had to matter for the kits to matter, so the run pool dropped from
  100 s to 10 s and now regenerates 1.5 s/s while both hands hold (see
  `docs/01-core-gameplay-physics.md`).
- Spartan Kick's launch is bounded by `max_player_speed_pixels_per_second`
  (900 px/s), so its configured speed stays at or below that clamp.
- Route generation still validates against base reach. Web Swing only adds
  options on top of guaranteed routes; Webhead's smaller pool and the other
  passives do not change route validity.
- A new character needs a skill profile, and at most one new
  `CharacterActiveSkill` subclass plus an `ActiveKind` value.
