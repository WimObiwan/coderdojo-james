# James: ideas for the next project

**Made:** 2026-11-22 · **For:** choosing what comes after the Arduino radar (`radar/README.md`)

The radar combined an Arduino, a sensor, a servo, a laptop program talking over USB, and a
3D-printed holder. Each idea below keeps most of that and adds **one or two real new
concepts**, so it's a step up without starting from zero.

These are coach ideas, mostly from **general knowledge**. Where an idea comes from a
tutorial or from the CoderDojo Drive, the source is given. Nothing has been built or
compiled yet.

**About parts.** "Has" means it's confirmed in `radar/README.md` (Parts): UNO R3, one small servo,
3× 100 µF, breadboard, wooden base, piezo, 16×2 LCD, LEDs, 220 Ω resistors, HC-SR04, Dupont
wires, and the Dojo's 3D printer. **"Check the box"** means I expect it in one of the two kits
but it isn't confirmed anywhere here. On 2026-11-22 I couldn't load the kit pages online:
the Keyestudio wiki refused the connection, and the Arduino store page didn't load.

## At a glance

Difficulty uses the radar as ★★. It's my estimate.

| # | Idea | Main new thing | Extra parts to buy | Laptop side | Print | Difficulty |
|---|---|---|---|---|---|---|
| 1 | Ball on a beam | Feedback control (PID) | None (a ping-pong ball) | Live graph + tuning sliders | Beam, pivot, mounts | ★★★ |
| 2 | 3D sonar scanner | Second axis, 3D graphics | 1 small servo | 3D point cloud you can rotate | Pan-tilt bracket | ★★★ |
| 3 | Plotclock (writes the time) | Inverse kinematics | 2 small servos | Sends the time; draw-to-plot | Arms and frame | ★★★★ |
| 4 | Speed camera for toy cars | Speed from a series of points, states | None (one HC-SR04) | Speed screen + leaderboard | Camera housing, start gate | ★★½ |
| 5 | Radar that locks on | State machine, algorithms | None | "LOCKED" overlay, target track | None | ★★½ |
| 6 | Sun tracker | Simple feedback | None for 1 axis | Sun position, light over time | Sensor head with shade | ★★ / ★★★ |
| 7 | Controller + own game | Game loop, two-way serial | None (maybe a joystick) | The game itself | Controller case | ★★★ |
| 8 | Radar on wheels | Motors, batteries, autonomy | Chassis, 2 motors, batteries | None while driving | Chassis or mounts | ★★★★ |

## 1. Ball on a beam ⭐ my first suggestion

**Worked out in detail in [`ball-on-beam/README.md`](ball-on-beam/README.md)**: mechanics with sizes, the
controller, the message format, the Processing panel, building steps, tuning, plan B.

A 3D-printed track on a pivot, tilted by the servo. The HC-SR04 sits at one end and
measures where a ping-pong ball is. The Arduino tilts the track to keep the ball at the
target spot. Push the ball and it comes back.

- **Step up:** feedback control. With only a P (proportional) term the ball overshoots and
  rocks back and forth. Adding D (damping) settles it, and I removes the last offset. James
  sees *why* each term exists by watching the ball.
- **Laptop:** Processing becomes a control panel. It shows a live graph of ball position
  against the target. Sliders send new P, I and D values *to* the Arduino, so serial now goes
  both ways.
- **Reuses:** servo, HC-SR04, capacitor, serial know-how, OpenSCAD and the printer.
- **Parts:** all in hand, plus a ping-pong ball.
- **Steps:** (1) roll the ball by hand and graph the position, (2) set the tilt with a
  Processing slider, (3) P only, (4) add D, (5) add I, (6) choose the target by clicking in
  Processing.
- **Risk:** the HC-SR04 sees a round ball less well than a wall. The Drive sheet in idea 4
  gives its range as 4 cm to 4 m, so the ball must stay further than ~5 cm away. **Do step 1
  first, before designing the beam.** The beam length depends on the printer bed (unknown);
  it may need to be printed in two pieces.

## 2. 3D sonar scanner (the radar in 3D)

Add a second servo that tilts the radar head up and down. The scanner sweeps row by row and
sends `pan,tilt,distance.`. Processing (P3D mode) draws every measurement as a dot in space.
Drag the mouse to turn the scan around.

- **Step up:** nested loops, a three-value message, and sin/cos in 3D (spherical to x, y,
  z). Also a pan-tilt bracket to design.
- **Reuses:** almost everything. The radar head goes on top of the new bracket.
- **Parts:** 1 extra small servo, the same kind as the kit's. Only one servo moves at a
  time during a scan, which is good for USB power. Keep the capacitor.
- **Honest limit:** the HC-SR04's sound beam is wide, so objects come out as blobs, not
  sharp shapes. A room scan also takes minutes. A narrow-beam distance sensor (to buy)
  would sharpen it. Which one is an open question.

## 3. Plotclock: a robot that writes the time

Two servos move a two-arm linkage that holds a whiteboard marker. A third servo lifts the
pen. It writes the current time on a small whiteboard and wipes it before writing the next
one.

- **Source:** an open-source project by Johannes Heberlein ("joo" on Thingiverse), 2014.
  It has printable or laser-cut parts and an Arduino sketch. Found via
  <https://hackaday.com/2014/02/13/a-clock-that-plots-time> and
  <https://www.elektormagazine.com/news/plotclock-writes-the-time-> (search results,
  2026-11-22; not read in full yet). If chosen, check its licence before copying any of
  it here; otherwise only link to it.
- **Step up:** the radar went from *angle to point* with sin/cos. This goes from *point to
  angles* (inverse kinematics: atan2 and the law of cosines). It also needs calibration, and
  each digit has to be drawn as strokes.
- **Laptop (our idea):** the UNO forgets the time when it's unplugged, so Processing sends
  the time at start-up. Extension: draw with the mouse in Processing and the plotclock copies
  it.
- **Parts:** 2 extra small servos, a whiteboard marker, a bit of whiteboard surface.
- **Risk:** small servos are sloppy, so the writing will be wobbly. That's part of the charm,
  but the mechanics need care. This is the hardest idea on the list.

## 4. Speed camera for toy cars

**Worked out in detail in [`speed-camera/README.md`](speed-camera/README.md), with one
HC-SR04:** it looks *along* the track at the oncoming car, and the speed is the slope of the
distance–time line. Plus the LCD, a servo start gate, and the Processing screen.

A car rolls down a ramp, and the Arduino measures its speed and shows it on the LCD. The
Drive sheet below does it with two sensors across the ramp. The detailed plan uses one.

- **Source:** CoderDojo Belgium, CDJ Oostende, *P2-project snelheid meten* (Drive:
  `cdj :: PUBLIC FOLDERS/cdj :: ARDUINO/NL/Materiaal CDJ Oostende/Pdf versie/`, read
  2026-11-22, CC BY-NC-SA). It uses a 1 m ramp, two HC-SR04s and an LCD1602 with an I2C
  adapter. It also has a good table of "abnormal" cases, such as sensor 2 firing first. Level
  ★★★ on their scale, age 11+.
- **Our step up:** a Processing "speed camera" screen with a leaderboard saved to a file.
  It also scales the speed to real life: a 1:64 toy car at 2 m/s is "really" 460 km/h.
  A 3D-printed camera housing, and a servo start gate for fair races.
- **Step up:** timing with `millis()`/`micros()`, state handling, and units.
- **Parts:** with the one-sensor design, nothing new. The sheet's two-sensor version would
  need a second HC-SR04. One HC-SR04 reading can take up to 30 ms (our `pulseIn` timeout),
  so a fast car can slip between readings of a sensor pointing *across* the track. That's
  why the plan points it *along* the track. LCD: the Starter Kit's 16×2 is probably the
  parallel type without I2C (check). It works, with more wires and the `LiquidCrystal`
  library.

## 5. Radar that locks on

Same build, new brain. The radar sweeps until something comes within range, then stops
sweeping. It follows the object with small scans left and right of it. If it loses the
object, it goes back to sweeping. The piezo or an LED signals "locked".

- **Step up:** a state machine (scan → lock → lost → scan) and designing an algorithm:
  how do you find the edges of an object, and its middle? The message format gets extended
  on both sides (`angle,distance,mode.`).
- **Laptop:** a lock-on box and the target's track drawn on the radar screen.
- **Parts:** nothing new. The cheapest option, and a good one while parts for another idea
  are on their way. Less new building, so less of a "new project" feel.

## 6. Sun tracker

Two light sensors side by side with a small wall between them, on the servo. The servo
turns towards the brighter side until both sensors read the same. A torch is the sun.

- **Step up:** feedback, in its simplest form. A gentle introduction to idea 1. With a
  second servo and four sensors it tracks in two directions (★★★).
- **Laptop:** where the "sun" is, plus a graph of the light over time. Leave it on a
  windowsill for a day.
- **Parts:** light-dependent resistors + 10 kΩ resistors (Starter Kit, check the box) or
  photocell modules (Keyestudio, check the box). For 2 axes: 1 extra servo.

## 7. Arduino controller + James's own game

James designs and prints a controller case, wires a joystick and buttons into it, and
writes a Processing game to play with it. The game also talks back: a beep from the piezo on
a hit, LEDs for lives left, the servo as a damage needle.

- **Game idea (ours):** a submarine sonar game that reuses the radar drawing. "Ping" to
  find hidden subs.
- **Step up:** a game loop, collisions, a two-way message protocol, and a case that's nice
  to hold.
- **Parts:** joystick module (Keyestudio, check the box) or two potentiometers (Starter
  Kit, check the box), plus pushbuttons. The most software and the least electronics on
  this list.

## 8. Radar on wheels

The radar head on a small robot car. It drives forward, and when something is close it
stops, looks left and right with the servo, and turns to the side with more room. A very
common Arduino robot.

- **Step up:** motors, a motor driver, batteries, and a robot that decides for itself
  without the USB cable.
- **Parts:** the Starter Kit probably has one DC motor and an H-bridge chip (check the box).
  Buy a small two-wheel chassis kit (2 gear motors, wheels, a caster) and a battery holder,
  or print the chassis.
- **Laptop:** none while driving: the UNO R3 has no wireless. A Bluetooth module (to buy)
  could send the radar picture back.
- **Risk:** power. Motors, the servo and the Arduino share the batteries, so the capacitor
  lesson comes back bigger. Also the most to buy.

## Looked at, but not a step up

From our own Dojo's list *Mogelijke projecten voor Arduino* (Dojo Drive, read 2026-11-22):
- **Railway crossing:** the HC-SR04 sees the train, red lights flash, the piezo sounds, and
  the servo lowers the barrier. It's a good project with exactly James's parts, but about the
  radar's level. It could be a quick win before a bigger one.
- **Parking sensor:** 6 LEDs light up as you get closer, and the beeping speeds up. Already
  close to the radar's "Make it his own" list.

## Choosing

My suggestion: **1, ball on a beam**. It uses only parts James has, the new idea (feedback)
is big and visible, and Processing gets a new job as a control panel. Alternatives:
- If the radar *screen* was the favourite part: **2, 3D scanner**.
- If building and printing was: **3, Plotclock**.
- If there are only a few sessions: **4, speed camera** or **5, lock-on**.

Worth asking James: what was the best part of the radar, what was hardest, and is the next
thing something that moves, measures, makes sound, or is played?

## Status

2026-11-22: list made. Nothing chosen, no code written, nothing compiled. Read for this
list: James's `radar/README.md`, `drive/README.md`, and from the Drive *Mogelijke projecten voor
Arduino.docx* and *P2-project snelheid meten.pdf*. The kit contents beyond what `radar/README.md`
confirms were **not** verified.

2026-11-22: idea 1 worked out in `ball-on-beam/README.md`, checked against two existing builds
(Arduino Project Hub, AntonAshraf on GitHub). Still a proposal: nothing built or compiled.

2026-11-22: James's folder now has one subfolder per project (Wim): the radar moved to
`radar/`, the ball-on-beam plan is `ball-on-beam/README.md`.

2026-11-22: idea 4 worked out in `speed-camera/README.md`, with one HC-SR04 instead of the
Drive sheet's two. Still a proposal: nothing built or compiled.

## Open questions

- **Which Keyestudio kit exactly?** `radar/README.md` says "37 in 1 sensor kit", part number
  KS0349. A web search on 2026-11-22 found a Keyestudio wiki page titled *"KS0349 Keyestudio
  48 in 1 Sensor Kit"* (the page itself wouldn't load). A photo of the module list in the box
  settles this and all the "check the box" items above.
- **Starter Kit contents** beyond those in `radar/README.md` (light sensors, potentiometers,
  pushbuttons, DC motor, H-bridge, LCD type): not re-checked.
- **Budget for extra parts** (one or two small servos), and who
  buys them?
- **The Dojo printer's bed size:** it decides the beam length for idea 1.
- **Which Projects Book projects has James already done** (if any)? That changes what's
  new.
