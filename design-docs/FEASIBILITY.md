# Can Jett Literally Build a Highrise World From This Cloud VM?

**Question:** Faceless (Highrise: LJAAYY) wants Jett to *literally* design and place things — create the actual world — ideally by running Highrise's official "Build a World with an AI Agent" path on this Linux cloud VM ("on a cloud server").

**Researched:** 2026-11-22 ~12:37 PST. No installs attempted, nothing downloaded, no sign-ins, no tokens/passwords handled.

## Short verdict

**Not on this VM, not by the official path — and the blocker is Highrise's own tooling, not effort.**
Highrise Studio Hub — the app that creates a project and installs the right Unity + Studio Package — is **Windows/Mac only**. There is no Linux Hub. Without a Hub-created project there is no `Library/Highrise/hr` launcher, and the official AI-agent commands only work inside a project that is **open in Unity**, signed in to the creator's Highrise account, with a human present to answer Unity dialogs. This VM also fails Unity's own requirements on several independent counts (see below).

The realistic way Jett "literally designs it" is **Route B**: the user runs Studio Hub + Unity on their own Windows/Mac computer (that's the setup Highrise designed the AI-agent path for), and Jett does the designing/building work in that project — either via an AI coding agent running in the project folder on that machine, or by Jett authoring the project's scene/Lua files from here and the user syncing them in and hitting Play/Upload. Details and honest limits for each route below.

---

## 1. What the official AI-agent path actually is

Source: Highrise, "Build a World with an AI Agent"
https://production-create.highrise.game/learn/studio/basics/build-with-an-ai-agent

- AI coding agents "such as Claude Code and Codex can build your world from a description, **working in a Highrise Studio project you have open in Unity**."
- Step 1: **Create a project in Studio Hub and open it in Unity** (per Getting Started). On open, Studio adds `CLAUDE.md` and `AGENTS.md` to the project folder telling an agent how to work there.
- Step 2: Open a terminal **in the project's folder** (example given: `Documents/Highrise Studio/Projects/My World`), start Claude Code or Codex, describe the world ("Build me a Highrise world where players race to collect coins").
- What the agent does: uses the project's launcher **`Library/Highrise/hr`**, runs `Library/Highrise/hr hr_guide` first, then uses Highrise Studio commands to **edit scenes, write Lua scripts, and play-test the world in Unity**.
- Hard limits stated in the guide itself:
  - "Highrise Studio's commands **only work while the project is open in Unity**. If Unity is closed, the agent runs `Library/Highrise/hr open` to open it."
  - "**If Unity asks for permission or shows a dialog, answer it: the agent can't.**" — a human must babysit Unity dialogs.
  - Commands need the Unity command line tools; if missing, the agent asks before installing them.
  - Finishing: "test it with the **Play** button in Unity and **publish it** as described in Getting Started."

So the agent is a *co-pilot inside a live, signed-in Unity session on the machine running Unity* — not a headless cloud builder. The agent binary itself (Claude Code / Codex) is a terminal program that could run anywhere, but everything it drives (`hr`, scene editing, play-test) is bound to that local Unity process.

## 2. Getting Started — install, sign-in, publish requirements

Source: Highrise, "Getting Started with Highrise Studio"
https://production-create.highrise.game/learn/studio/basics/getting-started
and Lecture 2, "Installing Tools"
https://create.highrise.game/learn/studio/create/beginner-guide/lecture-two

- **Studio Hub download: "installer (Windows or Mac)"** — Lecture 2, Step "Downloading Highrise Studio Hub". No Linux installer is offered anywhere in the official docs or the Studio Hub release posts (forum release notes list only Windows and macOS download links, e.g. Studio Hub 0.5.2 / 0.3.0 / 0.2.2 on createforum.highrise.game). Hub is also explicitly not usable on phone/tablet: "the studio requires you to work with Unity, which is a heavy software and only accessible on a PC."
- Hub then installs **Unity Hub + Unity Editor + the Highrise Studio Package**, and creates/opens projects.
- **Unity version pinned: Highrise Studio currently supports Unity 2022.3.30f1** (Lecture 2). A Unity account and a Unity Editor license are required — the documented fix for "No valid Unity Editor license found" is to sign into Unity Hub and add a free personal license.
- Project flow: Studio Hub → New Project → Basic Template → project loads in Unity.
- **In Unity: "Sign in to your Highrise account via the `Sign In` button"** (Getting Started, Step 3). This is the creator's own account sign-in — it must be done by Faceless, in person; Jett does not handle credentials.
- Publish flow (Getting Started, Steps 5–6): test with Play → **Upload button in Unity** → name the world → Creator Portal → Builds → Release → Publish. Publishing is therefore also tied to that signed-in Unity/Portal session, i.e. to the user's machine and account.

## 3. Unity on Linux in general (separate from Highrise)

Source: Unity system requirements for 2022.3
https://docs.unity3d.com/2022.3/Documentation/Manual/system-requirements.html

- A Linux Unity Editor does exist, but for 2022.3 it supports only **Ubuntu 20.04 and Ubuntu 18.04**, x64, **OpenGL 3.2+ or Vulkan-capable Nvidia/AMD GPU**, **GNOME desktop on X11** with Nvidia proprietary or AMD Mesa drivers, **8 GB RAM recommended**, and — critically — **"supported on workstations or laptop form factors, running without emulation, container or compatibility layer."**
- So even stock Unity 2022.3 does not support this VM's OS version, a container, or a GPU-less virtual display. (Newer Unity 6 supports Ubuntu 24.04, but Highrise pins 2022.3.30f1, so that doesn't help.)

## 4. This VM — measured facts (2026-11-22 ~12:37 PST)

Commands run: `uname -a`, `cat /etc/os-release`, `df -h`, `free -h`, `nproc`/`lscpu`, `ls /dev/dri`, checks for existing Unity/Studio installs, `uptime`.

| Item | This VM | Requirement | Fit |
|---|---|---|---|
| OS | Ubuntu 24.04.5 LTS, x86_64, KVM container/VM | Studio Hub: Windows/Mac only. Unity 2022.3 Linux: Ubuntu 20.04/18.04, no container | ❌ both |
| CPU | 4 vCPU visible (AMD EPYC), but runtime allocation is ~1.5 shared CPUs | Unity Editor is heavy; play-testing a 3D world | ❌ underpowered |
| RAM | 7.7 GiB total visible, ~6 GiB shared limit, <1 GiB free at check time | 8 GB recommended for Editor alone | ❌ |
| GPU / display | **No GPU, no `/dev/dri`**, no `DISPLAY`; Xvfb + Mesa software GL are present | Real OpenGL 3.2+/Vulkan GPU + GNOME/X11 | ❌ (Xvfb/Mesa is a workaround Unity does not support) |
| Disk | `/home` volume: 148 GB free — fine. Root overlay: only 7.5 GB — too small for a Unity install if it landed there | Unity + project typically tens of GB | ⚠️ workable only if everything is placed on `/home` |
| Installed | No Unity, no Unity Hub, no Highrise Studio anywhere on the box | — | — |
| Stability | **Host had been up 6 minutes at check time** — this VM reboots frequently and without warning (it killed both Highrise bots on 2026-11-02 and has rebooted repeatedly since) | A Unity project session must stay open for the whole build; the `hr` commands die with it | ❌ fatal for long build sessions |

Any one of the Hub's Windows/Mac-only limit, the container/GPU/RAM limits, or the reboot cycle would sink Route A on its own. Together they are conclusive for the *official* path.

---

## 5. Routes, ranked

### Route A — Install Studio + Unity on this VM and drive it via `hr`
**Verdict: ❌ Not feasible via the official path. Do not attempt as the plan.**

- Studio Hub has no Linux build, so there is no supported way to create a project, install the pinned Unity 2022.3.30f1 + Studio Package, or generate `Library/Highrise/hr` here.
- A hand-rolled bypass (install Linux Unity 2022.3 directly from Unity, side-load the Studio Package without Hub) is undocumented by Highrise, would run on an unsupported OS (24.04 vs 20.04/18.04), in a container Unity explicitly excludes, with no GPU, ~1.5 shared CPUs and <8 GB RAM — and the VM's frequent reboots would kill the mandatory always-open Unity session mid-build. Even if Unity limped open under Xvfb, every dialog ("the agent can't answer it") and the Highrise sign-in + Upload steps still need a human at that session.
- Estimated chance of a publishable world by this route: very low; expected cost: hours of multi-GB installs (Unity Editor alone is several GB, plus package/project caches) for a likely dead end. **Not recommended.**

### Route B — User's own computer runs Studio/Unity; Jett does the building work in that project ⭐ Most promising
**Verdict: ✅ Feasible — this is exactly the setup Highrise designed the AI-agent guide for. Two variants:**

- **B1 (official, smoothest):** On Faceless's Windows/Mac computer: install Studio Hub (which installs Unity 2022.3.30f1 + Studio Package), create a Basic Template project, sign into Unity with a Unity account (free personal license) and sign into his Highrise account in Unity — both sign-ins done by Faceless himself. Then open a terminal in the project folder and run an AI coding agent there (Claude Code or Codex, per the guide), and describe the world. The agent runs `hr hr_guide` and edits scenes / writes Lua / play-tests in the open Unity.
  - Honest note: in B1 the hands-on agent is the agent running *on his computer*, working from his description. Jett (this Muse, on the VM) can supply the exact world design, the description/prompt to give it, and review/fix its Lua and scene work if the project files are shared back — but Jett's hands are not directly on that keyboard.
- **B2 (Jett authors the files from here):** A Unity/Studio project is just a folder of files (scene `.unity` YAML, Lua scripts, project settings). Faceless creates the empty project in Studio Hub once, then syncs the project folder with Jett (e.g. a private Git repo or a shared Drive folder both sides can access). Jett then literally authors/edits the scene files and Lua scripts in that folder from this VM — designing and "placing" things as file edits — and Faceless reopens/refreshes the project in Unity, presses Play to test, and presses Upload to publish.
  - Limits: Jett cannot run `hr` commands, play-test, or see the 3D scene render from here (those need the open Unity on his machine), so iteration is: Jett edits → Faceless opens/plays → reports back or shares screenshots → Jett adjusts. Scene-YAML hand-editing is also more error-prone than driving Unity live, so B2 works best for scripted/procedural worlds and Lua gameplay, less well for delicate hand-placed décor.
  - Access needed: a sync channel for the project folder (Git is cleanest), set up by Faceless; no credentials shared with Jett — his Highrise/Unity sign-ins stay on his machine.

### Route C — Anything else documented?
**Verdict: ❌ No other official route found.**
- No Highrise web/cloud world editor and no world-building API were found in the official docs: worlds are built in Studio/Unity and published via Unity Upload + Creator Portal. (The Highrise bot API Jett already uses moves bots in rooms; it cannot create or edit worlds.)
- The in-game room editor on Faceless's phone is his own manual tool — Jett has no connection to it. Jett can still design a room for it (theme, layout map, item-by-item placement plan), but the placing would be by Faceless's hand. That's a fallback, not the "literally build it" ask.

---

## 6. Exact next step for the most promising route (Route B)

1. **Faceless, on his Windows/Mac computer (est. 30–60 min, mostly downloads):** install Highrise Studio Hub from create.highrise.game → let it install Unity Hub, Unity 2022.3.30f1 and the Studio Package → sign into Unity Hub (Unity account, free personal license) → in Studio Hub create a New Project (Basic Template) → in Unity, Sign In with his Highrise account. All sign-ins are his alone.
2. **Decide B1 vs B2 (one short chat message):** B1 if he's happy describing the world to an agent on his own machine with Jett supplying the design/prompt; B2 if he wants Jett personally authoring the files — then he sets up a private Git repo (or shared folder) containing that new project folder and gives Jett access to the repo/folder (not to any account password).
3. **Jett (est. ~15 min once the project/design exists):** writes the world design + the exact agent prompt (B1) or begins authoring scenes/Lua in the synced project (B2), starting from the world description Faceless gives (theme, gameplay, size).
4. **Test/publish stays with Faceless:** Play button in Unity to test; Upload in Unity → Creator Portal → Builds → Release → Publish.

**Total time estimate to a first testable world once Step 1 is done:** roughly 1–3 hours of build iteration for a small first world (procedural/scripted content faster; hand-placed décor slower) — marked as an estimate; the Step 1 downloads are the long pole and depend on his connection.

## Sources
- Highrise — Build a World with an AI Agent: https://production-create.highrise.game/learn/studio/basics/build-with-an-ai-agent
- Highrise — Getting Started with Highrise Studio: https://production-create.highrise.game/learn/studio/basics/getting-started
- Highrise — Lecture 2: Installing Tools (Hub "Windows or Mac"; Unity 2022.3.30f1; license fix): https://create.highrise.game/learn/studio/create/beginner-guide/lecture-two
- Highrise Create Forum — Studio Hub release posts (Windows/macOS links only): https://createforum.highrise.game/t/studio-hub-0-5-2/1469
- Unity — System requirements for Unity 2022.3: https://docs.unity3d.com/2022.3/Documentation/Manual/system-requirements.html
- This VM: `uname`, `/etc/os-release`, `df`, `free`, `lscpu`, `/dev/dri` and install checks run 2026-11-22.
