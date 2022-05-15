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

let currentDrawing = []; // this array stores a collection of strokes 
let currentStroke  = []; // each stroke is a coection of (x,y,pressure) sampled dover time

/***********************
*      UI BUTTONS      *
************************/
let clearButton;
let loadImageButton;
let saveAndClearButton;


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

    p.frameRate = 30;
  }

  p.draw = function() {

    // Start Pressure.js if it hasn't started already
    if(isPressureInit == false){
      initPressure();
    }


    if(isDrawing) {
      // Smooth out the position of the pointer
      penX = xFilter.filter(p.mouseX, p.millis());
      penY = yFilter.filter(p.mouseY, p.millis());

      // What to do on the first frame of the stroke
      if(isDrawingJustStarted) {
        //console.log("started drawing");
        prevPenX = penX;
        prevPenY = penY;
      }

      // Smooth out the pressure
      pressure = pFilter.filter(pressure, p.millis());

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
        p.fill(100)
        p.ellipse(x, y, s);
      }

      // Draw an ellipse at the latest position
      p.noStroke();
      p.fill(100)
      p.ellipse(penX, penY, brushSize);

      // Save the latest brush values for next frame
      prevBrushSize = brushSize;
      prevPenX = penX;
      prevPenY = penY;

      currentStroke.push([Date.now(), p.mouseX, p.mouseY, pressure]);

      isDrawingJustStarted = false;
    }

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
      clearButton.mousePressed(clearCanvas);

      saveAndClearButton = p.createButton('Save and Clear');
      saveAndClearButton.position(70, 10);
      saveAndClearButton.mousePressed(saveAndCear);

      loadImageButton = p.createButton('Load Image');
      loadImageButton.position(190, 10);
      loadImageButton.mousePressed(loadBackgroundImage);

      p.noStroke();
      p.fill(100)
    }

    loadBackgroundImage = function(){

    }

    saveAndCear = function() {
      // save currentDrawing data
      // ... 
      console.log("saving current drawing.")

      // add (0,0,0) as separator
      // let drawing = currentDrawing.reduce((r,a) => r.concat(a,Array([0,0,0,0])));
      let drawing = currentDrawing.reduce((r,a) => r.concat(a,"SEPARATOR"));

      console.log(currentDrawing);
      // console.log(drawing.join());

      // # Download image and text;
      // p.saveCanvas(drawCanvas, 'myDrawing', 'jpg');
      // let writer = p.createWriter('myDrawing.txt');
      // writer.write(drawing.flat());
      // writer.close();

      clearCanvas();
    }

    clearCanvas = function(){
      drawCanvas.clear();
      uiCanvas.clear();
      currentDrawing = [];
      currentStroke = [];
    }

  	p.draw = function() {

      uiCanvas.clear();

      if(showDebug){
        p.text("pressure = " + pressure, 10, 20);

        // p.stroke(200,50);
        // p.line(p.mouseX,0,p.mouseX,p.height);
        // p.line(0,p.mouseY,p.width,p.mouseY);

        // p.noStroke();
        // p.fill(100)
        var w = p.width * pressure;
        p.rect(0, 0, w, 4);
      }
    }


}, "p5_instance_02");


/***********************
*       UTILITIES      *
************************/

// Initializing Pressure.js
// https://pressurejs.com/documentation.html
function initPressure() {

  	//console.log("Attempting to initialize Pressure.js ");

    Pressure.set('#uiCanvas', {

      start: function(event){
        // this is called on force start
        isDrawing = true;
        isDrawingJustStarted = true;
  		},
      end: function(){
    		// this is called on force end
        if(isDrawing){
          currentDrawing.push([Date.now(),currentStroke]);
          currentStroke = [];
          // console.log(currentDrawing);
        }
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
