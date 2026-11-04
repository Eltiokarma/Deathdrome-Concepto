"""Lint de nuestro código; omite GUT y cualquier addon externo."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
scripts = sorted(str(p.relative_to(root)) for p in (root / "game").rglob("*.gd")
                 if not {"addons", ".godot"}.intersection(p.relative_to(root / "game").parts))
if scripts:
    subprocess.run(["gdlint", *scripts], cwd=root, check=True)
