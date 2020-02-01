#!/bin/bash
IMAGE_NAME=puyo
exec docker run -i -t --init --rm -v `pwd`/vol:/mnt/vol -v `pwd`/home:/home/mirakui $IMAGE_NAME $*
