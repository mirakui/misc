#!/bin/bash
IMAGE_NAME=puyo
exec docker run -i --init --rm -v `pwd`/vol:/mnt/vol -v `pwd`/home:/home/mirakui $IMAGE_NAME $*
