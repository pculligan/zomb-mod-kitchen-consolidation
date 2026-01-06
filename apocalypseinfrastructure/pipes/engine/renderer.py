"""
Primitive drawing routines for pipes.

Phase 1 renderer:
- Supports ONLY floor / straight / EW
- No lighting, shadows, or walls yet
- Produces a visible centered pipe body

All other combinations raise NotImplementedError.
"""

from dataclasses import dataclass
from PIL import Image, ImageDraw


def apply_point_shading_right_to_left(
    img: Image.Image,
    base_color: tuple[int, int, int, int],
    *,
    alpha1: int = 80,
    alpha2: int = 35,
) -> None:
    """
    Point-based highlight language (matches manual Photoshop technique for NS floor).

    For each row (y), find the first pipe pixel when scanning from right-to-left.
    Highlight ONLY that pixel, then paint 2 outward alpha pixels to the right:
      (x+1, y) and (x+2, y)

    This intentionally affects only the "point" pixels, not the whole edge.
    """
    w, h = img.size
    px = img.load()

    def clamp255(v: int) -> int:
        return 0 if v < 0 else 255 if v > 255 else v

    br, bg, bb, ba = base_color

    # Tunables (only adjust these)
    point_mul = 1.18
    fall1_mul = 1.22
    fall2_mul = 1.28

    point_rgb = (
        clamp255(int(br * point_mul)),
        clamp255(int(bg * point_mul)),
        clamp255(int(bb * point_mul)),
    )
    f1_rgb = (
        clamp255(int(br * fall1_mul)),
        clamp255(int(bg * fall1_mul)),
        clamp255(int(bb * fall1_mul)),
    )
    f2_rgb = (
        clamp255(int(br * fall2_mul)),
        clamp255(int(bg * fall2_mul)),
        clamp255(int(bb * fall2_mul)),
    )

    # For each scanline, locate the "point" pixel
    for y in range(h):
        x_point = None
        for x in range(w):
            if px[x, y][3] > 0:
                x_point = x
                break

        if x_point is None:
            continue

        # Only treat it as a "point" if it has transparent space to its right (edge)
        if x_point - 1 >= 0 and px[x_point - 1, y][3] > 0:
            continue

        # Highlight the point pixel (blend to avoid washing out)
        r, g, b, a = px[x_point, y]
        px[x_point, y] = (
            clamp255(int(r * 0.55 + point_rgb[0] * 0.45)),
            clamp255(int(g * 0.55 + point_rgb[1] * 0.45)),
            clamp255(int(b * 0.55 + point_rgb[2] * 0.45)),
            a,
        )

        # Outward falloff pixels to the right (only if currently transparent)
        x1 = x_point - 1
        if 0 <= x1 < w and px[x1, y][3] == 0:
            px[x1, y] = (f1_rgb[0], f1_rgb[1], f1_rgb[2], alpha1)

        x2 = x_point - 2
        if 0 <= x2 < w and px[x2, y][3] == 0:
            px[x2, y] = (f2_rgb[0], f2_rgb[1], f2_rgb[2], alpha2)


@dataclass(frozen=True)
class RenderJob:
    pipe_set: str
    surface: str
    shape: str
    variant: str


TILE_W = 128
TILE_H = 256


def iso_project(x: float, y: float, cx: int, cy: int) -> tuple[int, int]:
    """
    Project logical (x, y) into screen space using 2:1 isometric projection,
    anchored at (cx, cy).
    """
    sx = cx + (x - y)
    sy = cy + (x + y) // 2
    return int(sx), int(sy)


def render(job: RenderJob, geometry: dict, pipe_sets: dict) -> Image.Image:
    """
    Render a single pipe sprite for the given job.
    """

    # Guard: only support first primitive
    if not (
        job.surface == "floor"
        and (
            (job.shape == "straight" and job.variant in ("EW", "NS"))
            or (job.shape == "elbow" and job.variant in ("NE", "ES", "SW", "WN"))
            or (job.shape == "tee" and job.variant in ("NEW", "NES", "ESW", "NSW"))
            or (job.shape == "cross" and job.variant == "NESW")
            or (job.shape == "end" and job.variant in ("N", "E", "S", "W"))
        )
    ):
        raise NotImplementedError(
            f"Renderer only supports floor straight, elbow, tee, cross, and end variants; got {job}"
        )

    pipe_set = pipe_sets[job.pipe_set]
    color = tuple(pipe_set["colors"]["body"])
    thickness = pipe_set["thickness"]

    # Create transparent canvas
    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Floor anchor (Project Zomboid convention)
    # Center is ~63px from left, 33px up from bottom
    cx = 63
    cy = TILE_H - 33

    # Logical pipe geometry (flat, floor)
    # Full cell-span for floor pipes
    length = 64
    half = length // 2

    segments = []

    if job.shape == "straight":
        if job.variant == "EW":
            segments = [(-half, 0, half, 0)]
        else:  # NS
            segments = [(0, -half, 0, half)]

    elif job.shape == "elbow":
        if job.variant == "NE":
            segments = [
                (0, 0, 0, -half),   # N
                (0, 0, half, 0),    # E
            ]
        elif job.variant == "ES":
            segments = [
                (0, 0, half, 0),    # E
                (0, 0, 0, half),    # S
            ]
        elif job.variant == "SW":
            segments = [
                (0, 0, 0, half),    # S
                (0, 0, -half, 0),   # W
            ]
        elif job.variant == "WN":
            segments = [
                (0, 0, -half, 0),   # W
                (0, 0, 0, -half),   # N
            ]

    elif job.shape == "tee":
        if job.variant == "NEW":
            segments = [
                (0, 0, 0, -half),   # N
                (0, 0, half, 0),    # E
                (0, 0, -half, 0),   # W
            ]
        elif job.variant == "NES":
            segments = [
                (0, 0, 0, -half),   # N
                (0, 0, half, 0),    # E
                (0, 0, 0, half),    # S
            ]
        elif job.variant == "ESW":
            segments = [
                (0, 0, half, 0),    # E
                (0, 0, 0, half),    # S
                (0, 0, -half, 0),   # W
            ]
        elif job.variant == "NSW":
            segments = [
                (0, 0, 0, -half),   # N
                (0, 0, 0, half),    # S
                (0, 0, -half, 0),   # W
            ]

    elif job.shape == "cross":
        segments = [
            (0, 0, 0, -half),   # N
            (0, 0, half, 0),    # E
            (0, 0, 0, half),    # S
            (0, 0, -half, 0),   # W
        ]

    elif job.shape == "end":
        if job.variant == "N":
            segments = [
                (0, 0, 0, -half),   # center → north
            ]
        elif job.variant == "E":
            segments = [
                (0, 0, half, 0),    # center → east
            ]
        elif job.variant == "S":
            segments = [
                (0, 0, 0, half),    # center → south
            ]
        elif job.variant == "W":
            segments = [
                (0, 0, -half, 0),   # center → west
            ]

    # Project and draw all segments (flat geometry)
    for x1, y1, x2, y2 in segments:
        p1 = iso_project(x1, y1, cx, cy)
        p2 = iso_project(x2, y2, cx, cy)

        # Base pipe body (flat geometry)
        draw.line(
            [p1, p2],
            fill=color,
            width=thickness,
        )

    # Post-raster shading (point-based for NS straight floor)
    if job.shape == "straight" and job.variant == "NS":
        apply_point_shading_right_to_left(img, color)

    return img
