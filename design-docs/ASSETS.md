# Highrise World — Assets & Placement List
## Gamblers' Hangout / Casino Lounge for LJAAYYBot + LJAAYY2

Researched 2026-11-22 from official Highrise sources only (create.highrise.game, support.highrise.game, createforum.highrise.game). Anything not in a source is marked **[GUESS]**.

---

## 1. Read this first: World assets ≠ Room furniture

There are two different systems, and they do **not** share inventory:

- **A Highrise World (this project)** is built in **Highrise Studio** (Unity-based). Everything placed in it comes from the **Highrise Asset Catalog inside Studio**, from Unity primitives, or from custom assets imported/uploaded by the creator. The user's in-app furniture collection is **not** used here.
  - Source: support.highrise.game, "Highrise Worlds" — Worlds are "immersive virtual spaces… uniquely crafted by creators using Highrise Studio," with "3D modeling, world building, and Lua scripting," working "in conjunction with Unity." https://support.highrise.game/en/articles/9268957-highrise-worlds
- **A Highrise Room** is decorated in-app from furniture the player **owns**: tap the pencil icon, and the menu shows "your glorious collection of furniture"; search finds an item only "if you own it."
  - Source: support.highrise.game, "How Do I Design My Room and Add More Furniture?" https://support.highrise.game/en/articles/8043385-how-do-i-design-my-room-and-add-more-furniture

**Consequence:** nothing on this list needs the user to own the in-app version, and nothing on this list is bought from the in-app shop. Costs, where any exist, are inside Studio's Asset Catalog (see §7).

---

## 2. How the Asset Catalog works (verified)

- Integrated into Unity with the Highrise Studio Package; opens below the scene editor, or via **Highrise > Studio > Asset Catalog**. Search, browse, filter, download/install, and import objects directly into the world.
- Search by keyword — the official examples are literally `tree`, `chair`, `car`.
- Filter by category, including **Furniture**, **Landscapes**, **Vehicles**, "and more."
- A **Smart object** filter shows assets containing scripts / advanced functionality.
- Download flow: select asset → **Download** in the Inspector or on the thumbnail → auto-installed in the project → drag and drop into the scene.
- The catalog holds "premade assets, including models, decals, audio files, and plugins."
  - Source for all of the above: create.highrise.game, "Guide to Using the Highrise Asset Catalog." https://create.highrise.game/learn/studio/create/assets/highrise-catalog
- The importing-assets guide describes the catalog as offering "an extensive array of **free low-poly assets** across diverse categories such as Furniture, Landscapes, and Vehicles," and says assets can also be imported from the **Unity Asset Store** and from `.unitypackage` files / local files.
  - Source: create.highrise.game, "Importing Assets" overview. https://dev-create.highrise.game/learn/studio/create/assets/overview
- One concrete, named catalog item is verified: a **"Wooden Bench," available in the Highrise Assets Catalog under the "Furniture" category** — used as the example in the official Anchor Points guide.
  - Source: create.highrise.game, "Anchors" / Lecture 8: Anchor Points. https://create.highrise.game/learn/studio/create/environment/anchor
- **No official page found lists the full catalog inventory or individual item names/prices.** The catalog is browsed inside Studio, not on the web. So every specific item below is a *search plan* (what to type into the catalog), not a confirmed listing — except the Wooden Bench above.

### Templates (starting point)
- Studio Hub → New Project → choose the **Basic Template** "or another template" (official Getting Started). The beginner course (Lecture 3) suggests the **empty template** for a first project.
  - Sources: https://liveops-create.highrise.game/learn/studio/basics/getting-started · https://create.highrise.game/learn/studio/create/beginner-guide/lecture-three
- A **Kaiju Template** also exists (mentioned in the official creator forum as a Studio Hub template whose project contains WorldScene / HumanoidCharacter prefabs). Not needed for a lounge, just proof more than one template exists.
  - Source: https://createforum.highrise.game/t/how-to-edit-player-parameters/1068
- **Recommendation:** start from **Basic Template** — it comes with the scene/character setup, and the Asset Catalog auto-opens on new projects (per Studio Package 0.6.8 notes, https://createforum.highrise.game/t/studio-package-0-6-8/1118/1). **[GUESS]** that Basic is faster than Empty for a social lounge; no game mechanics are needed on day one.

---

## 3. Placement list — by zone

Legend for **Source type**:
- **CAT-FREE** = Asset Catalog, in the free low-poly range (the catalog's general offer; the specific item's price is only visible in Studio)
- **CAT-GOLD?** = Asset Catalog, but this kind of item *may* require Gold — official Lecture 5 warns "Some assets in the Highrise Assets Catalog may require purchase with Gold." https://create.highrise.game/learn/studio/create/beginner-guide/lecture-five
- **UNITY** = built with Unity/Studio primitives, lights, materials — no catalog purchase
- **CUSTOM** = custom-uploaded / imported asset (Unity Asset Store, local model, or self-made) — see §6
- **BUILT-IN** = ships with the Highrise Studio Package itself

### A. Poker area
| # | Item | Qty | Catalog search terms | Source type | Notes |
|---|------|-----|----------------------|-------------|-------|
| A1 | Round / oval game table (poker table substitute) | 2 | `table`, `round table`, `game table`, `poker` | CAT-FREE / CAT-GOLD? | No "poker table" listing is confirmed anywhere official — **[GUESS]** a generic round table + green material/felt-look top (material change is a normal Unity Inspector edit) reads as a poker table. A true casino poker table is the top **CUSTOM** candidate (§6). |
| A2 | Chairs with sit anchors around each table | 8 per table (16) | `chair` | CAT-FREE | `chair` is an official catalog search example. Add **Anchor Points** so avatars actually sit (see §5). |
| A3 | Chip stacks / card props on the table | 4–6 sets | `chips`, `cards`, `casino` | CUSTOM **[GUESS]** | No source confirms these exist in the catalog. Fallback: small colored cylinders/discs from Unity primitives (UNITY) as chip stacks. |
| A4 | Dealer standing spot + floor marker | 1 per table | — | UNITY | A decal or flattened cylinder on the floor; catalog includes decals (verified category of content, §2). |

### B. Blackjack area
| # | Item | Qty | Catalog search terms | Source type | Notes |
|---|------|-----|----------------------|-------------|-------|
| B1 | Long / half-moon game table | 2 | `table`, `desk`, `counter` | CAT-FREE / CAT-GOLD? | Same situation as A1 — **[GUESS]** a long table works; a real blackjack crescent table would be CUSTOM. |
| B2 | Stools / chairs with sit anchors | 5 per table (10) | `stool`, `chair` | CAT-FREE | Stools fit blackjack better than armchairs **[GUESS — design call]**. |
| B3 | Card shoe / chip tray props | 2 | `box`, `tray`, `casino` | CUSTOM / UNITY **[GUESS]** | Small boxes from primitives are enough at lounge scale. |

### C. Stage — trivia & radio (LJAAYY Radio)
| # | Item | Qty | Catalog search terms | Source type | Notes |
|---|------|-----|----------------------|-------------|-------|
| C1 | Stage platform | 1 | `platform`, `stage`, `deck` | UNITY / CAT-FREE | Safest build: raised box geometry with a nice material — full control of size. A catalog platform may exist **[GUESS]**. |
| C2 | Speaker stacks (visual) | 2–4 | `speaker`, `audio`, `music` | CAT-GOLD? / CUSTOM **[GUESS]** | No speaker model is confirmed in official sources. The catalog *does* carry audio files (verified), which is different from a speaker prop. Fallback: dark box stacks (UNITY) flanking the stage. |
| C3 | Microphone + stand (host spot) | 1 | `microphone`, `mic` | CUSTOM **[GUESS]** | Not confirmed in catalog. Marks where the trivia host / bot stands. |
| C4 | **PlayMusic component** (the actual radio/trivia audio) | 1 | Built-in components section of the Assets Catalog | **BUILT-IN** | Verified: "PlayMusic is a built-in component for playing background music in your scene… found in the built-in components section of the Assets Catalog." It plays AudioShader assets **or URLs** (`PlayFromURL`). This is how a radio stream URL can play in-world. Source: https://create.highrise.game/learn/studio-api/scripts/PlayMusic |
| C5 | Audio service / AudioShader assets (music beds, stingers for trivia) | as needed | Catalog audio files; Create → Highrise → Audio → Audio Shader | **BUILT-IN** / CAT-FREE | Verified: the Studio API `Audio` service plays music via AudioShaders and via **radio station URL** (`PlayMusicURL`), with volume/intensity controls. Sources: https://create.highrise.game/learn/studio-api/services/Audio · AudioShaders introduced in Studio Package 0.3.0, https://createforum.highrise.game/t/highrise-studio-package-0-3-0/896 |
| C6 | Backdrop / screen behind stage | 1 | `screen`, `sign`, `banner`, decal search | CAT-FREE / UNITY | Catalog carries **decals** (verified) — a logo/name decal on a flat panel is the cheapest "LJAAYY Radio" branding. Custom logo image imported as a texture/decal = CUSTOM, free to make. |
| C7 | Audience seating facing stage | 10–15 seats | `chair`, `bench` | CAT-FREE | **Wooden Bench (Furniture category) is a verified catalog item** — benches are perfect audience rows and are the official anchor example. |

### D. Lounge seating & social areas
| # | Item | Qty | Catalog search terms | Source type | Notes |
|---|------|-----|----------------------|-------------|-------|
| D1 | Sofas / couches | 3–4 | `sofa`, `couch` | CAT-FREE / CAT-GOLD? | **[GUESS]** these exist in Furniture; not individually confirmed. |
| D2 | Armchairs | 4–6 | `armchair`, `chair` | CAT-FREE | |
| D3 | Coffee / side tables | 4–6 | `table`, `coffee table` | CAT-FREE | |
| D4 | Benches (verified item) | 2–4 | `bench` → **Wooden Bench** | CAT-FREE | The one furniture item an official guide names outright. |
| D5 | Bar counter + back shelf | 1 set | `counter`, `bar`, `shelf` | CAT-FREE / UNITY / CUSTOM **[GUESS]** | A counter from primitives + catalog shelves is a reliable fallback. Bottles/glasses props = CUSTOM **[GUESS]**. |
| D6 | Bar stools with anchors | 4–6 | `stool` | CAT-FREE | |
| D7 | Rugs / floor coverings | 3–5 | `rug`, `carpet`, decal search | CAT-FREE | Defines zones (poker pit vs lounge) without walls. Decals are a verified catalog content type. |

### E. Lighting
| # | Item | Qty | Source type | Notes |
|---|------|-----|-------------|-------|
| E1 | Scene lights (ambient + spots over tables/stage) | as needed | **UNITY** | Verified: Getting Started lists adding objects "like cubes, spheres, and **lights**" via the GameObject menu, and editing properties in the Inspector. No purchase involved. Source: https://liveops-create.highrise.game/learn/studio/basics/getting-started |
| E2 | Lamp props (table/floor lamps) | 4–8 | CAT-FREE / CAT-GOLD? — search `lamp`, `light` | **[GUESS]** lamp models exist in Furniture; unconfirmed. Even if the prop is found, actual illumination still comes from E1 lights **[GUESS — standard Unity practice]**. |
| E3 | Neon-style signage glow | 2–3 | CUSTOM / UNITY **[GUESS]** | Emissive materials on a sign panel + a point light. No official "neon sign" catalog item confirmed. |

### F. Decor & structure
| # | Item | Qty | Catalog search terms | Source type | Notes |
|---|------|-----|----------------------|-------------|-------|
| F1 | Floor, walls, room shell | 1 set | Template scene + `floor`, `wall` | UNITY / Template | Comes from the template scene and material edits; Landscapes is a verified catalog category for larger environment pieces. |
| F2 | Plants | 4–6 | `plant`, `tree` | CAT-FREE | `tree` is an official catalog search example; Landscapes category verified. |
| F3 | Wall art / posters | 4–6 | `painting`, `poster`, `frame`, decals | CAT-FREE / CUSTOM | Custom poster images (bot branding, game rules) imported as textures = CUSTOM, no Gold cost to create. |
| F4 | Rope / divider / railing pieces for the game pit | 6–10 | `fence`, `railing`, `rope` | CAT-FREE / UNITY **[GUESS]** | Separates poker/blackjack pit from lounge traffic. |
| F5 | Entrance spawn area dressing (welcome sign, mat) | 1 set | `sign`, decals | CAT-FREE / UNITY | Keep spawn clear; dress the edges only. |

---

## 4. Quantities at a glance (build order)

1. **Shell first (UNITY/Template):** floor, walls, stage platform (C1), lighting rig (E1).
2. **Game pit (CAT-FREE first):** 2 poker tables (A1) + 16 chairs (A2), 2 blackjack tables (B1) + 10 stools (B2), dividers (F4).
3. **Stage (BUILT-IN + CAT-FREE):** PlayMusic component (C4), benches/chairs for audience (C7), backdrop (C6).
4. **Lounge (CAT-FREE):** sofas (D1), armchairs (D2), coffee tables (D3), bar set (D5–D6), rugs (D7).
5. **Dressing:** plants (F2), art (F3), lamps (E2), props (A3, B3) — props last, they're the most likely CUSTOM items.

Total catalog downloads: roughly **50–70 placed objects**, mostly duplicates of ~12–15 unique assets. **[GUESS — count from the tables above.]**

---

## 5. Don't skip: Anchor Points (so avatars can sit)

Placing a chair isn't enough — characters sit via **Anchor Points**, "designated spots on objects… where characters can interact, such as sitting on a bench or standing." The official guide's worked example is the catalog **Wooden Bench** (Furniture). Every chair, stool, sofa, and bench in zones A–D needs an anchor, or players will stand on/around the furniture instead of sitting at the tables.

Source: create.highrise.game, "Anchors." https://create.highrise.game/learn/studio/create/environment/anchor

---

## 6. Built-in / catalog vs custom-uploaded — summary

**Likely covered by built-in + catalog (no custom work):**
- All seating (chairs, stools, benches — bench verified), generic tables, sofas **[GUESS for sofa]**, plants/landscape pieces, rugs/decals, lamps **[GUESS]**
- The entire audio system: PlayMusic component, Audio service, AudioShaders (**BUILT-IN**, verified)
- Lights, stage platform, bar counter shell, dividers (**UNITY** primitives/materials)

**Likely custom-uploaded or imported (if we want them to look right):**
- A real poker table and a real blackjack crescent table (vs. dressed-up generic tables)
- Casino props: chip stacks, playing cards, card shoe
- Speaker stacks and microphone stand as *visual props*
- Branded art: "LJAAYY Radio" logo, house-rules posters

**How custom assets work (verified):** creators can upload their own objects/models/scripts to the Asset Catalog: in Unity, select the files → right-click → **Export Highrise Asset** → name + category → Upload → configure details on the asset package page → publish; status shows in the Creator Dashboard's **Creations** tab. Assets can also simply be imported into the project (Unity Asset Store, `.unitypackage`, local files) without publishing them.
Sources: https://create.highrise.game/learn/studio/distribute/publishing-asset · https://create.highrise.game/learn/studio/create/beginner-guide/lecture-five

---

## 7. Gold / cost notes (only what sources support)

- **Much of the catalog is free:** the official importing guide calls it "an extensive array of **free low-poly assets**." Budget assumption: **0 Gold for the core build** (seating, tables, plants, decor) is plausible but **not guaranteed per item**.
- **Some catalog assets cost Gold:** Lecture 5 states plainly, "Some assets in the Highrise Assets Catalog may require purchase with Gold." **No official source found gives per-item prices** — prices are only visible inside Studio's catalog UI. Do not budget a specific Gold amount until the catalog is open in Studio and each chosen asset's price is read there.
- **Custom assets you upload:** setting a Gold price is **optional** and is about *selling to others* — if priced, Highrise takes **30%** and the creator gets **70%** as Earned Gold. Using your own custom asset in your own world is not described as costing Gold.
  Source: https://create.highrise.game/learn/studio/distribute/publishing-asset
- **Not a cost of this build:** in-app Room furniture prices and Highrise Ideas item prices (e.g., 6,000–8,000 Gold) are different systems (avatar/room items) and don't apply to Studio World assets.
- **Nothing was bought for this research, and nothing should be bought without the user's OK.**

---

## 8. Sources

1. Guide to Using the Highrise Asset Catalog — https://create.highrise.game/learn/studio/create/assets/highrise-catalog
2. Importing Assets (overview) — https://dev-create.highrise.game/learn/studio/create/assets/overview
3. Lecture 5: Importing Assets (Gold warning) — https://create.highrise.game/learn/studio/create/beginner-guide/lecture-five
4. Anchors / Anchor Points (Wooden Bench, Furniture) — https://create.highrise.game/learn/studio/create/environment/anchor
5. Getting Started with Highrise Studio (templates, lights, publishing) — https://liveops-create.highrise.game/learn/studio/basics/getting-started
6. Lecture 3: Creating Your First Project — https://create.highrise.game/learn/studio/create/beginner-guide/lecture-three
7. Publishing Your Asset (custom uploads, 30%/70% Gold split) — https://create.highrise.game/learn/studio/distribute/publishing-asset
8. PlayMusic component — https://create.highrise.game/learn/studio-api/scripts/PlayMusic
9. Audio service (PlayMusicURL / radio) — https://create.highrise.game/learn/studio-api/services/Audio
10. Highrise Worlds (support) — https://support.highrise.game/en/articles/9268957-highrise-worlds
11. How Do I Design My Room and Add More Furniture? (support) — https://support.highrise.game/en/articles/8043385-how-do-i-design-my-room-and-add-more-furniture
12. Studio Package 0.6.8 (catalog opens on new projects) — https://createforum.highrise.game/t/studio-package-0-6-8/1118/1
