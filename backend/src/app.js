const express = require('express');
const morgan = require('morgan');
const helmet = require('helmet');
const cors = require('cors');

const dbo = require('./db/connection');

require('dotenv').config();

process.env.PORT 

const middlewares = require('./middlewares');
const api = require('./api');

const app = express();

app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(express.json());

app.use('/', api);

app.use(middlewares.notFound);
app.use(middlewares.errorHandler);

module.exports = app;
