// Step 1: make the servo sweep left and right, the way the radar will.
//
// Wiring:
//   servo brown  -> GND
//   servo red    -> 5V
//   servo orange -> pin 12
//
// When it starts, the servo first goes to 90 degrees (straight ahead) and
// waits 3 seconds. That is the moment to push the horn on so it points
// straight ahead. Then the sweep is the same on both sides.

#include <Servo.h>

const int SERVO_PIN = 12;

const int MIN_ANGLE = 15;
const int MAX_ANGLE = 165;
const int STEP_DELAY = 30;   // milliseconds per degree: bigger = slower

Servo myServo;

void setup() {
  myServo.attach(SERVO_PIN);
  myServo.write(90);   // straight ahead
  delay(3000);
}

void loop() {
  // from right to left ...
  for (int angle = MIN_ANGLE; angle <= MAX_ANGLE; angle++) {
    myServo.write(angle);
    delay(STEP_DELAY);
  }
  // ... and back
  for (int angle = MAX_ANGLE; angle > MIN_ANGLE; angle--) {
    myServo.write(angle);
    delay(STEP_DELAY);
  }
}
