# AIDE-QC Deployment Repository
This repository contains binaries for the various frameworks, compilers, and libraries 
provided by the AIDE-QC project. 

## Ubuntu Bionic (18.04)
For any Ubuntu 18.04 packages, run the following to enable downloads from the AIDE-QC apt repository (note you will require `sudo`):
```bash
$ wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/bionic/PUBLIC-KEY.gpg | apt-key add -
$ wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/bionic/aide-qc-bionic.list" > /etc/apt/sources.list.d/aide-qc-bionic.list
$ apt-get update
```
Next, one can install XACC on its own: 
```bash
$ apt-get install xacc
```
or QCOR, which will give you XACC plus a custom Clang/LLVM install with SyntaxHandler capabilities:
```bash
$ apt-get install qcor
```
All installs will be in the `/usr/local/xacc` directory.

## Ubuntu Focal (20.04)
For any Ubuntu 20.04 packages, run the following to enable downloads from the AIDE-QC apt repository (note you will require `sudo`):
```bash
$ wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/focal/PUBLIC-KEY.gpg | apt-key add -
$ wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/focal/aide-qc-focal.list" > /etc/apt/sources.list.d/aide-qc-focal.list
$ apt-get update
```
Next, one can install XACC on its own: 
```bash
$ apt-get install xacc
```
or QCOR, which will give you XACC plus a custom Clang/LLVM install with SyntaxHandler capabilities:
```bash
$ apt-get install qcor
```
All installs will be in the `/usr/local/xacc` directory.
