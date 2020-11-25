---
title: "Quantum Simulation (QSim)"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

The QSim library provides domain-specific tools for quantum simulation on quantum computes. It supports problems such as ground-state energy computations or time-dependent simulations.

The library comprises the main drivers, so-called workflows (`QuantumSimulationWorkflow`), which encapsulate the procedure (classical and quantum routines) to solve the quantum simulation problem. The input to QSim's workflows is a `QuantumSimulationModel`, specifying all the parameters of the quantum simulation problem, e.g., the observable operator, the Hamiltonian operator, which may be different from the observable or is time-dependent, etc.

The QSim library provides a `ModelBuilder` factory to facilitate `QuantumSimulationModel` creation for common use cases.

Built-in workflows can be retrieved from the registry by using getWorkflow helper function with the corresponding workflow name, such as `vqe`, `qaoa`, `qite`, etc. 

Some workflow may require additional configurations, which should be provided when calling getWorkflow. Please refer to specific workflow sections for information about their supported configurations. 

The retrieved workflow instance can then be used to solve the `QuantumSimulationModel` problem using the execute method, which returns the result information specific to that workflow, such as the ground-state energy for variational quantum eigensolver workflow or the time-series expectation values for time-dependent quantum simulation.

For advanced users or workflow developers, the QSim library also provides interfaces for state-preparation (ansatz) circuit generation and cost function (observable) evaluator. 

The first can be used during workflow execution to construct the quantum circuits for evaluation, e.g., variational circuits of a particular structure or first-order Trotter circuits for Hamiltonian evolution. 

The latter provides an abstraction for quantum backend execution and post-processing actions to compute the expectation value of an observable operator. For example, the cost function evaluator may add necessary gates to change the basis according to the observable operators, analyze the bitstring result to extract the expectation value. For more information, please refer to the Custom Workflow section.