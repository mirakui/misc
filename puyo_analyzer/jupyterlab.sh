#!/bin/bash
IMAGE_NAME=puyo
exec docker run -i --init --rm -v `pwd`/vol:/mnt/vol -v `pwd`/home:/home/mirakui -p 8888:8888 $IMAGE_NAME jupyter lab --ip=0.0.0.0 --no-browser
