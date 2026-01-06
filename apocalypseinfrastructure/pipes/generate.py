"""
Authoritative generator entrypoint.
Produces all pipe sprites deterministically from YAML definitions.

This phase:
- Loads YAML configs
- Validates canonical state
- Enumerates all required variants
- Prepares render jobs

No drawing is performed yet.
"""

from pathlib import Path
import yaml

from engine.surfaces import SURFACES
from engine.renderer import RenderJob
from engine.exporter import export_sprite


BASE_DIR = Path(__file__).parent
CONFIG_DIR = BASE_DIR / "config"
OUT_DIR = BASE_DIR / "generated"


def load_yaml(path: Path):
    with open(path, "r") as f:
        return yaml.safe_load(f)


def validate_pipe_sets(pipe_sets, surfaces):
    for name, ps in pipe_sets.items():
        if "offsets" not in ps:
            raise ValueError(f"Pipe set '{name}' missing offsets")
        for surface in surfaces:
            if surface not in ps["offsets"]:
                raise ValueError(
                    f"Pipe set '{name}' missing offset for surface '{surface}'"
                )


def validate_geometry(geometry):
    if "pipes" not in geometry:
        raise ValueError("geometry.yaml missing 'pipes' section")

    for shape, data in geometry["pipes"].items():
        if "segments" not in data or not data["segments"]:
            raise ValueError(f"Shape '{shape}' has no segments defined")


def enumerate_render_jobs(pipe_sets, geometry):
    jobs = []

    for pipe_set_name in pipe_sets.keys():
        for surface in SURFACES:
            for shape, data in geometry["pipes"].items():
                for variant_key in data["segments"].keys():
                    jobs.append(
                        RenderJob(
                            pipe_set=pipe_set_name,
                            surface=surface,
                            shape=shape,
                            variant=variant_key,
                        )
                    )

    return jobs


def main():
    pipe_sets = load_yaml(CONFIG_DIR / "pipe_sets.yaml")
    lighting = load_yaml(CONFIG_DIR / "lighting.yaml")
    geometry = load_yaml(CONFIG_DIR / "geometry.yaml")

    validate_pipe_sets(pipe_sets, SURFACES)
    validate_geometry(geometry)

    jobs = enumerate_render_jobs(pipe_sets, geometry)

    print(f"Prepared {len(jobs)} render jobs")

    for job in jobs:
        export_sprite(job, geometry, pipe_sets, lighting, OUT_DIR)


if __name__ == "__main__":
    main()
