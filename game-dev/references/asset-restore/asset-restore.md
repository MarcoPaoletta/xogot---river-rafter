# Asset provenance and restoration

Marco, 2026-10-27: keep restoration instructions in each game repository, push ordinary code/docs, and report which published projects are recoverable. Do not move projects into a deletion folder. The user selects and deletes them.

**Accepted provider-account confirmation, same date:** Marco confirmed that his generated models/assets remain in his own Tripo, Meshy, Hyper3D, SpriteCook, Pixel Engine and other generation-service accounts. Provider plus original names/relative paths and manual account retrieval steps are sufficient. Exact task IDs or direct URLs are optional when already known; their absence does not block cleanup, require another approval or trigger repeated questions/research. Record: `Marco confirmed on 2026-10-27 that these assets are in his provider account; IDs not recorded. Manual account lookup accepted.` This is user confirmation, not an API download test.

## Maintain the registry while building

Create `docs/ASSET_RESTORE.md` at the first asset import. If `ASSET_MANIFEST.md`, `ASSET_SOURCES.md` or another existing registry already contains the required fields, extend it instead and link it from the README. Do not create competing inventories. Use [the project metadata template](ASSET_RESTORE.template.md), replacing every placeholder with evidence or an explicit unknown.

Update the registry in the same change as every import, replacement, generated output or postprocess change. Review it before `setup-finished`, each relevant version tag, handoff and cleanup. Cover models, textures, sprites, animation, audio, fonts, plugins and any required source file omitted from Git. Preserve mappings for older versions that use different files. New and future builds maintain it from day one; an explicit cleanup request can add metadata to old games without refactoring their source or refreshing their private skill copies.

For each asset or coherent pack, record:

- Exact project-relative destination paths, required source filenames and the versions/tags that use them. A vague directory or a provider homepage does not identify a missing model.
- Provider, author, pack/model name, edition/version and license when known. Write `unknown` when evidence is absent. Link existing license/notice files.
- For public packs, keep the provider and original pack/file names, with official URLs, editions/releases and licenses when known. For his generated assets, record the provider, safe account/workspace label, original names/relative paths and accepted account confirmation. Include asset/task IDs only if already recorded; otherwise write `not recorded`. Never store signed URLs, tokens, credentials or private identities.
- Manual account retrieval: sign into Marco's usual account for that provider, open its library/history, locate the existing outputs by their original names or previews, download the recorded model/texture/animation formats and place them at the documented relative paths. Obtain a new download link through the account when needed; do not require the expired direct link or run a new generation merely to document recovery.
- Export format/options, associated textures, rigs/animations, fonts and other dependencies. Record exact extraction, naming and destination rules.
- Postprocess script paths, arguments and required tool versions/dependencies when known. Include source inputs and output paths. If no script exists, describe the manual steps and flag any result that cannot be recreated exactly.
- Whether bytes are committed, already managed by Git LFS, covered by Marco's provider-account confirmation, available from a documented public source, or genuinely unresolved. Existing checksums can identify files; no whole-project hashing or ZIP framework is required.

A generation prompt alone does not reproduce an exact export; the accepted route for his generated assets is manual retrieval of existing outputs from his accounts. Missing task IDs or direct links do not make that route unresolved. Flag concrete gaps outside his confirmation, such as a genuinely unknown provider or unique hand-authored files with no backup. Do not extend that warning to every account asset or claim that any download/API test occurred.

## Restoration and assessment

Restore into a new folder: clone the documented repo/ref, retrieve only the listed omitted assets, place them at the recorded relative paths and run the documented postprocess steps. If the repo already uses Git LFS, document its existing `git lfs pull` step and access requirements; do not enable LFS or migrate files automatically. Then let the engine regenerate its import cache. Distinguish `instructions complete` from `restore tested`; do not claim a download or playtest that was not performed.

Keep retrieval instructions as ordinary project metadata that is safe for the repository's actual visibility. The filled registry is versioned and pushed with the code. This reference, the full private methodology, `skills/game-dev/`, `skills/godot-game-dev/` and the local provenance README are not copied into public deliverables or pushed with the game.

For a cleanup assessment, report `READY FOR USER SELECTION` when the code/docs push is verifiable and restoration is documented, including the accepted provider-account confirmation for his generated assets. Do not block on absent IDs/direct links or request another confirmation. Only genuine uncovered code, history, saves, hand-authored data or unknown providers stay `UNRESOLVED`. StudioTwin, unpublished game projects and daily apps remain protected. A ready assessment never moves or deletes anything; keep all current paths until the user acts or explicitly requests a new operation.
