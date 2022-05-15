# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y g++

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libtool

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg

## Add source code to the build stage.
ADD . /h264bitstream
WORKDIR /h264bitstream

## TODO: ADD YOUR BUILD INSTRUCTIONS HERE.
RUN autoreconf -i
RUN ./configure
RUN make

#Package Stage
FROM --platform=linux/amd64 ubuntu:20.04

## TODO: Change <Path in Builder Stage>
COPY --from=builder /h264bitstream/h264_analyze /
COPY --from=builder /h264bitstream/.libs/ /.libs
COPY --from=builder /h264bitstream/.libs/libh264bitstream.so.0 /usr/lib/x86_64-linux-gnu/libh264bitstream.so.0
