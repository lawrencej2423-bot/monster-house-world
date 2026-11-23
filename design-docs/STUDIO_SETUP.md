# Highrise Studio Setup Playbook — Building a World for Faceless with an AI Agent

Researched 2026-11-22 from Highrise's official creator docs (sources at the bottom).
This is a playbook only — nothing has been installed and nobody has signed into anything yet.

**The core idea (official):** Highrise explicitly supports AI coding agents building a
world from a description. The agent works inside a Highrise Studio project that is
**open in Unity**, driving it through the project's own launcher, `Library/Highrise/hr`.
The human's jobs are only: install the tools, create the project, sign in with their
own Highrise account, and answer any Unity permission dialogs. Everything else —
scene editing, placing objects, Lua scripting, play-testing — the agent does.

---

## The biggest blocker (read this first)

**Highrise Studio Hub is a Windows-or-Mac installer. There is no Linux version in the
official docs.** Jett runs on a Linux cloud VM, so Studio + Unity **cannot run on
Jett's server**. The project has to live on a Windows or Mac computer where:

1. Unity is installed and the project is **open in Unity** (Studio's commands only
   work while the project is open), and
2. The user is present to sign in and to answer Unity dialogs (the agent can't).

So the realistic setup is: **the user's own computer runs Studio/Unity, and the agent
works in that project's folder from a terminal opened in the folder.** If the user
has no Windows/Mac computer available for this, there is no documented route — that
is the one hard gate on the whole plan.

Secondary blockers / friction points:

- **Sign-in is the user's alone.** Publishing requires signing into Unity with the
  user's own Highrise account (the `Sign In` button in Unity). Jett never handles
  the user's credentials, password, or any verification code for this — the user
  signs in themselves, on their own machine.
- **Unity dialogs:** "If Unity asks for permission or shows a dialog, answer it:
  the agent can't."
- **Unity command line tools:** the `hr` commands need them. If they're missing,
  the agent asks before installing them — it does not install silently.
- **Unity version:** the beginner course states Highrise Studio currently supports
  **Unity 2022.3.30f1**. Studio Hub's guided setup installs the right Unity +
  Highrise Studio Package; don't hand-pick a different Unity version.

---

## Step-by-step setup

### Phase A — Install the tools (user, on their Windows/Mac computer)

1. Download and install **Highrise Studio Hub** from the Highrise Studio Hub
   download page (Windows or Mac installer).
2. Open Studio Hub and follow its "Getting Started" steps — it walks through
   installing **Unity Hub and the Unity Editor** and the **Highrise Studio Package**.
   (Manual alternative from the docs: install Unity Hub yourself, sign into Unity
   Hub with a Unity account, then Installs → Install Editor → **2022.3.30f1** —
   but the Studio Hub guided route is the recommended one.)
3. Install **Visual Studio Code** (or another code editor) for scripting.
4. If using VS Code, install the **Highrise Studio Tools** extension from the
   Extensions view.

### Phase B — Create the project (user, in Studio Hub)

1. In Studio Hub, click **New Project**.
2. Choose the **Basic Template**. (The Getting Started guide says "Basic Template
   or another template"; the beginner course's Lecture 3 suggests the empty
   template for a first project. For a from-scratch AI-built world, Basic is the
   documented default — pick Basic unless the world concept needs a specific
   starter template.)
3. Name the project and choose where to save it
   (the AI-agent guide's example path is `Documents/Highrise Studio/Projects/My World`).
4. Click **Create Project** and wait for the project to load in Unity
   (can take a few minutes).

### Phase C — What Studio adds to the project (automatic)

When the project opens in Unity, Highrise Studio automatically adds two files to
the project folder:

- **`CLAUDE.md`**
- **`AGENTS.md`**

Per the official guide, "these files tell an agent how to work in the project."
They are the agent's standing instructions for that project — Jett reads and
follows them, and does not overwrite them.

### Phase D — Sign in (user only, inside Unity)

1. In Unity, click the **Sign In** button (top-left of the Unity editor in the
   beginner course layout) and sign in with **your own Highrise account**.
   This is what ties the world to your account for uploading/publishing.
2. Stay nearby: if Unity pops a permission request or dialog at any point during
   the build, you answer it — the agent cannot.

### Phase E — Start the agent (in the project folder)

1. Open a terminal **in the project's folder**
   (e.g. `Documents/Highrise Studio/Projects/My World`).
2. Start the AI coding agent there (the guide names Claude Code and Codex as the
   supported examples).
3. Give it the world description in plain words, e.g. the guide's example:
   *"Build me a Highrise world where players race to collect coins."*
   For Faceless's world, this is where the agreed theme/concept gets handed over —
   Jett designs from that description rather than the user placing anything.

### Phase F — How the agent actually builds (the `hr` launcher)

The agent does not click around the Unity GUI. It uses the project's launcher:

```
Library/Highrise/hr
```

Exact sequence the agent follows:

1. **Learn first:** run `Library/Highrise/hr hr_guide` before anything else —
   this "teaches it how to build Highrise worlds" (the official workflow, not
   optional).
2. **If Unity is closed:** run `Library/Highrise/hr open` to open the project in
   Unity. Studio's commands only work while the project is open in Unity.
3. **Build:** use Highrise Studio's commands (via the launcher) to:
   - edit scenes (add/place objects, terrain, buildings, props),
   - write **Lua** scripts for interactivity/gameplay (Highrise scripting is Lua,
     not C#),
   - **play-test** the world in Unity.
4. **If the Unity command line tools are missing:** the agent asks before
   installing them — expect a prompt here for the user to approve.
5. Iterate: describe changes → agent edits scene/scripts → play-test again.

### Phase G — Test, upload, publish (exact official sequence)

1. **Test** thoroughly with the **Play** button in Unity.
2. Click the **Upload** button in Unity to upload the world; give the world a name.
3. Optionally customize the world's information on the **Creator Portal**.
4. Go to the world's dashboard on the Creator Portal and open the world.
5. Go to **Builds** and click **Release**.
6. Give the world a version number (e.g. `1.0.0`) and add release notes if wanted.
7. Click **Publish**.

⚠️ "You cannot publish a world with no build uploaded. Make sure to upload a
build before releasing your world."

---

## The exact sequence Jett would follow, end to end

1. Confirm the user has a Windows/Mac computer for Studio (the hard gate above).
2. User installs Studio Hub → Unity (2022.3.30f1 via Hub guidance) → Highrise
   Studio Package → VS Code + Highrise Studio Tools extension. *(User's hands;
   Jett can walk them through it step by step.)*
3. User creates the project in Studio Hub: **New Project → Basic Template** →
   name/location → Create Project → project opens in Unity.
4. User signs into Unity with their own Highrise account (Sign In button).
   **Jett never touches credentials.**
5. User opens a terminal in the project folder and starts the agent there;
   `CLAUDE.md` / `AGENTS.md` are already in the folder from Studio.
6. Jett runs `Library/Highrise/hr hr_guide` first, then
   `Library/Highrise/hr open` if Unity isn't open.
7. Jett builds from the agreed world description: scene edits + object placement
   via Studio commands, Lua scripts for any games/interactivity, play-tests in
   Unity. User answers any Unity dialogs and approves the command-line-tools
   install if prompted.
8. Final Play test together; fix anything the user doesn't like by description.
9. Upload from Unity (Upload button, name the world) → Creator Portal →
   world's dashboard → Builds → Release → version `1.0.0` → Publish.
   *(The Upload/Publish clicks happen in the user's signed-in session.)*

---

## What Jett can and cannot do in this setup

| Can do | Cannot do |
|---|---|
| Design the world from a description | Run Studio/Unity on the Linux cloud VM (no Linux Studio Hub) |
| Edit scenes, place objects, write Lua via `Library/Highrise/hr` | Sign in with the user's Highrise account or handle any credential/code |
| Play-test in Unity via the launcher | Answer Unity permission dialogs |
| Run `hr open` to reopen the project in Unity | Build while the project is closed in Unity (commands require it open) |

---

## Sources (official Highrise Create docs, read 2026-11-22)

- Build a World with an AI Agent —
  https://production-create.highrise.game/learn/studio/basics/build-with-an-ai-agent
- Getting Started with Highrise Studio —
  https://liveops-create.highrise.game/learn/studio/basics/getting-started
- Beginner Guide, Lecture 2: Installing Tools (Studio Hub Windows/Mac installer;
  Unity 2022.3.30f1) —
  https://create.highrise.game/learn/studio/create/beginner-guide/lecture-two
- Beginner Guide, Lecture 3: Creating Your First Project —
  https://create.highrise.game/learn/studio/create/beginner-guide/lecture-three
