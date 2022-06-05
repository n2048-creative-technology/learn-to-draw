import java.io.InputStreamReader;
import processing.serial.*;      

// Constants
String drawingId = "0c23af0d-7dba-4e19-bc26-f095efef2c22";
boolean debug_on = false;            
boolean holdPenUp = false; // set to true to test drawing without pushing the pen            

boolean previewOnly = false; // outline drawing Canvas
boolean drawPreview = false; // actually draw canvas borders;

float canvasWidth_cm = 88;
float canvasHeight_cm = 75;
float canvasXOffset_cm = 104; //18; // 104
float canvasYOffset_cm = 46;

float mx = 7.35;
float nx = 1080;

float my = 12.5;
float ny = -850;


//float canvasWidth = mx*canvasWidth_cm+nx;
//float canvasHeight = my*canvasHeight_cm+ny;
//float canvasXOffset = mx*canvasXOffset_cm+nx;
//float canvasYOffset = my*canvasYOffset_cm+ny;

float canvasWidth = 400;
float canvasHeight = 250;
float canvasXOffset = 450;
float canvasYOffset = 200;

// 
JSONObject drawing;
PGraphics svg;
int drawingWidth, drawingHeight;

// Plotter:

float maxX = 1700;
float maxY = 1400;
float maxZ = 10;

// ---------------------------------------------------
// DEFINITIONS
// ---------------------------------------------------
// ----- create port object
Serial port;                        //create object from Serial class

// ----- flow control codes
final char XON = 0x11;              //plotter requests more code
final char XOFF= 0x13;              //stop sending code to plotter

float curX = 0;
float curY = 0;

// ----- flags
boolean ok_to_send = true;
boolean pen_down = false;
boolean homed = false;
boolean initialized = false;

String plotterResponse = "";

/// 

void setup() {
  runPython();

  size(850, 700); 

  // plotter setup
  if (debug_on) {
    printArray(Serial.list());
  }
  String plotter_port = Serial.list()[2];
  println(plotter_port);

  if (!debug_on) {
    port = new Serial(this, plotter_port, 115200);
    port.clear();
  }
  clear();
  //

  drawing = loadJSONObject("https://draw.neurohub.io/api/drawings/"+drawingId);  

  drawingWidth = drawing.getInt("width");
  drawingHeight = drawing.getInt("height");

  while (!debug_on && (!initialized || !homed)) {
    delay(100);
  }

  if (previewOnly) {
    while (true) {
      // outline Image Borders:
      preview();
    }
  } else {
    JSONArray strokes = drawing.getJSONArray("strokes");
    drawStrokes(strokes);
  }
  exit();
}

void drawStrokes(JSONArray strokes) {
  for (int j = 0; j < strokes.size(); j++) {
    JSONObject stroke = strokes.getJSONObject(j);
    String strokeId = stroke.getString("strokeId");      
    println("strokeId", strokeId);

    JSONArray points = stroke.getJSONArray("points");

    JSONObject point = points.getJSONObject(0);
    float x = point.getFloat("x");
    float y = point.getFloat("y");

    x = x*canvasWidth/drawingWidth + canvasXOffset;
    y = y*canvasHeight/drawingHeight + canvasYOffset;


    // bring the peen to start position.
    delay(200);
    penUp();
    delay(200);    
    goToPos(x, y);
    delay(200);
    penDown();
    delay(200);


    for (int k = 0; k < points.size(); k++) {
      point = points.getJSONObject(k);
      x = point.getFloat("x");
      y = point.getFloat("y");
      x = x*canvasWidth/drawingWidth + canvasXOffset;
      y = y*canvasHeight/drawingHeight + canvasYOffset;
      goToPos(x, y);
    }

    delay(200);
    penUp();
  }
}

void penDown() {
  if (holdPenUp) return;
  // tell motors to stay powered on hold position
  sendCommand("$1=255");
  sendCommand("z10");
  pen_down = true;
  delay(300);    //debounce delay
}
void penUp() {
  if (holdPenUp) return;
  sendCommand("$1=25");
  sendCommand("z0");
  pen_down = false;
  delay(300);    //debounce delay
}

void serialEvent (Serial port) {
  char letter = port.readChar();
  plotterResponse = plotterResponse + letter;
  if (letter == XON) ok_to_send = true;      //plotter ready for next command
  //print(letter);                            //echo character from arduino

  if (letter == '\n') {

    if (plotterResponse.indexOf("ok")>-1) {
      ok_to_send = true;
    }

    if (plotterResponse.indexOf("MPos:") > 0) {
      // parse current position:
      String[] coords = plotterResponse.split(":")[1].split(",");
      curX = float(coords[0]);
      curY = float(coords[1]);
      println(curX, curY);
      ok_to_send = true;
    }

    println(plotterResponse);
    plotterResponse = "";
  }

  if (!initialized && letter == '$') {
    init();
  }
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
  delay(200); // debounce
  penUp();
  delay(200); // debounce
  sendCommand("$H");
  curX = 0;
  curY = 0;
  homed=true;
}

void sendCommand(String command) {
  if (debug_on) return;
  ok_to_send = false;    
  for (int i = 0; i < (command.length()); i++) { 
    port.write(command.charAt(i));
    print(command.charAt(i));
  }
  port.write('\n');
  println();
  port.clear(); //clear transmit buffer
}

void goToPos(float _x, float _y) {
  float x = (constrain(_x, 0, drawingWidth)/drawingWidth-1)*maxX;
  float y = (-constrain(_y, 0, drawingHeight)/drawingHeight)*maxY;

  sendCommand("x"+x+"y"+y);

  if (debug_on) {
    curX=x;
    curY=y;
  }

  float distance_to_target = (curX - x)*(curX - x)+(curY - y)*(curY - y);
  while (distance_to_target > 1) { 
    println("distance = ", distance_to_target);
    getCurPoss();
    distance_to_target = (curX - x)*(curX - x)+(curY - y)*(curY - y);
    delay(10);
  }
  ok_to_send = true;
  println("just arrived!");
}

void getCurPoss() {
  sendCommand("?");
}

void runPython() {
  String cmd[] = {"/Users/mauricio/dogtime/learn-to-draw/drawing_to_gcode/test.py"};
  StringBuffer cmd_buffer = new StringBuffer();
  for (int i = 0; i < cmd.length; i++) {
    cmd_buffer.append(cmd[i]+" ");
  }
  println(cmd_buffer.toString());

  ProcessBuilder pb = new ProcessBuilder(cmd);
  pb.inheritIO();

  try {
    Process process = pb.start();
    InputStream inputStream = process.getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
    String res = "";
    while ((res = reader.readLine()) != null) {
      // This part get's printed in the Procesisng IDE's console, why?
      println(res);
    }
    int exitVal = process.waitFor();
    // While this part get's printed in the Procesisng Sketch's console (as made to run)
    println(exitVal);
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

void waitForOK() {
  print("waiting");
  while (!ok_to_send) {
    delay(100);
    print(".");
  }
  println();
}

//outline image Borders
void preview() {

  println("1", canvasWidth + canvasXOffset, canvasYOffset);
  goToPos(canvasWidth + canvasXOffset, canvasYOffset);

  delay(1000);
  println("2", canvasWidth + canvasXOffset, canvasHeight + canvasYOffset);
  goToPos(canvasWidth + canvasXOffset, canvasHeight + canvasYOffset);

  delay(1000);
  println("3", canvasXOffset, canvasHeight + canvasYOffset);
  goToPos(canvasXOffset, canvasHeight + canvasYOffset);  

  delay(1000);
  println("4", canvasXOffset, canvasYOffset);
  goToPos(canvasXOffset, canvasYOffset);
  delay(1000);
}
