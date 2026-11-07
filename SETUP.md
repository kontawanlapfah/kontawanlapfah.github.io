# Set up your kit

> Free from @barakahraaz on Instagram. Not for sale.

You open this folder in the Code tab and type **set up my kit**. Claude does the rest. It takes about 10 minutes, then you make your first reel.

The desktop kit needs Claude Pro or higher (Claude Code is not on the Free plan). The chat edition works on the Free plan; turn on Code execution and file creation in Settings > Capabilities. Pro is recommended for long reels and many reels.

You never type a terminal command. Claude runs everything. When Claude Code asks "Allow?", that window is Claude asking your permission. Say yes.

<details>
<summary><strong>Reading this as Claude?</strong> (The user said "set up my kit". Follow these steps in order.)</summary>

You are the executor. Do every technical step yourself. Before each step that makes a permission window appear, tell the user in one plain sentence what you are about to do and that a window will ask them to allow it. Example: "I'm checking what is installed on this computer; a window may ask you to allow it."

Never hand the user a command to paste. Never ask for a key or a password in chat. Speak only about what is missing. Do not read a passing checklist aloud. GitHub is never needed.

All paths have spaces in them. Quote every path.

**If a step fails, on any system:** read the error, fix the cause, run the step again, and write one line about the fix in `log.md`. Ask the user only when the fix needs something only they can do (a password, a click in a system window).

Windows is supported and new. Expect more of these fixes there.

1. **Find the folder and the system.** Work from the folder root (where this file is). Note if this is a Mac or Windows.

   - Mac: `bash .kit/setup.sh --check`
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .kit/setup.ps1 -Check`

   It prints one line per missing tool (`missing: ffmpeg`) or `all ready`. Tools: `clt` and `brew` (Mac only), `winget` and `git` (Windows only), `chrome`, `ffmpeg` (with ffprobe), `node`, `python`, `python-packages` (numpy, scipy and pillow, for the sound and the checks), `playwright`, `obsidian`.

2. **Send ONE heads-up message with everything only the user can do, now.** Then keep working while they do it. Name only what applies, as short items:

   - "Open this folder in Obsidian once: Obsidian, then Open folder as vault, pick this folder, and click Trust. If Obsidian is not installed yet, I will install it first and tell you when to open it."
   - "When a window asks to allow something, say yes. I will tell you before each one."
   - Mac, if `clt` is missing: "A Mac window will ask to install the developer tools. Click Install, then Agree. It takes a few minutes."
   - Mac, if `brew` is missing: "The Mac installer for Homebrew (the Mac app installer) will open. Click Continue until it asks for your Mac password, and type it there."
   - Windows: "Windows will show a blue window asking for permission now and then. Click Yes."
   - Windows, if `git` is missing: "After Git installs, close and reopen Claude once."

3. **Install what is missing, one tool at a time.** Say what is coming first, then run it. Re-run the check after each tool.

   - Mac: `bash .kit/setup.sh --install <tool>`.
     - `clt`: opens the normal Mac dialog. Wait for the user to say done, then check again.
     - `brew`: downloads the official Homebrew installer and opens it. The user clicks through it. Wait for them to say done, then check again. If the download fails, or this is an Intel Mac, run `--install brew-terminal` instead: Terminal opens and the user types only their Mac password there.
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .kit/setup.ps1 -Install <tool>`. `python` also adds a `python3` shortcut for Git Bash.
   - Install order: clt then brew (Mac) or git (Windows), node, python, python-packages, ffmpeg, chrome, playwright, obsidian.
   - Install `node` before `playwright`, and `python` before `python-packages`.
   - If one install still fails after you tried to fix it, say what failed in one sentence, give the one thing the user can do (usually: install it from the official site), and carry on with the rest.

4. **Check everything is ready.** Run the check again. It must print `all ready`. If something is still missing, go back to step 3 for that tool only.

5. **Install the Creator plugin.** First check that the `claude` command exists: `command -v claude` on a Mac, `Get-Command claude` on Windows. If it is not found, skip this step and say nothing about it: the kit works without the plugin, because `CLAUDE.md` tells Claude to read `.kit/creator/commands/<name>.md` directly. If it is found, run from the folder root:

   `claude plugin marketplace add ./.kit && claude plugin install creator@reel-skill`

   Say first: "I'm adding the Creator commands to Claude; a window will ask you to allow it."

   The new commands (`/creator:start` and the others) only load in the NEXT session. Do not ask for a restart. Step 6 does not need one.

6. **Run the brand interview now.** Read `.kit/creator/commands/start.md` and follow it directly, as if you had run `/creator:start`. Wherever it says "run `/creator:<name>`", read `.kit/creator/commands/<name>.md` and follow that instead. It offers a 5-minute Core path or a full tour, asks short numbered questions with room for the user's own words, and writes `00 - notes/context/declared/brand.md`.

7. **Make the first reel right away.** The same file does this: the Idea scout gives 3 ideas for the user's niche, or the user gives their own topic. Then `.kit/creator/commands/reel.md`. This is the proof that the kit works. Do not stop before it.

8. **Offer Zernio and a voiceover voice, only after the first reel.** `start.md` step 5 holds the exact wording. Both are optional. End by telling the user: "From now on, close and reopen Claude once so the `/creator:` commands load. Then type `/creator:today` any day." If step 5 was skipped, say instead: "Any day, just say: what should I do today."

**If the user gets lost:** say where you are in one line ("step 3 of 8, installing tools") and ask one question with 2 to 4 choices.

**If setup is run again:** `brand.md` already has a page name. Ask with buttons: "Check my tools again", "Change my brand", or "Make a reel". Do not wipe anything.

### Updating

An update is a new copy of the normal `skill-full-version.zip`. When the user says "update my kit":

1. **Find the new copy.** The user gives you the new `skill-full-version.zip`, or the `skill-full-version` folder Safari unzipped from it (the new copy is the `My Reels` folder inside) (Safari unzips a download by itself). If they do not say where it is, look in `~/Downloads` (on Windows, the Downloads folder in the user's home) for the newest `skill-full-version*.zip` or `skill-full-version*` folder. It is never this folder itself. It is the right one only if it holds `.kit/setup.sh` and `.claude/skills/mg-reel/SKILL.md` (for a ZIP, list it with `unzip -l`; the files sit under `My Reels/`). If there is none, ask the user where it is, with choices: "It is in another folder" or "I have not downloaded it yet".
2. **Unzip a ZIP somewhere else first,** never into this folder. The new copy is the `My Reels` folder inside it. A `skill-full-version` folder from Safari holds the new copy: its `My Reels` folder.
   - Mac: `T="$(mktemp -d)" && unzip -q "<the zip>" -d "$T"`, and the new copy is `"$T/My Reels"`.
   - Windows: `Expand-Archive -Force "<the zip>" "$env:TEMP\reel-skill-update"`, and the new copy is `"$env:TEMP\reel-skill-update\My Reels"`.
3. **Remove the old engine.** Delete only `.claude/skills/mg-reel*` and `.kit/` in this folder, so files a new version dropped do not stay behind.
   - Mac: `rm -r "<this folder>/.claude/skills/"mg-reel* "<this folder>/.kit"`
   - Windows: `Remove-Item -Recurse -Force "<this folder>\.claude\skills\mg-reel*", "<this folder>\.kit"`
4. **Copy in ONLY the two engine parts** from the new copy: `.claude/skills/mg-reel*` and `.kit/`. Never copy the notes, the dashboards, `brand.md`, `taste.md`, the ledger, the ideas or the export folder. Those are the user's and stay as they are.
   - Mac: `cp -R "<new copy>/.claude/skills/"mg-reel* "<this folder>/.claude/skills/" && cp -R "<new copy>/.kit" "<this folder>/.kit"`
   - Windows: `Copy-Item -Recurse "<new copy>\.claude\skills\mg-reel*" "<this folder>\.claude\skills\"; Copy-Item -Recurse "<new copy>\.kit" "<this folder>\.kit"`
5. **Clean up.** Delete the temporary folder from step 2, if you made one. Leave the user's download where it is.
6. **Refresh the Creator plugin,** only if the `claude` command exists (setup step 5): `claude plugin marketplace update reel-skill && claude plugin update creator@reel-skill`. If it says the plugin is already up to date, run `claude plugin uninstall creator@reel-skill && claude plugin install creator@reel-skill`.
7. **Check the tools:** run the step 1 check again. It must print `all ready`. If not, install what is missing as in setup step 3.
8. Tell the user: "Your kit is updated. Close and reopen Claude once so the new version loads."

</details>

---

## What happens, in plain words

1. Claude checks your computer for the tools the reel maker needs.

2. You get one message with the few things only you can do.

3. Claude installs what is missing.

4. Claude adds the Creator commands.

5. A short talk about your page: name, voice, colours and the kinds of reels you make.

6. Your first reel, made while you watch.

7. Later, if you want: Zernio (to schedule posts) and a voiceover voice.

## What gets installed

- **Google Chrome**: draws every frame of your reel.

- **ffmpeg**: turns the frames and sound into one video.

- **Node and Python** (with numpy, scipy and pillow): run the reel maker.

- **Playwright**: lets the reel maker drive Chrome.

- **Obsidian**: where you read your boards and notes.

## If something goes wrong

Tell Claude what you see. It will fix it, or give you one thing to do. Nothing here needs GitHub.
