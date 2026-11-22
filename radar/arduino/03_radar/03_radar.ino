// Step 3: the radar.
// The servo turns the sensor from 15 to 165 degrees and back. At every
// degree we measure the distance and send "angle,distance." to the
// computer, for example "45,23." means: at 45 degrees something is 23 cm away.
// The Processing sketch radar_display reads this and draws the radar screen.
//
// Wiring (the same as steps 1 and 2 together):
//   HC-SR04 VCC  -> 5V          servo red    -> 5V
//   HC-SR04 GND  -> GND         servo brown  -> GND
//   HC-SR04 Trig -> pin 10      servo orange -> pin 12
//   HC-SR04 Echo -> pin 11
//
// Based on "Arduino Radar Project" by Dejan Nedelkovski, HowToMechatronics.com
// https://howtomechatronics.com/projects/arduino-radar-project/
// (original code: ../../source/howtomechatronics-radar.ino)

#include <Servo.h>

const int TRIG_PIN  = 10;
const int ECHO_PIN  = 11;
const int SERVO_PIN = 12;

const int MIN_ANGLE = 15;
const int MAX_ANGLE = 165;
const int STEP_DELAY = 30;   // milliseconds per degree: bigger = slower

Servo myServo;

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  Serial.begin(9600);
  myServo.attach(SERVO_PIN);
}

void loop() {
  // from right to left ...
  for (int angle = MIN_ANGLE; angle <= MAX_ANGLE; angle++) {
    scan(angle);
  }
  // ... and back
  for (int angle = MAX_ANGLE; angle > MIN_ANGLE; angle--) {
    scan(angle);
  }
}

// Turn to one angle, measure, and send "angle,distance." to the computer.
void scan(int angle) {
  myServo.write(angle);
  delay(STEP_DELAY);
  int distance = measureDistance();

  Serial.print(angle);
  Serial.print(",");
  Serial.print(distance);
  Serial.print(".");
}

// The same function as in step 2.
// Returns the distance in centimetres, or 999 if there is no echo.
int measureDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duration == 0) {
    return 999;
  }
  return duration * 0.034 / 2;
}
