# Contributor Guide: Working On The Climber As An Artist (Who Codes Too)

This is for someone with no professional coding background who wants to
understand how this game is built, change how it *looks* — character art,
cosmetic skins, colors, UI layout — and eventually write some GDScript of
their own. If you can use layers in a design tool, you can do everything in
the "what's safe to touch" sections below without writing a line of code.
Section 7 is there for when you're ready to write some.

**Contents**
1. [The three ideas you need](#1-the-three-ideas-you-need)
2. [Getting the project open](#2-getting-the-project-open)
3. [How the game actually works](#3-how-the-game-actually-works)
4. [How the code is organized](#4-how-the-code-is-organized)
5. [Where things live, and what's safe to touch](#5-where-things-live-and-whats-safe-to-touch)
6. [Four things you can do with no code at all](#6-four-things-you-can-do-with-no-code-at-all)
7. [Writing your own code](#7-writing-your-own-code)
8. [Checking you didn't break anything](#8-checking-you-didnt-break-anything)
9. [Saving and sharing your changes](#9-saving-and-sharing-your-changes)
10. [Glossary](#10-glossary)
11. [If you want to go deeper](#11-if-you-want-to-go-deeper)

## 1. The three ideas you need

Godot (the engine this game is built in) organizes everything around three
kinds of files. Once these click, the folder structure makes sense.

- **Scenes** (`.tscn` files) — a screen or an object, built as a tree of
  pieces. The main menu is a scene. The player character is a scene. A scene
  is made of **nodes**: a `Label` (text), a `Sprite2D` (an image), a
  `PanelContainer` (a box that lays out its children), etc.
- **Resources** (`.tres` files) — reusable data, not a screen. A list of
  cosmetic skins, a set of colors for the chasing hazard, a character's set
  of texture paths. You edit these the same way you edit a scene — select
  it, change values in the Inspector panel on the right.
- **Scripts** (`.gd` files) — the code, written in GDScript (Godot's own
  language, syntactically close to Python). Sections 3–4 explain what
  they're doing; Section 7 walks through writing one.

Everything in this game is one of those three. There's no build step to
"see" your image, color, or code change — you edit the file, hit Play, and
look.

## 2. Getting the project open

1. Install Godot **4.6** from godotengine.org (the version has to match —
   check `project.godot` in the repo root if unsure, it's stamped there).
2. Open Godot, choose "Import", point it at this repo's `project.godot`.
3. Press **F5** (or the Play button, top right) to run the whole game.
   Press **F6** to run just the scene you currently have open — faster for
   checking a single screen.

You don't need to run any terminal commands to preview visual changes. For
code changes, Section 7 covers the terminal commands you *will* want.

## 3. How the game actually works

The pitch is: **climb, fall, laugh, retry.** Here's what's actually
happening under that, mechanic by mechanic.

### The climb: two hands, one stamina bar
The player has a left and right hand, each of which can grip a handhold.
Reach out, grab, let go, reach for the next one — that's the whole
movement model. The catch: **while only one hand is attached, a stamina
timer drains.** Grip with both hands and stamina holds steady. Run it to
zero on one hand and you fall. This is what pushes the pace of the climb —
you can't just hang around forever on one grip deciding your next move.

### Why you fall (there are five ways)
The game tracks a specific reason for every fall (`RunEndReason`):

| Reason | What happened |
|---|---|
| Bottom-screen fall | You fell far enough to drop off the bottom of the camera |
| Stamina fall | One-handed stamina timer hit zero |
| Missed grip fall | You reached for a hold and missed |
| Chaser contact | The rising hazard caught you |
| Lethal hazard | You touched something instantly deadly |

This matters for what happens next: **falls are rescue-eligible, Chaser
contact is not.** Get caught by the Chaser and the run is over — no
continue offer. Fall any other way (once per run) and the game can offer a
rewarded-ad "continue" instead of ending the run. This is a deliberate
design rule (see `docs/adr/` for the reasoning), not a bug — don't "fix" it
if you spot it while poking around.

### The run itself: five states
Every run moves through the same five stages in order:
`READY → CLIMBING → FALLING → RESCUE_OFFERED → ENDED`. Ready is the
pre-climb pause, Climbing is normal play, Falling is the comedic tumble
after a miss, Rescue Offered is the continue prompt, Ended is the results
screen. The HUD, camera, and UI screens all just react to whichever state
is currently active — that's why restyling `scenes/ui/*.tscn` is safe: the
scripts on those scenes don't decide *when* to show themselves, they just
draw whatever state they're handed.

### The Chaser: a rising hazard that reads your pace
The Chaser is the thing climbing up after you. It doesn't move at a fixed
speed — it watches how much vertical progress you've made recently and
reacts:
- Idle too long near the same height ("camping") → it speeds up to punish
  stalling.
- Climb very fast ("rapid climb") → it eases off slightly, so skilled play
  is rewarded rather than just producing an unwinnable speed race.
- Otherwise it holds a steady base speed.

Each `chaser_theme_*.tres` file is a *reskin* of this same behavior —
different color, glow, and audio, identical pacing logic. That's why you
can safely restyle the Chaser's look without touching how it plays.

### The route: a new layout every day, same for everyone
Levels aren't hand-placed and aren't random-per-player. Each calendar day
(UTC) produces one seed string, and that seed deterministically generates
the whole climb: where the handholds are, what type each one is, where
hazards go. Everyone playing on the same UTC day climbs the same layout.
This is what makes daily challenges and comparing runs with friends
meaningful — there's no "regenerate until it's easier."

### Coins and the store
Coins are a simple counter (`Wallet`) — earned by picking up coins during a
climb, spent in the store on cosmetic items. Cosmetics are strictly
**visual-only**: a jacket color, a hand-grip color, a whole character skin,
a Chaser reskin. None of them change speed, stamina, collision size, or any
other number that affects how the game plays — that separation is enforced
deliberately (see Section 4), which is exactly why it's safe for you to add
new cosmetic entries without risking game balance.

## 4. How the code is organized

Knowing the shape of `src/` helps you guess where something lives and
understand why the boundaries in Sections 5 and 7 exist — whether you're
just browsing or about to write a script.

The `src/` folder is split by *responsibility*, not by feature:

| Folder | Owns |
|---|---|
| `src/gameplay/player/` | Grip, stamina, hand attachment — the climbing feel |
| `src/gameplay/chaser/` | The rising hazard's pacing and contact detection |
| `src/gameplay/run/` | The five-state run flow, falling, rescue offers |
| `src/gameplay/generation/` | Turning a daily seed into an actual level layout |
| `src/economy/` | The coin wallet and transaction history |
| `src/cosmetics/` | Applying visual-only skins on top of the base character |
| `src/platform/` | Talking to the phone: ads, save files, haptics, purchases |
| `src/ui/` | Reading game state and turning it into what the screens in `scenes/ui/` should show |
| `resources/config/` | All the tuning numbers and catalogs, as editable files |
| `scenes/` | The actual screens and objects players see, plus the thin scripts wiring them up |

Two rules shape almost everything you'll notice while browsing, and both
matter more once you start writing code, not just reading it:

1. **Cosmetics can never touch gameplay.** A skin can change a color or a
   texture; it can never change mass, collision size, friction, or any
   tuning number. This is enforced by convention throughout the codebase —
   it's *why* `CosmeticItem` only exposes colors and texture ids, never a
   speed or a size.
2. **Screens don't decide game logic, they display it.** A UI scene
   (`scenes/ui/*.tscn` + its `.gd` script) reads a state object and shows
   it; it never computes stamina drain or decides when a run ends. That
   logic lives once, in `src/`, and every screen just reflects it. Section
   7 shows this pattern in full: it's the shape almost all UI code in this
   project follows.

The scripts are written in **strictly typed GDScript**: every value has a
declared type (a number, a `Color`, a specific class), and the game refuses
to start if a required file, node, or value is missing or invalid rather
than silently guessing a default. If you see a scary red error on launch
after an edit, this is why — it's the project catching a mistake early
instead of shipping a broken run. Section 7 covers what this means for code
you write yourself.

## 5. Where things live, and what's safe to touch

| Folder | What's in it | Safe for you? |
|---|---|---|
| `assets/art/character/human/*.png` | The character's body-part sprites (head, torso, arms, hands) | **Yes, no code needed** — replace in place, keep the same canvas size and pivot point |
| `assets/audio/` | Sound loops for the chaser hazard | Yes, if you're doing audio too |
| `resources/config/cosmetic_item_catalog.tres` | The list of unlockable skins shown in the in-game store | **Yes, no code needed** |
| `resources/config/player_appearance_catalog.tres` | Which texture files make up each playable character | **Yes, no code needed** |
| `resources/config/chaser_theme_*.tres` | Colors, glow, and pulse look of the chasing hazard | **Yes, no code needed** |
| `scenes/ui/*.tscn` (layout) | HUD, menus, store screen, settings, pause screen | **Yes, no code needed** for layout/color/font |
| `scenes/ui/*.gd`, `src/ui/*.gd` | The behavior behind those screens: what a button does, what a state shows | **Yes, once you're writing code** — this is the intended place for UI logic, see Section 7 |
| `src/cosmetics/*.gd` | How skins get applied to the character/Chaser | **Yes, once you're writing code**, if you're extending cosmetics |
| `scenes/player/human_character_rig.tscn` | The skeleton the character art attaches to | Careful — you can look, but don't move bones or resize collision shapes |
| `resources/config/*_tuning.tres` (chaser_tuning, stamina_tuning, economy_tuning, generation_tuning, route_*_tuning) | Gameplay balance numbers (speeds, timers, prices, difficulty) | **Ask first** — these look like plain numbers but they're tuned gameplay, not visuals |
| `src/gameplay/`, `src/economy/`, `src/platform/` | Physics feel, run rules, save data, ad/purchase integrations | **Ask first / pair on it** — shared systems other code depends on, with real architecture rules (see Section 7) |

The rule of thumb hasn't changed for the no-code stuff: color, texture
path, or `.tscn` layout is yours outright. What's new is that `src/ui/` and
the `.gd` files attached to `scenes/ui/*.tscn` are now yours too, once
you're comfortable writing GDScript — that's where "what does this button
do" logic belongs, and it's deliberately kept separate from the gameplay
systems in `src/gameplay/`, `src/economy/`, and `src/platform/`, which have
stricter rules because more of the game depends on them.

One catch worth knowing before you add a brand-new character or Chaser
skin: `CosmeticItem` entries for the **Character** and **Chaser Theme**
slots must point at a matching entry in `player_appearance_catalog.tres` or
`chaser_theme_catalog.tres` — the game validates this on load and refuses
to start if a cosmetic item references an appearance or theme id that
doesn't exist. Plain color-swap items (Body, Left Hand, Right Hand) don't
have this requirement — they're just colors on the base rig.

## 6. Four things you can do with no code at all

### Swap a character sprite
Open `assets/art/character/human/` and replace, say, `Head.png` with your
own art — same pixel dimensions, same origin/pivot as the original, so it
still sits correctly on the rig. Run the game (F5) and look at the player.

### Add a new cosmetic skin (no new art needed)
Open `resources/config/cosmetic_item_catalog.tres` in Godot. It's a list of
`CosmeticItem` entries — each one is just:

```
item_id            a unique name, e.g. &"body_sunrise_jacket"
display_name       what shows in the store, e.g. "Sunrise Jacket"
slot               which cosmetic slot: Body / Left Hand / Right Hand /
                    Chaser Theme / Character
price_coins        store price
visual_color       a Color
accent_color       a second Color
```

Duplicate an existing entry in the Inspector, give it a new `item_id` and
`display_name`, pick new colors, done. It'll show up in the store next run.

### Reskin the chaser hazard
Open one of `resources/config/chaser_theme_*.tres` (e.g.
`chaser_theme_glitch.tres`). Every field is a color, a glow size, or a pulse
speed — change `glow_color`, `crest_color`, `base_fill_color` and re-run to
see the new look chasing you up the wall. (Its speed and pacing come from
`chaser_tuning.tres` instead, which is gameplay balance — leave that one
alone; see Section 3's "The Chaser" for why the look and the pacing are
separate files.)

### Restyle a UI screen
Open `scenes/ui/run_hud.tscn` (or `main_menu.tscn`, `store_shell.tscn`,
`settings_menu.tscn`, `pause_menu.tscn`, `run_end_screen.tscn`). These are
currently plain default-Godot styling — no custom theme yet, so there's real
room for you here. Click a node in the scene tree on the left, edit its
layout/color/font in the Inspector on the right.

## 7. Writing your own code

### GDScript in five minutes
GDScript reads a lot like Python: indentation-based blocks, no semicolons,
`func` instead of `def`. A tiny example:

```gdscript
func add_two_numbers(first: int, second: int) -> int:
    return first + second
```

That's a typed function — one `int` in, one `int` out. This project always
writes it that way; see the rules below for why. For the full language
syntax (loops, conditionals, arrays, dictionaries — the parts that are just
"normal programming," not project-specific), the
[official GDScript reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html)
covers it better than this guide would by repeating it.

### The non-negotiable rules in this codebase
This project's `CLAUDE.md` and `docs/engineering/CODING_STANDARDS.md` set
firm conventions. They read as strict at first, but they're what make a
red error on launch mean something specific instead of the game just
behaving weirdly. The ones you'll hit immediately:

- **Type everything.** Every function parameter, return value, and
  variable whose type isn't obvious gets a declared type. Not
  `var speed = 5`, but `var speed: float = 5.0`.
- **No loose dictionaries for game data.** A `Dictionary` is fine for
  talking to Godot itself or parsing a save file, but the moment it holds
  "a cosmetic item" or "a run's state," it should be a typed class or
  `Resource` instead — like `CosmeticItem` or `StoreState`, not
  `{"name": "...", "price": 5}`.
- **No silent fallbacks.** Don't write
  `var x = value if value != null else default`. If something required is
  missing, say so loudly and stop, using the project's own helper:
  `Validation.require_condition(condition, "clear message")`. You've
  already seen this pattern all over the `.gd` files mentioned earlier in
  this guide — every `_init` and `assert_valid()` is built on it.
- **Keep scene scripts thin.** A script attached to a `.tscn` should mostly
  just wire up nodes and forward user actions. Reusable logic belongs in a
  standalone script under `src/`, not inside the scene script itself.

### The shape of a typical file here
Almost every non-scene script in this repo follows the same skeleton:

```gdscript
class_name CosmeticItem   # the name other scripts use to refer to this type
extends Resource          # or RefCounted for non-Inspector-editable data

@export var item_id: StringName = &"body_default"
@export var price_coins: int = 0

func assert_valid() -> void:
    Validation.require_condition(not item_id.is_empty(), "Cosmetic item id cannot be empty.")
    Validation.require_condition(price_coins >= 0, "Cosmetic item price cannot be negative.")
```

`class_name` + `extends` at the top, typed `@export` fields for anything
that should show up in the Inspector, and an `assert_valid()` you call
right after building or loading the thing, so a bad value gets caught at
the source instead of surfacing three screens later as a mystery bug.

### The pattern you'll actually use: State → Presenter → View
Almost all UI behavior in this project — and the part you're most likely
to write — follows one three-piece pattern. The in-game store is the
clearest real example, in `src/ui/store_state.gd`,
`src/ui/store_presenter.gd`, and `scenes/ui/store_shell.gd`:

1. **State** (`StoreState`) — a plain typed snapshot of what the screen
   should show right now: the wallet balance, the list of items, which one
   is selected. No game logic, just data, validated in `assert_valid()`.
2. **Presenter** (`StorePresenter`) — a pure function-like class that reads
   the real game data (catalog, inventory, wallet) and *builds* a `State`
   from it. This is where "can this be purchased" gets decided — by
   comparing the wallet balance to the price, nothing more exotic than
   that.
3. **View** (`StoreShell`, the scene script) — takes a `State` in
   `apply_state()` and paints it onto the actual `Label`/`Button`/`ItemList`
   nodes. When the player clicks something, it doesn't act on it directly —
   it emits a signal (`purchase_requested`, `equip_requested`) for a
   coordinator elsewhere to handle.

The reason this shows up everywhere: it means a screen's logic
(`StorePresenter.build_state`) can be unit-tested with no scene, no node
tree, no running game at all — just plain function calls. Section 8 shows
what that test looks like.

**A worked example.** Say you want the store to show how many items the
player currently has equipped. You'd touch exactly three spots:
1. Add a field to `StoreState`, e.g. `equipped_count: int`, validated like
   the others in `assert_valid()`.
2. In `StorePresenter.build_state()`, count how many `item_states` have
   `equipped == true` and pass it into the new `StoreState`.
3. In `StoreShell`, add a `Label` node in the `.tscn` (no code — Section 6),
   `@onready`-reference it, and set its text in `apply_state()`.

Nothing else needs to change — the coordinator that calls `apply_state()`
already runs every time the store's data changes.

### Testing what you write
Tests live under `tests/unit/`, `tests/integration/`, and `tests/scene/`,
using the GUT framework. A real one, `tests/unit/test_wallet.gd`, in full:

```gdscript
extends GutTest

func test_wallet_banks_normal_coin_pickups_immediately() -> void:
    var wallet: Wallet = Wallet.new()
    wallet.grant_coins(12)
    assert_eq(wallet.get_coins(), 12)
```

`extends GutTest`, one `func test_something_specific() -> void:` per
behavior, `assert_eq`/`assert_true`/etc. to check the result. If you add a
new field to `StoreState` per the example above, a test like
`test_store_presenter.gd` (check whether one already exists first) would
call `StorePresenter.build_state(...)` with fake inputs and assert the new
field comes out right — no scene needed, since the presenter is plain data
in, plain data out.

Run the whole suite with:

```sh
sh scripts/test.sh
```

`sh scripts/validate.sh` does that plus a project load check — run it
before you consider any change finished, same as the coding side does.

## 8. Checking you didn't break anything

For a visual-only change: just play the affected screen or run. If it
loads and looks right, you're done.

For a code change: run `sh scripts/validate.sh` (see Section 7). If Godot's
Output panel shows a red error on launch, it's usually one of: a broken
texture/resource path, a cosmetic item referencing an appearance/theme id
that doesn't exist in its catalog, or a `Validation.require_condition` you
wrote catching something you didn't expect — read the message, it names
exactly what's missing or invalid.

## 9. Saving and sharing your changes

This project uses git. The simplest flow:

1. Use GitHub Desktop (or ask for a walkthrough) rather than the command
   line if git is new to you.
2. Make your changes, then commit with a plain description ("new sunrise
   jacket skin", "restyled run HUD", "show equipped count in store").
3. Push and open a pull request, or just hand the branch to the coding
   friend to merge.

## 10. Glossary

- **Node** — one building block in a scene (an image, a button, a
  container). Scenes are trees of nodes.
- **Scene** (`.tscn`) — a saved tree of nodes: a screen, a character, an
  object.
- **Resource** (`.tres`) — a saved piece of data that isn't a scene: a
  catalog, a color set, a tuning table.
- **Script** (`.gd`) — code attached to a node or standalone, written in
  GDScript.
- **Inspector** — the panel in the Godot editor where you edit whatever
  node or resource is currently selected.
- **`class_name`** — the name a script gives itself so other scripts (and
  the Inspector) can refer to its type, e.g. `CosmeticItem`.
- **`extends`** — which built-in Godot type a script is built on top of:
  `Resource` for Inspector-editable data, `RefCounted` for plain non-node
  objects, `Control`/`Node2D`/etc. for scene scripts.
- **Signal** — a script's way of announcing "something happened" (e.g.
  `purchase_requested`) without knowing or caring who's listening.
- **Typed / strict typing** — every value in this codebase declares what
  kind of thing it is (a number, a `Color`, a specific class) up front,
  instead of being figured out at the last second. It's why the editor and
  the game can catch a mistake immediately rather than producing a subtle
  bug later.
- **StringName** (written `&"like_this"`) — an identifier used as an id,
  like `item_id` or `theme_id`. Functionally a String; you'll see the `&`
  prefix throughout `.tres` files and scripts.
- **Validation / "fail fast"** — this project intentionally refuses to
  start rather than silently use a wrong default when something's missing
  or invalid. A red error on load is the game telling you exactly what's
  broken, not a crash to panic about.
- **GUT** — the test framework this project uses (`extends GutTest`, tests
  under `tests/`).

## 11. If you want to go deeper

The full design intent for each system lives in `docs/` — see
[`docs/README.md`](./README.md) for the map. `docs/01-core-gameplay-physics.md`
and `docs/04-economy-monetization.md` are the most relevant to cosmetics and
store items if you want the "why," not just the "where." For the full
engineering rules referenced in Section 7, see
`docs/engineering/ARCHITECTURE.md`, `CODING_STANDARDS.md`, and
`TESTING.md` — those are the same rules `CLAUDE.md` holds Claude Code to,
and they apply to anyone writing code in this repo.
