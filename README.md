# AIDE-QC Deploy
This repository contains binaries for the various frameworks, compilers, and libraries 
provided by the AIDE-QC project. 

# Ubuntu 18.04

## Install XACC
```bash
$ wget -qO- https://aide-qc.github.io/deploy/xacc/debian/bionic/PUBLIC-KEY.gpg | apt-key add -
$ echo "deb https://aide-qc.github.io/deploy/xacc/debian/bionic ./" > /etc/apt/sources.list.d/xacc-bionic.list
$ apt-get update && apt-get install -y xacc
```

# Ubuntu 20.04

## Install XACC
```bash
$ wget -qO- https://aide-qc.github.io/deploy/xacc/debian/focal/PUBLIC-KEY.gpg | apt-key add -
$ echo "deb https://aide-qc.github.io/deploy/xacc/debian/focal ./" > /etc/apt/sources.list.d/xacc-focal.list
$ apt-get update && apt-get install -y xacc
```