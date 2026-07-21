// ===== INFORMATION ===== //
/*
  Treedix USB Tester — Flat Variant
  https://github.com/kennetek/gridfinity-rebuilt-openscad

  Holds the tester LYING FLAT in a shallow tray. See the companion
  "treedix-usb-tester-upright.scad" for the upright deep-pocket variant.

  A 2 x 2 x 4 gridfinity bin (stacking lip enabled) holding a Treedix USB
  Tester lying flat, kept stackable.

  The tester is 16mm tall. Rather than one 16mm-deep pocket, the cavity is
  stepped: the flat top rim (the ~6-7mm-wide shelf just inside the stacking
  lip) is lowered into a shallow tray, and a 7mm snug pocket at the bottom
  locates the tester. The pocket floor sits 16mm below the lip, so the 16mm
  tester's top is flush with the rim and clears the stacking lip — the bin
  stacks normally. The tester is reachable in the tray, so no finger-pulls.

  Footprint:
    gridx = 2 (wide)  -> ~83.5mm  (interior ~81.6mm)
    gridy = 2 (long)  -> ~83.5mm  (interior ~81.6mm)
    gridz = 4 tall    -> ~31.5mm bounding box (7mm base + stacking lip)

  Cavity (parameters below):
    77mm along the wide (x) axis
    67mm along the long (y) axis
    pocket_depth       = 7mm   snug pocket (locates the tester)
    pocket_floor_depth = 16mm  pocket floor below the lip (= tester height,
                               so the tester top sits flush with the rim)
    -> the flat top is lowered by (16 - 7) = 9mm to recess the pocket.

  NOTE on depth: with the stacking lip enabled, a 4-unit bin has 19.8mm of
  cuttable interior depth (the 7mm base plate and ~1.2mm stacking-lip support
  are not cuttable). The 16mm pocket floor therefore leaves a ~3.8mm floor, and
  both pocket_depth and pocket_floor_depth are clamped to the cuttable interior
  so the pocket floor never cuts into the base plate.

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
gridy = 2; // .1
// bin height in gridfinity units (7mm each, excludes stacking lip)
gridz = 4; // .1

/* [Height] */
// How "gridz" is interpreted. 0 = 7mm increments excluding the stacking lip.
gridz_define = 0; // [0:7mm increments - Excludes Stacking Lip, 1:Internal mm - Excludes Base & Stacking Lip, 2:External mm - Excludes Stacking Lip, 3:External mm]
// If the top stacking lip should exist (lets bins stack on this one).
include_lip = true;

/* [USB Tester Pocket] */
// Pocket size along the x (wide) axis. Bin interior here is ~81.6mm. Units: mm
pocket_x = 77; // .1
// Pocket size along the y (long) axis. Bin interior here is ~81.6mm. Units: mm
pocket_y = 67; // .1
// Depth of the snug pocket that locates the tester (its lower cradle). Units: mm
pocket_depth = 7; // .1
// Depth of the pocket FLOOR below the top rim / start of the stacking lip. Set
// to at least the tester's height (16mm) so the tester top sits at/below the
// lip and the bin stays stackable. Clamped to the cuttable interior. Units: mm
pocket_floor_depth = 16; // .1
// Vertical corner radius of the pocket (0 = sharp rectangular). Units: mm
pocket_corner_radius = 0; // .1
// Chamfer (beveled lead-in) around the pocket mouth for easier insertion.
// Applied as a 45 degree bevel of this size; 0 disables. Units: mm
pocket_chamfer = 1.0; // .1
// Semi-circular finger-pull notch(es) on the long sides, cut through the pocket
// wall so you can pry the tester up out of the snug pocket. Radius of the
// semi-circle; 0 disables. Units: mm
finger_pull_r = 6; // .1
// Cut the notch on both long sides (true) or only one side (false).
finger_pull_both_sides = true;

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
// depths so the model is always valid regardless of the gridz parameter.
_infill_mm = bin_get_infill_size_mm(bin1);
_pocket_depth = min(pocket_depth, _infill_mm.z);
// Floor depth (below the lip), clamped to the cuttable interior.
_floor_depth = min(pocket_floor_depth, _infill_mm.z);
// How far the flat top rim is lowered to recess the pocket down to the floor.
// Must be >= 0, i.e. the floor is at least as deep as the snug pocket.
_flat_top_drop = max(0, _floor_depth - _pocket_depth);

echo(str(
    "\n", "=== Treedix USB Tester bin (flat) ===",
    "\n", "  grid:                   ", gridx, " x ", gridy, " x ", gridz, " units",
    "\n", "  stacking lip:           ", include_lip ? "yes" : "no",
    "\n", "  bin bounding box (mm):  ", bin_get_bounding_box(bin1),
    "\n", "  interior/infill (mm):   ", _infill_mm,
    "\n", "  pocket x,y (mm):        ", [pocket_x, pocket_y],
    "\n", "  snug pocket depth (mm): ", _pocket_depth,
    "\n", "  flat top lowered (mm):  ", _flat_top_drop,
    "\n", "  pocket floor below lip: ", _floor_depth,
    "\n", "  top chamfer (mm):       ", pocket_chamfer,
    "\n"
));

bin_render(bin1) {
    // bin_render subtracts children from the bin. In the child frame, [0,0,0] is
    // the center of the bin at the TOP of the fill, with -z extending downward.
    //
    // The cavity is stepped (not a single deep pocket):
    //   1) Lower the flat top rim by _flat_top_drop, opening the top into a
    //      shallow tray so the tester's upper portion is reachable and its top
    //      can sit at the lip. Footprint is the full bin interior; subtraction is
    //      bounded by the bin fill, so it reliably removes the whole flat top
    //      layer without touching the walls or stacking lip.
    //   2) A snug pocket locates the tester; its floor sits _floor_depth below
    //      the lip (>= the tester height, so the tester top clears the lip).
    if (_flat_top_drop > 0)
        translate([0, 0, -_flat_top_drop / 2])
            cube([_infill_mm.x, _infill_mm.y, _flat_top_drop], center = true);

    translate([0, 0, -_flat_top_drop - _pocket_depth / 2])
        rounded_cube([pocket_x, pocket_y, _pocket_depth], pocket_corner_radius, center = true);

    // 45 degree chamfer (lead-in) around the pocket mouth, which now sits at the
    // lowered tray floor (z = -_flat_top_drop). Widens the mouth so the tester
    // funnels into the snug pocket without catching.
    _chamfer = min(pocket_chamfer, _pocket_depth);
    if (_chamfer > 0) {
        _widened = [pocket_x + 2 * _chamfer, pocket_y + 2 * _chamfer];
        translate([0, 0, -_flat_top_drop - _chamfer])
            linear_extrude(
                height = _chamfer,
                scale = [_widened.x / pocket_x, _widened.y / pocket_y]
            )
                rounded_square([pocket_x, pocket_y], pocket_corner_radius, center = true);
    }

    // Semi-circular finger-pull recess(es) on the long sides (y = +/- pocket_y/2):
    // a vertical cylinder centered on the pocket wall, open from the top (z = 0)
    // down to the pocket floor (z = -_floor_depth). The z = 0..-_flat_top_drop
    // part sits in the open tray (nothing to remove there); the rest cuts the
    // pocket wall so you can pry the tester up out of the snug pocket. A 45
    // degree frustum at the pocket mouth continues the chamfer around the notch.
    // Radius is clamped to the wall so the bin's outer wall stays intact.
    _wall_y = (_infill_mm.y - pocket_y) / 2;
    _fpr = min(finger_pull_r, max(0.1, _wall_y - 0.5));
    if (_fpr > 0) {
        for (sy = finger_pull_both_sides ? [-1, 1] : [1]) {
            // Straight notch, flush with the pocket floor (z = -_floor_depth).
            translate([0, sy * pocket_y / 2, -_floor_depth])
                cylinder(r = _fpr, h = _floor_depth, $fn = 48);
            // 45 degree chamfer around the notch at the pocket mouth (z =
            // -_flat_top_drop), widening from _fpr to _fpr + _chamfer.
            if (_chamfer > 0)
                translate([0, sy * pocket_y / 2, -_flat_top_drop - _chamfer])
                    cylinder(r1 = _fpr, r2 = _fpr + _chamfer, h = _chamfer, $fn = 48);
        }
    }
}
