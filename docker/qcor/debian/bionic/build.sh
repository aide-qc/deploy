#!/bin/bash

set -x

# Build the deb via Docker
docker build -t qcor/bionic .
docker run -d -P -it --name bionicqcor qcor/bionic
id=$(docker ps -aqf "name=bionicqcor") && docker cp $id:/qcor/build/qcor-1.0.0.deb . 
docker stop bionicqcor 
docker rm bionicqcor

# git clone the pages repo
# upload the xacc deb file there
git clone https://github.com/aide-qc/deploy 
cd deploy
cp ../qcor-1.0.0.deb qcor/debian/bionic 
cd qcor/debian/bionic 
gpg --import xacc-private-key.asc
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages
apt-ftparchive release . > Release
gpg --default-key 48BDEFAEDE93809A -abs -o - Release > Release.gpg
gpg --default-key 48BDEFAEDE93809A --clearsign -o - Release > InRelease
git status
git add -A 
git commit -m "automated ci build of qcor bionic deb"
git config remote.aideqcdeploy.url >&- || git remote add -t master aideqcdeploy https://amccaskey:$AIDEQC_ACCESS_TOKEN@github.com/aide-qc/deploy
git push -f aideqcdeploy HEAD:master
git remote remove aideqcdeploy