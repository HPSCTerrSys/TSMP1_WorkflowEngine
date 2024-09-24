# Run not fully coupled experiments

The [GettingStarted](../gettingstarted.md) section explains the workflow using a fully coupled TSMP as an example. For the sake of completeness, we'll explain here how to run a not fully coupled experiment using this workflow as well.   
However, the following lines assume that you have already run the fully coupled simulation from [GettingStarted](../gettingstarted.md). If not, go back to that section and run the default example first.


Running a not fully coupled experiment is not very different from running a fully coupled experiment. The main differences are   
1. You have to build TSMP for the model combination you want.
2. Not all static files / namelists need to be copied to the `rundir`.
3. Different model combinations require different forcing files.

**1.** Building TSMP for different model combinations is quite simple and controlled by the `-c` flag:
``` bash
# build TSMP as in default example but for clm3-pfl only
./build_tsmp.ksh --readclm=true --maxpft=4 -c clm3-pfl -m JURECA -O Intel
# build TSMP as in default example but for pfl only
./build_tsmp.ksh --readclm=true --maxpft=4 -c pfl -m JURECA -O Intel
```

**2.** You must inform the workflow which model components are involved by using the correct `COMBINATION` flag in `CASES.conf`. Depending on the `COMBINATION` flag, the workflow will automatically copy only the required static and namelist files, perform post-processing only for involved component models, etc.   

**3.** According to the `COMBINATION` flag, the workflow automatically sets the forcing setting with the top model involved. This means that if `clm3-cos5-pfl` is run, COSMO is the top model and therefore COSMO needs forcing files, all other components see the forcing via the coupling. If `clm3-pfl` is run, CLM is the top model, so CLM will need forcing files, and ParFlow will see forcing via coupling. If `pfl` is run, ParFlow will need forcing files.   
Technically, this is archived by keeping the name list very general and thus setting them up assuming the associated model needs forcing files. The workflow then simply deletes these lines if the component model does not need forcing. For an example [see how related lines are deleted for the parflow namelist](https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine/blob/main/ctrl/start_simulation.sh#L201-L203) when CLM is involved.

The forcing files itself has to be provided by the user under the following paths:
``` bash
# forcing for CLM
${BASE_ROOT}/forcing/clm/atm_forcing/YYYY-MM.nc
# forcing for ParFlow
${BASE_ROOT}/forcing/parflow/evaptrans_${formattedStartDate}.nc
```
where `YYYY-MM` is the year and month of the simulation start date, and
`${formattedStartDate}` is the formatted start date of the simulation according to the [dateString set in starter.sh](https://github.com/HPSCTerrSys/TSMP1_WorkflowEngine/blob/main/ctrl/starter.sh#L21C1-L21C11).
For the correct content and structure of the forcing file itself, we refere to the individual model manual.

> **IMPORTANT NOTE:**  
> Running ParFlow standalone build with TSMP does need a [patched / fixed ParFlow version](https://github.com/HPSCTerrSys/parflow/tree/ActivateEvapTransTSMP), where Evaptrans forcing is possible even without the `HAVECLM` compiler flag.
