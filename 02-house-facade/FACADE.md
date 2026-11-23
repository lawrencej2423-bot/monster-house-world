# FACADE — The Monster House, Rebuilt as a Replica

**Source of truth:** `../00-reference/REFERENCE.md` (the reference crew's breakdown of the
actual 2006 film house). This section was rebuilt against that file's REPLICA CHECKLIST
after the user rejected the first, generic haunted-house version. Everything below is
measured with the reference's own ratios: **W = house body width = 20 units** (body
X 10–30, centre X 20), **H = total height = 21 units** (H ≈ 1.05 × W).

**Default state when the world loads: MONSTER MODE.** The house sits planted at the
north end of the yard (facade zone Z 23–30), mouth open, eyes glowing, door light off.
The at-rest pieces (open door with yellow light, porch railing) are built too, but they
ship hidden on a "rest" layer in case an at-rest toggle is ever wanted.

---

## How it reads from the yard, in plain words

You spawn in the yard at night and look north. The first thing you see is that the
house is *too tall for how wide it is* — a narrow two-storey wooden house with a huge
steep roof taking up the whole top of it, like the roof is pressing the house down.

The siding is blue-grey and old — horizontal planks, warped, with gaps. Between the
two upstairs windows the planks do something strange: they twist and lean toward one
point in the middle of the face, like wrinkles pulled toward the bridge of a nose.
Under the roof edge hangs a ragged fringe of broken shingles, and the roof's edge
itself sags in the middle, so the whole top of the face frowns.

There are exactly **two lit windows** upstairs, both glowing warm orange, and they are
*not twins*. The left one sits flat in the wall — a square window with a cross of bars
in it and a little arched trim on top. The right one is a four-pane window stuck in a
box that juts out of the house toward you. Same height, same glow, different shapes —
that's how the real house looks, and it's what makes the face feel alive instead of
like a cartoon mask. A small dark chimney pokes out of the roof just left of the top,
with a thin wisp of smoke.

Downstairs there is no door to look at, because **the whole porch is the mouth**. The
porch roof has lifted like an upper lip. Hanging from its edge are long, uneven,
splintered boards — grey-blue wood, the house's own timber — some long, some snapped
short. Below them, shorter jagged boards stab up from the porch floor, which has
dropped like a lower jaw. Inside is just black. The mouth is nearly as wide as the
house itself. Nobody's teeth are white, and no two are the same length — that's
deliberate, and it's straight from the film stills.

Two huge dead trees frame the whole thing, one on each side, with more bare trees
packed in behind them, and a low mist sits around the base of the house. The only warm
light anywhere is the two orange eyes. If the house ever "rests," the mouth closes
into a normal shadowy porch and the front door stands open in the middle, spilling
bright yellow light — the brightest thing in the scene — but that's not how the world
loads. It loads awake, and hungry.

---

## Replica checklist coverage

Every item from REFERENCE.md §3, mapped to the manifest entries in
`facade_manifest.json`. Status key: ✅ covered · 🔀 handed off (outside the facade
zone — see note) · ⚠️ partial/flagged.

### Massing
| Checklist item | Manifest entries | Status |
|---|---|---|
| Two storeys + dominant roof; roof ≈ top 40% of H; H ≈ 1.0–1.1 × W | `LowerWall`, `UpperWall`, `RoofFrontSlab`, `RidgeCap`, `GableEnd_West/East` — W = 20, H = 21 (1.05 × W); roof mass Y ≈ 12.3–21.3 | ✅ |
| Subtle overall sag/lean; eaves and porch roof NOT level; centre dips lowest | `UpperWall` (rotZ −1°), `EaveBeam_CentreDip` (0.45 lower than end beams), `PorchRoof_WestHalf/EastHalf` (rise to centre peak), `HouseFoundation` (rotZ +0.4°) | ✅ |
| No side wings, no garage, no extra front windows | By construction: the only window parts in the manifest are the two eyes (machine-checked) | ✅ |

### Roof & chimney
| Checklist item | Manifest entries | Status |
|---|---|---|
| Steep shingled roof, large uneven wooden shakes, dark blue-grey (#2E3B44) | `RoofFrontSlab`, `ShingleScatter_1–4` (curled/lifted shakes) | ✅ |
| Missing/curled/lifted shingles; jagged holes in monster mode | `ShingleScatter_1–4`, `RoofHole_1`, `RoofHole_2` (monster layer) | ✅ |
| Small dark brick chimney just LEFT of centre at the ridge + thin smoke wisp | `Chimney_Small` (X 18.6, left of centre), `SmokeWisp` | ✅ |
| Eave line sags toward centre (the brow dip) | `EaveBeam_West`, `EaveBeam_CentreDip`, `EaveBeam_East` | ✅ |

### Brow & siding
| Checklist item | Manifest entries | Status |
|---|---|---|
| Ragged shingle-skirt band under the eaves, splintered/broken at its centre | `ShingleSkirtBand` + `SkirtShard_1–6` — deliberately NO shards between X 18.6 and 21.4 (the broken centre, machine-checked) | ✅ |
| Horizontal plank siding, blue-grey (#54646E), warped with gaps | `LowerWall`, `UpperWall` (plank material spec: warped, gaps, no two boards aligned) | ✅ |
| Planks twist/converge toward the centre "nose" point between/below the eyes, above the porch-roof peak; wrinkles radiate from it | `NosePoint_Hub` (at 20, 6.2), `SidingWrinkle_L1/L2/R1/R2/Centre` angled toward it; porch peak `PorchRoofPeak` directly below it | ✅ |

### Eyes
| Checklist item | Manifest entries | Status |
|---|---|---|
| EXACTLY two lit upper windows; centres ≈ 0.35 W and ≈ 0.65 W (spacing 0.30–0.35 W) | `EyeWindow_Left_Flat` (X 17 = 0.35 W), `EyeWindow_Right_4Pane` (X 23 = 0.65 W); spacing 0.30 W (machine-checked) | ✅ |
| Each ≈ 0.09–0.11 W wide, slightly taller than wide | Both eyes 2.0 wide (0.10 W) × 2.4 tall (machine-checked) | ✅ |
| LEFT eye flat in the wall, cross muntins, shallow arch trim on top | `EyeWindow_Left_Flat` + subparts `Muntin_Left_V/H`, `ArchTrim_Left` (REFERENCE ruling 2) | ✅ |
| RIGHT eye = 2×2 four-pane window in a PROJECTING DORMER BOX out of the roof slope | `EyeWindow_Right_4Pane` + subparts `Muntin_Right_V/H`, carried by `EyeDormerBox_Right` (front face Z 25.3 vs wall Z 27 — projects forward), `DormerRoof_Right` | ✅ |
| Both glow orange-amber (#FF9A2A–#FFB84D) with a soft halo on the siding | Both panes #FFA63D emissive; `EyeHalo_Left`, `EyeHalo_Right` point lights, matched intensity | ✅ |
| Eyes on the same level (ruling 5 — dormer projects forward, not up) | Both eye centres at Y 7.6 (machine-checked) | ✅ |

### Porch & door (resting layer)
| Checklist item | Manifest entries | Status |
|---|---|---|
| Full-width porch (≈ 1.0–1.05 W), depth ≈ 0.10–0.12 W, low-pitched shingle roof with a slight centre peak | `PorchFloor` (21 wide = 1.05 W, depth 2.1 = 0.105 W), `PorchRoof_WestHalf/EastHalf`, `PorchRoofPeak` | ✅ |
| Thin posts/screen frames every ≈ 0.10–0.12 W; low simple railing; dark interior | `PorchPostSet` (10 posts, spacing 0.105 W), `PorchRail_Low` (rest layer), `PorchInteriorShadow` | ✅ |
| Door centred ≈ 0.47–0.50 W, open, pouring yellow-white light (#FFD76A) onto the porch floor — brightest element in the scene | `FrontDoor_Open` (centre 0.4925 W, swung open), `DoorGlow_Plane`, `DoorLightSpill`, `DoorLight_Pool` — all **rest layer, hidden by default** (in monster mode the door and its light are inside the mouth, per REFERENCE) | ✅ |

### Monster mouth (the default backdrop state)
| Checklist item | Manifest entries | Status |
|---|---|---|
| Mouth = the porch opening itself, spanning ≈ 0.85 W, full porch height | `MouthInterior_Black` (17 wide = 0.85 W, Y 0.6–4.1 = full porch height) | ✅ |
| Porch roof tilted up as upper lip; porch floor dropped as lower jaw | `PorchRoof_WestHalf/EastHalf` (monster note: group tilts up ≈ 12°), `PorchFloor_LowerJaw` (dropped front strip) | ✅ |
| Upper teeth: irregular splintered boards from the porch-roof edge, longest ≈ 35–40% of mouth height, uneven, grey-blue, NO white/even teeth | `UpperTooth_1–9` — lengths 1.35 / 0.75 / 1.2 / 0.5 / **1.4 (= 40%)** / 0.85 / 1.15 / 0.6 / 1.0, all grey-blue siding-family colours (machine-checked: no white, lengths uneven) | ✅ |
| Lower teeth: jagged boards up from the porch floor, ≈ 25–30% of mouth height | `LowerTooth_1–7` — heights 0.55–1.05, max = 30% of mouth height (machine-checked) | ✅ |
| Interior near-black; door light OFF in this mode | `MouthInterior_Black` (#05070A, hint of dark red-brown depth); door parts are rest-layer and hidden by default | ✅ |
| House stays planted — no limb arms, no legs | By construction: no arm/leg parts exist. (The framing trees are yard trees, not house limbs.) | ✅ |

### Yard
| Checklist item | Manifest entries | Status |
|---|---|---|
| Two massive bare gnarled trees framing at ≈ ±0.6–0.7 W; dense bare trees behind/between on both sides | `GnarledTree_Left_Trunk` + `GnarledBranch_L1/L2`, `GnarledTree_Right_Trunk` + `GnarledBranch_R1/R2` (trunks at ±0.66 W, 0.08 W thick), `GroveSilhouette_West/East` — placed at the facade line (Z 24–28) as the backdrop row of the grove | ✅ |
| Straight centre walkway ≈ 0.07–0.09 W wide, curb to porch steps, on the 0.5 W line | `PorchSteps` (facade end of the path, on the centre line) | 🔀 Walkway itself is in the playable yard (Z < 23) — owned by the yard/layout section. Facade covers its top end (the steps). |
| KEEP AWAY sign left foreground (≈ 0.25 W), BEWARE sign right of walkway (≈ 0.60 W), crooked boards ≈ 0.04 H | — | 🔀 Both signs stand on the front lawn (Z < 23), outside the facade zone — handed to the yard/layout section with the reference's positions and wording. Not a facade build item. |
| Lawn dark desaturated green-brown, mostly shadowed; low mist at the house base | `MistBand_Base` (low mist at the base, facade side) | 🔀 Lawn surface itself is yard/layout section. Mist at the house base is covered here. |

### Palette / lighting
| Checklist item | Manifest entries | Status |
|---|---|---|
| Night blue-teal ambient; pale moon rim light from behind the roof | `MoonRimLight` (#BFD9E8, behind/above the roof); ambient values recorded in the manifest's `palette` block for the lighting/pipeline section to set | ✅ |
| ONLY warm lights: the two orange eyes (+ door light at rest) | `EyeHalo_Left/Right` are the only warm lights in the default state; `DoorLight_Pool` is rest-layer only. No other light parts exist in the manifest | ✅ |
| Nothing in the facade uses the casino palette (no neon, no gold trim) | By construction — manifest palette block explicitly forbids it; all colours are from the REFERENCE night palette | ✅ |

---

## What changed from the rejected generic version (so nobody rebuilds it)

- **Gone:** the symmetrical twin eyes with slanted "angry" tilts, the timber brow
  beams, the round attic "third eye," the nose bay window, the ground-floor windows,
  the white fang columns/cone teeth, the warm brown siding palette, the big leaning
  chimney on the east side.
- **In:** asymmetric eyes (flat cross-muntin left / dormer four-pane right), the
  sagging eave + broken shingle skirt as the brow, siding wrinkles converging on a
  nose point, the porch itself as the mouth with grey-blue splintered-board teeth,
  the film's blue-grey night palette, the small left-of-ridge smoking chimney, and
  the gnarled framing trees.
- **Zone discipline improved too:** the generic version needed a flagged exception
  (porch steps at Z 22.4). This replica needs **none** — every part, rotation
  included, stays inside Z 23–30 (machine-checked).

## Known simplifications (flagged, not hidden)

- **Roof construction:** the roof is built as a steep front-facing slab (backdrop
  style) rather than a full 3D hipped roof with a back slope — from the yard only the
  front elevation is ever seen, and the film roof reads near-vertical from the front.
  If a future angle (e.g. a flyover) exposes the back, the roof needs a back slope.
- **Teeth and shards** are straight-edged boxes in the manifest; their jagged,
  splintered read comes from the material/trim applied at build time, as noted on
  each part.
- **Smoke** is specified as a translucent column with a particle emitter preferred —
  whichever the Studio build supports.
