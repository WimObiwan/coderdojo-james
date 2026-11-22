/*  Radar display for the Arduino radar (step 3: 03_radar).
 *
 *  The Arduino sends "angle,distance." over USB, for example "45,23.".
 *  This sketch reads that and draws a radar screen: a green line that
 *  sweeps along, and red where something is closer than 40 cm.
 *
 *  Before you press Run:
 *    1. Upload 03_radar to the Arduino.
 *    2. CLOSE the Serial Monitor in the Arduino IDE. Only one program at a
 *       time can use the USB port.
 *    3. Set PORT_NUMBER below (see the comment there).
 *
 *  Based on "Arduino Radar Project" (updated version, fits any screen) by
 *  Dejan Nedelkovski, HowToMechatronics.com
 *  https://howtomechatronics.com/projects/arduino-radar-project/
 *  (original code: ../../source/howtomechatronics-radar-display.pde)
 *  The drawing code below is unchanged from the original.
 */

import processing.serial.*;

// Which USB port is the Arduino on?
// Press Run once: the console at the bottom then shows a numbered list of
// ports, like  [2] "COM3"  or  [0] "/dev/ttyACM0". Put that number here.
//   Windows: a COM port, usually the last one in the list (not COM1)
//   Mac:     /dev/cu.usbmodem... or /dev/cu.usbserial...
//   Linux:   /dev/ttyACM0 or /dev/ttyUSB0 (not /dev/ttyS...)
// Not sure? Unplug the Arduino, press Run, plug it back in, press Run again:
// the port that appeared is the Arduino.
int PORT_NUMBER = -1;   // -1 = not chosen yet

Serial myPort;
String noObject;
float pixsDistance;
int iAngle, iDistance;
PFont orcFont;

void setup() {
  size(1280, 720);   // window size: change it if you like, but keep it 16:9
                     // (1920x1080, 1600x900, 1280x720, 960x540)
  smooth();

  // The video uses the font "OCR A Extended". To get that exact look:
  // Tools > Create Font..., pick OCR A Extended, size 30, and replace this
  // line with:  orcFont = loadFont("OCRAExtended-30.vlw");
  orcFont = createFont("Monospaced", 30);

  String[] ports = Serial.list();
  println("Serial ports on this computer:");
  printArray(ports);
  if (PORT_NUMBER < 0 || PORT_NUMBER >= ports.length) {
    println("Set PORT_NUMBER at the top of this sketch to the Arduino's port and press Run again.");
  } else {
    try {
      myPort = new Serial(this, ports[PORT_NUMBER], 9600);
      myPort.bufferUntil('.');   // call serialEvent() after every '.'
      println("Listening on " + ports[PORT_NUMBER]);
    } catch (RuntimeException e) {
      println("Could not open " + ports[PORT_NUMBER] + ": " + e.getMessage());
      println("Is the Serial Monitor of the Arduino IDE still open? Close it and press Run again.");
    }
  }
}

void draw() {
  fill(98,245,31);
  textFont(orcFont);
  // simulating motion blur and slow fade of the moving line
  noStroke();
  fill(0,4);
  rect(0, 0, width, height-height*0.065);

  fill(98,245,31); // green color
  // calls the functions for drawing the radar
  drawRadar();
  drawLine();
  drawObject();
  drawText();
}

// Runs every time a complete message "angle,distance." has arrived.
void serialEvent(Serial port) {
  String data = port.readStringUntil('.');
  if (data == null) {
    return;
  }
  data = trim(data.substring(0, data.length()-1));   // drop the '.'

  int comma = data.indexOf(",");
  if (comma < 1) {
    return;   // half a message (happens just after connecting): skip it
  }
  iAngle = int(data.substring(0, comma));
  iDistance = int(data.substring(comma+1));
}

void drawRadar() {
  pushMatrix();
  translate(width/2,height-height*0.074); // moves the starting coordinats to new location
  noFill();
  strokeWeight(2);
  stroke(98,245,31);
  // draws the arc lines
  arc(0,0,(width-width*0.0625),(width-width*0.0625),PI,TWO_PI);
  arc(0,0,(width-width*0.27),(width-width*0.27),PI,TWO_PI);
  arc(0,0,(width-width*0.479),(width-width*0.479),PI,TWO_PI);
  arc(0,0,(width-width*0.687),(width-width*0.687),PI,TWO_PI);
  // draws the angle lines
  line(-width/2,0,width/2,0);
  line(0,0,(-width/2)*cos(radians(30)),(-width/2)*sin(radians(30)));
  line(0,0,(-width/2)*cos(radians(60)),(-width/2)*sin(radians(60)));
  line(0,0,(-width/2)*cos(radians(90)),(-width/2)*sin(radians(90)));
  line(0,0,(-width/2)*cos(radians(120)),(-width/2)*sin(radians(120)));
  line(0,0,(-width/2)*cos(radians(150)),(-width/2)*sin(radians(150)));
  line((-width/2)*cos(radians(30)),0,width/2,0);
  popMatrix();
}

void drawObject() {
  pushMatrix();
  translate(width/2,height-height*0.074); // moves the starting coordinats to new location
  strokeWeight(9);
  stroke(255,10,10); // red color
  pixsDistance = iDistance*((height-height*0.1666)*0.025); // covers the distance from the sensor from cm to pixels
  // limiting the range to 40 cms
  if(iDistance<40){
    // draws the object according to the angle and the distance
  line(pixsDistance*cos(radians(iAngle)),-pixsDistance*sin(radians(iAngle)),(width-width*0.505)*cos(radians(iAngle)),-(width-width*0.505)*sin(radians(iAngle)));
  }
  popMatrix();
}

void drawLine() {
  pushMatrix();
  strokeWeight(9);
  stroke(30,250,60);
  translate(width/2,height-height*0.074); // moves the starting coordinats to new location
  line(0,0,(height-height*0.12)*cos(radians(iAngle)),-(height-height*0.12)*sin(radians(iAngle))); // draws the line according to the angle
  popMatrix();
}

void drawText() { // draws the texts on the screen

  pushMatrix();
  if(iDistance>40) {
  noObject = "Out of Range";
  }
  else {
  noObject = "In Range";
  }
  fill(0,0,0);
  noStroke();
  rect(0, height-height*0.0648, width, height);
  fill(98,245,31);
  textSize(25);

  text("10cm",width-width*0.3854,height-height*0.0833);
  text("20cm",width-width*0.281,height-height*0.0833);
  text("30cm",width-width*0.177,height-height*0.0833);
  text("40cm",width-width*0.0729,height-height*0.0833);
  textSize(40);
  text("Object: " + noObject, width-width*0.875, height-height*0.0277);
  text("Angle: " + iAngle +" °", width-width*0.48, height-height*0.0277);
  text("Distance: ", width-width*0.26, height-height*0.0277);
  if(iDistance<40) {
  text("        " + iDistance +" cm", width-width*0.225, height-height*0.0277);
  }
  textSize(25);
  fill(98,245,60);
  translate((width-width*0.4994)+width/2*cos(radians(30)),(height-height*0.0907)-width/2*sin(radians(30)));
  rotate(-radians(-60));
  text("30°",0,0);
  resetMatrix();
  translate((width-width*0.503)+width/2*cos(radians(60)),(height-height*0.0888)-width/2*sin(radians(60)));
  rotate(-radians(-30));
  text("60°",0,0);
  resetMatrix();
  translate((width-width*0.507)+width/2*cos(radians(90)),(height-height*0.0833)-width/2*sin(radians(90)));
  rotate(radians(0));
  text("90°",0,0);
  resetMatrix();
  translate(width-width*0.513+width/2*cos(radians(120)),(height-height*0.07129)-width/2*sin(radians(120)));
  rotate(radians(-30));
  text("120°",0,0);
  resetMatrix();
  translate((width-width*0.5104)+width/2*cos(radians(150)),(height-height*0.0574)-width/2*sin(radians(150)));
  rotate(radians(-60));
  text("150°",0,0);
  popMatrix();
}
