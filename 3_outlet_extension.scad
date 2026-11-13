/*
  Aquarium Refill Hose Holder - Part 3: Outlet Extension
  ------------------------------------------------------
  Slip-on sleeve for the end of the glass-mount tunnel (Part 1). It:
    - closes the open side of the tunnel near its end (side shell with
      15 mm overlap tabs on the upper and lower plate),
    - grips the tunnel end with a full collar on three sides,
    - extends the water channel flush with the inside of the tunnel, and
    - lowers the channel ceiling towards the outlet, so the water stream
      is directed downwards into the aquarium instead of splashing out.

  Self-contained: everything this part needs is in this file.
  Values marked [SHARED] describe the tunnel of the glass mount and must
  stay identical in 1_glass_mount.scad; assembly.scad checks this and stops
  with an error if they differ.

  The grey ghost of the tunnel end is shown in preview (F5) only and is not
  part of the exported STL (F6).
*/

/* [Sleeve] */
// Fit on the printed tunnel, per side. Positive = looser, negative = tighter.
// Tuned with test prints (+1.0 -> -1.0); adjust for your printer.
fit_clearance        = -1;
shell_thickness      = 3.5;  // Wall thickness of the sleeve
overlap              = 15;   // Side tabs and end collar overlap onto the tunnel
slope_overlap        = 25;   // How far the side shell reaches back onto the slope

/* [Outlet] */
extension_length     = 55;   // Total length past the tunnel end
straight_before_drop = 15;   // Straight run before the ceiling starts to drop
outlet_drop          = 25;   // How much the ceiling drops at the outlet

show_tunnel_preview  = true; // Ghost of the tunnel end in F5 preview

/* [Tunnel of the glass mount - SHARED, copy from 1_glass_mount.scad] */
glass_thickness       = 12;
clip_width            = 70;
clip_height           = 50;
wall_thickness        = 5;
tilt_angle            = 27;
plate_width           = 70;
plate_length          = 75;
slope_extension       = 80;
straight_length       = 40;
tunnel_height         = 50;
lower_plate_thickness = 5;
upper_plate_thickness = 5;

/* [Hidden] */
$fn = 64;

// ---------------------------------------------------------------------------
// Derived geometry (same formulas as in 1_glass_mount.scad)
// ---------------------------------------------------------------------------
clip_depth    = glass_thickness + 2 * wall_thickness;
lower_plate_z = clip_height + (clip_depth / 2) * sin(tilt_angle) + 1;
upper_plate_z = lower_plate_z + tunnel_height;
plate_x0      = clip_width - plate_width;

slope_end_local  = plate_length / 2 + slope_extension;
straight_start_y = clip_depth / 2 + slope_end_local * cos(tilt_angle);
slope_drop       = -slope_end_local * sin(tilt_angle);
tunnel_end_y     = straight_start_y + straight_length;

straight_bottom_z     = lower_plate_z + slope_drop;
straight_top_z        = upper_plate_z + slope_drop + upper_plate_thickness;
straight_outer_height = straight_top_z - straight_bottom_z;

channel_bottom_z = straight_bottom_z + lower_plate_thickness;
channel_height   = straight_top_z - upper_plate_thickness - channel_bottom_z;
channel_width    = plate_width - wall_thickness;

// ---------------------------------------------------------------------------
// Part
// ---------------------------------------------------------------------------
module outlet_extension() {
    c = fit_clearance;
    s = fit_clearance + shell_thickness;    // Outer offset of the sleeve
    socket_from = slope_end_local - slope_overlap - 5;

    translate([plate_x0, 0, 0])
    difference() {
        union() {
            // 1. Side shell on the open side of the tunnel with overlap tabs
            //    onto both plates, along the sloped and the straight section
            intersection() {
                tunnel_envelope(0, plate_width, socket_from, grow = s);

                // Limit to the open side wall + overlap (X <= overlap) and
                // cut square to the slope where the shell begins
                union() {
                    tilted_frame(-(s + 1), lower_plate_z)
                        translate([0, slope_end_local - slope_overlap, -50])
                            cube([overlap + s + 1, slope_overlap + 10, 200]);

                    translate([-(s + 1), straight_start_y - 5, -50])
                        cube([overlap + s + 1, straight_length + 5, 200]);
                }
            }

            // 2. Full collar around the tunnel end
            translate([-s, tunnel_end_y - overlap, straight_bottom_z - s])
                cube([plate_width + 2 * s, overlap, straight_outer_height + 2 * s]);

            // 3. Channel extension - outer faces flush with the tunnel
            translate([-s, tunnel_end_y - 0.5, straight_bottom_z])
                cube([plate_width + s, straight_before_drop + 0.5, straight_outer_height]);

            hull() {
                translate([-s, tunnel_end_y + straight_before_drop - 0.5, straight_bottom_z])
                    cube([plate_width + s, 0.5, straight_outer_height]);

                translate([-s, tunnel_end_y + extension_length - 0.5, straight_bottom_z])
                    cube([plate_width + s, 0.5, straight_outer_height - outlet_drop]);
            }
        }

        // Socket for the tunnel end
        tunnel_envelope(0, plate_width, socket_from, grow = c);

        // Water channel - same cross-section as the inside of the tunnel,
        // so the floor is perfectly flush (no step)
        translate([-c, tunnel_end_y - 1, channel_bottom_z])
            cube([channel_width + c, straight_before_drop + 1.5, channel_height]);

        hull() {
            translate([-c, tunnel_end_y + straight_before_drop - 0.5, channel_bottom_z])
                cube([channel_width + c, 0.5, channel_height]);

            translate([-c, tunnel_end_y + extension_length + 1, channel_bottom_z])
                cube([channel_width + c, 0.5, channel_height - outlet_drop]);
        }
    }
}

// ---------------------------------------------------------------------------
// Tunnel geometry (same as in 1_glass_mount.scad)
// ---------------------------------------------------------------------------
// Origin on the hinge line (Y = clip_depth / 2), local +Y down the slope.
module tilted_frame(x, z) {
    translate([x, clip_depth / 2, z])
        rotate([-tilt_angle, 0, 0])
            children();
}

// Solid outer envelope of the tunnel (both plates and the space between
// them) for X in [x, x + width], from the slope coordinate y_from to the end.
//   grow - uniform offset in X and Z (positive = larger)
module tunnel_envelope(x, width, y_from, grow = 0) {
    gx = x - grow;
    gw = width + 2 * grow;

    hull() {
        tilted_frame(gx, lower_plate_z)
            translate([0, y_from, -grow])
                cube([gw, slope_end_local - y_from, lower_plate_thickness + 2 * grow]);
        tilted_frame(gx, upper_plate_z)
            translate([0, y_from, -grow])
                cube([gw, slope_end_local - y_from, upper_plate_thickness + 2 * grow]);
    }

    if (straight_length > 0) {
        hull() {
            tilted_frame(gx, lower_plate_z)
                translate([0, slope_end_local - 0.5, -grow])
                    cube([gw, 0.5, lower_plate_thickness + 2 * grow]);
            tilted_frame(gx, upper_plate_z)
                translate([0, slope_end_local - 0.5, -grow])
                    cube([gw, 0.5, upper_plate_thickness + 2 * grow]);
            translate([gx, straight_start_y, straight_bottom_z - grow])
                cube([gw, 0.5, straight_outer_height + 2 * grow]);
        }

        translate([gx, straight_start_y, straight_bottom_z - grow])
            cube([gw, straight_length, straight_outer_height + 2 * grow]);
    }
}

// ---------------------------------------------------------------------------
// Interface for assembly.scad (do not edit)
// ---------------------------------------------------------------------------
function extension_tunnel_values() = [glass_thickness, clip_width, clip_height, wall_thickness,
    tilt_angle, plate_width, plate_length, slope_extension, straight_length,
    tunnel_height, lower_plate_thickness, upper_plate_thickness];

outlet_extension();

// Preview only (F5): outline of the tunnel end the sleeve slides onto
if (show_tunnel_preview)
    %tunnel_envelope(plate_x0, plate_width, slope_end_local - slope_overlap - 15);
