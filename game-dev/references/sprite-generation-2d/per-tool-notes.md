# Per tool notes: SpriteCook, Pixel Engine, AutoSprite (and Makko, out of scope)

Companion of [sprite-generation-2d.md](sprite-generation-2d.md). That doc is the method; this one says what each MCP offers, what was measured, and how its tools map onto the method. Tool catalogues change between videos: Rule 1d of `SKILL.md` (update the plugin, list the models) comes first, and every number below carries its date and source. Anything not measured in a Letta build is marked **unverified**.

---

## SpriteCook (MCP and Claude plugin `spritecook@spritecook`)

**Measured in:** Overdue (plugin 0.1.15, skills 2026.10.20, 2026-10-23), Hedgehog Hammocks V3 (2026-10-09), Cogwood and the earlier packs (2026-07-16). Deep tool knowledge: the plugin's own skills (`spritecook-workflow-essentials`, `-generate-sprites`, `-animate-assets`, `-generate-tilesets`, `-polish-sprites`, `-use-assets-in-godot`), Skill 6.1 `1 - SpriteCook/style-guide.md` (prompt packs) and Skill 15.1 `1 - SpriteCook/README.md` (the findings sent to Kimo, 15 rows).

**Contact:** Kimo (Mick), founder, on Discord (`synkimo`). His art advice recorded in Overdue (2026-10-23): Nano Banana Pro is still the best model, Nano Banana 2.1 is good, any resolution is fine, but **never scale generated pixel art up or down, and the pixel size of every asset must match.**

### Models (Overdue `list_generation_models`, 2026-10-23)

| Model | Pixel | Native alpha | Max refs | Credits at 1K | What was measured |
| :-- | :-: | :-: | --: | --: | :-- |
| `pixel-engine-image-v1` (Pixel Engine Image) | yes | yes | 0 | 6 | **Exact size, 16 to 128 px per side**, longest side at most 4 times the shortest, both sides even past 64 px. Every Overdue still. Text only: any style, reference or edit asset is rejected. One subject per image. Prompts of about 600 characters or more fail and are refunded. The plugin doc says larger requests are scaled down to fit (unverified: Overdue never asked past 128). Editing one needs another model passed explicitly with `edit_asset_id` |
| `gemini-3-pro-image` (Nano Banana Pro) | yes | no | 10 | 16 (40 at 4K) | **Keeps the pixel size of its style references:** with three Pixel Engine props as references, 408x245 at k = 1 with spines as wide as the references. Size hint caps at 512 px (`resolved_parameters.requested_width` came back 512). Used for pieces between 128 and 512 px. Plugin doc: 20 rpm rate limit |
| `gemini-nano-banana-2.1` (NB 2.1) | yes | no | 14 | 12 (30 at 4K) | The tool default. Same probe: 480x268, k = 1, very good but drew a room in perspective that does not tile |
| `gpt-image-2.5-sunburst` | yes | yes | 14 | 8 medium, 25 high, plus 8 per reference | **Density mode, the size hint is ignored:** 48x48 asked, 129x124 back; 96x64 gave 272x254; 112x144 gave 34x34 (misdetected grid); 128x86 at 16:9 gave 503x283. Shipped nothing in Overdue. UI kit sheets use it regardless of the concept model |
| `gpt-image-2.5-flare` | yes | yes | 14 | 8 medium | Fast drafts; non square 1K billed as 2K |
| `gpt-image-2`, `gemini-3.1-flash-image`, `gemini-3.1-flash-lite-image`, `gemini-2.5-flash-image` | yes | no | 14, 14, 14, 3 | 9, 12, 8, 8 | Not used in Overdue; the 2.5 flash is deprecated |

Superseded facts to ignore in older docs: Skill 6.1 (2026-07-16) says no model supports native transparency (true then; `pixel-engine-image-v1` and the gpt 2.5 models now do) and pre-duplicates background plates x2 with nearest neighbour (that is scaling generated pixel art, which Kimo's rule forbids for shipped art).

### Tools and how they map onto the method

| Step of the method | SpriteCook tool | Notes |
| :-- | :-- | :-- |
| Update and list (§1) | `list_generation_models`, `list_tileset_options`, `list_presets`, `list_character_workflows`, `get_credit_balance` (also reports `latest_skills_version` and the concurrency, 10 on Marco's plan) | All free. Record them in `docs/MCP_NOTES.md` |
| Project and concept anchor (§2) | `create_project`, then `create_asset_upload` plus `finalize_asset_upload` for the concept | Never base64 in a log. `generate_character` and `animate_game_art` take no project: attach with `assign_assets_to_project` |
| Stills up to 128 px (§1, §5) | `generate_game_art` with `pixel-engine-image-v1`, `pixel` true, `mode` `assets` or `ui`, `width` and `height` = the target | k = 1 by construction, background already removed, 6 credits. Check `resolved_parameters.size_behavior` is `exact` |
| Stills 128 to 512 px (§5) | `generate_game_art` with `gemini-3-pro-image` and same density assets in `style_asset_ids` | Then `remove_background` when alpha is needed. Measure k and size every time |
| Style vs reference vs edit | `style_asset_ids` (look and pixel size), `reference_asset_id` (this exact subject, copies its pixel size closely), `edit_asset_id` (modify this one asset) | Never combine reference and edit. A reference carries its flaws too |
| Characters (§9) | `generate_character` then `generate_character_animations` | **No size control:** Remy came back 107 px on a 110 px canvas (25 credits, Sunburst high), at a density different from the Pixel Engine anchor, so Overdue did not ship it. Plugin doc: canvases of 56 to 170 px. Platformer presets: idle, walk, jump, run, attack, hurt, death (first clip 20 credits, each extra 14, preps 12). Its runs use `pixel-engine-v1.1` only and their own canvas |
| Animations (§9) | `animate_game_art` on the approved still, `model` `pixel-engine-v1.1` (even frames 2 to 16) or `pixel-engine-v1.5` (3 to 16, calmer on isolated subjects per the plugin doc, unverified in a Letta build) | **Keeps the source pixel size:** 68x68 frames from a 40x48 still, Remy 48 px in every frame. 20 credits a clip. `edge_margin` 6 by default (a percentage: raise it for wide swings), `vertical_align` `center` for flying subjects. Pixel sources up to 256 px (v1.1) or 320 px (v1.5); aspect between 1:2 and 2:1. Frame counts can differ by one: read `frame_count` |
| Tilesets (§10) | `generate_tileset` (platformer `autotile-16-set`, tile 16, 32 or 64; 32 is the clean path with no guide grid; edges transparent only), then `export_godot_tileset_package` | 2 variations: 24 credits on NB 2.1, 32 on Sunburst. Overdue picked the NB 2.1 set by a side by side with the concept. The exported TileSet `.tres` already carries terrains (fixed 2026-07-16 after Skill 15.1 findings 2 and 3); count the peering bits of every exported set, one of five Cogwood sets had zero. Godot AI cannot create TileSet tiles, so Overdue used the exported files verbatim and authored terrain collision separately |
| Godot characters | `export_godot_character_package` | Godot AI cannot fill a `SpriteFrames` with textures; Overdue used one `Sprite2D` strip per clip plus an `AnimationPlayer` (`ClipSprite`) |
| Transparency (§10) | `get_asset_metadata` (read `alpha_editing`), compare cutoffs locally with the plugin's `compare_alpha.py`, then `set_asset_alpha_cutoff` | 0 credits. Alpha is binary (0 or 255): no soft glows, which stay native. Skill 15.1 findings 10 to 12: the saved strip of a guided clip matched cutoff 36 while the API reported 96, and `alpha_editing` was unavailable on 2.5 stills and `animate_game_art` outputs in that run (2026-10-09) |
| Sheets of many objects | `auto_slice_asset` | Default `merge_distance` 1 welded two objects on Cogwood; `0` matched the web slicer. Count alpha islands first |
| Lost asset ids, timeouts (§12) | `list_recent_assets`, `list_active_jobs`, `check_job_status`, `check_character_animation_run` | Pixel animations ran past the MCP timeout and all finished (Skill 15.1 finding 7). Recover before resubmitting |

**Costs measured in Overdue:** a Pixel Engine still 6, a clip 20, a Sunburst medium still with one reference 16 to 22 and high 25 to 55, Nano Banana Pro at 4K 16:9 40, a tileset job 24 or 32. V1 4,757 credits (probes and anchors 525, Remy and first UI 262, other stills and systems art about 1,634, the view audit 2,336), V2 364.

---

## Pixel Engine (its own MCP)

**Measured in:** Critter Camp (Episode 2) and Duckling Detour (Episode 3), each with a twin built by GPT 6.1 Sol (`D:\_Programming\Game Development\Games - Letta Collaborations\Pixel Engine\`, `docs/ASSET_MANIFEST.md` and `docs/BUILD_NOTES.md`). The server needed authentication on 2026-10-25, so its server instructions were not visible here; the tool list below is read from its tool descriptions on that date. **Pixel Engine Image also exists inside SpriteCook** as `pixel-engine-image-v1`; Pixel Engine's own MCP calls it `pe_image_v1`, at the same price and the same 16 to 128 px limits (likely the same model, unverified).

### Tools (descriptions read 2026-10-25, re-read 2026-10-26: identical models, prices and limits, no new model)

Hosted HTTP connector (`https://api.pixelengine.ai/functions/v1/mcp`), so there is no package to update: "update" means disconnect and reconnect it (Rule 1d step 1) and re-read these descriptions. The Claude Code entry `pixel-engine` showed "Needs authentication" on 2026-10-26 (fix: `/mcp`, authorize); the connector entry from the app was already authorized and answered `check_balance` (10,236 purchased credits).

| Tool | What it does | Credits |
| :-- | :-- | --: |
| `generate_sprite` | Text to sprite. Models: `pe_image_v1` (exact size 16 to 128, background removed, text only, reports a seed so `enhance_prompt` `never` plus the seed repeats a sprite), `nb_flash` (default), `nb_pro`, `oai_gpt25_low`, `oai_gpt25_high` (best for edits with a reference), `oai_gpt25_max`. `source_job_id` or a reference URL keeps a set consistent; `palette` quantizes to an exact hex list | 6, 12, 36, 6, 12, 36 |
| `animate_sprite` | Still to clip (webp, gif or a spritesheet strip). `pixel-engine-v1.5` (default, 3 to 16 frames) or `pixel-engine-v1.1` (even 2 to 16, often loops walk, run and idle more cleanly). **A `pe_image_v1` sprite has no margin, so always pass `canvas`** (scale 1.5 for idle, walk, run; 1.3 to 1.8 for attacks, anchored away from the facing side; `bottom` for jumps) | 26 (v1.5), 20 (v1.1) |
| `remove_background` | For finished animations: animate on a solid flat background, then remove (not on a GIF) | 2 |
| `pixelate_image` | Turns a non pixel image into pixel art on a real grid. **Not for pixel art outputs:** its own description says a 48x64 sprite came back about 10x13 | free |
| `check_balance`, `get_job`, `list_recent_jobs` | Balance; results of jobs that returned an id after about 75 s; recovery of earlier jobs (outputs fetchable at least 24 h) | free |

### What was measured (the counter examples for the method)

- **Size and grid were unstable on the non exact models:** character stills on about 102 to 104 px canvases; `nb_pro` duckling stills on a 2x finer grid; a barrel 151x151 against a requested 22x28 (Duckling Sol); pine 247 against 140, bush 102 against 48. Acceptance had to tolerate props up to 60 percent off size. `pe_image_v1` does not appear in those builds; it is the fix for this class (§1 of the method), and Overdue measured it exact.
- **Views drifted:** bear, otter and raccoon stills came back three quarter; a back swim still showed the face; a water gate came out near isometric. Pixel Engine draws front, back and right; left is the mirror of right.
- **Animation defects:** loops that do not close (ratios 2.17 to 2.62 against a 1.8 limit), design drift (otter tail switching sides, goat horns flickering), extra objects (v1.5 drew feet on a swimming ranger in 4 of 8 and 6 of 8 frames), ripples and splashes growing to four times their reference. v1.1 was the retry lever 7 times after a v1.5 failure.
- **Background removal is a learned segmentation:** it erased pale parts (an iris lost 55 percent of its pixels, flowers 10.7 to 34.8 percent) and over included halo on strips (44 percent extra on a walk). Workaround: a grey key shader in Godot and pale fills.
- **Waste:** Duckling Detour 527 jobs, 278 rejected, 7,944 credits of which 5,006 (63 percent) on rejected jobs; Critter Camp 4,356 credits, 1,114 on rejected jobs. Most of that is what §1 (exact size), §3 (view lock) and §9 (still base, frame checks) of the method prevent.
- **Pending jobs still ran:** two animations returned pending, finished through `get_job`, and charged 26 each.

---

## AutoSprite (MCP `autosprite`)

**Measured in:** Last Floor Hotel (video 1, 2026-10-09, 747 credits) and Stormfield Fighters (video 2, 2026-10-21, 741 credits), `D:\_Programming\Game Development\Games - Letta Collaborations\AutoSprite\`, `docs/BUILD_NOTES.md`, `docs/AUTOSPRITE_LEDGER.md`, `docs/LESSONS_FOR_HUB.md`. Tool list read from its descriptions on 2026-10-25.

AutoSprite is **video based**: a clip is rendered as a short video and then cut into a spritesheet at the `frameSize` you ask (default 256, 0 = native). So the density of its frames is set by your `frameSize` choice, not drawn on a fixed grid, and re-cutting an existing video is free.

### Tools and how they map onto the method

| Step of the method | AutoSprite tool | Notes |
| :-- | :-- | :-- |
| Hero anchor (§2) | `create_character` (`quality` turbo 1 credit or pro 3; `pixelArt` true gives a 16-bit chibi front view snapped to a grid and a 32 colour palette, always 3 credits) or `upload_character` (free, your own approved still) | Prompts up to 600 characters. Uploading a still made by an exact size tool is the way to keep one density across tools (unverified in a Letta build) |
| Room to move (§9) | `pad_character` (1 credit, `character_size` 20 to 100) | Last Floor Hotel padded 5 bases that filled 93 to 96 percent of the frame to 80. The padding only carries into a clip in `first_frame` mode or with a pose |
| Starting pose (§9) | `generate_pose` (3 credits), `save_pose` (free, from an upload or a frame of an existing sheet) | Pin the same pose as first and last frame for a loop that must stay put; change the starting pose rather than the wording when a clip keeps failing the same way |
| Side view clips (§9) | `generate_spritesheet` (`turbo` 5 credits, 2 s; `pro` 10; `max` 35), `generate_attack_moves` (5 per move, cells twice the frame size), presets from `list_animations` | `raw_prompt` true for any non side view, or the side view wrapper fights the pose |
| Eight direction clips | `generate_isometric_pack` (15 credits per action, all 8 real directions from one render) | 25 frames over 2.333 s, 10.714 fps. Mirror tests confirmed real directions (left against mirrored right 26 to 52 on a 0 to 255 scale); the project rule was never `flip_h` |
| Props and FX | `generate_asset_preview` (1 credit, 4 turbo drafts), `create_asset` (free), `animate_asset` (5 turbo, 10 pro), `generate_asset_spritesheet` and `regenerate_single_spritesheet` (free re-cuts of an existing video) | Aspect ratios were not followed (a curtain needed 1:3.2, all drafts about 1:1). Some re-rolls landed on a glossy 3D or smooth vector backend instead of pixel art: look at every draft |
| Transparency (§10) | `remove_asset_background` (1 credit, cached), `removeBg` `default` or `ultra` on clips | Erased white and pale interiors (speech bubble, feather, crest, slash arc) and left a 1 px light fringe; Stormfield keyed every image except one locally from the border instead (tolerance 40, 0 credits) |
| Timeouts (§12) | `get_job_status` (poll every 30 s or more), `idempotencyKey` | Packs queue behind the web app for minutes while progressing: keep polling, never resubmit. 5 packs were refused at the 36 in flight limit (not charged). `generate_portrait` charged 12 credits for 12 jobs whose ids no status tool knew; the faces were cropped from the bases instead |

**Density in practice.** Last Floor Hotel is detailed (not pixel) art: 256 px frames drawn downscaled in Godot (the ghost at 0.365, guests at 0.49 to 0.63) with linear mipmaps, which is fine for HD art and would break pixel art. Stormfield is pixel art: 128 px frames, Nearest, no mipmaps, one scale per fighter from the stance frame (bodies 112, 121, 114 and 112 px). For a pixel art game under this module, choose one `frameSize` so the body lands at its target height and show every character at the same scale (a recommendation, not yet measured in a Letta build).

**Defects seen:** in `skeleton.sleep`, 2 of 8 directions never lay down (one 15 credit regeneration fixed all 8); a halftone artefact in 4 diagonal views lived in the source video, so the free re-cut could not fix it and a new pack was bought; a lamp that filled its frame clipped its smoke at the top edge, and the redo was worse.

---

## Makko: out of scope here

Makko has no MCP (it is driven in Chrome tabs) and its art is detailed, not one density pixel art. Use `Letta/Skills/Skill 27 - Makko Operator/` to generate and `references/sprite-animation-import/` to import (per clip scale, offset and facing).
