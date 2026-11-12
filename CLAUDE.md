# My Reels

> Free from @barakahraaz on Instagram. Not for sale.

This folder is your reel studio. It is also your Obsidian vault and your Claude project.

You make short reels here. Claude learns your taste with every reel.

## Start of every session

1. Read `00 - notes/context/declared/brand.md`.

2. If `page_name` there is empty, stop and run setup: read `SETUP.md` and follow it. SETUP runs the brand interview (`/creator:start`) for you, so do not run it again.

3. Read `00 - notes/context/observed/taste.md`.

4. Read `index.md`, and the last few lines of `log.md`.

## What the user says, and who answers

Match plain words to a helper. The helper files live in `.kit/creator/agents/`. The commands live in `.kit/creator/commands/`.

| The user says | Do this |
|---|---|
| "start", "set up my page", "first reel" | `/creator:start` |
| "what should I do today", "what next" | `/creator:today` (uses the Coach) |
| "give me ideas", "new ideas", "made-up story about X" | `/creator:ideas` (uses the Idea scout) |
| "save this", "here is an article / link / note" | `/creator:save` |
| "how did my post do", "numbers", "review" | `/creator:review` (uses the Coach) |
| "make this reel", "make idea X" | `/creator:reel` (Script writer, Reel maker, then Caption helper) |
| "make a carousel", "slides", "turn this reel into a carousel" | `/creator:carousel` (the `mg-carousel` skill) |
| "write a caption", "Threads post" | Caption helper |
| "update my kit", "I got an update" | `SETUP.md`, the "Updating" part |

The reel skills in `.claude/skills/mg-reel*` do the making. The `mg-carousel` skill makes carousels. If a user says "make a reel" with no command, use `/creator:reel`.

If the `/creator:` commands are not loaded (the plugin is not installed, or this session started before it was), read `.kit/creator/commands/<name>.md` and follow it. `/creator:reel` means `.kit/creator/commands/reel.md`, and so on.

If nothing fits, ask one numbered question with 2 to 4 choices. Do not guess.

## How to file notes

- Raw sources in `00 - notes/sources/` are never edited.

- Talk it through with the user first. Then file what you learned into the right notes.

- After filing, update `index.md` and add one line to `log.md`.

- Each folder has an `_index.md`. Finished or dropped notes go to `_archived/`. Your ledger stays put and is never moved.

- New idea notes copy `00 - notes/ideas/_template.md`. After each reel, add the lesson under `## Lessons` in `taste.md` as one short line, newest first. Keep it to 30 lessons at most and merge old ones.

## Where things go

- Reel folders: `00 - notes/content/<YYYY-MM-DD>-<slug>/`

- Finished videos: `03 - export/<YYYY-MM-DD>-<slug>/` (the same name as the reel folder)

- Carousel folders: `00 - notes/content/<YYYY-MM-DD>-<slug>-carousel/`

- Finished carousels (PNG slides and `caption.txt`): `03 - export/<YYYY-MM-DD>-<slug>-carousel/` (the same name as the carousel folder)

- Saved carousel templates: `00 - notes/context/declared/templates/<name>.md`

- Boards (dashboards): `01 - dashboards/`

- Never touch `.claude/` or `.kit/`. Updates replace them. Your notes are safe.

## Style

Plain, short sentences. Warm. No em dashes. No jargon.
