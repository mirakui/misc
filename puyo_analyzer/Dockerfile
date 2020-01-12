FROM python:3.8-buster

RUN apt update
RUN apt install -y ffmpeg
RUN apt install -y libopencv-dev python3-opencv

RUN pip install youtube-dl
RUN pip install jupyterlab

RUN useradd -ms /bin/bash mirakui
USER mirakui
WORKDIR /home/mirakui
