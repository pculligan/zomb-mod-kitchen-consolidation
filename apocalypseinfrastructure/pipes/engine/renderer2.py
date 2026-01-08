from __future__ import annotations

"""
renderer2.py — simple iso-geometry pipe renderer

Goal:
- Produce usable pipe sprites for Project Zomboid
- Avoid pixel-topology inference
- Define pipes as geometric primitives in isometric space
- Shade using real normals and a fixed light vector
"""

from dataclasses import dataclass
from enum import Enum, auto
from typing import Tuple, Iterable
import math

from PIL import Image


# ============================================================
# Basic configuration
# ============================================================

TILE_W = 128
TILE_H = 256

# Floor anchor (matches Zomboid-ish placement)
FLOOR_CX = 63
FLOOR_CY = TILE_H - 33

PIPE_RADIUS = 2.0  # pixels in screen space
AMBIENT = 0.55
DIFFUSE = 0.45

# Light coming from upper-left, slightly above
LIGHT_DIR = (-0.6, -0.6, 0.4)

# Stylized band tuning (alpha overlays)
SHADOW_EDGE_A = 0.55
SHADOW_IN1_A  = 0.35
SHADOW_IN2_A  = 0.22
SHADOW_IN3_A  = 0.10

HILITE_EDGE_A = 0.45
HILITE_IN1_A  = 0.18

GLOW_OUT1_A   = 0.20
GLOW_OUT2_A   = 0.10

ENDCAP_T      = 0.15  # fraction of segment length treated as endcap


# ============================================================
# Iso math
# ============================================================

def normalize(v):
    l = math.sqrt(sum(c*c for c in v))
    return tuple(c / l for c in v)


LIGHT_DIR = normalize(LIGHT_DIR)


def iso_project(p: Tuple[float, float, float]) -> Tuple[int, int]:
    """
    Simple iso projection.
    p = (x, y, z) in iso space
    """
    x, y, z = p
    sx = FLOOR_CX + (x - y)
    sy = FLOOR_CY + (x + y) * 0.5 - z
    return int(sx), int(sy)


# ============================================================
# Geometry primitives
# ============================================================

class RunDir(Enum):
    ISO_X = auto()
    ISO_Y = auto()
    ISO_Z = auto()


def run_vector(rd: RunDir) -> Tuple[float, float, float]:
    if rd == RunDir.ISO_X:
        return (1, 0, 0)
    if rd == RunDir.ISO_Y:
        return (0, 1, 0)
    return (0, 0, 1)


@dataclass(frozen=True)
class PipeSegment:
    start: Tuple[float, float, float]
    end: Tuple[float, float, float]


# ============================================================
# Helper functions for stylized shading
# ============================================================

def clamp01(a: float) -> float:
    return 0.0 if a < 0.0 else 1.0 if a > 1.0 else a

def alpha_blend_rgb(dst_rgb: Tuple[int, int, int], src_rgb: Tuple[int, int, int], a: float) -> Tuple[int, int, int]:
    a = clamp01(a)
    return (
        int(dst_rgb[0] * (1 - a) + src_rgb[0] * a),
        int(dst_rgb[1] * (1 - a) + src_rgb[1] * a),
        int(dst_rgb[2] * (1 - a) + src_rgb[2] * a),
    )

def overlay_black(px, x, y, a: float, force_alpha: bool = False) -> None:
    r, g, b, alpha = px[x, y]
    r2, g2, b2 = alpha_blend_rgb((r, g, b), (0, 0, 0), a)
    if force_alpha:
        alpha = max(alpha, int(255 * a))
    px[x, y] = (r2, g2, b2, alpha)

def overlay_white(px, x, y, a: float) -> None:
    r, g, b, alpha = px[x, y]
    r2, g2, b2 = alpha_blend_rgb((r, g, b), (255, 255, 255), a)
    px[x, y] = (r2, g2, b2, alpha)


# ============================================================
# Rendering
# ============================================================

def draw_strip_at(px, cx, cy, tx, ty, radius):
    """
    Draw a constant-width strip perpendicular to (tx, ty).
    """
    # Perpendicular unit vector
    nx, ny = (-ty, tx)
    nl = math.sqrt(nx*nx + ny*ny) or 1.0
    nx, ny = (nx / nl), (ny / nl)

    for o in range(-int(radius), int(radius) + 1):
        px_x = int(cx + nx * o)
        px_y = int(cy + ny * o)
        if 0 <= px_x < TILE_W and 0 <= px_y < TILE_H:
            yield px_x, px_y, abs(o)


def render_pipe(
    segments: Iterable[PipeSegment],
    base_color: Tuple[int, int, int],
) -> Image.Image:
    """
    Render pipe segments into a sprite using simple normal-based shading.
    """
    img = Image.new("RGBA", (TILE_W, TILE_H), (0, 0, 0, 0))
    px = img.load()

    for seg in segments:
        sx, sy, sz = seg.start
        ex, ey, ez = seg.end

        # Sample along the segment in small steps
        steps = int(max(
            abs(ex - sx),
            abs(ey - sy),
            abs(ez - sz)
        ) * 8)

        for i in range(steps + 1):
            t = i / max(1, steps)
            x = sx + (ex - sx) * t
            y = sy + (ey - sy) * t
            z = sz + (ez - sz) * t

            cx, cy = iso_project((x, y, z))

            # Determine run direction in screen space at this sample (centerline tangent)
            if i < steps:
                nxp, nyp = iso_project((sx + (ex - sx) * ((i + 1) / max(1, steps)),
                                        sy + (ey - sy) * ((i + 1) / max(1, steps)),
                                        sz + (ez - sz) * ((i + 1) / max(1, steps))))
                tx, ty = (nxp - cx), (nyp - cy)
            else:
                nxp, nyp = iso_project((sx + (ex - sx) * ((i - 1) / max(1, steps)),
                                        sy + (ey - sy) * ((i - 1) / max(1, steps)),
                                        sz + (ez - sz) * ((i - 1) / max(1, steps))))
                tx, ty = (cx - nxp), (cy - nyp)

            tl = math.sqrt(tx*tx + ty*ty) or 1.0
            tx, ty = (tx / tl), (ty / tl)

            # Draw constant-width strip
            for px_x, px_y, oabs in draw_strip_at(px, cx, cy, tx, ty, PIPE_RADIUS):
                # Base fill
                px[px_x, px_y] = (*base_color, 255)

                # Distance inward from edge
                edge_dist = PIPE_RADIUS - oabs

                # Endcap check
                is_endcap = (t < ENDCAP_T) or (t > (1.0 - ENDCAP_T))

                # Perp normal (screen space)
                if is_endcap:
                    exs, eys = iso_project(seg.start if t < 0.5 else seg.end)
                    rx, ry = (px_x - exs), (px_y - eys)
                    rl = math.sqrt(rx*rx + ry*ry) or 1.0
                    nx2, ny2 = (rx / rl), (ry / rl)
                else:
                    nx2, ny2 = (-ty, tx)

                lx, ly = LIGHT_DIR[0], LIGHT_DIR[1]
                side = nx2 * lx + ny2 * ly
                light_side = side > 0.0

                # Stylized bands
                if light_side:
                    if edge_dist < 0.5:
                        overlay_white(px, px_x, px_y, HILITE_EDGE_A)
                    elif edge_dist < 1.5:
                        overlay_white(px, px_x, px_y, HILITE_IN1_A)
                else:
                    if edge_dist < 0.5:
                        overlay_black(px, px_x, px_y, SHADOW_EDGE_A)
                    elif edge_dist < 1.5:
                        overlay_black(px, px_x, px_y, SHADOW_IN1_A)
                    elif edge_dist < 2.5:
                        overlay_black(px, px_x, px_y, SHADOW_IN2_A)
                    elif edge_dist < 3.5:
                        overlay_black(px, px_x, px_y, SHADOW_IN3_A)

                # Contact glow just outside strip
                if oabs == int(PIPE_RADIUS):
                    # one step outward on both sides
                    gx = int(px_x + (-ty))
                    gy = int(px_y + tx)
                    if 0 <= gx < TILE_W and 0 <= gy < TILE_H and px[gx, gy][3] == 0:
                        overlay_black(px, gx, gy, GLOW_OUT1_A, force_alpha=True)

    return img


# ============================================================
# Convenience builders
# ============================================================

def floor_straight(rd: RunDir, length: float) -> Iterable[PipeSegment]:
    """
    Build a straight floor pipe centered at origin.
    """
    half = length * 0.5
    if rd == RunDir.ISO_X:
        return [PipeSegment((-half, 0, 0), (half, 0, 0))]
    if rd == RunDir.ISO_Y:
        return [PipeSegment((0, -half, 0), (0, half, 0))]
    return []


def floor_end(rd: RunDir, length: float) -> Iterable[PipeSegment]:
    if rd == RunDir.ISO_X:
        return [PipeSegment((0, 0, 0), (length, 0, 0))]
    if rd == RunDir.ISO_Y:
        return [PipeSegment((0, 0, 0), (0, length, 0))]
    return []


# ============================================================
# Example entry point (temporary)
# ============================================================

if __name__ == "__main__":
    # Quick sanity render
    img = render_pipe(
        floor_straight(RunDir.ISO_Y, 12),
        base_color=(230, 230, 230),
    )
    img.save("test_pipe_ns_long.png")