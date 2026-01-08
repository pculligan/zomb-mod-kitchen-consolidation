
from __future__ import annotations

"""
renderer.py — practical sprite renderer

Goal: produce usable pipe sprites for Project Zomboid without hand pixel work.

Model:
- Three run directions in isometric basis:
    ISO_X : screen step (+1,+1)
    ISO_Y : screen step (-1,+1)
    ISO_Z : screen step ( 0,+1)  (vertical riser direction in screen space; we draw up by subtracting y)
- Geometry emits RunDir intent via a mask so overlaps are truthful.
- Classification is per (pixel, RunDir):
    edge_scan: run boundary along run axis
    point: special case of edge_scan
    edge_perp: silhouette edge perpendicular to run axis
    edge_side: LIGHT/DARK derived from which exposed perp side points toward global light (-1,-1)
- Shading is point-driven and uses only classification outputs (no guessing):
    DARK edge points -> 4-step shadow band inward along run axis
    LIGHT edge points -> 2-step highlight inward along run axis
    point glow -> 2-step black glow outward along run axis (both ends), force alpha

Debug:
- If DEBUG_CLASSIFICATION is True, we attach img._classification for exporter.
"""

from dataclasses import dataclass
from enum import Enum, auto
from typing import DefaultDict, Dict, Set, Tuple
from collections import defaultdict

from PIL import Image, ImageDraw


# ============================================================
# Enums / constants
# ============================================================

class RunDir(Enum):
    ISO_X = auto()
    ISO_Y = auto()
    ISO_Z = auto()


class EdgeSide(Enum):
    LIGHT = auto()
    DARK = auto()


TILE_W = 128
TILE_H = 256

FLOOR_CX = 63
FLOOR_CY = TILE_H - 33

WALL_CUBE_PX = TILE_W // 2
WALL_HEIGHT_PX = WALL_CUBE_PX * 3

DEBUG_CLASSIFICATION = True
ENABLE_SHADING = True


# Screen-space light direction (up-left)
LIGHT_VEC = (-1, -1)


# ============================================================
# Small helpers
# ============================================================

def _opaque(px, x: int, y: int) -> bool:
    return px[x, y][3] > 0


def iso_project_floor(x: float, y: float) -> Tuple[int, int]:
    return (
        int(FLOOR_CX + (x - y)),
        int(FLOOR_CY + (x + y) // 2),
    )


def run_vec(rd: RunDir) -> Tuple[int, int]:
    # screen-space direction of the run
    if rd == RunDir.ISO_X:
        return (1, 1)
    if rd == RunDir.ISO_Y:
        return (-1, 1)
    # ISO_Z: vertical in screen space
    return (0, 1)


def perp_vecs(vx: int, vy: int) -> Tuple[Tuple[int, int], Tuple[int, int]]:
    # 90° rotations in screen space
    return ((-vy, vx), (vy, -vx))


def dot(a: Tuple[int, int], b: Tuple[int, int]) -> int:
    return a[0] * b[0] + a[1] * b[1]


# ============================================================
# Alpha overlays
# ============================================================

def alpha_overlay(px, x, y, overlay_rgb, alpha):
    r, g, b, a = px[x, y]
    or_, og, ob = overlay_rgb
    px[x, y] = (
        int(r * (1 - alpha) + or_ * alpha),
        int(g * (1 - alpha) + og * alpha),
        int(b * (1 - alpha) + ob * alpha),
        a,
    )


def shadow_overlay(px, x, y, alpha):
    alpha_overlay(px, x, y, (0, 0, 0), alpha)


def light_overlay(px, x, y, alpha):
    alpha_overlay(px, x, y, (255, 255, 255), alpha)


def shadow_overlay_force_alpha(px, x, y, alpha):
    # outside the shape pixels have a=0; force alpha so the glow is visible
    r, g, b, _ = px[x, y]
    px[x, y] = (
        int(r * (1 - alpha)),
        int(g * (1 - alpha)),
        int(b * (1 - alpha)),
        int(255 * alpha),
    )


# ============================================================
# Intent emission (mask-based)
# ============================================================

def emit_run_dir_from_mask(mask: Image.Image,
                           run_map: DefaultDict[Tuple[int, int], Set[RunDir]],
                           run_dir: RunDir) -> None:
    px = mask.load()
    for y in range(TILE_H):
        for x in range(TILE_W):
            if px[x, y][3] > 0:
                run_map[(x, y)].add(run_dir)


def draw_stroke_with_intent(img: Image.Image,
                            run_map: DefaultDict[Tuple[int, int], Set[RunDir]],
                            p1: Tuple[int, int],
                            p2: Tuple[int, int],
                            *,
                            width: int,
                            run_dir: RunDir,
                            color: Tuple[int, int, int, int],
                            mode: str) -> None:
    """
    mode:
      - "floor": Pillow width stroke (best caps)
      - "wall": deterministic multiline (stable)
    """
    draw = ImageDraw.Draw(img)

    if mode == "floor":
        draw.line([p1, p2], fill=color, width=width)
        mask = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
        mdraw = ImageDraw.Draw(mask)
        mdraw.line([p1, p2], fill=(255, 255, 255, 255), width=width)
        emit_run_dir_from_mask(mask, run_map, run_dir)
        return

    # wall multiline
    half = width // 2
    # choose offset axis by run_dir: vertical riser offsets in X; diagonal offsets in Y
    if run_dir == RunDir.ISO_Z:
        offsets = [(dx, 0) for dx in range(-half, -half + width)]
    else:
        offsets = [(0, dy) for dy in range(-half, -half + width)]

    # draw
    for ox, oy in offsets:
        draw.line([(p1[0] + ox, p1[1] + oy), (p2[0] + ox, p2[1] + oy)], fill=color, width=1)

    # mask
    mask = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(mask)
    for ox, oy in offsets:
        mdraw.line([(p1[0] + ox, p1[1] + oy), (p2[0] + ox, p2[1] + oy)], fill=(255, 255, 255, 255), width=1)

    emit_run_dir_from_mask(mask, run_map, run_dir)


# ============================================================
# Classification
# ============================================================

def classify_per_run(img: Image.Image,
                     run_map: Dict[Tuple[int, int], Set[RunDir]]) -> Dict[Tuple[int, int], Dict[RunDir, dict]]:
    px = img.load()
    flags: Dict[Tuple[int, int], Dict[RunDir, dict]] = {}

    for (x, y), dirs in run_map.items():
        if not dirs:
            continue
        flags[(x, y)] = {}
        for rd in dirs:
            vx, vy = run_vec(rd)
            scan1 = (vx, vy)
            scan2 = (-vx, -vy)
            perp1, perp2 = perp_vecs(vx, vy)

            def in_run(nx, ny) -> bool:
                return (
                    0 <= nx < TILE_W and 0 <= ny < TILE_H and
                    _opaque(px, nx, ny) and
                    rd in run_map.get((nx, ny), set())
                )

            s1 = in_run(x + scan1[0], y + scan1[1])
            s2 = in_run(x + scan2[0], y + scan2[1])

            p1 = in_run(x + perp1[0], y + perp1[1])
            p2 = in_run(x + perp2[0], y + perp2[1])

            edge_scan = not (s1 and s2)
            point = edge_scan and (not s1 or not s2)

            edge_perp = not (p1 and p2)

            edge_side = None
            if edge_perp:
                # which perp side is exposed?
                exposed = None
                if not p1 and p2:
                    exposed = perp1
                elif not p2 and p1:
                    exposed = perp2
                # if both exposed or neither, leave None; this is rare and mostly at thin artifacts
                if exposed is not None:
                    # decide LIGHT/DARK by which exposed direction points more toward light vec
                    edge_side = EdgeSide.LIGHT if dot(exposed, LIGHT_VEC) > 0 else EdgeSide.DARK

            flags[(x, y)][rd] = {
                "edge_scan": edge_scan,
                "point": point,
                "edge_perp": edge_perp,
                "edge_side": edge_side,
                "scan": (scan1, scan2),
                "perp": (perp1, perp2),
            }

    return flags


# ============================================================
# Bulk helpers (for debug only; shading for bulk comes later)
# ============================================================

def compute_effective_bulk(img: Image.Image,
                           run_map: Dict[Tuple[int, int], Set[RunDir]]) -> Set[Tuple[int, int]]:
    """
    Bulk interior:
      - >=2 RunDirs and no 4-neighbor transparency
      - OR enclosed-junction fill (4-neighbor enclosed, neighbor dirs union>=2)
    """
    px = img.load()
    bulk: Set[Tuple[int, int]] = set()

    for (x, y), dirs in run_map.items():
        # rule 1
        if len(dirs) >= 2:
            touches_air = False
            for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < TILE_W and 0 <= ny < TILE_H) or not _opaque(px, nx, ny):
                    touches_air = True
                    break
            if not touches_air:
                bulk.add((x, y))
                continue

        # rule 2
        enclosed = True
        neighbor_dirs: Set[RunDir] = set()
        for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < TILE_W and 0 <= ny < TILE_H) or not _opaque(px, nx, ny):
                enclosed = False
                break
            neighbor_dirs |= run_map.get((nx, ny), set())
        if enclosed and len(neighbor_dirs) >= 2:
            bulk.add((x, y))

    return bulk


def compute_bulk_adjacent_edge(img: Image.Image,
                               run_map: Dict[Tuple[int, int], Set[RunDir]],
                               bulk_pixels: Set[Tuple[int, int]]) -> Set[Tuple[int, int]]:
    px = img.load()
    out: Set[Tuple[int, int]] = set()
    for (x, y), dirs in run_map.items():
        if not dirs or (x, y) in bulk_pixels:
            continue
        adjacent_bulk = False
        adjacent_air = False
        for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < TILE_W and 0 <= ny < TILE_H:
                if (nx, ny) in bulk_pixels:
                    adjacent_bulk = True
                elif not _opaque(px, nx, ny):
                    adjacent_air = True
        if adjacent_bulk and adjacent_air:
            out.add((x, y))
    return out


# ============================================================
# Shading operators (point-driven)
# ============================================================

def shadow_band_inward(px, x, y, dx, dy):
    # 4-step falloff
    shadow_overlay(px, x, y, 0.45)
    for step, a in ((1, 0.30), (2, 0.18), (3, 0.07)):
        xx, yy = x + step * dx, y + step * dy
        if 0 <= xx < TILE_W and 0 <= yy < TILE_H:
            shadow_overlay(px, xx, yy, a)


def light_point_highlight(px, x, y, dx, dy):
    light_overlay(px, x, y, 0.45)
    xx, yy = x + dx, y + dy
    if 0 <= xx < TILE_W and 0 <= yy < TILE_H:
        light_overlay(px, xx, yy, 0.18)


def black_glow_scanline(px, x, y, dx, dy):
    # darker values (as requested)
    x1, y1 = x + dx, y + dy
    if 0 <= x1 < TILE_W and 0 <= y1 < TILE_H:
        shadow_overlay_force_alpha(px, x1, y1, 0.20)
    x2, y2 = x + 2*dx, y + 2*dy
    if 0 <= x2 < TILE_W and 0 <= y2 < TILE_H:
        shadow_overlay_force_alpha(px, x2, y2, 0.10)


def apply_point_shading(img: Image.Image,
                        run_map: Dict[Tuple[int, int], Set[RunDir]],
                        per_run_flags: Dict[Tuple[int, int], Dict[RunDir, dict]]) -> None:
    """
    Apply ONLY point-driven treatments:
      - DARK edge points -> shadow band inward along run axis (toward inside)
      - LIGHT edge points -> highlight inward along run axis (toward inside)
      - glow outward along run axis on BOTH sides of the point
    """
    px = img.load()

    for (x, y), flags in per_run_flags.items():
        for rd, f in flags.items():
            if not f.get("edge_perp") or not f.get("point"):
                continue

            scan1, scan2 = f["scan"]

            # Determine inward direction: the scan step that is inside the run
            nx, ny = x + scan1[0], y + scan1[1]
            if 0 <= nx < TILE_W and 0 <= ny < TILE_H and _opaque(px, nx, ny):
                inward = scan1
                outward = scan2
            else:
                inward = scan2
                outward = scan1

            if f.get("edge_side") == EdgeSide.DARK:
                shadow_band_inward(px, x, y, inward[0], inward[1])
            elif f.get("edge_side") == EdgeSide.LIGHT:
                light_point_highlight(px, x, y, inward[0], inward[1])

            # glow both outward directions (only if outside)
            for dx, dy in (scan1, scan2):
                tx, ty = x + dx, y + dy
                if not (0 <= tx < TILE_W and 0 <= ty < TILE_H and _opaque(px, tx, ty)):
                    black_glow_scanline(px, x, y, dx, dy)

            break


# ============================================================
# Classification visualization
# ============================================================

def debug_color_for_pixel(dirs: Set[RunDir], per_run_flags: Dict[RunDir, dict]) -> Tuple[int, int, int, int]:
    # simple base coloring, edge_side overlay handled in build_classification_image
    if len(dirs) > 1:
        return (255, 255, 255, 255)

    rd = next(iter(dirs))
    f = per_run_flags.get(rd, {})

    if f.get("point"):
        if rd == RunDir.ISO_X:
            return (255, 0, 255, 255)
        if rd == RunDir.ISO_Y:
            return (255, 255, 0, 255)
        return (255, 0, 0, 255)

    if f.get("edge_scan"):
        if rd == RunDir.ISO_X:
            return (0, 255, 255, 255)
        if rd == RunDir.ISO_Y:
            return (0, 255, 0, 255)
        return (255, 128, 0, 255)

    if f.get("edge_perp"):
        if rd == RunDir.ISO_X:
            return (0, 0, 180, 255)
        if rd == RunDir.ISO_Y:
            return (0, 128, 128, 255)
        return (128, 64, 0, 255)

    return (64, 64, 64, 255)


def build_classification_image(run_map: Dict[Tuple[int, int], Set[RunDir]],
                               per_run_flags: Dict[Tuple[int, int], Dict[RunDir, dict]],
                               effective_bulk: Set[Tuple[int, int]],
                               bulk_adjacent_edge: Set[Tuple[int, int]]) -> Image.Image:
    cls_img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    px = cls_img.load()

    for (x, y), dirs in run_map.items():
        if not dirs:
            continue

        if (x, y) in effective_bulk and (x, y) not in bulk_adjacent_edge:
            px[x, y] = (255, 255, 255, 255)
            continue
        if (x, y) in bulk_adjacent_edge:
            px[x, y] = (200, 200, 200, 255)
            continue

        flags = per_run_flags.get((x, y), {})
        r, g, b, a = debug_color_for_pixel(dirs, flags)

        # overlay edge_side
        for rd, f in flags.items():
            if f.get("edge_perp") and f.get("edge_side") is not None:
                if f["edge_side"] == EdgeSide.LIGHT:
                    r = min(255, int(r * 0.5 + 255 * 0.5))
                    g = min(255, int(g * 0.5 + 255 * 0.5))
                    b = int(b * 0.5)
                else:
                    r = int(r * 0.3)
                    g = int(g * 0.3)
                    b = int(b * 0.3)
                break

        px[x, y] = (r, g, b, a)

    return cls_img


# ============================================================
# Render jobs / geometry
# ============================================================

@dataclass(frozen=True)
class RenderJob:
    pipe_set: str
    surface: str
    shape: str
    variant: str


def render(job: RenderJob, geometry: dict, pipe_sets: dict) -> Image.Image:
    pipe_set = pipe_sets[job.pipe_set]
    base_color = tuple(pipe_set["colors"]["body"])
    thickness = pipe_set["thickness"]

    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    run_map: DefaultDict[Tuple[int, int], Set[RunDir]] = defaultdict(set)

    half = TILE_W // 4  # 32

    # ---------------- Geometry: floor ----------------
    if job.surface == "floor":
        if job.shape == "straight":
            if job.variant == "EW":
                p1 = iso_project_floor(-half, 0)
                p2 = iso_project_floor(+half, 0)
                draw_stroke_with_intent(img, run_map, p1, p2, width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
            elif job.variant == "NS":
                p1 = iso_project_floor(0, -half)
                p2 = iso_project_floor(0, +half)
                draw_stroke_with_intent(img, run_map, p1, p2, width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")

        elif job.shape == "end":
            if job.variant == "N":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, -half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")
            elif job.variant == "S":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, +half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")
            elif job.variant == "E":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(+half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
            elif job.variant == "W":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(-half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")

        elif job.shape == "elbow":
            if job.variant == "NE":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, -half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(+half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
            elif job.variant == "ES":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(+half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, +half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")
            elif job.variant == "SW":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, +half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(-half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
            elif job.variant == "WN":
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(-half, 0),
                                        width=thickness, run_dir=RunDir.ISO_X, color=base_color, mode="floor")
                draw_stroke_with_intent(img, run_map, iso_project_floor(0, 0), iso_project_floor(0, -half),
                                        width=thickness, run_dir=RunDir.ISO_Y, color=base_color, mode="floor")

        elif job.shape == "tee":
            if job.variant == "NEW":
                arms = [(RunDir.ISO_Y, (0,0), (0,-half)), (RunDir.ISO_X, (0,0), (+half,0)), (RunDir.ISO_X, (0,0), (-half,0))]
            elif job.variant == "NES":
                arms = [(RunDir.ISO_Y, (0,0), (0,-half)), (RunDir.ISO_X, (0,0), (+half,0)), (RunDir.ISO_Y, (0,0), (0,+half))]
            elif job.variant == "ESW":
                arms = [(RunDir.ISO_X, (0,0), (+half,0)), (RunDir.ISO_Y, (0,0), (0,+half)), (RunDir.ISO_X, (0,0), (-half,0))]
            elif job.variant == "NSW":
                arms = [(RunDir.ISO_Y, (0,0), (0,-half)), (RunDir.ISO_Y, (0,0), (0,+half)), (RunDir.ISO_X, (0,0), (-half,0))]
            else:
                arms = []
            for rd, (x1,y1), (x2,y2) in arms:
                draw_stroke_with_intent(img, run_map, iso_project_floor(x1,y1), iso_project_floor(x2,y2),
                                        width=thickness, run_dir=rd, color=base_color, mode="floor")

        elif job.shape == "cross":
            arms = [(RunDir.ISO_Y, (0,0), (0,-half)), (RunDir.ISO_Y, (0,0), (0,+half)),
                    (RunDir.ISO_X, (0,0), (+half,0)), (RunDir.ISO_X, (0,0), (-half,0))]
            for rd, (x1,y1), (x2,y2) in arms:
                draw_stroke_with_intent(img, run_map, iso_project_floor(x1,y1), iso_project_floor(x2,y2),
                                        width=thickness, run_dir=rd, color=base_color, mode="floor")

    # ---------------- Geometry: walls (straights only, current) ----------------
    if job.surface in ("wall_n", "wall_w") and job.shape == "straight":
        if job.variant == "NS":
            # floor-resting riser base
            base = iso_project_floor(0, -half) if job.surface == "wall_n" else iso_project_floor(-half, 0)
            p1 = base
            p2 = (base[0], base[1] - WALL_HEIGHT_PX)
            draw_stroke_with_intent(img, run_map, p1, p2, width=thickness, run_dir=RunDir.ISO_Z, color=base_color, mode="wall")

        if job.variant == "EW":
            lift = WALL_CUBE_PX + (WALL_CUBE_PX // 2)
            if job.surface == "wall_n":
                p1 = iso_project_floor(-half, -half)
                p2 = iso_project_floor(+half, -half)
                rd = RunDir.ISO_X
            else:
                p1 = iso_project_floor(-half, -half)
                p2 = iso_project_floor(-half, +half)
                rd = RunDir.ISO_Y
            p1 = (p1[0], p1[1] - lift)
            p2 = (p2[0], p2[1] - lift)
            draw_stroke_with_intent(img, run_map, p1, p2, width=thickness, run_dir=rd, color=base_color, mode="wall")

    # ---------------- Classification ----------------
    per_run_flags = classify_per_run(img, run_map)

    # ---------------- Shading (point-driven) ----------------
    if ENABLE_SHADING:
        apply_point_shading(img, run_map, per_run_flags)

    # ---------------- Classification image (separate) ----------------
    if DEBUG_CLASSIFICATION:
        effective_bulk = compute_effective_bulk(img, run_map)
        bulk_adjacent_edge = compute_bulk_adjacent_edge(img, run_map, effective_bulk)
        img._classification = build_classification_image(run_map, per_run_flags, effective_bulk, bulk_adjacent_edge)

    return img
