---
title: "Add a New Circuit Synthesis Strategy"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

Here we describe how developers can extend the AIDE-QC stack with support for a new circuit synthesis strategy. 
We define circuit synthesis at the black-box level: a unitary matrix goes in and a list of one and two 
qubit gates come out. 

## <a id="background"></a> Background
To understand the class architecture for circuit synthesis strategies, it is important to understand the 
internal intermediate representation that AIDE-QC leverages for compiled quantum kernels. AIDE-QC builds upon 
the XACC intermediate representation, which exposes `Instruction` and `CompositeInstruction` abstract classes that 
are intended for subclassing for concrete instruction types and collections of concrete instructions. The IR model 
puts forward a collection of default `Instruction` sub-types for common quantum gates, and a `Circuit` sub-class for 
`CompositeInstruction` that models a quantum circuit (collection of gates). Pertinent methods on the `Circuit` (inherited from 
`CompositeInstruction`) consist of `addInstruction`, `replaceInstruction`, `insertInstruction`, `getInstructions`, and `expand`. These are 
all pretty self-explanatory, but `expand` requires a bit of a description of its functionality, as it is critical 
to circuit synthesis in the AIDE-QC stack. This method has signature `bool expand(options : HeterogeneousMap)`. 
The `options` `HeterogeneousMap` is a data structure that maps `string` keys to values of any type. The goal of 
`expand` is to take as input this options map, and use the information contained within it to construct 
`this` (or `self` in the Python jargon) `CompositeInstruction`, return `true` on success and `false` on an error. 

Therefore, to inject a new circuit synthesis strategy into the stack, one simply implements a new `Circuit` sub-type with 
a valid and strategy-specific implementation of `expand`. Of note - the compiler stack will always pass the `unitary` 
key with corresponding `Eigen::MatrixXcd` value for circuit synthesis strategies coming from the use of `decompose {}(...)` in 
C++ or `with decompose(...) as mat_var:` in Python. 

## <a id="create-synth"></a> Create Custom Circuit Synthesis Plugin
We start by creating a directory and the necessary files for the creation of a new circuit synthesis plugin
```sh
mkdir my_circ_synth && cd my_circ_synth
touch CMakeLists.txt manifest.json my_circ_synth.{hpp,cpp}
```

The plugin must define a `manifest.json` file to encode information about the plugin name and description. We populate the file with the following
```json
{
  "bundle.symbolic_name" : "my_circ_synth",
  "bundle.activator" : true,
  "bundle.name" : "My Cool Circuit Synthesis Method",
  "bundle.description" : "Cool Description Here."
}
```
Now we populate the `CMakeLists.txt` file with typical `CMake` boilerplate project calls, plus additional code to correctly build our plugin and install to the appropriate plugin folder location:
```cmake
# Boilerplate CMake calls to setup the project
cmake_minimum_required(VERSION 3.12 FATAL_ERROR)
project(my_circ_synth VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)

# Find XACC, provides underlying plugin system
find_package(XACC REQUIRED)

set(LIBRARY_NAME my-circ-synth)
file(GLOB SRC my_circ_synth.cpp)
usfunctiongetresourcesource(TARGET ${LIBRARY_NAME} OUT SRC)
usfunctiongeneratebundleinit(TARGET ${LIBRARY_NAME} OUT SRC)
add_library(${LIBRARY_NAME} SHARED ${SRC})

target_include_directories(${LIBRARY_NAME} PUBLIC . 
                                    LBFGSpp/include 
                                    ${XACC_ROOT}/include/eigen)

# _bundle_name must be == manifest.json bundle.symbolic_name !!!
set(_bundle_name my_circ_synth)
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
The above CMake code is pretty much ubiquitous across all XACC plugin builds. The first crucial part is `find_package(XACC)` which can be configured or customized with the `cmake .. -DXACC_DIR=/path/to/xacc` flag. Next we create a shared library containing the compiled `my_circ_synth` code, and configure it as a plugin with appropriate `usfunction*` calls (from the underlying `CppMicroServices` infrastructure). We link the library to the `xacc::xacc` target, configure the `RPATH` such that it can link to the install `lib/` directory, and install to the plugin storage directory. 

Next, we populate the `my_circ_synth.{hpp,cpp}` files with the required skeleton code
```cpp
#pragma once

#include "Circuit.hpp"
#include "IRProvider.hpp"
#include <Eigen/Dense>

// Feel free to use your own namespaces
namespace xacc {
namespace circuits {
class MyCircSynth : public xacc::quantum::Circuit {
public:
  MyCircSynth() : Circuit("my_custom_synth") {}
  bool expand(const xacc::HeterogeneousMap &runtimeOptions) override;
  const std::vector<std::string> requiredKeys() override;
  ~MyCircSynth();
  DEFINE_CLONE(PyQsearch);
};
} // namespace circuits
} // namespace xacc
```
```cpp
#include "my_circ_synth.hpp"
#include "xacc.hpp"
#include "xacc_plugin.hpp"

namespace xacc {

namespace circuits {
bool MyCircSynth::expand(const xacc::HeterogeneousMap &parameters) {

  Eigen::MatrixXcd unitary;
  if (parameters.keyExists<Eigen::MatrixXcd>("unitary")) {
    unitary = parameters.get<Eigen::MatrixXcd>("unitary");
  }
  
  // This is where you write your circuit synthesis code!!!
  // Goal here is to take the unitary matrix and output some 
  // kind of qasm-like representation. Ultimately, the output 
  // needs to be mapped to XACC IR Instructions and added to this 
  // Circuit with this->addInstruction(...). 

  // For demonstration purposes, 
  // lets assume that you have some way to convert this unitary to 
  // a OpenQasm string. We'll use the XACC staq Compiler to map this 
  // OpenQasm string to XACC IR and addInstruction on this Circuit

  auto oqasm_src = my_custom_way_to_get_openqasm(...);

  // Get the Staq Compiler and create XACC IR from oqasm_src
  auto staq = xacc::getCompiler("staq");
  auto program = staq->compile(oqasm_src)->getComposites()[0];

  // Add all Instructions in program to this Circuit
  for (int i = 0; i < program->nInstructions(); i++) {
    addInstruction(program->getInstruction(i));
  }

  // We suceeded, return true
  return true;
}

const std::vector<std::string> PyQsearch::requiredKeys() { return {"unitary"}; }
} // namespace circuits
} // namespace xacc

// Must register this plugin as an Instruction!
REGISTER_PLUGIN(xacc::circuits::MyCircSynth, xacc::Instruction)
```
The goal of the `expand` implementation is to extract the incoming unitary matrix, run your custom circuit synthesis strategy on it, and 
then map that result to XACC `Instructions` which can then be added to `this` `Circuit. 

Build and install this plugin with the following commands (from the top-level of the project directory)
```sh 
mkdir build && cd build 
cmake .. -G Ninja -DXACC_DIR=$(qcor -xacc-install)
cmake --build . --target install
```

Now to use this within the AIDE-QC stack
<table>
<tr>
<th>MyCircSynth in C++</th>
<th>MyCircSynth in Python</th>
</tr>
<tr>
<td>

```cpp
__qpu__ void foo(qreg q) {

    decompose {
        UnitaryMatrix u = UnitaryMatrix::Identity(8);
        // fill matrix
    }(q, my_circ_synth)

}
```

</td>
<td>

```python
from qcor import *

@qjit
def foo(q : qreg):
    with decompose(q, my_circ_synth) as u:
        # fill u...

```
</td>
</tr>
</table>