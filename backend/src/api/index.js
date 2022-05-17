const express = require('express');
const router = express.Router();
const dbo = require('../db/connection');

const DB_NAME = process.env.DB_NAME || 'drawings'

router.get('/', (req, res) => {
  res.json({
    message: 'API'
  });
});
  
router.post('/drawing', (req, res) => {
  const dbConnect = dbo.getDb();
  
  const drawingDocument = req.body;

  dbConnect
    .collection(DB_NAME)
    .insertOne(drawingDocument, function (err, result) {
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
        res.status(200).json(result);
      }
    });
});

module.exports = router;
