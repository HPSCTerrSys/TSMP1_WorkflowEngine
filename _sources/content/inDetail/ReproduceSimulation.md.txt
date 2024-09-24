# Reproduce Simulation

The functionality to reproduce individual simulations is very important. 
Reproducibility is not only good scientific practice, but also protects you from data loss and allows further testing even after the entire experiment has been completed.

To enable reproducibility, this workflow tracks (almost) everything with git on remote repositories (e.g. GitLab) and stores the exact settings used for individual simulations in the corresponding `simres/` directory. Below is an example of what this looks like in detail, and how to actually reproduce a simulation restored from tape.

**NOTE:**  
The forcing files used are not tracked because the storage volumes are too large.   
**Tracking the forcing files is the responsibility of the experimenter!**


## HISTORY.txt

The core element needed to reproduce a simulation is the `HISTORY.txt` file, stored in `simres/CASE/SIMDATE/log/HISTORY.txt`. Here `CASE` is the CASE name, e.g. `MainRun` by default, and `SIMDATE` is the actual simulation data, e.g. `1978120100`. Both will vary from experiment to experiment.   
An example of a `HISTORY.txt` file is shown below:
``` bash
###############################################################################
Author: Niklas WAGNER
e-mail: n.wagner@fz-juelich.de
version: Do 31. Aug 06:17:42 CEST 2023
###############################################################################
MACHINE: jurecadc
PARTITION: dc-cpu
CaseID: ProductionV1
Total runtime: 05h:12m:10s
###############################################################################
The following setup was used: 
###############################################################################
WORKFLOW 
-- REPO:
remote: https://icg4geo.icg.kfa-juelich.de/Configurations/TSMP/DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaselineHwu.git
-- LOG: 
tag: v0.1.0-79-g66b50b7
commit: 66b50b787795ea32e32bbd4332d2e3d1a7ca1566
author: Niklas Wagner
date: Wed Aug 23 16:32:12 2023 +0200
subject: Add production namelist-link and rundir

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of `git diff HEAD` is printed to `GitDiffHead_workflow.diff`.
###############################################################################
Submodule: geo/TSMP_EUR-11
remote: https://gitlab.jsc.fz-juelich.de/detect/detect_z03_z04/constant_fields/TSMP_EUR-11.git
tag: v3.1.1-36-g5fbc818
commit: 5fbc81871a161349abb71ffb8fcaa6b78bcef60a
author: Niklas Wagner
date: Thu Jun 22 11:56:05 2023 +0200
subject: Add maintenance section in documentation

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of `git diff HEAD` is printed to `GitDiffHead_TSMP_EUR-11.diff`.
###############################################################################
Submodule: src/TSMP
remote: https://github.com/HPSCTerrSys/TSMP.git
tag: v1.4.0
commit: dad9a4c4d5816839fcf64dd63f6a1eb1fda17655
author: chartick
date: Wed Apr 26 09:09:52 2023 +0200
subject: Merge pull request #187 from HPSCTerrSys/release_candidate

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of `git diff HEAD` is printed to `GitDiffHead_TSMP.diff`.
```

We can easily extract some information from this file, such as who is the author, when was this simulation run, on which machine was this simulation performed, how long was the runtime of this simulation etc.    
More important is the information about the different repositories used. Mandatory and always present is the information about the workflow repository used:
``` bash
WORKFLOW 
-- REPO:
remote: https://icg4geo.icg.kfa-juelich.de/Configurations/TSMP/DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaselineHwu.git
-- LOG: 
tag: v0.1.0-79-g66b50b7
commit: 66b50b787795ea32e32bbd4332d2e3d1a7ca1566
author: Niklas Wagner
date: Wed Aug 23 16:32:12 2023 +0200
subject: Add production namelist-link and rundir

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of `git diff HEAD` is printed to `GitDiffHead_workflow.diff`.
```
This logs the repository URL so that we can clone the workflow used and reuse it. It also logs the commit used, so we can check out the specific version of the workflow used for the simulation we want to reproduce. Even if the repository history has been broken, e.g. by applying a `git rebase`, etc., the tag, commit author, commit date, and commit subject are all tracked, to provide as much information as possible to find the exact same version of the workflow as was used for the original simulation.  

However, even if the above sounds like all the necessary information is being logged, it is possible to defeat this logging by not committing changes to the workflow during the runtime of the original simulation. Since uncommitted changes are not part of the git history, those changes are not part of this logging either. To avoid losing information this way, e.g. because important changes to the workflow were not committed, the current state of the working tree is also logged, by storing the output of `git diff HEAD` in `GitDiffHead_workflow.diff`. In this way, `GitDiffHead_workflow.diff` acts as a sort of patch file, which we can reapply to our recloned repository to restore the exact same state that was used for the original simulation.  

As with the workflow repository, all submodels used are also tracked.


## Reproducing a simulation

To reproduce a simulation, we need to do the following.


### Restage the `simres/` directory

During or after the original experiment, the individual `simres/` directories will be tarred and moved to the archive, ultimately migrated from spinning disk to tap. Manually restaging them back to spinning disk and unpacking them could be a very time consuming task, so there are two auxiliary scripts shipped with this workflow helping you with this. i) [aux_restageTape.sh](../auxiliaryscripts.md#aux_restagetapesh) and ii) [aux_UnTarManyTars.sh](../auxiliaryscripts.md#aux_untarmanytarssh)


### Restore the workflow used

Once the `simres/` directory is back on spinning disc, extract the `HISTORY.txt` file, move to a directory where you want to set up the old workflow, and clone the workflow repository.

``` bash
cd /DIR/WHERE/TO/SETUP/OLD/WORKFLOW
git clone GITURL
```

Enter the cloned directory.    
As we just want to reproduce a simulation, and dont want to push some changes to the remote repository, let us disable the push function. Just to make sure we do not mess up the remote repo. To do so type:

``` bash
git remote set-url --push origin no_push
```

Now restore the specific version of the workflow used by the simulation we want to reproduce. Do so by checking out the logged commit (stored in `HISTORY.txt`).

``` bash
git checkout COMMITSHA 
```

Most probably the workflow is using submodules, so initialize them now with:

``` bash
git submodule init 
git submodule update
```

To also include changes not committed to the repository, apply the previously mentioned patch file `GitDiffHead_workflow.diff`. Therefore copy this file from the restaged `simres/` directory to the new cloned workflow and use `git apply`:

``` bash
cp PATCHFILE ./
git apply GitDiffHead_workflow.diff
```

In principle the `GitDiffHead_workflow.diff` files does also contain the information if a submodule was not committed during runtime of the original simulation. But `git apply` does not update submodules, as submodule tracking is different to usual file tracking. So if submodules are used (if other repositories than the workflow are listed in `HISTORY.txt`) you have to update them manually.   
Therefore enter the individual submodule and check the currently checked out commit with `git log`. If the commit the is same as logged in `HISTORY.txt` everything is fine. If not, fetch the latest state of the submodule and checkout the commit logged in `HISTORY.txt`. E.g.:

``` bash
cd SUBMODULE
git fetch
git checkout COMMITSHA
```
Also apply the patch files for all submodules similar as described above for the
workflow (`GitDiffHead_workflow.diff`).

Now the workflow is in the same state as it was while running the original simulation.


### Build the model

To build the model (TSMP), follow the introductions in the `README.md` file. As we restored the same version of the workflow as used for the original simulation, the instructions in the `README.md` are also the same.


### Provide forcing files

Forcing files are not tracked due to their large storage volume. So contact the
author named within the `HISTORY.txt` files and aske for the forcing files.


### Re-Run the simulation

Finally you can rerun the simulation.  
However, even if we set up the same workflow version as used during the original simulation, you have to manually adjust the `ctrl/starter.sh` file first, in particular setting the start date and number of simulations. This is needed because we can submit multiple simulations by just providing the start date of the first simulation and the number of how many simulations to run in total (see [Job submission](../jobsubmission.md#job-submission). In this case the start date and the number of simulations to run does not have to match the simulation we want to re run. So you have to adjust.    
If done, run `starter.sh` with

``` bash
./starter.sh
```
