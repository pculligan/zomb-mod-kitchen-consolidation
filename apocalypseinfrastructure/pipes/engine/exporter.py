"""
PNG export utilities and naming conventions.

Phase 1 exporter:
- Writes PNGs for supported primitives
- Logs skips for unsupported jobs
"""

from pathlib import Path

from engine.renderer import RenderJob, render

# --- Classification output root ---
CLASSIFICATION_OUT_DIR = Path("pipes/generated") / "classification"


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
    Export a sprite for the given RenderJob.

    In Phase 1, only supported primitives are rendered; all other jobs are skipped.
    """
    out_path = sprite_path(base_dir, job)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        img = render(job, geometry, pipe_sets)
    except NotImplementedError:
        print(f"· skip {job.pipe_set}/{job.surface}/{job.shape}/{job.variant}")
        return

    img.save(out_path)
    print(f"✓ wrote {out_path}")

    # --- Always-on classification output ---
    from engine.renderer import DEBUG_CLASSIFICATION

    if DEBUG_CLASSIFICATION:
        cls_path = CLASSIFICATION_OUT_DIR / job.surface
        cls_path.mkdir(parents=True, exist_ok=True)

        cls_file = cls_path / sprite_filename(job)
        img._classification.save(cls_file)

        readme = CLASSIFICATION_OUT_DIR / "README.txt"
        if not readme.exists():
            readme.write_text(
                "Classification debug output.\n"
                "Colors encode RunDir / edge / point / bulk taxonomy.\n"
                "These images are diagnostics, not game assets.\n"
            )
