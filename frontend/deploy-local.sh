#!/bin/sh
docker build -t draw .
docker rm -f draw
docker run -dit -p 8080:80 --name draw draw
