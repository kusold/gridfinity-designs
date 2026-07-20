#!/usr/bin/env python3
"""Re-render OpenSCAD designs (STL + PNG) for one folder or all of them.

Run inside the nix devShell, which puts `openscad` on PATH and exports
OPENSCADPATH (the gridfinity-rebuilt-openscad library location).

Examples:
  bin/render.py                      # render every design folder
  bin/render.py treedix-usb-tester   # render just that folder
  bin/render.py --no-stl treedix-usb-tester   # PNG only
  bin/render.py --camera=0,0,12,55,0,30,220   # custom PNG camera
  bin/render.py --dry-run            # print commands without running them
"""

import argparse
import os
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

# The repo root is the parent of this script's `bin/` directory.
REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_IMGSIZE = "1200,1000"


def die(msg, code=1):
    print(f"render.py: error: {msg}", file=sys.stderr)
    sys.exit(code)


def find_design_folders(root):
    """Immediate subdirectories of `root` that contain at least one .scad file."""
    return sorted(
        child for child in root.iterdir()
        if child.is_dir() and any(child.glob("*.scad"))
    )


def resolve_target(arg, root):
    """Turn the CLI argument into a list of folders to render."""
    if arg == "all":
        folders = find_design_folders(root)
        if not folders:
            die(f"no design folders (with .scad files) found under {root}")
        return folders
    candidate = Path(arg)
    if not candidate.is_absolute():
        candidate = root / arg
    candidate = candidate.resolve()
    if not candidate.is_dir():
        die(f"folder not found: {candidate}")
    if not any(candidate.glob("*.scad")):
        die(f"no .scad files in {candidate}")
    return [candidate]


def run_real(cmd, verbose):
    """Run openscad; stream output if verbose, otherwise surface it only on failure."""
    if verbose:
        return subprocess.run(cmd).returncode
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if proc.returncode != 0 and proc.stdout:
        sys.stderr.write(proc.stdout if proc.stdout.endswith("\n") else proc.stdout + "\n")
    return proc.returncode


def render_scad(scad, args):
    """Render one .scad file's requested outputs. Returns True if all succeeded."""
    jobs = []
    if not args.no_stl:
        out = scad.with_suffix(".stl")
        jobs.append(("STL", out, [args.openscad, str(scad), "--render", "-o", str(out)]))
    if not args.no_png:
        out = scad.with_suffix(".png")
        cmd = [args.openscad, str(scad), "--render", f"--imgsize={args.imgsize}", "-o", str(out)]
        if args.camera:
            cmd.append(f"--camera={args.camera}")
        jobs.append(("PNG", out, cmd))

    ok = True
    for label, out, cmd in jobs:
        if args.dry_run:
            print(f"  [{label}] {' '.join(shlex.quote(c) for c in cmd)}")
            continue
        print(f"  {label} {out.name} ... ", end="", flush=True)
        rc = run_real(cmd, args.verbose)
        print("ok" if rc == 0 else "FAILED")
        ok = ok and rc == 0
    return ok


def main():
    ap = argparse.ArgumentParser(
        description="Re-render OpenSCAD designs (STL + PNG).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  bin/render.py                      render every folder\n"
            "  bin/render.py treedix-usb-tester   render one folder\n"
            "  bin/render.py --camera=0,0,12,55,0,30,220   custom PNG camera\n"
            "  bin/render.py --dry-run            show commands only\n"
        ),
    )
    ap.add_argument("folder", nargs="?", default="all",
                    help="design folder to render, or 'all' (default: all)")
    ap.add_argument("--no-stl", action="store_true", help="skip STL output")
    ap.add_argument("--no-png", action="store_true", help="skip PNG output")
    ap.add_argument("--camera", metavar="CAM", default=None,
                    help="OpenSCAD --camera value for PNG, e.g. 0,0,12,55,0,30,220")
    ap.add_argument("--imgsize", metavar="W,H", default=DEFAULT_IMGSIZE,
                    help=f"PNG size in pixels (default: {DEFAULT_IMGSIZE})")
    ap.add_argument("--openscad", default=shutil.which("openscad") or "openscad",
                    help="openscad binary (default: first on PATH)")
    ap.add_argument("-v", "--verbose", action="store_true",
                    help="stream openscad output instead of suppressing it")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the commands that would run, without executing them")
    args = ap.parse_args()

    if shutil.which(args.openscad) is None:
        die(f"openscad not found ({args.openscad}). Run inside the nix devShell.")
    if not os.environ.get("OPENSCADPATH"):
        die("OPENSCADPATH is not set. Run inside the nix devShell (direnv allow / nix develop).")

    targets = resolve_target(args.folder, REPO_ROOT)

    files = 0
    failures = 0
    for folder in targets:
        scads = sorted(folder.glob("*.scad"))
        rel = folder.relative_to(REPO_ROOT)
        print(f"\n{rel}/  ({len(scads)} .scad)")
        for scad in scads:
            files += 1
            if not render_scad(scad, args):
                failures += 1

    succeeded = files - failures
    print(f"\nDone: {succeeded}/{files} file(s) rendered successfully.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
