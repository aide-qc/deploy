---
title: "Getting Started"
date: 2019-11-29T15:26:15Z
draft: false
weight: 10
---

There are a few ways to get started with the AIDE-QC stack: the prebuilt Docker-based browser IDE, the binary package installations, and building everything from source. 

> **_NOTE:_** ***If any of the below instructions do not work for you, please file a bug at [AIDE-QC Issues](https://github.com/aide-qc/aide-qc/issues) with a detailed explanation of the failure you observed.***

## Install the aide-qc command line tool
We provide a command line utility (`aide-qc`) that enables one to quickly spin up 
a web-based IDE pre-packaged with the AIDE-QC software stack, as well as demonstrative examples. This tool requires a valid Docker installation on your local machine. To install Docker, please see [Docker Desktop for Windows/Mac](https://www.docker.com/products/docker-desktop) or [Docker for Linux](https://docs.docker.com/engine/install/). 

To install the `aide-qc` tool, run the following from your local terminal. 
```sh
/bin/bash -c "$(curl -fsSL https://aide-qc.github.io/deploy/install_ide.sh)"
```
Once you have `aide-qc`, install the latest IDE and start a new instance via
```sh
aide-qc --install
aide-qc --start my_first_quantum_ide
```
This will open a browser-based IDE with the AIDE-QC software stack ready for use. 

For more details on the `aide-qc` command line tool, click [here](users/aide-qc-clt.md).

## Install AIDE-QC
To install the AIDE-QC binaries, run the following command from your local terminal (will require `sudo` credentials):
```sh
/bin/bash -c "$(curl -fsSL https://aide-qc.github.io/deploy/install.sh)"
```
> **_NOTE:_** ***You may need to evaluate your $HOME/.bashrc (or .bash_profile on MacOS) in order to configure your install. E.g., if `brew list` fails, run `source ~/.bashrc` or `source ~/.bash_profile`.***

This will install the AIDE-QC software stack, including the `qcor` compiler, the underlying `xacc` framework, as well as pertinent Python bindings. If you are going to use the Python API, you may need to export your `PYTHONPATH`
```sh
export PYTHONPATH=$(qcor -pythonpath):$PYTHONPATH
```
We recommend you add this to your `.bashrc` or `.bash_profile`. 

> **_NOTE:_** ***On Ubuntu, the installation script will attempt to use `apt-get` over our custom [Homebrew](https://brew.sh) installer. If you would rather use Homebrew instead of `apt-get`, run the following command:*** ***`/bin/bash -c "$(curl -fsSL https://aide-qc.github.io/deploy/install.sh) '$1'" bash --use-brew`***

### Install AIDE-QC Rigetti QCS
If you are using the [Rigetti QCS](https://qcs.rigetti.com/) platform, and have access to the provided [JupyterLab](https://jupyterlab.readthedocs.io/en/stable/) IDE, open a terminal and run the following:
```sh
wget https://aide-qc.github.io/deploy/install.sh 
bash install.sh -qcs
export PYTHONPATH=$(qcor -pythonpath):$PYTHONPATH
```

## <a id="test"></a> Test out your install
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

You can also test out the Python API by putting the following script in a `bell.py` file:
```python
from qcor import qjit, qalloc, qreg

# Define a Bell kernel
@qjit
def bell(q : qreg):
    H(q[0])
    CX(q[0], q[1])
    for i in range(q.size()):
        Measure(q[i])

# Allocate 2 qubits
q = qalloc(2)

# Run the bell experiment
bell(q)

# Print the results
print('Results')
print(q.counts())
```
and run it with 
```sh
python3 bell.py -qpu qpp -shots 1024
Results
{'00': 548, '11': 476}
```

## Build from Souce
If the above binary installs do not work for your system, checkout how to [build from source](getting_started/build_from_source.md).
