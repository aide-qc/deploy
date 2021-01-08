---
title: "Add a New QuaSiMo Workflow"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

QuaSiMo is a domain-specific library for quantum simulation in the AIDE-QC software stack. 
The key extension point of QuaSiMo is its `QuantumSimulationWorkflow` interface, which is essentially the simulation driver for different protocols/procedures. Please refer to this [page](/deploy/users/quasimo/) for more information about QuaSiMo and its components. 

Besides its built-in workflow implementations (e.g. `vqe`, `qaoa`, etc.), users/developers may want to implement a new workflow (as a plugin) and contribute to the AIDE-QC stack. This section will provide a step-by-step guide on how to create a new QuaSiMo workflow. For simplicity, we use the VQE algorithm as an example, but please note that QuaSiMo already has a built-in implementation for VQE.

## <a id="create-workflow"></a> Create a New QuantumSimulationWorkflow 

The workflow is described via an abstract `QuantumSimulationWorkflow` class:

```cpp
// Quantum Simulation Workflow (Protocol)
// This can handle both variational workflow (optimization loop)
// as well as simple Trotter evolution workflow.

// Workflow result is stored in a HetMap
using QuantumSimulationResult = HeterogeneousMap;

// Abstract workflow:
class QuantumSimulationWorkflow : public Identifiable {
public:
  virtual bool initialize(const HeterogeneousMap &params) = 0;
  virtual QuantumSimulationResult
  execute(const QuantumSimulationModel &model) = 0;
};
```

Similar to [creating a new `Optimizer`](/deploy/developers/implement_optimizer/), to create a new QuaSiMo workflow, one need to subclass `QuantumSimulationWorkflow` and provide a concrete implementation.

Specifically, we need to provide a `name` and `description` string (`Identifiable` interface) and implement the `initialize` and `execute` methods of the `QuantumSimulationWorkflow` interface. Generally-speaking, `initialize` is where we parse any user-provided configuration parameters that the workflow supports, and `execute` is where we run the workflow procedure. This may include constructing quantum circuits, evaluating those circuits to estimate operator expectation values, classical processing and/or optimization, etc.

For example, we create a new custom VQE workflow implementation and name it `my-vqe` as follows:

```cpp
// VQE-type workflow which involves an optimization loop, i.e. an Optimizer.
class VqeWorkflow : public QuantumSimulationWorkflow {
public:
  virtual bool initialize(const HeterogeneousMap &params) override;
  virtual QuantumSimulationResult
  execute(const QuantumSimulationModel &model) override;

  virtual const std::string name() const override { return "my-vqe"; }
  virtual const std::string description() const override { return ""; }

private:
  std::shared_ptr<Optimizer> optimizer;
  HeterogeneousMap config_params;
};
```

In the above code, we create a new workflow named `my-vqe` and add any internal member variables as needed.

As an example, the simplified implementation of the `initialize` and `execute` methods are shown below.

```cpp
bool VqeWorkflow::initialize(const HeterogeneousMap &params) {
  const std::string DEFAULT_OPTIMIZER = "nlopt";
  optimizer.reset();
  if (params.pointerLikeExists<Optimizer>("optimizer")) {
    optimizer =
        xacc::as_shared_ptr(params.getPointerLike<Optimizer>("optimizer"));
  } else {
    optimizer = createOptimizer(DEFAULT_OPTIMIZER);
  }
  config_params = params;
  // VQE workflow requires an optimizer
  return (optimizer != nullptr);
}

QuantumSimulationResult
VqeWorkflow::execute(const QuantumSimulationModel &model) {
  auto nParams = model.user_defined_ansatz->nParams();
  evaluator = getEvaluator(model.observable, config_params);

  OptFunction f(
      [&](const std::vector<double> &x, std::vector<double> &dx) {
        auto kernel = model.user_defined_ansatz->evaluate_kernel(x);
        auto energy = evaluator->evaluate(kernel);
        return energy;
      },
      nParams);

  auto result = optimizer->optimize(f);
  return {{"energy", result.first}, {"opt-params", result.second}};
}
```

As we know, the VQE algorithm requires a classical optimizer hence we need to figure out which optimizer should be used during initialization.  In this case, we look for the `optimizer` key if provided. Otherwise, we just fall back to a default one (`nlopt` in this case).

Similarly, one may preset (providing default values) and parse any number of configuration parameters that his custom workflow support.

During workflow's `execute`, one can take advantage of QCOR API's to construct the quantum circuit. In this simple VQE workflow, the ansatz circuit was provided as a QCOR kernel functor (`user_defined_ansatz`), hence, we just need to evaluate (resolving variational gate parameters) during the optimization loop.

One key element of implementing workflow execution is to hook up the appropriate cost function evaluator. In that regard, QuaSiMo provides a utility function `getEvaluator` which will pick the appropriate evaluator based on user configurations, e.g., selecting the `default` (tomography-based) evaluator if none provided. 

Workflow developers are free to *not* use the `getEvaluator` utility if the workflow doesn't need to evaluate (observe) the operator or requires custom logic in selecting the evaluator.

Workflow developers are free to select which information to be returned at the end of the workflow execution. In particular, the workflow returns a heterogeneous key-value map (dictionary). In the VQE example, we returned the optimized energy value as well as the optimal parameters.

## <a id="build-workflow"></a> Build and Install

Similar to creating an `Optimizer` plugin, one needs to provide `CMakeLists.txt` and `manifest.json` files to build, register, and install this workflow plugin.

For example, the `manifest.json` should contain:

```json
{
  "bundle.symbolic_name" : "my_vqe_workflow",
  "bundle.activator" : true,
  "bundle.name" : "QuaSiMo VQE Workflow Implementation",
  "bundle.description" : ""
}

```

Then, we can populate the corresponding `CMakeLists.txt`

```cmake
set(LIBRARY_NAME qcor-my-vqe)
file(GLOB SRC *.cpp)

usfunctiongetresourcesource(TARGET ${LIBRARY_NAME} OUT SRC)
usfunctiongeneratebundleinit(TARGET ${LIBRARY_NAME} OUT SRC)

set(_bundle_name my_vqe_workflow)
add_library(${LIBRARY_NAME} SHARED ${SRC})

target_link_libraries(${LIBRARY_NAME} PUBLIC qcor qcor-quasimo qcor-quantum-simulation)
target_include_directories(${LIBRARY_NAME} PUBLIC ${XACC_ROOT}/include/qcor)
xacc_configure_library_rpath(${LIBRARY_NAME})

set_target_properties(${LIBRARY_NAME}
                      PROPERTIES COMPILE_DEFINITIONS
                                 US_BUNDLE_NAME=${_bundle_name}
                                 US_BUNDLE_NAME
                                 ${_bundle_name})

usfunctionembedresources(TARGET
                         ${LIBRARY_NAME}
                         WORKING_DIRECTORY
                         ${CMAKE_CURRENT_SOURCE_DIR}
                         FILES
												 manifest.json)
												 
if(APPLE)
  set_target_properties(${LIBRARY_NAME}
                        PROPERTIES INSTALL_RPATH "@loader_path/../lib;${LLVM_INSTALL_PREFIX}/lib")
  set_target_properties(${LIBRARY_NAME}
                        PROPERTIES LINK_FLAGS "-undefined dynamic_lookup")
else()
  set_target_properties(${LIBRARY_NAME}
                        PROPERTIES INSTALL_RPATH "$ORIGIN/../lib:${LLVM_INSTALL_PREFIX}/lib")
  set_target_properties(${LIBRARY_NAME} PROPERTIES LINK_FLAGS "-shared")
endif()

install(TARGETS ${LIBRARY_NAME} DESTINATION ${CMAKE_INSTALL_PREFIX}/plugins)

```

This is a typical `CMakeLists.txt` for QCOR/XACC plugins. As usual, please make sure the` _bundle_name` `CMake` variable matches the `bundle.symbolic_name` field in `manifest.json`.

Also, `target_link_libraries` and `target_include_directories` should be modified if one needs to use additional libraries.

Lastly, one needs to register the new workflow plugin so that users can retrieve the new workflow via the QuaSiMo workflow registry (via QuaSiMo `getWorkflow` function).

In your implementation (`.cpp`) file, simply add the followings:  

```cpp
#include "xacc_plugin.hpp"
namespace qcor {
REGISTER_PLUGIN(QuaSiMo::VqeWorkflow, QuaSiMo::QuantumSimulationWorkflow)
}
```

This will inject the necessary code to register your new VQE workflow plugin as a `QuantumSimulationWorkflow` interface implementation. Hence, QuaSiMo users can retrieve this workflow via the custom `my-vqe` name that we specified. 

Congratulations! You have completed a new QuaSiMo workflow that will be available to all QuaSiMo users (C++ and Python). 