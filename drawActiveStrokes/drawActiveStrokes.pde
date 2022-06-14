import java.io.InputStreamReader;
import processing.serial.*;      

// Constants
boolean debug_on = false;            
boolean holdPenUp = false; // set to true to test drawing without pushing the pen            
boolean previewOnly = false; // outline drawing Canvas

// measure from the top-right corner (x-stop) 
float canvas_top_right_x_cm = 21;
float canvas_top_right_y_cm = 49;
float canvas_bottom_left_x_cm = 120;
float canvas_bottom_left_y_cm = 104;

// curX and curY values (use the mouse on callibration mode) 
float canvas_top_right_x_pos = -112;
float canvas_top_right_y_pos = -406;
float canvas_bottom_left_x_pos = -940;
float canvas_bottom_left_y_pos = -1117;

float mx = (canvas_bottom_left_x_pos - canvas_bottom_left_x_cm)/(canvas_top_right_x_pos - canvas_top_right_x_cm);
float nx = canvas_bottom_left_x_pos - mx*canvas_bottom_left_x_cm;
float my = (canvas_bottom_left_y_pos - canvas_bottom_left_y_cm)/(canvas_top_right_y_pos - canvas_top_right_y_cm);
float ny = canvas_bottom_left_y_pos - mx*canvas_bottom_left_y_cm;


// Plotter:

float homingSpeed = 800;
float maxX = 1700;
float maxY = 1400;
float maxZ = 10;

//float canvasWidth = 400;
//float canvasHeight = 250;
//float canvasXOffset = 450;
//float canvasYOffset = 200;

float canvasWidth = 900;
float canvasHeight = 450;
float canvasXOffset = 10;
float canvasYOffset = 10;

// 
JSONObject drawing;
PGraphics svg;
float drawingWidth, drawingHeight;


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

JSONArray activeStrokes = new JSONArray();

void setup() {

  //runPython();

  // plotter setup
  if (debug_on) {
    printArray(Serial.list());
  }
  String plotter_port = Serial.list()[3];
  println(plotter_port);

  if (!debug_on) {
    port = new Serial(this, plotter_port, 115200);
    port.clear();
  }
  clear();
  //


  while (!debug_on && (!initialized || !homed)) {
    delay(100);
  }

  if (previewOnly) {
    while (true) {
      // outline Image Borders:

      JSONArray strokes = loadJSONArray("https://flow.neurohub.io/active");
      JSONObject stroke = strokes.getJSONObject(0);
      drawingWidth = stroke.getFloat("width");
      drawingHeight = stroke.getFloat("height");
      preview();
    }
  } else {
    runHomeCycle();
    getDataAndDraw();
  }
  exit();
}


void getDataAndDraw() {
  delay(1000);
  JSONArray strokes;
  
  println("Retrieving simplified strokes... [" + millis() + "]");
  strokes = loadJSONArray("https://flow.neurohub.io/simplified");
  println(strokes.size() + " stroke(s) found in sketch");
  updateStrokes(strokes);

  //println("Retrieving expanded strokes... [" + millis() + "]");
  //strokes = loadJSONArray("https://flow.neurohub.io/expanded");
  //updateStrokes(strokes);

  println("Retrieving predicted strokes... [" + millis() + "]");
  strokes = loadJSONArray("https://flow.neurohub.io/predictions");
  updateStrokes(strokes);

  println(activeStrokes.size() + " active stroke(s)");
  drawStrokes();
  getDataAndDraw();
}

void updateStrokes(JSONArray strokes) {
  for (int i = 0; i < strokes.size(); i++) {
    JSONObject newStroke = strokes.getJSONObject(i);
    String newId = newStroke.getString("strokeId");
    int listed = 0;
    for (int j = 0; j < activeStrokes.size(); j++) {
      JSONObject oldStroke = activeStrokes.getJSONObject(j);
      String oldId = oldStroke.getString("strokeId");      
      if (newId.equals(oldId)) {
        listed ++;
        break;
      }
    }
    if (listed == 0) {
      activeStrokes.append(newStroke);
    }
  }
}

void drawStrokes() {
  for (int j = 0; j < activeStrokes.size(); j++) {
    JSONObject stroke = activeStrokes.getJSONObject(j);
    
    JSONArray points = stroke.getJSONArray("points");
    if (points.size()<1) {
      println("stroke's already plotted");    
      continue;
    }
    String strokeId = stroke.getString("strokeId");      

    drawingWidth = stroke.getFloat("width");
    drawingHeight = stroke.getFloat("height");

    if (points.size()>0) {
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

      stroke.setJSONArray("points", new JSONArray());
      activeStrokes.setJSONObject(j, stroke);
      homed = false;
    }
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
      //println(curX, curY);
      ok_to_send = true;
    }

    //println(plotterResponse);
    plotterResponse = "";
  }

  if (!initialized && letter == '$') {
    init();
  }
}


void init() {
  //delay(500);

  delay(500);
  // set homing speed
  //sendCommand("$24="+homingSpeed); 

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
  if (homed) return;
  println("running home cycle...");
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
    //print(command.charAt(i));
  }
  port.write('\n');
  //println();
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
    //println("distance = ", distance_to_target);
    getCurPoss();
    distance_to_target = (curX - x)*(curX - x)+(curY - y)*(curY - y);
    delay(10);
  }
  ok_to_send = true;
  //println("on target!");
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
  //println(cmd_buffer.toString());

  ProcessBuilder pb = new ProcessBuilder(cmd);
  pb.inheritIO();

  try {
    Process process = pb.start();
    InputStream inputStream = process.getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
    String res = "";
    while ((res = reader.readLine()) != null) {
      // This part get's printed in the Procesisng IDE's console, why?
      //println(res);
    }
    //int exitVal = process.waitFor();
    // While this part get's printed in the Procesisng Sketch's console (as made to run)
    //println(exitVal);
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}

void waitForOK() {
  print("waiting");
  while (!ok_to_send) {
    delay(100);
    //print(".");
  }
  //println();
}

//outline image Borders
void preview() {

  //println("1", canvasWidth + canvasXOffset, canvasYOffset);
  goToPos(canvasWidth + canvasXOffset, canvasYOffset);

  delay(1000);
  //println("2", canvasWidth + canvasXOffset, canvasHeight + canvasYOffset);
  goToPos(canvasWidth + canvasXOffset, canvasHeight + canvasYOffset);

  delay(1000);
  //println("3", canvasXOffset, canvasHeight + canvasYOffset);
  goToPos(canvasXOffset, canvasHeight + canvasYOffset);  

  delay(1000);
  //println("4", canvasXOffset, canvasYOffset);
  goToPos(canvasXOffset, canvasYOffset);
  delay(1000);
}
