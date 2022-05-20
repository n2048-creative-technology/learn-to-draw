// Apple Pencil demo using Pressure.js

// Alternative method: https://github.com/quietshu/apple-pencil-safari-api-test

// If you want to go deeper into pointer events
// https://patrickhlauke.github.io/touch/
// https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/pressure


/***********************
*       SETTINGS       *
************************/

// How sensitive is the brush size to the pressure of the pen?
var pressureMultiplier = 10;

// What is the smallest size for the brush?
var minBrushSize = 1;

// Higher numbers give a smoother stroke
var brushDensity = 5;

var showDebug = false;

// Jitter smoothing parameters
// See: http://cristal.univ-lille.fr/~casiez/1euro/
var minCutoff = 0.0001; // decrease this to get rid of slow speed jitter but increase lag (must be > 0)
var beta      = 1.0;  // increase this to get rid of high speed lag

// const API_URL = 'http://localhost:3000';
const API_URL = 'https://draw.neurohub.io/api';
// const API_URL = '/api';

/***********************
*       GLOBALS        *
************************/
var xFilter, yFilter, pFilter;
var inBetween;
var prevPenX = 0;
var prevPenY = 0;
var prevBrushSize = 1;
var amt, x, y, s, d;
var pressure = -2;
var drawCanvas, uiCanvas;
var isPressureInit = false;
var isDrawing = false;
var isDrawingJustStarted = false;


/***************************
*   Drawing data points    *
****************************/

class Sketch {
  drawingId;
  timestamp;
  author;
  strokes;
  width;
  height;
  constructor(author, width, height){
    this.drawingId = generateUUID();
    this.timestamp = Date.now();
    this.strokes = [];
    this.setAuthor(author);
    this.width = width;
    this.height = height;
  }
  addStroke(stroke){
    this.strokes.push(stroke);
  }
  setAuthor(author){
    this.author = author.toLowerCase();
  }
  getAuthor(){
    return this.author;
  }
}
class Stroke {
  strokeId;
  color;
  points;
  constructor(color){
    this.strokeId = generateUUID();   
    this.color = color;
    this.points = [];
  }
  addPoint(point){
    this.points.push(point);
  }
}
class Point {
  timestamp;
  x;
  y;
  pressure;  
  constructor(x,y,pressure){
    this.timestamp = Date.now();
    this.x = x;
    this.y = y;
    this.pressure = pressure;
  }
}

let sketch;
let stroke;

/***********************
*      UI BUTTONS      *
************************/
let clearButton;
let loadImageButton;
let saveButton;
let colorPicker;
let author = '';

/***********************
*    DRAWING CANVAS    *
************************/
new p5(function(p) {

  p.setup = function() {

    // Filters used to smooth position and pressure jitter
    xFilter = new OneEuroFilter(60, minCutoff, beta, 1.0);
    yFilter = new OneEuroFilter(60, minCutoff, beta, 1.0);
    pFilter = new OneEuroFilter(60, minCutoff, beta, 1.0);

    // prevent scrolling on iOS Safari
    disableScroll();

    //Initialize the canvas
    drawCanvas = p.createCanvas(p.windowWidth, p.windowHeight);
    drawCanvas.id("drawingCanvas");
    drawCanvas.position(0, 0);
    p.background(255);

    p.frameRate = 60;

  }

  drawPoint = function(penX, penY,pressure, loading=false){
    // Start Pressure.js if it hasn't started already
    if(isPressureInit == false){
      initPressure();
    }

    if(isDrawing) {
 
       // What to do on the first frame of the stroke
      if(isDrawingJustStarted) {
        //console.log("started drawing");
        prevPenX = penX;
        prevPenY = penY;
      }

      // Define the current brush size based on the pressure
      brushSize = minBrushSize + (pressure * pressureMultiplier);

      // Calculate the distance between previous and current position
      d = p.dist(prevPenX, prevPenY, penX, penY);

      // The bigger the distance the more ellipses
      // will be drawn to fill in the empty space
      inBetween = (d / p.min(brushSize,prevBrushSize)) * brushDensity;

      // Add ellipses to fill in the space
      // between samples of the pen position
      for(i=1;i<=inBetween;i++){
        amt = i/inBetween;
        s = p.lerp(prevBrushSize, brushSize, amt);
        x = p.lerp(prevPenX, penX, amt);
        y = p.lerp(prevPenY, penY, amt);
        p.noStroke();
        p.fill(colorPicker.color());
        p.ellipse(x, y, s);
      }

      // Draw an ellipse at the latest position
      p.noStroke();
      p.fill(colorPicker.color())
      p.ellipse(penX, penY, brushSize);

      // Save the latest brush values for next frame
      prevBrushSize = brushSize;
      prevPenX = penX;
      prevPenY = penY;

      if(!loading){
        let point = new Point(p.mouseX, p.mouseY, pressure);
        stroke.addPoint(point);  
      }
      isDrawingJustStarted = false;
    }
  }

  p.draw = function() {
    // Smooth out the position of the pointer
    penX = xFilter.filter(p.mouseX, p.millis());
    penY = yFilter.filter(p.mouseY, p.millis());

    // Smooth out the pressure
    pressure = pFilter.filter(pressure, p.millis());

    drawPoint(penX, penY, pressure);
    // drawPoint(p.mouseX, p.mouseY, pressure);
  }
}, "p5_instance_01");


/***********************
*      UI CANVAS       *
************************/
new p5(function(p) {

  	p.setup = function() {
      uiCanvas = p.createCanvas(p.windowWidth, p.windowHeight);
      uiCanvas.id("uiCanvas");
      uiCanvas.position(0, 0);

      clearButton = p.createButton('Clear');
      clearButton.position(10, 10);
      clearButton.mousePressed(loadNew);

      saveButton = p.createButton('Save');
      saveButton.position(70, 10);
      saveButton.mousePressed(save);

      // loadImageButton = p.createButton('Load Image');
      // loadImageButton.position(190, 10);
      // loadImageButton.mousePressed(loadBackgroundImage);

      changeAuthorButton = p.createButton('Change Author');
      changeAuthorButton.position(290, 10);
      changeAuthorButton.mousePressed(changeAuthor);

      colorPicker = p.createColorPicker('#000000');
      colorPicker.position(p.windowWidth - 200, 5);

      p.text("test", 500, 60);

      clearCanvas();

      sketch = new Sketch(author, p.windowWidth, p.windowHeight);

      const id = location.search.split('id=')[1];
      if(id) loadFromId(id);

      if(location.search.indexOf('random')!=-1){
        loadRandom();
      }
    }

    changeAuthor = function() {
      author = prompt("What's your e-mail address");
      sketch.setAuthor(author);
    }

    loadBackgroundImage = function(){

    }

    loadRandom = function () {
      let intervalMS = 3000;
      fetch(`${API_URL}/random/`, {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
          }
        }).then(async function(response) {
          if(response.ok) {
            const data = await response.json();
            drawData(data);
            setInterval(loadRandom, intervalMS);
            return;
          }          
          setInterval(loadRandom, intervalMS);
          // throw new Error('Request failed.');
        }).catch(function(error) {
          alert('There was a problem fetching the drawing.');
          console.log(error);
          setInterval(loadRandom, intervalMS);
        });
    }
    
    loadFromId = function(id){
      fetch(`${API_URL}/drawings/${id}`, {
          method: 'GET',
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
          }
        }).then(async function(response) {
          if(response.ok) {
            const data = await response.json();
            drawData(data);
            return;
          }
          throw new Error('Request failed.');
        }).catch(function(error) {
          alert('There was a problem fetching the drawing.');
          console.log(error);
        });
    }

    drawData = function(data) {
      clearCanvas();
      sketch = new Sketch(data.author, data.width, data.height);
      sketch.drawingId = data.drawingId;
      sketch.timestamp = data.timestamp;
      data.strokes.forEach(s => {
        // console.log(stroke);
        const stroke = new Stroke(s.color);
        stroke.strokeId = s.strokeId;
        s.points.forEach(point => {
          const p =  new Point(point.x, point.y, point.pressure);
          p.timestamp = point.timestamp;
          stroke.addPoint(p);
        });
          sketch.addStroke(stroke);
        drawStroke(stroke);
      })
      console.log(sketch);
    }

    drawStroke = function(stroke) {
      isDrawing = true;
      isDrawingJustStarted = true;
      stroke.points.forEach(point => {
        drawPoint(point.x, point.y, point.pressure, true);
        isDrawingJustStarted = false;        
      });
      isDrawing = false;
      // p.resizeCanvas(p.windowWidth, p.windowHeight);
      p.updatePixels();
    }

    save = function() {
      console.log("saving current drawing.")

      fetch(`${API_URL}/drawings/${sketch.drawingId}`, {
          method: 'PUT',
          body: JSON.stringify(sketch),
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json'
          }
        }).then(function(response) {
          if(response.ok) {
            console.log('Drawing was added to the DB.');
            alert('Drawing saved!');            
            return;
          }
          throw new Error('Request failed.');
        }).catch(function(error) {
          alert('There was a problem saving the drawing. Try again!');
          console.log(error);
        });
      }

    loadNew = function(){
      location.search='';      
    }
    clearCanvas = function(){
      drawCanvas.clear();
      uiCanvas.clear();
    }

  	p.draw = function() {

      uiCanvas.clear();
      p.text(sketch.getAuthor(), 420, 25);

      p.fill(colorPicker.color());

      if(showDebug){
        p.text("pressure = " + pressure, 10, 60);

        var w = p.width * pressure;

        p.fill(0)
        p.stroke(0);
        p.rect(0, 0, w, 4);
      }
    }


}, "p5_instance_02");


/***********************
*       UTILITIES      *
************************/


function generateUUID() { // Public Domain/MIT
    var d = new Date().getTime();//Timestamp
    var d2 = ((typeof performance !== 'undefined') && performance.now && (performance.now()*1000)) || 0;//Time in microseconds since page-load or 0 if unsupported
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16;//random number between 0 and 16
        if(d > 0){//Use timestamp until depleted
            r = (d + r)%16 | 0;
            d = Math.floor(d/16);
        } else {//Use microseconds since page-load if supported
            r = (d2 + r)%16 | 0;
            d2 = Math.floor(d2/16);
        }
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
}

// Initializing Pressure.js
// https://pressurejs.com/documentation.html
function initPressure() {

  	//console.log("Attempting to initialize Pressure.js ");

    Pressure.set('#uiCanvas', {

      start: function(event){
        // this is called on force start
        isDrawing = true;
        isDrawingJustStarted = true;
        stroke = new Stroke(colorPicker.color().levels);
  		},
      end: function(){
        if(isDrawing) sketch.addStroke(stroke);
        isDrawing = false
        pressure = 0;
  		},
      change: function(force, event) {
        if (isPressureInit == false){
          console.log("Pressure.js initialized successfully");
	        isPressureInit = true;
      	}
        //console.log(force);
        pressure = force;

      }
    });

    Pressure.config({
      polyfill: true, // use time-based fallback ?
      polyfillSpeedUp: 1000, // how long does the fallback take to reach full pressure
      polyfillSpeedDown: 300,
      preventSelect: true,
      only: null
 		 });

}

// Disabling scrolling and bouncing on iOS Safari
// https://stackoverflow.com/questions/7768269/ipad-safari-disable-scrolling-and-bounce-effect

function preventDefault(e){
    e.preventDefault();
}

function disableScroll(){
    document.body.addEventListener('touchmove', preventDefault, { passive: false });
}
/*
function enableScroll(){
    document.body.removeEventListener('touchmove', preventDefault, { passive: false });
}*/
