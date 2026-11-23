# FINISHER RUNBOOK — Monster House Highrise World

**Purpose:** the exact, ordered steps that turn the text files in
https://github.com/lawrencej2423-bot/monster-house-world (manifests + Lua +
UXML) into a live Highrise **world**: install Highrise Studio Hub + Unity on
a Windows machine, assemble a Studio project from the repo, open it,
Play-test, and Upload to Highrise under the owner's account (LJAAYY).

**Where this runs:** a free GitHub Actions `windows-latest` runner for
everything automatable (`finisher.yml`, next to this file), and an
interactive signed-in Studio session for the rest. The owner's standing
rules apply throughout: **free only, no card; master files live in the
repo; the final upload is pre-approved once the build is finished; no
secrets in the repo, ever.**

**Tag legend — read the tags, they are the honesty system of this document:**
- **[VERIFIED]** — checked against an official source on 2026-11-22 (Highrise
  Create docs, Unity docs) or executed/tested by a crew.
- **[ASSUMED]** — standard-practice inference, not confirmed for Highrise
  Studio specifically. Verify at first real use; each assumption names its
  check.
- **[UNVERIFIED]** — no source found either way. Treat as a experiment, not
  a plan.
- **[MANUAL]** — a human step by design (sign-in, dialogs, terms). No agent
  and no CI job may do these.

---

## 0. Preconditions (all must be true before starting)

1. The V1 push to the repo is complete and the repo's own Build Checks
   workflow is green (manifests parse, Lua parses, QA sweep passes).
   **[VERIFIED mechanism — repo `07-pipeline/PIPELINE.md`]**
2. The integration item in §7 below is decided (which copy of the
   duplicated game stations wins). The finisher can run either way via a
   converter flag, but the *world* is only correct once the manifests
   themselves are reconciled.
3. The owner is reachable for the [MANUAL] steps in §5–§6. Nothing in
   §1–§3 needs him.

---

## 1. Install Unity Hub + Unity Editor (headless, on the runner)

Highrise pins **Unity 2022.3.30f1** — do not substitute another version.
**[VERIFIED — Highrise Beginner Guide, Lecture 2]**

1. Download Unity Hub:
   `https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup-x64.exe`
   **[VERIFIED — this is Unity's official CDN URL, cited in Unity/VRChat
   deployment docs]**
2. Silent install: `UnityHubSetup.exe /S`
   **[VERIFIED — Unity's own "advanced deployment" docs: "/S initiates a
   silent installation"; needs local admin, which GitHub windows runners
   have. Installed-check: registry key
   `HKLM\Software\Unity Technologies\Hub`, or
   `C:\Program Files\Unity Hub\Unity Hub.exe` exists.]**
3. Install the editor through the Hub's headless CLI:
   `"C:\Program Files\Unity Hub\Unity Hub.exe" -- --headless install --version 2022.3.30f1 --changeset <changeset>`
   **[VERIFIED pattern — Unity Hub CLI as documented in VRChat's VCC docs
   (`-- --headless install -v <version> -c <changeset>`). ASSUMED: the
   exact changeset hash for 2022.3.30f1 — it is a `workflow_dispatch`
   input in `finisher.yml`, not hard-coded, because no crew has confirmed
   the hash from an authoritative page yet. Check: Unity's editor archive
   page for 2022.3.30f1 lists the changeset; newer Hub versions may accept
   `--version` alone. The Hub CLI can return before the download finishes,
   so the workflow polls for
   `C:\Program Files\Unity\Hub\Editor\2022.3.30f1\Editor\Unity.exe` for up
   to 60 minutes.]**
4. **License wall [VERIFIED as a known issue, Lecture 2]:** the editor
   needs an activated Unity license; the documented fix for "No valid
   Unity Editor license found" is signing into Unity Hub and adding a free
   personal license. On a CI runner there is no Unity account and none may
   be created/stored for this project — so if the editor refuses to open
   on the runner, that is this wall. It does **not** block §2–§3 (file
   assembly needs no editor); it blocks opening the project *on the
   runner* (§4). Fallbacks in §8.

## 2. Install Highrise Studio Hub (headless attempt — the weak link)

1. The only official download route is the **Download button on
   https://create.highrise.game/highrise-studio** (Windows or Mac
   installer). **[VERIFIED — Highrise docs + Game Jam page point there;
   fetched 2026-11-22: the page's download target is script-driven and no
   direct installer URL is published in the docs or forum release posts
   (0.2.2 / 0.3.0 / 0.5.2 posts link "Windows"/"Mac" without exposing a
   reusable URL in text).]**
2. **There is no documented silent-install flag, no documented CLI, and no
   documented headless mode for Studio Hub. [UNVERIFIED — absence verified
   by search of the official docs/forum on 2026-11-22.]** The Hub is a
   GUI app whose job is interactive: install Unity + the Studio Package,
   create projects, open them in Unity.
3. `finisher.yml` therefore treats this as an *optional experiment*: if a
   human pastes a direct installer URL into the `studio_hub_installer_url`
   dispatch input, the workflow downloads it and tries the NSIS-style
   `/S` flag, warning loudly and never failing the run on it. Do not plan
   around this succeeding.
4. What the Hub normally does that we still need from *somewhere*
   **[VERIFIED — Getting Started]**: (a) installs the **Highrise Studio
   Package** into the project, (b) creates the project from the **Basic
   Template**, (c) on first open, the project gains `CLAUDE.md` /
   `AGENTS.md` and the `Library/Highrise/hr` launcher. A project that has
   never been through the Hub has none of these, and the `hr` commands
   only work while that project is open in Unity. **[VERIFIED — AI-agent
   guide]**

## 3. Assemble the Studio project from the repo files

Everything in this section is file copying + one conversion — fully
automatable, and `finisher.yml` does it into a `staging/project/` folder
uploaded as a run artifact.

1. **Convert the manifests → `Placements.lua`.**
   `python3 finisher-prep/convert_placements.py <repo-root> -o Placements.lua`
   **[VERIFIED — converter written and tested 2026-11-22 against the real
   manifests: 253 raw entries → 203 unique placements, 0 invalid. See §7
   for the duplicate story and the `--interior-wins` flag.]**
   Why: Highrise Lua cannot read files off disk, so `05-builder/builder.lua`
   loads one Module script named exactly **`Placements`** via
   `require("Placements")`. **[VERIFIED — BUILDER.md]**
2. **Copy the world scripts** into the project (staging layout mirrors the
   assumed in-project layout):
   - `05-builder/builder.lua` → `Assets/Scripts/`
   - `03-scripts-card-games/*.lua`, `04-scripts-party-games/**/*.lua`,
     `10-interior/*.lua`, `11-atmosphere/*.lua` → `Assets/Scripts/`
   - `04-scripts-party-games/**/*.uxml` → `Assets/UI/`
   - generated `Placements.lua` → `Assets/Scripts/Placements.lua`
   - the five JSON manifests → `Manifests/` (reference/re-conversion only;
     the game never reads them)
   **[ASSUMED layout — Unity projects keep scripts under `Assets/` and
   Highrise script/module conventions follow the project the Hub creates.
   Check on first real project: scripts must appear in Studio's script
   browser and the module must be named exactly `Placements`; if Studio
   wants a different folder, move the staging contents there — the file
   *set* is what matters, not this exact tree.]**
3. **What cannot be assembled from the repo:** the scene itself. A Studio
   project's scene, its `WorldBuilder` and `BuilderTemplates` objects,
   and the template stock are created *inside* Unity (§4). The repo
   deliberately holds no `.unity` scene file — the builder script creates
   the world *in* the scene at Play time from the Placements module.
   **[VERIFIED design — BUILDER.md "How the finisher runs it"]**

## 4. Open the project and build the world in-scene

**[MANUAL / interactive session — on the runner this is blocked by the §1
license wall and the §2 Hub gap; on the owner's machine or any interactive
Windows session with Studio installed, this is the documented flow.]**

1. In Studio Hub: **New Project → Basic Template** → name it → Create;
   the project opens in Unity. **[VERIFIED — Getting Started / Lecture 3]**
   (For a re-run against an existing project: open it; confirm
   `Library/Highrise/hr` exists in the project folder — that proves the
   Studio Package is in. **[VERIFIED path — AI-agent guide]**)
2. Copy the staging artifact's `Assets/` contents into the project,
   letting Unity import them.
3. In the scene, per BUILDER.md **[VERIFIED instructions]**:
   - empty object **`WorldBuilder`** with `builder.lua` attached;
   - empty object **`BuilderTemplates`**, kept **inactive**, stocked with
     one child per asset key the Placements module uses. For
     layout/interior entries the asset key is the entry's own name
     (97 + 29–79 unique names — stock from the Studio catalog / primitives
     per `06-assets/ASSETS_GUIDE.md`). For facade entries the converter
     already reduced `buildFrom` to a small primitive set —
     `UnityBox`, `UnityThinBox`, `UnityCylinder`, `UnityCone`,
     `UnityPrism`, `UnityPointLight` — with the part's real size carried
     as `scale`, so six unit templates stock all 77 facade parts.
     **[ASSUMED — the size-as-scale-on-unit-primitive reading of the
     facade manifest; check: the first facade part placed
     (HouseFoundation, 21.5 × 0.5 × 3.2) must come out that size.]**
   - the `Placements` Module script in the project (from §3.1).
4. Facade state: the facade manifest's `layer` field (`both` / `rest` /
   `monster`) is a visibility state, default **monster** (mouth open,
   door light off, no arms/legs). The builder passes `layer` through but
   does not act on it — set the rest-layer parts inactive in the scene
   after the build. **[VERIFIED data — facade manifest + REFERENCE.md
   ruling; ASSUMED handling — no crew has built a layer switcher yet.]**
5. Atmosphere (sky dome, moonlight, lightning) is **not** in Placements —
   it is scene settings + `Lightning.lua`; apply per
   `11-atmosphere/ATMOSPHERE.md` in the same session. **[VERIFIED —
   ATMOSPHERE.md / converter deliberately skips that manifest.]**

## 5. Play-test

1. **The owner signs in first** (needed for §6, harmless for Play):
   in Unity, **Sign In** button (top-left) → the owner's own Highrise
   account. **[MANUAL — VERIFIED requirement, Getting Started step 3.
   Exactly what it needs: the owner's Highrise credentials, entered by
   the owner, in that Unity session, possibly with a verification code
   sent at that moment. No agent handles it; nothing is stored.]**
2. Press **Play**. The builder runs once on ServerStart and logs every
   placement under the `[Builder]` prefix, grouped by zone, ending with a
   summary line. **Clean = `0 errors`.** `MISSING TEMPLATE` lines name
   asset keys still to stock in §4.3; `INVALID` lines name broken
   manifest entries (fix the manifest in the repo, re-convert, re-copy —
   never hand-edit the generated module). **[VERIFIED — BUILDER.md log
   guide; builder execution-tested under a stubbed API, 2026-11-22]**
3. Walk the world in the Game view (Simulation mode, switch device
   models): spawn → walkway → KEEP AWAY/BEWARE signs → facade (two orange
   eyes, mouth porch, teeth) → front door → teleport inside → poker /
   blackjack / trivia / RPS / radio stations at their anchors → exit door
   back out. Watch the Console for Lua errors the whole time.
   **[VERIFIED checklist basis — PUBLISH.md Layer A]**
4. **Exit Play Mode before uploading — upload is impossible while the
   game is running. [VERIFIED — Lecture 14]** Then save the scene.

## 6. Upload (and release) — the unproven step, stated plainly

**The Upload step is UNPROVEN from any cloud runner and from any agent
session. It has never been done for this project. What follows is the
official documented flow [VERIFIED as documentation — PUBLISH.md §2,
sources S1–S5], which assumes an interactive Unity session signed in as
the owner.**

1. In Unity (signed in as LJAAYY, Play Mode exited): click **Upload**
   (top-right). **[VERIFIED]**
2. If the **Project Validator** window appears, click **Fix** / resolve
   every flagged issue — upload is blocked until clear. **[VERIFIED]**
3. In the Upload World window: first time choose **Upload World** (create
   new), name the world, confirm, **Upload World**. Later builds choose
   **select world** and pick this world — never create a second one.
   **[VERIFIED]**
4. **Upload ≠ Publish.** The uploaded build is private (owner + invited
   members only) until released. Test it in the Highrise app (Worlds tab)
   and with an invited member before releasing. **[VERIFIED — Support
   article, PUBLISH.md Layer B]**
5. Release, in the **Creator Portal** (create.highrise.game), signed in
   as the owner **[MANUAL]**: set name/description/category/tags/max
   visitors/thumbnail; then **Builds → Release** the private build →
   **the owner personally agrees to the terms** → version **1.0.0** →
   **Publish**. **[VERIFIED flow; the terms agreement and final Publish
   confirmation are the owner's clicks.]**
6. The owner's upload pre-approval (2026-11-22) covers *starting* the
   upload without asking again. It does not move the sign-in, the terms
   agreement, or any Unity permission dialog away from the owner —
   **if Unity asks for permission or shows a dialog, a human answers it;
   the agent can't. [VERIFIED — AI-agent guide]**

**Exactly what sign-in the upload needs, in one place:**
- Unity editor: signed into the **owner's Highrise account** (Sign In
  button) — this is what ties the uploaded world to LJAAYY. Plus a Unity
  account/license for the editor itself (§1.4).
- Creator Portal: same owner account, for settings + release.
- Nobody else's credentials work, and none are ever written to the repo,
  a workflow file, or Actions secrets for this project.

## 7. Known integration item — duplicated stations (read before §3)

The interior manifest re-declares the game stations (poker, blackjack,
RPS, trivia, radio, lounge, bar, VIP…) at interior coordinates (X offset
+200) because the design moved the games **inside** the house. The layout
manifest still carries the yard copies. Combined raw: **253 entries, 50
duplicate names, 203 unique**. The builder places the *first* copy of a
name and skips the rest, so the converter does the same and prints every
duplicate. **[VERIFIED by the converter test run, 2026-11-22]**

- Default conversion (no flag): **layout (yard) copies win** — matches
  BUILDER.md's original combined list.
- `--interior-wins`: **interior copies win** (e.g. `PokerTable_Main`
  moves from x=7.5 in the yard to x=207.5 inside). **[VERIFIED by test]**
- The real fix is the planned integration pass on the manifests
  themselves: delete the yard game pits from `01-layout` so the yard is
  pure Monster House, keep the stations only in `10-interior`. Until that
  lands, the finisher must run the converter with `--interior-wins` and
  say so in the run summary. Either way the *count* is 203 — check the
  builder's Play log summary against it.

## 8. Failure fallbacks, in order

1. **Hub won't install headlessly / no installer URL** (expected):
   the automated run still delivers the staging artifact. A human
   installs Studio Hub interactively (5 minutes on any Windows/Mac
   machine) and continues from §4. Nothing is lost — master files are in
   the repo + the artifact.
2. **Unity license wall on the runner** (§1.4): same hand-off — the
   project opens on a machine where a human signed into Unity Hub once.
   This is the documented Route B from FEASIBILITY.md and remains the
   most likely actual finisher path.
3. **Changeset rejected by Hub CLI:** confirm the 2022.3.30f1 changeset
   from Unity's editor archive, re-dispatch `finisher.yml` with the
   `unity_changeset` input; or drop the input (newer Hubs accept
   `--version` alone). **[ASSUMED remedy]**
4. **Builder log shows MISSING TEMPLATE flood:** stock the named asset
   keys under `BuilderTemplates` (§4.3) and press Play again — the
   builder is idempotent, re-runs skip what's placed. **[VERIFIED]**
5. **Project Validator blocks upload:** fix each flagged item in the
   repo/manifests where possible, re-convert, re-copy, re-Play. Do not
   bypass the validator. **[VERIFIED it gates upload]**
6. **Upload itself fails or demands something unexpected** (new dialog,
   account check, world-name clash): **stop and report exactly what it
   asked for.** Do not invent credentials, do not create accounts, do not
   pay for anything (free-only rule). The world name may need a variant
   if taken — that's an owner decision.
7. **Total automation dead end:** the fallback of last resort is the
   owner's own machine running the whole §4–§6 flow with an agent
   assisting in the project folder (Highrise's own documented AI-agent
   setup, STUDIO_SETUP.md) — slower, but every step of it is documented
   and proven by Highrise's own guides.

## 9. What "done" looks like

- [ ] Builder Play log ends `0 errors`, 203 placements accounted for.
- [ ] Layer A walk-through clean; console free of Lua errors.
- [ ] Upload success message seen in the owner's signed-in Unity session.
- [ ] Private build tested in the Highrise app by the owner (+1 member).
- [ ] Creator Portal: settings saved, build released as **1.0.0**,
      published by the owner.
- [ ] Owner has walked the live world in-game (his standing request).
- [ ] `UPDATE_LOG.md` gains the V-entry and the bot DM note is queued per
      the version-delivery rule (bots relaunch separately — PUBLISH.md §5).

## Sources

- Highrise — Getting Started with Highrise Studio:
  https://liveops-create.highrise.game/learn/studio/basics/getting-started
- Highrise — Beginner Guide, Lecture 2 (Studio Hub installer, Windows/Mac;
  Unity 2022.3.30f1; license fix) and Lecture 14 (publishing):
  https://create.highrise.game/learn/studio/create/beginner-guide/lecture-two
- Highrise — Build a World with an AI Agent (`Library/Highrise/hr`,
  dialogs are human-only):
  https://production-create.highrise.game/learn/studio/basics/build-with-an-ai-agent
- Highrise — Studio Hub download page (button-only download, no published
  direct URL): https://create.highrise.game/highrise-studio
- Unity — Hub advanced deployment (silent install `/S`, registry check):
  https://docs.unity.cn/2019.1/Documentation/Manual/GettingStartedHubAdvancedConsiderations.html
- VRChat VCC docs — Unity Hub headless CLI (`-- --headless install`,
  official Hub CDN URL): https://vcc.docs.vrchat.com/vpm/cli/
- Project docs: STUDIO_SETUP.md, PUBLISH.md, FEASIBILITY.md,
  repo/07-pipeline/PIPELINE.md, repo/05-builder/BUILDER.md (all read
  2026-11-22 for this runbook).
