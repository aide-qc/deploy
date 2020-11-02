---
title: "Tensor Network Quantum Virtual Machine"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

[TNQVM](https://github.com/ORNL-QCI/tnqvm) is an `Accelerator` implementation that leverages tensor network theory to simulate quantum circuits.

TNQVM supports [ITensor](http://itensor.org)-MPS (built-in) and [ExaTN](https://github.com/ORNL-QCI/exatn) numerical tensor processing libraries.

## <a id="installation"></a> Install the TNQVM 

**Required Dependencies**: XACC (part of AIDE-QC Software Stack)

**Optional Dependencies**: ExaTN, MPI

### Locate XACC install directory

Depending on the way XACC was installed, e.g. compiling from source or using `apt-get`/`brew`, XACC may be located at different locations. 

For example, if installed from source, XACC can be found at `$HOME/.xacc` by default. 

On the other hand, if the AIDE-QC Software Stack was installed with `apt-get install qcor`, XACC can be found at `/usr/local/xacc`.

### *(Optional)* Clone and build ExaTN library

If ExaTN backends are required, we need to clone and build the ExaTN library before compiling TNQVM.

Full build instructions can be found [here](https://github.com/ORNL-QCI/exatn#linux-build-instructions). 
In the followings, we just provides examples for some common build configurations.

```bash
git clone https://github.com/ORNL-QCI/exatn.git
cd exatn && mkdir build && cd build
cmake .. -DBLAS_LIB=<BLAS_LIB_NAME> -DBLAS_PATH=<BLAS_LIB_PATH> -DMPI_LIB=<MPI_LIB_NAME> -DMPI_ROOT_DIR=<MPI_LIB_PATH> -DMPI_BIN_PATH=<MPI_BIN_PATH>
make install
```

| Variable            | Description                                                                |  Example                           |
|---------------------|----------------------------------------------------------------------------|------------------------------------|
| <BLAS_LIB_NAME>     | Name of the Blas library                                                   |`ATLAS`                             |
| <BLAS_LIB_PATH>     | Path to the Blas library                                                   |`/usr/lib/x86_64-linux-gnu`         |
| <MPI_LIB_NAME>      | Name of the MPI implementation                                             |`MPICH` or `OPENMPI`                |
| <MPI_LIB_PATH>      | Path to the MPI library                                                    |`/usr/lib/x86_64-linux-gnu/openmpi/`|
| <MPI_BIN_PATH>      | Path to the directory that contains MPI binary executables, e.g. `mpirun`. | `/usr/bin`                         |


**Note:** if you need to use ExaTN with GPU hardware (e.g. CUDA), please follow the instructions [here](https://github.com/ORNL-QCI/exatn#linux-build-instructions).

After installation, ExaTN will be located at `$HOME/.exatn` by default unless a specific `CMAKE_INSTALL_PREFIX` value was specified. We will need this information to compile TNQVM with ExaTN in the next step.

### Clone and build TNQVM

#### Without ExaTN:
If we only want to use TNQVM with the built-in ITensor-MPS numerical backend (skipping the above step), the build instructions are:

```bash
git clone  https://github.com/ornl-qci/tnqvm 
cd tnqvm && mkdir build && cd build 
cmake .. -DXACC_DIR=<XACC_DIR> -DTNQVM_BUILD_TESTS=TRUE
make install
```

`<XACC_DIR>` is the XACC install directory that we have located in the first [step](#locate-xacc-install-directory), e.g. `$HOME/.xacc` if installed from source or `/usr/local/xacc` if using `apt-get`.

`-DTNQVM_BUILD_TESTS=TRUE` is optional but *highly-recommended* to validate the TNQVM installation. 
If set, we can test the installation by running the `ctest` command after `make install`.

#### With ExaTN:

```bash
git clone  https://github.com/ornl-qci/tnqvm 
cd tnqvm && mkdir build && cd build 
cmake .. -DXACC_DIR=<XACC_DIR> -DEXATN_DIR=<EXATN_DIR> -DTNQVM_BUILD_TESTS=TRUE
make install
```

`<EXATN_DIR>` is the location of the ExaTN library, which was installed in the previous step. As before, it is highly-recommended that we test the installation afterward by running `ctest`.

#### Enable multi-node MPS Tensor distribution

When using **with** ExaTN, TNQVM can support MPS tensors that are distributed across multi nodes. This feature can be enabled by adding `-DTNQVM_MPI_ENABLED=TRUE` to CMake along with other configuration variables.

**Prerequisites**: ExaTN is built with MPI enabled, i.e., setting `MPI_LIB` and `MPI_ROOT_DIR` when configuring the ExaTN build.

Build configurations:

```bash
git clone  https://github.com/ornl-qci/tnqvm 
cd tnqvm && mkdir build && cd build 
cmake .. -DXACC_DIR=<XACC_DIR> -DEXATN_DIR=<EXATN_DIR> -DTNQVM_BUILD_TESTS=TRUE -DTNQVM_MPI_ENABLED=TRUE
make install
```


## Using TNQVM 
Show with xacc alone, show with qcor at c++ and python jit level

The TNQVM Accelerator can be requested in the XACC framework by

```cpp
auto qpu = xacc::getAccelerator("tnqvm", {{"tnqvm-visitor", "exatn"}});
```

The `tnqvm-visitor` key can refer to one of the following options:

|   `tnqvm-visitor`  |                  Description                                           |    
|--------------------|------------------------------------------------------------------------|
|    `itensor-mps`   | MPS simulator based on itensor library.                                | 
|    `exatn`         | Full tensor contraction simulator based on ExaTN library.              |    
|    `exatn-mps`     | MPS simulator based on ExaTN library.                                  |    
|    `exatn-pmps`    | Purified-MPS (density matrix) simulator based on ExaTN library.        |   

**Note**: If TNQVM was built without ExaTN, only the `itensor-mps` visitor will be available.

Let's look at a typical Bell-state quantum circuit simulation:

<table>
<tr>
<th>Bell Experiment - C++</th>
<th>Bell Experiment - Python</th>
</tr>
<tr>
<td>

```cpp
#include "xacc.hpp"
int main(int argc, char **argv) {
  xacc::Initialize(argc, argv);
  // Get reference to the TNQVM Accelerator
  auto accelerator = xacc::getAccelerator(
      "tnqvm", {{"tnqvm-visitor", "exatn"}, {"shots", 1024}});

  // Allocate some qubits
  auto buffer = xacc::qalloc(2);
  auto xasmCompiler = xacc::getCompiler("xasm");
  auto ir = xasmCompiler->compile(R"(__qpu__ void bell(qbit q) {
      H(q[0]);
      CX(q[0], q[1]);
      Measure(q[0]);
      Measure(q[1]);
  })", accelerator);

  accelerator->execute(buffer, ir->getComposites()[0]);
  buffer->print();
  xacc::Finalize();
  return 0;
}
```
</td>
<td>

```python
import xacc
qpu = xacc.getAccelerator('tnqvm', { 'tnqvm-visitor': 'exatn', 'shots': 1024 })

# Define the quantum kernel in standard Python
@xacc.qpu(accelerator=qpu)
def bell(q):
    H(q[0])
    CX(q[0],q[1])
    Measure(q[0])
    Measure(q[1])

# Allocate 2 qubits
q = xacc.qalloc(2)

# run the bell state computation
bell(q)

print(q)
```
</td>
</tr>
</table>

Similarly, TNQVM can be used with the QCOR compiler. 
Rather than explicitly requesting the TNQVM accelerator, one just need to pass `tnqvm` to the `-qpu` command-line argument when compiling with QCOR.


<table>
<tr>
<th>Bell Experiment - C++</th>
<th>Bell Experiment - Python</th>
</tr>
<tr>
<td>
Compile and run with

```bash
qcor -qpu tnqvm[tnqvm-visitor:exatn] -shots 1024 bell.cpp
./a.out
```
</td>
<td>

Run with

```bash
python3 bell.py -qpu tnqvm[tnqvm-visitor:exatn] -shots 1024
```
</td>
</tr>
<tr>
<td>

```cpp
__qpu__ void bell(qreg q) {
  H(q[0]);
  CX(q[0], q[1]);
  for (int i = 0; i < q.size(); i++) {
    Measure(q[i]);
  }
}

int main() {
  auto q = qalloc(2);
  // Run the quantum kernel
  bell(q);
  q.print();
}
```
</td>
<td>

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
</td>
</tr>
</table>