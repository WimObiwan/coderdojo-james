# James: speed camera for toy cars (detailed plan)

**Status:** proposal (idea 4 of `../next-project-ideas.md`), not chosen yet · **Written:**
2026-11-22

A toy car rolls down a ramp and along a straight run-out towards a "speed camera" at the
end. The camera is the HC-SR04, looking down the track at the oncoming car, the way a real
speed camera looks at oncoming traffic. It measures the distance to the car about 30 times
a second. From how fast that distance shrinks, the Arduino works out the speed and shows it
on the LCD: in m/s, and as "real-life" km/h for a 1:64 car. On the laptop, Processing draws
every run as a distance–time graph and keeps a leaderboard.

The idea and the ramp come from a Drive sheet (see Sources). The rest is **our own design**,
from general knowledge. Nothing has been built or compiled.

## One sensor: look along the track, not across it

The Drive sheet *P2-project snelheid meten* uses **two** HC-SR04s pointing *across* the
ramp, like two finish lines, and times the car from one to the other. With only one sensor
across the track you'd have to time how long the car blocks it. That doesn't work: a 7 cm
car at 2 m/s passes in 35 ms, about as long as one measurement takes.

So the one sensor looks **along** the track instead:

```
 distance                       each dot = one measurement (every 30 ms)
 (cm)
 100 ┤●
     │   ●                        the car comes closer:
  80 ┤      ●                     the dots go down in a straight line
     │         ●
  60 ┤            ●               speed = how steep the line is
     │               ●                  = cm per ms
  40 ┤                  ●
     │                     ●      1 cm/ms = 10 m/s
  20 ┤                        ●
     └──────────────────────────── time (ms)
      0    100   200   300   400
```

That's also the big idea James learns: **speed is the steepness of the distance–time
line.** A faster car draws a steeper line.

## The setup

```
 side view (not to scale)

  start gate (servo arm)
  ┌──┐│
  │ ◐├┤▄█▄
  └──┘│   ╲
           ╲   ramp, ~1 m (cardboard with edges)
            ╲
     books   ╲___________________________________________ ┌───────┐
     under    ╲         run-out, ~1.2 m, flat  ▄█▄ ──►    ◄)))│HC-SR04│ "speed camera"
     the top                                              │       │
                                                          └─▓▓────┘ ← soft bumper below the sensor
              ◄──────────── measuring window (from step 0) ──────►
```

- **Ramp:** as in the P2 sheet, sturdy cardboard about 1 m long and 10 cm wide, with narrow
  strips along the edges so the car doesn't fall off. The top rests on books, so the height
  is easy to change.
- **Run-out:** flat, straight, ~1.2 m, with edges as well. The final length depends on how
  far the sensor can see a toy car (step 0).
- **Speed camera:** a 3D-printed housing at the end of the run-out with the HC-SR04
  looking back up the track. The eyes sit at about car height, roughly 3–4 cm above the
  track. A **soft bumper** under the sensor (foam, a sponge) stops the car. It sits under and
  behind the sensor's face, so the sensor doesn't see it.
- **Start gate (optional, step 7):** the servo with a printed arm across the top of the
  ramp. Press the button: the piezo beeps three times, the arm swings away, the car goes.
  The Arduino then knows the exact start time, so it also gives a **race time**.

## Why this one

| | Radar | Speed camera |
|---|---|---|
| Sensor | measures one distance per angle | measures a **series** of distances over time |
| Maths | sin/cos | **speed = distance ÷ time**, the slope of a line, units (cm/ms → m/s → km/h) |
| Code | a loop that sweeps | a **state machine**: waiting → measuring → done → waiting |
| Output | laptop only | **LCD on the Arduino** (works without a laptop) + laptop screen |
| Servo | turns the sensor | start gate |
| Fun | seeing the room | racing your own cars, a leaderboard, "460 km/h!" |

It's a smaller step than the ball on a beam: no feedback loop and no tuning. It's mostly
*measuring well* and *counting carefully*.

## How it works

### Measuring the car

The same time-of-flight code as the radar's `02_distance` (`duration × 0.034 / 2` = cm),
with three changes:

- **Faster:** a measurement every 30 ms instead of the radar's 1 per degree. At 2 m/s the
  car moves 6 cm between measurements, so over a 1 m window that's about 15 points. If
  echoes from one ping disturb the next (spikes in step 0), slow down to 40–60 ms.
- **Timeout to match the window:** a car at 1.5 m sends its echo back after about 9 ms, so
  `pulseIn(..., 10000)` is enough. No echo = 0 = "nothing seen".
- **Record the time of each measurement** with `millis()`. Each point is a pair: *(time,
  distance)*.

### Detecting a run: a state machine

The Arduino is always in one of three states. The P2 sheet does the same with a table of
cases (car at sensor 2 before sensor 1, and so on). This is the one-sensor version.

| State | What it does | Goes to the next state when |
|---|---|---|
| **ARMED** (waiting) | measures, but saves nothing | something appears inside the window (closer than `START_CM`) → **MEASURING** |
| **MEASURING** | saves every (time, distance) that fits | the car is closer than `END_CM`, or no good point for 300 ms → calculate, show → **DONE** |
| **DONE** | shows the result, ignores the car (it bounces, gets picked up) | nothing in the window for 1 s → **ARMED** |

**A point "fits"** if it is closer than the previous one, but not by more than the car can
travel in 30 ms. At most about 12 cm: 4 m/s × 30 ms, my starting value. That throws out
spikes, a hand above the track and the bounce off the bumper. A run with fewer than 5 points
doesn't count; the LCD says `try again`.

### From points to speed

**Version 1 (step 3): first and last point.**
`speed = (first distance − last distance) / (last time − first time)` in cm/ms, × 10 =
m/s. Easy to understand, and to do by hand from the Serial Monitor.

**Version 2 (step 6): the best straight line through all points** (least squares). It uses
every point, so one slightly wrong point matters less. The formula is a mouthful, but the
idea is clear on the graph: the line that passes as close as possible to all the dots.
**This is a sketch of the idea, not compiled code.**

```cpp
float bestSpeed() {                       // best straight line through all n points
  float sT = 0, sD = 0, sTT = 0, sTD = 0;
  for (int i = 0; i < n; i++) {
    float t = times[i] - times[0];        // ms since the first point
    sT += t;  sD += dists[i];  sTT += t * t;  sTD += t * dists[i];
  }
  float slope = (n * sTD - sT * sD) / (n * sTT - sT * sT);   // cm per ms (negative: coming closer)
  return -slope * 10.0;                   // m/s
}
```

Which one is better? Let James find out: roll the same car 5 times from the same height,
and see which version gives the steadier numbers.

### Units: the fun part

- 1 cm/ms = 10 m/s. Multiply m/s by 3.6 to get km/h.
- Toy cars of the common small size are 1:64 scale (general knowledge; check the box or
  the bottom of the car). A real car the same size would go 64 times as fast: **2 m/s ×
  64 = 128 m/s ≈ 460 km/h.** The LCD shows both.
- **Can it be right?** A car rolling down from height *h* without any friction would reach
  √(2·g·h). From 20 cm up that's about 2.0 m/s (my calculation). The measured speed must be
  lower. How much lower tells how much the friction "ate". If the camera says *more* than
  that, something's wrong with the measurement. That's a nice check, and a bit of physics.

## Parts

| Needed | Where from | Notes |
|---|---|---|
| UNO R3, USB, breadboard, wires | Starter Kit + Dupont set (has) | |
| HC-SR04 | Keyestudio kit (has) | **The only sensor needed** |
| 16×2 LCD | Starter Kit or Keyestudio kit (has, "one in both kits") | Type unknown: parallel (6 data wires + contrast pot) or I2C (4 wires). See Electronics |
| Servo | Starter Kit (has) | Start gate, step 7. Optional |
| Piezo | Starter Kit (has) | Countdown beeps and a "flash" beep |
| 100 µF capacitor | Starter Kit (has) | For the servo, as in the radar |
| Pushbutton | Starter Kit (check the box) | Start button |
| Potentiometer | Starter Kit (check the box) | LCD contrast, if the LCD is the parallel type |
| **Toy cars** | James's own | The more, the better the leaderboard |
| **Cardboard**, ~1 m and ~1.2 m × 10 cm, plus strips for edges | not in a box | Or a plank, or a toy track if someone has one |
| **Books**, a **sponge or foam** | not in a box | Ramp height; the bumper |
| Printed parts | Dojo printer | Camera housing with bumper, start gate, maybe number-plate clips |

Nothing has to be bought.

## Electronics

The radar's pins for the sensor and the servo, so James knows them already:

| Part | Pins |
|---|---|
| HC-SR04 Trig / Echo | **10** / **11** (VCC to 5V, GND to GND) |
| Servo (start gate) | signal **12**, with the 100 µF across the rails |
| Piezo | **9** and GND |
| Pushbutton | **8** and GND (`INPUT_PULLUP`: pressed reads LOW, no resistor needed) |
| LCD, parallel type | RS **7**, E **6**, D4–D7 **5, 4, 3, 2**. RW to GND, contrast (V0) to the middle of the potentiometer, backlight through 220 Ω. Library: `LiquidCrystal` (comes with the IDE) |
| LCD, I2C type | SDA **A4**, SCL **A5**, VCC, GND. Library: `LiquidCrystal_I2C` (install it) |

Wire and test one part at a time, as in the radar: sensor first, LCD next, then button,
piezo and servo.

## Laptop: the speed camera screen

```
┌──────────────────────────────────────────────────────────────────┐
│  SPEED CAMERA                          ┌─ LEADERBOARD ──────────┐ │
│                                        │ 1. Red Racer   2.14 m/s│ │
│      1.84 m/s                          │ 2. Blue Van    1.97 m/s│ │
│      = 424 km/h  (1:64)                │ 3. Truck       1.52 m/s│ │
│                                        └────────────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│ cm 100 ┤●                                                          │
│     75 ┤  ●●          dots: this run    line: best fit            │
│     50 ┤      ●●●                                                 │
│     25 ┤           ●●●●                 slope = −0.184 cm/ms      │
│        └────────────────────── ms                                 │
├──────────────────────────────────────────────────────────────────┤
│  Car name: Red Racer_     [START]  [GATE UP]   scale 1:64 ▾   COM3 │
└──────────────────────────────────────────────────────────────────┘
```

- A white **flash** over the whole window when a speed comes in.
- **Leaderboard** saved to a CSV file in the sketch folder (`saveTable`), so it survives a
  restart.
- Type the car's name before each run.

**Messages, one per line** (newline at the end, as in the ball on a beam):

| Direction | Message | Meaning |
|---|---|---|
| Arduino → laptop | `#ARMED`, `#GO` | state changes, printed in the console |
| Arduino → laptop | `P,135,62.4` | one point: ms since the first point, cm |
| Arduino → laptop | `S,1.84,1035` | result: speed in m/s, race time in ms (0 without the gate) |
| Arduino → laptop | `X` | run didn't count (too few points) |
| laptop → Arduino | `G` | countdown + open the gate |
| laptop → Arduino | `U` | gate back up |

Processing can draw its own best-fit line through the `P` points. If its slope matches the
Arduino's `S`, both programs did the maths the same way: a good check.

## Building in steps

**0. Can the sensor see a toy car, and how far?** (Before building any track.) HC-SR04 on
the table at car height; the Arduino prints the distance every 30 ms. Push a car slowly
towards it from 2 m away and watch *Tools > Serial Plotter*. Write down **from how far it
reliably sees the car**. That sets the length of the run-out and `START_CM`. Also try 30,
40 and 60 ms between measurements: do spikes appear with the car far away?
*James learns:* testing the riskiest part first. If the car is hard to see, give it a
"number plate" (see When it doesn't work).

**1. Build the track.** Ramp and run-out with edges, print the camera housing, fix the
sensor in it, and add the bumper.

**2. Watch a car come in.** The Arduino just keeps sending `time,distance`. Roll a car and
watch the Serial Plotter: a falling line. Faster car, steeper line.
*James learns:* what a distance–time graph means.

**3. Catch one run.** The state machine, and speed from the first and last point, in the
Serial Monitor.
*James learns:* states, arrays (saving the points), cm/ms → m/s.

**4. LCD.** `1.84 m/s` on line 1, `424 km/h 1:64` on line 2. Now the speed camera works
without a laptop.
*James learns:* a library, decimals on a small screen.

**5. The speed camera screen in Processing.** Graph, flash, leaderboard, CSV.
*James learns:* drawing a graph from points, lists and sorting, saving a file.

**6. The best straight line.** Least squares on the Arduino *and* in Processing. Five runs
of the same car: which version is steadier?
*James learns:* that every measurement has an error, and how to measure that.

**7. Start gate.** Button → three beeps → servo swings the arm away → `#GO`. Also show the
race time.
*James learns:* putting it all together; a fair start for racing.

## When it doesn't work

| Symptom | Likely cause |
|---|---|
| The sensor doesn't see the car far away | Small car, a round nose. Shorten the window, or clip a flat **number plate** (card or printed, ~3 × 2 cm) on the front. It reflects much better (general knowledge, test in step 0) |
| Spikes in the graph | Measuring too fast: echoes of the previous ping. Go from 30 to 40–60 ms. Or an echo off a wall behind the ramp |
| A reading without a car (the window is never empty) | The sensor sees the ramp or the books at the far end: set `START_CM` shorter than that distance |
| Every run says `try again` | Too few points: window too short, measuring too slowly, or the car too fast. Check with the Serial Plotter |
| The same car gives very different speeds | Car not straight on the track (rubs the edges), different start spot: use the start gate. Compare version 1 and 2 |
| Speed higher than √(2·g·h) | A wrong point got in (spike), or a units mistake (cm vs m, ms vs s) |
| LCD lights up but shows nothing / only blocks | Contrast: turn the potentiometer. I2C type: wrong address in the code |
| Arduino resets when the gate opens | Capacitor on the servo, as in the radar |
| "Port busy" | Serial Monitor/Plotter or Processing still open (same as the radar) |

## Make it your own

- **Watch it speed up:** measure on the *ramp* itself (camera at the bottom of a long
  straight slope, no run-out). The graph becomes a curve, not a straight line, because the
  car keeps accelerating.
- **Speed of sound by temperature:** sound is a bit faster when it's warm (about 331 + 0.6 ×
  °C m/s, general knowledge). With the temperature sensor from the Starter Kit (check the
  box) the camera corrects itself. Is the difference even measurable?
- **Speed limit:** set a limit. Too fast → red LED and a "fine" on the screen.
- **Which car is best?** Roll every car 5 times; the leaderboard shows the average and the
  spread, not just the best run.
- **Ramp height vs speed:** 10, 20, 30 cm. Does twice as high give twice the speed? (No:
  √2 as much. Let James find that out from the data.)

## Sources

- CoderDojo Belgium, CDJ Oostende, *P2-project snelheid meten* (Drive:
  `cdj :: PUBLIC FOLDERS/cdj :: ARDUINO/NL/Materiaal CDJ Oostende/Pdf versie/`, read
  2026-11-22, CC BY-NC-SA 3.0, attribution "CoderDojo Belgium vzw"). From it: the idea of a
  speed camera for a toy car on a ramp, the cardboard ramp (1 m × 10 cm, edge strips), the
  table of abnormal cases, HC-SR04 range 4 cm to 4 m. **Different here:** one sensor along
  the track instead of two across it, the LCD without I2C as an option, the laptop screen,
  the start gate.
- Everything else (the one-sensor method, least squares, the state machine, scale speed,
  the physics check) is general knowledge, not from a tutorial.

## Open questions

- **Does James want this one?** See "Choosing" in `../next-project-ideas.md`.
- **Step 0:** from how far does the HC-SR04 see a toy car? That sets the run-out length.
- **The LCD:** parallel or I2C, and which kit's? The wiring and the library depend on it.
- **Toy cars:** which ones does James have, and what scale (1:64 is written on many)?
- **Track material:** cardboard (as in the sheet), a plank, or a toy track, if the Dojo or
  James has one.
