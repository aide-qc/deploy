---
title: "Build Everything from Source"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---
## Table of Contents
* [Install Dependencies](#deps)
* [XACC and QCOR on Ubuntu](#xqubuntu)
* [XACC and QCOR on Mac OS X and Linux x86_64 with Homebrew](#xqbrew)
* [Build the LLVM Clang SyntaxHandler Fork](#llvmcsp)

For the adventurous out there, or if your system does not support the above prebuilt binary instructions, you can build the AIDE-QC components from source.

## <a id="deps"></a> Install Dependencies
Run the package installer commands for your system to get all requisite dependencies:

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
# Add ubuntu-toolchain-r/test to get GCC 9
sudo apt-get update && sudo apt-get install -y software-properties-common 
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && sudo apt-get update 
# Install deps
sudo apt-get install -y gcc-9 g++-9 gfortran-9 python3.8 libpython3.8-dev python3-pip libcurl4-openssl-dev libssl-dev liblapack-dev libblas-dev ninja-build lsb-release
python3 -m pip install cmake --user 
# We'll skip building LLVM/Clang with SyntaxHandler and install binary
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | sudo tee -a /etc/apt/sources.list.d/aide-qc.list
sudo apt-get update
sudo apt-get install -y clang-syntax-handler
# Point defaults to GCC 9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 50
sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-9 50
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
# Install deps
sudo apt-get update
sudo apt-get install -y gcc g++ gfortran python3 libpython3-dev python3-pip libcurl4-openssl-dev libssl-dev liblapack-dev libblas-dev ninja-build lsb-release
python3 -m pip install cmake --user 
# We'll skip building LLVM/Clang with SyntaxHandler and install binary
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" | sudo tee -a /etc/apt/sources.list.d/aide-qc.list
sudo apt-get update
sudo apt-get install -y clang-syntax-handler
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
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# If on Fedora, do this first!
sudo dnf update -y && sudo dnf install gcc gcc-c++ lapack-devel

# Install deps, turn off dependents check
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=false
brew tap aide-qc/deploy
brew install gcc@10 python3 cmake openssl curl ninja llvm-csp

``` 
</td>
</tr>
</table>

The following instructions assume that you have run the above commands for your OS to ensure all requisite dependencies are available. 

## <a id="xqubuntu"></a> XACC and QCOR on Ubuntu
To build and install `xacc`, run the following:
```sh
git clone --recursive https://github.com/aide-qc/xacc 
cd xacc && mkdir build && cd build
cmake .. -G Ninja 
   # Optional flags
   -DXACC_BUILD_TESTS=TRUE
   -DCMAKE_INSTALL_PREFIX=/desired/path/to/install
   -DXACC_BUILD_EXAMPLES=TRUE

# Build and install to $HOME/.xacc (if CMAKE_INSTALL_PREFIX not specified)
cmake --build . --target install
```
This will install `xacc` to `$HOME/.xacc` (by default, will be your specified `CMAKE_INSTALL_PREFIX` if provided) with Python bindings for your `python3` installation (from the above `apt-get` dependencies install). You will need to set your `PYTHONPATH` to the `xacc` install directory in order to use the `xacc` python bindings
```sh
export PYTHONPATH=$PYTHONPATH:$HOME/.xacc
```
It is usually a good idea to add this to your `.bashrc` file. 

Next, build and install `qcor`:
```sh
(if in xacc/build) cd ../../
git clone https://github.com/aide-qc/qcor
cd qcor && mkdir build && cd build
cmake .. -G Ninja -DLLVM_ROOT=/usr/local/xacc/llvm 
    # Optional flags
    -DQCOR_BUILD_TESTS=TRUE
    -DCMAKE_INSTALL_PREFIX=/desired/path/to/install
    -DXACC_DIR=/path/to/xacc/install (if not $HOME/.xacc)

# Build and install to $HOME/.xacc (if CMAKE_INSTALL_PREFIX not specified)
cmake --build . --target install
```
This will install `qcor` to `$HOME/.xacc` (by default, will be your specified `CMAKE_INSTALL_PREFIX` if provided) with Python bindings for your `python3` installation. Update your `PYTHONPATH` if you did not install to `$HOME/.xacc`. You will also want to update your `PATH` variable to point to `$HOME/.xacc/bin` or `CMAKE_INSTALL_PREFIX/bin`
```sh
export PATH=$PATH:$HOME/.xacc/bin
```
It is usually a good idea to add this command to your `.bashrc` file. 

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

## <a id="xqbrew"></a> XACC and QCOR on Mac OS X and Linux x86_64 with Homebrew (not Ubuntu)
Make sure that you use `g++-10`, `gcc-10` explicitly in your `cmake` calls (they can be found with `brew --prefix gcc@10`). To build `xacc`
```sh
git clone --recursive https://github.com/aide-qc/xacc
cd xacc && mkdir build && cd build 
# Need to point build to Homebrew installed OpenSSL and Curl libs
cmake .. -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 -DOPENSSL_ROOT_DIR=$(brew --prefix openssl) -DCMAKE_PREFIX_PATH=$(brew --prefix curl) -G Ninja
   # Optional flags
   -DXACC_BUILD_TESTS=TRUE
   -DCMAKE_INSTALL_PREFIX=/desired/path/to/install
   -DXACC_BUILD_EXAMPLES=TRUE

# Build and install to $HOME/.xacc (if CMAKE_INSTALL_PREFIX not specified)
cmake --build . --target install
```
This will install XACC to `$HOME/.xacc` with Python bindings for your `python3` installation (from the above `brew` dependencies install, located in `$(brew --prefix python3)`). You will need to set your `PYTHONPATH` in order to use the XACC python bindings
```sh
export PYTHONPATH=$PYTHONPATH:$HOME/.xacc
```
It is usually a good idea to add this to your `.bash_profile` file. 

Next, build and install `qcor`:
```sh
(if in xacc/build) cd ../../
git clone https://github.com/aide-qc/qcor
cd qcor && mkdir build && cd build
cmake .. -G Ninja -DCMAKE_CXX_COMPILER=g++-10 -DCMAKE_C_COMPILER=gcc-10 \
         -DLLVM_ROOT=$(brew --prefix llvm-csp) \
         # Pass the next 2 flags on Mac OS X only
         -DQCOR_EXTRA_HEADERS="$(brew --prefix)/opt/gcc@10/include/c++/10.2.0;$(brew --prefix)/opt/gcc@10/include/c++/10.2.0/$(gcc-10 -dumpmachine)" \
         -DGCC_STDCXX_PATH=$(brew --prefix)/opt/gcc@10/lib/gcc/10
    # Optional flags
    -DQCOR_BUILD_TESTS=TRUE
    -DCMAKE_INSTALL_PREFIX=/desired/path/to/install
    -DXACC_DIR=/path/to/xacc/install (if not $HOME/.xacc)

# Build and install to $HOME/.xacc (if CMAKE_INSTALL_PREFIX not specified)
cmake --build . --target install
```
This will install `qcor` to `$HOME/.xacc`, or `CMAKE_INSTALL_PREFIX` if specified, with Python bindings for your `python3` installation. Update your `PYTHONPATH` if you did not install to `$HOME/.xacc`. You will also want to update your `PATH` variable to point to `$HOME/.xacc/bin` or `CMAKE_INSTALL_PREFIX/bin`
```sh
export PATH=$PATH:$HOME/.xacc/bin
```
It is usually a good idea to add this command to your `.bash_profile` file. 

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


## <a id="llvmcsp"></a> Build the LLVM-CSP Fork
> **_NOTE:_** This is a long build and not recommended for most users. We have binaries built and distributed with `apt-get` and Homebrew, these should be your first choice. The following is mainly for book-keeping and due diligence.

If you would like to build a custom install of our LLVM fork containing the Clang `SyntaxHandler`, run the following:
```sh
git clone https://github.com/hfinkel/llvm-project-csp llvm
cd llvm && mkdir build && cd build
cmake ../llvm -G Ninja -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_TARGETS_TO_BUILD=X86 \
      -DLLVM_ENABLE_DUMP=ON \
      -DLLVM_ENABLE_PROJECTS=clang \
      -DCMAKE_CXX_COMPILER=g++-10 \
      -DCMAKE_C_COMPILER=gcc-10 \
      -DCMAKE_INSTALL_PREFIX=$HOME/.llvm
cmake --build . --target install
```