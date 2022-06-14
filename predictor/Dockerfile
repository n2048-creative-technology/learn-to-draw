FROM tensorflow/tensorflow:latest

RUN pip install flask
RUN pip install flask_restful
RUN pip install pandas
RUN pip install numpy
RUN pip install scipy

WORKDIR /app

# COPY model.h5 /app/model.h5

COPY api.py /app/api.py

EXPOSE 5002
CMD python api.py
