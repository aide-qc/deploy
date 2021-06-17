---
date: 2017-10-19T15:26:15Z
lastmod: 2019-10-26T15:26:15Z
publishdate: 2018-11-23T15:26:15Z
---

<table border="0">
 <tr>
    <td><b style="font-size:30px">AIDE-QC: Software Stack for Quantum-Classical Computing</b></td>
    <td><b style="font-size:30px">Getting Started</b></td>
 </tr>
 <tr>
    <td width="1000">
AIDE-QC is a next-generation software stack enabling heterogeneous quantum-classical programming, compilation, 
and execution on both near-term and future fault-tolerant quantum computers. Our approach treats quantum computers 
as co-processors and puts forward single-source C++ and Pythonic programming models for quantum code expression and 
compilation to native backend gate sets. 

AIDE-QC builds upon the service-oriented [XACC](background/xacc.md) quantum programming framework and puts forward plugins 
for quantum language parsing, intermediate representations, transformations on compiled circuits, error mitigation strategies, 
and backend execution and emulation, to name a few. These plugin interfaces enable AIDE-QC to remain flexible as the quantum 
computing research landscape grows and advances. 

Ultimately, AIDE-QC puts forward a novel C++ [language extension](lang_spec/_index.md) for heterogeneous quantum-classical computing called 
[QCOR](background/qcor.md). This extension enables programmers to work in C++ and define quantum code as stand-alone 
functions or **quantum kernels**.</td>
    <td>
## Install the AIDE-QC IDE (any OS, requires Docker)
```sh
$ /bin/bash -c "$(curl -fsSL https://aide-qc.github.io/deploy/install_ide.sh)"
$ aide-qc --install
$ aide-qc --start my_first_quantum_ide
# IDE will open in browser, ready for work
```
## Install the binaries locally (Mac, Linux)
```sh
/bin/bash -c "$(curl -fsSL https://aide-qc.github.io/deploy/install.sh)"
```
See more details on installation at [Getting Started](getting_started/_index.md).

</td>
 </tr>
</table>
<br />
<br />

---

<!--
# AIDE-QC Software Stack for Quantum Computing
AIDE-QC is a next-generation software stack enabling heterogeneous quantum-classical programming, compilation, <br />
and execution on both near-term and future fault-tolerant quantum computers. Our approach treats quantum computers <br />
as co-processors and puts forward single-source C++ and Pythonic programming models for quantum code expression and <br />
compilation to native backend gate sets. 

AIDE-QC builds upon the service-oriented [XACC](background/xacc.md) quantum programming framework and puts forward plugins <br />
for quantum language parsing, intermediate representations, transformations on compiled circuits, error mitigation strategies, <br />
and backend execution and emulation, to name a few. These plugin interfaces enable AIDE-QC to remain flexible as the quantum <br />
computing research landscape grows and advances. 

Ultimately, AIDE-QC puts forward a novel C++ language extension for heterogeneous quantum-classical computing called <br />
[QCOR](background/qcor.md). This extension enables programmers to work in C++ and define quantum code as stand-alone <br />
functions or **quantum kernels**.
-->

## Quick Look - Programming [Grover's Algorithm](https://en.wikipedia.org/wiki/Grover%27s_algorithm)
<table>
<tr>
<td width="800">
AIDE-QC promotes a single-source programming model for quantum computing. While most approaches promote circuit construction 
data structures for remote submission APIs, we enable a true quantum-classical programming language via extensions to existing familiar 
programming languages, like C++ and Python. <br />

Here we demonstrate how to program a textbook quantum algorithm - the Grover search. We want to implement the general circuit 
shown to the right, with initialization, iterative oracle and amplification application, and final qubit measurement. We decompose 
the algorithm into 2 library header files and a third implementation file with `main()` entrypoint. 

</td>
<td width="800" style='text-align:center; vertical-align:middle'>
<img src="grover_circuit.png" width=600px />
</td>
<tr>
<tr>
<td style='text-align:center; vertical-align:middle; font-size:30px'>amplification.hpp</td>
<td style='text-align:center; vertical-align:middle; font-size:30px'>grover.hpp</td>
<td style='text-align:center; vertical-align:middle; font-size:30px'>run_grover.cpp</td>
</tr>
<td >

```cpp

__qpu__ void amplification(qreg q) {
  compute {
    H(q);
    X(q);
  } action {
    // we have N qubits, get the first N-1 as the 
    // ctrl qubits, and the last one for the 
    // ctrl-ctrl-...-ctrl-z operation qubit
    auto ctrl_qubits = q.head(q.size()-1);
    auto last_qubit = q.tail();
    Z::ctrl(ctrl_qubits, last_qubit);
  }
}

```
</td>
<td>

```cpp
#include "amplification.hpp"
using GroverPhaseOracle = KernelSignature<qreg>;

__qpu__ void run_grover(qreg q, GroverPhaseOracle oracle,
                        const int iterations) {
  // Put them all in a superposition
  H(q);
  // Iteratively apply the oracle then reflect
  for (int i = 0; i < iterations; i++) {
    oracle(q);
    amplification(q);
  }
  // Measure all qubits
  Measure(q);
}
```
</td>
<td width="450">

```cpp
#includle "grover.hpp"

__qpu__ void oracle(qreg q) {
    CZ(q[0], q[2]);
    CZ(q[1], q[2]);
}

int main(int argc, char** argv) {
    auto q = qalloc(3);
    run_grover(q, oracle, 1);
    for (auto [bits, count] : q.counts()) {
      print(bits, ":", count);
    }
}

```
</td>
</tr>
<tr>
<td >
To start, we look at the circuit above and notice a sub-circuit called out as `amplification`. It has a very specific structure - a 
patturn of Hadamard and X gates on all qubits, followed by a multi-qubit control-Z operation, and ended with another Hadamard/X broadcast operation. AIDE-QC and QCOR 
express this common pattern (so-called compute-action-uncompute) via a special compute {...} action {...} syntax. Note here also that qubit and sub-qreg extraction 
is possible on a provided qreg, and all single-qubit gates can be controlled on one or many qubits. 
</td>
<td>
The AIDE-QC stack allows one to define quantum kernels that can be parameterized with other quantum callables via the KernelSignature<T...> type. This kernel 
is general for any provided oracle, and demonstrates the utility of the classical language extension, whereby all existing classical control flow structures are 
usable (e.g. for loops).
</td>
<td width="450">
Finally, to use this general grover library code, we just include it as one would for any external library. We define an oracle quantum kernel, and pass it 
to the general grover call. Our oracle in this example marks states |101> and |011>, so our results should see these states each with 50% probability.
</td>
</tr>
<tr>
<td width="500">

```sh
# Compile with qcor, target any quantum coprocessor
$ qcor -qpu ibm:ibmq_vigo -shots 8192 bell.cpp
# Execute the binary
$ ./a.out
```
</td>
</tr>

</table>
