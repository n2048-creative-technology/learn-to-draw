const express = require('express');
const morgan = require('morgan');
const helmet = require('helmet');
const cors = require('cors');
const bodyParser = require('body-parser');

const dbo = require('./db/connection');
dbo.connectToServer();

require('dotenv').config();

process.env.PORT 

const middlewares = require('./middlewares');
const api = require('./api');

const app = express();

app.use(bodyParser.json({
  limit: '1000mb',
}));

app.use(bodyParser.urlencoded({
  limit: '1000mb',
  parameterLimit: 100000,
  extended: true 
}));

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

app.use('/', api);

app.use(middlewares.notFound);
app.use(middlewares.errorHandler);

module.exports = app;
