#!/bin/bash

set -x

# Build the deb via Docker
docker build -t csp/bionic . --no-cache
docker run -d -P -it --name csp csp/bionic
id=$(docker ps -aqf "name=csp") && docker cp $id:/llvm/build/LLVM-10.0.0git-Linux.deb . 
docker stop csp 
docker rm csp