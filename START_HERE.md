# START HERE — pickup guide for any AI continuing this project

**Owner:** Faceless (Highrise username LJAAYY). GitHub account: lawrencej2423-bot.
**Project:** a Highrise **WORLD** (a Studio world project — NOT a regular room) styled as a ~95% replica of the house from the 2006 animated film *Monster House*. Playable area = the front yard; the game floor (poker, blackjack, trivia, RPS, radio for the owner's two bots LJAAYYBot and LJAAYY2) is INSIDE the house, reached by tapping/walking into the front door, which teleports the player inside. One world, two areas. Storm night sky, lightning, moonlight as the key light; the only warm glow comes from the house itself.

## Read in this order
1. `00-reference/REFERENCE.md` — the film-accuracy source of truth for the facade (ratios, checklist).
2. `design-docs/DESIGN.md` — the full design spec (grid, zones, bot station anchors §5). Note: §2's "original in that style" wording is SUPERSEDED by the ~95% replica brief; games are INSIDE now, not in the yard.
3. Section folders `01-layout` … `11-atmosphere` — each has its manifest + a README/guide. `05-builder/builder.lua` places everything from the manifests when the world runs in Highrise Studio.
4. `08-qa/SWEEP_REPORT.md` — QA state. Last full sweep: GREEN (0 fails; one honest PENDING: TriviaScreen is a script hook, not a placed object).
5. `UPDATE_LOG.md` + `updates/` — version history. Every finished update is versioned V1, V2, …; each version's note is also DM'd to the owner in Highrise by his bot (the V1 note is queued until the bots relaunch — see below).

## Standing rules from the owner (do not break)
- **Free only.** No paid services, no credit card, no paywalls for the build route. The build runs on GitHub Actions free Windows runners.
- **Master files live HERE, in this repo** — never only on a cloud machine. If a session wipes, re-open these files and re-upload.
- **The final upload is pre-approved** (owner, 2026-11-22): when the build is finished, start the Highrise upload without asking again. The owner then visits the world in-game himself.
- **Bug Department** (`.github/workflows/bug-department.yml` + `09-bug-department/`): runs on GitHub alone — every push + every 6 hours — auto-fixes safe mechanical issues and opens/closes its own issue for the rest. It needs no AI session.
- **Never put secrets in this repo.** No bot tokens, no API keys, ever. The owner's two Highrise bots are currently DOWN (host restart 2026-11-02); relaunching them needs the owner to supply each bot's Highrise token once, in person. That is also why the V1 DM hasn't been sent yet.
- Verify bot presence in a room by WHISPER, not DM. Settle any running game before switching bot modes (gold safety).

## Status at V1
All sections built and sweep-green: yard layout (97 objects), replica facade (77 parts), card-game + party-game scripts, builder (execution-tested), assets (86 entries), pipeline, QA, Bug Department, storm atmosphere, interior + teleport door. Pushed to this repo; first Actions build runs on push. Remaining: the Studio finisher (open the project in Highrise Studio on a free runner, Play, Upload) — **the Upload step is not yet proven**; it may need the owner's Highrise sign-in inside Studio. Do not claim the world is live in Highrise until the upload is verified and the owner has walked it.
