# Asset restore registry

All 3D models are by **Quaternius**, licensed **CC0 1.0**, downloaded on 2026-10-30 as GLB from Poly Pizza (`https://static.poly.pizza/<id>.glb`). Each file was renamed on download and placed in its own folder, then imported with Godot's default `.import` settings. Nothing was rescaled, decimated or texture-capped; scale is applied on the instancing nodes.

| Project path | Poly Pizza title | Poly Pizza id |
|---|---|---|
| assets/models/raft/raft/raft.glb | Raft | 9c276a46-9174-48ee-9624-3944d5b0d3ef |
| assets/models/raft/raft_paddle/raft_paddle.glb | Raft Paddle | 28c8e9ad-b50d-49ea-905c-74597423ef2a |
| assets/models/characters/adventurer/adventurer.glb | Adventurer | 69689495-028d-4b81-8678-792338a5693e |
| assets/models/nature/pine_tree/pine_tree.glb | Pine Tree | 4ab9f316-03f8-4588-9dcb-ca4f02f4219b |
| assets/models/nature/pine_tree_autumn/pine_tree_autumn.glb | Pine Tree Autumn | 3e8bc39d-53b5-4aed-a47f-1827be7e0e43 |
| assets/models/nature/pine_tree_snow/pine_tree_snow.glb | Pine Tree with Snow | 1e077c40-f8df-4322-9faf-964faecc5860 |
| assets/models/nature/birch_tree/birch_tree.glb | Birch Tree | f51ba6c2-51e9-43ce-b2a9-ccb0230b55e6 |
| assets/models/nature/birch_tree_snow/birch_tree_snow.glb | Birch Tree with Snow | 6f6529a3-2385-4781-96f2-802cf2c6e832 |
| assets/models/nature/willow/willow.glb | Willow | fb9965b3-0b81-4bec-9798-9a55d57e6daa |
| assets/models/nature/autumn_tree/autumn_tree.glb | Autumn Tree | 653f3101-2c31-4d15-9e54-3d81aeca345a |
| assets/models/nature/dead_tree_snow/dead_tree_snow.glb | Dead Tree with Snow | 4cfe60b4-042a-44fa-881d-0a3ed5adce04 |
| assets/models/nature/bush/bush.glb | Bush | 57727111-0deb-4a85-9182-9f1371f6ca96 |
| assets/models/nature/bush_snow/bush_snow.glb | Bush Snow | 84e3f229-b276-4766-8846-a8d70beef332 |
| assets/models/nature/rock_moss/rock_moss.glb | Rock Moss | 76cc8706-7c55-4ba6-9492-f673b477b4bf |
| assets/models/nature/rock_snow/rock_snow.glb | Rock Snow | 3d9f39ed-af7d-491a-90a3-957036099b1d |
| assets/models/nature/rock_large_a/rock_large_a.glb | Rock Large | a50f220b-3c4c-4226-ae97-0458ed615cd2 |
| assets/models/nature/rock_large_b/rock_large_b.glb | Rock Large | c14651f6-9ef8-41e8-8aca-cafed61d9ca2 |
| assets/models/nature/rock_large_c/rock_large_c.glb | Rock Large | d7bc2b98-2c73-4e78-b0bd-e5e24d65734a |
| assets/models/nature/wood_log/wood_log.glb | Wood Log | 89d5c7b9-0735-4640-913d-87261dfecd32 |
| assets/models/nature/wood_log_moss/wood_log_moss.glb | Wood Log with Moss | 5283865a-f61a-4787-b02d-28b5b76df7b9 |
| assets/models/nature/tree_stump_moss/tree_stump_moss.glb | Tree Stump with Moss | f6caf11a-75ff-4a6e-9d87-28b44f685803 |
| assets/models/nature/lilypad/lilypad.glb | Lilypad | ae432cca-6422-42ef-a982-b74bd0fc99b2 |
| assets/models/nature/cloud/cloud.glb | Cloud | 46e91434-8a45-4ed8-9ebc-239e1bc176f3 |
| assets/models/nature/mountain_group/mountain_group.glb | Mountain Group | f01e8d13-d978-4d21-8980-d03b907fe362 |
| assets/models/props/crate/crate.glb | Crate | 694ea720-b36e-4139-9ff4-b8f51ca91e43 |
| assets/models/props/barrel/barrel.glb | Barrel | bb7f786f-2204-4dac-afe8-4d47243a3ac2 |
| assets/models/props/dock/dock.glb | Dock | 37a007c2-8b27-4092-8b57-4817636d763f |
| assets/models/props/dock_long/dock_long.glb | Dock Long | 4c55ba08-c218-4526-bfdc-3f6a0a2b7e7f |
| assets/models/props/flag/flag.glb | Flag | 4cd7e950-9c30-4005-8a7d-81b4d555715e |
| assets/models/props/star_coin/star_coin.glb | Star Coin | a892170f-459a-4d1f-814a-76cfd4fafcbc |
| assets/models/props/fish/fish.glb | Fish (spare, unused) | 311a79f6-ba3e-47aa-80ce-04185fc76b2a |
| assets/models/props/pickup_heart/pickup_heart.glb | Pickup Heart | 38716c7c-cd82-4254-8cce-51a6c2491e8a |

Restore: `curl -L https://static.poly.pizza/<id>.glb -o <project path>`, then rescan in the editor.

**Font:** `assets/fonts/LilitaOne-Regular.ttf` from Google Fonts (`github.com/google/fonts/raw/main/ofl/lilitaone/`), SIL OFL 1.1, licence beside it.

**Audio:** `assets/audio/*.res` are synthesized offline by `tools/make_audio.gd`. To re-bake: in the editor run `load("res://tools/make_audio.gd").new().run()`.

**Generated materials and particles:** `assets/materials/*.tres`, `scenes/levels/env_*.tres` and `scenes/levels/level_N_river.tres` (river curves) are project-authored.

## Added 2026-10-30 (feature round 2)

| Project path | Poly Pizza title | Poly Pizza id |
|---|---|---|
| assets/models/animals/fox/fox.glb | Fox | e18e86df-1692-48d8-ac6e-1e25ab4ad574 |
| assets/models/animals/frog/frog.glb | Frog | 08416495-b056-4ed7-b23b-5a10e82277a0 |
| assets/models/animals/bunny/bunny.glb | Bunny | 084b5ebe-c3eb-4e64-9b17-06e2d1e3da5d |
| assets/models/animals/raccoon/raccoon.glb | Raccoon | c1c63d3e-1f22-42e9-a47a-682c9f109834 |
| assets/models/animals/husky/husky.glb | Husky | 611d25c7-430f-4bb5-ab2c-d8f5f3cb9712 |
| assets/models/animals/deer/deer.glb | Deer | 4b6c2a41-43c7-404c-ae37-e8c4645ff93b |
| assets/models/animals/bird/bird.glb | Bird | bc6de37a-fdc5-4ef2-85c6-4a2e7b5db9d5 |
| assets/models/props/gem_blue/gem_blue.glb | Gem Blue | 60566587-6940-4642-9feb-44a023791fda |
| assets/models/props/arrow_sign/arrow_sign.glb | Arrow Sign | 8f3134c7-f206-41e1-9c67-55f3fe566490 |
| assets/models/props/chest/chest.glb | Chest (spare, unused) | b4373a5a-463e-43e1-aece-7dda31788c0d |

All by Quaternius, CC0 1.0. `star_coin_mesh.res` and `cloud_mesh.res` are meshes extracted unchanged from their GLBs, so they can be used with their own material and shadow settings.
