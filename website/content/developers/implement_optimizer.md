---
title: "Implement a new Optimizer"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

## Background
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

Finally, `Optimizers` expose an `optimize` method that is designed to be implemented by sub-types to provide a sub-type specific optimization strategy. Implementations should take the input `OptFunction` and use calls to its `operator()()` to affect execution of the optimization strategy (derivative-free or gradient-based). `optimize()` returns an `OptResult`, which is just a `std::pair<double, std::vector<double>>` encoding the optimal function value and the corresponding optimal parameters. 

Note, all `Optimizers` are `Identifiable`, therefore, sub-types must implement `name()` and `description()` providing a unique name for the `Optimizer` sub-type and corresponding description. 

## Create an Optimizer Sub-Type

For the purposes of this tutorial, let's try to create a new AIDE-QC `Optimizer` that delegates to [LBFGS++](https://github.com/yixuan/LBFGSpp) header-only C++ library providing an implementation of the [L-BFGS](https://en.wikipedia.org/wiki/Limited-memory_BFGS) gradient-based optimization algorithm. To start, create a new project directory and add the library as a submodule 
```sh
mkdir my-lbfgs && cd mylbfgs 
git clone https://github.com/yixuan/LBFGSpp
touch CMakeLists.txt mylbfgs_optimizer.{hpp,cpp} manifest.json
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
  OptResult optimize(OptFunction &function) override;
  const bool isGradientBased() const override {return true;}
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
In `mylbfgs_optimizer.hpp`, we declare the `MyLBFGSOptimizer` sub-class of `Optimizer`, indicate that it is a gradient-based `Optimizer`, and give it the unique name `my-lbfgs`. In the implementation file, we start on the `MyLBFGSOptimizer::optimize` implementation. Critically (this ensures your new `Optimizer` can be used in the AIDE-QC stack), we include `xacc_plugin.hpp` and end the file with a registration macro that registers the new `Optimizer` with AIDE-QC.

Next, we turn our attention to the `CMake` build system. First, our plugin needs to define a `manifest.json` file, which encodes plugin name and description information. We populate the file with the following
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
target_include_directories(${LIBRARY_NAME} PUBLIC . 
                                    LBFGSpp/include 
                                    ${XACC_ROOT}/include/eigen)
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
                            "${CMAKE_INSTALL_PREFIX}/lib;${XACC_ROOT}/lib")
  set_target_properties(${LIBRARY_NAME} PROPERTIES LINK_FLAGS 
                            "-undefined dynamic_lookup")
else()
  set_target_properties(${LIBRARY_NAME} PROPERTIES INSTALL_RPATH 
                        "$ORIGIN/../lib;${XACC_ROOT}/lib")
  set_target_properties(${LIBRARY_NAME} PROPERTIES LINK_FLAGS "-shared")
endif()

# Install to Plugins directory
install(TARGETS ${LIBRARY_NAME} DESTINATION ${XACC_ROOT}/plugins)
```
The above CMake code is pretty much ubiquitous across all XACC plugin builds. The crucial parts are that 
one runs `find_package(XACC)` which can be configured or customized with the `cmake .. -DXACC_DIR=/path/to/xacc` flag (by default will look in `$HOME/.xacc`). Next we create a shared library containing the compiled `mylbfgs_optimizer`, and configure it as a plugin with appropriate `usfunction*` calls (from the underlying `CppMicroServices` infrastructure). We link the library to the `xacc::xacc` target, configure the `RPATH` such that it can link to the install `lib/` directory, and install to the plugin storage directory. 

To build this we run (assuming XACC is installed to `$HOME/.xacc`) 
```sh 
mkdir build && cd build 
cmake .. -G Ninja -DXACC_DIR=$HOME/.xacc
cmake --build . --target install
```
If you installed the AIDE-QC stack via `apt-get` or Homebrew installers, you should use 
```sh
-DXACC_DIR=/usr/local/xacc (apt-get)
-DXACC_DIR=$(brew --prefix xacc) (homebrew)
```

Now a quick and easy way to test that your `Optimizer` is installed and available (even though we haven't implemented `optimize()` yet) is to run the following python script to see the name `my-lbfgs` printed. 
```python
from qcor import createOptimizer
optimizer = createOptimizer('my-lbfgs')
print(optimizer.name())
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

  const int n_dim = function.dimensions();
  // Set up parameters
  LBFGSParam<double> param;
  param.epsilon = 1e-6;
  param.max_iterations = 100;

  // Create solver and function object
  LBFGSSolver<double> solver(param);

  // Create a lambda that we can pass to LBFGSSolver
  // that wraps calls to the OptFunction by 
  // mapping Eigen::VectorXd to std::vector<double>
  auto lbfgs_functor_wrapper = [&](const VectorXd& x, VectorXd& grad) {
    std::vector<double> x_vec(x.size()), grad_vec(x.size());

    // Map x and grad to std::vector<double>
    VectorXd::Map(&x_vec[0], x.size()) = x;
    VectorXd::Map(&grad_vec[0], grad.size()) = grad;

    auto value = function(x_vec, grad_vec);

    grad = Map<VectorXd>(grad_vec.data(), grad_vec.size());
    return value;
  };

  // Initial guess
  VectorXd x = VectorXd::Zero(n_dim);
  
  // x will be overwritten to be the best point found
  double fx;
  int niter = solver.minimize(lbfgs_functor_wrapper, x, fx);

  std::cout << niter << " iterations" << std::endl;
  std::cout << "x = \n" << x.transpose() << std::endl;
  std::cout << "f(x) = " << fx << std::endl;

  std::vector<double> opt_params(x.size());
  VectorXd::Map(&opt_params[0], x.size()) = x;

  return std::make_pair(fx, opt_params);
}
```

## Test the my-lbfgs Optimizer
We can demonstrate the utility of our custom `Optimizer` in both C++ and Python:
<table>
<tr>
<th>Rosenbrock + My-LBFGS - C++</th>
<th>Rosenbrock + My-LBFGS - Python</th>
</tr>
<tr>
<td>

```cpp
#include "qcor.hpp"
using namespace qcor;

int main() {
  auto optimizer = createOptimizer("my-lbfgs");

  auto rosenbrock = [](const std::vector<double>& x,
                       std::vector<double>& gradx) {
    gradx[0] = -2 * (1 - x[0]) + 400. * (x[0] * x[0] * x[0] - x[1] * x[0]);
    gradx[1] = 200 * (x[1] - x[0] * x[0]);
    auto val = (1. - x[0]) * (1. - x[0]) +
           100 * (x[1] - x[0] * x[0]) * (x[1] - x[0] * x[0]);
    return val;
  };

  OptFunction opt_function(rosenbrock, 2);
  auto [opt_val, opt_params] = optimizer->optimize(opt_function);
  std::cout << "OptVal: " << opt_val << "\n";
}
```
```sh
qcor rosenbrock.cpp ; ./a.out
```
</td>
<td>

```python

from qcor import createOptimizer
optimizer = createOptimizer('my-lbfgs')

def rosenbrock(x):
    # Compute gradient
    g = [-2*(1-x[0]) + 400.*(x[0]**3 - x[1]*x[0]), 200 * (x[1] - x[0]**2)]
    # compute function
    xx = (1.-x[0])**2 + 100*(x[1]-x[0]**2)**2
    print(x, xx)
    return xx, g

r,p = optimizer.optimize(rosenbrock,2)

print('Result = ', r,p)


```
```sh
python3 rosenbrock.py 
``` 
</td>
</tr>
</table>