#!/usr/bin/env bash
# Siembra etiquetas, milestones e issues desde docs/08_ROADMAP.md.
# Uso: scripts/seed_github.sh [--dry-run] [--repo dueño/repo]
set -euo pipefail
cd "$(dirname "$0")/.."
command -v gh >/dev/null || { echo "Instala GitHub CLI: https://cli.github.com"; exit 1; }
python3 scripts/seed_github.py "$@"
