const { MongoClient } = require("mongodb");

const DB_USERNAME = process.env.DB_USERNAME || null
const DB_PASWORD = process.env.DB_PASWORD || null
const DB_HOST = process.env.DB_HOST || 'localhost'
const DB_PORT = process.env.DB_PORT || '27017'
const DB_NAME = process.env.DB_NAME || 'drawings'
const DB_AUTH = process.env.DB_AUTH || 'admin'

let connectionString = '';
if(DB_USERNAME||DB_PASWORD) {
  connectionString=`mongodb://${DB_USERNAME||''}:${DB_PASWORD||''}@${DB_HOST}:${DB_PORT}/${DB_AUTH}?retryWrites=true&w=majority`
}
else{
  connectionString=`mongodb://${DB_HOST}:${DB_PORT}/${DB_AUTH}?retryWrites=true&w=majority`
}

const client = new MongoClient(connectionString, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

let dbConnection;

module.exports = {
  connectToServer: function () {
    client.connect(function (err, db) {
      if (err || !db) {
        return console.error(err);
      }

      dbConnection = db.db(DB_NAME);
      console.log("Successfully connected to MongoDB.");
    });
  },

  getDb: function () {
    return dbConnection;
  },
};