# Introduction

[TSMP1_WorkflowEngine](https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine) provides an example of how to run bigger simulations. 
Bigger simulations, such as long lasting climate simulations, require a bit more 
effort to run than the TSMP included test-cases.
This extra effort ranges from a proper directory structure, to some helper 
scripts, to how to subdivide and submit a simulation that takes months to run 
through. Also a proper strategy on how to possibly reproduce simulation results 
is of good scientific practise.  

The following examples and descriptions are based on a fully coupled climate 
simulation case over the [EUR-11 domain](https://gitlab.jsc.fz-juelich.de/detect/detect_z03_z04/constant_fields/TSMP_EUR-11), 
but the underlying idea applies to all kinds of simulations, such as LESs, NWPs, 
and others.   
It is assumed that the user has access to the [JSC-Infrastructure](https://www.fz-juelich.de/en/ias/jsc/systems/supercomputers), where 
large forcing data are stored. The user can run this example also without access 
to the [JSC-Infrastructure](https://www.fz-juelich.de/en/ias/jsc/systems/supercomputers), but will then have to provide the forcing data 
themselves.  

The following documentation is divided into different sections, each of which 
explains one part of the workflow in detail. For a quick start, there is the 
[Getting Started](./gettingstarted.md) section, which guides the user through all the steps needed 
to get this workflow up and running, without going into detail - this is the recommended entry point.
