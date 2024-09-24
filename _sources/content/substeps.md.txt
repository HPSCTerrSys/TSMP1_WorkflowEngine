# Substeps

The essence of the workflow is to break up large experiments into several 
sub-steps, for a more robust and easier handling

First, the experiment is split into several much shorter simulations, that 
e.g. a multi-decade climate experiment typically consists of several 
simulations, each covering a period of one month.  
Second, the workflow further split each simulation into sub-steps, namely the 
**pre-processing**, the actual **simulation**, the **post-processing**, and the 
**finishing**, to increase the performance and to modularise the workflow as 
much as possible.

## Pre-processing

The pre-processing (prepro) sub-step is intended to encompass all tasks that 
need to be 
performed prior to the actual simulation and therefore usually includes the 
processing of the forcing data, which is highly individual. An example of this 
could be the resampling of the raw forcing data to the computational grid of the 
component model used.

## Simulation

The simulation sub-step is the core step of the workflow. Scripts in this step 
set up the run directory (`rundir`), run the simulation, clean up by moving the 
simulation results to the simulation results directory (`simres`), and log the 
exact workflow used to enable reproduction.

In detail, an identifiable, individual run directory is created for each 
simulation as a subdirectory of `rundir/` to allow the user to run multiple 
simulations in parallel. Usually this subdirectory is named after the current 
simulation date, so if the monthly simulation for January in 1950 is run, the 
directory `rundir/19500101/` is created.  
Then all the necessary files are copied to the run directory, such as the model 
executables, namelists, auxiliary files, restart files, and (some) static files. 
In turn, the raw model output from the model components is also dumped into the 
run directory.   
The namlists are adapted according to the current simulation, by replacing 
predefined flags with the correct values. This could be the correct simulation 
date, for example, which varies from simulation to simulation, and the workflow 
takes care to set the correct values here.   
Once everything is set up, the simulation is started.   
After the simulation has finished, the raw model output is moved from the run 
directory to the simulation results directory (`simres`). Again, a subdirectory 
is created with the same name as the run directory. This is done to keep only 
the simulation results and to avoid storing e.g. big, redundant static files. 
Next to the simulation results, some log files are created to keep track of the 
exact workflow used, by logging the repository used, the commit, and a 
`git diff` of unstaged files. Further restart files are copied to a dedicated 
restart directory to allow the next simulation to start correctly.  
Finally, the run directory is removed, as it is no longer needed, to keep the 
workflow directory structure clean.

## Post-processing

The post-processing (postpro) step is used to provide higher level products 
than the raw 
model data. Examples include calculating variables that are not a direct output 
of the model (e.g. discharge for ParFlow), aggregating model output for defined 
time periods (e.g. writing monthly files), adding experiment specific metadata 
(e.g. CF-convention), storing output in a specific data structure (e.g. 
CMORized), or generating some quick insitu quality check plots for monitoring. 
Some of these tasks are quite mandatory, such as adding specific metadata to 
keep track of what is stored with the files and to make the data easily 
available to others. Other tasks are performed to save time. Because the 
post-processing step is performed immediately after the simulation and is a 
separate slurm job, time-consuming calculations could be performed here without 
losing performance of the entire experiment, compared to running simulation and 
post-processing in one job, or even running the post-processing after the entire 
experiment.

## Finishing

The finishing substep is somewhat optional. In principle, all substeps are 
self-contained and will, for example, clean up temporarily generated data at the 
end of the specific substep. However, sometimes it is useful to execute some 
tasks after all other substeps. In this workflow those tasks are the checksum 
calculation and the compression.    
So when all the previous tasks have been completed, the checksum of the 
generated data is calculated and is stored in a file within the same directory. 
This is done to allow the user to verify that the data is not corrupted. And 
this task is performed after all other substeps, simply for performance reasons, 
e.g. so that the next simulation can start, without waiting for the checksum to 
be calculated.    
The compressing task is simply to compress the data in `simres/`, as these are 
no longer needed (post-processing is done) to prepare for archiving.

