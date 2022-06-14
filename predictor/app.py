from flask import Flask, request, jsonify, Response
import pandas as pd
import numpy as np
from scipy.interpolate import UnivariateSpline
import json
from json import JSONEncoder
import time
import tensorflow as tf
from tensorflow import keras 

app = Flask(__name__)

model = keras.models.load_model('models/model.h5')

# Expect list of strokes [{strokeId, points:{timestamp, x,y,pressure}...}... ]
# same format as https://flow.neurohub.io/active
# Return list of strokes [{strokeId, points:{timestamp, x,y,pressure}...}... ]
@app.route('/simplify', methods=["POST"])
def add_simplify():
    numPoints = 10;
    data = []
    for stroke in request.json:
        simple_stroke = stroke;
        simple_stroke['points'] = interpolate(stroke['points'], numPoints)
        data.append(simple_stroke);
    
    return Response(json.dumps(data, cls=NumpyArrayEncoder), headers={'Access-Control-Allow-Origin':'*', 'Content-Type':'application/json'});

@app.route('/expand', methods=["POST"])
def add_expand():
    numPoints = 60;
    data = []
    for stroke in request.json:
        expanded_stroke = stroke;
        expanded_stroke['points'] = interpolate(stroke['points'], numPoints)
        data.append(expanded_stroke);
    
    return Response(json.dumps(data, cls=NumpyArrayEncoder), headers={'Access-Control-Allow-Origin':'*', 'Content-Type':'application/json'});



@app.route('/predict', methods=["POST"])
def add_predict():    
    numPoints = 10;  # match NN input layer
    points = [];

    width = 1;
    height = 1;

    data = []
    for stroke in request.json:
        points = interpolate(stroke['points'], numPoints);
        width = stroke['width'];
        height = stroke['height'];
        predicted_stroke = stroke;
        predicted_stroke['points'] = predict(points, width, height, numPoints)
        data.append(predicted_stroke)

    return Response(json.dumps(data, cls=NumpyArrayEncoder), headers={'Access-Control-Allow-Origin':'*', 'Content-Type':'application/json'});

    # return Response(generated.iloc[numPoints:].to_json(orient = 'records'), headers={'Access-Control-Allow-Origin':'*', 'Content-Type':'application/json'});

    # for n in range(500):
    #   prediction = pd.DataFrame(model.predict(input_seq.values), columns=points.columns)
    #   a = input_seq.loc[:,prediction.shape[1]:].values
    #   input_seq = pd.DataFrame([np.concatenate((a.reshape(a.shape[1],), prediction.values.reshape(prediction.shape[1])))])
    #   generated = generated.append(prediction, ignore_index=True)

    # return Response(json.dumps(generated.values, cls=NumpyArrayEncoder), headers={'Access-Control-Allow-Origin':'*', 'Content-Type':'application/json'});

class NumpyArrayEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return JSONEncoder.default(self, obj)

def predict(points, width, height, numPoints = 10):
    points = pd.DataFrame(points).loc[:,["x","y","pressure"]];
    points['x'] /= width;
    points['y'] /= height;

    generated = points.iloc[points.shape[0]-numPoints:].copy();

    for n in range(100):
        input_seq = pd.DataFrame(generated.iloc[generated.shape[0]-numPoints:].values.reshape(1,generated.shape[1]*numPoints));
        prediction = pd.DataFrame(model.predict(input_seq.values), columns=points.columns)
        generated = generated.append(prediction,ignore_index=True)
        
    generated['x'] *= width;
    generated['y'] *= height;
    generated['timestamp'] = time.time();

    return generated.to_dict(orient='records');

def interpolate(points, numPoints = 10):
    if len(points) < 5: return points; 
    points_df = pd.DataFrame(points);
    s=.1
    x, y, p, t = points_df["x"].to_numpy(), points_df["y"].to_numpy(), points_df["pressure"].to_numpy(), points_df["timestamp"].to_numpy()
    coords = np.linspace(0, x.size, x.size)
    k=np.min([x.size,5])
    splt = UnivariateSpline(coords, t, k=k, s=s)
    splx = UnivariateSpline(coords, x, k=k, s=s)
    sply = UnivariateSpline(coords, y, k=k, s=s)
    splp = UnivariateSpline(coords, p, k=k, s=s)
    ts = np.linspace(0, t.size, numPoints)
    xs = np.linspace(0, x.size, numPoints)
    ys = np.linspace(0, y.size, numPoints)
    ps = np.linspace(0, p.size, numPoints)
    data = [];
    for n in range(numPoints):
        data.append({'timestamp':splt(ts)[n],
                'x':splx(xs)[n],
                'y':sply(ys)[n],
                'pressure':splp(ps)[n]
        })
    return data 



if __name__ == '__main__':
     app.run()
     