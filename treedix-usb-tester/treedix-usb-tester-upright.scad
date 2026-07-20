// ===== INFORMATION ===== //
/*
  Treedix USB Tester — Upright Variant
  https://github.com/kennetek/gridfinity-rebuilt-openscad

  Holds the tester UPRIGHT in a deep narrow pocket. See the companion
  "treedix-usb-tester-flat.scad" for the tester lying flat in a shallow tray.

  A 2 x 1 x 4 gridfinity bin with a single centered rectangular pocket sized
  for a Treedix USB Tester.

  Footprint:
    gridx = 2 (wide)  -> ~83.5mm  (interior ~81.6mm)
    gridy = 1 (long)  -> ~41.5mm  (interior ~39.6mm)
    gridz = 4 tall    -> 28mm tall (7mm base; stacking lip disabled)

  Pocket (all parameters below):
    76mm along the wide (2-unit) axis
    15mm along the long (1-unit) axis
    25mm deep, clamped to the bin's available interior depth.

  NOTE on depth: with the stacking lip disabled, a 4-unit bin has 21mm of
  cuttable interior depth (the 7mm base plate is not cuttable). The requested
  pocket_depth is therefore clamped to that maximum so the pocket floor never
  cuts into the base plate. Raise `gridz` (5 = 28mm, 6 = 35mm of interior
  depth) for a deeper pocket.

  Run inside the nix devShell (OPENSCADPATH is set there), or open in the
  OpenSCAD GUI and use the Customizer to tweak parameters.
*/

include <src/core/standard.scad>
use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>
use <src/core/bin.scad>
use <src/core/cutouts.scad>
use <src/helpers/generic-helpers.scad>
use <src/helpers/shapes.scad>

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 4;
$fs = 0.25; // .01

/* [Bin Size] */
// number of bases along x-axis (width). 1 unit = 42mm
gridx = 2; // .1
// number of bases along y-axis (length)
gridy = 1; // .1
// bin height in gridfinity units (7mm each, excludes stacking lip)
gridz = 4; // .1

/* [Height] */
// How "gridz" is interpreted. 0 = 7mm increments excluding the stacking lip.
gridz_define = 0; // [0:7mm increments - Excludes Stacking Lip, 1:Internal mm - Excludes Base & Stacking Lip, 2:External mm - Excludes Stacking Lip, 3:External mm]
// If the top stacking lip should exist. Disabled so this bin does not stack.
include_lip = false;

/* [USB Tester Pocket] */
// Pocket size along the 2-unit (wide) axis. Bin interior here is ~81.6mm. Units: mm
pocket_x = 76; // .1
// Pocket size along the 1-unit (long) axis. Bin interior here is ~39.6mm. Units: mm
pocket_y = 15; // .1
// Pocket depth from the top rim. Clamped to the bin's available interior depth. Units: mm
pocket_depth = 25; // .1
// Vertical corner radius of the pocket (0 = sharp rectangular). Units: mm
pocket_corner_radius = 0; // .1
// Chamfer (beveled lead-in) around the top rim of the pocket for easier
// insertion. Applied as a 45 degree bevel of this size; 0 disables. Units: mm
pocket_chamfer = 1.5; // .1

/* [Base Hole Options] */
// only cut magnet/screw holes at the corners of the bin
only_corners = false;
// Use gridfinity refined hole style. Not compatible with magnet_holes!
refined_holes = false;
// Base will have holes for 6mm Diameter x 2mm high magnets.
magnet_holes = false;
// Base will have holes for M3 screws.
screw_holes = false;
// Magnet holes will have crush ribs to hold the magnet.
crush_ribs = true;
// Magnet/Screw holes will have a chamfer to ease insertion.
chamfer_holes = true;
// Magnet/Screw holes will be printed so supports are not needed.
printable_hole_top = true;

hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);

// ===== IMPLEMENTATION ===== //

bin1 = new_bin(
    grid_size = [gridx, gridy],
    height_mm = height(gridz, gridz_define, false),
    include_lip = include_lip,
    hole_options = hole_options,
    only_corners = only_corners,
);

// The pocket can never be deeper than the bin's cuttable interior (the base
// plate is rendered separately and is not subtracted). Clamp the requested
// depth so the model is always valid regardless of the gridz parameter.
_infill_mm = bin_get_infill_size_mm(bin1);
_pocket_depth = min(pocket_depth, _infill_mm.z);

echo(str(
    "\n", "=== Treedix USB Tester bin (upright) ===",
    "\n", "  grid:                   ", gridx, " x ", gridy, " x ", gridz, " units",
    "\n", "  bin bounding box (mm):  ", bin_get_bounding_box(bin1),
    "\n", "  interior/infill (mm):   ", _infill_mm,
    "\n", "  pocket x,y (mm):        ", [pocket_x, pocket_y],
    "\n", "  requested depth (mm):   ", pocket_depth,
    "\n", "  effective depth (mm):   ", _pocket_depth,
    "\n", "  top chamfer (mm):       ", pocket_chamfer,
    "\n"
));

bin_render(bin1) {
    // bin_render subtracts children from the bin. In the child frame,
    // [0,0,0] is the center of the bin at the TOP of the fill, with -z
    // extending downward into the bin. Center the pocket on x/y and drop it
    // down by the (clamped) depth.
    translate([0, 0, -_pocket_depth / 2])
        rounded_cube([pocket_x, pocket_y, _pocket_depth], pocket_corner_radius, center = true);

    // 45 degree chamfer (lead-in) around the top rim. Extrudes the pocket
    // profile from full size at the bottom of the chamfer up to a widened
    // opening at the rim (z = 0), so the tester slides in without catching.
    _chamfer = min(pocket_chamfer, _pocket_depth);
    if (_chamfer > 0) {
        _widened = [pocket_x + 2 * _chamfer, pocket_y + 2 * _chamfer];
        translate([0, 0, -_chamfer])
            linear_extrude(
                height = _chamfer,
                scale = [_widened.x / pocket_x, _widened.y / pocket_y]
            )
                rounded_square([pocket_x, pocket_y], pocket_corner_radius, center = true);
    }
}
