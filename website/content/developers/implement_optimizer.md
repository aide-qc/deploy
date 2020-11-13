---
title: "Implement a new Optimizer"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

### Table of Contents
* [Background](#background)
* [Create a Custom L-BFGS Optimizer](#create-optimizer)
* [Test the Custom L-BFGS Optimizer](#test-my-lbfgs)
* [Custom Optimizer Options](#custom-lbfgs-options)

## <a id="background"></a> Background
The AIDE-QC software stack provides an extension point for classical, multi-variate function optimization. This provides the means 
to experiment with multiple optimization strategies pertinent to variational quantum computing algorithms (e.g. VQE). 

We describe optimization via an extensible `Optimizer` class. The essential structure of the `Optimizer` infrastructure is shown below
```cpp
// Identifiable, exposes a name and a description
class Identifiable {
public:
   virtual const std::string name() const = 0;
   const std::string description() const = 0;
};

// Useful typedef for Functors that can be optimized
using OptimizerFunctor = 
     std::function<double(const std::vector<double> &, std::vector<double> &)>;

// OptFunction
class OptFunction {
public:
   OptFunction(OptimizerFunctor&, const int n_dim);
   const int dimensions() const;
   virtual double operator()(const std::vector<double> &x,
                            std::vector<double> &dx);
};

class Optimizer : public Identifiable {
public:
virtual OptResult optimize(OptFunction & function) = 0
};
``` 

First, we consider functions that can be optimized to be of a specific structure. In C++, we associate these functions with an `std::function<>` that returns a `double` and takes a `std::vector<double>` as input (evaluate this function at the given parameters `x`), and another optional `std::vector<double>` that encodes the gradient of the vector `x`. The gradient vector may or may not be provided by the function, but if it is not, we do not allow gradient-based optimization strategies. We assign a type name to this functor, the `OptimizerFunctor`.

We wrap `OptimizerFunctors` in another data structure called the `OptFunction`. This class exposes an `operator()()` overload that delegates to the wrapped `OptimizerFunctor`, but additionaly encodes information about the number of optimization functor parameters (the dimension of the problem).

Finally, `Optimizers` expose an `optimize` method that is designed to be implemented by sub-types to provide a sub-type specific optimization strategy. Implementations should take the input `OptFunction` and use calls to its `operator()()` to affect execution of the optimization strategy (derivative-free or gradient-based). `optimize()` returns an `OptResult`, which is just a `std::pair<double, std::vector<double>>` encoding the optimal function value and the corresponding optimal parameters. Also, in the `qcor` data model, `ObjectiveFunctions` are sub-types of `OptFunction`, and therefore, one can pass an `ObjectiveFunction` to `optimize()` as well.

Note, all `Optimizers` are `Identifiable`, therefore, sub-types must implement `name()` and `description()` providing a unique name for the `Optimizer` sub-type and corresponding description. 

## <a id="create-optimizer"></a> Create a New Optimizer

For the purposes of this tutorial, let's try to create a new AIDE-QC `Optimizer` that delegates to the [LBFGS++](https://github.com/yixuan/LBFGSpp) header-only C++ library providing an implementation of the [L-BFGS](https://en.wikipedia.org/wiki/Limited-memory_BFGS) gradient-based optimization algorithm that leverages the [Eigen](https://eigen.tuxfamily.org) matrix library. To start, create a new project directory and add the library as a submodule 
```sh
mkdir my-lbfgs && cd mylbfgs 
git clone https://github.com/yixuan/LBFGSpp
touch CMakeLists.txt mylbfgs_optimizer.{hpp,cpp} manifest.json
# create an examples directory too
mkdir examples
touch rosenbrock.{cpp,py}
```
First, let's populate the `mylbfgs_optimizer.*` source files with the necessary `Optimizer` sub-type boilerplate
```cpp
// mylbfgs_optimizer.hpp
#pragma once
#include "Optimizer.hpp"
using namespace xacc;

namespace mylbfgs {
class MyLBFGSOptimizer : public Optimizer {
public:
  // Define here, we implement in the cpp file
  OptResult optimize(OptFunction &function) override;
  // L-BFGS requires gradients
  const bool isGradientBased() const override {return true;}
  // Give it a unique name and description
  const std::string name() const override { return "my-lbfgs"; }
  const std::string description() const override { return "This is a demo!"; }
};
}
```
```cpp
// mylbfgs_optimizer.cpp
#include "mylbfgs_optimizer.hpp"
#include "xacc_plugin.hpp"

namespace mylbfgs {
OptResult MyLBFGSOptimizer::optimize(OptFunction &function) {
    // ... Optimization code here ...
    // ... We will implement this in a minute ... 
    return {0.0, std::vector<double>{}};
}
}
REGISTER_OPTIMIZER(mylbfgs::MyLBFGSOptimizer)
```
In `mylbfgs_optimizer.hpp`, we declare the `MyLBFGSOptimizer` sub-class of `Optimizer`, indicate that it is a gradient-based `Optimizer`, and give it the unique name `my-lbfgs`. In the implementation file, we start on the `MyLBFGSOptimizer::optimize` implementation. Critically, we include `xacc_plugin.hpp` and end the file with a registration macro that registers the new `Optimizer` with AIDE-QC - this ensures the new `Optimizer` can be used in the AIDE-QC stack.

Next, we turn our attention to the `CMake` build system - `CMakeLists.txt` and `manifest.json`. The plugin must define a `manifest.json` file to encode information about the plugin name and description. We populate the file with the following
```json
{
  "bundle.symbolic_name" : "my_lbfgs_optimizer",
  "bundle.activator" : true,
  "bundle.name" : "LBFGS++ Optimizer",
  "bundle.description" : "This plugin integrates LBFGS++ with AIDE-QC."
}
```
Now we populate the `CMakeLists.txt` file with typical `CMake` boilerplate project calls, plus additional code to correctly build our plugin and install to the appropriate plugin folder location:
```cmake
# Boilerplate CMake calls to setup the project
cmake_minimum_required(VERSION 3.12 FATAL_ERROR)
project(my_lbfgs_optimizer VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Find XACC, provides underlying plugin system
find_package(XACC REQUIRED)

# Create the my-lbfgs-optimizer library
set(LIBRARY_NAME my-lbfgs-optimizer)
file(GLOB SRC mylbfgs_optimizer.cpp)
usfunctiongetresourcesource(TARGET ${LIBRARY_NAME} OUT SRC)
usfunctiongeneratebundleinit(TARGET ${LIBRARY_NAME} OUT SRC)
add_library(${LIBRARY_NAME} SHARED ${SRC})

# L-BFGS++ will require Eigen, XACC provides it
target_include_directories(${LIBRARY_NAME} PUBLIC . 
                                    LBFGSpp/include 
                                    ${XACC_ROOT}/include/eigen)

# _bundle_name must be == manifest.json bundle.symbolic_name !!!
set(_bundle_name my_lbfgs_optimizer)
set_target_properties(${LIBRARY_NAME}
                      PROPERTIES COMPILE_DEFINITIONS
                                 US_BUNDLE_NAME=${_bundle_name}
                                 US_BUNDLE_NAME ${_bundle_name})
usfunctionembedresources(TARGET ${LIBRARY_NAME} 
                         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                         FILES manifest.json)

# Link library with XACC
target_link_libraries(${LIBRARY_NAME} PUBLIC xacc::xacc)

# Configure RPATH
if(APPLE)
  set_target_properties(${LIBRARY_NAME} PROPERTIES INSTALL_RPATH 
                            "${XACC_ROOT}/lib")
  set_target_properties(${LIBRARY_NAME} PROPERTIES LINK_FLAGS 
                            "-undefined dynamic_lookup")
else()
  set_target_properties(${LIBRARY_NAME} PROPERTIES INSTALL_RPATH 
                        "${XACC_ROOT}/lib")
  set_target_properties(${LIBRARY_NAME} PROPERTIES LINK_FLAGS "-shared")
endif()

# Install to Plugins directory
install(TARGETS ${LIBRARY_NAME} DESTINATION ${XACC_ROOT}/plugins)
```
The above CMake code is pretty much ubiquitous across all XACC plugin builds. The first crucial part is `find_package(XACC)` which can be configured or customized with the `cmake .. -DXACC_DIR=/path/to/xacc` flag. Next we create a shared library containing the compiled `mylbfgs_optimizer` code, and configure it as a plugin with appropriate `usfunction*` calls (from the underlying `CppMicroServices` infrastructure). We link the library to the `xacc::xacc` target, configure the `RPATH` such that it can link to the install `lib/` directory, and install to the plugin storage directory. 

To build this we run (from the top-level of the project directory)
```sh 
mkdir build && cd build 
cmake .. -G Ninja -DXACC_DIR=$(qcor -xacc-install)
cmake --build . --target install
```

Now a quick and easy way to test that your `Optimizer` is installed and available (even though we haven't implemented `optimize()` yet) is start the interactive Python interpreter and run the following commands to see the name `my-lbfgs` printed. 
```sh
$ python3
Python 3.8.6 (default, Oct 10 2020, 07:54:55) 
[GCC 5.4.0 20160609] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from qcor import createOptimizer
>>> optimizer = createOptimizer('my-lbfgs')
>>> print(optimizer.name())
my-lbfgs
```

Next we turn our attention to implementing `optimize()` in `mylbfgs_optimizer.cpp`. To do so we follow their provided [README](https://github.com/yixuan/LBFGSpp/blob/master/README.md) example, noting that `xacc` provides the `Eigen` matrix library by default (so we can just include it and it will work)
```cpp
// add the required includes at the top 
#include <Eigen/Core>
#include <LBFGS.h>

...

OptResult MyLBFGSOptimizer::optimize(OptFunction &function) {
  using namespace LBFGSpp;
  using namespace Eigen;

  // Get the dimension of the problem
  const int n_dim = function.dimensions();

  // Set up LBFGS++ parameters
  LBFGSParam<double> param;
  param.epsilon = 1e-6;
  param.max_iterations = 100;

  // Create solver object
  LBFGSSolver<double> solver(param);

  // It looks like LBFGS++ requires Eigen::VectorXd as 
  // input to the objective function to be optimized
  //
  // So here we create a lambda that translates VectorXd to 
  // OptFunction std::vector<double> and calls our function
  // 
  // This is what we will pass to the solver 
  auto lbfgs_functor_wrapper = [&](const VectorXd& x, VectorXd& grad) {
    std::vector<double> x_vec(x.size()), grad_vec(x.size());

    // Map x and grad to std::vector<double>
    VectorXd::Map(&x_vec[0], x.size()) = x;
    VectorXd::Map(&grad_vec[0], grad.size()) = grad;

    // Evaluate our OptFunction!
    auto value = function(x_vec, grad_vec);

    // Map the gradient back to a VectorXd
    grad = Map<VectorXd>(grad_vec.data(), grad_vec.size());
    return value;
  };

  // Initial guess
  VectorXd x = VectorXd::Zero(n_dim);
  
  // Run the optimization algorithm!
  double fx;
  int niter = solver.minimize(lbfgs_functor_wrapper, x, fx);

  // Print the Results!
  std::cout << niter << " iterations" << std::endl;
  std::cout << "x = \n" << x.transpose() << std::endl;
  std::cout << "f(x) = " << fx << std::endl;

  // Map optimal parameters from VectorXd to std::vector<double>
  std::vector<double> opt_params(x.size());
  VectorXd::Map(&opt_params[0], x.size()) = x;

  // Return the OptResult
  return OptResult{fx, opt_params};
}
```
Now in the `build/` directory, run cmake again
```sh
cmake --build . --target install
```
You're now ready to test out the new `Optimizer`.

## <a id="test-my-lbfgs"></a> Test the my-lbfgs Optimizer
We can demonstrate the utility of our custom `Optimizer` in both C++ and Python:
<table>
<tr>
<th>Rosenbrock + My-LBFGS - C++</th>
<th>Rosenbrock + My-LBFGS - Python</th>
</tr>
<tr>
<td>

```cpp
// Include qcor, you don't need to do this 
// if you have quantum kernels defined
// e.g. __qpu__ void foo(...) {...}
// we don't in this example, so include qcor.hpp

#include "qcor.hpp"
using namespace qcor;

int main() {
  // Get the Optimizer
  auto optimizer = createOptimizer("my-lbfgs");

  // Define a 2-dimensional Rosenbrock function
  // and its gradient
  auto rosenbrock = [](const std::vector<double>& x,
                       std::vector<double>& gradx) {
    gradx[0] = -2 * (1 - x[0]) + 400. * (x[0] * x[0] * x[0] - x[1] * x[0]);
    gradx[1] = 200 * (x[1] - x[0] * x[0]);
    auto val = (1. - x[0]) * (1. - x[0]) +
           100 * (x[1] - x[0] * x[0]) * (x[1] - x[0] * x[0]);
    return val;
  };

  // Create the OptFunction, noting it has 2 parameters
  OptFunction opt_function(rosenbrock, 2);

  // Run the Optimizer
  auto [opt_val, opt_params] = optimizer->optimize(opt_function);
  
  // Print the results
  std::cout << "OptVal: " << opt_val << "\n";
  for (auto x : opt_params) std::cout << x << " ";
  std::cout << std::endl;
}

```
```sh
qcor rosenbrock.cpp ; ./a.out
```
</td>
<td>

```python
# Import createOptimizer from qcor
from qcor import createOptimizer

# Create the Optimizer
optimizer = createOptimizer('my-lbfgs')

# Define the 2-d Rosenbrock function and its gradient
# Note that in Python, we have to return the gradient
# as part of a return tuple
def rosenbrock(x):
    # Compute gradient
    g = [-2*(1-x[0]) + 400.*(x[0]**3 - x[1]*x[0]), 200 * (x[1] - x[0]**2)]
    # compute function
    xx = (1.-x[0])**2 + 100*(x[1]-x[0]**2)**2
    return xx, g

# Run the Optimizer, noting it has 2 parameters
# OptFunction is implicit in Python
opt_val,opt_params = optimizer.optimize(rosenbrock,2)

# Print the results
print('Result = ', opt_val,opt_paramas)


```
```sh
python3 rosenbrock.py 
``` 
</td>
</tr>
</table>

The `Optimizer` can also be used for variational quantum algorithms. Here we demonstrate using this `Optimizer` for the VQE algorithm. 
<table>
<tr>
<th>Deuteron VQE, My-LBFGS - C++</th>
<th>Deuteron VQE, My-LBFGS - Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void ansatz(qreg q, double theta) {
  X(q[0]);
  Ry(q[1], theta);
  CX(q[1], q[0]);
}

int main(int argc, char **argv) {
  
  // Programmer needs to set 
  // the number of variational params
  auto n_variational_params = 1;

  // Create the Deuteron Hamiltonian
  auto H = 5.907 - 2.1433 * X(0) * X(1) - 
        2.1433 * Y(0) * Y(1) + .21829 * Z(0) -
        6.125 * Z(1);

  // Create the ObjectiveFunction, here we want to run VQE
  // need to provide ansatz, Operator, and number of params
  // we also provide a gradient strategy to use
  auto objective = createObjectiveFunction(
      ansatz, H, n_variational_params,
      {{"gradient-strategy", "parameter-shift"}});

  // Create the Optimizer.
  auto optimizer = createOptimizer("my-lbfgs");

  // Optimize, get opt val and params
  auto [opt_val, opt_params] = optimizer->optimize(*objective.get());
  
  // Print the results
  std::cout << "OptVal: " << opt_val << "\n";
  for (auto x : opt_params) std::cout << x << " ";
  std::cout << std::endl;
}

```
```sh
qcor vqe_mylbfgs.cpp ; ./a.out
```
</td>
<td>

```python
# Import data structures from qcor
from qcor import *
# Define a quantum kernel in python using 
# the @qjit decorator for quantum just in 
# time compilation
@qjit
def ansatz(q: qreg, theta: float):
    X(q[0])
    Ry(q[1], theta)
    CX(q[1], q[0])
        
# Programmer needs to set
# the number of variational params
n_variational_params = 1

# Create the Deuteron Hamiltonian
H = -2.1433 * X(0) * X(1) - 2.1433 * \
        Y(0) * Y(1) + .21829 * Z(0) - 6.125 * Z(1) + 5.907

# Create the ObjectiveFunction, here we want to run VQE
# need to provide ansatz, Operator, and number of params
# we also provide a gradient strategy to use
objective = createObjectiveFunction(
    ansatz, H, n_variational_params,
    {'gradient-strategy': 'parameter-shift'})

# Create the Optimizer.
optimizer = createOptimizer("my-lbfgs")

# Optimize, get opt val and params
opt_val, opt_params = optimizer.optimize(objective)

# Print the results
print('Result = ', opt_val, opt_params)
```
```sh
python3 vqe_mylbfgs.py 
``` 
</td>
</tr>
</table>

## <a id="custom-lbfgs-options"></a> Custom Optimizer Options
`Optimizers` also support the injection of custom options, structured as a map of strings (keys) to any type (values). 
This is useful for customizing the `Optimizer` workflow strategy. Let's demonstrate this with the `MyLBFGSOptimizer`, and specifically, 
let's make it so that the programmer can modify a `max-iterations` parameter. 

Every `Optimizer` has access to a protected class member called `options`. This is a `HeterogeneousMap` instance that maps string keys to 
any type (using the [`std::any`](https://en.cppreference.com/w/cpp/utility/any) template type, or in Python, just a `dict`). This options 
map is injected into the `Optimizer` at creation, and is available for implementations of `Optimizer::optimize()` to use. Let's modify 
the `MyLBFGSOptimizer::optimize()` implementation to support a `max-iterations` key:

```cpp
OptResult MyLBFGSOptimizer::optimize(OptFunction &function) {
  
  ... rest of the code from above ... 

  int max_iters = 100;
  if (options.keyExists<int>("max-iterations")) {
    max_iters = options.get<int>("max-iterations");
  }

  // Set up LBFGS++ parameters
  LBFGSParam<double> param;
  param.epsilon = 1e-6;
  param.max_iterations = max_iters;

  ... rest of the code from above ...

}
```
`HeterogeneousMap` exposes a `keyExists<T>(key:string) : bool` to indicate if a given key exists in the map with the correct template type. `Optimizer` developers should always check first to see if the key exists, as programmers may or may not provide the given optional parameter. If the key does exists with the given type, then developers can leverage the `get<T>(key:string):T` method on the map to get the value of the input parameter, and use it to influence the rest of the `Optimizer::optimize` workflow. 

Users of the `Optimizer` can provide custom options via the `createOptimizer` function in the following manner (shown in both C++ and Python):
<table>
<tr>
<th>Custom Optimizer Options - C++</th>
<th>Custom Optimizer Options - Python</th>
</tr>
<tr>
<td>

```cpp
  // Create the Optimizer.
  auto optimizer = createOptimizer("my-lbfgs", {{"max-iterations", 50}});
```
</td>
<td>

```python
# Create the Optimizer.
optimizer = createOptimizer("my-lbfgs", {'max-iterations':50})
```
</td>
</tr>
</table>

