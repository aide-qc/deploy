---
title: "Operators"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The AIDE-QC stack puts forward as part of the QCOR specification an extensible 
model for quantum mechanical operators. 

We sub-type this concept for operators exposing a certain algebra. We have defined `PauliOperator` and `FermionOperator` sub-types, and have put forward a mechanism for transformation between the two. 

## <a id="spin"></a> Spin Operators
AIDE-QC puts forward an `Operator` implementation to model Pauli matrices, Pauli tensor products, and sums of Pauli tensor products. The `PauliOperator` can be create in C++ and Python and used in the familiar algebraic name. We expose `X(int)`, `Y(int)`, and `Z(int)` API calls that return the corresponding Pauli operator on the provide qubit index. These can be used to build up more compilicated Pauli operators:
```cpp
auto H = 5.907 - 2.1433 * X(0) * X(1) - 2.1433 * Y(0) * Y(1) + .21829 * Z(0) -
           6.125 * Z(1);
```
Note here that algebraic operators are defined on this data structure, so composing simple Pauli matrices into larger tensorial product terms and summing them is extremely straightforward. These operators can also be created from string 
```cpp
auto H = createOperator(
      "5.907 - 2.1433 X0X1 - 2.1433 Y0Y1 + .21829 Z0 - 6.125 Z1");
```
And note, these API calls are also in Python
```python
from qcor import *
H = -2.1433 * X(0) * X(1) - 2.1433 * \
    Y(0) * Y(1) + .21829 * Z(0) - 6.125 * Z(1) + 5.907
H = createOperator(
      "5.907 - 2.1433 X0X1 - 2.1433 Y0Y1 + .21829 Z0 - 6.125 Z1")
```
Time-dependent Hamiltonians can be defined using these API calls:
```python
def td_hamiltonian(t):
  Jz = 2 * np.pi * 2.86265 * 1e-3
  epsilon = Jz
  omega = 4.8 * 2 * np.pi * 1e-3
  return -Jz * Z(0) * Z(1)  - Jz * Z(1) * Z(2) + (-epsilon * np.cos(omega * t)) * (X(0) + X(1) + X(2)) 
```

## <a id="fermion"></a> Fermion Operators
AIDE-QC puts forward an `Operator` implementation to model fermion operators. These can be constructed from 
exposed `adag(int)` and `a(int)` API calls representing fermion creation and annhilation operators, respectively. The instance returned from these API calls exposes appropriate algebra and can be used to construct more complicated fermionic tensor product terms. 
 
TODO finish this...

## <a id="chemistry"></a> Chemistry Operators

```python
H = createOperator('psi4', {'geometry':geom_str, 'basis':'sto-3g'})
-or-
H = createOperator('pyscf', {'geometry':geom_str, 'basis':'sto-3g'})
```

## <a id="openfermion"></a> OpenFermion Integration
Coming to a theater near you...

## <a id="optransforms"></a> Operator Transformations