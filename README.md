# AIDE-QC Deploy
This repository contains binaries for the various frameworks, compilers, and libraries 
provided by the AIDE-QC project. 

# Ubuntu 18.04
For any Ubuntu 18.04 packages, add the public gpg key to your apt install
```bash
$ wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/bionic/PUBLIC-KEY.gpg | apt-key add -
```
then add the AIDE-QC apt-get repository
```bash
$ wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/bionic/aide-qc-bionic.list" > /etc/apt/sources.list.d/aide-qc-bionic.list
$ apt-get update
```
## Install QCOR (installs qcor+xacc)
```bash
$ apt-get install -y qcor
```
## Install XACC (on its own)
```bash
$ apt-get install xacc
```

# Ubuntu 20.04
For any Ubuntu 20.04 packages, add the public gpg key to your apt install
```bash
$ wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/focal/PUBLIC-KEY.gpg | apt-key add -
```
then add the AIDE-QC apt-get repository
```bash
$ wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/focal/aide-qc-focal.list" > /etc/apt/sources.list.d/aide-qc-focal.list
$ apt-get update
```
## Install QCOR (installs qcor+xacc)
```bash
$ apt-get install -y qcor
```
## Install XACC (on its own)
```bash
$ apt-get install xacc
```
