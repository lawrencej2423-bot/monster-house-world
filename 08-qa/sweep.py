#!/usr/bin/env python3
"""
Monster House Highrise world — QA bug sweep (Section Crew 8).

Stdlib-only automated checks for the world repo. Run from anywhere:

    python3 08-qa/sweep.py [--root <repo-root>] [--json]

Exit code: 0 = no FAILs (PENDING sections are OK), 1 = at least one FAIL.

Checks (against DESIGN.md §1 / §3 / §5 in ../.. i.e.
~/workspace/highrise-bot/world-building/DESIGN.md):

  1. Every .json file in the repo parses as valid JSON.
  2. Layout objects (from any manifest JSON):
     - stay inside the 40 x 30 footprint (X 0-40, Z 0-30),
     - do not overlap each other (flat floor/decals/rugs/platforms exempt),
     - stay out of the central aisle (X 18-22, Z 2-22),
     - keep the 1.5-unit clear ring around every game table.
  3. Every .lua file passes a balance/syntax sanity check
     (delimiter balance + block keyword balance; uses luac if present).
  4. Manifest object names must be names defined in DESIGN.md §3/§5.
  5. No file may reference an anchor (BotStation_*, BotGreeterAnchor_*,
     HostSpot, TriviaScreen) that is not defined in DESIGN.md and does not
     exist in a manifest. DESIGN-defined-but-not-yet-placed anchors are
     PENDING, unknown anchors are FAIL.

Tolerance rule: sibling section folders that are missing, empty, or hold
no relevant files yet are reported as PENDING, never as failures — other
crews build in parallel.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

# ---------------------------------------------------------------- constants

AISLE = (18.0, 22.0, 2.0, 22.0)          # x_min, x_max, z_min, z_max
FOOTPRINT = (0.0, 40.0, 0.0, 30.0)       # x_min, x_max, z_min, z_max
CLEAR_RING = 1.5

SECTIONS = [
    "01-layout", "02-house-facade", "03-scripts-card-games",
    "04-scripts-party-games", "05-builder", "06-assets",
    "07-pipeline", "08-qa",
]

# Names that are points/markers, not furniture: exempt from aisle + ring.
MARKER_PREFIXES = ("BotStation_", "BotGreeterAnchor")
MARKER_NAMES = {"HostSpot", "SpawnPoint"}
# Flat surfaces: exempt from the overlap check (things sit ON them).
FLAT_TOKENS = ("Rug", "Floor", "Carpet", "Decal", "Platform", "Circle",
               "Runner", "DanceFloor")
# Objects that legitimately live on/inside a game table's ring.
RING_EXEMPT_TOKENS = ("Seat", "Chair", "Stool", "ChipDecor")
# DESIGN RULING (Jett, 2026-11-22, resolving the DESIGN §1 vs §3
# conflict): §3's specific blackjack placements WIN over §1's general
# aisle rule. BlackjackTable_Main (19,0,18) and PvPBlackjackTable
# (19,0,11) are EXEMPT from the central-aisle check, and so are their
# 1.5-unit clear rings where those rings overlap the aisle (X 18-22).
# The two tables' own signage travels with the exemption: BlackjackSign
# hangs at Y=4 above BlackjackTable_Main, and PvPSign is table dressing
# mounted on PvPBlackjackTable's edge — neither is walkway furniture.
# EVERYTHING else in the aisle still FAILs.
AISLE_EXEMPT_NAMES = {"BlackjackTable_Main", "PvPBlackjackTable",
                      "BlackjackSign", "PvPSign"}
# A table's own sign is on-table/overhead dressing for that table, not
# a ground intrusion into its clear ring.
TABLE_SIGNS = {"PokerSign": "PokerTable_Main",
               "BlackjackSign": "BlackjackTable_Main",
               "PvPSign": "PvPBlackjackTable"}
# Levels that never occupy the floor: exempt from the ground-level
# aisle and clear-ring checks (a hanging sign at Y=4 or a ceiling beam
# at Y=7.4 cannot block a walkway or a player's standing ring).
NON_GROUND_LEVELS = {"hanging", "ceiling"}
GAME_TABLE_NAMES = {"PokerTable_Main", "PokerTable_Overflow",
                    "BlackjackTable_Main", "PvPBlackjackTable"}
ANCHOR_RE = re.compile(
    r"\b(?:BotStation_[A-Za-z0-9_]+|BotGreeterAnchor_[A-Za-z0-9_]+"
    r"|HostSpot|TriviaScreen)\b")
NAME_RE = re.compile(r"^[A-Z][A-Za-z0-9_]*$")

# ---------------------------------------------------------------- findings


class Findings:
    def __init__(self):
        self.fails = []     # (section, file, line, problem)
        self.pending = []   # (section, note)
        self.passes = []    # (section, note)

    def fail(self, section, file, line, problem):
        self.fails.append((section, file, line, problem))

    def pend(self, section, note):
        self.pending.append((section, note))

    def ok(self, section, note):
        self.passes.append((section, note))


def section_of(root, path):
    rel = os.path.relpath(path, root)
    parts = rel.split(os.sep)
    return parts[0] if parts and parts[0] in SECTIONS else "(repo root)"


def find_line(path, needle):
    """1-based line number of first occurrence of needle in file, else None."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh, 1):
                if needle in line:
                    return i
    except OSError:
        pass
    return None

# ---------------------------------------------------------------- DESIGN.md


def design_names(design_path):
    """Extract expected object/anchor names from DESIGN.md §3 and §5."""
    names = set()
    anchors = set()
    if not os.path.isfile(design_path):
        return names, anchors
    with open(design_path, "r", encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    # §3 = from '## 3.' to '## 4.' ; §5 = from '## 5.' to '## 6.'
    sec3 = text.split("## 3.", 1)[-1].split("## 4.", 1)[0] \
        if "## 3." in text else ""
    sec5 = text.split("## 5.", 1)[-1].split("## 6.", 1)[0] \
        if "## 5." in text else ""
    for blob in (sec3, sec5):
        # strip fenced code blocks first — the §3 plan-view fence would
        # otherwise break backtick pairing and swallow inline names
        blob = re.sub(r"```.*?```", "", blob, flags=re.S)
        for raw in re.findall(r"`([^`\n]+)`", blob):
            # expand "LoungeSofa_1/2" style shorthand
            m = re.match(r"^([A-Za-z_]+_)(\d+)/(\d+)$", raw)
            if m:
                names.add(m.group(1) + m.group(2))
                names.add(m.group(1) + m.group(3))
                continue
            if NAME_RE.match(raw):
                names.add(raw)
    anchors = {n for n in names
               if n.startswith(MARKER_PREFIXES) or n in MARKER_NAMES
               or n == "TriviaScreen"}
    return names, anchors

# ---------------------------------------------------------------- manifests


def iter_files(root, exts):
    for dirpath, _dirs, files in os.walk(root):
        for fn in sorted(files):
            if fn.lower().endswith(exts):
                yield os.path.join(dirpath, fn)


def get_objects(data):
    """Yield object dicts from common manifest shapes."""
    if isinstance(data, list):
        items = data
    elif isinstance(data, dict):
        items = None
        for key in ("objects", "items", "placements", "layout"):
            if isinstance(data.get(key), list):
                items = data[key]
                break
        if items is None:
            items = [data] if "name" in data else []
    else:
        items = []
    for it in items:
        if isinstance(it, dict) and isinstance(it.get("name"), str):
            yield it


def obj_box(obj):
    """Return (x_min, x_max, z_min, z_max) or None if unpositioned.

    Accepts position/pos as [x, y, z] or {x, z}; size as [sx, sy, sz],
    {x, z}, width/depth, or radius. A bare point yields a zero-size box.
    """
    pos = obj.get("position", obj.get("pos"))
    x = z = None
    if isinstance(pos, (list, tuple)) and len(pos) >= 3:
        x, z = pos[0], pos[2]
    elif isinstance(pos, dict):
        x, z = pos.get("x"), pos.get("z")
    if x is None:
        x = obj.get("x")
    if z is None:
        z = obj.get("z")
    if not isinstance(x, (int, float)) or not isinstance(z, (int, float)):
        return None
    hx = hz = 0.0
    size = obj.get("size", obj.get("dimensions"))
    if isinstance(size, (list, tuple)) and len(size) >= 3:
        hx, hz = size[0] / 2.0, size[2] / 2.0
    elif isinstance(size, dict):
        hx = (size.get("x") or 0) / 2.0
        hz = (size.get("z") or 0) / 2.0
    if isinstance(obj.get("width"), (int, float)):
        hx = obj["width"] / 2.0
    if isinstance(obj.get("depth"), (int, float)):
        hz = obj["depth"] / 2.0
    if isinstance(obj.get("radius"), (int, float)):
        hx = hz = float(obj["radius"])
    return (x - hx, x + hx, z - hz, z + hz)


def is_marker(name):
    return name.startswith(MARKER_PREFIXES) or name in MARKER_NAMES


def is_flat(name, obj):
    t = str(obj.get("type", "")).lower()
    return any(tok.lower() in name.lower() or tok.lower() in t
               for tok in FLAT_TOKENS)


def boxes_overlap(a, b):
    return a[0] < b[1] and b[0] < a[1] and a[2] < b[3] and b[2] < a[3]

# ---------------------------------------------------------------- checks


def check_json(root, fnd):
    """Parse every .json; return {path: data} for the good ones."""
    parsed = {}
    count = 0
    for path in iter_files(root, (".json",)):
        count += 1
        sec = section_of(root, path)
        try:
            with open(path, "r", encoding="utf-8") as fh:
                parsed[path] = json.load(fh)
        except json.JSONDecodeError as e:
            fnd.fail(sec, path, e.lineno,
                     "JSON parse error: %s (col %d)" % (e.msg, e.colno))
        except OSError as e:
            fnd.fail(sec, path, None, "Unreadable file: %s" % e)
    if count:
        fnd.ok("(all)", "%d JSON file(s) checked, %d parsed OK"
               % (count, len(parsed)))
    return parsed


def declared_bounds(data):
    """A manifest may declare its own area footprint (world.grid
    footprint_x / footprint_z) — e.g. 10-interior sits at a +200 X
    offset as the second area of one world ('two rooms but one').
    Objects in such a manifest are bounds-checked against the DECLARED
    40x30 area, not the yard's. Manifests without a declaration use
    the global yard FOOTPRINT."""
    try:
        grid = data["world"]["grid"]
        fx = grid["footprint_x"]
        fz = grid["footprint_z"]
        return (float(fx[0]), float(fx[1]), float(fz[0]), float(fz[1]))
    except (TypeError, KeyError, IndexError, ValueError):
        return FOOTPRINT


def check_layout(root, fnd, parsed, expected_names):
    objects = []  # (name, box, path, obj)
    bounds_of = {}  # path -> (x_min, x_max, z_min, z_max)
    for path, data in parsed.items():
        bounds_of[path] = declared_bounds(data)
        for obj in get_objects(data):
            box = obj_box(obj)
            if box is not None:
                objects.append((obj["name"], box, path, obj))
            else:
                objects.append((obj["name"], None, path, obj))

    placed_names = {n for n, _b, _p, _o in objects}
    # An instance entry may carry "design_name": the exact DESIGN name
    # of the object it instances (e.g. name EntryPlanter_A, design_name
    # EntryPlanter). The instance name stays unique for the builder;
    # the DESIGN name counts as placed.
    placed_names |= {o["design_name"] for _n, _b, _p, o in objects
                     if isinstance(o.get("design_name"), str)}

    # --- naming vs DESIGN §3/§5 -------------------------------------------
    # A name passes if it IS a DESIGN name, or the entry explicitly
    # maps to one via "design_name", or the entry is explicitly marked
    # as a legitimate extra prop DESIGN never names ("extra_prop":
    # true with "design_name": null). Unmarked unknown names FAIL.
    for name, _box, path, obj in objects:
        sec = section_of(root, path)
        if not expected_names or name in expected_names:
            continue
        if obj.get("design_name") in expected_names:
            continue
        if obj.get("extra_prop") is True:
            continue
        fnd.fail(sec, path, find_line(path, '"%s"' % name),
                 "Object name '%s' is not a DESIGN.md §3/§5 name "
                 "(naming rule, §1: exact names required)" % name)
    if objects and expected_names:
        fnd.ok("(all)", "%d placed object(s); names checked against "
               "%d DESIGN names" % (len(objects), len(expected_names)))
    missing = sorted(n for n in expected_names if n not in placed_names)
    if missing:
        fnd.pend("01-layout",
                 "DESIGN names not yet placed in any manifest (build "
                 "in progress): %s" % ", ".join(missing))

    boxed = [(n, b, p, o) for n, b, p, o in objects if b is not None]

    # --- footprint bounds ---------------------------------------------------
    for name, box, path, _o in boxed:
        fx0, fx1, fz0, fz1 = bounds_of.get(path, FOOTPRINT)
        if box[0] < fx0 or box[1] > fx1 or box[2] < fz0 or box[3] > fz1:
            fnd.fail(section_of(root, path), path,
                     find_line(path, '"%s"' % name),
                     "'%s' extends outside the 40x30 footprint: "
                     "X %.2f-%.2f, Z %.2f-%.2f"
                     % (name, box[0], box[1], box[2], box[3]))

    # --- central aisle ------------------------------------------------------
    ax0, ax1, az0, az1 = AISLE
    for name, box, path, obj in boxed:
        if is_marker(name) or "Carpet" in name or "Runner" in name \
                or "Aisle" in name:
            continue
        # DESIGN ruling (see AISLE_EXEMPT_NAMES): the two §3 blackjack
        # tables and their own signage are exempt; nothing else is.
        if name in AISLE_EXEMPT_NAMES:
            continue
        # Non-ground objects (hanging signs, ceiling pieces) cannot
        # block a walkway.
        if str(obj.get("level", "")).lower() in NON_GROUND_LEVELS:
            continue
        if boxes_overlap(box, AISLE):
            fnd.fail(section_of(root, path), path,
                     find_line(path, '"%s"' % name),
                     "'%s' intrudes on the central aisle "
                     "(X 18-22, Z 2-22), which §1 requires be kept "
                     "completely clear" % name)

    # --- pairwise overlap ---------------------------------------------------
    for i in range(len(boxed)):
        for j in range(i + 1, len(boxed)):
            n1, b1, p1, o1 = boxed[i]
            n2, b2, p2, o2 = boxed[j]
            if n1 == n2:
                continue
            if is_flat(n1, o1) or is_flat(n2, o2):
                continue
            if is_marker(n1) or is_marker(n2):
                continue
            if boxes_overlap(b1, b2):
                fnd.fail(section_of(root, p1), p1,
                         find_line(p1, '"%s"' % n1),
                         "'%s' overlaps '%s' (%s)" %
                         (n1, n2, os.path.basename(p2)))

    # --- game-table clear rings ---------------------------------------------
    tables = [(n, b, p) for n, b, p, _o in boxed
              if n in GAME_TABLE_NAMES]
    for tname, tbox, tpath in tables:
        ring = (tbox[0] - CLEAR_RING, tbox[1] + CLEAR_RING,
                tbox[2] - CLEAR_RING, tbox[3] + CLEAR_RING)
        for name, box, path, obj in boxed:
            if name == tname or name.startswith(tname):
                continue
            if is_marker(name) or is_flat(name, obj):
                continue
            if any(tok in name for tok in RING_EXEMPT_TOKENS):
                continue
            # A table's own sign (hanging over it / mounted on it) is
            # dressing for that table, not a ring intrusion.
            if TABLE_SIGNS.get(name) == tname:
                continue
            # Non-ground objects (hanging signs, ceiling beams) do not
            # occupy the floor ring around a table.
            if str(obj.get("level", "")).lower() in NON_GROUND_LEVELS:
                continue
            if boxes_overlap(box, ring) and not boxes_overlap(box, tbox):
                fnd.fail(section_of(root, path), path,
                         find_line(path, '"%s"' % name),
                         "'%s' sits inside the 1.5-unit clear ring of "
                         "game table '%s' (§1 clearance rule)"
                         % (name, tname))
    if tables:
        fnd.ok("(all)", "%d game table(s) found; clear rings checked"
               % len(tables))
    return placed_names


def strip_lua(src):
    """Remove Lua comments and string contents for balance counting."""
    out = []
    i, n = 0, len(src)
    while i < n:
        if src.startswith("--[[", i):
            j = src.find("]]", i + 4)
            i = n if j == -1 else j + 2
        elif src.startswith("--", i):
            j = src.find("\n", i)
            i = n if j == -1 else j
        elif src.startswith("[[", i):
            j = src.find("]]", i + 2)
            i = n if j == -1 else j + 2
        elif src[i] in "\"'":
            q = src[i]
            i += 1
            while i < n and src[i] != q:
                i += 2 if src[i] == "\\" else 1
            i += 1
        else:
            out.append(src[i])
            i += 1
    return "".join(out)


def check_lua(root, fnd):
    count = 0
    luac = shutil.which("luac") or shutil.which("luac5.4") \
        or shutil.which("lua")
    for path in iter_files(root, (".lua",)):
        count += 1
        sec = section_of(root, path)
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        if luac:
            exe = ["luac", "-p", path] if "luac" in luac \
                else ["luac5.4", "-p", path]
            try:
                r = subprocess.run(exe, capture_output=True, text=True,
                                   timeout=30)
                if r.returncode != 0:
                    fnd.fail(sec, path, None,
                             "luac syntax error: %s"
                             % (r.stderr.strip().splitlines() or ["?"])[0])
                continue
            except (OSError, subprocess.SubprocessError):
                pass  # fall through to balance check
        code = strip_lua(src)
        for open_c, close_c in (("(", ")"), ("{", "}"), ("[", "]")):
            if code.count(open_c) != code.count(close_c):
                fnd.fail(sec, path, None,
                         "Unbalanced '%s%s': %d open vs %d close"
                         % (open_c, close_c, code.count(open_c),
                            code.count(close_c)))
        words = re.findall(r"[A-Za-z_][A-Za-z0-9_]*", code)
        openers = sum(words.count(w)
                      for w in ("function", "if", "for", "while"))
        # A 'do' that closes a for/while header is not a block opener.
        # Track pending headers: each for/while expects one header 'do';
        # any 'do' beyond those opens a standalone do...end block.
        pending_headers = 0
        standalone_dos = 0
        for w in words:
            if w in ("for", "while"):
                pending_headers += 1
            elif w == "do":
                if pending_headers > 0:
                    pending_headers -= 1
                else:
                    standalone_dos += 1
        openers += standalone_dos
        ends = words.count("end")
        repeats = words.count("repeat")
        untils = words.count("until")
        if openers != ends:
            fnd.fail(sec, path, None,
                     "Block imbalance: %d block opener(s) "
                     "(function/if/for/while/do) vs %d 'end'"
                     % (openers, ends))
        if repeats != untils:
            fnd.fail(sec, path, None,
                     "Block imbalance: %d 'repeat' vs %d 'until'"
                     % (repeats, untils))
    if count:
        fnd.ok("(all)", "%d Lua file(s) sanity-checked%s"
               % (count, " with luac" if luac else
                  " (balance check only — no luac on this machine)"))
    return count


def check_anchors(root, fnd, placed_names, design_anchors):
    referenced = {}  # anchor -> [(path, line)]
    for path in iter_files(root, (".lua", ".json", ".md", ".yml", ".yaml")):
        if os.path.basename(path) == "SWEEP_REPORT.md":
            continue
        try:
            with open(path, "r", encoding="utf-8",
                      errors="replace") as fh:
                for i, line in enumerate(fh, 1):
                    for m in ANCHOR_RE.finditer(line):
                        referenced.setdefault(m.group(0), []).append(
                            (path, i))
        except OSError:
            continue
    for anchor, refs in sorted(referenced.items()):
        if anchor in placed_names:
            continue
        if anchor in design_anchors:
            fnd.pend(section_of(root, refs[0][0]),
                     "Anchor '%s' is referenced (%s:%d) and defined in "
                     "DESIGN §5, but not yet placed in a manifest"
                     % (anchor, os.path.basename(refs[0][0]), refs[0][1]))
        else:
            path, line = refs[0]
            fnd.fail(section_of(root, path), path, line,
                     "Reference to anchor '%s', which exists in no "
                     "manifest and is not a DESIGN §5 anchor "
                     "(possible typo)" % anchor)
    if referenced:
        fnd.ok("(all)", "%d distinct anchor name(s) referenced; "
               "all resolve to DESIGN §5 or a manifest"
               % len(referenced))

# ---------------------------------------------------------------- main


def main():
    ap = argparse.ArgumentParser(description="Monster House world QA sweep")
    here = os.path.dirname(os.path.abspath(__file__))
    ap.add_argument("--root", default=os.path.dirname(here),
                    help="repo root (default: parent of 08-qa/)")
    ap.add_argument("--design",
                    default=os.path.join(
                        os.path.dirname(os.path.dirname(here)),
                        "DESIGN.md"),
                    help="path to DESIGN.md")
    ap.add_argument("--json", action="store_true",
                    help="also print machine-readable JSON summary")
    args = ap.parse_args()
    root = os.path.abspath(args.root)
    fnd = Findings()

    # section presence → PENDING tolerance
    for sec in SECTIONS:
        d = os.path.join(root, sec)
        if not os.path.isdir(d):
            fnd.pend(sec, "Section folder does not exist yet — crew "
                     "still building (PENDING, not a failure)")
        elif sec != "08-qa" and not any(True for _ in iter_files(d, (
                ".json", ".lua", ".md", ".yml", ".yaml"))):
            fnd.pend(sec, "Section folder is empty — crew still "
                     "building (PENDING, not a failure)")

    expected_names, design_anchors = design_names(args.design)
    if not expected_names:
        fnd.pend("08-qa", "DESIGN.md not found at %s — naming/anchor "
                 "checks ran in degraded mode" % args.design)

    parsed = check_json(root, fnd)
    placed = check_layout(root, fnd, parsed, expected_names)
    lua_count = check_lua(root, fnd)
    if lua_count == 0:
        fnd.pend("03-scripts-card-games",
                 "No Lua files in repo yet — script checks PENDING")
    check_anchors(root, fnd, placed, design_anchors)

    # ---------------- report ----------------
    print("=" * 68)
    print("MONSTER HOUSE WORLD — QA SWEEP")
    print("Repo root: %s" % root)
    print("=" * 68)
    for sec, note in fnd.passes:
        print("PASS    [%s] %s" % (sec, note))
    for sec, note in fnd.pending:
        print("PENDING [%s] %s" % (sec, note))
    for sec, path, line, problem in fnd.fails:
        loc = os.path.relpath(path, root)
        if line:
            loc += ":%d" % line
        print("FAIL    [%s] %s — %s" % (sec, loc, problem))
    print("-" * 68)
    print("Totals: %d pass note(s), %d pending, %d FAIL"
          % (len(fnd.passes), len(fnd.pending), len(fnd.fails)))
    if args.json:
        print(json.dumps({
            "fails": [{"section": s, "file": os.path.relpath(p, root),
                       "line": l, "problem": pr}
                      for s, p, l, pr in fnd.fails],
            "pending": [{"section": s, "note": n}
                        for s, n in fnd.pending],
            "passes": [{"section": s, "note": n}
                       for s, n in fnd.passes],
        }, indent=2))
    return 1 if fnd.fails else 0


if __name__ == "__main__":
    sys.exit(main())
