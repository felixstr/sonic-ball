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

//------------------ End Record Movements --------------------
void setup()
{
  size(500, 500);

  println(Serial.list()); // Prints the list of serial available devices (Arduino should be on top of the list)
  myXbeePort = new Serial(this, "/dev/tty.Bluetooth-Incoming-Port", 38400); // Open a new port and connect with Arduino at 38400 baud
  myXbeePort.buffer(22);

  MidiBus.list(); // List all available Midi devices
  myMidiBus = new MidiBus(this, "", "P5toMIDI"); //Mac
}

void draw()
{
  background(0);
  drawGraph(width/2, 10);
  myMidiBus.sendControllerChange(1, 20, int(map(gyro.y, -32768, +32767, 0, 127)));
  
  
  checkMove(); // is ball moving? (inMove)
  if (inMove) {
    record();
  } else {
    play();
  }
}

int lastMoveStatus = 0;
boolean  inMoveLast = false;
boolean  moveChangeFlag = true;
boolean change = false;






void checkMove() {
  float mag = gyro.mag();
  println(mag);
  
  boolean inMoveCurrent = (mag > 300);
  inMove = inMoveCurrent;
  
  /*
  boolean inMoveCurrent = (mag > 5000);
  println("inMoveCurrent: "+inMoveCurrent);
  println("inMove: "+inMove);
  
  if ((inMoveLast && !inMoveCurrent) || (!inMoveLast && inMoveCurrent)) {
    change = true;
    lastMoveStatus = millis();
  }
  println("lastMoveStatus: "+lastMoveStatus);
  println("change: "+change);
  
  if (((millis() - lastMoveStatus) > 5000) && change) {
    inMove = !inMove;
    change = false;
  }
  
  inMoveLast = inMoveCurrent;
  */
}

void record() {
  
  if(trackMillis == true){
    m = 0;
    m = millis();
    trackMillis = false;
  }
  
  if(m + 1 == millis()){
    gyroMagni.add(gyro.mag());
    accelMagni.add(accel.mag()); 
   trackMillis = false;
  }
  
  
  

}

void play() {}

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

void keyPressed()
{
  switch(key)
  {
  case 'a':
    myMidiBus.sendNoteOn(1, 64, 127); // Send a Midi noteOn
    myMidiBus.sendNoteOff(1, 64, 127); // Send a Midi noteOn
    break;
  case 'c':

    break;
  }
}






