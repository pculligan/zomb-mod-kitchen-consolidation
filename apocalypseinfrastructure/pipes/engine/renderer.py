
"""
renderer.py — Intent-first classification milestone

GOAL OF THIS FILE
=================
We are explicitly NOT doing "clever shading" here.

We are refactoring the renderer so that the *classification model* is correct,
stable, and understandable. Once classification is trustworthy, we can plug
our proven shading masks back in.

CLASSIFICATION HIERARCHY (LOCKED)
=================================

Level 0: Solid vs Transparent
-----------------------------
- Everything below applies only to SOLID pixels (alpha > 0).

Level 1: RunDir membership (INTENT)
-----------------------------------
- A solid pixel may belong to one or more directional shape layers.
- This is emitted during geometry drawing (no inference from neighbors).

RunDir ∈ { ISO_X, ISO_Y, ISO_Z }
- ISO_X: isometric east–west run (diagonal on screen for floors)
- ISO_Y: isometric north–south run (other diagonal on screen for floors)
- ISO_Z: vertical riser (screen-vertical)

Level 2: Edge vs Interior (PER RunDir)
--------------------------------------
For a given pixel and a given RunDir that the pixel participates in:

- Interior: solid with solid neighbors on BOTH sides of the scan axis for that RunDir
- Edge:     solid with transparency on at least one side of that scan axis

Level 3: Point (SPECIAL CASE of Edge, PER RunDir)
-------------------------------------------------
For a given pixel and RunDir:

- Point: an Edge pixel that is also a *run boundary* along the scan direction
         (i.e., at least one of the immediate neighbors along the scan axis is transparent)

This matches the original, scanline-transition definition:
- first solid after transparent OR last solid before transparent

Level 4: Bulk (ORTHOGONAL OVERLAY)
----------------------------------
Bulk is NOT "interior of a long run".
Bulk is NOT "not-a-point".

Bulk = pixel participates in more than one RunDir (overlap / junction mass)
    bulk := len(run_dirs[pixel]) > 1

WHY DEBUG COLORS
================
We will now output an intentionally loud debug image so we can SEE:

- Which pixels belong to which RunDir
- Which pixels are edges for that RunDir
- Which edge pixels are points
- Which pixels are bulk (overlap) / junction mass

Only after this is correct do we restore the final shading system.

"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum, auto
from typing import DefaultDict, Dict, Set, Tuple
from collections import defaultdict

from PIL import Image, ImageDraw


# ============================================================
# Intent enums (global)
# ============================================================

class RunDir(Enum):
    ISO_X = auto()
    ISO_Y = auto()
    ISO_Z = auto()


# ============================================================
# Rendering constants
# ============================================================

TILE_W = 128
TILE_H = 256

FLOOR_CX = 63
FLOOR_CY = TILE_H - 33

WALL_CUBE_PX = TILE_W // 2
WALL_HEIGHT_PX = WALL_CUBE_PX * 3


# ============================================================
# Debug controls
# ============================================================

# When True: output classification debug colors (very visible).
# When False: output base geometry only (still emits intent, but no debug recolor).
DEBUG_CLASSIFICATION = True


# ============================================================
# Helpers
# ============================================================

def _opaque(px, x: int, y: int) -> bool:
    return px[x, y][3] > 0


def iso_project_floor(x: float, y: float) -> Tuple[int, int]:
    """
    Standard 2:1 isometric projection for floor plane.
    """
    return (
        int(FLOOR_CX + (x - y)),
        int(FLOOR_CY + (x + y) // 2),
    )


def clamp(v: int) -> int:
    return 0 if v < 0 else 255 if v > 255 else v


# ============================================================
# Geometry emission WITH intent
# ============================================================


# ============================================================
# Mask-based intent emission helper
# ============================================================

def emit_run_dir_from_mask(
    mask: Image.Image,
    run_map: DefaultDict[Tuple[int, int], Set[RunDir]],
    run_dir: RunDir,
) -> None:
    """
    Assign RunDir to ALL pixels painted by this stroke,
    regardless of whether they were previously opaque.
    """
    px = mask.load()
    for y in range(TILE_H):
        for x in range(TILE_W):
            if px[x, y][3] > 0:
                run_map[(x, y)].add(run_dir)


def draw_floor_stroke_with_intent(
    img: Image.Image,
    run_map: DefaultDict[Tuple[int, int], Set[RunDir]],
    p1: Tuple[int, int],
    p2: Tuple[int, int],
    *,
    thickness: int,
    run_dir: RunDir,
    color: Tuple[int, int, int, int],
) -> None:
    # Draw into the main image
    draw = ImageDraw.Draw(img)
    draw.line([p1, p2], fill=color, width=thickness)

    # Draw into a temporary mask to capture stroke coverage
    mask = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(mask)
    mdraw.line([p1, p2], fill=(255, 255, 255, 255), width=thickness)

    emit_run_dir_from_mask(mask, run_map, run_dir)


def draw_wall_multiline_with_intent(
    img: Image.Image,
    run_map: DefaultDict[Tuple[int, int], Set[RunDir]],
    p1: Tuple[int, int],
    p2: Tuple[int, int],
    *,
    thickness: int,
    run_dir: RunDir,
    color: Tuple[int, int, int, int],
    offset_axis: str,
) -> None:
    """
    Walls: deterministic rasterization (N parallel 1px strokes).
    offset_axis:
      - "x" for vertical risers (perpendicular is horizontal)
      - "y" for diagonal wall runs (perpendicular is vertical)
    """
    draw = ImageDraw.Draw(img)
    half = thickness // 2

    if offset_axis == "x":
        for dx in range(-half, -half + thickness):
            draw.line([(p1[0] + dx, p1[1]), (p2[0] + dx, p2[1])], fill=color, width=1)
    else:
        for dy in range(-half, -half + thickness):
            draw.line([(p1[0], p1[1] + dy), (p2[0], p2[1] + dy)], fill=color, width=1)

    # Draw into temp mask
    mask = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    mdraw = ImageDraw.Draw(mask)

    if offset_axis == "x":
        for dx in range(-half, -half + thickness):
            mdraw.line([(p1[0] + dx, p1[1]), (p2[0] + dx, p2[1])], fill=(255, 255, 255, 255), width=1)
    else:
        for dy in range(-half, -half + thickness):
            mdraw.line([(p1[0], p1[1] + dy), (p2[0], p2[1] + dy)], fill=(255, 255, 255, 255), width=1)

    emit_run_dir_from_mask(mask, run_map, run_dir)


# ============================================================
# Classification (edge/point per RunDir) — uses transparency, not clever math
# ============================================================

def neighbor_offsets_for_run(run_dir: RunDir):
    """
    Returns:
      scan_offsets  -> neighbors along the run direction
      perp_offsets  -> neighbors perpendicular to the run (silhouette)
    """
    if run_dir == RunDir.ISO_X:
        # diagonal run, scan horizontally, silhouette is vertical
        return ((-1, 0), (1, 0)), ((0, -1), (0, 1))
    if run_dir == RunDir.ISO_Y:
        # other diagonal run, scan horizontally, silhouette is vertical
        return ((-1, 0), (1, 0)), ((0, -1), (0, 1))
    else:  # ISO_Z
        # vertical riser, scan vertically, silhouette is horizontal
        return ((0, -1), (0, 1)), ((-1, 0), (1, 0))


def classify_per_run(
    img: Image.Image,
    run_map: Dict[Tuple[int, int], Set[RunDir]],
) -> Dict[Tuple[int, int], Dict[RunDir, Dict[str, bool]]]:
    """
    Per pixel, per RunDir flags:

    flags[(x,y)][RunDir] = {
        "edge_scan": True/False,   # run boundary
        "edge_perp": True/False,   # silhouette edge
        "point": True/False        # special case of edge_scan
    }
    """
    px = img.load()
    flags: Dict[Tuple[int, int], Dict[RunDir, Dict[str, bool]]] = {}

    for (x, y), dirs in run_map.items():
        flags[(x, y)] = {}

        for rd in dirs:
            (scan1, scan2), (perp1, perp2) = neighbor_offsets_for_run(rd)

            def in_run(nx, ny):
                return (
                    0 <= nx < TILE_W and
                    0 <= ny < TILE_H and
                    _opaque(px, nx, ny) and
                    rd in run_map.get((nx, ny), set())
                )

            s1 = in_run(x + scan1[0], y + scan1[1])
            s2 = in_run(x + scan2[0], y + scan2[1])

            p1 = in_run(x + perp1[0], y + perp1[1])
            p2 = in_run(x + perp2[0], y + perp2[1])

            edge_scan = not (s1 and s2)
            point = edge_scan and (not s1 or not s2)

            # Perpendicular silhouette edge:
            # bulk pixels are STILL edges if they touch transparency
            edge_perp = not (p1 and p2)

            flags[(x, y)][rd] = {
                "edge_scan": edge_scan,
                "edge_perp": edge_perp,
                "point": point,
            }

    return flags


# ============================================================
# Bulk correction: 1-pixel dilation at intersections
# ============================================================
def compute_effective_bulk(
    img: Image.Image,
    run_map: Dict[Tuple[int, int], Set[RunDir]],
) -> Set[Tuple[int, int]]:
    """
    Returns pixels that are true BULK INTERIOR.

    A pixel is bulk interior if:
    1) It has >=2 RunDirs AND does not touch transparency, OR
    2) It is fully enclosed by solid neighbors whose combined RunDirs >=2

    This second rule performs a minimal topological fill at true junctions
    (e.g. diagonal crosses) without smearing bulk outward.
    """
    px = img.load()
    bulk_pixels = set()

    for (x, y), dirs in run_map.items():
        # ---- Rule 1: direct overlap, fully solid ----
        if len(dirs) >= 2:
            touches_transparent = False
            for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < TILE_W and 0 <= ny < TILE_H):
                    touches_transparent = True
                    break
                if not _opaque(px, nx, ny):
                    touches_transparent = True
                    break

            if not touches_transparent:
                bulk_pixels.add((x, y))
                continue

        # ---- Rule 2: enclosed junction fill ----
        neighbor_dirs = set()
        enclosed = True

        for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
            nx, ny = x + dx, y + dy
            if not (0 <= nx < TILE_W and 0 <= ny < TILE_H):
                enclosed = False
                break
            if not _opaque(px, nx, ny):
                enclosed = False
                break
            neighbor_dirs |= run_map.get((nx, ny), set())

        if enclosed and len(neighbor_dirs) >= 2:
            bulk_pixels.add((x, y))

    return bulk_pixels

# ============================================================
# Bulk-adjacent edge: silhouette boundary around bulk mass
# ============================================================
def compute_bulk_adjacent_edge(
    img: Image.Image,
    run_map: Dict[Tuple[int, int], Set[RunDir]],
    bulk_pixels: Set[Tuple[int, int]],
) -> Set[Tuple[int, int]]:
    """
    A pixel is a bulk-adjacent edge if:
    - It is NOT bulk itself
    - It is solid
    - It is 4-neighbor adjacent to at least one bulk pixel
    - It is 4-neighbor adjacent to at least one transparent pixel

    This captures the silhouette boundary around junction mass
    without polluting scanline edge logic.
    """
    px = img.load()
    result = set()

    for (x, y), dirs in run_map.items():
        if (x, y) in bulk_pixels:
            continue

        if not dirs:
            continue

        adjacent_bulk = False
        adjacent_transparent = False

        for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < TILE_W and 0 <= ny < TILE_H:
                if (nx, ny) in bulk_pixels:
                    adjacent_bulk = True
                elif not _opaque(px, nx, ny):
                    adjacent_transparent = True

        if adjacent_bulk and adjacent_transparent:
            result.add((x, y))

    return result


# ============================================================
# Debug coloring
# ============================================================

def debug_color_for_pixel(
    dirs: Set[RunDir],
    per_run_flags: Dict[RunDir, Dict[str, bool]],
) -> Tuple[int, int, int, int]:
    # Bulk override ONLY for interior bulk.
    # Edge bulk pixels should still be visible as edges.
    if len(dirs) > 1:
        # Caller must decide whether this bulk pixel is edge-adjacent.
        return (255, 255, 255, 255)

    rd = next(iter(dirs))
    f = per_run_flags.get(rd, {})

    # Point (special scan-edge)
    if f.get("point"):
        if rd == RunDir.ISO_X:
            return (255, 0, 255, 255)   # magenta
        if rd == RunDir.ISO_Y:
            return (255, 255, 0, 255)   # yellow
        return (255, 0, 0, 255)         # red

    # Scan-edge (non-point)
    if f.get("edge_scan"):
        if rd == RunDir.ISO_X:
            return (0, 255, 255, 255)   # cyan
        if rd == RunDir.ISO_Y:
            return (0, 255, 0, 255)     # green
        return (255, 128, 0, 255)       # orange

    # Perpendicular silhouette edge
    if f.get("edge_perp"):
        if rd == RunDir.ISO_X:
            return (0, 0, 180, 255)     # deep blue
        if rd == RunDir.ISO_Y:
            return (0, 128, 128, 255)   # teal
        return (128, 64, 0, 255)        # brown

    # Interior
    return (64, 64, 64, 255)


# ============================================================
# Render orchestration
# ============================================================

from dataclasses import dataclass

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

    # ---------------- Geometry (expanded floor geometry block) ----------------

    # Floor pipes (Pillow stroke + intent emission)
    if job.surface == "floor":

        # --- Straight ---
        if job.shape == "straight":
            if job.variant == "EW":
                p1 = iso_project_floor(-half, 0)
                p2 = iso_project_floor(+half, 0)
                draw_floor_stroke_with_intent(
                    img, run_map, p1, p2,
                    thickness=thickness,
                    run_dir=RunDir.ISO_X,
                    color=base_color,
                )
            elif job.variant == "NS":
                p1 = iso_project_floor(0, -half)
                p2 = iso_project_floor(0, +half)
                draw_floor_stroke_with_intent(
                    img, run_map, p1, p2,
                    thickness=thickness,
                    run_dir=RunDir.ISO_Y,
                    color=base_color,
                )

        # --- Elbows ---
        elif job.shape == "elbow":
            # All elbows originate at center (0,0)
            if job.variant == "NE":
                # ISO_Y north + ISO_X east
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(0, -half),
                    thickness=thickness, run_dir=RunDir.ISO_Y, color=base_color
                )
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(+half, 0),
                    thickness=thickness, run_dir=RunDir.ISO_X, color=base_color
                )

            elif job.variant == "ES":
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(+half, 0),
                    thickness=thickness, run_dir=RunDir.ISO_X, color=base_color
                )
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(0, +half),
                    thickness=thickness, run_dir=RunDir.ISO_Y, color=base_color
                )

            elif job.variant == "SW":
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(0, +half),
                    thickness=thickness, run_dir=RunDir.ISO_Y, color=base_color
                )
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(-half, 0),
                    thickness=thickness, run_dir=RunDir.ISO_X, color=base_color
                )

            elif job.variant == "WN":
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(-half, 0),
                    thickness=thickness, run_dir=RunDir.ISO_X, color=base_color
                )
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(0, 0), iso_project_floor(0, -half),
                    thickness=thickness, run_dir=RunDir.ISO_Y, color=base_color
                )

        # --- Tee ---
        elif job.shape == "tee":
            # Center + three arms
            if job.variant == "NEW":
                arms = [
                    (RunDir.ISO_Y, (0, 0), (0, -half)),   # N
                    (RunDir.ISO_X, (0, 0), (+half, 0)),   # E
                    (RunDir.ISO_X, (0, 0), (-half, 0)),   # W
                ]
            elif job.variant == "NES":
                arms = [
                    (RunDir.ISO_Y, (0, 0), (0, -half)),   # N
                    (RunDir.ISO_X, (0, 0), (+half, 0)),   # E
                    (RunDir.ISO_Y, (0, 0), (0, +half)),   # S
                ]
            elif job.variant == "ESW":
                arms = [
                    (RunDir.ISO_X, (0, 0), (+half, 0)),   # E
                    (RunDir.ISO_Y, (0, 0), (0, +half)),   # S
                    (RunDir.ISO_X, (0, 0), (-half, 0)),   # W
                ]
            elif job.variant == "NSW":
                arms = [
                    (RunDir.ISO_Y, (0, 0), (0, -half)),   # N
                    (RunDir.ISO_Y, (0, 0), (0, +half)),   # S
                    (RunDir.ISO_X, (0, 0), (-half, 0)),   # W
                ]
            else:
                arms = []

            for rd, (x1, y1), (x2, y2) in arms:
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(x1, y1),
                    iso_project_floor(x2, y2),
                    thickness=thickness,
                    run_dir=rd,
                    color=base_color,
                )

        # --- Cross ---
        elif job.shape == "cross":
            arms = [
                (RunDir.ISO_Y, (0, 0), (0, -half)),   # N
                (RunDir.ISO_Y, (0, 0), (0, +half)),   # S
                (RunDir.ISO_X, (0, 0), (+half, 0)),   # E
                (RunDir.ISO_X, (0, 0), (-half, 0)),   # W
            ]
            for rd, (x1, y1), (x2, y2) in arms:
                draw_floor_stroke_with_intent(
                    img, run_map,
                    iso_project_floor(x1, y1),
                    iso_project_floor(x2, y2),
                    thickness=thickness,
                    run_dir=rd,
                    color=base_color,
                )

    # Wall straights (geometry-only, already positioned correctly in your pipeline)
    if job.surface in ("wall_n", "wall_w") and job.shape == "straight":
        # Vertical riser (ISO_Z)
        if job.variant == "NS":
            # North wall riser base is at north-face center on floor; west wall at west-face center on floor.
            if job.surface == "wall_n":
                base = iso_project_floor(0, -half)
            else:
                base = iso_project_floor(-half, 0)

            p1 = base
            p2 = (base[0], base[1] - WALL_HEIGHT_PX)
            draw_wall_multiline_with_intent(
                img, run_map, p1, p2,
                thickness=thickness,
                run_dir=RunDir.ISO_Z,
                color=base_color,
                offset_axis="x",
            )

        # Horizontal run elevated (ISO_X or ISO_Y)
        if job.variant == "EW":
            lift = WALL_CUBE_PX + (WALL_CUBE_PX // 2)  # center of second cube

            if job.surface == "wall_n":
                # Horizontal on north face uses ISO_X direction
                p1 = iso_project_floor(-half, -half)
                p2 = iso_project_floor(+half, -half)
                p1 = (p1[0], p1[1] - lift)
                p2 = (p2[0], p2[1] - lift)
                draw_wall_multiline_with_intent(
                    img, run_map, p1, p2,
                    thickness=thickness,
                    run_dir=RunDir.ISO_X,
                    color=base_color,
                    offset_axis="y",
                )
            else:
                # Horizontal on west face uses ISO_Y direction
                p1 = iso_project_floor(-half, -half)
                p2 = iso_project_floor(-half, +half)
                p1 = (p1[0], p1[1] - lift)
                p2 = (p2[0], p2[1] - lift)
                draw_wall_multiline_with_intent(
                    img, run_map, p1, p2,
                    thickness=thickness,
                    run_dir=RunDir.ISO_Y,
                    color=base_color,
                    offset_axis="y",
                )

    # ---------------- Classification ----------------
    per_run_flags = classify_per_run(img, run_map)

    # ---------------- Debug output ----------------
    if DEBUG_CLASSIFICATION:
        px = img.load()
        # Compute "effective bulk" pixels (handles 1-pixel rasterization gaps at intersections)
        effective_bulk = compute_effective_bulk(img, run_map)
        # Compute bulk-adjacent edge pixels (silhouette boundary around bulk mass)
        bulk_adjacent_edge = compute_bulk_adjacent_edge(img, run_map, effective_bulk)
        # Clear image and repaint with debug colors for all solid pixels in run_map
        for (x, y), dirs in run_map.items():
            if not dirs:
                continue

            # 1. True interior bulk
            if (x, y) in effective_bulk and (x, y) not in bulk_adjacent_edge:
                px[x, y] = (255, 255, 255, 255)  # BULK interior
            # 2. Bulk that is also an edge (touches transparency)
            elif (x, y) in effective_bulk and (x, y) in bulk_adjacent_edge:
                px[x, y] = (220, 220, 220, 255)  # BULK EDGE (lighter gray)
            # 3. Non-bulk bulk-adjacent edge
            elif (x, y) in bulk_adjacent_edge:
                px[x, y] = (200, 200, 200, 255)
            # 4. Normal edge/point classification
            else:
                px[x, y] = debug_color_for_pixel(dirs, per_run_flags.get((x, y), {}))

    return img
