"""
Pipe sprite renderer.

Architecture:
- Rasterize flat isometric pipe geometry
- Classify pixels into edge types (bulk vs point, top vs bottom)
- Determine interior side per pixel (LEFT / RIGHT)
- Apply masks in order:
    1) Bulk bias (mass)
    2) Bulk edge treatments (continuous rim/underside)
    3) Point edge treatments (crisp accents)
    4) AA (exterior transparency)  [MUST BE LAST]

Key invariant (floor):
- All shading is scanline-local (same y)
- Directionality is derived from per-pixel shape side

Walls (current scope):
- Support ONLY north wall straights (geometry-only)
- Use explicit wall-local origins
- Validate projection & anchoring before adding wall shading
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Dict, Set, Tuple

from PIL import Image, ImageDraw


# ============================================================
# Shape side (scanline interior direction)
# ============================================================

class ShapeSide(Enum):
    LEFT = -1
    RIGHT = 1


# ============================================================
# Mask tuning (art knobs live here)
# ============================================================

FLOOR_MASKS = {
    # Strong, crisp highlight for point pixels (you already like this language)
    "highlight_point": {
        "ks": (0.70, 0.40, 0.20),   # POINT + 2 interior pixels
        "target_rgb": (255, 255, 255),
    },
    # Subtle continuous rim highlight for bulk edge pixels
    "highlight_bulk": {
        "ks": (0.28, 0.16),         # subtle
        "target_rgb": (255, 255, 255),
    },

    # Strong, crisp shadow for bottom-edge point pixels
    "shadow_point": {
        "ks": (0.85, 0.80, 0.70, 0.35, 0.05),  # POINT + 4 inward pixels
        "target_rgb": (0, 0, 0),
    },
    # Subtle continuous underside shadow for bulk bottom edge pixels
    "shadow_bulk": {
        "ks": (0.32, 0.20, 0.12),   # gentle, continuous form shadow
        "target_rgb": (0, 0, 0),
        "occlusion_k": 0.18,        # edge pixel
        "inner_occlusion_k": 0.10,  # first interior pixel
    },

    # AA (exterior) — lerp-to-black colors with alphas
    "aa_point": {
        "k": (0.30, 0.55),
        "alpha": (60, 25),
    },
    "aa_bulk": {
        "k": (0.22, 0.40),
        "alpha": (35, 15),
    },

    # Body mass (uniform, subtle)
    "bulk_bias": {
        "bias_k": 0.06,
        "target_rgb": (0, 0, 0),
    },
}


# ============================================================
# Helpers
# ============================================================

def _clamp255(v: int) -> int:
    return 0 if v < 0 else 255 if v > 255 else v


def _lerp_rgb(a: Tuple[int, int, int], b: Tuple[int, int, int], k: float) -> Tuple[int, int, int]:
    return (
        _clamp255(int(a[0] * (1 - k) + b[0] * k)),
        _clamp255(int(a[1] * (1 - k) + b[1] * k)),
        _clamp255(int(a[2] * (1 - k) + b[2] * k)),
    )


def _opaque(px, x: int, y: int) -> bool:
    return px[x, y][3] > 0


# ============================================================
# Edge detection + typing (bulk vs point)
# ============================================================

def classify_floor_edges(img: Image.Image) -> tuple[Set[Tuple[int, int]], Set[Tuple[int, int]], Set[Tuple[int, int]], Set[Tuple[int, int]]]:
    """
    Returns four sets:
      - top_points
      - top_bulk
      - bottom_points
      - bottom_bulk

    Definition:
      top_edge(x,y)    := opaque(x,y) and transparent(x,y-1)
      bottom_edge(x,y) := opaque(x,y) and transparent(x,y+1)

    Typing:
      edge pixel is BULK if BOTH neighbors on the scanline are also that same edge type.
      Otherwise it is POINT (end/corner of an edge run).

    This is local, deterministic, and works for straights, elbows, tees, crosses.
    """
    w, h = img.size
    px = img.load()

    top_edge: Set[Tuple[int, int]] = set()
    bottom_edge: Set[Tuple[int, int]] = set()

    for y in range(h):
        for x in range(w):
            if not _opaque(px, x, y):
                continue

            if y - 1 >= 0 and not _opaque(px, x, y - 1):
                top_edge.add((x, y))

            if y + 1 < h and not _opaque(px, x, y + 1):
                bottom_edge.add((x, y))

    def is_bulk(edge_set: Set[Tuple[int, int]], x: int, y: int) -> bool:
        return ((x - 1, y) in edge_set) and ((x + 1, y) in edge_set)

    top_points: Set[Tuple[int, int]] = set()
    top_bulk: Set[Tuple[int, int]] = set()
    bottom_points: Set[Tuple[int, int]] = set()
    bottom_bulk: Set[Tuple[int, int]] = set()

    for (x, y) in top_edge:
        if is_bulk(top_edge, x, y):
            top_bulk.add((x, y))
        else:
            top_points.add((x, y))

    for (x, y) in bottom_edge:
        if is_bulk(bottom_edge, x, y):
            bottom_bulk.add((x, y))
        else:
            bottom_points.add((x, y))

    return top_points, top_bulk, bottom_points, bottom_bulk


# ============================================================
# Shape side detection + junctions
# ============================================================

def shape_side_at(px, w: int, x: int, y: int) -> ShapeSide:
    """
    Which side of the scanline contains pipe interior for this pixel.
    Prefer LEFT if both sides exist (stable tie-break).
    """
    if x - 1 >= 0 and _opaque(px, x - 1, y):
        return ShapeSide.LEFT
    if x + 1 < w and _opaque(px, x + 1, y):
        return ShapeSide.RIGHT
    return ShapeSide.LEFT


def is_junction(px, w: int, x: int, y: int) -> bool:
    """
    Junction pixel has pipe on BOTH scanline sides.
    """
    return (
        x - 1 >= 0 and x + 1 < w and
        _opaque(px, x - 1, y) and
        _opaque(px, x + 1, y)
    )


# ============================================================
# Shared interior gradient helper
# ============================================================

def apply_interior_gradient(
    img: Image.Image,
    x: int,
    y: int,
    *,
    side: ShapeSide,
    ks: Tuple[float, ...],
    target_rgb: Tuple[int, int, int],
) -> None:
    """
    Apply scanline-local interior gradient starting at (x, y) and moving toward interior side.
    Only touches opaque pixels.
    """
    w, h = img.size
    px = img.load()
    dx = side.value

    for i, k in enumerate(ks):
        xx = x + dx * i
        if 0 <= xx < w and _opaque(px, xx, y):
            r, g, b, a = px[xx, y]
            px[xx, y] = (*_lerp_rgb((r, g, b), target_rgb, k), a)


# ============================================================
# MASK: Bulk bias (mass)
# ============================================================

def apply_bulk_bias(img: Image.Image) -> None:
    """
    Apply a uniform, subtle dark bias to ALL opaque pipe pixels.
    (Single pass, no repeated application.)
    """
    w, h = img.size
    px = img.load()

    bias_k = FLOOR_MASKS["bulk_bias"]["bias_k"]
    target_rgb = FLOOR_MASKS["bulk_bias"]["target_rgb"]

    for y in range(h):
        for x in range(w):
            if not _opaque(px, x, y):
                continue
            r, g, b, a = px[x, y]
            px[x, y] = (*_lerp_rgb((r, g, b), target_rgb, bias_k), a)


# ============================================================
# MASKS: Edge treatments (bulk + point)
# ============================================================

def apply_bulk_edge_masks(
    img: Image.Image,
    top_bulk: Set[Tuple[int, int]],
    bottom_bulk: Set[Tuple[int, int]],
) -> None:
    """
    Apply subtle continuous rim/underside treatments.
    Bulk edges are allowed at junctions.
    """
    px = img.load()
    w, _ = img.size

    # --- Top bulk highlight ---
    hk = FLOOR_MASKS["highlight_bulk"]["ks"]
    ht = FLOOR_MASKS["highlight_bulk"]["target_rgb"]

    for (x, y) in top_bulk:
        side = shape_side_at(px, w, x, y)
        dx = side.value

        # Edge pixel
        r, g, b, a = px[x, y]
        px[x, y] = (*_lerp_rgb((r, g, b), ht, hk[0]), a)

        # First interior-adjacent pixel
        x1 = x + dx
        if 0 <= x1 < w and _opaque(px, x1, y):
            r, g, b, a = px[x1, y]
            px[x1, y] = (*_lerp_rgb((r, g, b), ht, hk[1]), a)

        # Remaining interior gradient (starts after the first interior pixel)
        if len(hk) > 2:
            apply_interior_gradient(
                img,
                x + dx * 2,
                y,
                side=side,
                ks=hk[2:],
                target_rgb=ht,
            )

    # --- Bottom bulk occlusion band + shadow ---
    sk = FLOOR_MASKS["shadow_bulk"]["ks"]
    st = FLOOR_MASKS["shadow_bulk"]["target_rgb"]
    ok = FLOOR_MASKS["shadow_bulk"]["occlusion_k"]
    ik = FLOOR_MASKS["shadow_bulk"]["inner_occlusion_k"]

    for (x, y) in bottom_bulk:
        side = shape_side_at(px, w, x, y)
        dx = side.value

        # Edge occlusion pixel
        r, g, b, a = px[x, y]
        px[x, y] = (*_lerp_rgb((r, g, b), st, ok), a)

        # First interior-adjacent occlusion
        x1 = x + dx
        if 0 <= x1 < w and _opaque(px, x1, y):
            r, g, b, a = px[x1, y]
            px[x1, y] = (*_lerp_rgb((r, g, b), st, ik), a)

        # Remaining interior shadow gradient (starts after the first interior pixel)
        apply_interior_gradient(
            img,
            x + dx * 2,
            y,
            side=side,
            ks=sk,
            target_rgb=st,
        )


def apply_point_edge_masks(
    img: Image.Image,
    top_points: Set[Tuple[int, int]],
    bottom_points: Set[Tuple[int, int]],
) -> None:
    """
    Apply strong crisp accents for point pixels.
    Suppress points at junctions to avoid crunchy centers.
    """
    px = img.load()
    w, _ = img.size

    hk = FLOOR_MASKS["highlight_point"]["ks"]
    ht = FLOOR_MASKS["highlight_point"]["target_rgb"]
    for (x, y) in top_points:
        if is_junction(px, w, x, y):
            continue
        side = shape_side_at(px, w, x, y)
        apply_interior_gradient(img, x, y, side=side, ks=hk, target_rgb=ht)

    sk = FLOOR_MASKS["shadow_point"]["ks"]
    st = FLOOR_MASKS["shadow_point"]["target_rgb"]
    for (x, y) in bottom_points:
        if is_junction(px, w, x, y):
            continue
        side = shape_side_at(px, w, x, y)
        apply_interior_gradient(img, x, y, side=side, ks=sk, target_rgb=st)


# ============================================================
# MASK: AA (exterior) — MUST BE LAST
# ============================================================

def apply_aa_mask(
    img: Image.Image,
    edge_pixels: Set[Tuple[int, int]],
    base_rgb: Tuple[int, int, int],
    *,
    stronger: bool,
) -> None:
    """
    Exterior AA mask for a set of edge pixels.
    AA always fades away from pipe interior (out_dx = -side).
    """
    w, h = img.size
    px = img.load()

    key = "aa_point" if stronger else "aa_bulk"
    aa_k_1, aa_k_2 = FLOOR_MASKS[key]["k"]
    aa_a_1, aa_a_2 = FLOOR_MASKS[key]["alpha"]

    aa1_rgb = _lerp_rgb(base_rgb, (0, 0, 0), aa_k_1)
    aa2_rgb = _lerp_rgb(base_rgb, (0, 0, 0), aa_k_2)

    for (x, y) in edge_pixels:
        side = shape_side_at(px, w, x, y)
        out_dx = -side.value

        for step, mul_rgb, alpha in (
            (1, aa1_rgb, aa_a_1),
            (2, aa2_rgb, aa_a_2),
        ):
            xx = x + out_dx * step
            if 0 <= xx < w and px[xx, y][3] == 0:
                px[xx, y] = (mul_rgb[0], mul_rgb[1], mul_rgb[2], alpha)


@dataclass(frozen=True)
class RenderJob:
    pipe_set: str
    surface: str
    shape: str
    variant: str


TILE_W = 128
TILE_H = 256

# Floor anchor
FLOOR_CX = 63
FLOOR_CY = TILE_H - 33

# Wall geometry (north wall only)
WALL_CUBE_PX = TILE_W // 2          # 64px per cube
WALL_HEIGHT_CUBES = 3
WALL_HEIGHT_PX = WALL_CUBE_PX * WALL_HEIGHT_CUBES
# Top vertex of the floor diamond in screen space (2:1 iso)
WALL_N_BASE_CY_OFFSET = TILE_W // 4
WALL_PIPE_Z_PX = WALL_CUBE_PX * 2    # default horizontal pipe height


# --- Floor deterministic thick-line drawing helper ---

def draw_floor_line(
    draw: ImageDraw.ImageDraw,
    p1: Tuple[int, int],
    p2: Tuple[int, int],
    *,
    thickness: int,
    diagonal: bool,
    color: Tuple[int, int, int, int],
) -> None:
    """
    Draw a floor pipe segment as `thickness` parallel 1px lines.

    diagonal=True  -> EW floor pipe (offset in screen-vertical direction)
    diagonal=False -> NS floor pipe (offset in screen-horizontal direction)
    """
    half_w = thickness // 2
    if diagonal:
        # offset vertically
        for dy in range(-half_w, -half_w + thickness):
            draw.line(
                [(p1[0], p1[1] + dy), (p2[0], p2[1] + dy)],
                fill=color,
                width=1,
            )
    else:
        # offset horizontally
        for dx in range(-half_w, -half_w + thickness):
            draw.line(
                [(p1[0] + dx, p1[1]), (p2[0] + dx, p2[1])],
                fill=color,
                width=1,
            )

# --- Floor pipe end cap helper ---
def draw_floor_end_cap(
    draw: ImageDraw.ImageDraw,
    center: Tuple[int, int],
    *,
    thickness: int,
    diagonal: bool,
    color: Tuple[int, int, int, int],
) -> None:
    """
    Draw a square end cap for a floor pipe.

    For diagonal (EW) pipes:
      - End cap is screen-vertical (flat cut)
    For non-diagonal (NS) pipes:
      - End cap is screen-horizontal (flat cut)
    """
    cx, cy = center
    half_w = thickness // 2

    if diagonal:
        # Vertical cap
        for dx in range(-half_w, -half_w + thickness):
            for dy in range(-half_w + 1, half_w):
                draw.point((cx + dx, cy + dy), fill=color)
    else:
        # Horizontal cap: thin slice
        for dy in range(-half_w, -half_w + thickness):
            draw.point((cx, cy + dy), fill=color)


def render_floor(job: RenderJob, base_color: Tuple[int, int, int, int], thickness: int) -> Image.Image:
    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    half = TILE_W // 4
    segments: list[tuple[float, float, float, float, bool]] = []

    if job.shape == "straight":
        if job.variant == "EW":
            segments = [(-half, 0, half, 0, True)]
        else:
            segments = [(0, -half, 0, half, False)]

    elif job.shape == "elbow":
        if job.variant == "NE":
            segments = [(0, 0, 0, -half, False), (0, 0, half, 0, True)]
        elif job.variant == "ES":
            segments = [(0, 0, half, 0, True), (0, 0, 0, half, False)]
        elif job.variant == "SW":
            segments = [(0, 0, 0, half, False), (0, 0, -half, 0, True)]
        elif job.variant == "WN":
            segments = [(0, 0, -half, 0, True), (0, 0, 0, -half, False)]

    elif job.shape == "tee":
        if job.variant == "NEW":
            segments = [(0, 0, 0, -half, False), (0, 0, half, 0, True), (0, 0, -half, 0, True)]
        elif job.variant == "NES":
            segments = [(0, 0, 0, -half, False), (0, 0, half, 0, True), (0, 0, 0, half, False)]
        elif job.variant == "ESW":
            segments = [(0, 0, half, 0, True), (0, 0, 0, half, False), (0, 0, -half, 0, True)]
        elif job.variant == "NSW":
            segments = [(0, 0, 0, -half, False), (0, 0, 0, half, False), (0, 0, -half, 0, True)]

    elif job.shape == "cross":
        segments = [
            (0, 0, 0, -half, False),
            (0, 0, half, 0, True),
            (0, 0, 0, half, False),
            (0, 0, -half, 0, True),
        ]

    elif job.shape == "end":
        if job.variant == "N":
            segments = [(0, 0, 0, -half, False)]
        elif job.variant == "E":
            segments = [(0, 0, half, 0, True)]
        elif job.variant == "S":
            segments = [(0, 0, 0, half, False)]
        elif job.variant == "W":
            segments = [(0, 0, -half, 0, True)]

    for x1, y1, x2, y2, diagonal in segments:
        p1 = iso_project_floor(x1, y1, FLOOR_CX, FLOOR_CY)
        p2 = iso_project_floor(x2, y2, FLOOR_CX, FLOOR_CY)

        # Floor pipe body: use Pillow stroke for stable end caps
        draw.line([p1, p2], fill=base_color, width=thickness)

    # --- SHADING PIPELINE (unchanged) ---
    apply_bulk_bias(img)
    top_points, top_bulk, bottom_points, bottom_bulk = classify_floor_edges(img)
    apply_bulk_edge_masks(img, top_bulk, bottom_bulk)
    apply_point_edge_masks(img, top_points, bottom_points)
    all_bulk_edges = set().union(top_bulk, bottom_bulk)
    all_point_edges = set().union(top_points, bottom_points)
    apply_aa_mask(img, all_bulk_edges, base_color[:3], stronger=False)
    apply_aa_mask(img, all_point_edges, base_color[:3], stronger=True)

    return img

def north_wall_origin(cx: int, cy_floor: int) -> Tuple[int, int]:
    """
    North wall origin at the floor–wall seam.
    The seam is the top vertex of the floor diamond.
    """
    seam_offset = TILE_W // 4
    return cx, cy_floor - seam_offset



def project_wall_n_horizontal(local_x: float, z_px: float, ox: int, oy: int) -> Tuple[int, int]:
    """
    Project a horizontal pipe on the north wall.
    This follows the diagonal face of the wall.
    """
    sx = ox + local_x
    sy = oy + (local_x // 2) - z_px
    return int(sx), int(sy)


def project_wall_n_vertical(z_px: float, ox: int, oy: int) -> Tuple[int, int]:
    """
    Project a vertical pipe on the north wall.
    Vertical pipes rise straight up from the wall–floor seam.
    """
    sx = ox
    sy = oy - z_px
    return int(sx), int(sy)


def render_wall_n_straight(job: RenderJob, base_color: Tuple[int, int, int, int], thickness: int) -> Image.Image:
    """
    North wall straight pipes (geometry-only, centered via wall-local origin).

    Variants:
    - EW: horizontal pipe along north wall face (diagonal like floor EW)
    - NS: vertical pipe rising up the north wall
    """
    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    ox, oy = north_wall_origin(FLOOR_CX, FLOOR_CY)
    half = TILE_W // 4

    if job.variant == "EW":
        # North-wall horizontal pipe:
        # floor-projected, diagonal, raised to center of cube index 1

        half = TILE_W // 4          # 32px
        half_w = thickness // 2

        # Lift to center of second cube (cube index 1)
        z_lift_px = WALL_CUBE_PX + (WALL_CUBE_PX // 2)   # 96px

        # World-space base at center of north face on floor plane
        x1, y1 = -half, -half
        x2, y2 = +half, -half

        for dy in range(-half_w, -half_w + thickness):
            p1 = iso_project_floor(x1, y1, FLOOR_CX, FLOOR_CY)
            p2 = iso_project_floor(x2, y2, FLOOR_CX, FLOOR_CY)

            # apply thickness offset AND vertical lift
            p1 = (p1[0], p1[1] + dy - z_lift_px)
            p2 = (p2[0], p2[1] + dy - z_lift_px)

            draw.line([p1, p2], fill=base_color, width=1)

    elif job.variant == "NS":
        # North-wall vertical pipe is a FLOOR-RESTING object
        # Positioned at the center of the north face on the floor plane

        half = TILE_W // 4          # 32 for 128px tiles
        half_w = thickness // 2

        # Base position on the floor: (x=0, y=-half)
        base_x, base_y = iso_project_floor(0, -half, FLOOR_CX, FLOOR_CY)

        # Vertical extent (how tall the pipe rises visually)
        pipe_height_px = WALL_HEIGHT_PX

        for dx in range(-half_w, -half_w + thickness):
            p1 = (base_x + dx, base_y)
            p2 = (base_x + dx, base_y - pipe_height_px)
            draw.line([p1, p2], fill=base_color, width=1)

    else:
        raise NotImplementedError(job.variant)

    return img

def iso_project_floor(x: float, y: float, cx: int, cy: int) -> Tuple[int, int]:
    """
    Project floor-local coordinates (x, y) into screen space
    using standard 2:1 isometric projection.
    """
    sx = cx + (x - y)
    sy = cy + (x + y) // 2
    return int(sx), int(sy)

def render(job: RenderJob, geometry: dict, pipe_sets: dict) -> Image.Image:
    pipe_set = pipe_sets[job.pipe_set]
    base_color = tuple(pipe_set["colors"]["body"])
    thickness = pipe_set["thickness"]

    if job.surface == "floor":
        return render_floor(job, base_color, thickness)

    if job.surface == "wall_n":
        if job.shape == "straight" and job.variant in ("EW", "NS"):
            return render_wall_n_straight(job, base_color, thickness)
        raise NotImplementedError("wall_n currently supports only straight(EW,NS)")

    raise NotImplementedError(f"Unsupported surface: {job.surface}")
