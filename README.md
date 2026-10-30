# River Rafter

A white-water rafting game for iPhone, built in Godot 4.7 with Xogot and Claude Opus 5.5.
Hold the phone in landscape and tilt it to steer a raft down a flowing river. Collect star coins, ride the rapids and dodge rocks and drifting logs across three rivers: Pine Gorge, Autumn Bend and Frozen Rapids.
Later rounds add a flow combo for near misses, waterfalls, critters that hop onto the raft, whirlpools, a paddle burst (button, Space or a phone shake), river forks, a turbo booster and an in-game FX tuner.

## Run it

1. Open the project folder in Xogot (iPhone or iPad) or Godot 4.7.
2. Press Play. The main scene is `scenes/main.tscn`.

Keep the project on Godot 4.7, the version Xogot ships. Opening it in a newer desktop Godot upgrades the version stamp and it may stop opening in Xogot.

## Controls

| Input | Action |
|---|---|
| Tilt the phone left or right (landscape) | Steer |
| Tilt the phone back | Brake |
| A / D or Left / Right arrows | Steer (keyboard) |
| S or Down arrow | Brake (keyboard) |
| Touch and hold the left or right half of the screen | Steer (when there is no tilt sensor) |
| Paddle button, Space or a shake | Paddle burst |
| M or the speaker button | Sound on or off (the game boots muted) |
| Esc, P or the II button | Pause (recalibrate tilt, invert tilt, sensitivity) |
| F2 or a double tap on the top half of the screen | FX tuner |
| F1 or a three finger tap | Debug panel |

## Versions

This repository holds one `main` branch with the finished game. The project was built in rounds inside Xogot and the repository was created after the last one, so there are no per-version tags or branches. The design is in `docs/GDD.md`, and the notes of every round of feedback and features, with the measured values, are in `docs/BUILD_NOTES.md`.

## Project layout

| Folder | Contents |
|---|---|
| `scenes/` | One saved scene per game element: levels, raft, camera rig, pickups, hazards, FX, props, UI |
| `scripts/` | GDScript, mirrored by domain |
| `assets/` | Third-party models exactly as downloaded, plus project-authored audio, materials, shaders and UI theme |
| `docs/` | GDD, build notes and the asset restore registry |
| `tools/` | `make_audio.gd`, the script that synthesizes the sound effects |
| `game-dev/` | The Godot game development skill (agent instructions) used to build the game, included on purpose so you can use it in your own projects |
| `game_ideas.html`, `humanoid.tscn` | The game concepts the agent pitched first, and the first editor test, kept as they were |

## License and credits

Code and original content: MIT (see `LICENSE`). The 3D models and the font in `assets/` keep their own licenses (see `THIRD_PARTY_NOTICES.md`).

3D models by Quaternius (CC0 1.0). Font Lilita One (SIL OFL 1.1). Sound effects are synthesized by `tools/make_audio.gd`.
Built in Xogot (Godot 4.7.2) with an AI agent.
