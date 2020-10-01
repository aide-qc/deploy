#!/bin/bash

set -x

docker build -t xacc/bionic . --no-cache
docker run -d -P -it --name bionicxacc xacc/bionic
id=$(docker ps -aqf "name=bionicxacc") && docker cp $id:/home/dev/xacc/build/xacc-1.0.0.deb . 
docker stop bionicxacc 
docker rm bionicxacc

# git clone the pages repo
# upload the xacc deb file there
