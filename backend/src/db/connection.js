const { MongoClient } = require("mongodb");

const DB_USERNAME = process.env.DB_USERNAME || 'JeWSwxsp5uqerd1p'
const DB_PASWORD = process.env.DB_PASWORD || '8erBv51wLlfDFf7g'
const DB_HOST = process.env.DB_HOST || 'localhost'
const DB_PORT = process.env.DB_PORT || '27017'
const DB_NAME = process.env.DB_NAME || 'drawings'

const connectionString=`mongodb://${DB_USERNAME}:${DB_PASWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?retryWrites=true&w=majority`

const client = new MongoClient(connectionString, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

let dbConnection;

module.exports = {
  connectToServer: function (callback) {
    client.connect(function (err, db) {
      if (err || !db) {
        return callback(err);
      }

      dbConnection = db.db(DB_NAME);
      console.log("Successfully connected to MongoDB.");

      return callback();
    });
  },

  getDb: function () {
    return dbConnection;
  },
};