#!/bin/bash

set -x

# Build the deb via Docker
docker build -t xacc/bionic . --no-cache
docker run -d -P -it --name bionicxacc xacc/bionic
id=$(docker ps -aqf "name=bionicxacc") && docker cp $id:/home/dev/xacc/build/xacc-1.0.0.deb . 
docker stop bionicxacc 
docker rm bionicxacc

# git clone the pages repo
# upload the xacc deb file there
git clone https://github.com/aide-qc/deploy 
cd deploy
cp ../xacc-1.0.0.deb xacc/debian/bionic 
git status
git add -A 
git commit -s -m "automated ci build of xacc bionic deb"
git config remote.aideqcdeploy.url >&- || git remote add -t master aideqcdeploy https://amccaskey:$AIDEQC_ACCESS_TOKEN@github.com/aide-qc/deploy
git push -f aideqcdeploy HEAD:master
git remote remove aideqcdeploy