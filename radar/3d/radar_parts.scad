// James's radar: 3D-printable sensor head and servo stand.
//
// BEFORE PRINTING: measure YOUR sensor and servo (calipers, or a good ruler)
// and change the numbers under "MEASURE THESE". The numbers below are
// typical values for an HC-SR04 and a 9 g micro servo, not measured on
// James's parts.
//
// Make the STL files:
//   openscad -D 'part="head"'  -o radar_head.stl  radar_parts.scad
//   openscad -D 'part="stand"' -o radar_stand.stl radar_parts.scad
// Units: millimetres.

part = "assembly";   // "head", "stand", or "assembly" (preview only, don't print)

/* ---------- MEASURE THESE: HC-SR04 sensor ---------- */
pcb_w       = 45;    // width of the blue board
pcb_h       = 20;    // height of the blue board, without the pins
can_d       = 16;    // diameter of one silver "eye"
can_spacing = 26;    // centre of one eye to centre of the other
can_z       = 10;    // from the board edge WITHOUT pins to the centre of an eye
front_parts = 3.5;   // height of the silver crystal between the eyes

/* ---------- MEASURE THESE: servo ---------- */
servo_l     = 22.8;  // body length, without the tabs
servo_w     = 12.4;  // body width
tab_z       = 15.8;  // from the bottom of the servo to the underside of the tabs
tab_holes   = 27.8;  // centre to centre of the screw holes in the two tabs

/* ---------- print settings ---------- */
clr  = 0.4;          // clearance: prints come out slightly too fat
wall = 2.4;
$fn  = 64;

/* ---------- sensor head ----------
   Use position: foot on the servo horn, faceplate at the front (y = 0),
   eyes pointing to -y. The board sits behind the faceplate UPSIDE DOWN,
   pins at the top, so the wires go up and away from the servo.
   Print it standing on its foot, as it is drawn. */
face_t = 2.4;                       // faceplate thickness
foot_t = 4;                         // foot thickness (horn screws bite into this)
gap    = front_parts + 1;           // room for the crystal behind the faceplate
pcb_y  = face_t + gap;              // front of the board
pcb_t  = 1.6;
axis_y = pcb_y + pcb_t + 5;         // servo axis: just behind the board
head_W = pcb_w + 2*wall;
head_H = foot_t + pcb_h + 2;
head_D = axis_y + 7;

module head() {
  difference() {
    union() {
      // faceplate
      translate([-head_W/2, 0, 0]) cube([head_W, face_t, head_H]);
      // foot
      translate([-head_W/2, 0, 0]) cube([head_W, head_D, foot_t]);
      // 4 small standoffs at the corners of the board (keep the crystal free)
      for (sx = [-1, 1], z = [foot_t, foot_t + pcb_h - 2])
        translate([sx > 0 ? pcb_w/2 - 2 : -pcb_w/2, face_t - 0.01, z])
          cube([2, gap + 0.01, 2]);
      // 2 small ridges behind the bottom corners of the board
      for (sx = [-1, 1])
        translate([sx > 0 ? pcb_w/2 - 4 : -pcb_w/2, pcb_y + pcb_t + clr, foot_t - 0.01])
          cube([4, 2, 3]);
    }
    // the two eyes
    for (sx = [-1, 1])
      translate([sx*can_spacing/2, -1, foot_t + can_z])
        rotate([-90, 0, 0]) cylinder(d = can_d + 2*clr, h = face_t + 1.5);
    // access hole for the screw in the middle of the servo horn
    translate([0, axis_y, -1]) cylinder(d = 6, h = foot_t + 2);
  }
}

/* ---------- servo stand ----------
   The servo drops in from the top and hangs by its tabs. Screw the tabs
   down with the servo's own screws. The ends are open for the cable.
   Print it as drawn, flat side down. */
base_t = 3;
deck_t = 3;
in_l   = servo_l + 2*clr;
in_w   = servo_w + 2*clr;
deck_L = tab_holes + 8;
deck_W = in_w + 2*wall;
deck_top = base_t + tab_z + 0.5;    // servo hangs 0.5 mm above the base
base_L = deck_L + 16;
base_W = deck_W + 12;

module stand() {
  difference() {
    union() {
      translate([-base_L/2, -base_W/2, 0]) cube([base_L, base_W, base_t]);
      for (sy = [-1, 1])
        translate([-deck_L/2, sy > 0 ? in_w/2 : -in_w/2 - wall, 0])
          cube([deck_L, wall, deck_top]);
      translate([-deck_L/2, -deck_W/2, deck_top - deck_t]) cube([deck_L, deck_W, deck_t]);
    }
    // hole for the servo body
    translate([-in_l/2, -in_w/2, base_t]) cube([in_l, in_w, 100]);
    // pilot holes for the tab screws
    for (sx = [-1, 1]) translate([sx*tab_holes/2, 0, base_t]) cylinder(d = 1.8, h = 100);
    // holes to screw the stand onto the wooden base (or use double-sided tape)
    for (sx = [-1, 1]) translate([sx*(base_L/2 - 4), 0, -1]) cylinder(d = 3.4, h = base_t + 2);
  }
}

/* ---------- assembly preview: rough dummy servo and sensor (not printed) ---------- */
servo_top   = deck_top + 7;         // typical 9 g servo: ~7 mm of body above the tabs
shaft_x     = servo_l/2 - 5.9;      // typical: shaft ~6 mm from one end
horn_top    = servo_top + 4 + 1.5;  // gear tower + horn

module dummy_servo() {
  translate([-servo_l/2, -servo_w/2, base_t + 0.5]) cube([servo_l, servo_w, servo_top - base_t - 0.5]);
  translate([-16, -servo_w/2, deck_top]) cube([32, servo_w, 2.5]);                       // tabs
  translate([shaft_x, 0, servo_top]) cylinder(d = 7, h = horn_top - servo_top);          // tower + horn
}

module dummy_sensor() {   // in head coordinates: board upside down, eyes, pins
  translate([-pcb_w/2, pcb_y, foot_t]) cube([pcb_w, pcb_t, pcb_h]);
  for (sx = [-1, 1])
    translate([sx*can_spacing/2, pcb_y - 12, foot_t + can_z]) rotate([-90, 0, 0]) cylinder(d = can_d, h = 12);
  translate([-6, pcb_y - front_parts, foot_t + 1]) cube([12, front_parts, 5]);           // crystal, between the eyes
  for (i = [0:3])
    translate([-3.81 + i*2.54 - 0.3, pcb_y + 0.5, foot_t + pcb_h]) cube([0.6, 0.6, 6]);
}

// head sits on the horn, its axis on the servo shaft; angle 90 = straight ahead
module head_on_servo(angle = 90) {
  translate([shaft_x, 0, horn_top]) rotate([0, 0, angle - 90]) translate([0, -axis_y, 0]) children();
}

module assembly() {
  color("SteelBlue") stand();
  color("DimGray") dummy_servo();
  head_on_servo() { color("Orange") head(); color("RoyalBlue") dummy_sensor(); }
}

if (part == "head")          head();
if (part == "stand")         stand();
if (part == "assembly")      assembly();
