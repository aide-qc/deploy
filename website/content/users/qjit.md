---
title: "Quantum JIT (QJIT)"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The quantum kernel programming model in C++ for the AIDE-QC stack relies on a novel 
Clang plugin interface called the [SyntaxHandler](../developers/clang_syntax). This infrastructure 
enables quantum programming with annotated C++ functions in a language agnostic manner. A downside to 
this is that quantum kernels are defined at compile-time and are therefore less-flexible for use cases 
where runtime-generated circuits are useful. 

To address this, we have put forward an infrastructure for just-in-time compilation of quantum kernels. 
This infrastructure enables one to programmatically run the `SyntaxHandler` workflow and compile 
the resultant C++ API code to an LLVM [Module](https://llvm.org/doxygen/classllvm_1_1Module.html). This `Module` 
is used as input to the LLVM JIT infrastructure which enables us to create function pointers to 
compiled quantum kernels at runtime. 

We have packaged this infrastructure into a simple, easy-to-use `QJIT` class. This class exposes a `jit_compile()` 
method that takes C++ quantum kernels and executes the entire `SyntaxHandler` -> LLVM IR --> LLVM JIT workflow. 

Let's demonstrate how one might use this in C++:

```cpp
// To use the QCOR JIT utilities 
// just include the qcor_jit.hpp header
#include "qcor_jit.hpp"

int main() {

  // QJIT is the entry point to QCOR quantum kernel 
  // just in time compilation
  QJIT qjit;

  // Define a quantum kernel string dynamically
  const auto kernel_src = R"#(__qpu__ void bell(qreg q) {
        using qcor::openqasm;
        h q[0];
        cx q[0], q[1];
        creg c[2];
        measure q -> c;
    })#";

  // Use the QJIT instance to compile this at runtime
  qjit.jit_compile(kernel_src);

  // Now, one can get the compiled kernel as a 
  // functor to execute, must provide the kernel 
  // argument types as template parameters
  auto bell_functor = qjit.get_kernel<qreg>("bell");

  // Allocate some qubits and run the kernel functor
  auto q = qalloc(2);
  bell_functor(q);
  q.print();

  // Or, one can call the QJIT invoke method 
  // with the name of the kernel function and 
  // the necessary function arguments.
  auto r = qalloc(2);
  qjit.invoke("bell", r);
  r.print();

  // Note, if QCOR QJIT has not seen this kernel 
  // source code before, it will run through the 
  // entire JIT compile process. If you have run 
  // this JIT compile before, QCOR QJIT will read a 
  // cached representation of the kernel and load that, 
  // increasing JIT compile performance. 
}
```
The `QJIT` class is provided by the `qcor_jit.hpp` header. Programmers simply instantiate the data structure, define the kernel source code string, and 
invoke the `jit_compile` method. This will internally store pointers to the compiled quantum kernel functions, which you can access via the `get_kernel<T...>(name:string)` method, which takes the argument types and the name of the kernel. This function pointer can be called just like one would call a pre-defined quantum kernel funciton. One can also use the `invoke(name:string, args:T...)` method, which will invoke the internal function pointer with the given arguments. 

A key feature of this workflow is that all compiled kernel LLVM IR `Modules` are cached. This means that after the first `jit_compile` call for a given kernel string, the resultant `Module` bitcode will be stored and associated with a unique hash for the kernel source string. Everytime this code is run again, the execution time will be faster because internally we will load the cached `Module` instead of going through the entire compile workflow. 

One can also use this infrastructure from Python:

```python
from qcor import QJIT, qreg, qalloc

# Instantiate the QJIT
qjit = QJIT()

# Define your kernel source
kernel_src = '''__qpu__ void bell(qreg q) {
        using qcor::openqasm;
        h q[0];
        cx q[0], q[1];
        creg c[2];
        measure q -> c;
    }'''

# JIT Compile
qjit.jit_compile(kernel_src)

# Invoke the kernel.
# Note, in Python we have to provide the args as 
# a dict, where keys have to match the arg 
# name in the kernel source
q = qalloc(2)
qjit.invoke('bell', {'q':q})
q.print()

# You could also view the re-written C++ src
kernel_name, cpp_src = qjit.run_syntax_handler(kernel_src)
print(cpp_src)
```

