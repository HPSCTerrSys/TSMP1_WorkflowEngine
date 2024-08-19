#!/bin/bash

# PURPOSE: 
#   This bash script is part of the TSMP1 workflow engine.
#   It is the main run-control script which is used to time-loop over
#   many simulation steps (= any time-interval to be run within a single
#   job) by setting up a slurm chain job with dependencies. This
#   script covers all operations (forcing data preprocessing, simulation,
#   postprocessing/monitoring, cleaning/archiving), except the generation
#   of static fields (geo/).
#   See the TSMP1 workflow engine documentation for further details.
# RESTRUCTIONS: 
#   Manual code modifications needed.
#   Empty string for depencies may be removed. Script extension needed.
# VERSION: 
#   2024-08-14 (last functionality edits)
# AUTHOR(S): 
#   Niklas WAGNER (ex FZJ), refinements by Klaus GOERGEN
# MAINTAINER: 
#   Klaus GOERGEN (k.goergen@fz-juelich.de)
# LICENSE:
#   MIT
# USAGE: 
#   ./$0

################################################################################
# Adjust according to your needs below
################################################################################

# length of one simulaiton. Has to be a valid `date`  option like '1 month', 
# '10 days', etc. (number is # IMPORTANT!) AT THE MOMENT simLength>=1day IS 
# NEEDED! In essence this is the time increment, i.e. the simulation time
# interval
simLength="1 month"

# total number of jobs (NoS/simPerJob=numberof sbatch jobs)
NoS=1

# number of simulations to run within one job (less queuing time?), default by 
# NWa is 4 to 6: i.e., run 6 simulations within one big job
# misleading nomenclature, within a single NoS multiple simulations can be run
# as part of a single sbatch call (with a long wall clock time)
simPerJob=1          

# start date - needs to be changed while simulation is progressing this is the 
# start date of any action, when manually starting a simuilation  this needs to 
# be adjusted
# The format of `startDate` and `initDate` hast to follow ISO norm 8601 
# (https://de.wikipedia.org/wiki/ISO_8601). This is importat to ensure `date` 
# is working properly!
startDate="2019-01-01T00:00Z" 

# init date - is fix for entre simulation 
initDate="1950-01-01T00:00Z"  

# The date string used to name simulation results etc. Again, this has to be a 
# valid `date` option
dateString="+%Y%m%d%H"

# this is only relevant for sim pos fin nd only if a job is the forst job in a 
# chain of jobs; defeult is empty, but can be manually set, but then needs to 
# be checked whether the job was successful, otherwise just sacct or scontrol
prevJobID=""

# Define which substeps (PREprocessing, SIMulation,  POStprocessing, FINishing) 
# should be run. Default is to # set each substep to 'true', if one need to 
# run individual steps exclude other substeps by setting to 'false'
# typical operation (i) pre, (ii) sim+pos+fin, (iii) aux-scripts
pre=false 
sim=true
pos=false
fin=false

# jjsc39, slts, esmtst
computeAccount="jjsc39"

# assuming one is executing this script from the BASE_CTRLDIR, what is the 
# case most of the time
CTRLDIR=$(pwd)

# see ctrl/CASES.conf for variant / case or a run withint the simulation 
# experiment
CaseID="testNewSlurmNewAffinityNewCtrl"

# quick identifier of the run for job name, helps in case of multiple running 
# jobs
jobShortId="ssp370"

################################################################################
# within the same type of sim. exp. and setup, do not change anything below
################################################################################

# Set timestep for component models in seconds
TSTP_COSMO=100
TSTP_CLM=900
TSTP_PARFLOW=900

# PROC (processor, i.e. number of MPI tasks and CPU cores) distribution of 
# individual component models; normally no changes during simulation experiment
PROC_COSMO_X=16
PROC_COSMO_Y=24
PROC_PARFLOW_P=14
PROC_PARFLOW_Q=14
PROC_CLM=60
PROCX_INT2LM=16
PROCY_INT2LM=8
PROCIO_INT2LM=0

# def SBATCH for prepro
pre_NODES=1
pre_NTASKS=128
pre_NTASKSPERNODE=128
pre_WALLCLOCK=01:00:00 #00:45:00
pre_PARTITION=dc-cpu
pre_MAILTYPE=FAIL

# def SBATCH for simulation
# sim_NODES and sim_NTASKS are set automatically based on PROC_* further below
sim_NTASKSPERNODE=128 # 128, 48 
sim_WALLCLOCK=05:30:00
sim_PARTITION=dc-cpu #dc-cpu, mem192, batch, esm
sim_MAILTYPE=ALL

# def SBATCH for postpro (was set to 24 tasks)
pos_NODES=1
pos_NTASKS=128
pos_NTASKSPERNODE=128
pos_WALLCLOCK=02:00:00 #03:30:00 # (vis is about 10min, only for single month)
pos_PARTITION=dc-cpu #dc-cpu-devel
pos_MAILTYPE=FAIL

# def SBATCH for finishing
fin_NODES=1
fin_NTASKS=128
fin_NTASKSPERNODE=128
fin_WALLCLOCK=00:40:00
fin_PARTITION=dc-cpu #dc-cpu-devel
fin_MAILTYPE=FAIL

################################################################################
# End of adjustments; do not edit anything below
################################################################################

# Export those variables set above which are needed in all scripts:
# this is variables which are time invariant
export simLength=${simLength}
export dateString=${dateString}
export initDate=${initDate}
export CaseID=${CaseID}
export TSTP_COSMO=${TSTP_COSMO}
export TSTP_CLM=${TSTP_CLM}
export TSTP_PARFLOW=${TSTP_PARFLOW}
export PROC_COSMO_X=${PROC_COSMO_X}
export PROC_COSMO_Y=${PROC_COSMO_Y}
export PROC_PARFLOW_P=${PROC_PARFLOW_P}
export PROC_PARFLOW_Q=${PROC_PARFLOW_Q}
export PROC_CLM=${PROC_CLM}
export PROCX_INT2LM=${PROCX_INT2LM}
export PROCY_INT2LM=${PROCY_INT2LM}
export PROCIO_INT2LM=${PROCIO_INT2LM}
export PRE_PARTITION=${pre_PARTITION}
export PRE_NTASKS=${pre_NTASKS}
export SIM_PARTITION=${sim_PARTITION}
export SIM_NTASKS=${sim_NTASKS}
export POST_PARTITION=${pos_PARTITION}
export POST_NTASKS=${pos_NTASKS}
export FIN_PARTITION=${fin_PARTITION}
export FIN_NTASKS=${fin_NTASKS}

# Update some paths exported via 'export_paths.sh' 'updatePathsForCASES()' is 
# located in 'start_helper.sh'
source ${CTRLDIR}/SimInfo.sh
source ${CTRLDIR}/export_paths.sh
source ${BASE_CTRLDIR}/start_helper.sh
updatePathsForCASES ${BASE_CTRLDIR}/CASES.conf ${CaseID}
export COMBINATION=${COMBINATION}

# The TSMP build name is automatically created during the TSMP 
# builing step (compilation) and typically consists of
# JSCMACHINE_COMBINATION. One can look up
# this name within the TSMP/bin/ dir.
TSMPbuild="JURECA_${COMBINATION}" #TSMPbuild="JUWELS_${COMBINATION}" 
export TSMP_BINDIR=${BASE_SRCDIR}/TSMP/bin/${TSMPbuild}

# Calculate sim_NTASKS based on PROC_* and COMBINATION
sim_NTASKS=0
IFS='-' read -ra components <<< "${COMBINATION}"
for component in "${components[@]}"; do
  if [[ "${component}" == cos? ]]; then
    sim_NTASKS=$(( ($PROC_COSMO_X*$PROC_COSMO_Y) + $sim_NTASKS ))
  elif [[ "${component}" == clm? ]]; then
    sim_NTASKS=$(( $PROC_CLM + $sim_NTASKS ))
  elif [[ "${component}" == pfl ]]; then
    sim_NTASKS=$(( ($PROC_PARFLOW_P*$PROC_PARFLOW_Q) + $sim_NTASKS ))
  else
    echo "ERROR: unknown component ($component) --> Exit"
    exit 1
  fi
done
sim_NODES=$(((${sim_NTASKS}+${sim_NTASKSPERNODE}-1)/${sim_NTASKSPERNODE}))

echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- pwd: $(pwd)"
echo "--- simulation    init-date: ${initDate}"
echo "---              start-date: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "---             COMBINATION: ${COMBINATION}"
echo "--- HOST: $(hostname)"

# set up the slurm scheduler chain job
cd $BASE_CTRLDIR
loop_counter=0
while [ $loop_counter -lt $NoS ]
do

  startDateId=$(date -u -d "${startDate}" "${dateString}")
  echo "loop_counter ${loop_counter} / NoS ${NoS} / startDate ${startDate} ${startDateId}"

  # if there are not enough simmulations left to fill the job
  # reduce $simPerJob to number of jobs left
  # if total NoS cannot be divided by simPerJob to an integer
  # at the end of a simulation or with days instead of 
  # months run daily until the end of a month
  # this is only relevant in case of blockwise execution, i.e.
  # per job multiple simulations
  if [[ $((loop_counter+simPerJob)) -gt $NoS ]]; then
    echo "-- too few simulations left, to run last job with $simPerJob simulations"
    simPerJob=$((NoS-loop_counter))
  fi

  # Preprocessing, lateral boundary forcing, human water use, etc.
  if $pre ; then
    echo "pre"
    submit_prepro_return=$(sbatch \
          --job-name="${CaseID}_pre_${simShortId}_${startDateId}" \
          --constraint=largedata \
          --export=ALL,startDate=${startDate},CTRLDIR=${BASE_CTRLDIR},NoS=${simPerJob} \
          --output="${BASE_LOGDIR}/%x.out.%j" \
          --error="${BASE_LOGDIR}/%x.err.%j" \
          --mail-type=${sim_MAILTYPE} \
          --mail-user=${AUTHOR_MAIL} \
          --nodes=${sim_NODES} \
          --ntasks=${sim_NTASKS} \
          --ntasks-per-node=${sim_NTASKSPERNODE} \
          --threads-per-core=1 \
          --time=${sim_WALLCLOCK} \
          --partition=${sim_PARTITION} \
          --account=${computeAccount} \
          submit_prepro.sh 2>&1)
    echo "${submit_prepro_return}"
    submit_prepro=$(echo $submit_prepro_return | awk '{print $(NF)}')
    echo "prepro for $startDate: $submit_prepro"
  fi

  # Simulation
  # Note that $submit_simulation is decoupled from postpro and finishing.
  # The simulation therby depends on the prepro and itself only, aiming to
  # run the individual simulations as fast as possible, since no jobs are
  # executed in between.
  if $sim ; then
    echo "sim"
    if $pre ; then
      dependencyString="afterok:${submit_prepro}"
      if [[ $loop_counter -gt 0 ]] ; then
        dependencyString="${dependencyString}:${submit_simulation}"
      fi
    else
      if [[ $loop_counter -gt 0 ]] ; then
        dependencyString="afterok:${submit_simulation}"
      else
        dependencyString=$prevJobID
      fi
    fi
    submit_simulation_return=$(sbatch \
          --job-name="${CaseID}_sim_${jobShortId}_${startDateId}" \
          --dependency=$dependencyString \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          --output="${BASE_LOGDIR}/%x.out.%j" \
          --error="${BASE_LOGDIR}/%x.err.%j" \
          --mail-type=${sim_MAILTYPE} \
          --mail-user=${AUTHOR_MAIL} \
          --nodes=${sim_NODES} \
          --ntasks=${sim_NTASKS} \
          --ntasks-per-node=${sim_NTASKSPERNODE} \
          --threads-per-core=1 \
          --time=${sim_WALLCLOCK} \
          --partition=${sim_PARTITION} \
          --account=${computeAccount} \
          submit_simulation.sh 2>&1)
    echo "${submit_simulation_return}"
    submit_simulation=$(echo $submit_simulation_return | awk 'END{print $(NF)}')
    echo "simulation for $startDate: $submit_simulation"
  fi

  # Postprocessing including monitoring
  if $pos ; then
    if $sim ; then
      dependencyString="afterok:${submit_simulation}"
    else
      dependencyString=$prevJobID
    fi
    submit_postpro_return=$(sbatch \
          --job-name="${CaseID}_pos_${jobShortId}_${startDateId}" \
          --dependency=$dependencyString \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          --output="${BASE_LOGDIR}/%x.out.%j" \
          --error="${BASE_LOGDIR}/%x.err.%j" \
          --mail-type=${pos_MAILTYPE} \
          --mail-user=${AUTHOR_MAIL} \
          --nodes=${pos_NODES} \
          --ntasks=${pos_NTASKS} \
          --ntasks-per-node=${pos_NTASKSPERNODE} \
          --threads-per-core=1 \
          --time=${pos_WALLCLOCK} \
          --partition=${pos_PARTITION} \
          --account=${computeAccount} \
          submit_postpro.sh 2>&1)
    echo "${submit_postpro_return}"
    submit_postpro=$(echo ${submit_postpro_return} | awk 'END{print $(NF)}')
    echo "postpro for $startDate: $submit_postpro"
  fi

  # Finalisation
  if $fin ; then
    if $pos ; then
      dependencyString="afterok:${submit_postpro}"
    else
      dependencyString=$prevJobID
    fi
    submit_finishing_return=$(sbatch \
          --job-name="${CaseID}_fin_${jobShortId}_${startDateId}" \
          --dependency=$dependencyString \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          --output="${BASE_LOGDIR}/%x.out.%j" \
          --error="${BASE_LOGDIR}/%x.err.%j" \
          --mail-type=${pos_MAILTYPE} \
          --mail-user=${AUTHOR_MAIL} \
          --nodes=${fin_NODES} \
          --ntasks=${fin_NTASKS} \
          --ntasks-per-node=${fin_NTASKSPERNODE} \
          --threads-per-core=1 \
          --time=${fin_WALLCLOCK} \
          --partition=${fin_PARTITION} \
          --account=${computeAccount} \
          submit_finishing.sh 2>&1)
    echo "${submit_finishing_return}"
    submit_finishing=$(echo ${submit_finishing_return} | awk 'END{print $(NF)}')
    echo "finishing for $startDate: $submit_finishing"
  fi
  
  # Forward the simulation control counter
  # Iterate 'simPerJob' times and increment `startDate` to calculate the 
  # new startDate of the next job. This loops to me seems the easyest solution
  # to make use of native `date` increments like ''1 month', '10 days', etc.  
  # And increment `loop_counter` as well...
  # KGo: Because per NoS job multiple operations are possible within one sbatch
  # command, set by the simPerJob, the date has to be corrected here
  # as NoS=SimPerJobxNrOfSbatchJobs (SbatchJobs can be multiple dependencies)
  i=1; while [ $i -le $simPerJob ]; do
    startDate=$(date -u -d "${startDate} +${simLength}" "+%Y-%m-%dT%H:%MZ")
    ((loop_counter++))
    ((i++))
  done

done

exit 0
