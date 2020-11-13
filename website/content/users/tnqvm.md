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

You can always locate where XACC is installed with 
```sh
qcor -xacc-install
```

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


## <a id="usage"></a> Using TNQVM 

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

### Full tensor contraction simulation

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

### Approximate simulation with MPS

To use the MPS-bases simulator, one needs to pass the name `exatn-mps` to the `tnqvm-visitor` option as shown in the below C++ example.

```cpp
#include "xacc.hpp"

int main (int argc, char** argv) {
    // Initialize the XACC Framework
    xacc::Initialize(argc, argv);
    xacc::set_verbose(true);
    auto qpu = xacc::getAccelerator("tnqvm", {
        {"tnqvm-visitor", "exatn-mps"},
        {"shots", 10},
    });

    // Allocate a register of 40 qubits
    auto qubitReg = xacc::qalloc(40);

    // Create a Program
    auto xasmCompiler = xacc::getCompiler("xasm");
    auto ir = xasmCompiler->compile(R"(__qpu__ void ghz(qbit q) {
        H(q[0]);
        for (int i = 0; i < 39; i++) {
            CX(q[i], q[i+1]);
        }
        // Measure two random qubits
        // should only get entangled bitstrings:
        // i.e. 00 or 11
        Measure(q[2]);
        Measure(q[37]);
    })", qpu);

    // Request the quantum kernel representing
    // the above source code
    auto program = ir->getComposite("ghz");
    // Execute!
    qpu->execute(qubitReg, program);
    qubitReg->print();

    // Finalize the XACC Framework
    xacc::Finalize();
    return 0;
}
```

In this example, we simulate a simple cat-state experiment with a rather large number of qubits (40). Since this is an MPS-based simulator, the amount of memory required depends on the amount of entanglement, which is not much in this case. Hence, we can easily run this simulation on our laptops.


### Noisy simulation with locally-purified MPS simulator

TNQVM is experimentally supporting noisy circuit simulation using the locally-purified MPS method. The `tnqvm-visitor` name for this method is `exatn-pmps`.

In this mode, users need to either provide the device/backend model in JSON format (using configuration key `backend-json`) or specify an IBMQ backend that they want to emulate (using the `backend` option). The latter is demonstrated in the below example.

```cpp
#include "xacc.hpp"

int main(int argc, char **argv) {

  // Initialize the XACC Framework
  xacc::Initialize(argc, argv);

  // Using the purified-mps backend with noise model from
  // "ibmq_5_yorktown - ibmqx2" device.
  auto qpu = xacc::getAccelerator(
      "tnqvm", {{"tnqvm-visitor", "exatn-pmps"}, {"backend", "ibmqx2"}});

  // Allocate a register of 2 qubits
  auto qubitReg = xacc::qalloc(2);

  // Create a Program: simple Bell test
  auto xasmCompiler = xacc::getCompiler("xasm");
  auto ir = xasmCompiler->compile(R"(__qpu__ void bell(qbit q, double theta) {
    H(q[0]);
    CX(q[0],q[1]);
    Measure(q[0]);
    Measure(q[1]);
    })", qpu);

  // Request the quantum kernel representing
  // the above source code
  auto program = ir->getComposite("bell");

  // Execute!
  qpu->execute(qubitReg, program);
  // Print the result (measurement count distribution) in the buffer.
  qubitReg->print();

  // Finalize the XACC Framework
  xacc::Finalize();

  return 0;
}
```

It's worth noting that the `exatn-pmps` visitor can only simulate localized (single-qubit) noise processes and hence doesn't take into account correlated noise operations.


Lastly, below is the list of all available configuration options for each visitor type. 

Some of the options are custom for specific simulation scenarios. Users are encouraged to submit questions on the TNQVM repository for programming supports.

For the `exatn` simulator, there are additional options that users can set during initialization:

|  Initialization Parameter   |                  Parameter Description                                 |    type     |         default          |
|-----------------------------|------------------------------------------------------------------------|-------------|--------------------------|
| exatn-buffer-size-gb        | ExaTN's host memory buffer size (in GB)                                |    int      | 8 (GB)                   |
| exatn-contract-seq-optimizer| ExaTN's contraction sequence optimizer to use.                         |    string   | metis                    |
| calc-contract-cost-flops    | Estimate the Flops and Memory requirements only (no tensor contraction)<br>If true, the following info will be added to the AcceleratorBuffer: <br>  - `contract-flops`: Flops count. <br>  - `max-node-bytes`: Max intermediate tensor size in memory.<br>  - `optimizer-elapsed-time-ms`: optimization walltime.<br>  |    bool     | false                    |
| bitstring                   | If provided, the output amplitude/partial state vector associated with that `bitstring` will be computed.<br>The length of the input `bitstring` must match the number of qubits.<br>Non-projected bits (partial state vector) are indicated by `-1` values.<br>Returned values in the AcceleratorBuffer:<br>  - `amplitude-real`/`amplitude-real-vec`: Real part of the result.<br>  - `amplitude-imag`/`amplitude-imag-vec`: Imaginary part of the result.| vector<int> | `<unused>`                 |
| contract-with-conjugate     | If true, we append the conjugate of the input circuit.<br>This is used to validate internal tensor contraction.<br>`contract-with-conjugate-result` key in the AcceleratorBuffer will be set to `true` if the validation is successful.|    bool     | false                    |
| mpi-communicator            | The MPI communicator to initialize ExaTN runtime with.<br>If not provided, by default, ExaTN will use `MPI_COMM_WORLD`.                  |    void*    | `<unused>`                 |

For the `exatn-mps` simulator, there are additional options that users can set during initialization:

|  Initialization Parameter   |                  Parameter Description                                 |    type     |         default          |
|-----------------------------|------------------------------------------------------------------------|-------------|--------------------------|
| svd-cutoff                  | SVD cut-off limit.                                                     |    double   | numeric_limits::min      |
| max-bond-dim                | Max bond dimension to keep.                                            |    int      | no limit                 |
| mpi-communicator            | The MPI communicator to initialize ExaTN runtime with.<br>If not provided, by default, ExaTN will use `MPI_COMM_WORLD`.                  |    void*    | `<unused>`                 |

For the `exatn-pmps` simulator, there are additional options that users can set during initialization:

|  Initialization Parameter   |                  Parameter Description                                 |    type     |         default          |
|-----------------------------|------------------------------------------------------------------------|-------------|--------------------------|
| backend-json                | Backend configuration JSON to estimate the noise model from.           |    string   | None                     |
| backend                     | Name of the IBMQ backend to query the backend configuration.           |    string   | None                     |
