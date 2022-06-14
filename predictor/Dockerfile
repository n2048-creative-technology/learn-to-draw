FROM tensorflow/tensorflow:latest

RUN pip install flask
RUN pip install flask_restful
RUN pip install pandas
RUN pip install numpy
RUN pip install scipy

WORKDIR /app

COPY ./models models

COPY app.py /app/app.py

EXPOSE 5000
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0"]