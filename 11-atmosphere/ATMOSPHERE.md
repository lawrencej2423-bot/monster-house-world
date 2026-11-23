# ATMOSPHERE — storm sky, moonlight & lightning

**Section 11 of the Monster House world repo.** Everything about the sky and the
outdoor light lives here. User's spec (2026-11-22): the sky is a **storm**, with
**lightning**; the light on the players is **moonlight**; and the only warm glow
in the scene comes from **the house in the background**.

Files: `atmosphere_manifest.json` (the placements/settings the builder and
Studio setup work from) and `Lightning.lua` (the flash script).

---

## The three light sources — and only three

| Light | Colour | Job |
|---|---|---|
| **Moonlight** | Cold blue-silver `#B9CFEA` | THE light on the players, the yard, the walkway and the tables. One directional light, coming from behind/above the house (north-high) shining south over the yard — the same direction as the moon rim light on the house in the film poster, so the house's rim and the players' light read as one moon. |
| **House glow** | Warm orange `#FFA63D` eyes, yellow-white `#FFD76A` door | Background only. Owned by the facade section (02): the two glowing eye windows + halos, and the door light (rest layer only — OFF when the house is in its default monster-mouth state). **This section adds no warm light, ever.** |
| **Lightning** | Cold white-blue `#EAF2FF` | Brief scripted flashes that light the sky behind the house and lift the whole yard for a fraction of a second, then darkness again. |

Underneath those sits a whisper of cold ambient (`#0B1D2A–#14313F`, the film's
night range) so unlit corners read as deep blue instead of black holes. That's
a floor, not a fourth light.

## The storm sky

- **Dome/backdrop:** near-black blue at the top (`#060D16`) grading to deep
  blue-teal at the horizon (`#14313F`), with the storm clouds baked in.
- **Two cloud layers** of dark blue-grey cloud masses (`#101E29` / `#1C2F3D`)
  drifting slowly at different speeds — the drift between layers is what makes
  it feel like a storm hanging overhead instead of a painted ceiling. Their
  north edges catch pale moonlight (`#5E707A`).
- **One moon:** a pale full-moon disc (`#DCE9F5`) sitting north, high, **behind
  the roofline** — exactly the poster composition — partly veiled by the high
  cloud layer. It's a picture of the moon, not a lamp; the actual light is the
  directional Moonlight_Main.
- **Low fog:** thin pale blue-grey mist hugging the ground at the base of the
  house and drifting over the walkway (the film stills show mist at the base).
  Kept thin so the walkway, the KEEP AWAY / BEWARE signs and the tables stay
  readable.

## Lightning — how the flash works

`Lightning.lua` attaches to an empty object named `LightningController`.

- The **server** is the clock: it waits a random **7–18 seconds**, then fires
  one event to every client carrying the strike's strength. All players see
  the same flash at the same time; clients never pick their own timing.
- The **flash pattern is a double flash**, like real lightning: a quick first
  strike, a short dark gap, then a second strike about half again as bright
  that fades out over roughly half a second. All-in, the sky is lit well under
  5% of the time.
- Each flash pulses two things together: `LightningSkyFlash` (a big soft panel
  behind the house, invisible at rest, so the clouds light up from behind and
  the roof/trees silhouette) and `LightningFlashLight` (a cold light, off at
  rest, that briefly lifts the yard).
- **Yard side only.** The flashes do not light the house interior — that's a
  separate enclosed space with its own section.
- Honest note: the script uses only doc-verified calls for its structure
  (events, `GameObject.Find`, lifecycle). The exact timer call and the
  light/material property writes are **not** confirmed by our docs, so each is
  wrapped so that if it fails in Studio, it logs once and the world simply
  runs without lightning — nothing else breaks. These are first-Play-test
  checks, listed at the bottom of the script.

## How this is built in Studio

1. **Sky:** use the scene's skybox slot *or* one big inverted dome mesh —
   never both. Paint/assign the storm gradient above; if a custom skybox
   texture isn't ready, a dark blue-teal skybox tinted to `#0B1D2A` is an
   acceptable stand-in until the storm texture lands.
2. **Moon + clouds:** place `MoonDisc`, `StormCloudLayer_Low`,
   `StormCloudLayer_High` from the manifest. Slow drift can be a simple
   rotation/offset animation on the cloud layers; static is acceptable for v1
   if animation fights the build — the two-tone layering matters more than
   the motion.
3. **Lighting settings:** set the scene's directional light to Moonlight_Main
   (colour `#B9CFEA`, from behind/above the house toward spawn), ambient to
   AmbientNight_Fill (cold, very low). Shadows on if the scene budget allows.
4. **Lightning objects:** place `LightningSkyFlash` (starts invisible),
   `LightningFlashLight` (starts at 0), and the empty `LightningController`
   with `Lightning.lua` attached. Names must stay exact — the script finds
   them by name.

## What this supersedes

DESIGN.md §1's lighting plan said: *"Warm ambient overall; each zone gets its
own accent color."* **For the yard, that line is dead** (user spec,
2026-11-22). Outdoor ambient is cold storm-night blue; zones outdoors are
separated by moonlight and the house's warm glow, not by warm accent lights.
Casino colours survive only as materials and signage on the game dressing —
never as warm light cast on the yard. (Interior lighting belongs to the
interior section; the games-inside-the-house change doesn't alter anything
here — the yard still sits under the storm.)
