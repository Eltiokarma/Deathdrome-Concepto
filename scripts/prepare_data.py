"""Copias de ejecución; editar únicamente los JSON de /data."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent

def prepare():
    target = ROOT / "game" / "data"
    target.mkdir(parents=True, exist_ok=True)
    for name in ("balance.json", "runners.json"):
        shutil.copyfile(ROOT / "data" / name, target / name)
    print("Datos preparados en game/data (generados, no editar).")

if __name__ == "__main__":
    prepare()
