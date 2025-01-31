import processing.svg.*;

JSONArray list;
PGraphics svg;

void setup() {
  list= loadJSONArray("https://draw.neurohub.io/api/list");  
  for (int i = 0; i < list.size(); i++) {

    String drawingId = list.getJSONObject(i).getString("drawingId");

    JSONObject drawing = loadDrawing(drawingId);

    svg = createGraphics(drawing.getInt("width"), drawing.getInt("height"), SVG, "./svg/"+drawingId+".svg");
    svg.beginDraw();
    svg.background(255);

    JSONArray strokes = drawing.getJSONArray("strokes");
    drawStrokes(strokes);

    svg.dispose();
    svg.endDraw();
  }

  println("goodbye!");
  exit();
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
      //svg.strokeWeight(point.getFloat("pressure"));
      svg.curveVertex(x, y);
    }

    svg.endShape();
  }
}
