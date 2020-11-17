---
title: "Pass Manager"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The QCOR infrastructure has a wide variety of quantum circuit transformation plugins, which are often referred to as *transpilers* in the literature.

There are two categories of transpilers: *circuit optimization* and *placement*. 

Circuit optimizers are plugins that can rewrite the input circuits into a more optimal form (fewer gates) while reserving the intended transformation (e.g. in terms of the overall unitary matrix). 

Placement plugins act as the final router to map or embed the circuit into the backend hardware topology. This placement action is not relevant for simulation but is very important for NISQ hardware execution due to limited connectivity.

These reentrant transpiler plugins are executed as passes over the circuit IR tree. The sequence of these passes is determined by the QCOR's **pass manager**. The pass manager will execute circuit optimization passes depending on the optimization level or manual command-line settings, then a single placement pass (selectable) taking into account the target qpu topology.
 

### <a id="pmusage"></a> Basic usage

There are 3 levels of optimization that have been pre-defined in QCOR:

- Level 0: no optimization.

- Level 1: `rotation-folding`, `single-qubit-gate-merging`, and `circuit-optimizer`

- Level 2: level 1 passes + `two-qubit-block-merging`

The descriptions of those optimization passes are shown below.

|   Pass name                  |                  Description                                           |    
|------------------------------|------------------------------------------------------------------------|
| `circuit-optimizer`          | A collection of simple pattern-matching-based circuit optimization routines.| 
| `single-qubit-gate-merging`  | Combines adjacent single-qubit gates and finds a shorter equivalent sequence if possible.|    
| `two-qubit-block-merging`    | Combines a sequence of adjacent one and two-qubit gates operating on a pair of qubits and tries to find a more optimal gate sequence via Cartan decomposition if possible.|    
| `rotation-folding`           | A wrapper of the [Staq](https://github.com/softwareQinc/staq)'s `RotationOptimizer` which implemented the rotation gate merging algorithm.| 
| `voqc`                       | A wrapper of the [VOQC](https://github.com/inQWIRE/SQIR) (Verified Optimizer for Quantum Circuits) OCaml library, which implements generic gate propagation and cancellation optimization strategy.| 

The optimization level can be specified by `-opt [0,1,2]` the QCOR command-line option.

The pass manager also collected detailed statistics about each optimization pass that it executed. This information can be printed out by providing the `-print-opt-stats` option to the QCOR compiler when compiling your source code.

For backend placement, by default, QCOR will perform the `swap-shortest-path` placement if the backend has topology (connectivity) information. 
Different placement strategies can be specified using the `-placement` command-line option.

The list of available placement services is shown in the following.
|   Placement name             |                  Description                                           |    
|------------------------------|------------------------------------------------------------------------|
| `swap-shortest-path`         | Wrapper of the [Staq](https://github.com/softwareQinc/staq)'s `SwapMapper`| 
| `triQ`  | Noise adaptive layout based on [TriQ](https://github.com/prakashmurali/TriQ) library.|    
| `enfield`    | Wrapper of [enfield](https://github.com/ysiraichi/enfield) allocators. This needs to be installed manually from the XACC [fork](https://github.com/ORNL-QCI/enfield/tree/xacc)|    


### <a id="pmadvancedusage"></a> Advanced usage 

Custom sequences of optimization passes can be specified using the following compile option:

```sh
qcor -qpu qpp -opt-pass pass1[,pass2] source.cpp
```

in which, users provide an ordered (comma-separated) list of passes to be executed using the `-opt-pass` key.

This can be used in conjunction with the `-print-opt-stats` option to collect the statistics if required.


Manual qubit mapping can be used instead of topology-based placement by providing the `-qubit-map` option followed by the list of qubit indices specifying the mapping. 

For example, `-qubit-map 2,1,4,3,0` dictates the following mapping 0->2, 1->1, 2->4, 3->3, 4->0.
It is important to note that no further placement is performed after the `-qubit-map` based mapping. Hence, users need to make sure that the mapping is appropriate for the target hardware backend.

### <a id="pmexamples"></a> Examples

#### Circuit Optimization

In this example, we just compile a simple circuit using the QCOR compiler.
The circuit contains a pair of mergeable rotation gates. 

<table>
<tr>
<th>C++</th>
<th>Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void test_circ(qreg q) {
  H(q[0]);
  Rx(q[0], 0.123);
  Rx(q[0], 0.456);
}

int main() {
  // Create a qubit register
  auto q = qalloc(1);
  // Run the quantum kernel
  test_circ(q);
  q.print();
}
```
</td>
<td>

```Python
@qjit
def test_circ(q : qreg):
  H(q[0])
  Rx(q[0], 0.123)
  Rx(q[0], 0.456)


# Create a qubit register
q = qalloc(1)
# Run the quantum kernel
test_circ(q)
q.print()
```
</td>
</tr>
<tr>
<td>

```sh
qcor -opt 1 -print-opt-stats simple_circuit.cpp 
./a.out
```
</td>
<td>

```sh
python3 simple_circuit.py -opt 1 -print-opt-stats
```
</td>
</tr>
</table>

We compiled the above QCOR kernel source using optimization level 1 and request optimization statistics.

When the executable is executed, we can see the optimization data printed out, which confirm that the two `Rx` rotation gates
have been merged into one.

```
 - Number of Gates Before: 3
 - Number of Gates After: 2
--------------------------------
| GATE     |BEFORE   |AFTER    |
--------------------------------
| Rx       |2        |1        |
| H        |1        |1        |
--------------------------------
```

#### Placement

Let's take a look at an example where qubit placement is required for target hardware backends.

```cpp
// Create a GHZ state
__qpu__ void create_ghz(qreg q) {
  H(q[0]);
  CX(q[0], q[1]);
  CX(q[0], q[2]);
  for (int i = 0; i < q.size(); i++) {
    Measure(q[i]);
  }
}

int main() {
  // Print out the kernel for submission
  auto q = qalloc(3);
  create_ghz::print_kernel(std::cout, q);
}
```

It's a simple experiment to create a 3-qubit entangle state. Albeit its simplicity, not all quantum devices can execute this circuit as is since it requires triangular connectivity between qubit 0, 1, and 2.

Let's compile and execute the above source code targeting two different hardware backends:

<table>
<tr>
<th>ibmq_ourense</th>
<th>ibmqx2</th>
</tr>
<tr>
<td>

```
0 -- 1 -- 2 
     |      
     3       
     |       
     4  
```
</td>
<td>

```
      1
    / | 
   /  |
  /   |
 /    |
0 --  2  --  3
      |     /
      |    /
      |   / 
      |  /
      4
```
</td>
</tr>
<tr>
<td>

```sh
qcor -qpu ibm:ibmq_ourense simplePlacement.cpp 
./a.out
```
</td>
<td>

```sh
qcor -qpu ibm:ibmqx2 simplePlacement.cpp 
./a.out
```

</td>
</tr>

<tr>
<td>

```
H q0
CNOT q1,q0
CNOT q0,q1
CNOT q1,q2
Measure q1
Measure q0
Measure q2
```
</td>
<td>

```
H q0
CNOT q0,q1
CNOT q0,q2
Measure q0
Measure q1
Measure q2
```
</td>
</tr>
</table>

As we can see, due to the limited connectivity of the `ourense` backend, an additional CNOT gate is required (plus the remapping of qubits) after placement. The `qx2` backend has triangular connectivity groups (0-1-2 and 2-3-4), and thus it can map the GHZ state-preparation circuit to its qubits directly.