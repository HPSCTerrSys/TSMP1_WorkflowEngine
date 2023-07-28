# DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline 

> :warning: **Warning**  
> The current version / tag of this repository is < v1.0.0 and is therefore 
> still under testing, so use it with caution.

## Set up the TSMP_WorkflowStarter

**First**, clone this repository into your project-directory with its 
dependencies provided as git submodules, 

``` bash
cd $PROJECT_DIR
git clone --recurse-submodules https://gitlab.jsc.fz-juelich.de/detect/detect_z03_z04/setups_configurations/DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline.git
```

and export the following path to an environment variable for later use.

``` bash
cd DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline
export BASE_ROOT=$(pwd)
```

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

**Third**, install `int2lm` which is needed to prepare the COSMO forcing needed 
during the actual simulation. `int2lm` is provided as a submodule and can be 
found in `src/int2lm3.00/`.    
To build `int2lm` change to its directory and prepare the `Fopts` and `loadenv` 
file. You find predefined files in `LOCAL`, which you can simply link to the 
int2lm-rootdir:                                              
```
cd ${BASE_ROOT}/src/int2lm3.00/                                                     
ln -sf LOCAL/JUWELS_Fopts ./Fopts && ln -sf LOCAL/JUWELS_Stage2020_loadenv ./loadenv
```
Note: `Fopts` and `loadenv` are generic enough to work on both `JUWELS` and 
`JURECA`, so stick with them on both machines for now.    

After preparation, source the environment, clean up the installation directory, 
and compile the source:                                                                    
```                                                                             
cd ${BASE_ROOT}/src/int2lm3.00/                                                      
source loadenv                                                                  
make clean                                                                      
make                                                                            
```                                                                             
When no error is thrown, a binary called `int2lm3.00` is created.

**Next**, customise your personal information in `ctrl/SimInfo.sh`. The lines 
you need to adjust are   
`AUTHOR_NAME=`  
`AUTHOR_MAIL=`  
`AUTHOR_INSTITUTE=`  
This information will be used to add to simulation results and to send SLURM 
notifications.

``` bash
cd $BASE_ROOT/ctrl
vi SimInfo.sh
```

**Finally**, adapt `ctrl/export_paths.sh` to correctly determine the root 
directory of this workflow:

``` bash
cd $BASE_ROOT/ctrl
vi export_paths.sh
```

Within this file change the line   
`rootdir="/ADD/YOUR/ROOT/DIR/${expid}"`   
according to you `$PROJECT_DIR` from above. To verify `rootdir` is set properly 
do   
`source $BASE_ROOT/ctrl/export_paths.sh && echo "$rootdir" && ls -l $rootdir`.    
You should see the following content:

```
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
only needs to provide restart-files for ParFlow and CLM only.

In this example, we do run a simulation over the EUR-11 domain for the year 
1979, for which restart files could be taken from:

```
/p/largedata2/detectdata/projects/Z04/SPINUP_TSMP_EUR-11/restarts
``` 

If needed, do request access to the related data project via [JuDoor](https://judoor.fz-juelich.de/login).

To make the restart files available, go to the restart directory, and copy the 
restart files there:

``` bash
cd $BASE_ROOT/rundir/MainRun/restarts
# copy CLM restart file
cp -r /p/largedata2/detectdata/projects/Z04/SPINUP_TSMP_EUR-11/restarts/clm ./
# copy ParFlow restart file
cp -r /p/largedata2/detectdata/projects/Z04/SPINUP_TSMP_EUR-11/restarts/parflow ./
```
**NOTE**: 
ParFlow needs the previous model-outpt as a restart-file, whereas CLM needs a 
special restart-file from the current time-step. This is why the date within 
the file name is different.

## Provide forcing files for atmosphere

**TBE**
```
${BASE_ROOT}/forcing
ln -sf /p/largedata2/detectdata/CentralDB/era5/ ./cafFilesIn
```
**TBE**

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

## Exercice
To become a little bit famillar with this workflow, work on the following tasks:

1) Do simulate the compleat year of 2020.
2) Plot a time serie of the spatial averaged 2m temperature for 2020.
3) Write down which information / data / files you might think are needed to 
   repoduce the simulation.
4) Think about how you could check the simulation is running fine during 
   runtime.

## Further documentation
Please find further and more general information about the workflow [here](https://niklaswr.github.io/TSMP_WorkflowStarter/content/introduction.html)
