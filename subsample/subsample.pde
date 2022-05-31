import processing.svg.*;

Table table;
JSONArray list;
PGraphics pg;
PGraphics svg;

void setup() {
  size(64, 64);
  table = new Table();

  table.addColumn("drawingId");
  table.addColumn("strokeId");

  for (int y = 0; y<height; y++) {
    for (int x = 0; x<width; x++) {
      int idx = x+y*width;
      table.addColumn("pos_"+idx);
    }
  }

  list= loadJSONArray("https://draw.neurohub.io/api/list");  
  for (int i = 0; i < list.size(); i++) {

    String drawingId = list.getJSONObject(i).getString("drawingId");

    JSONObject drawing = loadDrawing(drawingId);

    svg = createGraphics(drawing.getInt("width"), drawing.getInt("height"), SVG, "./svg/"+drawingId+".svg");
    svg.beginDraw();
    svg.background(255);

    JSONArray strokes = drawing.getJSONArray("strokes");
    drawStrokes(strokes, drawingId, drawing.getInt("width"), drawing.getInt("height"));

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

void drawStrokes(JSONArray strokes, String drawingId, int w, int h) {
  background(255);
  for (int j = 0; j < strokes.size(); j++) {
    JSONObject stroke = strokes.getJSONObject(j);
    String strokeId = stroke.getString("strokeId");      

    int strokeColor = color(
      stroke.getJSONArray("color").getInt(0), 
      stroke.getJSONArray("color").getInt(1), 
      stroke.getJSONArray("color").getInt(2), 
      stroke.getJSONArray("color").getInt(3)
      );

    svg.stroke(strokeColor);

    pg = createGraphics(w, h);
    pg.beginDraw();
    //pg.background(255);

    pg.stroke(strokeColor);

    JSONArray points = stroke.getJSONArray("points");
    svg.beginShape();

    pg.beginShape();

    for (int k = 0; k < points.size(); k++) {
      JSONObject point = points.getJSONObject(k);
      int x = point.getInt("x");
      int y = point.getInt("y");
      //float pressure = point.getFloat("pressure");
      //svg.strokeWeight(point.getFloat("pressure"));
      pg.curveVertex(x, y);
      svg.curveVertex(x, y);
    }
    svg.endShape();

    pg.endShape();

    pg.dispose();
    pg.endDraw();

    // At this point, the input is the pixels, plus all the strokes untill now (minus the last stroke)
    // The output is the last stroke

    loadPixels();

    TableRow newRow = table.addRow();
    newRow.setString("drawingId", drawingId);
    newRow.setString("strokeId", strokeId);
    for (int p=0; p< pixels.length; p++) {
      int r = pixels[p] >> 16 & 0xFF;
      newRow.setInt("pos_" +p, r < 100?1:0);
    }
    saveTable(table, "data/strokes.csv");

    pg.filter(THRESHOLD, .5);
    for (int e=0; e < 100; e++) {
      pg.filter(ERODE);
    }

    image(pg, 0, 0, width, height);
    save("png/" + drawingId + "/" + j + "-" + strokeId + ".png");
  }
}
