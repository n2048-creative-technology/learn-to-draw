const express = require('express');
const router = express.Router();
const dbo = require('../db/connection');

router.get('/', (req, res) => {
  res.json({
    message: 'API'
  });
});
  
router.post('/drawing', (req, res) => {
  const dbConnect = dbo.getDb();
  
  const drawingDocument = {
    created: new Date(),
    author: req.body.author,
    drawing: req.body.drawing,
  };

  dbConnect
    .collection('drawings')
    .insertOne(drawingDocument, function (err, result) {
      if (err) {
        res.status(400).send('Error inserting drawing!');
      } else {
        res.status(204).json({
          message: 'Drawing saved!',
          data: drawingDocument
        });
      }
    });
});


module.exports = router;
