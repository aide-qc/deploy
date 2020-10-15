# AIDE-QC Deployment Repository
This repository contains binaries for the various frameworks, compilers, and libraries 
provided by the AIDE-QC project. 

## Mac OS X and Linux x86_64
For Mac OS X and most Linux distributions, we leverage [Homebrew](https://brew.sh/) to install the AIDE-QC stack. 
Therefore you must first install Hombebrew (simple instructions on Homebrew [homepage](https://brew.sh/)). 

Once Homebrew is installed, run the following command from your terminal 
```bash 
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aide-qc/deploy/master/aide_qc/homebrew/install.sh)"
```
This will install the AIDE-QC stack, including XACC and QCOR. 

Test it out your install by trying to compile the code below with qcor
```bash
// Test out qcor, copy and paste below text into terminal!
printf "__qpu__ void f(qreg q) {
  H(q[0]);
  Measure(q[0]);
}
int main() {
  auto q = qalloc(1);
  f(q);
  q.print();
}  " | qcor -qpu qpp -shots 1024 -x c++ -
./a.out
```

## Ubuntu Bionic (18.04) and Focal (20.04)
To install on Ubuntu using `apt-get` debian packages, run the following to enable downloads from the AIDE-QC apt repository:
```bash
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
sudo wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" > /etc/apt/sources.list.d/aide-qc.list
apt-get update
```
Note that the above requires you have `lsb_release` installed (usually is, if not, `apt-get install lsb-release`).

Now one can install XACC on its own: 
```bash
apt-get install xacc
```
or QCOR, which will give you XACC plus a custom Clang/LLVM install with SyntaxHandler capabilities:
```bash
apt-get install qcor
``
Test it out by trying to compile the code below with qcor
```bash
// Test out qcor, copy and paste below text into terminal!
printf "__qpu__ void f(qreg q) {
  H(q[0]);
  Measure(q[0]);
}
int main() {
  auto q = qalloc(1);
  f(q);
  q.print();
}  " | qcor -qpu qpp -shots 1024 -x c++ -
./a.out
```
All installs will be in the `/usr/local/xacc` directory.
