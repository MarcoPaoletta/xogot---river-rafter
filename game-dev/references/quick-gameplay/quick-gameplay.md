# Quick gameplay: few mechanics, few levels, everything polished (Marco, 2026-10-25)

Read this before writing a GDD, a build order, or the first level of ANY Letta game, in any engine. It decides how big the game is, and that decision comes before every other one.

> *"Prefiero 3 niveles bien pulidos que 30... para un video necesitás nada más que un minuto, minuto y medio de gameplay bien, bien pulido."* (Marco, 2026-10-25)

## 1. The rule

**Quality of the content beats quantity of content, always.** A Letta game exists to be filmed. In the video Marco shows roughly one to one and a half minutes of gameplay, so every level, mechanic and system past what fits in that window is work nobody sees, and it is work that was not spent on polish. The agent's default instinct is the opposite (more levels, more rooms, more systems reads as "more complete"). That instinct is the bug this module corrects.

What a Letta game is, by default:

- **One signature mechanic** that looks great the first time you see it, plus **at most two supporting mechanics**.
- **Three to five levels** (rooms, days, planets, arenas, zones), each one short and **visually distinct** from the others.
- **Everything polished**: juice, render, UI and feel at the steam ready bar of this skill, on every piece that exists.
- **Readable in seconds**: Marco starts the recording, says "this is the game I am going to show you", presses Play, and within a few seconds the viewer understands the game and sees it look good.

This is a philosophy, not a stopwatch. Nobody times the gameplay to 60 seconds. The numbers below are defaults that a project's GDD or Marco can change; the direction (small and polished over big and rough) does not change.

## 2. The evidence (why this is the rule)

| Game | What happened | What it proves |
|---|---|---|
| **Overdue** (SpriteCook long 8, 2026-10-23) | V1 ended with **30 rooms** and 4,757 SpriteCook credits. In the video Marco shows very little of it. In the V2 round he asked for an Express mode: *"No need to test ALL the rooms... do not need that much content, that is why I also asked for express mode"*, with the target *"within 60 to 90 seconds of gameplay everything happens"*. Express became a linear route of 6 to 8 existing rooms, every ability unlocked on the way, one puzzle per room, a boss at the end. | 30 rooms cost time, credits and verification, and the video needed 6 to 8. The extra content also hid the progression problems the log still carries. |
| **Splatwalk** (Meshy long 5, 2026-10-10) | Marco barely showed the game's content and, in his words, the video did very well in views. The game has one striking base mechanic (the paint splat), and many sessions went into polishing that single effect (`references/paint-splash/`). | The view count came from one mechanic that looks great, not from the amount of content. |
| **Sushi Restaurant** (Xogot for Mac video 1, 2026-09-08) | Five short days, the first correct dish served within 40 seconds of Day 1 starting, all very polished. Marco (2026-10-25): *"más que suficiente, no necesito más que eso, pero está muy pulido"*. | Few levels, fast to first payoff, and polish is a complete video. |
| **Amber Run** (Ziva video 5, Mario Galaxy style, 2026-09-01) | Five small planets, each one demonstrable in about 30 to 40 seconds, each very different visually, each readable in one look (12 to 20 units of radius against a 2.9 unit player). | Short and visually distinct levels give the edit a new image every few seconds and are understood instantly. |

Evidence level: the Overdue quotes and numbers come from its `docs/V2_PLAN.md` and `docs/BUILD_NOTES.md`; Sushi Restaurant and Amber Run numbers from their GDDs; the Splatwalk view result is Marco's statement (2026-10-25), not a measured comparison.

## 3. Scope budget (defaults, written into every GDD)

| Item | Default | Hard ceiling without Marco's OK |
|---|---|---|
| Signature mechanic | 1 | 1 |
| Supporting mechanics | 1 to 2 | 3 |
| Levels / rooms / days / planets / arenas | 3 to 5 | 8 |
| Time to clear one level, a competent player | 30 to 60 s | 90 s |
| Full run of all the content | 2 to 5 min | 8 min |
| Time from Play to the signature mechanic on screen | under 10 s | 20 s |
| Enemy, item or building types | as few as cover the levels | whatever each level actually uses |

Rules that go with the table:

1. **Each level is visually distinct**: a different palette, biome, light, set piece or hazard, so a cut in the edit reads as "new" at thumbnail size. Five levels that look the same are worth one level.
2. **Each level shows something.** Write one line per level saying what it adds on camera (a new hazard, the second mechanic, the boss). A level with nothing new to show is cut.
3. **Polish before content.** Level N+1 is not started until levels 1 to N pass the perceptual gate (juice, render, UI, no placeholders). When time runs short, the cut is in content, never in polish.
4. **The signature mechanic gets the polish budget.** Iterate its feel the way Splatwalk iterated the splat: impact layers, sound, particles, camera, timing, until it looks great in a compressed video. One mechanic at 100 percent beats three at 60.
5. **Variety lives inside the few levels.** "Use the asset pack fully" and "show everything fast" (both rules of this skill) mean more variety per level, not more levels. Arena scale is still a feel parameter (Container Yard went to twice the size): bigger space is fine, more levels is the thing to avoid.
6. **The progression is fast.** Everything the game has appears within the first minute or two of play (this skill's "The WOW is in the first minute" rule). Difficulty and spectacle grow by count, speed and pressure, never by drip feeding content over half an hour.

## 4. When the game is already big (Express route)

Some briefs or earlier rounds produce a large game (Overdue). Do not delete content on your own initiative: cutting what exists is Marco's call. The move that works:

- **An Express mode** (a main menu button) that strings a linear route of the best existing levels, 6 to 8 at most, with every ability and attack unlocked on the way, one clear beat per level (a puzzle, a hazard, a set piece), the finale or boss at the end, and an end screen with the time. Target: everything shown in 60 to 90 s by a player who knows the route.
- Reuse what exists; build nothing new for it beyond the route and its beats.
- Verification concentrates on the Express route plus the parts Marco will film. Do not spend hours proving all 30 rooms.
- Express is not mandatory in every game. A game built with this module from day one is already the size of an Express route and does not need one.

When Marco says a game "feels like too much" or "too big", propose (in one short list) the curated route, the levels it keeps, and the polish pass on the signature mechanic; apply the route, and wait for his OK before removing anything.

## 5. What goes in the GDD

Every build GDD **opens** with this block, at the very top, right under the title and before Section 1 (Marco, 2026-10-25: *"esta filosofía arriba de todo, bien directo y al grano"*). Short and direct, with:

- the signature mechanic in one sentence and its feel acceptance criteria (what the viewer sees in the first 10 s);
- the numbered list of levels (3 to 5 by default), one line each: setting, what it shows on camera, target clear time;
- a **"Not built"** list (systems and content deliberately left out);
- a **cut order**: what goes first if time runs short (always content, never polish);
- acceptance: Play to signature mechanic under 10 s; full run under the target minutes; every level distinct in a thumbnail size frame; levels 1 to N pass the perceptual gate before N+1 starts.

The drop-in block for GDD writers is `Letta/Skills/Skill 5 - Proposal Writer/1 - Build GDD/patterns/quick-gameplay.md` (in the Hub).

## 6. Checklist (before declaring a build done)

- [ ] 1 signature mechanic, at most 2 supporting ones; any more are justified in the GDD or approved by Marco.
- [ ] 3 to 5 levels by default (8 at most without Marco's OK), each visually distinct and each with one line of what it shows.
- [ ] From Play, the signature mechanic is on screen in under 10 s.
- [ ] A competent player clears the whole content in 2 to 5 minutes (or the project's stated target).
- [ ] Every existing level passes the perceptual gate; nothing unpolished was added to pad the count.
- [ ] If the game was already big: an Express route exists or was proposed, and nothing was deleted without Marco's OK.

## 7. Engine applicability

Engine independent. It applies as written to Godot, Unity (Aura, Meadow Mechs), Unreal (where it adds to the speed budgets of `references/unreal-engine/`), Xogot and Ziva builds.
