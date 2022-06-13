FROM tensorflow/tensorflow:latest

WORKDIR /app

COPY model1-unnormalized-202009Mar-1423.h5 /app/modelh.h5
COPY model-202006Mar-2130.h5 /app/model.h5
#COPY model-202007Mar-1638.h5 /app/model.h5

COPY app.py /app/app.py

CMD python app.py
