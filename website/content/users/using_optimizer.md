---
title: "Using an Optimizer"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

`Optimizers` have proven ubiquitous across variational quantum computation. AIDE-QC is focused on the development of novel 
optimization strategies for noisy quantum co-processors. To deploy these strategies in an extensible and modular way, the AIDE-QC 
software stack puts forward and `Optimizer` interface / concept that can be implemented for particular optimization strategies. Currently, 
we provide a number of implementations, some of which delegate to popular optimization libraries that provide a wealth of gradient-based 
and derivative free algorithms. 

Here we describe how to use AIDE-QC `Optimizers`. We provide implementations that are backed by [MLPack](https://ensmallen.org/docs.html) and [NLOpt](https://nlopt.readthedocs.io/en/latest/). If you are interested in 
creating a custom `Optimizer`, checkout the [`Optimizer` Developer Guide](../developers/implement_optimizer). 

For background on the `Optimizer` class itself, checkout this [link](../developers/implement_optimizer/#background).

## <a id="create-optimizer"></a> Create an Optimizer
The `qcor` runtime library puts forward a simple `createOptimizer()` API call that will return an instance of the `Optimizer` interface. 
Programmers can use this API call in both C++ and Python in order retrieve a specific desired `Optimizer` implementation with additional 
custom input parameters. Here we demonstrate a few examples of this in C++ and Python

<table>
<tr>
<th>Get the NLOpt Optimizer - C++</th>
<th>Get the NLOpt Optimizer - Python</th>
</tr>
<tr>
<td>

```cpp
  // Create the simplest Optimizer. Default 
  // NLopt algorithm is COBYLA
  auto optimizer = createOptimizer("nlopt");

  // Get NLOpt, but use L-BFGS
  auto optimizer = createOptimizer("nlopt", {{"algorithm", "l-bfgs"}});

  // Get NLOpt, specify max function evaluations
  auto optimizer = createOptimizer("nlopt", {{"algorithm", "l-bfgs"}, {"nlopt-maxeval", 100}});

  // Get the MLPack optimizer, default is adam
  auto optimizer = createOptimizer("mlpack");

  // Get MLPack, Stochastic Gradient Descent 
  // with custom step-size
  auto optimizer = createOptimizer("mlpack", {{"algorithm", "sgd"}, {"mlpack-step-size", .3}});
```
</td>
<td>

```python
# Create the simplest Optimizer. Default 
# NLopt algorithm is COBYLA
optimizer = createOptimizer('nlopt')

# Get NLOpt, but use L-BFGS
optimizer = createOptimizer('nlopt', {'algorithm': 'l-bfgs'})

# Get NLOpt, specify max function evaluations
optimizer = createOptimizer('nlopt', {'algorithm': 'l-bfgs', 'nlopt-maxeval': 100})

# Get the MLPack optimizer, default is adam
optimizer = createOptimizer('mlpack')

# Get MLPack, Stochastic Gradient Descent 
# with custom step-size
optimizer = createOptimizer('mlpack', {'algorithm': 'sgd', 'mlpack-step-size': .3})
```
</td>
</tr>
</table>

Any `Optimizer` can be created and specified in this way. See below for the list of [Available Optimizers](#available-optimizers), and note 
the creation of new `Optimizers` is an open research and development activity, so this list will grow over time. 

## <a id="optimize-function"></a> Optimize a Custom Function
Here we demonstrate how one might use the `Optimizer` interface to find the 
optimal value and optimal parameters for a general function. To do so, we 
take the problem of defining a parameterized quantum kernel, observing the 
resultant state based on a custom Hamiltonian, and computing the resultant expectation 
value of that observable at the given set of state input parameters. Our goal will be to define 
a function to optimize that takes a list or vector of floats and returns the corresponding 
expectation value. 

We first demonstrate this in Python, see below:
```python
from qcor import *

# Define an observable
H = -2.1433 * X(0) * X(1) - 2.1433 * \
    Y(0) * Y(1) + .21829 * Z(0) - 6.125 * Z(1) + 5.907

# Define a parameterized quantum kernel
@qjit
def ansatz(q : qreg, theta : float):
    X(q[0])
    Ry(q[1], theta)
    CX(q[1], q[0])

# We know the target energy
target_energy = -1.74

# Define a function to optimize
def objective_function(x : List[float]):
    # Allocate some qubits to execute on
    q = qalloc(H.nBits())
    # Observe the ansatz at the given arguments
    energy = ansatz.observe(H, q, x[0])
    # We want to see how far we are from the target
    return abs(target_energy - energy)

# Create an Optimizer, NLOpt COBYLA with max of 20 function evals
optimizer = createOptimizer('nlopt', {'nlopt-maxeval':20})

# Optimize!
opt_val, opt_params = optimizer.optimize(objective_function, 1)
print(opt_val, opt_params)
```
This example starts by defining a custom observable (Hamiltonian) and a parameterized 
quantum kernel ansatz. The function we want to optimize observes this ansatz based on 
the Hamiltonian and current input parameters, and returns the expectation value of the 
Hamiltonian (the energy in this case). Our goal is to find `x[0]` that gets us as close 
to the target energy as possible, so we return `abs(target_energy - energy)`. Optimizing this 
function with the AIDE-QC stack is simple - create the desired `Optimizer` and call `optimize`, 
providing the function to optimize and the number of variational parameters. 

We can do the same thing in C++:
```cpp
// Define the quantum kernel ansatz
__qpu__ void ansatz(qreg q, double theta) {
  X(q[0]);
  Ry(q[1], theta);
  CX(q[1], q[0]);
}

int main() {
  // Define an observable
  auto H = -2.1433 * X(0) * X(1) - 2.1433 * Y(0) * Y(1) + .21829 * Z(0) -
           6.125 * Z(1) + 5.907;

  // We know the target energy 
  double target_energy = -1.74;

  // Define a function to optimize
  OptFunction objective_function(
      [&](const std::vector<double>& x, std::vector<double>& gradx) {
        // Get the energy, <ansatz(theta) | H | ansatz(theta)>
        auto energy = observe(ansatz, H, qalloc(H.nBits()), x[0]);
        // We want to see how far we are from the target
        return std::fabs(target_energy - energy);
      },
      1);

  // Create an Optimizer, NLOpt COBYLA with max of 20 function evals
  auto optimizer = createOptimizer("nlopt", {{"nlopt-maxeval", 20}});

  // Optimize!
  auto [opt_val, opt_params] = optimizer->optimize(objective_function);
  std::cout << opt_val << "\n";
  for (auto x : opt_params) std::cout << x << " ";
  std::cout << std::endl;
}
```

## <a id="available-optimizers"></a> Available Optimizers
Here we provide detailed specifications of the available `Optimizer` implementations we provide as part of the AIDE-QC software stack. 
For each, we detail its available options - their key name, default values, and required types. 

### <a id="avail-mlpack"></a> mlpack
Get reference to this `Optimizer` with `createOptimizer("mlpack")`. Get reference to the various optimization strategies with 
`createOptimizer("mlpack", {{"algorithm", "adadelta"}})` (`adadelta` as an example). See below for all strategies and associated 
options. 

|    ``algorithm``       | Optimizer Parameter    |                  Parameter Description                          | default | type   |
|------------------------|------------------------|-----------------------------------------------------------------|---------|--------|
|        adam            | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-beta1           | Exponential decay rate for the first moment estimates.          | .7      | double |
|                        | mlpack-beta2           | Exponential decay rate for the weighted infinity norm estimates.| .999    | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-eps             | Value used to initialize the mean squared gradient parameter.   | 1e-8    | double |
|        l-bfgs          |        None            |                                                                 |         |        |
|        adagrad         | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-eps             | Value used to initialize the mean squared gradient parameter.   | 1e-8    | double |
|        adadelta        | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-eps             | Value used to initialize the mean squared gradient parameter.   | 1e-8    | double |
|                        | mlpack-rho             | Smoothing constant.                                             | .95     | double |
|        cmaes           | mlpack-cmaes-lambda    | The population size.                                            | 0       | int    |
|                        |mlpack-cmaes-upper-bound| Upper bound of decision variables.                              | 10.     | duoble |
|                        |mlpack-cmaes-lower-bound| Lower bound of decision variables.                              | -10.0   | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|        gd              | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|        momentum-sgd    | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-momentum        | Maximum absolute tolerance to terminate algorithm.              | .05     | double |
|   momentum-nesterov    | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-momentum        | Maximum absolute tolerance to terminate algorithm.              | .05     | double |
|        sgd             | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|        rms-prop        | mlpack-step-size       | Step size for each iteration.                                   | .5      | double |
|                        | mlpack-max-iter        | Maximum number of iterations allowed                            | 500000  | int    |
|                        | mlpack-tolerance       | Maximum absolute tolerance to terminate algorithm.              | 1e-4    | double |
|                        | mlpack-alpha           | Smoothing constant                                              | .99     | double |
|                        | mlpack-eps             | Value used to initialize the mean squared gradient parameter.   | 1e-8    | double |

### <a id="avail-nlopt"></a> nlopt
Get reference to this `Optimizer` with `createOptimizer("nlopt")`. Get reference to the various optimization strategies with 
`createOptimizer("nlopt", {{"algorithm", "l-bfgs"}})` (`l-bfgs` as an example). See below for all strategies and associated 
options. 


|     ``algorithm``      | Optimizer Parameter    |                  Parameter Description                          | default | type   |
|------------------------|------------------------|-----------------------------------------------------------------|---------|--------|
|        cobyla          | nlopt-ftol             | Maximum absolute tolerance to terminate algorithm.              | 1e-6    | double |
|                        | nlopt-maxeval          | Maximum number of iterations allowed                            | 1000    | int    |
|        l-bfgs          | nlopt-ftol             | Maximum absolute tolerance to terminate algorithm.              |   1e-6  | double |
|                        | nlopt-maxeval          | Maximum number of iterations allowed                            | 1000    | int    |
|      nelder-mead       | nlopt-ftol             | Maximum absolute tolerance to terminate algorithm.              | 1e-6    | double |
|                        | nlopt-maxeval          | Maximum number of iterations allowed                            | 1000    | int    |

### <a id="scikitquant"></a> scikit-quant
Get reference to this `Optimizer` with `createOptimizer("skquant")`. Get reference to the various optimization strategies with 
`createOptimizer("skquant", {{"method", "imfil"}})` (`imfil` as an example). See below for all strategies and associated 
options. 

To use this `Optimizer` you must install it separately:
```sh
python3 -m pip install --user scikit-quant
```


|   ``algorithm``        | Optimizer Parameter    |                  Parameter Description                          | default | type   |
|------------------------|------------------------|-----------------------------------------------------------------|---------|--------|
|        (all)           | budget                 | Number of allowed function evaluations.                         | 100     | int    |

### <a id="libcmaes"></a> libcmaes
Get reference to this `Optimizer` with `createOptimizer("cmaes")`. Get reference to the various optimization strategies with 
`createOptimizer("cmaes", {{"cmaes-max-iter", 100}})` (`cmaes-max-iter` as an example). See below for all strategies and associated 
options. 

To use this `Optimizer` you must install it separately:
```sh
git clone https://github.com/ornl-qci/libcmaes
cd libcmaes && mkdir build && cd build
cmake .. -DXACC_DIR=$(qcor -xacc-install) -DEIGEN3_INCLUDE_DIR=$(qcor -xacc-install)/include/eigen -DCMAKE_INSTALL_PREFIX=$HOME/.libcmaes
make install
```


| Optimizer Parameter    |                  Parameter Description                          | default | type   |
|------------------------|-----------------------------------------------------------------|---------|--------|
| cmaes-max-iter         | Number of allowed cmaes iterations.                             | -1      | int    |
| cmaes-max-feval        | Number of allowed function evaluations.                         | -1      | int    |
