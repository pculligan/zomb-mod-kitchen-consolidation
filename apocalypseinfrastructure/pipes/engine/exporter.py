from pathlib import Path

from engine.renderer import RenderJob, render

# --- Classification output root ---
CLASSIFICATION_OUT_DIR = Path("pipes/generated") / "classification"

SHEET_OUT_FILE = Path("pipes/generated") / "pipe_sheet.png"


def sprite_filename(job: RenderJob) -> str:
    """
    Canonical filename for a sprite.
    Example: straight_ew.png
    """
    return f"{job.shape}_{job.variant.lower()}.png"


def sprite_path(base_dir: Path, job: RenderJob) -> Path:
    """
    Canonical output path for a sprite.
    """
    return base_dir / job.pipe_set / job.surface / sprite_filename(job)


def export_sprite(
    job: RenderJob,
    geometry: dict,
    pipe_sets: dict,
    lighting: dict,  # reserved for later phases
    base_dir: Path,
) -> None:
    """
    Export sprites.

    For this phase:
    - ALWAYS produce a single pipe sheet exactly once.
    - Ignore all other jobs.
    """

    # Guard: only render sheet once
    if getattr(export_sprite, "_sheet_done", False):
        return

    try:
        img = render(
            RenderJob(
                pipe_set=job.pipe_set,
                surface="floor",
                shape="sheet",
                variant="",
            ),
            geometry,
            pipe_sets,
        )
    except NotImplementedError:
        print("· sheet renderer not available")
        return

    out_file = Path("pipes/generated") / "pipe_sheet.png"
    out_file.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_file)

    print(f"✓ wrote sheet {out_file}")

    export_sprite._sheet_done = True
