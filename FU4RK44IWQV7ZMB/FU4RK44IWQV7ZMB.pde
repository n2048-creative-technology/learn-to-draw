/*
GRBL cheatsheet: 
 https://www.diymachining.com/downloads/GRBL_Settings_Pocket_Guide_Rev_B.pdf
 */


float maxX = 1700;
float maxY = 1400;
float maxZ = 10;

// ---------------------------------------------------
// DEFINITIONS
// ---------------------------------------------------
// ----- create port object
import processing.serial.*;         //library
Serial port;                        //create object from Serial class

// ----- flow control codes
final char XON = 0x11;              //plotter requests more code
final char XOFF= 0x13;              //stop sending code to plotter

float curX = 0;
float curY = 0;

// ----- flags
boolean debug_on = false;            

boolean keyboard_mode = true;       
//true: gcode comes from the keyboard
//false: gcode comes from a file

boolean plotter_paused = true;
//true: keyboard mode
//false: able to plot

boolean ok_to_send = true;
//true: send
//false: waiting for XON character from plotter

boolean pen_down = false;

boolean homed = false;

boolean initialized = false;


// ---------------------------------------------------
// SETUP
// ---------------------------------------------------
void setup() { 

  // ----- create draw window
  size(850, 700); 

  // ----- connect to the arduino
  if (debug_on) {
    printArray(Serial.list());                   //note the array number for your arduino port ...
  }

  String plotter_port = Serial.list()[2];        // ... and change the [2] to match

  println(plotter_port);

  port = new Serial(this, plotter_port, 115200);  // 9600
  //port = new Serial(this, "/dev/tty.usbserial-1410", 115200);
  port.clear();                                  //clear send buffer

  clear();
  background(#D3D3D3);
}

// ---------------------------------------------------
// DRAW (main loop)
// ---------------------------------------------------
void draw() {
  background(255);
  fill(255, 0, 0);
  
  // 0,0 --> with, 0
  // width/2, height/2 --> -maxX/2, -maxY/2
  float x = width+curX*width/maxX;
  float y = -curY*height/maxY;
  ellipse(x, y, 10, 10);
  text("("+curX+", "+ curY+ ")", 20, 30);  
  plotter_paused = true;           //pause plotting
  keyboard_mode = true;

  if (mousePressed && ((mouseButton == RIGHT) || (mouseButton == LEFT))) { 
    plotter_paused = false;           //resume plotting
    keyboard_mode = false;
  }

  //if (ok_to_send && !plotter_paused) {   
  if (!plotter_paused && ok_to_send) {    
    //delay(500);    //debounce delay    
    // ----- send the command to the plotter

    goToPos(mouseX, mouseY);

    println();
    ok_to_send = false;    
    port.clear(); //clear transmit buffer
  }
}

// ---------------------------------------------------
// SERIAL EVENT (called whenever a character arrives)
// ---------------------------------------------------
void serialEvent (Serial port) {
  char letter = port.readChar();
  if (letter == XON) ok_to_send = true;      //plotter ready for next command
  print(letter);                            //echo character from arduino

  if (letter == 'k') {
    ok_to_send = true;
  }
  if (!initialized && letter == '$') {
    init();
  }
}

// ---------------------------------------------------
// KEY PRESSED (called each key press)
// ---------------------------------------------------
void keyPressed() {
  // ----- validate each keypress. Also prevents control characters from showing.
  switch (key) {
  case LEFT: 
    break;
  case RIGHT: 
    break;
  case UP: 
    break;
  case DOWN:
    break;
  case ' ': 
    {
      if (!pen_down) {     
        // tell motors to stay powered on hold position
        sendCommand("$1=255");
        sendCommand("z10");
        pen_down = true;
      } else {
        sendCommand("$1=25");
        sendCommand("z0");
        pen_down = false;
      }
      delay(500);    //debounce delay 
      break;
    }
  case 'H':    
    {
      runHomeCycle();
      break;
    }
  case 'h':    
    {
      runHomeCycle();
      break;
    }
  case 'c':
    {
      goToCenter();
      break;
    }
  case 'C':
    {
      goToCenter();
      break;
    }
  case 'a':
  case 'b': 
  case 'd':
  case 'e': 
  case 'f': 
  case 'g': 
  case 'i': 
  case 'j': 
  case 'k': 
  case 'l': 
  case 'm': 
  case 'n': 
  case 'o': 
  case 'p': 
  case 'q': 
  case 'r': 
  case 's': 
  case 't': 
  case 'u': 
  case 'v': 
  case 'w': 
  case 'x': 
  case 'y': 
  case 'z':
  case 'A': 
  case 'B': 
  case 'D': 
  case 'E': 
  case 'F': 
  case 'G': 
  case 'I': 
  case 'J': 
  case 'K': 
  case 'L': 
  case 'M': 
  case 'N': 
  case 'O': 
  case 'P': 
  case 'Q': 
  case 'R': 
  case 'S': 
  case 'T': 
  case 'U': 
  case 'V': 
  case 'W': 
  case 'X': 
  case 'Y': 
  case 'Z':  
  case '1': 
  case '2': 
  case '3': 
  case '4': 
  case '5': 
  case '6': 
  case '7': 
  case '8': 
  case '9': 
  case '0': 
  case '.':
  case '_': 
  case '-': 
  case '+': 
  case '=': 
  case '$': 
  case '?': 
  case '\\': 
  case '\r':
  case '\n':
    {
      // ----- send each keypress to the plotter
      if (keyboard_mode == true) {
        print(key);
        port.write(key);  //plotter will echo each keypress
      }
    }
  default: 
    {
      break;
    }
  }
}
void goToCenter() {
  goToPos(width/2, height/2);
}
void init() {
  //delay(500);

  delay(500);
  // set max X to 10mm
  sendCommand("$130="+maxX); 
  // set max Z to 10mm
  sendCommand("$131="+maxY); 
  // set max Z to 10mm
  sendCommand("$132="+maxZ); 

  // reverse directions
  sendCommand("$3=2"); 

  delay(500);
  runHomeCycle();
  initialized = true;
}

void runHomeCycle() {

  ok_to_send = false;
  // homing cycle direction
  // reverse x = yes, reverse y = yes, reverse z = no
  delay(500);

  sendCommand("$H");

  curX = 0;
  curY = 0;
  
  homed=true;
  ok_to_send = true;
}

void sendCommand(String command) {
  for (int i = 0; i < (command.length()); i++) { 
    port.write(command.charAt(i));
    print(command.charAt(i));
  }
  port.write('\n');
  println();
  port.clear(); //clear transmit buffer
}

void goToPos(float _x, float _y) {
  float x = (constrain(_x, 0, width)/width-1)*maxX;
  float y = (-constrain(_y, 0, height)/height)*maxY;

  curX = x;
  curY = y;

  sendCommand("x"+x+"y"+y);
}
