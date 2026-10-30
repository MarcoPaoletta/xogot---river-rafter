# game-dev: how it reaches each game

This folder is the **single canonical copy** of the skill, and it is plain markdown: Claude, Codex or any AI reads it.

**It is no longer a Claude skill** (Marco's rule, 2026-09-24: *"I don't want to use Claude specific skills, everything has to be reusable in Codex and anywhere"*). The junction that existed at `~/.claude/skills/game-dev` (2026-07-20) was removed that day: it only served Claude, and it only loaded `SKILL.md`, not the `references/`.

## How the agent that builds a game sees it

The games live outside the Hub (`D:\_Programming\Game Development\...`), so every Godot project carries **its own local copy, ignored by Git** in `skills/game-dev/`:

```
py -3 "C:\_Marco Paoletta\Work\Marco's Hub\Letta\Skills\game-dev\install_to_project.py" "<root of the Godot project>"
```

**It works with any engine (Marco, 2026-10-20).** The script detects Godot (`project.godot`), Unity (`ProjectSettings/ProjectVersion.txt` with `Assets/`) and Unreal (`.uproject`); for another engine pass `--engine other`, and `--engine godot|unity|unreal` forces one. In projects that are not Godot the `.gdignore` files are not created and `skills/README.md` carries a note about the engine. The skill is still written mostly for Godot: the "Engine applicability" section of `SKILL.md` says which parts hold for any engine (first case: Aura's Meadow Mechs, Unity).

The script copies the folder, writes `skills/README.md` with the Hub commit it came from and a `.gdignore` ONLY in the reference script folders (`references/*/scripts/`). The `skills/` folder with its `.md` files is visible in Godot's FileSystem on purpose (Marco, 2026-09-24: *"I want the skills to appear in Godot"*); the reference `.gd` files stay hidden because they carry `class_name` and would clash with the game's classes (there is a `paint_slime.gd`). And the game's `AGENTS.md` / `CLAUDE.md` say "read `skills/game-dev/SKILL.md` before touching anything" (templates in Skill 30 `templates/agent-docs.md`). Skill 30 runs it in Step 4, on every new starter.

## Privacy and distribution (Marco, 2026-10-07)

The skill is Marco's own work and he may monetize it in the future. **It is not given away with the game's code and it does not inherit its MIT license.** In public repos, or repos shared with third parties, it is never committed, pushed or delivered in a ZIP, export or source package. The game does not depend on it to run. By default, all games carry an ignored local copy to avoid leaking it if they are made public or shared later.

The installer adds `/skills/game-dev/`, `/skills/godot-game-dev/` and `/skills/README.md` to `.gitignore`, without ignoring third party public skills. Do not use `git add -f` on those paths. Before publishing or sharing, verify with `git check-ignore` that they are ignored and with `git ls-files` that they are not tracked. Only the canonical copy in the private Hub and the private mirror `MarcoPaoletta/game-dev-skill` are versioned; do not change their visibility or share them.

If a copy is already tracked, the installer stops without modifying the project: `.gitignore` does not protect it. First keep the local skill and a private backup of the repo, inventory all branches/tags and current/previous paths, remove those paths from the entire exposed history and verify the remote refs afterwards. A deletion commit or `git rm --cached` alone is not enough. Record forks or third party copies separately, because rewriting Marco's repo does not delete other people's repos. Public docs may explain that a private methodology was used, without pasting the full skill or requiring it to run the game.

**Resolved exception (2026-10-07, night):** Marco lifted the restriction on the Xogot shooter of long 5 (twin-stick). `MarcoPaoletta/twin-stick-shooter-starter-kit` (public) had the skill committed in `skills/game-dev/` (57 files plus `skills/README.md`). It was removed from all branches and tags, the `game-dev-skill` tag was deleted and the paths were added to `.gitignore`. There is a prior backup and detail in `docs/context/game-dev-distribution.md`. `MarcoPaoletta/xogot---twin-stick-shooter` is private and was not touched.

**Scope of v1.8.0:** the modular scenes rule is installed in future builds. Updating the canonical skill and its mirror does not imply modifying games that are already done or under construction, nor refreshing their copies. The eventual cleanup of a published skill is a separate privacy task; it is never used as an excuse to refactor those games.

## Where what is learned gets written

Always **here**, in the Hub, never in the game's copy. For an old game to get the new material, Marco has to ask for that update and then the script is run again on that project. Do not refresh existing games just because the canonical copy changed.

## What "put the Godot skills into it" means

When Marco says *"download the skills into it"*, *"put the updated godot game dev skills in it"* or similar, he **always** means this Hub folder (Marco, 2026-09-28). Run the script above on the project (it overwrites the old local copy with the Hub's and leaves the source commit in `skills/README.md`), confirm that the game's `AGENTS.md` and `CLAUDE.md` have `skills/game-dev/SKILL.md` first in the reading list, and commit only the `.gitignore` and the project docs that changed. **Never commit `skills/game-dev/` or its local README.** No other skills are searched for and nothing is downloaded from the internet.

## Mirror and Mac (Marco, 2026-10-05)

When the mirror is synced from a Git hook, its Git subprocesses clear the parent repository's index/worktree environment variables. The mirror must use its own index and repository; a temporary Hub index must never be reused across repositories.

The skill is called **`game-dev`** (formerly `godot-game-dev`). It is mirrored in the private repo `MarcoPaoletta/game-dev-skill` with `sync_mirror.py` (it runs on its own from the Hub's post-commit hook when a commit touches this folder). The Mac has a clone at `~/Skills/game-dev` with ONLY this skill; it is updated with `git -C ~/Skills/game-dev pull` and installed in a project with `python3 ~/Skills/game-dev/install_to_project.py "<project>"`. It holds for Xogot games too (the installer deletes the old `skills/godot-game-dev/` copy if it exists).
