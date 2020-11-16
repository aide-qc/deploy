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

Now we turn our attention to the different ways one might write quantum kernel function bodies, i.e. the current set of low-level and high-level quantum DSLs that we support in the AIDE-QC programming stack. 

## <a id="xasm"></a> XASM
The default language in C++ for quantum kernels is based on the XACC XASM quantum assembly language. This language provides a source-level representation of the internal XACC quantum intermediate representation (IR). Out of all the quantum languages supported by AIDE-QC, the XASM language supports the most classical C++ control flow mechanisms (`for`, `if`, etc.). It also allows mixing certain classical statements that help in constructing the quantum kernel most efficiently, such as simple variable assignment and use. This language supports most one and two qubit gate instructions, and rotation gates can be parameterized by incoming kernel arguments. 

Let's turn our attention to some examples. First we look at an IBM-style [hardware efficient ansatz](https://www.nature.com/articles/nature23879) to demonstrate the utility of existing C++ control flow intermixed with quantum instructions.
```cpp
__qpu__ void hwe(qreg q, std::vector<double> x, const int layers,
                 std::vector<std::pair<int, int>> cnot_coupling) {
  // Get the number of qubits
  auto n_qubits = q.size();
  // Loop over layers
  for (auto layer : range(layers)) {
    // Create first Rx Rz layer
    for (auto i : range(n_qubits)) {
      // Shift the x vector idx based on the layer we are in
      auto rx_xidx = layer * n_qubits * 5 + i;
      auto rz_xidx = layer * n_qubits * 5 + i + q.size();
      Rx(q[i], x[rx_xidx]);
      Rz(q[i], x[rz_xidx]);
    }

    // Next set of angle indices will be shifted
    auto shift = n_qubits * 2;

    // Apply the CNOTs
    for (auto [i, j] : cnot_coupling) {
      CX(q[i], q[j]);
    }

    // Add the final layer of rotation gates
    for (auto i : range(n_qubits)) {
      // Shift the idx based on the layer we are in
      auto rx1_xidx = layer * n_qubits * 5 + shift + i;
      auto rz_xidx = layer * n_qubits * 5 + shift + i + n_qubits;
      auto rx2_xidx = layer * n_qubits * 5 + shift + i + 2 * n_qubits;
      Rx(q[i], x[rx1_xidx]);
      Rz(q[i], x[rz_xidx]);
      Rx(q[i], x[rx2_xidx]);
    }
  }
}
```
In the above example, one can see the breadth of programming expressions that can be leveraged to construct 
common quantum circuits. This example takes a number of non-trivial function arguments, and leverages them 
to construct a general hardware efficient circuit, parameterized on a vector of angles `x`. The use of 
nested for loops and C++-17 structured bindings provide an expressive kernel DSL for programming general 
parameterized quantum kernels. This example applies layers of rotation + entangling + rotation patterns using C++ for loops, variable assignment on the stack, and quantum instruction calls. These instructions are not imported or included from an external library, they are part of the language extension itself. One can now use this kernel or print it to a QASM-like string in the following way 
```cpp
... with the above kernel definition ...
int main() {
  // Lets use 2 layers, 4 qubits, and nearest-neighbor coupling
  int layers = 2;
  auto q = qalloc(4);
  auto x_init = random_vector(-1., 1., q.size() * layers * 5);
  std::vector<std::pair<int, int>> coupling{{0, 1}, {1,2}, {2,3}};

  // Print the kernel to see it!
  hwe::print_kernel(std::cout, q, x_init, layers, coupling);
}
```

A more complicated example may be a kernel that generates a QAOA circuit based on 
a general cost Hamiltonian. Let's see how one might program that:
```cpp
__qpu__ void qaoa_ansatz(qreg q, int n_steps, std::vector<double> gamma,
                         std::vector<double> beta, PauliOperator& cost_ham) {

  // Local Declarations
  auto nQubits = q.size();
  int gamma_counter = 0;
  int beta_counter = 0;

  // Start off in the uniform superposition
  for (int i : range(nQubits)) {
    H(q[i]);
  }

  // Get all non-identity hamiltonian terms
  // for the following exp(H_i) trotterization
  auto cost_terms = cost_ham.getNonIdentitySubTerms();

  // Loop over qaoa steps
  for (int step : range(n_steps)) {

    // Loop over cost hamiltonian terms
    for (int i : range(cost_terms.size())) {

      // for xasm we have to allocate the variables
      auto cost_term = cost_terms[i];
      auto m_gamma = gamma[gamma_counter];

      // trotterize
      exp_i_theta(q, m_gamma, cost_term);

      gamma_counter++;
    }

    // Add the reference hamiltonian term
    // H_ref = SUM_i X(i)
    for (int i : range(nQubits)) {
      auto ref_ham_term = X(i);
      auto m_beta = beta[beta_counter];
      exp_i_theta(q, m_beta, ref_ham_term);
      beta_counter++;
    }
  }
}
```
Here one can see the usual use of C++ control flow to build up the QAOA circuit. The interesting part is the 
the non-trivial argument structure, whereby we are able to parameterize the kernel construction on the 
number of QAOA steps, gamma and beta parameter vectors, and the cost Hamiltonian itself, passed as a [PauliOperator](operators). 

## <a id="openqasm"></a> OpenQasm
The next quantum kernel language that the AIDE-QC stack supports is IBM's [OpenQasm](https://en.wikipedia.org/wiki/OpenQASM). Programmers can leverage this dialect by starting off the kernel with the `using qcor::openqasm` statement. Here is a simple example
```cpp
__qpu__ void bell(qreg q) {
    using qcor::openqasm;
    h q[0];
    cx q[0], q[1];
    creg c[2];
    measure q -> c;
}
```

There are a lot of quantum circuit benchmarking activities that leverage pre-generated OpenQasm source files. External OpenQasm files can be integrated with quantum kernels through the usual C++ preprocessor:
```cpp
__qpu__ void grover_5(qreg q) {
  using qcor::openqasm;
#include "grover_5.qasm"
}
```
This assumes a `grover_5.qasm` file is in the header search path. 

One can also mix XASM and OpenQasm languages (actually you can mix any available language):
```cpp
__qpu__ void bell_multi(qreg q, qreg r) {
  H(q[0]);
  CX(q[0], q[1]);

  using qcor::openqasm;

  h r[0];
  cx r[0], r[1];

  using qcor::xasm;
  
  for (int i = 0; i < q.size(); i++) {
    Measure(q[i]);
    Measure(r[i]);
  }
}
```
Since XASM is the default language, you don't have to specify `using qcor::xasm` to start off, but if you do switch to another language, you will need to specify `using qcor::xasm` if you switch back to XASM. 

## <a id="matrix"></a> Unitary Matrix
The AIDE-QC quantum kernel programming model also supports novel circuit synthesis strategies that 
take as input a general unitary matrix describing the desired quantum operation. We have defined 
another kernel language extension that allows one to program at the unitary matrix level and indicate 
to the compiler that this is intended for decomposition into one and two qubit gates based on some 
internal synthesis strategy. Let's demonstrate this by defining a Toffoli gate as a unitary matrix: 
```cpp
__qpu__ void ccnot(qreg q) {

  // set initial state to 111
  for (int i : range(q.size())) {
    X(q[i]);
  }

  // To program at the unitary matrix level,
  // invoke the decompose call, indicating which 
  // buffer to target, can optionally provide decomposition 
  // algorithm name and an optimizer. 
  decompose {
    // Create the unitary matrix
    UnitaryMatrix ccnot_mat = UnitaryMatrix::Identity(8, 8);
    ccnot_mat(6, 6) = 0.0;
    ccnot_mat(7, 7) = 0.0;
    ccnot_mat(6, 7) = 1.0;
    ccnot_mat(7, 6) = 1.0;
  }
  (q);

  // Add some measures
  for (int i = 0; i < q.size(); i++) {
    Measure(q[i]);
  }
}
int main() {
  // allocate 3 qubits
  auto q = qalloc(3);

  // By default this uses qfast with adam optimizer,
  // print what the unitary decomp was
  ccnot::print_kernel(std::cout, q);

  // Run the unitary evolution.
  ccnot(q);

  // should see 011 (msb) for toffoli input 111
  q.print();
}
```

Here we see that programmers declare a `decompose` scope, and inside define a unitary matrix using a provided 
`UnitaryMatrix` data structure (a `typedef` for `Eigen::MatrixXcd`). Once the matrix is defined, users close the `decompose` scope and provide at least the `qreg` to operate on. Programmers can also provide the circuit synthesis algorithm name (`QFAST` is the default) and a classical `Optimizer` to use for the decomposition strategy. 

## <a id="pyxasm"></a> Pythonic XASM
We have also defined a Pythonic version of the XASM language that provides quantum instructions alongside Pythonic control flow statements. This language was developed for our Python JIT compiler infrastructure, but can also be leveraged from C++ quantum kernel functions

<table>
<tr>
<th>PyXASM Language - C++</th>
<th>PyXASM Language - Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void ghz(qreg q) {
    using qcor::pyxasm;
    H(q[0])
    for i in range(q.size()-1):
        CX(q[i], q[i+1])
    for i in range(q.size()):
        Measure(q[i])
}
```
</td>
<td>

```python
@qjit
def ghz(q : qreg):
    H(q[0])
    for i in range(q.size()-1):
        CX(q[i], q[i+1])
    for i in range(q.size()):
        Measure(q[i])
```
</td>
</tr>
</table>

One should be able to use this Pythonic XASM language in the same ways that the C++ dialect is used. Below we demonstrate a Pythonic quantum phase estimation kernel that makes use of kernel composition and `ctrl` versions of dependent kernels:
```python
@qjit
def iqft(q : qreg, startIdx : int, nbQubits : int):
    """
    Define an inverse quantum fourier transform kernel
    """
    for i in range(nbQubits/2):
        Swap(q[startIdx + i], q[startIdx + nbQubits - i - 1])
            
    for i in range(nbQubits-1):
        H(q[startIdx+i])
        j = i +1
        for y in range(i, -1, -1):
            theta = -MY_PI / 2**(j-y)
            CPhase(q[startIdx+j], q[startIdx + y], theta)
            
    H(q[startIdx+nbQubits-1])

@qjit
def oracle(q : qreg):
    """
    Define the oracle for our phase estimation algorithm,
    a T gate on the last qubit
    """
    bit = q.size()-1
    T(q[bit])

@qjit
def qpe(q : qreg):
    """
    Run the quantum phase estimation kernel using the 
    ctrl of the oracle kernel and the pre-defined inverse 
    fourier transform. 
    """
    nq = q.size()
    X(q[nq - 1])
    for i in range(q.size()-1):
        H(q[i])
            
    bitPrecision = nq-1
    for i in range(bitPrecision):
        nbCalls = 2**i
        for j in range(nbCalls):
            ctrl_bit = i
            oracle.ctrl(ctrl_bit, q)
            
    # Inverse QFT on the counting qubits
    iqft(q, 0, bitPrecision)
            
    for i in range(bitPrecision):
        Measure(q[i])

q = qalloc(4)
qpe(q)
print(q.counts())
assert(q.counts()['100'] == 1024)
```
```sh
python3 qpe.py -shots 100
```

## <a id="pyxasm_unitary"></a> Pythonic Unitary Matrix
We have exposed a mechanism in Python (similar to the above C++ [decompose unitary](#unitary)) for circuit synthesis from a user provided unitary matrix. This mechanism builds off the Python 
`with EXPRESSION as VAR` syntax in order to allow programmers to specify a scope or block of code that 
describes or builds up a unitary matrix with the intent of letting the AIDE-QC compiler stack decompose or synthesize it into appropriate one and two qubit gates. 

Programmers can program the quantum co-processor at the unitary matrix level in Python in the following manner (here we demonstrate the matrix definition of a controlled CNOT gate):
```python
from qcor import *

@qjit
def ccnot_kernel(q : qreg):
    # create 111
    for i in range(q.size()):
        X(q[i])
            
    with decompose(q) as ccnot:
        ccnot = np.eye(8)
        ccnot[6,6] = 0.0
        ccnot[7,7] = 0.0
        ccnot[6,7] = 1.0
        ccnot[7,6] = 1.0
    
    # CCNOT should produce 110 (lsb)
    for i in range(q.size()):
        Measure(q[i])

# Execute the above CCNOT kernel
q = qalloc(3)
ccnot_kernel(q)
# should see 110
print(q.counts())
```

We start out by defining a Pythonic quantum kernel in the usual way, annotated with `@qjit` to indicate just-in-time compilation of the python kernel function. Programmers start the unitary matrix definition block by writing `with decompose(q) as ccnot`, following the general structure `with decompose(Args...) as MatrixVariableName`. `decompose` takes as its first argument the `qreg` to operate on. The second argument is the name of the circuit synthesis algorithm to leverage. Here we let the compiler decide which to use by not specifying it. Currently we support `QFAST` for general unitaries, `kak` for 2 qubit unitaries, and `z-y-z` for 1 qubit unitaries. The body of this `with` statement should contain any code necessary to build up the unitary matrix as a [Numpy](https://numpy.org/) `matrix` or `array` of shape `(N,N)` (you do not have to import `Numpy`, it is implicit in the compiler). The matrix variable name must be the same as what is specified after the `as` keyword. Note that this segment of code can be used interchangeably with PyXASM, here we have started by adding an `X` gate on all 3 qubits, and finished by applying `Measures`. 

Programmers are free to use `Numpy` fully within the scope of the `with decompose` statement. See here an example leveraging `np.kron()` to apply an `X` gate on all qubits
```python
@qjit
def all_x(q : qreg):
    with decompose(q) as x_kron:
        sx = np.array([[0, 1],[1, 0]])
        x_kron = np.kron(np.kron(sx,sx),sx)
            
    for i in range(q.size()):
        Measure(q[i])
```

Moreover, one can program unitary decomposition blocks that are dependent on kernel arguments. Here we demonstrate leveraging [SciPy](https://scipy.org) and [OpenFermion](https://openfermion.org) to define a unitary rotation `exp(.5i * x * (X0 Y1 - Y0 X1))` that we can leverage in a variational algorithm
```python
from qcor import *
@qjit
def ansatz(q : qreg, x : List[float]):
    X(q[0])
    with decompose(q, kak) as u:
        from scipy.sparse.linalg import expm
        from openfermion.ops import QubitOperator
        from openfermion.transforms import get_sparse_operator
        qop = QubitOperator('X0 Y1') - QubitOperator('Y0 X1')
        qubit_sparse = get_sparse_operator(qop)
        u = expm(0.5j * x[0] * qubit_sparse).todense()

# Run VQE with the above ansatz.
H = -2.1433 * X(0) * X(1) - 2.1433 * \
    Y(0) * Y(1) + .21829 * Z(0) - 6.125 * Z(1) + 5.907
q = qalloc(2)
objective = createObjectiveFunction(ansatz, H, 1)
optimizer = createOptimizer('nlopt', {'initial-parameters':[.5]})
results = optimizer.optimize(objective)
print(results)
```
Notice that since we know this is a two-qubit problem, we specify that `decompose` should leverage the `kak` synthesis algorithm. We are free to import modules within the scope and use those external modules to build up a `numpy` unitary matrix representation. Here we leverage OpenFermion, which gives one the ability to map `QubitOperators` to sparse matrices. Since we require `numpy.matrix` for the decomposition, we simply map from sparse to dense with `todense()`. The remainder of the above example demonstrates that one can use this quantum kernel with the rest of the AIDE-QC software stack, specifically for algorithm expression and execution. It is illuminating to compare the quantum kernel above with the [paper](https://arxiv.org/pdf/1801.03897.pdf) (Equation 7) it came from, and to note how efficient it is to map mathematical representations to compile-able quantum code. 



