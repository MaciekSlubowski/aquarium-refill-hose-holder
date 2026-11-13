/*
  Aquarium Refill Hose Holder - Part 2: Clamp Screw
  -------------------------------------------------
  Thumb screw with a 4-spoke cross knob. It is screwed through the threaded
  hole in the upper plate of the glass mount (Part 1) and presses the hose
  against the lower plate, so it cannot slip out of the tunnel.

  Self-contained: everything this part needs is in this file.
  Values marked [SHARED] must stay identical in 1_glass_mount.scad;
  assembly.scad checks this and stops with an error if they differ.

  Print: knob down, no supports - see README.md.
*/

/* [Thread] */
screw_diameter = 20;    // [SHARED] Nominal (major) diameter
thread_pitch   = 3.0;   // [SHARED] Must be identical for hole and screw
tip_chamfer    = 2.5;   // Chamfer on the last millimetres of the tip

/* [Length] */
// Thread inside the upper plate + boss of the glass mount
// (upper_plate_thickness + boss_height there; 1_glass_mount.scad echoes it)
grip_length    = 8;
// Thread below the upper plate. Must be shorter than the clear gap echoed
// by 1_glass_mount.scad (39.5 mm by default), or the tip hits the lower
// plate before the knob seats.
clamp_reach    = 38;

/* [Cross knob] */
hub_diameter   = 26;    // Rests on the boss of the glass mount (30 mm)
knob_span      = 58;    // Tip to tip
spoke_width    = 15;
knob_height    = 12;

/* [Hidden] */
$fn = 64;

thread_length = grip_length + clamp_reach;   // 46 mm by default

// ---------------------------------------------------------------------------
// Part - knob lying flat on Z = 0, thread pointing up (print orientation)
// ---------------------------------------------------------------------------
module clamp_screw() {
    cross_knob();

    // Threaded shank, full diameter along the whole length, chamfered tip.
    // The thread starts exactly at the knob face; 1_glass_mount.scad locks
    // the hole thread to the seat plane the same way, so they mesh.
    translate([0, 0, knob_height])
        intersection() {
            helical_thread(d = screw_diameter, h = thread_length, pitch = thread_pitch);

            union() {
                cylinder(d = screw_diameter + 1, h = thread_length - tip_chamfer);

                translate([0, 0, thread_length - tip_chamfer])
                    cylinder(d1 = screw_diameter + 1, d2 = screw_diameter - 4, h = tip_chamfer);
            }
        }
}

module cross_knob() {
    spoke_offset = (knob_span - spoke_width) / 2;

    for (angle = [0, 90])
        rotate([0, 0, angle])
            hull() {
                translate([-spoke_offset, 0, 0]) cylinder(d = spoke_width, h = knob_height);
                translate([ spoke_offset, 0, 0]) cylinder(d = spoke_width, h = knob_height);
            }

    cylinder(d = hub_diameter, h = knob_height);
}

// ---------------------------------------------------------------------------
// Helical thread (identical copy in 1_glass_mount.scad)
// ---------------------------------------------------------------------------
// Trapezoidal single-start right-hand thread made by twisting a one-lobe
// "cam" cross-section: one full turn per pitch. Much faster to render than
// a polyhedron thread. d = major diameter, h = length.
module helical_thread(d, h, pitch) {
    r_max = d / 2;
    depth = 0.55 * pitch;
    r_min = r_max - depth;

    linear_extrude(height = h, twist = -360 * h / pitch,
                   slices = round(h / pitch * 24), convexity = 10)
        polygon([
            for (a = [0 : 5 : 355])
                let(
                    t = 1 - abs(a - 180) / 180,                      // 0 -> 1 -> 0
                    profile = (min(0.85, max(0.15, t)) - 0.15) / 0.7, // trapezoid
                    r = r_min + depth * profile
                )
                [r * cos(a), r * sin(a)]
        ]);
}

// ---------------------------------------------------------------------------
// Interface for assembly.scad (do not edit)
// ---------------------------------------------------------------------------
function screw_thread_values() = [screw_diameter, thread_pitch];
function screw_grip_length()   = grip_length;
function screw_clamp_reach()   = clamp_reach;

// Screw as mounted: knob face on Z = 0, thread pointing down (-Z)
module clamp_screw_mounted() {
    translate([0, 0, knob_height])
        rotate([180, 0, 0])
            clamp_screw();
}

clamp_screw();
