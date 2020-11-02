---
title: "Quantum Kernels"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The AIDE-QC stack programming model treats available QPUs (physical or virtual) as general co-processors. Programming those co-processors consists of defining what we call *quantum kernels* - standard functions (in the classical language) whose function body is made up of some quantum domain specific language (DSL), and the function is annotated appropriately to indicate that this function is *quantum*. These domain specific languages can be low-level quantum assembly representations, or high-level language constructs that the `qcor` compiler can parse and compile to appropriate instructions for the targeted backend. As of this writing, the `qcor` compiler allows quantum kernel expression using the XACC XASM and IBM OpenQasm assembly dialects, as well as a higher-level unitary matrix decomposition mechanism that lets programmers express algorithms as unitary matrices that the compiler decomposes to one and two qubit gates. We also support a Pythonic form of the XASM dialect for use in defining single-source Pythonic quantum kernels. Ultimately, quantum kernel expressions in the AIDE-QC stack will have the following form (`args...` here implies any argument types can be passed to the kernel)

<table>
<tr>
<th>C++ Quantum Kernel Structure</th>
<th>Pythonic Quantum Kernel Structure</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void kernel(qreg q, args...) {
   ... qDSL ... 
}
```
</td>
<td>

```python
@qjit
def kernel(q : qreg, args...):
    ... Pythonic qDSL ... 
```
</td>
</tr>
</table>

In C++, we require users annotate quantum kernel functions with `__qpu__`. This annotations is actually a preprocessor definition that expands to `[[clang::syntax(qcor)]]` to interface the kernel with the [Clang Syntax Handler](../developers/clang_syntax) infrastructure. This ensures proper processing of the quantum DSL within the kernel function body and maps it to appropriate `qcor` runtime API calls. These kernels must take a `qreg` (quantum register) instances a function argument to operate the quantum code on. After that, kernels can take any further function arguments that parameterize the quantum computation. 

In Python, we require users annotate quantum kernel functions with the `@qjit` decorator. This decorator gives us the ability to analyze the quantum kernel function body and just-in-time compile it using the `qcor` [QJIT]() infrastructure (which further delegates to the [Clang Syntax Handler](../developers/clang_syntax) and the [LLVM JIT Engine](https://llvm.org/docs/tutorial/BuildingAJIT1.html)). These functions must also take a `qreg` that the kernel function body operates on, and can take any further arguments to parameterize the quantum code. However, note that in Python, programmers must provide the correct type hint for the function argument. This helps our infrastructure not have to perform argument type inference when mapping to C++ and the `QJIT` infrastructure. 

The AIDE-QC programming model adheres extra functionality to quantum kernels. Specifically, given a quantum kernel, programmers should be able to produce controlled and adjoint versions of the kernel, as well as print or query structural information about the kernel. Given a kernel `foo`, one should be able to leverage `foo::ctrl(...)` in C++, or `foo.ctrl(...)` in Python. Similarly for the `adjoint` or reverse of a kernel. Quantum kernels should also enable printing to a stream, and querying the number of instructions, depth, etc. Here is an example of using `ctrl`, `adoint`, and other kernel query functions:
<table>
<tr>
<th>C++ Extra Kernel Functionality</th>
<th>Pythonic Quantum Kernel Structure</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void oracle(qreg q) {
   int bitIdx = q.size() - 1;
   T(q[bitIdx]);
}

__qpu__ void qpe(qreg q) {
  ...
  for (auto i = 0; i < bitPrecision; i++) {
    for (int j = 0; j < (1 << i); j++ ) {
        oracle::ctrl(i, q);
    }
  }
  ...
}
```
</td>
<td>

```python
@qjit
def oracle(q : qreg):
   bitIdx = q.size() - 1
   T(q[bitIdx])

@qjit
def qpe(q : qreg):
    ...
    for i in range(bitPrecision):
        for j in range(1<<i):
            oracle.ctrl(i, q)
    ...


```
</td>
</tr>
<tr>
<td>

```cpp
__qpu__ void measure_all(qreg q) {
  for (int i : range(q.size()) {
    Measure(q[i]);
  }
}

__qpu__ void kernel(qreg q, double x) {
    X(q[0]);
    Ry(q[1], x);
    CX(q[1],q[0]);
}

__qpu__ void do_nothing(qreg q, double x) {
    quantum_kernel(q,x);
    quantum_kernel::adjoint(q,x);
    measure_qbits(q);
}
```
</td>
<td>

```python
@qjit
def measure_all(q : qreg):
  for i in range(q.size()):
     Measure(q[i])

@qjit
def kernel(q : qreg, x : float):
    X(q[0])
    Ry(q[1], x)
    CX(q[1],q[0])

@qjit
def do_nothing(q : qreg, x : float):
    quantum_kernel(q,x)
    quantum_kernel.adjoint(q, x)
    measure_qbits(q)
}
```
</td>
</tr>
<tr>
<td>

```cpp
__qpu__ void kernel(qreg q, double x) {
    X(q[0]);
    Ry(q[1], x);
    CX(q[1],q[0]);
}
int main() {
    auto q = qalloc(2);
    kernel::print_kernel(std::cout, q, 2.2);
    auto n_inst = kernel::n_instructions(q, 2.2);
}
```
</td>
<td>

```python
@qjit
def kernel(q : qreg, x : float):
    X(q[0])
    Ry(q[1], x)
    CX(q[1],q[0])

q = qalloc(2)
kernel.print_kernel(q, 2.2)
n_inst = kernel.n_instructions(q, 2.2)

```
</td>
</tr>
</table>

Now we will...

## XASM

## OpenQasm

## Unitary Matrix

## Python
