---
title: "Hello World"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The AIDE-QC software stack promotes a hardware-agnostic, single-source programming model for efficient 
and extensible heterogeneous quantum-classical computing. Here we want to provide a small hello world 
example that attempts to demonstrate that model. Specifically, we will show how to program 
a simple GHZ state quantum kernel that can run on any of the available QPUs that are integrated 
with the AIDE-QC stack. 

Let's start of in C++. We start by describing a quantum kernel - a C++ function, annotated with `__qpu__` whose 
function body contains some quantum code. 
```cpp
__qpu__ void ghz(qreg q) {
    // hadamard on first qubit
    H(q.head()); 
    // CNOTs on (i,i+1) pairs
    for (int i : range(q.size()-1))
        X::ctrl(q[i], q[i+1]);
    Measure(q);
}
int main() {
    // Allocate some qubits
    auto q = qalloc(5);
    // Run the 5 qubit GHZ code
    ghz(q);
    // Show the resultant counts
    for (auto [bits, counts] : q.counts()) {
        print(bits, ": ", counts);
    }
}
```
```sh
qcor -qpu qpp -shots 1024 -o ghz.x ghz.cpp
# One could also compile-only and link in a separate step
qcor -qpu qpp -shots 1024 -o ghz.o -c ghz.cpp
qcor ghz.o -o ghz.x
# Run
./ghz.x
00000: 530
11111: 494
```
To run this on an actual QPU (make sure your [credentials](remote_qpu_creds/#ibm) are set):
```sh
qcor -qpu ibm:ibmq_vigo -shots 1024 -o ghz_ibm.x ghz.cpp
./ghz_ibm.x
IBM Job 5fa04ee1d3b8d80013995877 Status: COMPLETED.                    
00000: 427
00001: 11
00011: 5
00100: 6
00110: 3
00111: 4
01000: 8
01101: 2
01110: 3
01111: 10
10000: 5
10010: 1
10110: 5
10111: 16
11000: 17
11010: 2
11011: 6
11100: 4
11101: 12
11110: 75
11111: 402
```
We should note that the logical connectivity of the GHZ state on 5 qubits does not directly map one-to-one on the IBM Vigo backend. `qcor` is able to automatically provide this connectivity mapping (we call it qubit placement, more details at [pass manager](pass_manager)). 

We could also run this via the AIDE-QC Python JIT quantum kernel compiler. 
```python
from qcor import qjit, qalloc, qreg

# one can set the qpu programmatically 
# set_qpu('qpp', {'shots': 2048})

@qjit
def ghz(q : qreg):
    H(q[0])
    for i in range(q.size()-1):
        X.ctrl(q[i], q[i+1])
    Measure(q)

q = qalloc(5)
ghz(q)
for bits, counts in q.counts().items():
    print(bits, ':', counts)
```
To run this on the Aer quantum circuit simulator, here we show perfect and noisy simulation, and physical execution:
```sh
# Simulated, no noise
python3 ghz.py -qpu aer -shots 1024
00000 : 550
11111 : 474

# Simulated with IBM Vigo noise model
python3 ghz.py -qpu aer:ibmq_vigo -shots 1024
00000 : 488
00001 : 7
00010 : 2
00100 : 4
01000 : 9
01110 : 1
01111 : 13
10000 : 10
10110 : 1
10111 : 15
11011 : 5
11100 : 1
11101 : 4
11110 : 99
11111 : 365

# Physical IBM Vigo execution
python3 ghz.py -qpu ibm:ibmq_vigo -shots 1024
IBM Job 5fa050bba19c1900139f2951 Status: COMPLETED....                   
00000 : 488
00001 : 14
00010 : 6
00011 : 2
00100 : 6
00101 : 1
00110 : 1
00111 : 2
01000 : 3
01110 : 2
01111 : 14
10000 : 3
10110 : 3
10111 : 10
11000 : 9
11001 : 1
11010 : 6
11011 : 6
11100 : 8
11101 : 12
11110 : 51
11111 : 376
```
