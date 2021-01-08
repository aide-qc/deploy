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
auto [kernel_name, cpp_src] = qjit.run_syntax_handler(kernel_src)
print(cpp_src)
```

## <a id="pyqjit"></a> Pythonic `@qjit`
We leverage the above C++ `QJIT` infrastructure to enable a single-source programming model for 
quantum-classical computing in Python. To do so, we have defined a new domain specific language that is
supported by our Clang Syntax Handler infrastructure that is XASM-like, but in Python. This language enables programmers to program quantum instructions in a manner that is acceptable to the first-pass of the Python interpreter's syntax check. We have defined a novel Python decorator, `@qjit`, that programmers leverage to defined Python functions written in our available pythonic XASM dialect (as well as a [unitary matrix decomposition language](quantum_kernels/#pyxasm_unitary)). This decorator provides a mechanism for analyzing the decorated function body (written in the `pyxasm` dialect) and just-in-time compiling it with the above C++ `QJIT` class. This mechanism produces an internal C++ function pointer that is called whenever the `qjit.__call__(*args)` method is invoked. 

Check out this simple GHZ state example
```python
from qcor import qjit, qalloc, qreg

@qjit
def ghz(q : qreg):
    H(q[0])
    for i in range(q.size()-1):
        CX(q[i], q[i+1])
    for i in range(q.size()):
        Measure(q[i])

q = qalloc(5)
ghz(q)
for bits, counts in q.counts().items():
    print(bits, ':', counts)
```
The `qjit.__init__()` method will leverage the [inspect](https://docs.python.org/3/library/inspect.html) module to analyze and pre-process the source code representation of the function body, and send the source string to the `QJIT::jit_compile()` call, kicking off the `Syntax Handler -> Clang CodeGen -> LLVM Module -> LLVM JIT -> Function Pointer` workflow. The function pointer is invoked when `ghz(q)` is called. 

`qjit` exposes a number of methods that make it easy to query information about the kernel, or to map it to other representations. Let's demonstrate this for the GHZ state
```python
from qcor import qjit, qalloc, qreg

@qjit
def ghz(q : qreg):
    H(q[0])
    for i in range(q.size()-1):
        CX(q[i], q[i+1])
    for i in range(q.size()):
        Measure(q[i])

q = qalloc(5)

print('Kernel Name: ', ghz.kernel_name())
print('N Instructions: ', ghz.n_instructions(q))

print('As OpenQasm:\n', ghz.openqasm(q))
print('As XASM:\n')
ghz.print_kernel(q)

# For Developers and Debugging
print('Src code sent to QJIT:\n', ghz.get_internal_src() )
print('Src code compiled to LLVM IR:\n', ghz.get_syntax_handler_src())
```
This will print the following:
```sh
Kernel Name:  ghz
N Instructions:  10
As OpenQasm:
 OPENQASM 2.0;
include "qelib1.inc";
qreg qrg_nWlrB[5];
creg qrg_nWlrB_c[5];
h qrg_nWlrB[0];
CX qrg_nWlrB[0], qrg_nWlrB[1];
CX qrg_nWlrB[1], qrg_nWlrB[2];
CX qrg_nWlrB[2], qrg_nWlrB[3];
CX qrg_nWlrB[3], qrg_nWlrB[4];
measure qrg_nWlrB[0] -> qrg_nWlrB_c[0];
measure qrg_nWlrB[1] -> qrg_nWlrB_c[1];
measure qrg_nWlrB[2] -> qrg_nWlrB_c[2];
measure qrg_nWlrB[3] -> qrg_nWlrB_c[3];
measure qrg_nWlrB[4] -> qrg_nWlrB_c[4];

H qrg_nWlrB0
CNOT qrg_nWlrB0,qrg_nWlrB1
CNOT qrg_nWlrB1,qrg_nWlrB2
CNOT qrg_nWlrB2,qrg_nWlrB3
CNOT qrg_nWlrB3,qrg_nWlrB4
Measure qrg_nWlrB0
Measure qrg_nWlrB1
Measure qrg_nWlrB2
Measure qrg_nWlrB3
Measure qrg_nWlrB4

As XASM:
 None
Src code sent to QJIT:
 __qpu__ void ghz(qreg q) {
using qcor::pyxasm;

    H(q[0])
    for i in range(q.size()-1):
        CX(q[i], q[i+1])
    for i in range(q.size()):
        Measure(q[i])
}

Src code compiled to LLVM IR:
 void ghz(qreg q) {
void __internal_call_function_ghz(qreg);
__internal_call_function_ghz(q);
}
class ghz : public qcor::QuantumKernel<class ghz, qreg> {
friend class qcor::QuantumKernel<class ghz, qreg>;
protected:
void operator()(qreg q) {
if (!parent_kernel) {
parent_kernel = qcor::__internal__::create_composite(kernel_name);
}
quantum::set_current_program(parent_kernel);
if (runtime_env == QrtType::FTQC) {
quantum::set_current_buffer(q.results());
}
quantum::h(q[0]);
for (auto &i : range(q.size()-1)) {
quantum::cnot(q[i], q[i+1]);
}
for (auto &i : range(q.size())) {
quantum::mz(q[i]);
}

}
public:
inline static const std::string kernel_name = "ghz";
ghz(qreg q): QuantumKernel<ghz, qreg> (q) {}
ghz(std::shared_ptr<qcor::CompositeInstruction> _parent, qreg q): QuantumKernel<ghz, qreg> (_parent, q) {}
virtual ~ghz() {
if (disable_destructor) {return;}
auto [q] = args_tuple;
operator()(q);
if (runtime_env == QrtType::FTQC) {
if (is_callable) {
quantum::persistBitstring(q.results());
for (size_t shotCount = 1; shotCount < quantum::get_shots(); ++shotCount) {
operator()(q);
quantum::persistBitstring(q.results());
}
}
return;
}
xacc::internal_compiler::execute_pass_manager();
if (optimize_only) {
return;
}
if (is_callable) {
quantum::submit(q.results());
}
}
};
void ghz(std::shared_ptr<qcor::CompositeInstruction> parent, qreg q) {
class ghz __ker__temp__(parent, q);
}
void __internal_call_function_ghz(qreg q) {
class ghz __ker__temp__(q);
}
void ghz__with_hetmap_args(HeterogeneousMap& args) {
class ghz __ker__temp__(args.get<qreg>("q"));
}
void ghz__with_parent_and_hetmap_args(std::shared_ptr<CompositeInstruction> parent, HeterogeneousMap& args) {
class ghz __ker__temp__(parent, args.get<qreg>("q"));
}


// Fix for __dso_handle symbol not found
#ifndef __FIX__DSO__HANDLE__
#define __FIX__DSO__HANDLE__ 
int __dso_handle = 1;
#endif
```

One can also use `qjit` on an un-measured parameterized quantum kernel in order to compute the expectation value with respect to some provided `Operator`. 
```python
from qcor import *

H = -2.1433 * X(0) * X(1) - 2.1433 * \
    Y(0) * Y(1) + .21829 * Z(0) - 6.125 * Z(1) + 5.907

@qjit
def ansatz(q : qreg, theta : float):
    X(q[0])
    Ry(q[1], theta)
    CX(q[1], q[0])

q = qalloc(2)
# Note, first arg is the Operator, followed
# by the args required by the kernel
energy = ansatz.observe(H, q, .59)
print(energy)
```

### <a id="pyqjit_translate"></a> Advanced Variational Argument Translation

For advanced use cases that leverage variational algorithms through the AIDE-QC API, where the kernel argument structure may not be a simple float or list of floats, programmers need to provide a mechanism for translating between a list of floats (circuit parameters) and the argument structure for the kernel. Let's look at the following QAOA example
```python
from qcor import *
import numpy as np
from types import MethodType

# Define a QAOA kernel with variational parameters (theta and beta angles)
@qjit
def qaoa_circ(q: qreg, cost_ham: PauliOperator, nbSteps: int, gamma: List[float], beta: List[float]):
    # Start off in the uniform superposition
    for i in range(q.size()):
        H(q[i])
    
    terms = cost_ham.getNonIdentitySubTerms()
    for step in range(nbSteps):
        for term in terms:
            exp_i_theta(q, theta[step], term)

        # Reference Hamiltonian: 
        for i in range(len(q)):
            ref_ham_term = X(i)
            exp_i_theta(q, beta[step], ref_ham_term)
   
# Allocate 4 qubits
q = qalloc(4)
n_steps = 3
# Hamiltonion:
H = -5.0 - 0.5 * (Z(0) - Z(3) - Z(1) * Z(2)) - Z(2) + 2 * Z(0) * Z(2) + 2.5 * Z(2) * Z(3)

# Custom arg_translator in a Pythonic way
def qaoa_translate(self, q: qreg, x: List[float]):
    ret_dict = {}    
    ret_dict["q"] = q
    ret_dict["cost_ham"] = H
    ret_dict["nbSteps"] = n_steps
    ret_dict["theta"] = x[:n_steps]
    ret_dict["beta"] = x[n_steps:]
    return ret_dict

# Rebind arg translate:
qaoa_circ.translate = MethodType(qaoa_translate, qjit)

# Use the standard parameterization scheme: 
# one theta + one beta per step
n_params = 2 * n_steps
obj = createObjectiveFunction(qaoa_circ, H, n_params)

# Run optimization
optimizer = createOptimizer('nlopt', {'initial-parameters': np.random.rand(n_params)})
results = optimizer.optimize(obj)
```
Here we have a quantum kernel `qaoa_circ` that is building up the QAOA ansatz for a provided cost Hamiltonian. Input to the kernel is the `qreg`, the cost Hamiltonian, the number of QAOA steps, and the cost and mixing parameters, `gamma` and `beta`. In order to leverage this ansatz with `ObjectiveFunction` or the `QuaSiMo` library, we must provide a mechanism for translating variational parameters `x : List[float]` to kernel arguments. 

To accomplish this, we require programmers to specify a function that takes a `qreg` and a `List[float]` and creates and returns a dictionary mapping kernel argument variable names to concrete values (either from global scope or from the incoming `List[float]`). In the QAOA example, we take global `H` and `n_steps` and map them to the corresponding argument variable name in the kernel definition. We also split the incoming `List[float]` and map them to `gamma` and `beta` keys. To inject this translation function into the `qjit` instance, we leverage `types.MethodType` and set the `qjit` instance (the function name) `translate` method. We are now free to use this parameterized kernel within the variational datastructures exposed by the AIDE-QC stack. 