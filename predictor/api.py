from flask import Flask, request
from flask_restful import Resource, Api
from json import dumps
from flask.ext.jsonpify import jsonify

app = Flask(__name__)
api = Api(app)

class Simplify(Resource):
    def post(self, data):
        result = {}
        return jsonify(result)

class Expand(Resource):
    def post(self, data):
        result = {}
        return jsonify(result)

class Predict(Resource):
    def posr(self, data):
        result = {}
        return jsonify(result)
        
api.add_resource(Simplify, '/simplify') # Route_1
api.add_resource(Expand, '/expand') # Route_2
api.add_resource(Predict, '/predict') # Route_3

if __name__ == '__main__':
     app.run(port='5002')
     