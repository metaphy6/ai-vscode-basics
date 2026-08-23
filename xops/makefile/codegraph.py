"""xops/makefile/codegraph.py — `make codeg`.

Initializes or updates the local CodeGraph index using an installed runner or
the npm package through npx. stdlib-only and cross-platform.
"""

from __future__ import annotations

import subprocess
import sys

from _common import REPO_ROOT, err, have, info, ok, step, warn


def _runner() -> list[str] | None:
    if have("codegraph"):
        return ["codegraph"]
    if have("npx"):
        return ["npx", "-y", "@colbymchenry/codegraph"]
    return None


def update(_args: list[str]) -> None:
    index_path = REPO_ROOT / ".codegraph"
    action = "updating" if index_path.exists() else "initializing"
    step(f"🔍 CodeGraph {action}")

    command = _runner()
    if command is None:
        warn("Neither codegraph nor npx was found; index was not updated.")
        info("Install Node.js or CodeGraph, then run: make codeg")
        raise SystemExit(1)

    info(f"runner: {' '.join(command)}")
    result = subprocess.run(
        [*command, "init", "."],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )
    if result.stdout:
        print(result.stdout, end="", file=sys.stderr)
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr, end="", file=sys.stderr)
        err(f"CodeGraph update failed (exit {result.returncode}).")
        raise SystemExit(result.returncode)

    ok(f"CodeGraph updated: {index_path}")


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("usage: codegraph.py update", file=sys.stderr)
        raise SystemExit(0 if len(sys.argv) >= 2 else 64)
    if sys.argv[1] != "update":
        err(f"unknown codegraph subcommand: {sys.argv[1]!r}")
        raise SystemExit(64)
    update(sys.argv[2:])


if __name__ == "__main__":
    main()
