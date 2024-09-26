# Getting Started 

## Set up the TSMP1_WorkflowEngine

**First**, clone this repository into your project-directory with its 
dependencies marked with git-submodules, 

``` bash
cd $PROJECT_DIR
git clone --recurse-submodules https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine.git
```

and export the root path of the cloned repository to an environment variable for later use.

``` bash
cd $PROJECT_DIR/TSMP1_WorkflowEngine
export BASE_ROOT=$(pwd)
```

> **Note**:
> If for any reason one of the submodule is not cloned correctly, you can 
reenforce and update by typing
`git submodule update --init --recursive -- <submodule_name>`
from the workflow root directory.

**Second**, get TSMP ready by cloning all component models (COSMO, ParFlow, 
CLM, and Oasis) into `src/TSMP/`, 

``` bash
cd ${BASE_ROOT}/src/TSMP
export TSMP_DIR=$(pwd)
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/cosmo5.01_fresh.git  cosmo5_1
git clone -b UseMaskNc https://github.com/HPSCTerrSys/parflow.git                       parflow
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/clm3.5_fresh.git     clm3_5
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/oasis3-mct.git       oasis3-mct
```

and build the binaries.

``` bash
cd $TSMP_DIR/bldsva
./build_tsmp.ksh --readclm=true --maxpft=4 -c clm3-cos5-pfl -m JURECA -O Intel
```

**Third**, install `int2lm` which is used to prepare the `COSMO` forcing needed
during the actual simulation. `int2lm` is provided as a submodule and can be
found in `src/int2lm3.00/`.
To build `int2lm` change to its directory and prepare the `Fopts` and `loadenv`
file. You find predefined files in `LOCAL`, which you can simply link to the
`int2lm` rootdir:

``` bash
cd ${BASE_ROOT}/src/int2lm3.00/                                                     
ln -sf LOCAL/JUWELS_Fopts ./Fopts && ln -sf LOCAL/JUWELS_Stage2020_loadenv ./loadenv
```

> **Note:**
> `Fopts` and `loadenv` are generic enough to work on both `JUWELS` and
`JURECA`, so stick with them on both machines for now.  

After preparation, source the environment, clean up the installation directory,
and compile the source:

``` bash
cd ${BASE_ROOT}/src/int2lm3.00/                                                      
source loadenv                                                                  
make clean                                                                      
make                                                                            
```

When no error is thrown, a binary called `int2lm3.00` is created.

**Finally**, adapt `ctrl/export_paths.ksh` to correctly determine the root 
directory of this workflow and `SimInfo.sh` to set the correct author 
information:

``` bash
cd $BASE_ROOT/ctrl
vi export_paths.ksh
vi SimInfo.sh
```

Within `export_paths.ksh` change the line   
``` bash
rootdir="/PATH/TO/YOUR/EXPDIR/${expid}"
```
according to you `$PROJECT_DIR` from above. To verify `rootdir` is set properly 
do   
`source $BASE_ROOT/ctrl/export_paths.ksh && echo "$rootdir" && ls -l $rootdir`.    
You should see the following content:

``` bash
PATH/TO/YOUR/PROJECT
ctrl/
doc/
forcing/
geo/
LICENSE
monitoring/
postpro/
README.md
rundir/
simres/
src/
```

Within `SimInfo.sh` change the lines   
``` bash 
export AUTHOR_NAME="AUTHOR NAME" 
export AUTHOR_MAIL="AUTHOR EMAIL" 
export AUTHOR_INSTITUTE="INSTITUTE"
```
Those infromation are used to be loged and saved with the simulation results and
the email is used to send `SLURM` notifications.

The setup is now complete, and can be run after providing proper restart and 
forcing files. 

## Provide restart files

To continue a simulation, restart-files are needed to define the initial 
state of the simulation. Since large simulations (simulation period of years / 
several decades), such as we are aiming for, are usually calculated as a 
sequence of shorter simulations (simulation period of days / months), each 
simulation represents a restart of the previous simulation. Therefore, restart 
files must be provided for each component and simulation.

Within this workflow, the component models expect the individual restart files 
to be located at:

```bash
$BASE_ROOT/rundir/MainRun/restarts/COMPONENT_MODEL
``` 

During the normal course of this workflow, the restart files are automatically 
placed there. Only for the very first simulation the user has to provide 
restart files manually to initialise the simulation. Therefore it is important 
to know that COSMO is able to run without restart files, than running a 
cold-start, while CLM and ParFlow always expect restart-files. So the user 
needs to provide restart-files for ParFlow and CLM only.   

In this example, we do run a simulation over the EUR-11 domain for the year 
1979, for which restart files could be taken from JSC machines. If needed, do 
request access to the related data project via 
[JuDoor](https://judoor.fz-juelich.de/login). The relevant data is stored under:

``` bash
/p/largedata2/detectdata/CentralDB/projects/z04/SPINUP_TSMP_EUR-11/restarts
``` 

To make the restart files available to the workflow, go to the restart 
directory and copy the restart files there:

``` bash
cd $BASE_ROOT/rundir/MainRun/restarts
# copy CLM restart file
cp -r /p/largedata2/detectdata/CentralDB/projects/z04/SPINUP_TSMP_EUR-11/restarts/clm ./
# copy ParFlow restart file
cp -r /p/largedata2/detectdata/CentralDB/projects/z04/SPINUP_TSMP_EUR-11/restarts/parflow ./
```
> **NOTE**:
> ParFlow needs the previous model-output as a restart-file, whereas CLM needs a 
special restart-file from the current time-step. This is why the date within 
the file name is different for CLM and ParFlow.

## Provide forcing (boundary) files

COSMO is a local model, simulating only a subdomain of the globe, and therefore 
needs to be informed about incoming meteorological conditions passing the 
domain boundary (as e.g. low pressure systems). This is done using local boundary 
files (`lbf` for short). At the same time, the status quo of the atmosphere is 
needed for the first time step (not to be confused with restart files!). In 
the meteorological domain this status quo is called ‘analysis’, wherefore this 
information is passed to COSMO with so called ‘local analysis files’  (`laf` for 
short).   
These two types of boundary files must to be provided for each simulation and 
are expected by the workflow under:

``` bash 
$BASE_ROOT/forcing/laf_lbfd/all
```

In the pre-processing step of this workflow the `laf_lbfd` files are generated
by `INT2LM` automatically wherefore on has to provide the raw meterological data
only, which could be taken from JSC machines. If needed, do request access to 
the data project via [JuDoor](https://judoor.fz-juelich.de/login). The raw 
forcing data are stored under:
``` bash
/p/largedata2/detectdata/CentralDB/era5/
```
To make the raw forcing files available to the workflow, go to the forcing 
directory and link the directory from above there:
``` bash
cd ${BASE_ROOT}/forcing
ln -sf /p/largedata2/detectdata/CentralDB/era5/ ./cafFilesIn
```

## Start a simulation

To start a simulation simply execute `starter.sh` from `ctrl` directory:

``` bash
cd $BASE_ROOT/ctrl
# adjust according to you need between 
# 'Adjust according to your need BELOW'
# and
# 'Adjust according to your need ABOVE'
vi ./starter.sh 
# start the simulation
./starter.sh 
```

## Start a simulation with GPU or MSA
Currently, the branch `msa_update` includes the necessary adaptions to use the 
workflow with ParFlow running on internal GPUs (GPU) and on the JUWELS-Booster
(MSA).
To use the functionality, ParFlow has to be compiled for GPU in the `TSMP/bldsva`
folder
```bash
./build_tsmp.ksh --readclm=true --maxpft=4 -c clm3-cos5-pfl -m JUWELS -O Intel -A GPU
```
After the compilation, rename the ParFlow and the binaries folder.
Use `_GPU` as an appendix for internal GPU runs and `_MSA` for cross-cluster 
submissions. 

```bash
mv TSMP/parflow_JUWELS_clm3-cos5-pfl/ TSMP/parflow_JUWELS_clm3-cos5-pfl_GPU/
mv TSMP/bin/JUWELS_clm3-cos5-pfl/ TSMP/bin/JUWELS_clm3-cos5-pfl_GPU/
```
In the branch `msa_update` `starter.sh` has new functionalities
(choice of GPU partition, etc..:).
Have look at them before you start the simulation. If you are ready submit the 
simulation with:
```bash
./starter.sh GPU
or
./starter.sh MSA
```

Note: GPU and MSA submissions are experimental. ParFlow tends to not probably 
terminate in GPU-runs compiled with Intel. MSA-runs on the JUWELS-Booster have 
problems with the Hypre library which is as a default used for simulations on 
EUR-11.

## Exercice
To become a little bit famillar with this workflow, work on the following tasks:

1) Do simulate the compleat year of 1979.
2) Plot a time serie of the spatial averaged 2m temperature for 1979.
3) Write down which information / data / files you might think are needed to 
   repoduce the simulation.
4) Think about how you could check the simulation is running fine during 
   runtime.

## Running not full coupled mode

The example above is for the fully coupled TSMP, but other model combinations can be run using this workflow as well. What to look out for when running in other than fully coupled mode can be read in the section ['Run not fully coupled experiments'](./inDetail/NotFullyCoupledExp.md).

