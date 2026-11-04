#!/usr/bin/env python3
"""Crea etiquetas, milestones e issues en GitHub a partir de docs/08_ROADMAP.md.

Requisitos: gh autenticado (`gh auth login`) y estar dentro del clon del repo
o pasar --repo dueño/repo.

Uso:
  python3 scripts/seed_github.py --dry-run          # muestra lo que haría
  python3 scripts/seed_github.py --repo Eltiokarma/purga

Es idempotente: no duplica etiquetas, milestones ni issues con el mismo título.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROADMAP = ROOT / "docs" / "08_ROADMAP.md"

LABELS = {
    "infra": "5319e7", "gameplay": "1d76db", "combat": "d93f0b", "ai": "0e8a16",
    "ui": "fbca04", "level": "c5def5", "art": "f9d0c4", "audio": "bfdadc",
    "network": "006b75", "balance": "b60205", "docs": "0075ca", "research": "d4c5f9",
    "good first issue": "7057ff", "design-decision": "000000",
}


def parse_roadmap(text: str):
    milestones = []
    current = None
    issue = None
    for line in text.splitlines():
        m = re.match(r"^## (M\d+) · (.+)$", line)
        if m:
            current = {"code": m.group(1), "title": f"{m.group(1)} · {m.group(2).strip()}", "issues": []}
            milestones.append(current)
            issue = None
            continue
        i = re.match(r"^### (PUR-\d+) · (.+)$", line)
        if i and current is not None:
            issue = {"id": i.group(1), "title": f"[{i.group(1)}] {i.group(2).strip()}", "labels": [], "body": []}
            current["issues"].append(issue)
            continue
        if issue is None:
            continue
        if line.strip() == "---":
            issue = None
            continue
        lab = re.match(r"^\*\*Etiquetas:\*\*\s*(.+?)\s*$", line)
        if lab:
            issue["labels"] = re.findall(r"`([^`]+)`", lab.group(1))
        issue["body"].append(line)
    for ms in milestones:
        for it in ms["issues"]:
            it["body"] = "\n".join(it["body"]).strip() + "\n\n_Generado desde docs/08_ROADMAP.md_"
    return milestones


def gh(args, repo, dry, capture=False):
    cmd = ["gh"] + args + (["--repo", repo] if repo and args[0] != "api" else [])
    if dry:
        print("DRY:", " ".join(a if " " not in a else repr(a) for a in cmd[:8]), "...")
        return ""
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0 and not capture:
        print("  ⚠", res.stderr.strip())
    return res.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", help="dueño/repo (por defecto el repo actual)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    milestones = parse_roadmap(ROADMAP.read_text(encoding="utf-8"))
    n_issues = sum(len(m["issues"]) for m in milestones)
    print(f"Roadmap: {len(milestones)} milestones, {n_issues} issues")
    if a.dry_run:
        for ms in milestones:
            print(f"\n{ms['title']}")
            for it in ms["issues"]:
                print(f"  {it['title']}  {it['labels']}")
        return

    repo = a.repo or gh(["repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"], None, False).strip()
    if not repo:
        sys.exit("No se pudo determinar el repo. Usa --repo dueño/repo.")

    print("Etiquetas…")
    for name, color in LABELS.items():
        gh(["label", "create", name, "--color", color, "--force"], repo, False)

    print("Milestones…")
    existing = json.loads(gh(["api", f"repos/{repo}/milestones?state=all&per_page=100"], repo, False, True) or "[]")
    have = {m["title"] for m in existing}
    for ms in milestones:
        if ms["title"] not in have:
            gh(["api", f"repos/{repo}/milestones", "-f", f"title={ms['title']}"], repo, False)

    print("Issues…")
    raw = gh(["issue", "list", "--state", "all", "--limit", "500", "--json", "title"], repo, False, True)
    titles = {x["title"] for x in json.loads(raw or "[]")}
    for ms in milestones:
        for it in ms["issues"]:
            if it["title"] in titles:
                print("  =", it["title"])
                continue
            args = ["issue", "create", "--title", it["title"], "--body", it["body"], "--milestone", ms["title"]]
            for lab in it["labels"]:
                args += ["--label", lab]
            gh(args, repo, False)
            print("  +", it["title"])
    print("Listo.")


if __name__ == "__main__":
    main()
