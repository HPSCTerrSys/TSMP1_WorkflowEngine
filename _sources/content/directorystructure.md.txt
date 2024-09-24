# Directory Structure

As trivial and minor as a proper directory structure may sound, it  is very 
important.   
As the name suggests, a directory structure structures the workflow. Directory 
names do dictate where to find certain files, where to store simulation results, 
forcing data, etc. This helps the maintainer to develop the source code, and 
also helps the user to get started and become familiar with the workflow. 

The directory structure of this workflow consists of a single layer only 
and contains the following directories:

```
TSMP_WorkflowStarter/
|    
|---- ctrl
|    |---- namelist
|    |---- env
|---- forcing
|---- geo
|---- monitoring
|---- postpro
|---- rundir
|---- simres
|---- src
```

There may be other subdirectories, but those are not part of the mentioned 
directory structure and may vary from setup to setup.

All of the directories are named very strictly according to what they are aimed 
for. With some experience of the workflow, these names will become very 
intuitive. Each directory is described in detail below.

## ctrl/
`ctrl/` (**c**on**tr**o**l**) contains all the scripts needed to control the 
workflow, as well as scripts written specifically for this workflow, such as 
post-processing scripts. 

### ctrl/namelist/
`ctrl/namelist/`, clearly contains **namlist**s for the individual component 
models used within the workflow. As these namelists do control the model 
behaviour and are specific to the workflow, this is a subdirectory of `ctrl/`.

### ctrl/env/
`ctrl/env/` contains the **env**iroment files used. Since each simulation 
depends on a specific set of programs (e.g. python) and libraries (e.g. netCDF) 
in a specific version, we need to provide this information to the user of the 
workflow. Environment files does list these dependencies and ensure that the 
required environment is set up correctly.

## forcing/
`forcing/` is a directory containing any **forcing** files needed. This could 
be an atm. forcing dataset driving the land surface model CLM or lateral 
boundary conditions needed by the atm. Model COSMO.

## geo/
`geo/` contains files required by the component models that define the model 
domain. This could be topographic data, land cover data, soil properties, grids 
defining the spatial extent of the domain and many more. Often this data is 
referred to as `static files`, but as some of the required data sets, such as 
the land cover, may change over time, `static` could be misleading, hence the 
name `geo/`.

## monitoring/
`monitoring/` contains the output of some **monitoring** functions. 
Monitoring of simulations is a crucial aspect to ensure accurate and reliable
results. Various factors can impact the simulation outcomes, ranging from 
simulation interruptions and crashes to subtle corruptions of the results. 
Manually reviewing simulation results periodically can be extremely 
time-consuming, especially considering the large size of simulation outputs and 
the potentially lengthy duration of simulations, which may run for several 
months. To address this challenge, a monitoring functionality has been 
incorporated into this workflow.

The monitoring functionality automatically generates summary plots at regular
intervals, providing a concise overview of the simulation progress. A detailed 
description of the implementation could be found within the 
[Simulation Monitoring](./inDetail/monitoring.md#simulation-monitoring) section.  
Those monitoring plots are stored in the `monitoring/` directory, allowing users 
to conveniently monitor 
the simulation directly by browsing through them. It is also conceivable that 
one could upload these plots to a web server, enabling even more accessible
monitoring of the simulation. Scripts providing this functionality have been
intentionally designed with simplicity and robustness in mind. While they may 
not generate publication-ready plots, they serve the purpose of providing 
essential information about the simulation. Users should bring a basic 
understanding of the simulation results to effectively utilize these scripts.


## postpro/
`postpro/` simply contains the **post-pro**cessed simulation results. The 
post-processing step is thereby very individual for each simulation and can vary 
from simple aggregation of simulation results (to e.g. monthly files), to the 
calculation of further diagnostics derived from the original simulation results.

## rundir/
`rundir/` is the directory in which the actual simulation **run**s. In order to 
run a simulation, you need a directory where everything is put together, i.e. 
static files, executables for individual component models, namelist, etc. for 
that particular simulation. Most of the time the actual run directory is even a 
subdirectory of `rundir/`, automatically created by the workflow, allowing you 
to run multiple simulations in parallel.

## simres/
`simres` simply contains the raw (not post processed) **sim**ulation 
**res**ults. In addition, some log files are stored with each simulation 
results, containing information about which workflow was used to generate those 
simulation results. If the workflow is used correctly, this log file will 
contain all the information  needed to reproduce the simulation result.

## src/
`src/` contains **s**ou**rc**e code used within the workflow. The most 
prominent of these is the cloned and build [TSMP](https://github.com/HPSCTerrSys/TSMP), 
but other external code is also placed here.

## export_paths.sh
Not directly part of the directory structure, but an important aspect of why 
this structure is used, is the `export_path.sh` script located in `ctrl/`. This 
script is one of the core pieces of code in this workflow, and allows you to run 
the workflow from any location, and even change the location during runtime. 
`export_paths.sh` is loaded at the beginning of each simulation and exports the 
absolute paths to the main directories (the ones above) in environment 
variables. Each script within this workflow in turn uses these environment 
variables to refer to other directories and scripts. This avoids the problem of 
using hard-coded paths, and gives the user full flexibility in where the 
simulation is run.
