FROM python:3.6

RUN apt-get update -y \
    && apt-get install libsasl2-dev python-dev libldap2-dev libssl-dev libsnmp-dev

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

WORKDIR /app

COPY model.h5 /app/modelh.h5

COPY api.py /app/api.py

EXPOSE 5002
CMD python api.py
