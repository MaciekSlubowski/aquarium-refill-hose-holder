/*
  Aquarium Refill Hose Holder - assembly view
  -------------------------------------------
  Shows all three parts in their mounted positions (F5 preview) and checks
  that the [SHARED] values in the three part files still match. Export each
  part from its own file.
*/

use <1_glass_mount.scad>
use <2_clamp_screw.scad>
use <3_outlet_extension.scad>

explode = 0;    // Pulls the parts apart for an exploded view (mm), e.g. 40

// ---------------------------------------------------------------------------
// Consistency checks between the part files
// ---------------------------------------------------------------------------
assert(mount_tunnel_values() == extension_tunnel_values(),
    "Tunnel values differ between 1_glass_mount.scad and 3_outlet_extension.scad");
assert(mount_thread_values() == screw_thread_values(),
    "screw_diameter / thread_pitch differ between 1_glass_mount.scad and 2_clamp_screw.scad");
assert(screw_grip_length() == mount_grip_length(),
    str("grip_length in 2_clamp_screw.scad must be ", mount_grip_length(),
        " (upper_plate_thickness + boss_height of the glass mount)"));
assert(screw_clamp_reach() < mount_clear_gap(),
    str("clamp_reach in 2_clamp_screw.scad must be below ", mount_clear_gap(),
        " mm, or the tip hits the lower plate before the knob seats"));

// ---------------------------------------------------------------------------
// Parts
// ---------------------------------------------------------------------------
color("SteelBlue")
    glass_mount();

// Knob face on the seat; the thread phase matches the hole
color("Orange")
    mount_screw_seat()
        translate([0, 0, explode])
            render(convexity = 10)   // OpenCSG preview cannot show the thread otherwise
                clamp_screw_mounted();

color("MediumSeaGreen")
    translate([0, explode, 0])
        outlet_extension();
