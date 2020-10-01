# Run the following to install
```bash 
$ wget -qO- https://aide-qc.github.io/deploy/xacc/debian/bionic/PUBLIC-KEY.gpg | apt-key add -
$ echo "deb https://aide-qc.github.io/deploy/xacc/debian/bionic ./" > /etc/apt/sources.list.d/xacc-bionic.list
$ apt-get update
$ apt-get install xacc
```

## when the files change
```bash 
  gpg --import xacc-private-key.asc
  dpkg-scanpackages --multiversion . > Packages
  gzip -k -f Packages
  apt-ftparchive release . > Release
  gpg --default-key 48BDEFAEDE93809A -abs -o - Release > Release.gpg
  gpg --default-key 48BDEFAEDE93809A --clearsign -o - Release > InRelease
  ```