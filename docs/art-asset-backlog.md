# Art & Audio Asset Backlog

What still renders as a placeholder (flat `Polygon2D`, `ColorRect`, untextured
`Button`/`PanelContainer`, or a generated tone) and needs real assets. Audited
2026-10-02 against `scenes/`, `resources/config/` and `assets/`.

Conventions the finished assets should follow:

- **Pixel art on a 270×480 canvas, shown at 4×** (viewport is 1080×1920). Full-screen
  UI layers are drawn on the whole canvas in place, like the main menu.
- **Animated objects** use numbered frames `frame_01.png … frame_NN.png` in their own
  folder, played by `frame_loop_presentation.gd` (handholds) or
  `wind_loop_presentation.gd` (wind hazards) at 12 fps.
- **Handhold and hazard frames are 32×32.**

## Gameplay objects

| Item | Placeholder now | Where it plugs in | Needed |
|---|---|---|---|
| Ghost handhold | Pale blue `Polygon2D` | `scenes/handholds/presentation/ghost.tscn` | 32×32 loop frames → `assets/art/game_object/ghost/` |
| Coin pickup | `Polygon2D` built in code | `src/gameplay/pickups/generated_coin_pickup_spawn_adapter.gd` (requires a `Visual` `Polygon2D`, so it needs a small code change to accept a sprite) | Coin sprite or spin loop |
| Tutorial handholds (6) | Yellow `Polygon2D` | `scenes/main/run_scene.tscn` → `Handholds/TutorialHold*/Visual` | Reuse `Normal.png`, or a tutorial-highlight variant |
| Bug swarm hazard | `Polygon2D` | `scenes/hazards/presentation/bug_swarm.tscn` | Loop frames |
| Falling rock hazard | `Polygon2D` | `scenes/hazards/presentation/falling_rock.tscn` | Sprite (and optional crumble frames) |
| Pendulum log hazard | `Polygon2D` | `scenes/hazards/presentation/pendulum_log.tscn` | Sprite |
| Spike cluster hazard | `Polygon2D` | `scenes/hazards/presentation/spike_cluster.tscn` | Sprite |
| Startle puff hazard | `Polygon2D` | `scenes/hazards/presentation/startle_puff.tscn` | Puff loop frames |
| Wandering critter hazard | `Polygon2D` | `scenes/hazards/presentation/wandering_critter.tscn` | Walk loop frames |
| Updraft / downdraft | Reuse the wind-gust frames | `scenes/hazards/presentation/{updraft,downdraft}.tscn` | Optional: their own up/down wind frames |
| Chaser glow and crest | Two translucent `Polygon2D`s drawn over the animated chaser | `scenes/chaser/chaser_kill_zone.tscn` → `GlowVisual`, `CrestVisual` | Confirm whether they stay; otherwise bake them into `Chaser_animation` |

Done: normal, rest, burn, break, boost and rocket handholds; wind gust; chaser body
animation; floor; player body parts (`assets/PNG/Character/CHR2/`).

## Cosmetics

Every cosmetic in `resources/config/cosmetic_item_catalog.tres` is a **colour tint
only** (`visual_color` / `accent_color`), with no art of its own:

- Body: Trail Jacket, Sunrise Jacket
- Hands: Left/Right Chalk Wrap, Left/Right Gold Grip
- Chaser themes: Rising Void, Hot Coffee, Glitch. Each needs its own chaser animation
  set; only the default `Chaser_animation` exists.

Each also needs a **store icon**.

## UI screens

| Screen | Placeholder now | Needed |
|---|---|---|
| Run end screen (`scenes/ui/run_end_screen.tscn`) | Default-theme `PanelContainer`, 6 plain `Button`s, labels | Panel; buttons for Continue (ad), Double Coins (ad), Store, Restart, New Seed, Main Menu |
| Store (`scenes/ui/store_shell.tscn`) | Default-theme panel, `ItemList`, `OptionButton`, Close/Purchase/Equip buttons | Panel, slot tabs, item tile frame, the three buttons, coin-price badge |
| Tutorial overlay (`scenes/ui/tutorial_overlay.tscn`) | Default-theme `PanelContainer` holding a label | Prompt bubble or panel; optional gesture hint icons (tap, hold, swipe) |
| Main menu Store button (`scenes/ui/main_menu.tscn`) | Hidden plain `Button` | Button art, once the store is shown on the menu |

Done: main menu (background, logo, panel, Play/Tutorial/Settings), run HUD, pause
menu, settings menu. Their `Backdrop` `ColorRect`s are intentional dim overlays,
not missing art.

## Audio

`assets/` contains **no recorded audio files**.

- Chaser loops (`assets/audio/chaser_{pressure,hot_coffee,glitch}_loop.tres`) are
  generated `AudioStreamWAV` tones and need real loops.
- Music: the settings menu has a music volume control, but no music track exists. A
  main-menu track and an in-run track are needed.
- SFX: none exist. Likely needs: grab, release, slip/fall, landing/thud, coin
  pickup, each hazard, each special hold (burn sizzle, break crack, boost, rocket),
  rescue, run end, and UI tap.
