# PUBLISH.md — Publishing & Testing Checklist for Faceless's Highrise World

Owner: Faceless (Highrise username **LJAAYY**). Bots: **LJAAYYBot** (bot #1) and **LJAAYY2** (bot #2).
Rule for this whole file: **Upload ≠ Publish.** Uploading a build only sends it to Highrise's servers — the World stays private until a build is **Released** in the Creator Portal. An uploaded-but-unreleased build is visible only to the owner and members he has added. [S1][S3]

---

## 1. Play-testing — how it works

Testing happens in three layers. Do them in order; don't skip to release.

### Layer A — In-editor test (Unity / Highrise Studio)
- [ ] Open the project in Unity from Studio Hub.
- [ ] Press the **Play** button in the Unity toolbar to run the world in the editor. Walk the spawn, every zone, every interactive/Lua feature. [S2]
- [ ] Check the Game view in **Simulation** mode and switch device models to preview how it looks on different phones/devices. [S4]
- [ ] Watch the Console for Lua/script errors while playing; fix before moving on.
- [ ] **Exit Play Mode when done — you cannot upload while the game is running.** [S3]

### Layer B — Private in-app test (after first upload, before release)
- [ ] Upload a build (see §2). Uploaded builds can be opened **in the Highrise app before they are public** — the world appears under the **Worlds** tab for the owner. Test on a real phone, not just the editor. [S1][S3]
- [ ] Add testers: Creator Portal → world main page → **Members** tab → **invite member** → search username. Invited members can enter the world before it goes public and give feedback. [S3]
- [ ] Test with at least one other real player in the same instance (multiplayer behaviour, seats/anchors, games).
- [ ] Log every bug found; fixes go into the next build (see §3 — updating).

### Layer C — Post-release smoke test
- [ ] After Release (§2), reopen the app, find the world under Worlds, join as a normal player would, and confirm it loads the released build.
- [ ] If it doesn't show for other players: first check a build was actually **released** (not just uploaded), then give it a little time and reopen the app. [S1]

---

## 2. Publishing a World — step by step

Per the official Support article and Creator Portal guides: **upload from Studio → set details in the Creator Portal → test in the app → release a build from the Creator Portal.** [S1]

### Upload (in Unity)
- [ ] Exit Play Mode. [S3]
- [ ] Confirm you are **signed into your Highrise account inside Unity** (Sign In button, top-left of the editor). [S2][S3]
- [ ] Click **Upload** (top-right corner of Unity). [S3]
- [ ] If the **Project Validator** window pops up, click **Fix** / address every issue it flags before proceeding — upload is blocked until they're resolved. [S3][S5]
- [ ] In the Upload World window: choose **Upload World** to create a new world (first time) — or **select world** to push a build to the existing one. Name the world, confirm settings, click **Upload World**. [S3][S5]
- [ ] Wait for the success message, then continue in the **Creator Portal** (create.highrise.game). [S5]

### World settings (Creator Portal — set these before release)
- [ ] **Name** — the public world name.
- [ ] **Introduction / description** — short intro plus a fuller description of what the world is and what players do there. [S3][S5]
- [ ] **Category** — pick the category that fits. [S3]
- [ ] **Tags** — add tags so players can find it in search. [S3][S5]
- [ ] **Max visitors per instance** — set the maximum number of users per instance. [S3]
- [ ] **Thumbnail + gallery images** — upload a thumbnail and gallery screenshots. [S3]
- [ ] **Room subscription** — decide on/off. Enabling it lets you charge users for creating private rooms in your world (monetisation option; leave off for a free public launch unless Faceless says otherwise). [S3]
- [ ] Click **Save** to finalise the details. [S5]
- [ ] Content check: the World must follow the Highrise Community Guidelines and Creator Terms, and only use content you have the rights to — rule-breaking worlds can be removed. [S1]

### Release (Creator Portal — this is what makes it public)
- [ ] Go to the **Builds** tab. [S2][S3]
- [ ] Find the **Private** build and click **Release**. [S3]
- [ ] **Agree to the terms and conditions** (Faceless personally — see §4). [S3]
- [ ] Assign a version number — **1.0.0** for launch. [S2][S3]
- [ ] Add release notes (optional at launch, recommended for updates). [S3]
- [ ] Click **Publish**. The world is now live and findable with the other Worlds in the app. [S1][S2]

> No build uploaded = nothing to publish. A world with no released build stays private. [S2][S3]

---

## 3. Updating a live World

Same pipeline, repeated — players always get the newest released build. [S1]

- [ ] Make changes in Unity, play-test (Layer A).
- [ ] Exit Play Mode → **Upload** → in the Upload World window choose **select world** and pick this world (do NOT create a new one). [S3]
- [ ] Test the new private build in the app / with members (Layer B).
- [ ] Creator Portal → **Builds** → **Release** the new build with a **new version number** (e.g., 1.0.1 for fixes, 1.1.0 for new features) and release notes describing what changed. [S1][S3]
- [ ] Smoke-test in the app (Layer C).

---

## 4. What Faceless personally must do (nobody else can)

These steps are tied to his account and identity — Jett/agents cannot do them, and no password, code, or token should ever be shared in chat or written in a file.

- [ ] **Sign in to Highrise inside Unity** (Sign In button) as LJAAYY, including any verification code or approval prompt that appears at that moment. [S2]
- [ ] **Sign in to the Creator Portal** (create.highrise.game) as LJAAYY for world settings and release.
- [ ] **Answer Unity permission dialogs** if any pop up while an agent is working in the project — per the official AI-agent guide, the agent can't answer those; a human has to. [S6]
- [ ] **Agree to the terms and conditions** at Release and click the final **Publish** confirmation (or explicitly tell Jett the build is approved and press it himself live). [S3]
- [ ] **Supply each bot's API token at relaunch time** through the secure entry flow when asked — tokens are not stored anywhere the bots/watchdog can use, so a relaunch cannot happen without him present (see §5). Never paste tokens into documents.
- [ ] Decide the judgement calls: final world **name**, **public vs. private**, **room subscription on/off**, and max visitors.

---

## 5. Launch-day checklist

### Before release
- [ ] Final build passes Layer A (editor) and Layer B (in-app, with at least one invited member) testing with no open blockers.
- [ ] World settings complete (§2): name, description, category, tags, max visitors, thumbnail + gallery, room subscription decision made.
- [ ] Faceless signed in to Unity and the Creator Portal (§4).

### Release
- [ ] Upload final build → Creator Portal → Builds → Release **v1.0.0** → Publish. [S2][S3]
- [ ] Layer C smoke test: join the live world from the app as a player; confirm spawn, movement, and headline features work.

### Station the bots (LJAAYYBot + LJAAYY2)
Prerequisite, known state: **both bots are currently DOWN** (killed by the Nov 2 host restart) and neither token is stored — each needs a manual relaunch with Faceless present to supply its token (§4). Do this on launch day, in this order:

- [ ] Get the live world's **room/world ID**: open the world in the app → room info → **Share this Room** → the ID is in the invite link; or Dashboard → Creations → Copy Room ID. (A bot is not tied to a room — the room ID is chosen when the bot code runs.) [S7]
- [ ] Give each bot **designer rights** to the world/room if it will enter as a bot — bots need designer rights to the room they are entering. [S7]
- [ ] Relaunch **LJAAYYBot** pointed at the new world's room ID; confirm "Bot is live" in its log.
- [ ] Relaunch **LJAAYY2** pointed at the same room ID (her own token — the two bots never fight over one token).
- [ ] **Verify in-room by WHISPER, not DM** — a whisper proves the bot is actually present in the room with you; a DM only proves its inbox works. Whisper each bot and confirm it answers, and visually confirm both avatars are in the world.
- [ ] Run the bot smoke commands in-room: `!help`, one game command, and one `!muse` relay test (LJAAYY2).
- [ ] Leave both bots running in the world; note that a host/VM restart kills them and they cannot auto-relaunch (token not stored) — if they vanish, it's a relaunch, not a bug hunt.

### Announce
- [ ] Share the world link/invite with friends and the Highrise community.
- [ ] Watch first-player feedback; queue fixes as a v1.0.1 update (§3).

---

## Sources (official Highrise only)

- **[S1]** Support — "How do I publish or update a World?" — https://support.highrise.game/en/articles/17758786-how-do-i-publish-or-update-a-world (updated 2026-11-03): upload from Studio, details in Creator Portal, test in app, release a build; updates = upload + release a new build with a new version; unreleased builds are owner/members-only; Community Guidelines / Creator Terms apply.
- **[S2]** Create — "Getting Started with Highrise Studio" — https://liveops-create.highrise.game/learn/studio/basics/getting-started : Studio Hub → Unity + Studio Package install; Sign In in Unity; Play button testing; Upload; release via Creator Portal Builds with version number; cannot publish with no build uploaded.
- **[S3]** Create — "Lecture 14: Publishing Your Game" — https://create.highrise.game/learn/studio/create/beginner-guide/lecture-fourteen : exit Play Mode before upload; Project Validator; select world vs. Upload World; name/introduction/category/tags/max visitors/thumbnail/gallery; room subscription; Members tab invites for pre-public testing; Builds → Release Private build → agree terms → version → Publish; unreleased = private.
- **[S4]** Create — "Lecture 3: Creating Your First Project" — https://create.highrise.game/learn/studio/create/beginner-guide/lecture-three : Game view Simulation mode with device models; Play button tests in editor.
- **[S5]** Create — "Publish Your World" — https://production-create.highrise.game/learn/studio/distribute/publishing-world : Play-button test → Upload (upper right) → name → Upload World → Creator Portal details (introduction/description, tags, thumbnail, category, max users) → Save → test again in app under Worlds tab / Members invites → Builds → Release with version number.
- **[S6]** Create — "Build a World with an AI Agent" — https://production-create.highrise.game/learn/studio/basics/build-with-an-ai-agent : Studio commands only work while the project is open in Unity; if Unity asks for permission or shows a dialog, the human must answer it — the agent can't.
- **[S7]** Create — Bot guides, "Creating a Bot" — https://dev3-create.highrise.game/learn/bots/guides/creating-a-bot : room ID from the in-app "Share this Room" link; bots need designer rights to the room they enter; bot API token is created per-bot on the creator Dashboard (Bots & API Keys).

*Prepared 2026-11-22. No sign-ins performed and no secrets used in preparing this checklist.*
