FROM python:3.8-buster

RUN apt update
RUN apt install -y ffmpeg
RUN apt install -y libopencv-dev

RUN pip install youtube-dl
RUN pip install jupyterlab
RUN pip install opencv-contrib-python
RUN pip install matplotlib

RUN apt install -y zsh
RUN pip install scikit-image

RUN useradd -ms /bin/bash mirakui
USER mirakui
WORKDIR /home/mirakui
