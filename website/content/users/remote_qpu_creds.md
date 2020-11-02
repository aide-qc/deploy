---
title: "Remote QPU Credentials"
date: 2019-11-29T15:26:15Z
draft: false
weight: 15
---
`qcor` provides a set of command line arguments that make it simple to set your remote QPU API credentials. 

## <a id="ibm"></a> IBM API Credentials
To execute quantum kernels on the remote IBM backends, run the following
```sh
qcor -set-credentials ibm -key YOURKEY -hub YOURHUB -group YOURGROUP -project YOURPROJECT
```
where YOURKEY, YOURHUB, YOURGROUP, and YOURPROJECT are provided by your account with the IBM Quantum ecosystem. 

To view your currently set API credentials
```sh
qcor -print-credentials ibm
```
To update any aspect of your credentials (could do this for project, group, key, hub)
```sh
qcor -update-credentials ibm -project OTHERPROJECT
```
