#!/usr/bin/env python3
"""convert_placements.py -- JSON manifests -> Lua `Placements` module.

Highrise Lua cannot read files off disk, so the repo's JSON manifests are
converted into one Module script named `Placements` that
05-builder/builder.lua loads with require("Placements"). The module shape
and the per-entry schema are the ones BUILDER.md specifies:

    --!Type(Module)
    return {
        placements = {
            { name = "...", asset = "...", x = .., y = .., z = ..,
              rotation = .. | { x=.., y=.., z=.. }, zone = "...",
              part = "...", scale = { x=.., y=.., z=.. }, notes = "..." },
            ...
        },
    }

The real section manifests do NOT use that shape natively -- each crew
wrote its own. This converter normalizes all of them:

  source                                   list key   part name
  ---------------------------------------  ---------  ---------
  01-layout/layout_manifest.json           objects    layout
  02-house-facade/facade_manifest.json     parts      facade
  10-interior/interior_manifest.json       objects    interior

Normalization rules (kept deliberately conservative -- the builder ignores
fields it does not know, so human-useful extras are passed through, never
invented):

  layout / interior entries:
    name                 -> name            (required)
    position {x,y,z}     -> x, y, z         (x and z required, y defaults 0)
    rotation_y_deg       -> rotation        (yaw degrees; omitted when 0)
    zone                 -> zone
    type, level          -> passed through as extras (builder ignores)
    notes                -> notes
    (no `asset`: the builder defaults the template key to the entry name,
     which is the layout/interior crews' convention)

  facade entries:
    name                 -> name            (required)
    position {x,y,z}     -> x, y, z
    rotationDeg {x,y,z}  -> rotation table  (omitted when all zero)
    size {x,y,z}         -> scale           (facade parts are built from
                                             unit primitives, so the part's
                                             size IS its scale on a unit
                                             template -- see FINISHER_RUNBOOK)
    buildFrom            -> asset, via PRIMITIVE_ASSETS below (the facade
                            is primitives: boxes, cylinders, lights...)
    category             -> zone is "Facade"; category passed as extra
    material, color,
    layer, buildFrom     -> passed through as extras (builder ignores;
                            `layer` rest/monster/both is a Studio-side
                            visibility state, NOT the builder's `active`)

NOT converted (deliberately):
  06-assets/assets_manifest.json      -- a catalog of things to stock, not
                                         placements.
  11-atmosphere/atmosphere_manifest   -- scene settings (sky, lights,
                                         lightning), applied in Studio per
                                         11-atmosphere/ATMOSPHERE.md, not
                                         cloned templates.

Duplicate names across the combined list: the builder places the first and
skips the rest, so the converter does the same and warns on stderr.
Entries missing a name or a numeric x/z are invalid (the builder would log
them INVALID); the converter drops them and warns on stderr.

Usage:
    python3 convert_placements.py [REPO_ROOT] [-o OUT.lua]

REPO_ROOT defaults to ../repo relative to this script (the finisher-prep
folder sits next to repo/ in world-building/). With no -o, the module is
written to stdout. A summary is always printed to stderr.

Stdlib only. Python 3.8+.
"""

import argparse
import json
import sys
from pathlib import Path

# buildFrom (facade crew's words) -> template asset key the finisher stocks
# under BuilderTemplates. One unit primitive per key; the part's `size`
# becomes its scale. Anything unrecognized falls back to UnityBox and is
# counted in the summary so a human can review the fallback list.
PRIMITIVE_ASSETS = [
    ("point light", "UnityPointLight"),
    ("light", "UnityPointLight"),
    ("cone", "UnityCone"),
    ("triangular prism", "UnityPrism"),
    ("cylinder", "UnityCylinder"),
    ("thin box", "UnityThinBox"),
    ("box", "UnityBox"),
]
FALLBACK_ASSET = "UnityBox"


def primitive_asset(build_from):
    """Return (asset_key, matched). matched=False means no known primitive
    was named and the generic box fallback was used -- those are the
    entries a human should eyeball. A plain 'Unity box' buildFrom matches
    the 'box' needle and is a legitimate UnityBox, NOT a fallback."""
    text = (build_from or "").lower()
    for needle, asset in PRIMITIVE_ASSETS:
        if needle in text:
            return asset, True
    return FALLBACK_ASSET, False


def lua_str(value):
    out = []
    for ch in str(value):
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif ord(ch) < 0x20:
            out.append("\\%d" % ord(ch))
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


def lua_num(value):
    f = float(value)
    if f == int(f) and abs(f) < 1e15:
        return str(int(f))
    return repr(f)


def is_num(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def position_of(entry):
    """Return (x, y, z) from a nested position{} or flat fields, else None."""
    pos = entry.get("position")
    if isinstance(pos, dict):
        x, y, z = pos.get("x"), pos.get("y", 0), pos.get("z")
    else:
        x, y, z = entry.get("x"), entry.get("y", 0), entry.get("z")
    if not (is_num(x) and is_num(z)):
        return None
    if not is_num(y):
        y = 0
    return float(x), float(y), float(z)


def normalize_flat(entry, part):
    """layout / interior shape -> builder entry (or None if invalid)."""
    name = entry.get("name")
    pos = position_of(entry)
    if not name or pos is None:
        return None
    out = {"name": name, "x": pos[0], "y": pos[1], "z": pos[2]}
    rot = entry.get("rotation_y_deg", entry.get("rotationY", entry.get("yaw")))
    if is_num(rot) and float(rot) != 0:
        out["rotation"] = float(rot)
    if entry.get("zone"):
        out["zone"] = entry["zone"]
    out["part"] = part
    for extra in ("type", "level"):
        if entry.get(extra) is not None:
            out[extra] = entry[extra]
    if entry.get("notes"):
        out["notes"] = entry["notes"]
    return out


def normalize_facade(entry):
    """facade shape -> builder entry (or None if invalid)."""
    name = entry.get("name")
    pos = position_of(entry)
    if not name or pos is None:
        return None
    asset, matched = primitive_asset(entry.get("buildFrom"))
    out = {"name": name, "asset": asset,
           "x": pos[0], "y": pos[1], "z": pos[2]}
    out["_asset_matched"] = matched
    rot = entry.get("rotationDeg")
    if isinstance(rot, dict):
        rx, ry, rz = rot.get("x", 0), rot.get("y", 0), rot.get("z", 0)
        if any(is_num(v) and float(v) != 0 for v in (rx, ry, rz)):
            out["rotation"] = {"x": float(rx or 0), "y": float(ry or 0),
                               "z": float(rz or 0)}
    elif is_num(rot) and float(rot) != 0:
        out["rotation"] = float(rot)
    size = entry.get("size")
    if isinstance(size, dict) and all(is_num(size.get(a)) for a in ("x", "y", "z")):
        out["scale"] = {a: float(size[a]) for a in ("x", "y", "z")}
    out["zone"] = "Facade"
    out["part"] = "facade"
    for extra in ("category", "material", "color", "layer", "buildFrom"):
        if entry.get(extra) is not None:
            out[extra] = entry[extra]
    if entry.get("notes"):
        out["notes"] = entry["notes"]
    return out


SOURCES = [
    ("01-layout/layout_manifest.json", "objects", "layout", normalize_flat),
    ("02-house-facade/facade_manifest.json", "parts", "facade", None),  # below
    ("10-interior/interior_manifest.json", "objects", "interior", normalize_flat),
]


def load_placements(repo_root, interior_wins=False):
    """Return (entries, stats) reading every source manifest under repo_root.

    Duplicate names: first source wins (the builder's own rule). Default
    order is layout -> facade -> interior, matching BUILDER.md's original
    combined list (layout + facade) with the interior appended. The
    interior manifest re-declares the game stations at interior
    coordinates (games moved inside the house), so until the planned
    integration pass removes the yard copies from the layout manifest,
    --interior-wins is the finisher's switch for letting the interior
    copies win instead. See FINISHER_RUNBOOK.md, "Known integration item".
    """
    entries = []
    seen = {}
    stats = {"per_part": {}, "duplicates": [], "invalid": [], "fallbacks": []}
    sources = list(SOURCES)
    if interior_wins:
        sources.sort(key=lambda s: 0 if s[2] == "interior" else 1)
    for rel, list_key, part, normalizer in sources:
        path = repo_root / rel
        data = json.loads(path.read_text(encoding="utf-8"))
        raw_list = data.get(list_key)
        if not isinstance(raw_list, list):
            raise ValueError("%s: expected a '%s' array" % (rel, list_key))
        count = 0
        for raw in raw_list:
            if part == "facade":
                entry = normalize_facade(raw)
            else:
                entry = normalizer(raw, part)
            if entry is None:
                stats["invalid"].append("%s: %s" % (rel, raw.get("name", "<unnamed>")))
                continue
            if entry["name"] in seen:
                stats["duplicates"].append(
                    "%s (first seen in %s)" % (entry["name"], seen[entry["name"]]))
                continue
            seen[entry["name"]] = rel
            if part == "facade" and not entry.pop("_asset_matched", True):
                stats["fallbacks"].append(entry["name"])
            else:
                entry.pop("_asset_matched", None)
            entries.append(entry)
            count += 1
        stats["per_part"][part] = count
    return entries, stats


FIELD_ORDER = ["name", "asset", "x", "y", "z", "rotation", "zone", "part",
               "scale", "active", "type", "level", "category", "material",
               "color", "layer", "buildFrom", "notes"]


def entry_to_lua(entry):
    fields = []
    for key in FIELD_ORDER:
        if key not in entry:
            continue
        value = entry[key]
        if isinstance(value, dict):  # rotation table or scale table
            inner = ", ".join("%s = %s" % (k, lua_num(value[k]))
                              for k in ("x", "y", "z") if k in value)
            fields.append("%s = { %s }" % (key, inner))
        elif isinstance(value, bool):
            fields.append("%s = %s" % (key, "true" if value else "false"))
        elif is_num(value):
            fields.append("%s = %s" % (key, lua_num(value)))
        else:
            fields.append("%s = %s" % (key, lua_str(value)))
    return "        { " + ", ".join(fields) + " }"


def to_lua_module(entries):
    lines = [
        "--!Type(Module)",
        "-- Placements.lua -- GENERATED by finisher-prep/convert_placements.py",
        "-- from the repo JSON manifests (01-layout, 02-house-facade,",
        "-- 10-interior). Do not hand-edit; fix the manifest and re-run the",
        "-- converter. Consumed by 05-builder/builder.lua via",
        "-- require(\"Placements\").",
        "return {",
        "    placements = {",
    ]
    for entry in entries:
        lines.append(entry_to_lua(entry) + ",")
    lines.append("    },")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("repo_root", nargs="?", default=None,
                        help="repo checkout root (default: ../repo next to this script)")
    parser.add_argument("-o", "--out", default=None,
                        help="write the Lua module here (default: stdout)")
    parser.add_argument("--interior-wins", action="store_true",
                        help="on duplicate names, the interior manifest's "
                             "copy wins over the layout manifest's (use "
                             "once the games-inside integration is decided; "
                             "see FINISHER_RUNBOOK.md)")
    args = parser.parse_args(argv)

    if args.repo_root:
        repo_root = Path(args.repo_root)
    else:
        repo_root = Path(__file__).resolve().parent.parent / "repo"

    entries, stats = load_placements(repo_root, interior_wins=args.interior_wins)
    module = to_lua_module(entries)

    if args.out:
        Path(args.out).write_text(module, encoding="utf-8")
    else:
        sys.stdout.write(module)

    print("convert_placements: %d placements total" % len(entries),
          file=sys.stderr)
    for part, count in stats["per_part"].items():
        print("  %-9s %d" % (part, count), file=sys.stderr)
    for dup in stats["duplicates"]:
        print("  DUPLICATE skipped (first wins): %s" % dup, file=sys.stderr)
    for inv in stats["invalid"]:
        print("  INVALID dropped: %s" % inv, file=sys.stderr)
    if stats["fallbacks"]:
        print("  facade entries on the %s fallback asset: %s"
              % (FALLBACK_ASSET, ", ".join(stats["fallbacks"])),
              file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
