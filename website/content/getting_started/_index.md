---
title: "Getting Started"
date: 2019-11-29T15:26:15Z
draft: false
weight: 10
---

There are a few ways to get started with the AIDE-QC stack. The easiest way is to install the pre-built binaries. As of this writing, we provide installers based on Homebrew and the Debian `apt-get` installer.

The second way to get AIDE-QC on your system is to install directly from source. This way is of course more difficult and takes more time, but provides a wide array of customization for your install. 

> **_NOTE:_** If any of the below instructions do not work for you, please file a bug at [AIDE-QC Issues](https://github.com/aide-qc/aide-qc/issues) with a detailed explanation of the failure you observed. 

## Install AIDE-QC
To install AIDE-QC, run the following command from your local terminal (will require `sudo` credentials):
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aide-qc/deploy/master/aide_qc/install.sh)"
``` 
This will install the AIDE-QC software stack. You will have the `qcor` compiler, the underlying `xacc` framework, as well as pertinent Python bindings. If you are going to use the Python API, you'll need to export your `PYTHONPATH`
```sh
export PYTHONPATH=$(qcor -qcor-install):$(qcor -xacc-install):$PYTHONPATH
```
We recommend you add this to your `.bashrc` or `.bash_profile`. 

Note: On Ubuntu, the installation script will attempt to use `apt-get` over our custom [Homebrew](https://brew.sh) installer. If you would rather use Homebrew instead of `apt-get`, run the following 
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/aide-qc/deploy/master/aide_qc/homebrew/install.sh) '$1'" bash --use-brew
```

Now, test out your install (next section). 

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

If the above binary installs do not work for your system, checkout how to [build from source](getting_started/build_from_source.md).
