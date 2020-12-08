---
title: "Hybrid C++ / Python Plugins"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---

## Background
In this article, we will demonstrate how one might integrate python code as a new plugin with the C++ AIDE-QC stack, thereby making 
it available for use with the C++ and Python AIDE-QC API. We have shown this in a cursory way in the [Add a New Quantum Backend](implement_accelerator) 
article. Here we devote a bit more time to the pybind11 bindings, and the requirements for ensuring a working 
plugin for use in C++ and Python. 

As an example we will try to integrate a Qiskit Transpiler pass as a QCOR optimization pass. 
