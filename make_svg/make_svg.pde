import processing.svg.*;

JSONArray list;
PGraphics svg;

void setup() {
  size(100, 100);
  stroke(0);
  noLoop();
  list= loadJSONArray("https://draw.neurohub.io/api/list");
  loop();
}

JSONObject loadDrawing(String drawingId) {
  println("https://draw.neurohub.io/api/drawings/" + drawingId);
  JSONObject drawing = loadJSONObject("https://draw.neurohub.io/api/drawings/" + drawingId); 
  return drawing;
}

void drawStrokes(JSONArray strokes) {
  for (int j = 0; j < strokes.size(); j++) {
    JSONObject stroke = strokes.getJSONObject(j);
    //String strokeId = stroke.getString("strokeId");      
    int strokeColor = color(
      stroke.getJSONArray("color").getInt(0), 
      stroke.getJSONArray("color").getInt(1), 
      stroke.getJSONArray("color").getInt(2), 
      stroke.getJSONArray("color").getInt(3)
      );

    svg.stroke(strokeColor);

    JSONArray points = stroke.getJSONArray("points");

    svg.beginShape();

    for (int k = 0; k < points.size(); k++) {
      JSONObject point = points.getJSONObject(k);
      int x = point.getInt("x");
      int y = point.getInt("y");
      //float pressure = point.getFloat("pressure");
      svg.curveVertex(x, y);
    }

    svg.endShape();
  }
}
void draw() {

  for (int i = 0; i < list.size(); i++) {

    String drawingId = list.getString(0);

    println("https://draw.neurohub.io/api/drawings/" + drawingId);
    JSONObject drawing = loadDrawing(drawingId);
    JSONArray strokes = drawing.getJSONArray("strokes");

    svg = createGraphics(drawing.getInt("width"), drawing.getInt("height"), SVG, "./svg/"+drawingId+".svg");
    svg.beginDraw();
    svg.background(255);

    drawStrokes(strokes);

    svg.dispose();
    svg.endDraw();
  }
}
