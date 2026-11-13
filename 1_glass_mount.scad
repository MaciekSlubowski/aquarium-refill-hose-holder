/*
  Aquarium Refill Hose Holder - Part 1: Glass Mount
  -------------------------------------------------
  Clips onto the top edge of the aquarium glass. Above the clip, two parallel
  plates form a sloped tunnel that holds the refill hose. The upper plate has
  a threaded hole with a reinforcing boss for the clamp screw (Part 2), which
  presses the hose against the lower plate.

  Self-contained: everything this part needs is in this file.
  Values marked [SHARED] must stay identical in the other part files:
    - tunnel values  -> 3_outlet_extension.scad
    - thread values  -> 2_clamp_screw.scad
  assembly.scad checks this and stops with an error if they differ.

  All dimensions in millimetres, angles in degrees.
  Coordinate system:  X - across the tunnel,  Y - away from the glass
  (direction of the water flow),  Z - up.

  Print: on its side, lying on the closed side wall - see README.md.
*/

/* [Glass clip] */
glass_thickness   = 12;   // [SHARED] Slot for the aquarium glass (glass + fit clearance)
clip_width        = 70;   // [SHARED] Width of the clip along the glass edge
clip_height       = 50;   // [SHARED] How far the clip reaches down over the glass
wall_thickness    = 5;    // [SHARED] Clip walls and the tunnel side wall

/* [Tunnel] */
tilt_angle            = 27;  // [SHARED] Downward slope of the tunnel
plate_width           = 70;  // [SHARED] Width of both plates (X)
plate_length          = 75;  // [SHARED] Base length of the sloped plates
slope_extension       = 80;  // [SHARED] Extra length added to the sloped section
straight_length       = 40;  // [SHARED] Horizontal section at the end (0 = none)
tunnel_height         = 50;  // [SHARED] Vertical spacing between the plates
lower_plate_thickness = 5;   // [SHARED]
upper_plate_thickness = 5;   // [SHARED]

/* [Clamp screw hole] */
screw_diameter  = 20;    // [SHARED] Nominal (major) screw diameter
thread_pitch    = 3.0;   // [SHARED] Must be identical for hole and screw
hole_clearance  = 1.0;   // Extra hole diameter for FDM tolerance (hole = 21 mm)
threaded_hole   = true;  // false = plain hole (e.g. for a nut)
boss_height     = 3;     // Reinforcing boss above the upper plate
boss_diameter   = 30;
screw_offset    = 0;     // Moves the hole along the slope (0 = above the clip)
entry_chamfer_d = 23;    // Top diameter of the 45-degree lead-in chamfer of the hole

/* [Hidden] */
$fn = 64;

// ---------------------------------------------------------------------------
// Derived geometry
// ---------------------------------------------------------------------------
clip_depth = glass_thickness + 2 * wall_thickness;

// Hinge heights of the plates. The +1 mm keeps the tilted lower plate clear
// of the clip top edge for any tilt angle.
lower_plate_z = clip_height + (clip_depth / 2) * sin(tilt_angle) + 1;
upper_plate_z = lower_plate_z + tunnel_height;

plate_x0 = clip_width - plate_width;              // Plates flush with the clip's +X edge

slope_end_local  = plate_length / 2 + slope_extension;   // Along the slope, from the hinge
straight_start_y = clip_depth / 2 + slope_end_local * cos(tilt_angle);
slope_drop       = -slope_end_local * sin(tilt_angle);

straight_bottom_z     = lower_plate_z + slope_drop;
straight_top_z        = upper_plate_z + slope_drop + upper_plate_thickness;
straight_outer_height = straight_top_z - straight_bottom_z;

// Screw: axis position, seat (top of the boss) in the tilted upper-plate
// frame and the clear distance from the underside of the upper plate to
// the top of the lower plate, measured along the screw axis.
screw_x      = plate_x0 + plate_width / 2;
screw_seat_z = upper_plate_thickness + boss_height;
clear_gap    = tunnel_height * cos(tilt_angle) - lower_plate_thickness;

echo(str("Glass mount: screw grip length (plate + boss) = ", screw_seat_z,
         " mm, clear gap below the upper plate = ", clear_gap, " mm"));

// ---------------------------------------------------------------------------
// Part
// ---------------------------------------------------------------------------
module glass_mount() {
    difference() {
        union() {
            // 1. Glass clip, blended into the underside of the lower plate
            hull() {
                cube([clip_width, clip_depth, clip_height]);

                intersection() {
                    translate([0, 0, clip_height])
                        cube([clip_width, clip_depth, 30]);

                    tilted_frame(plate_x0, lower_plate_z)
                        translate([0, -plate_length / 2, 0])
                            cube([plate_width, plate_length, lower_plate_thickness]);
                }
            }

            // 2. Tunnel: lower plate, upper plate and side wall
            tunnel_body();

            // 3. Reinforcing boss around the screw hole
            screw_frame()
                cylinder(d = boss_diameter, h = screw_seat_z);
        }

        // Slot for the aquarium glass
        translate([-1, wall_thickness, -1])
            cube([clip_width + 2, glass_thickness, clip_height + 1]);

        // Screw hole through the upper plate and the boss
        screw_frame()
            screw_hole();
    }
}

// Threaded (or plain) hole in the screw frame, with a lead-in chamfer on top.
// The thread is phase-locked to the seat plane (top of the boss): it starts
// a whole number of pitches below it. 2_clamp_screw.scad starts its thread at
// the knob face the same way, so in assembly.scad the two threads mesh.
module screw_hole() {
    d = screw_diameter + hole_clearance;

    if (threaded_hole) {
        turns_below = ceil((screw_seat_z + 2) / thread_pitch);
        translate([0, 0, screw_seat_z - turns_below * thread_pitch])
            helical_thread(d = d, h = (turns_below + 2) * thread_pitch, pitch = thread_pitch);
    } else {
        translate([0, 0, -2])
            cylinder(d = d, h = screw_seat_z + 4);
    }

    // 45-degree lead-in chamfer from the thread root to entry_chamfer_d:
    // removes the thin first crest and lets the screw find the thread
    d_minor = d - 2 * 0.55 * thread_pitch;
    h_cone  = (entry_chamfer_d - d_minor) / 2;
    translate([0, 0, screw_seat_z - h_cone])
        cylinder(d1 = d_minor, d2 = entry_chamfer_d, h = h_cone);
    translate([0, 0, screw_seat_z - 0.01])
        cylinder(d = entry_chamfer_d, h = 1);
}

// Places children on the screw axis: origin on the underside of the upper
// plate, +Z out of the plate (the seat is at Z = screw_seat_z).
module screw_frame() {
    tilted_frame(screw_x, upper_plate_z)
        translate([0, screw_offset, 0])
            children();
}

// ---------------------------------------------------------------------------
// Tunnel geometry
// ---------------------------------------------------------------------------
//        hinge line
//            |       sloped section      knee   straight section
//     upper  o------------------------------\________________
//     plate                                  \
//     lower  o------------------------------\ \______________
//     plate                                  \_______________

// Origin on the hinge line (Y = clip_depth / 2), local +Y down the slope.
module tilted_frame(x, z) {
    translate([x, clip_depth / 2, z])
        rotate([-tilt_angle, 0, 0])
            children();
}

// One plate: sloped section + knee + horizontal section
module tunnel_plate(z_base, thickness) {
    tilted_frame(plate_x0, z_base)
        translate([0, -plate_length / 2, 0])
            cube([plate_width, plate_length + slope_extension, thickness]);

    if (straight_length > 0) {
        hull() {
            tilted_frame(plate_x0, z_base)
                translate([0, slope_end_local - 0.5, 0])
                    cube([plate_width, 0.5, thickness]);

            translate([plate_x0, straight_start_y, z_base + slope_drop])
                cube([plate_width, 0.5, thickness]);
        }

        translate([plate_x0, straight_start_y, z_base + slope_drop])
            cube([plate_width, straight_length, thickness]);
    }
}

// Solid side wall (+X side) joining the two plates along the full length
module tunnel_side_wall() {
    x  = plate_x0 + plate_width - wall_thickness;
    y0 = -plate_length / 2;

    hull() {
        tilted_frame(x, lower_plate_z)
            translate([0, y0, 0])
                cube([wall_thickness, slope_end_local - y0, lower_plate_thickness]);
        tilted_frame(x, upper_plate_z)
            translate([0, y0, 0])
                cube([wall_thickness, slope_end_local - y0, upper_plate_thickness]);
    }

    if (straight_length > 0) {
        hull() {
            tilted_frame(x, lower_plate_z)
                translate([0, slope_end_local - 0.5, 0])
                    cube([wall_thickness, 0.5, lower_plate_thickness]);
            tilted_frame(x, upper_plate_z)
                translate([0, slope_end_local - 0.5, 0])
                    cube([wall_thickness, 0.5, upper_plate_thickness]);
            translate([x, straight_start_y, straight_bottom_z])
                cube([wall_thickness, 0.5, straight_outer_height]);
        }

        translate([x, straight_start_y, straight_bottom_z])
            cube([wall_thickness, straight_length, straight_outer_height]);
    }
}

module tunnel_body() {
    tunnel_plate(lower_plate_z, lower_plate_thickness);
    tunnel_plate(upper_plate_z, upper_plate_thickness);
    tunnel_side_wall();
}

// ---------------------------------------------------------------------------
// Helical thread (identical copy in 2_clamp_screw.scad)
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
function mount_tunnel_values() = [glass_thickness, clip_width, clip_height, wall_thickness,
    tilt_angle, plate_width, plate_length, slope_extension, straight_length,
    tunnel_height, lower_plate_thickness, upper_plate_thickness];
function mount_thread_values() = [screw_diameter, thread_pitch];
function mount_grip_length()   = screw_seat_z;
function mount_clear_gap()     = clear_gap;

// Places children on the screw seat (top of the boss), +Z pointing away
// from the tunnel - the clamp screw's knob face goes here.
module mount_screw_seat() {
    screw_frame()
        translate([0, 0, screw_seat_z])
            children();
}

glass_mount();
