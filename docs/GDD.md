# River Rafter – Build GDD

## Quick gameplay (read first)

- **Signature mechanic:** tilt the iPhone (landscape) to steer a white-water raft down a flowing river. The current always pushes you forward; tilting back brakes. Visible in the first 5 s after Play: countdown, GO, raft moving and steering.
- **Supporting mechanics (2):** star coins to collect (stars rating), rapids chevrons that boost speed. Hazards: rocks and drifting logs cost one of 3 hearts.
- **Levels (3, ~50–60 s each):**
  1. **Pine Gorge:** summer midday, green pines, gentle gates and slaloms, teaches coins and rapids.
  2. **Autumn Bend:** golden sunset, falling leaves, narrower and more winding river, adds drifting logs.
  3. **Frozen Rapids:** snowy dusk, snowfall, narrowest channel, rock gardens, more logs and rapids.
- **Not built:** multiplayer, shop/upgrades, procedural endless mode, character customization, music track.
- **Cut order if time runs short:** decor density first, then the 3rd level; never polish.
- **Acceptance:** Play → raft moving in under 10 s; full run of all 3 rivers in under 4 min; each river reads as a different place in a thumbnail.

## Loop
Title (live river, orbiting camera) → pick river → 3-2-1-GO (tilt auto-calibrates on GO) → raft → finish banner (confetti, rider waves, 1–3 stars) or capsize (3 hits) → Next / Retry / Menu.

## Controls
- Tilt left/right (roll) steers, tilt back (pitch) brakes. Calibrated at GO; "Recalibrate tilt", "Invert tilt steering" and "Tilt sensitivity" in the pause menu.
- Fallbacks: A/D or arrows, S/Down to brake, touch-and-hold left/right half of the screen (when no sensor).
- M or the speaker button toggles sound (the game boots muted). Esc/P or the II button pauses. F1 or a three-finger tap opens the debug panel.

## Stars
1 for finishing, +1 for ≥50% of coins, +1 for ≥85% of coins with at most one hit.

## Scene architecture
- `scenes/main.tscn`: director (`scripts/core/main.gd`), LevelSlot (level 1 instanced so the editor shows the world), Raft, CameraRig, HUD, Title, Pause, Results, Debug, ScreenFade.
- `scenes/levels/level_N.tscn`: WorldEnvironment, Sun, River (RiverBuilder: Path3D curve → water ribbon and valley terrain, data generated at load and cleared before save), Hazards, Pickups, Rapids, Decor, Backdrop, StartDock, FinishGate, Ambient particles.
- Elements (`scenes/elements/`): raft, camera_rig, coin, heart_pickup, hazard_rock_moss/snow/grey, hazard_log, rapids, finish_gate. FX (`scenes/fx/`): splash_burst, coin_burst, pop_label. Props (`scenes/props/`): one scene per decor model.
- Autoloads: `GameState` (progress and settings), `Audio` (scene with pooled players, boots muted), `Tilt` (sensor → steer/brake).
