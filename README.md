# AIDE-QC Deployment Repository
This repository contains binaries for the various frameworks, compilers, and libraries 
provided by the AIDE-QC project. 

## Mac OS X and Linux x86_64
For Mac OS X and most Linux distributions, we leverage (LINK Homebrew) to install the AIDE-QC stack. 
Therefore, to install AIDE-QC, you must first install Hombebrew (simple instructions on Homebrew homepage). 

Once Homebrew is installed, run the following command from your terminal 
```bash 
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aide-qc/deploy/master/aide_qc/homebrew/install.sh)"
```
This will install the AIDE-QC stack, including XACC and QCOR. 

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

// Test out qcor, copy and paste below text into terminal!
$ printf "__qpu__ void f(qreg q) {
  H(q[0]);
  Measure(q[0]);
}
int main() {
  auto q = qalloc(1);
  f(q);
  q.print();
}  " | qcor -qpu qpp -shots 1024 -x c++ -
$ ./a.out
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

// Test out qcor, copy and paste below text into terminal!
$ printf "__qpu__ void f(qreg q) {
  H(q[0]);
  Measure(q[0]);
}
int main() {
  auto q = qalloc(1);
  f(q);
  q.print();
}  " | qcor -qpu qpp -shots 1024 -x c++ -
$ ./a.out
```
All installs will be in the `/usr/local/xacc` directory.
