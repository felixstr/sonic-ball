// MIDI Bridge
// Sonic Interaction Design
// Moritz Kemper, IAD Physical Computing Lab
// ZHdK, 09/01/2015

import processing.serial.*;    // Import the Processing Serial Library 
import themidibus.*;           // Import the MIDI Bus Library: https://github.com/sparks/themidibus 

Serial myXbeePort;             // The used Serial Port
MidiBus myMidiBus;             // The used MIDI Port

int xbeeAddress = 0;           // The Address we are listening to

PVector accel = new PVector(); // Variable to store Accelerometer Data
PVector gyro = new PVector();  // Variable to store Gyroscope Data

boolean inMove = false;
boolean trackMillis = true;

//------------------ Record Movements --------------------
ArrayList<Float> gyroMagni = new ArrayList<Float>();
ArrayList<Float> accelMagni = new ArrayList<Float>();
int m;
int mm;
int mmCount = 0;
boolean bREC = true;

//------------------ End Record Movements --------------------



//--------------------------------------------------------
void setup()
{
  size(500, 500);

  println(Serial.list()); // Prints the list of serial available devices (Arduino should be on top of the list)

  myXbeePort = new Serial(this, Serial.list()[Serial.list().length-1], 38400); // Open a new port and connect with Arduino at 38400 baud

  Serial.list();
  myXbeePort.buffer(22);

  MidiBus.list(); // List all available Midi devices
  myMidiBus = new MidiBus(this, "", "P5toMIDI"); //Mac

  println("setup end");
}

//---------------------------------------------------------
void draw()
{
  background(0);
  drawGraph(width/2, 10);

  checkMove(); // is ball moving? (inMove)
  if (inMove) {
    record();
    mmCount = 0;
  } else {
    play();
  }
}

//---------------------------------------------------------
int lastMoveStatus = 0;
boolean  inMoveLast = false;
boolean  moveChangeFlag = true;
boolean change = false;


void checkMove() {
  float mag = gyro.mag();
  int tolerance = 1000;

  boolean inMoveCurrent = (mag > tolerance);

  if ((inMoveLast && !inMoveCurrent) || (!inMoveLast && inMoveCurrent)) {
    change = true;
    lastMoveStatus = millis();
  }
  // println("lastMoveStatus: "+lastMoveStatus);
  // println("change: "+change);

  if (((millis() - lastMoveStatus) > tolerance) && change) {
    inMove = inMoveCurrent;
    change = false;

    if (inMove) {
      prepareRecord();
    } else {
      preparePlay();
    }
  }

  inMoveLast = inMoveCurrent;
}

/**
 * wird vor dem record einmal aufgerufen
 */
void prepareRecord() {
  println("**** RECORDING ****");

  myMidiBus.sendNoteOff(0, 31, 127 );
  gyroMagni.clear();
  accelMagni.clear();
} 

/**
 * wird vor dem play einmal aufgerufen
 */
void preparePlay() {
  println("**** PLAYING ****");

  myMidiBus.sendNoteOn(0, 31, 127 );
}

/**
 * speicher die bewegung in zwei arrayLists
 */
void record() {
  myMidiBus.sendNoteOff(0, 31, 127 );
  
  
  if (trackMillis == true) {
    m = 0;
    m = millis();
    trackMillis = false;
  }

  if (m + 1 < millis()) {

    gyroMagni.add(gyro.mag());
    accelMagni.add(accel.mag()); 
    trackMillis = false;
  }
}



/**
 * spielt die gespeicherte bewegung ab und sendet sie an den midiBus
 */
void play()  {
  if (gyroMagni.size() > 0) {
  
    if (trackMillis == true) {
      mm = millis();
      trackMillis = false;
    }

    if (mm + 1 < millis()) {
      if (mmCount >= gyroMagni.size()-1) mmCount = 0;
      if (mmCount < gyroMagni.size()) mmCount++;

      //println( gyroMagni.get(mmCount));
      println(mmCount + " von " + gyroMagni.size());
      println("Gyro Value an Stelle: " + mmCount + " :" +   map(gyroMagni.get(mmCount), 500, 40000, 0, 127));
      println("Accel Value an Stelle: " + mmCount + " :" +   map(accelMagni.get(mmCount), 3500, 50000, 0, 127));


      myMidiBus.sendControllerChange(0, 74, (int)map(gyroMagni.get(mmCount), 500, 40000, 0, 127));
      myMidiBus.sendControllerChange(0, 75, (int)map(accelMagni.get(mmCount), 3500, 50000, 0, 127));
    }
  }
}

//---------------------------------------------------------
void serialEvent(Serial myXbeePort) // Is called everytime there is new data to read
{
  if (myXbeePort.available() == 22)
  {
    if (myXbeePort.read() == 0x7e)
    {
      xbeeAddress = myXbeePort.read();

      byte[] inBuffer = new byte[20]; // Create an empty Byte Array to fill it with data from Arduino
      inBuffer = myXbeePort.readBytes(); // Read in the Bytes

        //Assign the values for the Accelerometer
      accel.x = int(0.8*accel.x + 0.2*(int)((inBuffer[1] << 8) | (inBuffer[0] & 0xff)));
      accel.y = int(0.8*accel.y + 0.2*(int)((inBuffer[3] << 8) | (inBuffer[2] & 0xff)));
      accel.z = int(0.8*accel.z + 0.2*(int)((inBuffer[5] << 8) | (inBuffer[4] & 0xff)));

      //Assign the values for the Gyroscope
      gyro.x = int(0.8*gyro.x + 0.2*(int)((inBuffer[7] << 8) | (inBuffer[6] & 0xff)));
      gyro.y = int(0.8*gyro.y + 0.2*(int)((inBuffer[9] << 8) | (inBuffer[8] & 0xff)));
      gyro.z = int(0.8*gyro.z + 0.2*(int)((inBuffer[11] << 8) | (inBuffer[10] & 0xff)));
    }
  }
}

//---------------------------------------------------------
float highestValue = 0;
float lowestValue = 20000;
void drawGraph(int x, int y)
{
  fill(255);
  noStroke();
  text("XBee Nr  "+xbeeAddress, x-width/2+10, y);
  text("Accel X  "+accel.x, x-width/2+10, y+20); 
  rect(x, y+=10, map(accel.x, -32768, +32767, -64, 63), 10);
  text("Accel Y  "+accel.y, x-width/2+10, y+20); 
  rect(x, y+=10, map(accel.y, -32768, +32767, -64, 63), 10);
  text("Accel Z  "+accel.z, x-width/2+10, y+20); 
  rect(x, y+=10, map(accel.z, -32768, +32767, -64, 63), 10);

  text("Accel Mag  "+accel.mag(), x-width/2+10, y+20);
  /*
  if (accel.mag() > highestValue) { 
    highestValue = accel.mag();
  }
  println("highestValue  "+highestValue);
  if (accel.mag() < lowestValue) { 
    lowestValue = accel.mag();
  }
  println("lowestValue  "+lowestValue);
  */
  
  y+=20;
  text("Gyro X  "+gyro.x, x-width/2+10, y+20); 
  rect(x, y+=10, map(gyro.x, -32768, +32767, -64, 63), 10);
  text("Gyro Y  "+gyro.y, x-width/2+10, y+20); 
  rect(x, y+=10, map(gyro.y, -32768, +32767, -64, 63), 10);
  text("Gyro Z  "+gyro.z, x-width/2+10, y+20); 
  rect(x, y+=10, map(gyro.z, -32768, +32767, -64, 63), 10);

  text("Gyro Mag  "+gyro.mag(), x-width/2+10, y+20);

  y+=20;
  text("Moving: "+(inMove ? "true" : "false"), x-width/2+10, y+20);
}

//---------------------------------------------------------
void keyPressed()
{
  switch(key)
  {
  case 'a':
    myMidiBus.sendNoteOff(0, 31, 127 );
    break;
  case 'c':

    break;
  }
}




