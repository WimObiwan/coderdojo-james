// Step 2: measure a distance with the ultrasonic sensor (HC-SR04)
// and show it on the computer.
//
// Wiring:
//   HC-SR04 VCC  -> 5V
//   HC-SR04 GND  -> GND
//   HC-SR04 Trig -> pin 10
//   HC-SR04 Echo -> pin 11
//
// Upload, then open Tools > Serial Monitor and set it to 9600 baud.
// Hold your hand in front of the sensor and move it closer and further away.

const int TRIG_PIN = 10;
const int ECHO_PIN = 11;

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  Serial.begin(9600);
}

void loop() {
  int cm = measureDistance();
  Serial.print("Distance: ");
  Serial.print(cm);
  Serial.println(" cm");
  delay(200);
}

// Returns the distance in centimetres, or 999 if there is no echo
// (nothing in front of the sensor, or too far away).
int measureDistance() {
  // 1. Send a short "ping": Trig HIGH for 10 microseconds.
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // 2. Echo stays HIGH for as long as the sound was on its way,
  //    in microseconds. We wait at most 30000 microseconds (30 ms).
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duration == 0) {
    return 999;   // no echo came back in time
  }

  // 3. Sound covers 0.034 cm per microsecond (343 metres per second).
  //    It travels there AND back, so divide by 2.
  return duration * 0.034 / 2;
}
