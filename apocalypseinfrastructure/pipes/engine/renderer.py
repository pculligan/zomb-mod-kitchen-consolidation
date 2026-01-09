from __future__ import annotations

"""
renderer.py — pipe sprite sheet generator (NO SHADING)

Clean line-based renderer:
- Uses ImageDraw.line for all geometry
- No pixel-dot strokes
- No nested closures
- Geometry math preserved from last working state
"""

from dataclasses import dataclass
from PIL import Image, ImageDraw, ImageFont


# ============================================================
# Config
# ============================================================

CELL_W = 128
CELL_H = 256
SHEET_COLS = 8
SHEET_ROWS = 8

FLOOR_CX = 63
FLOOR_CY = CELL_H - 33

WALL_RISE = 96
CUBE_H = WALL_RISE // 3

SHAPE_ORDER = [
    ("straight", "EW"),
    ("straight", "NS"),
    ("end", "N"), ("end", "E"), ("end", "S"), ("end", "W"),
    ("elbow", "NE"), ("elbow", "ES"), ("elbow", "SW"), ("elbow", "WN"),
    ("tee", "NEW"), ("tee", "NES"), ("tee", "ESW"), ("tee", "NSW"),
    ("cross", "NESW"),
]

FACES = ["floor", "wall_n", "wall_w"]


# ============================================================
# Public API
# ============================================================

@dataclass(frozen=True)
class RenderJob:
    pipe_set: str
    surface: str
    shape: str
    variant: str


def render(job: RenderJob, geometry: dict, pipe_sets: dict) -> Image.Image:
    if job.shape != "sheet":
        raise NotImplementedError("Only sheet rendering is supported")
    return render_pipe_sheet(pipe_sets[job.pipe_set])


# ============================================================
# Geometry helpers (LINE-BASED)
# ============================================================

def draw_line(draw: ImageDraw.ImageDraw, p1, p2, color, thickness):
    draw.line([p1, p2], fill=(*color, 255), width=thickness)


# ============================================================
# Floor geometry
# ============================================================

def draw_floor_shape(draw, cx, cy, steps, thickness, color, shape, variant):
    def arm(dx, dy):
        x, y = cx, cy
        for _ in range(steps):
            nx, ny = x + dx, y + dy
            draw_line(draw, (x, y), (nx, ny), color, thickness)
            x, y = nx, ny

    if shape == "straight":
        if variant == "EW":
            arm(2, 1)
            arm(-2, -1)
        else:
            arm(-2, 1)
            arm(2, -1)

    elif shape == "end":
        dirs = {"N": (2, -1), "E": (2, 1), "S": (-2, 1), "W": (-2, -1)}
        arm(*dirs[variant])

    elif shape == "elbow":
        elbows = {
            "NE": [(2, -1), (2, 1)],
            "ES": [(2, 1), (-2, 1)],
            "SW": [(-2, 1), (-2, -1)],
            "WN": [(-2, -1), (2, -1)],
        }
        for dx, dy in elbows[variant]:
            arm(dx, dy)

    elif shape == "tee":
        tees = {
            "NEW": [(2, -1), (2, 1), (-2, -1)],
            "NES": [(2, 1), (-2, 1), (-2, -1)],
            "ESW": [(-2, 1), (-2, -1), (2, 1)],
            "NSW": [(2, -1), (-2, 1), (-2, -1)],
        }
        for dx, dy in tees[variant]:
            arm(dx, dy)

    elif shape == "cross":
        for dx, dy in [(-2, -1), (2, -1), (2, 1), (-2, 1)]:
            arm(dx, dy)


# ============================================================
# Wall geometry
# ============================================================

def draw_wall_shape(draw, cx, cy, thickness, color, shape, variant, wall):
    cube1_y = cy - 1 * CUBE_H
    cube2_y = cy - 2 * CUBE_H
    cube3_y = cy - 3 * CUBE_H

    face_cx = cx - CUBE_H if wall == "wall_w" else cx
    face_cy = cube2_y

    if shape == "straight":
        if variant == "EW":
            draw_line(draw, (face_cx - 20, face_cy - 10), (face_cx + 20, face_cy + 10), color, thickness)
        else:
            draw_line(draw, (face_cx, cube1_y + CUBE_H), (face_cx, cube3_y - CUBE_H), color, thickness)

    elif shape == "end":
        if variant == "N":
            draw_line(draw, (face_cx, face_cy), (face_cx, cube3_y - CUBE_H), color, thickness)
        elif variant == "S":
            draw_line(draw, (face_cx, face_cy), (face_cx, cube1_y + CUBE_H), color, thickness)
        elif variant == "E":
            draw_line(draw, (face_cx, face_cy), (face_cx + 20, face_cy + 10), color, thickness)
        elif variant == "W":
            draw_line(draw, (face_cx, face_cy), (face_cx - 20, face_cy - 10), color, thickness)

    elif shape == "elbow":
        draw_wall_shape(draw, cx, cy, thickness, color, "end", variant[0], wall)
        draw_wall_shape(draw, cx, cy, thickness, color, "end", variant[1], wall)

    elif shape == "tee":
        for d in variant:
            draw_wall_shape(draw, cx, cy, thickness, color, "end", d, wall)

    elif shape == "cross":
        for d in "NESW":
            draw_wall_shape(draw, cx, cy, thickness, color, "end", d, wall)


# ============================================================
# Sheet renderer
# ============================================================

def render_pipe_sheet(pipe_set):
    sheet = Image.new("RGBA", (CELL_W * SHEET_COLS, CELL_H * SHEET_ROWS), (0, 0, 0, 0))
    thickness = pipe_set["thickness"]
    color = tuple(pipe_set["colors"]["body"][:3])
    steps = 20
    font = ImageFont.load_default()

    for face_index, surface in enumerate(FACES):
        base_row = face_index * 2

        for shape_index, (shape, variant) in enumerate(SHAPE_ORDER):
            col = shape_index % SHEET_COLS
            row = base_row + (shape_index // SHEET_COLS)
            if row >= base_row + 2:
                continue

            tile = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
            draw = ImageDraw.Draw(tile)
            cx, cy = FLOOR_CX, FLOOR_CY

            if surface == "floor":
                draw_floor_shape(draw, cx, cy, steps, thickness, color, shape, variant)
            else:
                draw_wall_shape(draw, cx, cy, thickness, color, shape, variant, surface)

            draw.text((4, 4), f"{surface}:{shape}:{variant}", fill=(255, 0, 0, 255), font=font)
            sheet.paste(tile, (col * CELL_W, row * CELL_H))

    return sheet
