"""Verificación reproducible: datos, GUT y paquete aislado. Requiere Godot y GUT."""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def run(args, cwd=ROOT):
    result = subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=120)
    print(result.stdout, end="")
    if result.returncode or "SCRIPT ERROR:" in result.stdout or "\nERROR:" in result.stdout:
        raise SystemExit(result.returncode or 1)


run([sys.executable, "scripts/validate_data.py"])
run([sys.executable, "scripts/prepare_data.py"])
run(["godot", "--headless", "--editor", "--path", "game", "--quit"])
run(["godot", "--headless", "--path", "game", "--script", "addons/gut/gut_cmdln.gd",
     "-gdir=res://tests", "-gexit"])
with tempfile.TemporaryDirectory() as directory:
    package = str(Path(directory) / "purga.pck")
    run(["godot", "--headless", "--path", "game", "--export-pack", "Linux", package])
    run(["godot", "--headless", "--main-pack", package, "--quit-after", "5"], cwd=directory)
print("PASS: datos, GUT y arranque del paquete aislado.")
