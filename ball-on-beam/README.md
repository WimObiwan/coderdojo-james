# James: ball on a beam (detailed plan)

**Status:** proposal (idea 1 of `../next-project-ideas.md`), not chosen yet · **Written:**
2026-11-22

A track on a pivot, tilted by the servo. The HC-SR04 sits at one end and measures where a
ping-pong ball is. The Arduino keeps tilting the track so the ball stays at the target spot.
Give it a push and it comes back. On the laptop, Processing shows the ball live and has
sliders to tune the controller while it runs.

This plan is **our own design**, not a tutorial. It is based on general knowledge, with
numbers checked against two existing builds (see Sources). Nothing has been built or
compiled.

```
 side view

        HC-SR04                    target            end stop
          ┌┴┐  )))      ●            ┆                  │
   ═══════╧═╧════════════════════════════════════════════╧═══   ← track (V-groove)
                                 ▲            │
                         pivot   │            │ pushrod (paperclip)
                         (axle)  │          ┌─┴─┐
                                 │          │ ◐ │  ← servo, horn turns
                                 │          └───┘
   ══════════════════════════════╧══════════════════════════   ← base board
```

## Why this one

| | Radar | Ball on a beam |
|---|---|---|
| Sensor | HC-SR04 looks around | the same HC-SR04 looks along the track |
| Servo | turns the sensor; the Arduino decides where | tilts the track; **where depends on what it measures** |
| Laptop | listens and draws | draws, **and sends settings back** |
| Maths | sin/cos: angle + distance → point | speed = change in position per unit of time; P, I and D |
| Big idea | two programs agree on a message | **feedback**: measure, correct, measure again |

Reused: the wiring (same pins), the distance code, the capacitor, the Processing serial code
with `PORT_NUMBER`, OpenSCAD and the printer. Feedback is behind thermostats, cruise
control, drones and self-balancing scooters, so it's a concept worth knowing.

## How it works

### The ball

Tilt the track a little and the ball starts rolling, faster and faster, towards the low
end. My calculation (ignoring friction): a ping-pong ball in a 90° V-groove accelerates at
about 0.43 × g × sin(tilt). At a 3° tilt it rolls 30 cm in about 1.7 s; at 10°, in about
0.9 s. So things happen in about a second. The controller has to react several times per
second, and only small tilts are needed.

The ball is slower in a V-groove than on a flat surface. It touches the V at two points,
so it has to spin faster for the same speed. Slower makes it easier to control.

### The controller: P, I and D in James's words

Every 50 ms the Arduino asks three questions and adds up the answers into one tilt:

- **P (where is the ball?)** The further the ball is from the target, the more it tilts
  towards the target. P alone overshoots: when the ball reaches the target it's still
  rolling, so it goes past, then comes back, and keeps rocking forever, like a marble in a
  bowl.
- **D (how fast is it rolling?)** If the ball is already rolling towards the target, tilt
  less, or even against it. This is the brake, like the shock absorbers on a car. With P + D
  the ball settles.
- **I (how long has it been off?)** If the ball sits just next to the target for a long
  time, slowly add more tilt. This fixes a "level" that isn't quite level, or a track that
  isn't quite straight. It's the patient one. Too much I and it starts to rock again.

The heart of the sketch is about this big. **This is a sketch of the idea, not compiled
code.**

```cpp
void loop() {
  readCommands();                          // new P, I, D or target from the laptop?
  if (millis() - lastTime < PERIOD_MS) return;
  lastTime += PERIOD_MS;
  float dt = PERIOD_MS / 1000.0;           // 0.05 s

  float pos   = readBallCm();              // where is the ball?
  float error = target - pos;              // how far from where it should be?
  float speed = (pos - lastPos) / dt;      // how fast is it rolling? (cm/s)
  lastPos = pos;
  integral += error * dt;                  // how long has it been off?
  integral = constrain(integral, -I_MAX, I_MAX);

  float tilt = kp * error + ki * integral - kd * speed;
  tilt = constrain(tilt, -MAX_TILT, MAX_TILT);
  beam.write(LEVEL + DIRECTION * tilt);    // servo degrees around "level"
  sendStatus(pos, target, tilt);           // to Processing
}
```

For the coach:
- D uses the ball's *speed*, not the change in error. Then clicking a new target doesn't
  make the beam jump ("derivative on measurement").
- `integral` is clamped (anti-windup). Otherwise it keeps growing while the ball is held
  by hand, and the beam slams over when it's let go.
- `DIRECTION` is +1 or −1, depending on which side the servo is. If the ball runs away
  instead of coming back, flip it. Both reference builds have this choice: one uses
  `REVERSE`, the other `102 - Output`.
- We write the PID ourselves (about ten lines) instead of using the Arduino PID library, so
  James can see what each term does.

### Measuring the ball

The same as the radar's `02_distance`: time of flight, `duration × 0.034 / 2` = cm. Three
changes:

- **Short timeout.** The ball is never more than ~40 cm away, so the echo is back within
  about 2.4 ms. A `pulseIn` timeout of 3000 µs is enough. With no echo, **keep the last
  position**, don't jump to 999 as the radar does.
- **Throw away impossible jumps.** At most the ball rolls about 66 cm/s (10° over the full
  track, my calculation), so it can't move more than ~3.3 cm in 50 ms. A reading that jumps
  more than 5 cm is a bad echo: ignore it. 5 cm is my starting value.
- **Smooth the speed.** Speed from two noisy positions is very noisy, and D amplifies that
  noise. Use `speed = 0.7 * speed + 0.3 * newSpeed` (exponential smoothing). The Project
  Hub build does the same on the position, with 0.5.

**Not more often than every 50 ms.** One echo has to die out before the next ping, or
"echoes run into each other" (comment in the AntonAshraf code). Their loops run at about
50 ms and 140 ms. 50 ms is 20 times per second.

## Parts

| Needed | Where from | Notes |
|---|---|---|
| UNO R3, USB cable, breadboard | Starter Kit (has) | |
| Small servo | Starter Kit (has) | It's working all the time now, not just sweeping |
| HC-SR04 | Keyestudio kit (has) | |
| 100 µF capacitor, 1 or 2 | Starter Kit (has 3) | A second one in parallel if the servo makes the Arduino reset |
| Jumper wires | Dupont set (has) | |
| **Ping-pong ball** | not in a box | Standard 40 mm. Bring two, one gets dented |
| **Paperclip** | not in a box | The pushrod, Z-bent at both ends (RC-model style) |
| **Axle for the pivot** | Dojo? TBD | An M3 screw + nut, or a 3 mm rod or nail |
| **Base board, ~45 × 10 cm** | TBD | A piece of plank; the Starter Kit's wooden base is too short |
| Printed parts | Dojo printer | Track (maybe in 2 pieces), sensor mount, pivot stand, servo mount |
| *Later:* 3 potentiometers | Starter Kit (check the box) | Knobs for P, I, D (see Make it your own) |

Nothing has to be bought, except possibly the pivot screw if the Dojo has none.

## Electronics

**Exactly the radar's wiring**, so James already knows it:

| From | To |
|---|---|
| 5V / GND | breadboard + / − rails |
| HC-SR04 VCC / GND | + / − rail |
| HC-SR04 Trig / Echo | pin **10** / pin **11** |
| Servo red / brown / signal | + rail / − rail / pin **12** |
| 100 µF | across the rails next to the servo, long leg to + |

The sensor rides on the track, so it moves a little. Give its wires slack at the pivot end
and tape them to the track.

## Mechanics (proposed sizes, to be checked)

```
  top view of the track (mm)

  0      50                     200                          350  400
  ├──────┼───────────────────────┼─────────────────────────────┼────┤
  [HC-SR04]  near stop            pivot    pushrod at 250       far stop
             ball never closer    (axle)   (50 mm from pivot)
             than here
             ◄────────── usable: ball 6 … 33 cm from the sensor ───────►
```

- **Track:** 400 mm, 90° V-groove. The ball's centre sits about 28 mm above the bottom of
  the V, and the ball touches the walls about 14 mm up. Make the V walls 15–20 mm high:
  high enough to hold the ball, low enough that the sound hits the ball and not the walls.
- **Sensor:** at the 0 end, the "eyes" centred at the height of the ball's centre, looking
  straight along the track. The mount can borrow from `../radar/3d/radar_parts.scad`: same eye sizes,
  same upside-down trick.
- **Near stop at 50 mm.** The HC-SR04 starts at about 4 cm (Drive sheet P2), and very close
  up its two eyes look at different sides of the ball (warning seen in web search results).
  So the ball must never get closer than ~6 cm.
- **Far stop at 350 mm**, so the ball can't fall off. When the ball is gone, the sensor
  sees the stop: that's handy, not a problem.
- **Pivot in the middle** (200 mm), on two printed uprights about 70 mm high, with an axle
  through a block under the track. ±10° tilt moves the ends about ±35 mm, so 70 mm is
  enough clearance.
- **Servo beside the pivot**, horn arm about 12.5 mm (measure: which hole of the horn).
  The pushrod goes up to the track 50 mm from the pivot. That's a **lever of about 1 : 4**:
  40° on the servo gives about 9° on the track. Each servo degree is a small tilt, so the
  control is finer. Lesson: a lever trades movement for precision.
- **Why not the track straight on the servo horn?** It's simpler, but the small servo then
  carries the whole track on its shaft, and each servo degree is a full degree of tilt.
  Possible, but the linkage is better.
- **Balance:** the sensor makes the 0 end heavier. If the servo hums while holding still,
  tape a few washers or coins under the far end.
- **Printing:** whether 400 mm fits depends on the printer bed (unknown). Otherwise print
  two halves of 200 mm with a joining plate underneath. The joint must be smooth, or the
  ball stops there. Print the V open side up. The layer lines then run along the track,
  which is fine for rolling.

As with the radar: **measure first** (ball, servo, horn, sensor), then I write the `.scad`
with the measurements at the top, export STL and STEP, and run the collision checks over
the whole tilt range.

## Laptop: the control panel

```
┌────────────────────────────────────────────────────────────────┐
│  ┌┐))      ●          ┆                     │     tilt  +3.2°   │
│  ════════════════════════════════════════════ (tilts on screen) │
│  sensor   ball      target            click the beam = target   │
├────────────────────────────────────────────────────────────────┤
│ cm 30 ┤                                                         │
│    20 ┤┄┄┄┄┄┄╭╮┄┄┄┄╭─┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ── ball  ┄┄ target   │
│    10 ┤──────╯╰─╮╭─╯                                            │
│     0 ┤         ╰╯                          last 10 seconds     │
├────────────────────────────────────────────────────────────────┤
│  P [=====|------] 1.20  I [|----------] 0.00  D [===|-----] 0.60│
│  [AUTO]  [MANUAL]  [RECORD]                       Listening COM3 │
└────────────────────────────────────────────────────────────────┘
```

**Messages, one per line** (ending with a newline, `\n`):

| Direction | Message | Meaning |
|---|---|---|
| Arduino → laptop | `12.4,20.0,3.2` | ball (cm), target (cm), tilt (°). 20 per second |
| Arduino → laptop | `#P=1.20` | echo of a new setting, printed in the console |
| laptop → Arduino | `P1.2` · `I0.02` · `D0.6` | new gains |
| laptop → Arduino | `T20` | new target, in cm |
| laptop → Arduino | `M0` / `M1` | manual / automatic |
| laptop → Arduino | `A5` | in manual: tilt +5° |

- **Why not `.` at the end, like the radar?** The numbers have decimal points now. A
  newline also makes the Arduino IDE's *Serial Plotter* draw the three values as lines,
  without any Processing. That's handy in step 0.
- Every command can also be typed in the Serial Monitor, so the Arduino side can be tested
  without Processing.
- **The UNO restarts when Processing opens the port** (general knowledge: that's how the
  UNO's auto-reset works). So Processing waits ~2 s after connecting, then sends all slider
  values. Otherwise the Arduino keeps its default values while the sliders say something
  else.
- Sliders: write our own (a rectangle you drag, about 20 lines), instead of a library.
  The ControlP5 library would also work, but I haven't checked it with Processing 4.
- **RECORD** writes every line to a CSV file (`saveTable`), to compare runs afterwards.

## Building in steps

Each step works on its own before the next starts, like the radar's.

**0. Can the sensor see the ball?** (Before printing anything.) Put the HC-SR04 on the
table at ball height, behind a ruler. Roll the ball slowly from 5 to 35 cm and watch
*Tools > Serial Plotter*. Good enough: the line follows the ball without spikes or gaps
over 6–33 cm, give or take about half a centimetre. If not, see Plan B.
*James learns:* testing the riskiest part first.

**1. Build the beam.** Measure, print, assemble. Upload a sketch where the potentiometer
or the Serial Monitor (`A` commands) sets the servo angle, and find **LEVEL**: the angle
where the ball doesn't roll either way. Write it down; it goes in the code as a constant.
*James learns:* calibration, and the lever (how many track degrees per servo degree).

**2. Ball on the screen.** The Arduino only measures and sends. Processing draws the track,
the ball and the graph. This is the radar's step 5 again, with a new picture.
*James learns:* reading lines and splitting them, a scrolling graph.

**3. You are the controller.** Manual mode: the arrow keys in Processing tilt the track.
James tries to keep the ball on the target. It's hard! Talk about what James watched:
*where* the ball was (that's P), and *how fast* it was rolling (that's D).
*James learns:* sending commands to the Arduino; the feel for what the code has to do.

**4. P only.** Automatic mode, I and D at 0. Start with a small P and raise it. The ball
moves towards the target, but overshoots and rocks forever. Record it.
*James learns:* the first feedback loop, and why it isn't enough.

**5. Add D.** Raise D until the rocking dies out. Too much D and the track trembles: that's
the noisy speed, so smooth it.
*James learns:* speed from position, smoothing, damping.

**6. Add I.** If the ball settles just next to the target, add a little I until it's spot
on.
*James learns:* adding up over time, and why it needs a limit.

**7. Play with it.** Click the beam to move the target. Push the ball, blow on it through a
straw. Record runs and compare: how far it overshoots, how long until it settles.
*James learns:* measuring how good a controller is.

## Tuning: a recipe for the coach

1. I = 0, D = 0. Raise P until the ball rocks steadily around the target.
2. Raise D until the rocking dies out within a few swings.
3. Raise P a bit more, then D again, while it keeps behaving.
4. Only then a small I, if there is still an offset.
5. Ball runs away immediately → `DIRECTION` is wrong, not the gains.

**Starting values** from the two builds in Sources, both with position in cm and output in
servo degrees: **P 0.8 · I 0.02 · D 0.75** (Project Hub) and **P 2.05 · I 0 · D 0.85**
(AntonAshraf). Their linkage isn't described, so these only give an order of magnitude.
With our 1 : 4 lever, expect larger values in servo degrees. Note: both have I almost or
exactly 0.

## When it doesn't work

| Symptom | Likely cause |
|---|---|
| Position spikes or gaps | Ball too close (< 6 cm), sensor not at ball-centre height, echo off the V walls. Check the jump filter |
| Position stuck at ~35 cm with the ball elsewhere | The sensor sees the far stop, not the ball: aim it at the ball's centre |
| Ball runs straight to one end | `DIRECTION` wrong (flip the sign), or LEVEL far off |
| Ball rocks and never settles | Too little D, or too much P |
| Track trembles or buzzes in place | Too much D, or a noisy speed: smooth more. Play in the pushrod |
| Ball stops just next to the target | Needs a little I, or LEVEL is a bit off |
| Ball sticks at one spot | Rough spot or seam in the track: sand it, or line the V with tape |
| Sliders change nothing | The Arduino reset when Processing connected: wait 2 s and resend. Look for `#P=` lines in the console |
| Arduino resets, servo jitters | Capacitor missing or the wrong way round; add the second 100 µF |
| "Port busy" on upload | Serial Monitor or Plotter open, or Processing running (same as the radar) |

## Plan B (if step 0 fails)

Several builds make this work with an HC-SR04 and a 30 cm range, so it should work. But
the sensor is meant for flat targets, and a round ball gives a weaker, noisier echo
(warning seen in web search results, not tested here). If step 0 shows that:

1. **Roll a cylinder instead of a ball:** a short printed roller, about 40 mm across and 40
   mm long. It's curved only one way, so it sends more sound back (my reasoning, untested).
   The track then needs a flat bottom with low sides.
2. **A bigger ball** (a tennis ball) gives a bigger target. The track gets wider.
3. **Another sensor (to buy):** an infrared distance sensor (Sharp GP2Y0A21, analog), as in
   the Electronoobs ball-and-beam build. That build is the basis of the ASEE paper in
   Sources. Or a laser time-of-flight sensor (VL53L0X, I2C). Either way the measuring code
   changes, but the rest of the plan stays the same.

## Make it your own

- **Knobs instead of a laptop:** three potentiometers as P, I and D knobs (Starter Kit,
  check the box), values on the 16×2 LCD.
- **Follow the target:** the target moves slowly back and forth. How well does the ball keep
  up?
- **A game for two:** one player disturbs the ball with a straw. Score = seconds the ball
  stays within 1 cm of the target.
- **Remember the best settings** in EEPROM, so they survive unplugging.
- **The big sequel:** a ball on a *plate*, with two servos and two directions. That needs
  another way to see the ball, such as a touch panel or a camera.

## Sources

- *Self Balancing Ball and Beam using PID control*, nihalsuri, Arduino Project Hub, 2021:
  <https://projecthub.arduino.cc/nihalsuri/24357c80-d6c4-4d8e-bfa4-f30d4444f096> (read
  2026-11-22). 30 cm beam, Trig/Echo sensor, Arduino PID library, P 0.8 · I 0.02 · D 0.75,
  exponential filter 0.5, loop of about 50 ms, output limited to ±24°. No licence stated.
- *Ball & Beam PID Control System using Arduino Uno*, AntonAshraf on GitHub:
  <https://github.com/AntonAshraf/Ball-Beam-PID-Control> (read 2026-11-22, GPL-3.0).
  Ultrasonic sensor, target 15 cm, P 2.05 · I 0 · D 0.85, no filter, loop of about 140 ms.
  Comment: "Don't set too low or echos will run into eachother."
- CoderDojo Belgium, CDJ Oostende, *P2-project snelheid meten* (Drive, read 2026-11-22):
  HC-SR04 range 4 cm to 4 m.
- *Exploring PID control in ball-beam systems: a hands-on educational approach*, ASEE:
  <https://peer.asee.org/exploring-pid-control-in-ball-beam-systems-a-hands-on-educational-approach.pdf>.
  Seen in search results only: its hardware follows the Electronoobs tutorial (IR sensor).
- Warnings about the HC-SR04 with a round ball and at close range: from web search results
  on 2026-11-22. I didn't read the page they came from, so treat them as things to test in
  step 0.

We write our own code. If we copy anything from the AntonAshraf repository, its GPL-3.0
licence applies, so better not.

## Open questions

- **Does James want this one?** See "Choosing" in `../next-project-ideas.md`.
- **Step 0:** does the HC-SR04 see the ping-pong ball well enough?
- **Printer bed size:** the track in one piece or two?
- **Measurements:** ball diameter, the horn hole distance from the servo shaft (sets the
  lever), servo body. The HC-SR04 is already in the radar's table, still unmeasured.
- **At the Dojo?** An M3 screw + nut for the pivot, a ~45 cm plank for the base.
