---
title: "User Guide"
date: 2019-11-29T15:26:15Z
draft: false
weight: 10
---
Welcome to the AIDE-QC User Guide. Here we document how to use the various aspects of the AIDE-QC quantum programming, compilation, and execution software stack. The links below detail the various mechanics of the stack, how to define quantum code, build certain plugins, leverage the ahead-of-time and just-in-time compilers, and express quantum-classical algorithms. 

The user guide pages are listed below, with pertinent sub-sections called out for quick access to specific information. 

[Hello World - Simple GHZ State](hello_world) 

[Quantum Kernels - Language Extensibility](quantum_kernels)
* [XASM](quantum_kernels/#xasm)
* [OpenQasm](quantum_kernels/#openqasm)
* [Unitary Matrix](quantum_kernels/#matrix)
* [Python XASM](quantum_kernels/#pyxasm)
* [Python Unitary Matrix](quantum_kernels/#pyxasm_unitary)

[Operators - Hamiltonian Expression](operators)
* [Spin](operators/#spin)
* [Fermion](operators/#fermion)
* [Chemistry](operators/#chemistry)
* [OpenFermion](operators/#openfermion)
* [Operator Transformations](operators/#transforms)

[Remote QPU Credentials](remote_qpu_creds)
* [IBM API Credentials](remote_qpu_creds/#ibm)

[Using an Optimizer](using_optimizer)
* [Create an Optimizer](using_optimizer/#create-optimizer)
* [Optimize a Custom Function](using_optimizer/#optimize-function)
* [Available Optimizers](using_optimizer/#available-optimizers)
    * [mlpack](using_optimizer/#avail-mlpack)
    * [nlopt](using_optimizer/#avail-nlopt)

[Tensor Network Quantum Virtual Machine](tnqvm)
* [Installing TNQVM](tnqvm/#installation)
* [Using TNQVM](tnqvm/#usage)

[Pass Manager - Optimizing Circuits and Qubit Placement](pass_manager)
* [Basic Usage](pass_manager/#pmusage)
* [Advanced Usage](pass_manager/#pmadvancedusage)
* [Examples](pass_manager/#pmexamples)

[Quantum JIT - Just-In-Time Compilation of Quantum Kernels](qjit)
* [Use in C++](qjit)
* [Pythonic QJIT](qjit/#pyqjit)
    * [Advanced Variational Argument Translation](qjit/#pyqjit_translate)

[Quantum Simulation (QSim) Library](qsim)
* [Overview](qsim/#overview)
* [Simulation Model](qsim/#problem-model)
* [Workflow](qsim/#workflow)
    * [Variational Quantum Eigensolver - VQE](qsim/#vqe-workflow)
    * [Quantum Approximate Optimization Algorithm - QAOA](qsim/#qaoa-workflow)
    * [Quantum Imaginary Time Evolution - QITE](qsim/#qite-workflow)
    * [Time-dependent Simulation](qsim/#td-ham-workflow)
* [Cost Function (Observable) Evaluate](qsim/#cost-eval)
    * [Partial Tomography](qsim/#partial-tomo)
    * [Quantum Phase Estimation](qsim/#phase-est)
* [Custom Workflow](qsim/#new-workflow)
