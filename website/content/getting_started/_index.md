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

### Ubuntu 18.04 and 20.04 `apt-get install`
To install on Ubuntu using `apt-get` debian packages, run the following to enable downloads from the AIDE-QC `apt` repository:

```sh
wget -qO- https://aide-qc.github.io/deploy/aide_qc/debian/PUBLIC-KEY.gpg | sudo apt-key add -
sudo wget -qO- "https://aide-qc.github.io/deploy/aide_qc/debian/$(lsb_release -cs)/aide-qc.list" > /etc/apt/sources.list.d/aide-qc.list
sudo apt-get update
```
Note that the above requires you have `lsb_release` installed (usually is, if not, `sudo apt-get install lsb-release`).

Now one can install `qcor` which will give you the entire AIDE-QC stack:
```sh
sudo apt-get install qcor
```

If you are going to use the Python API, you'll need to export your `PYTHONPATH`
```sh
export PYTHONPATH=/usr/local/xacc:$PYTHONPATH
```
We recommend you add this to your `.bashrc` or `.bash_profile`. 

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

If you are going to use the Python API, you'll need to export your `PYTHONPATH`
```sh
export PYTHONPATH=$(brew --prefix qcor):$(brew --prefix xacc):$PYTHONPATH
```
We recommend you add this to your `.bashrc` or `.bash_profile`. 

## Test out your install
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
q.print()
```
and run it with 
```sh
python3 bell.py -qpu qpp -shots 1024
{
    "AcceleratorBuffer": {
        "name": "qrg_nWlrB",
        "size": 2,
        "Information": {},
        "Measurements": {
            "00": 517,
            "11": 507
        }
    }
}
```

If the above binary installs do not work for your system, checkout how to [build from source](getting_started/build_from_source.md).
