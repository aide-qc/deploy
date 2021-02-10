#!/bin/bash

set -e

# Build the deb via Docker
docker build -t combined/bionic . --no-cache
docker run -d -P -it --name bionicqcor combined/bionic
id=$(docker ps -aqf "name=bionicqcor") && docker cp $id:/qcor/build/qcor-1.0.0.deb . && docker cp $id:/home/dev/xacc/build/xacc-1.0.0.deb .
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

cd ../../../
cp ../xacc-1.0.0.deb xacc/debian/bionic 
cd xacc/debian/bionic 
gpg --import xacc-private-key.asc
dpkg-scanpackages --multiversion . > Packages
gzip -k -f Packages
apt-ftparchive release . > Release
gpg --default-key 48BDEFAEDE93809A -abs -o - Release > Release.gpg
gpg --default-key 48BDEFAEDE93809A --clearsign -o - Release > InRelease

git status
git add -A 
git commit -m "automated ci build of xacc and qcor bionic deb packages"
git config remote.aideqcdeploy.url >&- || git remote add -t master aideqcdeploy https://amccaskey:$AIDEQC_ACCESS_TOKEN@github.com/aide-qc/deploy
git push -f aideqcdeploy HEAD:master
git remote remove aideqcdeploy