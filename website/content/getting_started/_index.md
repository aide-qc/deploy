---
title: "Getting Started"
date: 2019-11-29T15:26:15Z
draft: false
weight: 10
---
There are a few ways to get started with the AIDE-QC stack. The easiest way is to install the pre-built binaries. As of this writing, we provide installers based on Homebrew and the Debian `apt-get` installer. If you are on Ubuntu, we recommend the `apt-get` route, and if you are on Mac OS X or any other Linux distrubition (like Fedora, CentOS, etc.) we recommend the Homebrew route. 

The second way to get AIDE-QC on your system is to install directly from source. This way is of course more difficult and takes more time, but provides a wide array of customization for your install. 

> **_NOTE:_** If any of the below instructions do not work for you, please file a bug at [AIDE-QC Issues](https://github.com/aide-qc/aide-qc/issues) with a detailed explanation of the failure you observed. 

## Install Prebuilt Binaries
### Linux x86_64 and Mac OS X 10.14 and 10.15
First install [Homebrew](https://brew.sh). The Homebrew homepage provides a single command to do this, it is extremely straightforward. Next. run the following command from your local terminal:
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aide-qc/deploy/master/aide_qc/homebrew/install.sh)"
``` 
This will install the AIDE-QC software stack. You will have the `qcor` compiler, the underlying `xacc` framework, as well as pertinent Python bindings. The install locations for `xacc` and `qcor` can be queried using `brew`
```sh
brew --prefix qcor
brew --prefix xacc
```

Test out your install by compiling and executing the following simple `qcor` code:
```sh
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

### Ubuntu 18.04 and 20.04 `apt-get install`
To install on Ubuntu using `apt-get` debian packages, run the following to enable downloads from the AIDE-QC `apt` repository:

```sh
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
sudo wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" > /etc/apt/sources.list.d/aide-qc.list
apt-get update
```
Note that the above requires you have `lsb_release` installed (usually is, if not, `apt-get install lsb-release`).

Now one can install `xacc` on its own:
```sh
apt-get install xacc
```
or `qcor`, which will give you the entire AIDE-QC stack:
```sh
apt-get install qcor
```
Test out your install by compiling and executing the following simple `qcor` code:
```sh
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

## Build everything from source individually
For the adventurous out there, or if your system does not support the above prebuilt binary instructions, you can build the AIDE-QC components from source. First, run the package installer commands for your system to get all requisite dependencies:

<table>
<tr>
<th>OS</th>
<th>Command</th>
</tr>
<tr>
<td>
<b>
Ubuntu 18.04
</b>
</td>
<td>

```bash
apt-get update
apt-get install -y software-properties-common 
add-apt-repository ppa:ubuntu-toolchain-r/test -y 
apt-get update 
apt-get install -y gcc-9 g++-9 gfortran-9 python3.8 libpython3.8-dev python3-pip libcurl4-openssl-dev libssl-dev liblapack-dev libblas-dev ninja-build lsb-release
python3 -m pip install cmake --user 
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
sudo wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" > /etc/apt/sources.list.d/aide-qc.list
apt-get update
apt-get install -y clang-syntax-handler
``` 
</td>
</tr>
<tr>
<td>
<b>
Ubuntu 20.04
</b>
</td>
<td>

```bash
apt-get update
apt-get install -y gcc g++ gfortran python3 libpython3-dev python3-pip libcurl4-openssl-dev libssl-dev liblapack-dev libblas-dev ninja-build lsb-release
python3 -m pip install cmake --user 
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
sudo wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" > /etc/apt/sources.list.d/aide-qc.list
apt-get update
apt-get install -y clang-syntax-handler
``` 
</td>
</tr>
<tr>
<td>
<b>
Mac OS X

Linux x86_64 (not Ubuntu)
</b>
</td>
<td>

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=false
brew tap aide-qc/deploy
brew install gcc@10 python3 cmake openssl curl ninja llvm-csp
``` 
</td>
</tr>
</table>

Now describe installing xacc and qcor, llvm_root is different for brew and ubuntu
