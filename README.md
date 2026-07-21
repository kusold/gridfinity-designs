# gridfinity-designs

A collection of my parametric [Gridfinity](https://gridfinity.xyz/) storage bin
designs, written in [OpenSCAD](https://openscad.org/) and built on top of the
excellent [`gridfinity-rebuilt-openscad`](https://github.com/kennetek/gridfinity-rebuilt-openscad)
library by kennetek.

Each design lives in its own folder as `.scad` source. The Nix flake in this
repo wires up OpenSCAD and the upstream library so the `use <src/core/...>`
includes resolve with no manual setup.

## Designs

| Design | Variant | Bin (W × L × H) | Holds |
| --- | --- | --- | --- |
| `treedix-usb-tester/` | `upright` | 2 × 1 × 4 | Treedix USB Tester standing upright in a deep narrow pocket |
| `treedix-usb-tester/` | `flat` | 2 × 2 × 4 | Treedix USB Tester lying flat; 16mm pocket sized to the tester height so the stacking lip stays usable |

Open any `.scad` file to read its header comment for the exact footprint,
pocket dimensions, and the parameters you can tweak in the OpenSCAD Customizer.

## Development environment

This repo uses [Nix](https://nixos.org/) (flakes) + [direnv](https://direnv.net/)
to provide a reproducible OpenSCAD toolchain. The flake pins the OpenSCAD
**unstable** snapshot — required because the upstream library uses modern syntax
(`2021.01` stable can't parse it) and because it renders dramatically faster.

To enter the dev shell:

```sh
# If direnv is hooked into your shell:
direnv allow

# Or, without direnv:
nix develop
```

Either way, the shell exports `OPENSCADPATH` (pointing at
`gridfinity-rebuilt-openscad`) so the library's `include`/`use` paths resolve,
and puts `openscad` and `python3` on `PATH`.

## Rendering designs

`bin/render.py` re-renders `.scad` files into both `.stl` (for printing) and
`.png` (for previews). Run it inside the dev shell:

```sh
bin/render.py                       # render every design folder
bin/render.py treedix-usb-tester    # render one folder
bin/render.py --no-stl <folder>     # PNG previews only
bin/render.py --camera=0,0,12,55,0,30,220 <folder>   # custom PNG camera
bin/render.py --dry-run             # print commands without running them
```

## Folder convention

Each design is a top-level directory containing `.scad` sources and a rendered
`.png` preview (tracked in git). Generated `.stl` models are large and are
gitignored — regenerate them with `bin/render.py`.

```
treedix-usb-tester/
├── treedix-usb-tester-upright.scad   # source (tracked)
├── treedix-usb-tester-upright.png    # preview (tracked)
├── treedix-usb-tester-flat.scad
└── treedix-usb-tester-flat.png
```

To add a new design, drop a folder of `.scad` files at the repo root and
`bin/render.py` will pick it up automatically.
