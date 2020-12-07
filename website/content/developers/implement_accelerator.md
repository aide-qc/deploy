---
title: "Add a New Quantum Backend"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

Here we detail how one might inject a new simulator or physical backend into the AIDE-QC software stack. The process for doing this is 
via the implementation of a new `xacc::Accelerator` sub-class, and its contribution to the stack as a new plugin library. 

## <a id="background"></a> Background
```cpp
class Accelerator : public Identifiable {
public:
  virtual void initialize(const HeterogeneousMap &params = {}) = 0;
  virtual void updateConfiguration(const HeterogeneousMap &config) = 0;
  virtual const std::vector<std::string> configurationKeys() = 0;
  virtual HeterogeneousMap getProperties();
  virtual std::vector<std::pair<int, int>> getConnectivity();

  // Execute a single program. All results persisted to the buffer
  virtual void
  execute(std::shared_ptr<AcceleratorBuffer> buffer,
          const std::shared_ptr<CompositeInstruction> 
             CompositeInstruction) = 0;

  // Execute a vector of programs. A new buffer
  // is expected to be appended as a child of the provided buffer.
  virtual void execute(std::shared_ptr<AcceleratorBuffer> buffer,
          const std::vector<std::shared_ptr<CompositeInstruction>>
             CompositeInstructions) = 0;
```
The `Accelerator` class structure is shown above. All `Accelerators` expose a mechanism for one-time initialization. 
The `initialize` method takes as input an optional `HeterogeneousMap` which enables initial user 
configuration of the `Accelerator`. Examples of input here include `shots` and `backend` (which physical backend to 
run on, i.e. `ibmq_vigo` for the `ibm` `Accelerator`). Users can also update any initialization parameters 
via the `updateConfiguration` method. Implementations should expose which input keys they expect via 
the `configurationKeys()` method. Next, `Accelerator` enables one to retrieve any pertinent properties from 
the backend the implementation delegates to. This is useful for users to gain access to error rates and other 
physical backend information. `Accelerator` exposes a mechanism for providing the backend processor physical 
qubit connectivity as a list or vector of edges. 

Critically, `Accelerator` exposes a mechanism for execution of `CompositeInstructions`. `execute` takes as input 
an `AcceleratorBuffer` and the quantum circuit encoded as a `CompositeInstrucion`. The goal of `execute` implementations 
is to map the `CompositeInstruction` to the input required by the backend (map the IR to native gates, map those native gates to the format required by the backend API), affect execution of that circuit, and retrieve execution results and persist them to the input buffer. `Accelerator` also exposes an `execute` method that will execute a vector of `CompositeInstructions`. 

The ability to map `CompositeInstructions` to the unique input format of the targeted backend is critical to the implementation of `execute` on `Accelerator` sub-types. To make this efficient, we have provided a means to walk the IR tree and _*visit*_ each concrete node (which is itself an `Instruction`, with concrete implementations for the various quantum gates). Most `Accelerators` will make use of this in the following way:
```cpp
void MyAccelerator::execute(std::shared_ptr<AcceleratorBuffer>, const std::shared_ptr<CompositeInstruction> circuit) {

  // Create an instance of your custom instruction visitory
  auto my_visitor = std::make_shared<MyCustomInstructionVisitor>();

  // Pre-order tree traversal
  InstructionIterator iter(circuit);
  while(iter.hasNext()) {
      auto instruction = iter.next();

      // Visit the Instruction
      instruction->accept(my_visitor);
  }

  auto backend_circ_format = my_visitor->getMyFormat();

  // Now execute via backend API...

}
```
Developers are free to implement an `InstructionVisitor` in any way they see fit, as long as they implement the pertinent `Instruction` `visit(...)` calls
```cpp
class MyCustomInstructionVisitor : public AllGateVisitor {
protected:
   std::string my_backend_circ_format_str = "";
public:
   void visit(Hadamard& h) override {
       // build up my_backend_circ_format_str for Hadamard
       ....
   }
   void visit(CNOT& cnot) override {
       // build up my_backend_circ_format_str for Hadamard
       ....
   }
   ...
   std::string getMyFormat() {return my_backend_circ_format_str;}
}
```
As an example, imagine your backend required or exposed a submission API that took an OpenQasm string as input. You could implement an `InstructionVisitor` that 
visited concrete `Instruction` nodes and built up a string on the class that contained the visited circuit as an OpenQasm code string. You would then expose a 
method for retrieving that string after walking the tree, and could use it in the submission API for your backend. 

After mapping the incoming `CompositeInstruction` to the correct submission format, the next goal for `execute` is to affect execution on the backend and retrieve execution results. The results should be persisted to the input `AcceleratorBuffer` so that upstream users can retrieve them, these are usually just 
bitstrings and corresponding counts. 
```cpp
  // Continuing the execute impl from above
  auto backend_circ_format = my_visitor->getMyFormat();

  // Now execute via backend API...
  auto bit_strings_counts = execute_on_actual_backend(backend_circ_format);

  // Add the results to the buffer
  for (auto [bits, count] : bit_strings_counts) {
      buffer->appendMeasurement(bits, count);
  }

  // All done!

  return;
}
```

## <a id="quimb"></a> Concrete Example - Quimb Integration
To illustrate the concepts presented in the previous section, here we provide a concrete demonstration 
of injecting a new quantum backend into the AIDE-QC stack. Specifically, we'll demonstrate 
how to add a new simulation capability to the stack - the quantum circuit simulation module from the 
[Quimb](https://quimb.readthedocs.io/en/latest/tensor-circuit.html) library. This provides an interesting test 
case in that it will require a new `Accelerator` subtype, an `InstructionVisitor` to map `CompositeInstructions` to 
the required Quimb input, and a mechanism for executing the Pythonic Quimb simulation from C++. 

We start out by creating the files necessary to build and install a new plugin for the AIDE-QC stack.
```sh
mkdir quimb_accelerator && cd quimb_accelerator 
touch CMakeLists.txt quimb_accelerator.{hpp,cpp} manifest.json
```
First, let's populate the `quimb_accelerator.*` source files with the necessary `Accelerator` sub-type boilerplate
```cpp
#pragma once

#include "Accelerator.hpp"

namespace xacc {
class QuimbAccelerator : public Accelerator { 
 protected:
  std::map<std::string, int> execute_with_quimb(const std::string &code,
                                                const int n_qubits);
 public:
  void initialize(const HeterogeneousMap &params = {}) override;
  void updateConfiguration(const HeterogeneousMap &config) override;
  const std::vector<std::string> configurationKeys() override;
  HeterogeneousMap getProperties() override;

  // Execute a single program. All results persisted to the buffer
  void execute(std::shared_ptr<AcceleratorBuffer> buffer,
               const std::shared_ptr<CompositeInstruction> circuit)
      override;

  // Execute a vector of programs. A new buffer
  // is expected to be appended as a child of the provided buffer.
  void execute(std::shared_ptr<AcceleratorBuffer> buffer,
               const std::vector<std::shared_ptr<CompositeInstruction>>
                   circuits) override;

  // Give it a unique name and description
  const std::string name() const override { return "quimb"; }
  const std::string description() const override { return "This is a demo!"; }
};
}  // namespace xacc
```
```cpp
#include "quimb_accelerator.hpp"
#include "xacc_plugin.hpp"

namespace xacc {

void QuimbAccelerator::initialize(const HeterogeneousMap &params) {
  // do nothing for now
}
void QuimbAccelerator::updateConfiguration(const HeterogeneousMap &config) {
  // do nothing for now
}
const std::vector<std::string> QuimbAccelerator::configurationKeys() {
  // nothing for now
  return {};
}

HeterogeneousMap QuimbAccelerator::getProperties() {
  HeterogeneousMap m;
  return m;
}
void QuimbAccelerator::execute(
    std::shared_ptr<AcceleratorBuffer> buffer,
    const std::vector<std::shared_ptr<CompositeInstruction>>
        circuits) {
  // handle this later
}

void QuimbAccelerator::execute(
    std::shared_ptr<AcceleratorBuffer> buffer,
    const std::shared_ptr<CompositeInstruction> circuit) {}


}  // namespace xacc
REGISTER_ACCELERATOR(xacc::QuimbAccelerator)
```

In `quimb_accelerator.hpp`, we declare the `QuimbAccelerator` sub-class of `Accelerator`, and give it the unique name `quimb`. In the implementation file, we start on `initialize`, `updateConfiguration`, `configurationKeys` and `getProperties` but leave them empty for now. We will handle the `execute` single `CompositeInstruction` method first. Critically, we include `xacc_plugin.hpp` and end the file with a registration macro that registers the new `Accelerator` with AIDE-QC - this ensures the new `Accelerator` can be used in the AIDE-QC stack.

Next, we turn our attention to the `CMake` build system - `CMakeLists.txt` and `manifest.json`. The plugin must define a `manifest.json` file to encode information about the plugin name and description. We populate the file with the following
```json
{
    "bundle.symbolic_name" : "quimb_accelerator",
    "bundle.activator" : true,
    "bundle.name" : "Bindings for Quimb",
    "bundle.description" : "Cool Description Here."
  }
```
Now we populate the `CMakeLists.txt` file with typical `CMake` boilerplate project calls, plus additional code to correctly build our plugin and install to the appropriate plugin folder location:
```cmake
# Boilerplate CMake calls to setup the project
cmake_minimum_required(VERSION 3.12 FATAL_ERROR)
project(quimb_accelerator VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Find XACC, provides underlying plugin system
find_package(XACC REQUIRED)
# Find Python includes and library
find_package(Python COMPONENTS Interpreter Development REQUIRED)

set(LIBRARY_NAME quimb-accelerator)
file(GLOB SRC quimb_accelerator.cpp)
usfunctiongetresourcesource(TARGET ${LIBRARY_NAME} OUT SRC)
usfunctiongeneratebundleinit(TARGET ${LIBRARY_NAME} OUT SRC)
add_library(${LIBRARY_NAME} SHARED ${SRC})

target_include_directories(${LIBRARY_NAME} PUBLIC . ${Python_INCLUDE_DIRS}
                                    ${XACC_ROOT}/include/pybind11/include)

# _bundle_name must be == manifest.json bundle.symbolic_name !!!
set(_bundle_name quimb_accelerator)
set_target_properties(${LIBRARY_NAME}
                      PROPERTIES COMPILE_DEFINITIONS
                                 US_BUNDLE_NAME=${_bundle_name}
                                 US_BUNDLE_NAME ${_bundle_name})
usfunctionembedresources(TARGET ${LIBRARY_NAME} 
                         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                         FILES manifest.json)

# Link library with XACC
target_link_libraries(${LIBRARY_NAME} PUBLIC xacc::xacc xacc::quantum_gate Python::Python)

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
The above CMake code is pretty much ubiquitous across all XACC plugin builds. The first crucial part is `find_package(XACC)` which can be configured or customized with the `cmake .. -DXACC_DIR=/path/to/xacc` flag. Next we create a shared library containing the compiled `quimb_accelerator` code, and configure it as a plugin with appropriate `usfunction*` calls (from the underlying `CppMicroServices` infrastructure). We link the library to the `xacc::xacc` target, configure the `RPATH` such that it can link to the install `lib/` directory, and install to the plugin storage directory. Since we plan 
to delegate to Python, we `find_package(Python)` and include the Python headers and link to the Python target. Moreover, since we plan to create a new `AllGateVisitor` we also need to link to the `xacc::quantum_gate` target. 

To build this we run (from the top-level of the project directory)
```sh 
mkdir build && cd build 
cmake .. -G Ninja -DXACC_DIR=$(qcor -xacc-install)
cmake --build . --target install
```

Now that we have a project that builds and installs, let's turn our attention to implementing `QuimbAccelerator::execute`. We note that in Quimb, one can create a quantum circuit using a list of tuples
```python
qc = qtn.Circuit(3)
gates = [
    ('H', 0),
    ('H', 1),
    ('CNOT', 1, 2),
    ('CNOT', 0, 2),
    ('H', 0),
    ('H', 1),
    ('H', 2),
]
qc.apply_gates(gates)
```
So our implementation strategy will be to create a new `InstructionVisitor` that will map `CompositeInstructions` to a 
python source string that resembles the code above. We begin by adding a `QuimbInstructionVisitor` to the `quimb_accelerator.hpp` file after the `QuimbAccelerator` declaration. 
```cpp
// Add these 2 lines to top of the file
#include "AllGateVisitor.hpp"
using namespace xacc::quantum;

... Accelerator code ...

class QuimbInstructionVisitor : public AllGateVisitor {
protected:
  std::string quimb_py_str = "gates = [\n";
public:
  void visit(Hadamard& h) override {
      quimb_py_str += "   ('H', " + std::to_string(h.bits()[0]) + "),\n";
  }
  void visit(CNOT& cnot) override {
      quimb_py_str += "   ('CNOT', " + std::to_string(cnot.bits()[0]) + ", " + std::to_string(cnot.bits()[1]) + "),\n";
  }
  ... other visit methods ...

  std::string getQuimbCode() {
      quimb_py_str += "]";
      return quimb_py_str;
  }
};
```

Now we can update the `execute` method to follow the pattern detailed above.
```cpp
void QuimbAccelerator::execute(
    std::shared_ptr<AcceleratorBuffer> buffer,
    const std::shared_ptr<CompositeInstruction> circuit) {

  auto visitor = std::make_shared<QuimbInstructionVisitor>();

  // Pre-order tree traversal
  InstructionIterator iter(circuit);
  while(iter.hasNext()) {
      auto instruction = iter.next();
      if (!instruction->isComposite()) {
        // Visit the Instruction
        instruction->accept(visitor);
      }
  }

  auto quimb_code = visitor->getQuimbCode();

  auto bit_strings_counts = execute_with_quimb(quimb_code, buffer->size());

  // Add the results to the buffer
  for (auto [bits, count] : bit_strings_counts) {
      buffer->appendMeasurement(bits, count);
  }

  return;
}
```

The above code illustrates the initial pattern discussed at the beginning of this article. We walk the IR tree, visit 
each node which constructs the data required as input by the Quimb simulator, executes the simulator and adds the results 
to the buffer. Now we look into what this execution actually looks like, how is `execute_with_quimb` implemented? The 
AIDE-QC stack provides [pybind11](https://github.com/pybind/pybind11) as part of the install so that developers can create plugins that are interoperable with Python. Specifically, we'll use the embedded interpreter provided by `pybind11`. To do so, we must update the `quimb_accelerator.hpp` header to keep track of the [py::scoped_interpreter_guard](https://pybind11.readthedocs.io/en/stable/advanced/embedding.html)
```cpp
...

#include <pybind11/stl.h>
#include <pybind11/stl_bind.h>
#include <pybind11/embed.h>
namespace py = pybind11;

class QuimbAccelerator : public Accelerator {
 protected:
  std::shared_ptr<py::scoped_interpreter> guard;
  std::map<std::string, int> execute_with_quimb(const std::string &code,
                                                const int n_qubits);
...
```
Let's look at our `execute_with_quimb` method implementation
```cpp
std::map<std::string, int> execute_with_quimb(const std::string& code, const int n_qubits) {
  if (!guard && !Py_IsInitialized()) {
    guard = std::make_shared<py::scoped_interpreter>();
  }

  std::string py_code = "from quimb.tensor import Circuit\n";
  py_code += "from collections import Counter\n";
  py_code += code;
  py_code += "\nqc = Circuit(" + std::to_string(n_qubits) + ")\n";
  py_code += "qc.apply_gates(gates)\n";
  py_code += "bit_strings = []\n";
  py_code += "for b in qc.sample(" + std::to_string(1024) + "):\n";
  py_code += "    bit_strings.append(b)\n";
  py_code += "counts = Counter(bit_strings)\n";

  auto locals = py::dict();
  try {
    py::exec(py_code, py::globals(), locals);
  } catch (std::exception &e) {
    std::stringstream ss;
    ss << "Quimb Exec Error:\n";
    ss << e.what();
    xacc::error(ss.str());
  }

  return locals["counts"].cast<std::map<std::string, int>>();
}
```
This method starts by checking if the python interpreter has been initialized, and if not, we allocate the 
`scoped_interpreter`. The next segment attempts to build up some Quimb Python source code that will 
incorporate the code generated by the `QuimbInstructionVisitor` to create a circuit, sample from that 
resultant wavefunction represented internally as a tensor network, and allocate a dictionary of measurement counts. 
We execute the code with `py::exec()` with a locally allocated `locals` dictionary, which we use to get 
the `counts` back as a `map<std::string, int>`. The function ends by returning this map, which is then used to 
persist the execution results to the buffer at the end of the `execute()` method. 

Build and install the above updates with 
```sh
cd build 
make -j4 install
```

We can now test this out with `qcor` via C++ or Python
<table>
<tr>
<th>Quimb Test in C++</th>
<th>Quimb Test in Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void bell(qreg q) {
  H(q[0]);
  CX(q[0], q[1]);
  Measure(q[0]);
  Measure(q[1]);
}

int main(int argc, char **argv) {
  auto q = qalloc(2);
  bell(q);
  q.print();
}
```
```sh
qcor -qpu quimb bell.cpp ; ./a.out
```
</td>
<td>

```python
from qcor import qjit, qalloc, qreg

@qjit
def bell(q : qreg):
    H(q[0])
    CX(q[0], q[1])
    for i in range(q.size()):
        Measure(q[i])

q = qalloc(2)
bell(q)
q.print()
```
```sh
python3 bell.py -qpu quimb
``` 
</td>
</tr>
</table>

Finally, let's see how to take user input via the `initialize` method. Above we have hardcode the number of shots to 1024. Let's see if we can accept that as input. To do so, we add a `int shots` member to the `QuimbAccelerator` and default it to 1024.
```cpp
...
class QuimbAccelerator : public Accelerator {
 protected:
  int shots = 1024;
  std::shared_ptr<py::scoped_interpreter> guard;
  std::map<std::string, int> execute_with_quimb(const std::string &code,
                                                const int n_qubits);
...
```

Next, we implement `initialize` to check for a `shots` key in the input parameters, and set it if it is found.
```cpp
void QuimbAccelerator::initialize(const HeterogeneousMap &params) {
  if (params.keyExists<int>("shots")) {
      shots = params.get<int>("shots");
  }
}
```
Now we can update `execute_with_quimb` to use this `shots` protected member
```cpp
std::map<std::string, int> execute_with_quimb(const std::string& code, const int n_qubits) {
  ...
  
  py_code += "bit_strings = []\n";
  py_code += "for b in qc.sample(" + std::to_string(shots) + "):\n";
  py_code += "    bit_strings.append(b)\n";
  
  ...
}
```

You can now run the above examples with the `-shots 2048` command line arguments to observe results that contain that many shots. 

## <a id="openqasm"></a> OpenQasm Compatible Backends
Any backend can be integrated in a relatively straightforward manner if that backend 
accepts an OpenQasm string as input. For instance, imagine a backend that takes as input a `qiskit.QuantumCircuit`. We can 
easily interface the `Accelerator` backends with APIs like this via the AIDE-QC source-to-source translation capabilities. Let's take a look:
```cpp
void MyAccelerator::execute(std::shared_ptr<AcceleratorBuffer> buffer, const std::shared_ptr<CompositeInstruction> circuit) {
  // Get the Staq OpenQasm Compiler
  auto staq = xacc::getCompiler("staq");

  // Translate the circuit to OpenQasm
  auto openqasm_str = staq->translate(circuit);

  // Execute with some function that accepts openqasm
  // This could be any OpenQasm compatible API
  auto results = execute_openqasm_api(openqasm_str);

  // Add the results to the buffer
  for (auto [bits, count] : bit_strings_counts) {
      buffer->appendMeasurement(bits, count);
  }
}
```
We leave the details of this OpenQasm-compatible backend API opaque for the purposes of this demonstration, but `execute_openqasm_api()` may for example, take the OpenQasm code string and use it to construct a `qiskit.QuantumCircuit` and use that to execute with the `qiskit` infrastructure. Of course, this is just an example, the above code should enable integration with any backend that accepts OpenQasm as input. 