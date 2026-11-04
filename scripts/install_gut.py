"""Instala GUT MIT fijado a un commit; requiere git y acceso a GitHub."""
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
TAG = "v9.6.1"
COMMIT = "c80954f47bed74a0a2c471d472c0389f98e0a8f6"

with tempfile.TemporaryDirectory() as directory:
    source = Path(directory) / "gut"
    subprocess.run(["git", "clone", "--depth", "1", "--branch", TAG,
                    "https://github.com/bitwes/Gut.git", str(source)], check=True)
    actual = subprocess.check_output(["git", "-C", str(source), "rev-parse", "HEAD"], text=True).strip()
    if actual != COMMIT:
        raise SystemExit("El tag GUT no corresponde al commit fijado; instalación cancelada.")
    target = ROOT / "game" / "addons" / "gut"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(source / "addons" / "gut", target)
print(f"GUT {TAG} instalado ({COMMIT}).")
