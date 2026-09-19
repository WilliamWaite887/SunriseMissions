# Homecoming (mission_towerfall) — handoff

Session date: 2026-09-18. Sunrise 0.5.1.0.

Everything below was verified against the live install, the generated SDK, or the Sunrise C++
source. Where something is a guess, it says so.

---

## 1. Environment

| Thing | Value |
|---|---|
| Game root | `C:\Users\William\Documents\projectSunrise\` (old build, `destiny2.exe` ~123 MB) |
| Sunrise runtime | `<root>\bin\x64\Sunrise\` |
| Scripts | `<root>\bin\x64\Sunrise\scripts\` — **a git clone** of `stanuwu/SunriseMissions` |
| Generated SDK | `<root>\bin\x64\Sunrise\sdk\lua\` |
| Homecoming SDK module | `sdk\lua\missions\mission_towerfall_80b500bc.lua` (~1.1 MB) |
| Logs | `<root>\bin\x64\Sunrise\logs\sunrise.log` |
| Mod source repo | `C:\Users\William\Documents\Sunrise\` (the C++ mod, separate checkout) |

`scripts/` was originally the launcher's plain copy. It was replaced with a git clone so edits
survive launcher updates; all 60 `.lua` files were verified byte-identical before the swap. The
launcher's copy is preserved at `scripts.launcher-backup/` (safe to delete).

`settings.json` was changed for debugging: `core.logging.file_sink: true` and
`core.logging.levels.server: "debug"`. `mission_scripting` and `lua_declarations` were already on.

**Launch the activity as `#266 | Story | Homecoming`.** There are two rows in the Activity Launcher
dropdown and only one works:

| | #265 | #266 |
|---|---|---|
| internal name | `Homecoming` | `mission_towerfall` |
| definition | `0xF07A75D3` | `0x62D85FB3` |
| scenario | `0xFFFFFFFF` (none) | `0x80B500BC` |

#265 has no scenario, so nothing binds to it. `RED_WAR.md` names it as unplayable. Logs for #266
read `activity_row=267` (1-based row for index 266).

### `.gitattributes` warning

`scripts/.gitattributes` pins `*.lua -text` with the comment *"The runtime hashes these files byte
for byte, so git must not rewrite line endings."* Five shipped scripts genuinely contain CRLF as
committed content. **Do not normalize line endings across the repo** — it will break those files'
hashes.

---

## 2. Iteration loop

Edit the `.lua` → save → **World window → Script page → Reload script**. No relaunch needed.

- Mission state (variables, timers, which steps have started) persists across reload.
- `on_load` runs instead of `on_start`; the flow graph resumes where it was.
- `reload()` also calls `mission_state::recover()` when the script had faulted, so a typo that
  faults the VM is recoverable without relaunching
  (`Sunrise/src/server/activity/mission/mission_script_runtime.cpp:741`, `:754-760`).

**Important limitation:** `on_start` code for a step or encounter that has *already started* will
not re-run on reload. For changes to a beat you have passed, relaunch from orbit.

Rule of thumb: editing a beat ahead of you → reload. Editing a beat behind you → relaunch.

### Reading the log

```bash
grep "ev=mission_script" logs/sunrise.log \
  | grep -vE "stage=packet|stage=push|stage=receive|stage=keepalive|stage=service|device_state|host_committed"
```

Trigger fires (the most useful signal) look like:

```
stage=player_trigger result=resolved ... object=80b50ca7 slot=152 volume_key=... volume_slot=273
```

Map `object` + `slot` back to a name by matching `slot/<object>/......./<index>` in the SDK module.
An armed trigger reports on every update while you stand inside it, so 4–9 repeats per crossing is
normal — the first report disarms it.

### HUD

`events N/M` on the Mission Script overlay is `eventsCommitted / eventsSeen`
(`Sunrise/src/core/ui/hud/overlays/ui_hud_mission_script_overlay.cpp:86-90`). A faulted VM prints
`lastVmError` on the same overlay, so `running phase 0` with no error line means the script is
healthy. Do not mistake a low `detail=` grep count for event starvation — most deliveries are not
individually logged.

---

## 3. How this script is built

Homecoming is **declarative**. `mission_towerfall.lua` returns `campaign.new{...}` and
`lib/campaign.lua` builds everything: both flow graphs, per-leg trigger arming, cutscene lifecycle,
trigger disarm, marker re-registration. You mostly edit table entries, not control flow.

Read these comments in `lib/campaign.lua` before editing — they encode non-obvious runtime rules:

- `:52-53` — assign a combat objective **before** placing a squad, or a cohort misreads the squad
  as cleared for ~1 second.
- `:83-84` — an armed trigger reports every update while the player is inside; first report
  disarms.
- `:107-116` — an interactable needs `set_interactable_object{used = true}` or the client shows a
  generic prompt and **never reports a use**.
- `:460-461` — a goal sent before its marker's object registers shows no marker, so it is re-sent
  on region entry.
- `:402-404` — **an encounter with no `trigger`/`monitor` runs at arrival.** This caused a real bug
  this session (see §6).

`check()` at `lib/campaign.lua:164` validates the whole content table at load and throws a named
error (e.g. "X ends on a trigger no leg arms"), so typos fail loudly at load, not silently mid-run.

### Sandbox limits

`lib/mission_lib.lua:1`: *"The sandbox has no pairs, next, string.match or math.random."* Use
`ipairs`. Also: 128 KiB script, 5M instructions per callback, 512 variables, 32 timers.

### Scene vs. idle — the distinction that matters

A scene slot is only activatable with `context:scene():activate{}` if it has a **symbol** entry in
the SDK (i.e. it appears in `mission.Scene`). A row that exists only as a `Slot` is a sensor you
drive with `play_performance` / `lib.play_idles` instead.

Worked example: `SCENE_SHAXX` has a symbol row → in `mission.Scene` → activatable.
`SC_UNDERWATCH_INTRO` has only a Slot row → **not** in `mission.Scene` → not activatable as a scene.

Check before using a name:

```bash
awk '/^mission.Scene = \{/,/^\}/' sdk/lua/missions/mission_towerfall_80b500bc.lua | grep '^    NAME = '
```

Note the asymmetry in the API: `scene = Scene.X` to play one, `ends = {scene = Slot.X}` to wait on
one. Different namespaces. (`adventure_vod` is the reference for this idiom.)

---

## 4. Current diff (5 changes, all in `mission_towerfall.lua`)

`git diff` in `scripts/` shows 37 insertions, 3 deletions. Upstream base is `f317a32`.

### 4.1 Imports — **confirmed working**
Added `local lib = require("lib.mission_lib")` and `Scene` to the destructure.

### 4.2 Cast scenes on `underwatch_cast` — **confirmed working in game**
Activates `SCENE_SHAXX`, `SC_CIVILIAN_CATATONIC`, `SC_CIVILIAN_KNEEL`, `SC_CIVILIAN_GROUND_1`,
`SC_CIVILIAN_GROUND_2`, `SC_CIVILIAN_ON_KNEES_CRYING`. All six verified present in `mission.Scene`.

Before: placed bodies held a default pose and the whole opening was a diorama. After: **user
confirmed Shaxx is kneeling.** This is the one fix visually confirmed in game.

### 4.3 Hero moment on `first_contact` — **untested**
Activates `SC_HERO_MOMENT_UNDERWATCH` + `SCENE_CAYDE_GOLDEN_GUN` from `PT_DROP_POD`.

Cayde should stand up and Golden Gun two Legionaries. It was first attached to a new encounter
waiting on `PT_HERO_MOMENT`; that **never fires** (see §5). It now hangs off `PT_DROP_POD`, which
the same encounter already uses to place `SQ_CABAL_HERO_MOMENT` and `_B` — the exact two
Legionaries Cayde shoots. Not yet observed in game.

### 4.4 Hangar gating doors on `hangar` — **untested, strongest evidence**
Opens `D_GATING_AMANDA_START` and `D_GATING_AMANDA_HANGAR`.

This addresses a reproducible hard block. Log evidence from the stuck session:
`PT_DIALOGUE_HANGAR_WINDOW` at t=621000 → `PT_HANGAR_SPAWN` at t=645281 (26-unit hangar fight
spawned correctly) → region 32 at t=658765 → **nothing for 51 seconds until quit.**

The `hangar` step waits on `PT_GOTO_PLAZA_80B50B91`, which is `slot=0` of object `80b50b91`; only
`slot=1` ever fired. Both gating doors live in the hangar object `80b5036a` and the script never
touched them. Fits "stuck, no door opens" exactly.

### 4.5 Armory door + rifle prompts — **untested**
Split the old `gear` step in two:

- `gear` — goal shows, walk to the armory, door **stays shut**, ends on `PT_WEAPON`
- `armory` — opens `D_GUN_DOOR`, registers the three rifles, ends on `PT_WEAPON_COMPLETE`

User reported the retail beat is: door closed → Shaxx speaks → door opens. The original script
opened the door the instant the step started. `PT_WEAPON` was already armed by the `underwatch` leg
but unused by any step — a spare trigger at the door threshold.

Rifle prompts (`AUTO_`/`PULSE_`/`SCOUT_RIFLE_INTERACTABLE`) are registered via
`set_interactable_object{used = true}`, **not** via `ends = {interact = ...}` — there are three
rifles and you take one, and the step already ends on `PT_WEAPON_COMPLETE`. Idiom copied from
`adventure_ginger.lua:317`.

Log confirms registration works: after a reload, `object changed ... interaction_open=1` on slots
103, 105, 106. Whether the prompt is correct in game is unverified.

**Open item:** Shaxx's line was deliberately not added. Cue text is not in the SDK — it is on the
in-game Dialogue page. Find the armory line under `M_DIALOG_SENSOR_80B50913`, confirm with
**Play cue**, then add `lines = {line(cue.CUE_n)}` to the `armory` step.

**Caution:** `PT_WEAPON` (t=229437) and `PT_WEAPON_COMPLETE` (t=230890) fired **1.4 s apart** in
one session. The `armory` step may be too short-lived for a line to breathe. If so, put the line on
`gear` so it plays on approach.

---

## 5. Hard-won facts about this map

### `PT_SC_*` triggers are script-fired, not player-crossed
`PT_HERO_MOMENT`, `PT_SC_CIVILIANS_START`, `PT_SC_CIVILIANS_MID`,
`PT_SC_CIVILIAN_GROUND_1_LOOK`, `PT_SC_CIVILIAN_WALL_SIT_C`, `PT_NUX_SPRINT` — **all have zero
fires across every session**, including runs where the player walked well past their locations.

Do not arm one and wait on it. Hang the scene off a trigger the player actually crosses.

### `squad_refused "not_runnable"` — one is expected
Exactly one per session, in every run including ones predating any edit. It is placement **#14 of
`underwatch_cast` = `SQ_RED_GUARD_FAKE_FIGHT`**.

Meaning (`Sunrise/src/server/activity/activity_sdk_squad_runtime.cpp:325-326`): the squad's flags
lack `kSquadRunnableMask` — it is authored as scene-driven content that cannot be `place{}`d at
all. Cosmetic, pre-existing, unfixed. **Refused requests are not faults.**

If the refusal count ever exceeds 1, something new is wrong.

### "mosquito" means Thresher
`O_MOSQUITO_VS_FRAMES` / `SCENE_FRAMES_VS_MOSQUITO` are a **Thresher gunship drive-by**, not an
infantry Cabal. Confirmed by the user playing the scene manually from the Scenes page.

The user also confirmed **neither the Thresher nor the frame squads appear in the original
mission's opening**, so this scene does not belong in the opening beat at all. An encounter using
it was added and then fully removed this session. Net change: zero.

### `activate_objects` cannot spawn
`context_activate_objects` *"Groups exact **authored** objects by native owner"*
(`Sunrise/src/server/activity/mission/mission_script_lua_context_api.cpp:20-21`). It toggles
objects the map already authored. It cannot create a body.

### The Scenes page `Advance` button == `context:scene():activate{}`
Both call `activate_authored_scene`
(`Sunrise/src/server/ui/activity_host/activity_host_sdk_mission_view.cpp:329`). So manual playback
from the Scenes page is an exact test of what your script does — very useful for isolating
"is the scene broken?" from "is my invocation wrong?".

### `unlinked` in the Activity Host dropdown is not an error
It just means `linkCount == 0`
(`Sunrise/src/server/ui/activity_host/activity_host_panel.cpp:47`). Ignore it.

---

## 6. Mistakes made this session — do not repeat

1. **Fabricated directory listings.** Early on, three tool calls returned confident, detailed
   listings for paths that did not exist, and they were reported as fact. **Verify any path with a
   plain `ls`/`cat` before building on it.**

2. **Added a beat that is not in the mission.** Built a `frames_vs_mosquito` encounter on the
   assumption that the opening involved frames fighting something. The user, comparing against
   video, reported that neither the Thresher nor the frames are in the original opening. Removed.

3. **Introduced a regression while "fixing" a non-bug.** Split the mosquito encounter so the object
   registered at arrival and the scene played later — which put the Thresher on screen at spawn,
   because an encounter with no trigger runs at arrival (`lib/campaign.lua:402-404`).

4. **Guessed at trigger semantics three times.** `PT_HERO_MOMENT` was assumed to be a player volume.
   It is not. The log (zero fires) settled it, not reasoning.

The pattern: **the SDK tells you what exists, not what the mission does.** Ask the user to compare
against video before building a beat.

---

## 7. Known blocker — the wall-break Cabal

**Status: not scriptable today. Do not spend time here.**

The retail beat: the player walks up to a wall, a Cabal breaks through it, it explodes, he yells.

What works: `PT_WALL_EXPLODE` fires (9× observed) and the `wall` encounter opens
`D_UNDERWATCH_COLLAPSING_WALL`. Wall breaks, audio plays.

What is missing: the Cabal body. Two independent reasons:

1. **No Cabal squad is authored near that wall.** The 14 unused Underwatch squads are frames,
   fleeing civilians, and test assets. `SQ_LEGIONARYA/B/C` are Cabal (`0x80C1A52D`) but sit at
   y≈37–42, a different area from the wall.

2. **`LT_WALL_EXPLODE` (idx 151, type 25, `look_trigger_sensor`) has no runtime support.**
   `lookTriggerSensor = 25` exists in `Sunrise/src/middleware/content/packages/tables/slot_type.h:31`
   and `look_trigger_sensor` in the auth schema catalog — the data parses. But there is **no Lua
   binding and no handler** anywhere under `Sunrise/src/server/activity/mission/`. For contrast,
   `player_trigger` (type 31) appears in 5 files including a dedicated
   `mission_script_player_trigger.cpp`.

So the sensor that most likely gates this beat cannot reach a script. Adding look-trigger support
is a **C++ contribution to the mod**, not a scripting task. Ask stan on Discord before attempting.

---

## 8. Suggested next steps

1. **Relaunch #266 and test the four unverified fixes** (§4.3–4.5). Highest value is the hangar
   gating doors — that unblocks the rest of the mission.
2. **Get Shaxx's cue number** from the Dialogue page and finish the armory beat.
3. **When a beat looks wrong, use the Squads / Scenes / Objects pages** before theorising. The
   Scenes page `Advance` button in particular is an exact test of a script's scene call.
4. **Always ask the user to compare against video.** Three wrong guesses this session were caught
   that way and by nothing else.

### Beats still completely unaddressed

`plaza_hold` and `plaza_defend` end on `cohort{}.cleared`, and `overload` ends on
`ends = {destroyed = {...}}` for the three shield generators. None reached in testing. These are the
likely next hard blocks, because a single wrong slot in a cohort stalls the chain silently.

### Unused scene assets (candidates, unverified)

The Underwatch has ~20 scene sensors; the script now uses 8. Notably unused:
`SC_UNDERWATCH_INTRO` (sensor-only — idle, not scene), `SC_CIVILIAN_RUN_EXPLOSION`,
`SC_CIVILIAN_RUN_FRONT_*`, `SC_FRAME_COVER_SHOOT_DIE`, `SC_CENTURION_INTRO`,
`SCENE_CABAL_FIRST_CONTACT`. Check against video before wiring any of them — that is exactly the
mistake that cost this session its time.
