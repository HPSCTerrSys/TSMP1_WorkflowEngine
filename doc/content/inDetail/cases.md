# CASES

To explain CASES within this workflow, let's start with some more fundamental.    

In the philosophy of this workflow, a complete workflow repository is an experiment. 
This means for example that this repository (TSMP1_WorkflowEngine) with all its submodules, is an experiment.    
An experiment is one or more (similar) simulations aimed at investigating a particular question, proving a particular hypothesis, or demonstrating a particular situation.
Let's say you want to run a climate simulation over the EUR-11 domain in fully coupled TSMP mode. So you set up a complete workflow repository like this one, give it a name and run your simulation - this is an experiment.     
Next, your supervisor wants you to run a standalone ICON simulation over South Africa to investigate the potential for an offshore wind farm - this is another  experiment where you will set up a new complete workflow repository with a new appropriate name.    
Two different simulations, two different workflow repositories, two experiments.   
Now let's assume a sensitivity study. You want to run a climate simulation over the EUR-11 domain in fully coupled TSMP mode and you want to know how sensitive this simulation is to soil porosity. You need to run several simulations for the full time period, each differing only in a few settings in the ParFlow namelist. Even though these are separate simulations, they belong to the same experiment and should be run within the same workflow repository. This is where CASES come in.

CASES are different simulations within the same experiment.    
Since there is only one `rundir`, one `namelist` directory, one `simres` directory, etc., the different CASES (the different simulations) have to be technically separated so that they do not interfere with each other - e.g. so that they do not overwrite each other. This is done with the `CASES.conf` file, which defines different subdirectories for each CASE. Which CASE to run is controlled within `starter.sh` with the flag `CaseID="MainRun"`. For technical reasons, CASES are always used, even if only one simulation is run, but this is not a big deal.

The technical functionality of CASES is actually quite simple. CASES takes advantage of the fact that all paths within this workflow are determined by the `export_paths.ksh` script, which is shown below:
```
expid="TSMP1_WorkflowEngine"
rootdir="/PATH/TO/YOUR/EXPDIR/${expid}"
export EXPID="${expid}"
# export needed paths
export BASE_ROOTDIR="${rootdir}"
export BASE_CTRLDIR="${rootdir}/ctrl"
export BASE_EXTDIR="${rootdir}/ctrl/externals"
export BASE_ENVSDIR="${rootdir}/ctrl/envs"
export BASE_NAMEDIR="${rootdir}/ctrl/namelists"
export BASE_LOGDIR="${rootdir}/ctrl/logs"
export BASE_FORCINGDIR="${rootdir}/forcing"
export BASE_RUNDIR="${rootdir}/rundir"
export BASE_SIMRESDIR="${rootdir}/simres"
export BASE_GEODIR="${rootdir}/geo"
export BASE_POSTPRODIR="${rootdir}/postpro"
export BASE_MONITORINGDIR="${rootdir}/monitoring"
export BASE_SRCDIR="${rootdir}/src"
```
So for example, if any script in this workflow needs to copy a forcing file, it will use the `$BASE_FORCINGDIR` variable to access the `.../forcing/` directory. The same does apply if any script needs to load an environment file, it will use the `$BASE_ENVSDIR` variable to access the `.../ctrl/envs/` directory, where the environment files are stored. And so forth.

CASES will now expand these base directories by the relative path set in `CASES.conf`. See below for an example `CASES.conf`:
```
[MainRun]
    CASE-NAME = MainRun
    CASE-CALENDAR="365_day"
    CASE-DESCRIPTION = 'production'
    CASE-FORCINGDIR = /
    CASE-RUNDIR = /MainRun
    CASE-SIMRESDIR = /MainRun
    CASE-POSTPRODIR = /MainRun
    CASE-MONITORINGDIR = /MainRun
    CASE-NAMEDIR = /MainRun
    CASE-GEODIR = /TSMP_EUR-11/static
    CASE-COMBINATION = "clm3-cos5-pfl"
```
The CASE defined here is `MainRun` - the default case. So when the `MainRun' CASE is run, all base paths are extended by the above relative paths, resulting in
```
BASE_FORCINGDIR="${rootdir}/forcing" >> "${rootdir}/forcing/”
BASE_RUNDIR="${rootdir}/rundir" >> "${rootdir}/rundir/MainRun" 
BASE_SIMRESDIR="${rootdir}/simres" >> "${rootdir}/simres/MainRun"
BASE_POSTPRODIR="${rootdir}/postpro" >> "${rootdir}/postpro/MainRun"
BASE_MONITORINGDIR="${rootdir}/monitoring" >> "${rootdir}/monitoring/MainRun"
BASE_NAMEDIR="${rootdir}/ctrl/namelists" >> "${rootdir}/ctrl/namelists/MainRun"
BASE_GEODIR="${rootdir}/geo" >> "${rootdir}/geo/TSMP_EUR-11/static"
```
The actual expansion of the base paths is done by the function [updatePathsForCASES()](https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine/blob/main/ctrl/start_helper.sh#L158C1-L191) which is called in [starter.sh](https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine/blob/main/ctrl/starter.sh#L108).

If any script in the workflow then wants to store files in the `simres/` directory, it uses the `$BASE_SIMRESDIR` variable to store the data in `${rootdir}/simres/MainRun`. If different CASES point to different subdirectories, this prevents the simulation from interfering with each other and allows multiple simulations from different CASES to run in parallel.  
You will notice that `$BASE_FORCINGDIR` is not extended, which is a way of allowing different CASES to use the same forcing. 
Going back to the sensitivity study example, you would use a similar CASE structure to MainRun above. All simulations share the same geo files, the same forcing, but different namelists and different directories to store the output.
