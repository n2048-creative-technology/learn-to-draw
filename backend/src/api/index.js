const express = require('express');

const emojis = require('./emojis');

const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    message: 'API'
  });
});


router.post('/drawing', (req, res) => {
  res.json({
    message: 'Drawing saved!',
    data: req.body
  });
});


module.exports = router;
