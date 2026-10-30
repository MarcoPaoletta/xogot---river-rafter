# Build notes – River Rafter (2026-10-30)

## Verified in the editor (embedded run on iPhone, Xogot 1.7.7 / Godot 4.7.2, Mobile renderer)
- The Master bus boots muted. M and the speaker button toggle it.
- Title → countdown → rafting → finish: 2 stars recorded, River 2 unlocked, results panel shown.
- Capsize after 3 hits shows the fail panel with Retry / Menu.
- Level swap (Next / direct load of Frozen Rapids) works; LevelSlot holds exactly one level.
- Tilt sensor detected (`Tilt.has_sensor = true`), keyboard steering moves the raft, coins and hearts update the HUD.
- All 28 project scripts compile with zero errors, and runtime debug errors are zero.
- Perf sample (level 1): CPU process 3.4 ms/frame, 307 draw calls, ~320k primitives, 398 objects. The embedded game was throttled to 1 FPS because the chat covered it, so on-device FPS is still to be measured.

## Tuned values
- Raft: base 9 m/s, brake 4.8, boost 15.5 for 1.6 s, steer 8.5 m/s lateral, 3 hearts, 1.5 s invulnerability.
- Tilt: full lock at 22° roll, brake from 8° to 22° back-tilt. Auto-calibrated at GO; axes are remapped if the sensor still reports portrait axes.
- Camera: rigid follow, distance 8.5, height 4.3, FOV 62 → 76 on boost, trauma-squared shake with a max of 0.45 m.
- Fog density: summer 0.0028, autumn 0.0038, winter 0.0055. The terrain material uses `vertex_color_is_srgb`.

## Feedback round 1 (2026-10-30)
- Rider removed from the raft; the paddle lies inside it. `raft.gd` treats a rider as optional, and the finish plays a hop and splash instead.
- Coins: the imported metallic material (metallic 0.4, albedo 0.72/0.65/0.31) read dark. They now use `coin_gold.tres` (albedo 1.0/0.8/0.24, metallic 0.1, emission 0.3, rim 0.3) on the extracted `star_coin_mesh.res`.
- Coin pickup: the gold puff clouds are replaced by additive four-point sparkles (`sparkle.gdshader`, 20 per pickup, 0.55 s) plus one expanding ring flash (`pickup_ring.gdshader`, 0.35 s). No per-shot material duplication.
- Foam: the opaque torus rings and billboard puffs are replaced by `foam.gdshader`, which is noise-broken lace with per-particle seeds. It is used for the flat wake patches trailing the raft, the hull contact ring, the rings around rocks and logs, and the hit splashes. Water streaks are now thin flow lines.
- Cloud models no longer cast shadows (they left a dark patch on the water).

## Open items to check on device
- Real landscape play: steering sign (use "Invert tilt steering" if reversed) and comfort of the 22° full lock.
- Frame rate on the target iPhone. If it is low, reduce `Decor` density or set visibility ranges on the props.
- A concept-vs-gameplay comparison image was not composed: there is no image tool here, and the concept is the SVG in `game_ideas.html`.

## Feature round 2 (2026-10-30)
- **Flow combo:** a near miss means passing a hazard with 0–1.7 m of clearance (hazard `near_radius`: rocks 1.05, logs 2.3). Each one adds 26% to the meter, which decays at 3.5%/s. A full meter gives 6 s of FLOW: double coin value, ×1.15 speed, glowing water. A hit resets it.
- **Waterfalls:** `RiverBuilder.drops` (lip distance, height), 5 m faces. The raft launches when steepness 0.6 m ahead exceeds 0.25 (hop 2.2 m/s, gravity 16). Time scale is 0.55 while airborne. Landing gives a splash and shake scaled by impact. A mist scene and lip rocks are placed at each drop, plus a 4-coin arc.
- **Critters:** frog, bunny, fox, raccoon and husky on rocks. They hop onto raft seats, and coin value = 1 + crew. A hit throws one into the water.
- **Whirlpools:** radius 6.5, pull 30, the eye costs a heart. Spiral shader, camera roll.
- **Paddle burst:** the HUD button, Space, or a shake (linear acceleration > 13 m/s², cooldown 0.55 s). Costs 34% stamina (regen 16%/s): +5 m/s and a 7 m/s dodge toward your tilt.
- **Forks:** `RiverBuilder.forks` (start, end, extra half width). The island half width is widen − 3. The raft is locked to the channel it entered. Calm channel: coins and a critter. Wild channel: rapids, rocks, a whirlpool and the treasure coin (value 10).
- **Living river:** leaping fish (3 per level), bird flocks that take off as you approach, deer that look up and watch the raft.
- **Turbo booster:** blue gem, 3 s at 19 m/s. Rocks are smashed for +3 instead of costing hearts.
- **FX tuner:** double-tap the top half of the screen, or F2. Page 1: wake/foam/spray/water sliders while the autopilot zig-zags. Page 2: per-level sun (`level_N_look.tres`) and Environment while it drives straight; the level buttons reload into another river. Save writes the `.tres` files and Reload restores them from disk. The camera turns (not slides) to frame the raft on the right.
- Fixes: river elements whose Area3D is nested (critters) are now found by walking up parents; zero-scale tweens use 0.001; wildlife guards reads of the raft while it's being freed; autopilot never triggers the finish.

## Feedback round 3 (2026-10-30)
- Coin panel uses a compact `HudPanel` theme variation (margins 22/10/26/10). The score label minimum width went from 190 to 70.
- The paddle button shows the real raft paddle GLB in a transparent SubViewport, with an idle sway and a swing on each stroke. The drawn glyph is removed.
- The tuner camera keeps the gameplay camera type. It moves closer and lower (distance 7.0, height 3.3, FOV 48) and uses an off-axis frustum (lens shift) to place the raft on the right with no stretching.
- Tuner sections: Wake Trail, Wake Foam Look, Hull Foam, Side Spray, Rock Foam, Water Surface / Sun, Ambient & Sky, Exposure & Glow, Fog, Color Grade.
