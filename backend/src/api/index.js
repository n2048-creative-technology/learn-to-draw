const express = require('express');
const router = express.Router();
const dbo = require('../db/connection');
const { parse } = require('json2csv');

const DB_NAME = process.env.DB_NAME || 'drawings'

router.get('/', (req, res) => {
  res.json({
    message: 'API'
  });
});
  
router.put('/drawings/:drawingId', (req, res) => {
  const dbConnect = dbo.getDb();
  
  const drawingDocument = req.body;

  dbConnect
    .collection(DB_NAME)
    .findOneAndUpdate({
        drawingId: req.params.drawingId
      }, 
      { $set: drawingDocument}, { new:true, upsert: true }, function (err, result) {
      if (err) {
        res.status(400).send('Error inserting drawing!');
      } else {
        res.status(200).json({
          message: 'Drawing saved!',
          data: drawingDocument
        });
      }
    });
});

router.get('/drawings', (req, res) => {
  const dbConnect = dbo.getDb();
  
  const drawingDocument = req.body;

  dbConnect
    .collection(DB_NAME)
    .find({}).toArray(function (err, result) {
      if (err) {
        res.status(400).send('Error inserting drawing!');
      } else {
        res.status(200).json(result.map(d=>{
          delete d._id; return d;
        }));
      }
    });
});

router.get('/random', (req, res) => {
  const dbConnect = dbo.getDb();
  
  const drawingDocument = req.body;

  dbConnect
    .collection(DB_NAME)
    .find({}).toArray(function (err, result) {
      if (err) {
        res.status(400).send('Error inserting drawing!');
      } else {
        const count = result.length;
        const r = Math.floor(Math.random()*count);
        const drawing = result[r];
        delete drawing._id;
        res.status(200).json(drawing);
      }
    });
});


router.get('/drawings/:drawingId', (req, res) => {
  const dbConnect = dbo.getDb();

  const drawingDocument = req.body;

  dbConnect
    .collection(DB_NAME)
    .findOne({ drawingId: req.params.drawingId }, function (err, result) {
      if (err) {
        res.status(400).send('Error inserting drawing!');
      } else {
        delete result._id;
        if(req.query.csv){

          const fields = [
          'ts', 'x', 'y', 
          'dt', 'dx', 'dy', 
          'pressure',
           // 'red', 'green', 'blue', 
           'pen_down', 'pen_up'];
          const opts = { fields };

          strokes = result.strokes.map(
              stroke => {
                x = stroke.points[0].x;
                y = stroke.points[0].y;
                t = stroke.points[0].timestamp;
                let num = stroke.points.length-1;
                return stroke.points.map( 
                  (point, n) => {
                    return {
                      ts: point.timestamp,    // timestamp of point
                      x: point.x,            // absolute coordinates on canvas
                      y: point.y,            // absolute coordinates on canvas
                      dt: point.timestamp-t,  // delta time since last point
                      dx: point.x-x,          // horizontal distance from last point 
                      dy: point.y-y,          // vertical distance from last point
                      pressure: point.pressure,     // point pressure
                      //red: stroke.color[0],    // Red
                      //green: stroke.color[1],    // Green
                      //blue: stroke.color[2],    // Blue
                      pen_down: n===0?1:0,          // stroke start
                      pen_up: n===num?1:0,        // stroke end
                    };                    
                  }
                )
              }
            ).flat();

          const csv = parse(strokes, opts);
          console.log(csv);
          res.type('text/csv');
          res.status(200).send(csv);
        }
        else {
          res.status(200).json(result);
        }
      }
    });
});

module.exports = router;
