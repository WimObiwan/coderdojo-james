"""Export the radar parts as STEP files, for Fusion and Onshape.

STEP files are real solids (flat faces, round holes), not triangle meshes like the
STLs. Fusion: open the .step and save it as a Fusion design (.f3d). Onshape: Import.

The sizes are read from radar_parts.scad, so change measurements THERE, export the
STLs with OpenSCAD, then run this script. It rebuilds the same shapes as the
head() and stand() modules in the .scad, and checks its result against the STLs.

Needs CadQuery:  python3 -m venv cq && cq/bin/pip install cadquery
Run (in this folder):  cq/bin/python export_step.py
"""
import re
from pathlib import Path

import cadquery as cq

HERE = Path(__file__).resolve().parent
SCAD = HERE / "radar_parts.scad"

# Plain numbers set in the .scad ("name = 12.3;"). Everything derived from them is
# recomputed below with the same formulas as in the .scad.
NAMES = ["pcb_w", "pcb_h", "can_d", "can_spacing", "can_z", "front_parts",
         "servo_l", "servo_w", "tab_z", "tab_holes", "clr", "wall",
         "face_t", "foot_t", "pcb_t", "base_t", "deck_t"]
text = SCAD.read_text()
p = {}
for name in NAMES:
    m = re.search(rf"^\s*{name}\s*=\s*(-?[0-9.]+)\s*;", text, re.M)
    if not m:
        raise SystemExit(f"{name} not found as a plain number in {SCAD.name}")
    p[name] = float(m.group(1))
globals().update(p)

# --- derived values, as in the .scad ---
gap = front_parts + 1
pcb_y = face_t + gap
axis_y = pcb_y + pcb_t + 5
head_W = pcb_w + 2 * wall
head_H = foot_t + pcb_h + 2
head_D = axis_y + 7

in_l = servo_l + 2 * clr
in_w = servo_w + 2 * clr
deck_L = tab_holes + 8
deck_W = in_w + 2 * wall
deck_top = base_t + tab_z + 0.5
base_L = deck_L + 16
base_W = deck_W + 12


def box(x, y, z, dx, dy, dz):
    return cq.Solid.makeBox(dx, dy, dz, cq.Vector(x, y, z))


def cyl(d, h, x, y, z, direction=(0, 0, 1)):
    return cq.Solid.makeCylinder(d / 2, h, cq.Vector(x, y, z), cq.Vector(*direction))


def head():
    s = box(-head_W / 2, 0, 0, head_W, face_t, head_H)                  # faceplate
    s = s.fuse(box(-head_W / 2, 0, 0, head_W, head_D, foot_t))          # foot
    for sx in (-1, 1):
        for z in (foot_t, foot_t + pcb_h - 2):                          # 4 standoffs
            x = pcb_w / 2 - 2 if sx > 0 else -pcb_w / 2
            s = s.fuse(box(x, face_t - 0.01, z, 2, gap + 0.01, 2))
        x = pcb_w / 2 - 4 if sx > 0 else -pcb_w / 2                     # 2 ridges
        s = s.fuse(box(x, pcb_y + pcb_t + clr, foot_t - 0.01, 4, 2, 3))
    for sx in (-1, 1):                                                  # the two eyes
        s = s.cut(cyl(can_d + 2 * clr, face_t + 1.5,
                      sx * can_spacing / 2, -1, foot_t + can_z, (0, 1, 0)))
    s = s.cut(cyl(6, foot_t + 2, 0, axis_y, -1))                        # horn screw access
    return s.clean()


def stand():
    s = box(-base_L / 2, -base_W / 2, 0, base_L, base_W, base_t)        # base
    for sy in (-1, 1):                                                  # side walls
        y = in_w / 2 if sy > 0 else -in_w / 2 - wall
        s = s.fuse(box(-deck_L / 2, y, 0, deck_L, wall, deck_top))
    s = s.fuse(box(-deck_L / 2, -deck_W / 2, deck_top - deck_t, deck_L, deck_W, deck_t))  # deck
    s = s.cut(box(-in_l / 2, -in_w / 2, base_t, in_l, in_w, 100))       # servo body
    for sx in (-1, 1):
        s = s.cut(cyl(1.8, 100, sx * tab_holes / 2, 0, base_t))         # tab screw pilots
        s = s.cut(cyl(3.4, base_t + 2, sx * (base_L / 2 - 4), 0, -1))   # base screw holes
    return s.clean()


def stl_props(path):
    """Volume, size, centre of mass and second moments (about the centre of mass)
    of an ASCII STL from OpenSCAD. A moved hole changes the moments even when the
    volume and the outer size stay the same."""
    tri = []
    vol, first, second = 0.0, [0.0] * 3, [0.0] * 3
    lo, hi = [1e9] * 3, [-1e9] * 3
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line.startswith("vertex"):
            continue
        v = [float(t) for t in line.split()[1:4]]
        tri.append(v)
        lo = [min(a, b) for a, b in zip(lo, v)]
        hi = [max(a, b) for a, b in zip(hi, v)]
        if len(tri) == 3:
            a, b, c = tri
            d = (a[0] * (b[1] * c[2] - b[2] * c[1])
                 - a[1] * (b[0] * c[2] - b[2] * c[0])
                 + a[2] * (b[0] * c[1] - b[1] * c[0]))       # 6 x signed tetra volume
            vol += d / 6
            for i in range(3):
                first[i] += d / 24 * (a[i] + b[i] + c[i])
                second[i] += d / 60 * (a[i] ** 2 + b[i] ** 2 + c[i] ** 2
                                       + a[i] * b[i] + a[i] * c[i] + b[i] * c[i])
            tri = []
    com = [f / vol for f in first]
    sec = [s - vol * g ** 2 for s, g in zip(second, com)]
    return abs(vol), [h - l for l, h in zip(lo, hi)], com, [abs(s) for s in sec]


def step_props(shape):
    from OCP.BRepGProp import BRepGProp
    from OCP.GProp import GProp_GProps
    g = GProp_GProps()
    BRepGProp.VolumeProperties_s(shape.wrapped, g)
    c, m = g.CentreOfMass(), g.MatrixOfInertia()
    ixx, iyy, izz = m.Value(1, 1), m.Value(2, 2), m.Value(3, 3)
    sec = [(iyy + izz - ixx) / 2, (ixx + izz - iyy) / 2, (ixx + iyy - izz) / 2]
    return g.Mass(), [c.X(), c.Y(), c.Z()], sec


ok = True
for name, make in (("radar_head", head), ("radar_stand", stand)):
    solid = make()
    out = HERE / f"{name}.step"
    cq.exporters.export(cq.Workplane().add(solid), str(out), exportType="STEP")

    back = cq.importers.importStep(str(out)).val()      # read it back, as Fusion/Onshape would
    bb = back.BoundingBox()
    size = [bb.xlen, bb.ylen, bb.zlen]
    print(f"{out.name}: {len(back.Solids())} solid, valid={back.isValid()}, "
          f"volume {back.Volume():.0f} mm3, size {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f} mm")
    if len(back.Solids()) != 1 or not back.isValid():
        ok = False

    stl = HERE / f"{name}.stl"
    if stl.exists():
        v_stl, size_stl, com_stl, sec_stl = stl_props(stl)
        v, com, sec = step_props(back)
        dv = (v - v_stl) / v_stl * 100
        dsize = max(abs(a - b) for a, b in zip(size, size_stl))
        dcom = max(abs(a - b) for a, b in zip(com, com_stl))
        dsec = max(abs(a - b) / b * 100 for a, b in zip(sec, sec_stl))
        print(f"  vs {stl.name}: volume {dv:+.2f} %, size {dsize:.2f} mm, "
              f"centre of mass {dcom:.3f} mm, moments {dsec:.2f} %")
        if abs(dv) > 1 or dsize > 0.05 or dcom > 0.05 or dsec > 0.5:
            print("  WARNING: does not match the STL. Re-export the STL, or the .scad and"
                  " this script no longer describe the same part.")
            ok = False

raise SystemExit(0 if ok else 1)
