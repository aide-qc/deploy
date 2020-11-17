---
date: 2017-10-19T15:26:15Z
lastmod: 2019-10-26T15:26:15Z
publishdate: 2018-11-23T15:26:15Z
---

# AIDE-QC Software Stack
AIDE-QC is a next-generation software stack enabling heterogeneous quantum-classical programming, compilation, and execution on both near-term and future fault-tolerant quantum computers. Our approach treats quantum computers as novel co-processors and puts forward C++ and Pythonic programming models for quantum code expression and compilation to native backend gate sets. 

The AIDE-QC project decomposes the stack research and development into Programming, Compiler, Verification and Validation, Error Mitigation, Optimization, and Software Integration thrusts. The union of these efforts represents the development of a holistic software ecosystem that enables an extensible and modular approach to the quantum-classical programming workflow. 

AIDE-QC builds upon the service-oriented [XACC](background/xacc.md) quantum programming framework and puts forward service interfaces or plugins for quantum language parsing, intermediate representations, transformations on compiled circuits, error mitigation strategies, and backend execution and emulation, to name a few. These plugin interfaces enable the AIDE-QC to remain flexible as the quantum computing research landscape grows and advances. On top of that, AIDE-QC puts forward a novel C++ compiler for heterogeneous quantum-classical computing, [QCOR](background/qcor.md).

Below we give a quick demonstration of how a simple quantum-classical Hello World code (preparing a Bell state on 2 qubits) can be programmed using AIDE-QC in both C++ and Python:
<table>
<tr>
<th>Quantum Hello World - C++</th>
<th>Quantum Hello World - Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void bell(qreg q) {
    H(q[0]);
    CX(q[0], q[1]);
    for (int i : range(q.size())) {
        Measure(q[0]);
    }
}
int main() {
    auto q = qalloc(2);
    bell(q);
    auto counts = q.counts();
    for (auto [bits, count] : counts) {
        print(bits, ":", count);
    }
}
```
```sh
qcor -qpu ibm:ibmq_vigo -shots 8192 bell.cpp
./a.out
```
</td>
<td>

```python
from qcor import *

@qjit
def bell(q : qreg):
    H(q[0])
    CX(q[0], q[1])
    for i in range(q.size()):
        Measure(q[i])

q = qalloc(2)
bell(q)
counts = q.counts()
for bits, count : counts.items():
    print(bits, ':', count)


```
```sh
python3 bell.py -qpu tnqvm -shots 1024

``` 
</td>
</tr>
</table>

To start using the AIDE-QC quantum-classical software stack, head over to [Getting Started](getting_started/_index.md)